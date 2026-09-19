% second_round_analysis  生成第二回合牌堆分布并计算每个牌堆下的胜率，保存为 CSV


clearvars -except; clc;

% start timer for total runtime
tStart = tic;

% 参数
ranks = 1:8; nRanks = numel(ranks);

% 生成单玩家的36种点数组合（计数向量）
playerComb = [];
for i = 1:nRanks
    v = zeros(1,nRanks); v(i) = 2; playerComb = [playerComb; v];
    for j = i+1:nRanks
        v = zeros(1,nRanks); v(i)=1; v(j)=1; playerComb = [playerComb; v];
    end
end
nComb = size(playerComb,1);
assert(nComb==36);

% 预计算点数/是否对子
playerPoint = zeros(nComb,1);
playerIsPair = false(nComb,1);
for k = 1:nComb
    cnt = playerComb(k,:); idx = find(cnt>0);
    if any(cnt==2)
        r = find(cnt==2); playerPoint(k) = 10 + r; playerIsPair(k) = true;
    else
        playerPoint(k) = mod(sum(idx),10);
    end
end

% 预计算阶乘
fact = arrayfun(@factorial,0:8); %#ok<NASGU>

% 第一回合总发牌数（使用完整牌堆32张）
totalDeals_first = nchoosek(32,2) * nchoosek(30,2) * nchoosek(28,2) * nchoosek(26,2);

% 映射：remaining deck (长度8向量) -> 累计权重（来自第一回合）
remMap = containers.Map();
remWeightMap = containers.Map();

% 遍历第一回合所有点数组合，累加到对应的剩余牌向量
fprintf('Enumerating all first-round point configurations (this may take a while)...\n');
iter = 0; totIter = nComb^4; printInterval = 200000;
for iM = 1:nComb
    aM = playerComb(iM,:);
    for iX = 1:nComb
        aX = playerComb(iX,:);
        for iY = 1:nComb
            aY = playerComb(iY,:);
            for iZ = 1:nComb
                aZ = playerComb(iZ,:);
                iter = iter + 1;
                if mod(iter, printInterval)==0
                    fprintf(' first-round progress: %d / %d (%.2f%%)\n', iter, totIter, 100*iter/totIter);
                end

                t = aM + aX + aY + aZ;
                if any(t > 4), continue; end % 不可能的组合（超过4张同点数）

                % 第一回合权重 w_first(D) = prod_r 4!/(4-tr)! / (aM! aX! aY! aZ!)
                w = 1;
                for r = 1:nRanks
                    w = w * (24 / (fact(4 - t(r)+1) * fact(aM(r)+1) * fact(aX(r)+1) * fact(aY(r)+1) * fact(aZ(r)+1)));
                end

                rem = 4 - t; key = sprintf('%d_', rem);
                if isKey(remWeightMap, key)
                    remWeightMap(key) = remWeightMap(key) + w;
                else
                    remWeightMap(key) = w;
                end
            end
        end
    end
end

% 汇总 remMap -> 提取所有剩余牌向量与对应概率
keysRem = remWeightMap.keys;
nRem = numel(keysRem);
deckStates = zeros(nRem, nRanks);
deckProb = zeros(nRem,1);
deckWeight = zeros(nRem,1);
for k = 1:nRem
    key = keysRem{k};
    % parse key back to vector
    nums = sscanf(key, '%d_');
    deckStates(k,:) = nums';
    deckWeight(k) = remWeightMap(key);
    deckProb(k) = deckWeight(k) / totalDeals_first;
end

fprintf('Found %d distinct second-round deck states.\n', nRem);

% 对每个 deckState 计算下一手（第二回合）的胜率分布
results = struct();
results.deck = cell(nRem,1);
results.prob_first = deckProb;
results.win_X = zeros(nRem,1);
results.win_Y = zeros(nRem,1);
results.win_Z = zeros(nRem,1);
results.twoFarmers = zeros(nRem,1);
results.threeFarmers = zeros(nRem,1);
results.farmerWinPair_X = zeros(nRem,1);
results.farmerWinPair_Y = zeros(nRem,1);
results.farmerWinPair_Z = zeros(nRem,1);
results.farmerWinNonPair_X = zeros(nRem,1);
results.farmerWinNonPair_Y = zeros(nRem,1);
results.farmerWinNonPair_Z = zeros(nRem,1);
results.totalDeals_next = zeros(nRem,1);
% joint weights for (X,Y,Z) where each in {-1,1,2}
results.jointWeights = zeros(nRem, 27);
results.jointLabels = cell(27,1);

fprintf('Computing next-deal win probabilities for each deck state...\n');
% total unordered deals from this remaining deck
remTotal = 24;
totalDeals_next = nchoosek(remTotal,2) * nchoosek(remTotal-2,2) * nchoosek(remTotal-4,2) * nchoosek(remTotal-6,2);

% prepare joint label names and safe table column names
vals = [-1, 1, 2];
jointColNames = cell(27,1);
cnt = 0;
for ix = 1:3
    for iy = 1:3
        for iz = 1:3
            cnt = cnt + 1;
            lab = sprintf('%d_%d_%d', vals(ix), vals(iy), vals(iz));
            results.jointLabels{cnt} = lab;
            % make a safe variable name for table: joint_m1_1_2 etc.
            if vals(ix) == -1
                sx = 'm1';
            elseif vals(ix) == 1
                sx = '1';
            else
                sx = '2';
            end
            if vals(iy) == -1
                sy = 'm1';
            elseif vals(iy) == 1
                sy = '1';
            else
                sy = '2';
            end
            if vals(iz) == -1
                sz = 'm1';
            elseif vals(iz) == 1
                sz = '1';
            else
                sz = '2';
            end
            jointColNames{cnt} = sprintf('joint_%s_%s_%s', sx, sy, sz);
        end
    end
end

for idx = 1:nRem
    fprintf('Processing deck %d / %d...', idx, nRem);
    rem = deckStates(idx,:);
    results.deck{idx} = sprintf('%d%d%d%d%d%d%d%d', rem);
    results.totalDeals_next(idx) = totalDeals_next;

    % 遍历所有点数组合（36^4），在该剩余牌限制下计算权重
    totalW = 0;
    fw = zeros(3,1); fwPair = zeros(3,1); fwNonPair = zeros(3,1);
    twoW = 0; threeW = 0;
    jRow = zeros(1,27);
    for iM = 1:nComb
        aM = playerComb(iM,:); pM = playerPoint(iM); isPairM = playerIsPair(iM);
        for iX = 1:nComb
            aX = playerComb(iX,:); pX = playerPoint(iX); isPairX = playerIsPair(iX);
            for iY = 1:nComb
                aY = playerComb(iY,:); pY = playerPoint(iY); isPairY = playerIsPair(iY);
                for iZ = 1:nComb
                    aZ = playerComb(iZ,:); pZ = playerPoint(iZ); isPairZ = playerIsPair(iZ);

                    t = aM + aX + aY + aZ;
                    if any(t > rem), continue; end

                    % weight under this remaining deck: prod_r rem_r!/(rem_r - t_r)! / (aM! aX! aY! aZ!)
                    w2 = 1;
                    for r = 1:nRanks
                        w2 = w2 * (fact(rem(r)+1) / fact(rem(r) - t(r)+1) / (fact(aM(r)+1) * fact(aX(r)+1) * fact(aY(r)+1) * fact(aZ(r)+1)));
                    end

                    totalW = totalW + w2;

                    % 比较点数（地主平局获胜）
                    winX = (pX > pM);
                    winY = (pY > pM);
                    winZ = (pZ > pM);
                    if winX
                        fw(1) = fw(1) + w2;
                        if isPairX, fwPair(1) = fwPair(1) + w2; else fwNonPair(1) = fwNonPair(1) + w2; end
                    end
                    if winY
                        fw(2) = fw(2) + w2;
                        if isPairY, fwPair(2) = fwPair(2) + w2; else fwNonPair(2) = fwNonPair(2) + w2; end
                    end
                    if winZ
                        fw(3) = fw(3) + w2;
                        if isPairZ, fwPair(3) = fwPair(3) + w2; else fwNonPair(3) = fwNonPair(3) + w2; end
                    end

                    % 构造联合状态：-1 表示输，1 表示赢但非豹子，2 表示赢且为豹子
                    if winX
                        if isPairX, sx = 2; else sx = 1; end
                    else
                        sx = -1;
                    end
                    if winY
                        if isPairY, sy = 2; else sy = 1; end
                    else
                        sy = -1;
                    end
                    if winZ
                        if isPairZ, sz = 2; else sz = 1; end
                    else
                        sz = -1;
                    end

                    % map (-1,1,2) to positions 1..3 each
                    pos = @(v) (v==-1)*1 + (v==1)*2 + (v==2)*3;
                    pi1 = pos(sx); pj2 = pos(sy); pk3 = pos(sz);
                    ind27 = (pi1-1)*9 + (pj2-1)*3 + pk3;
                    jRow(ind27) = jRow(ind27) + w2;

                    nWinners = winX + winY + winZ;
                    if nWinners >= 2, twoW = twoW + w2; end
                    if nWinners == 3, threeW = threeW + w2; end

                end
            end
        end
    end

    % 归一化为概率（除以 totalDeals_next）
    if totalW ~= totalDeals_next
        % 由于组合计数方式一致，这里totalW应等于totalDeals_next；允许微小浮点误差
        % 若差异较大，保留 warning
        if abs(totalW - totalDeals_next) > 1e-6 * totalDeals_next
            warning('totalW (%.0f) differs from totalDeals_next (%.0f) for deck %s', totalW, totalDeals_next, results.deck{idx});
        end
    end

    results.win_X(idx) = fw(1) / totalDeals_next;
    results.win_Y(idx) = fw(2) / totalDeals_next;
    results.win_Z(idx) = fw(3) / totalDeals_next;
    results.twoFarmers(idx) = twoW / totalDeals_next;
    results.threeFarmers(idx) = threeW / totalDeals_next;
    results.farmerWinPair_X(idx) = fwPair(1);
    results.farmerWinPair_Y(idx) = fwPair(2);
    results.farmerWinPair_Z(idx) = fwPair(3);
    results.farmerWinNonPair_X(idx) = fwNonPair(1);
    results.farmerWinNonPair_Y(idx) = fwNonPair(2);
    results.farmerWinNonPair_Z(idx) = fwNonPair(3);
    results.jointWeights(idx, :) = jRow;

    elapsed_iter = toc(tStart);
    fprintf(' Done %d / %d (%.1fs)\n', idx, nRem, elapsed_iter);
end

% 将结果保存为 CSV
fprintf('Saving results to round2_results.csv...\n');
T = table;
T.deck = results.deck;

% 按照 round1 的保存格式组织字段
% 计算每个牌堆下的概率与期望（基于该牌堆的 totalDeals_next）
ev_X = zeros(nRem,1); ev_Y = zeros(nRem,1); ev_Z = zeros(nRem,1);
winrate_X = results.win_X; winrate_Y = results.win_Y; winrate_Z = results.win_Z;
nonpair_X = zeros(nRem,1); nonpair_Y = zeros(nRem,1); nonpair_Z = zeros(nRem,1);
pair_X = zeros(nRem,1); pair_Y = zeros(nRem,1); pair_Z = zeros(nRem,1);
farmerWinWeight_X = zeros(nRem,1); farmerWinWeight_Y = zeros(nRem,1); farmerWinWeight_Z = zeros(nRem,1);
farmerWinNonPairWeight_X = results.farmerWinNonPair_X; farmerWinNonPairWeight_Y = results.farmerWinNonPair_Y; farmerWinNonPairWeight_Z = results.farmerWinNonPair_Z;
farmerWinPairWeight_X = results.farmerWinPair_X; farmerWinPairWeight_Y = results.farmerWinPair_Y; farmerWinPairWeight_Z = results.farmerWinPair_Z;

for i = 1:nRem
    td = results.totalDeals_next(i);
    if td == 0
        nonpair_X(i)=0; nonpair_Y(i)=0; nonpair_Z(i)=0;
        pair_X(i)=0; pair_Y(i)=0; pair_Z(i)=0;
        farmerWinWeight_X(i)=0; farmerWinWeight_Y(i)=0; farmerWinWeight_Z(i)=0;
        ev_X(i)=NaN; ev_Y(i)=NaN; ev_Z(i)=NaN;
        continue;
    end
    nonpair_X(i) = results.farmerWinNonPair_X(i) / td;
    nonpair_Y(i) = results.farmerWinNonPair_Y(i) / td;
    nonpair_Z(i) = results.farmerWinNonPair_Z(i) / td;
    pair_X(i) = results.farmerWinPair_X(i) / td;
    pair_Y(i) = results.farmerWinPair_Y(i) / td;
    pair_Z(i) = results.farmerWinPair_Z(i) / td;
    farmerWinWeight_X(i) = results.farmerWinPair_X(i) + results.farmerWinNonPair_X(i);
    farmerWinWeight_Y(i) = results.farmerWinPair_Y(i) + results.farmerWinNonPair_Y(i);
    farmerWinWeight_Z(i) = results.farmerWinPair_Z(i) + results.farmerWinNonPair_Z(i);

    % 期望值（按 round1 的 ev_farmer 定义）
    prob_nonpair = nonpair_X(i);
    prob_pair = pair_X(i);
    prob_win = prob_nonpair + prob_pair;
    prob_loss = 1 - prob_win;
    ev_X(i) = prob_nonpair + 2*prob_pair - prob_loss;

    prob_nonpair = nonpair_Y(i);
    prob_pair = pair_Y(i);
    prob_win = prob_nonpair + prob_pair; prob_loss = 1 - prob_win;
    ev_Y(i) = prob_nonpair + 2*prob_pair - prob_loss;

    prob_nonpair = nonpair_Z(i);
    prob_pair = pair_Z(i);
    prob_win = prob_nonpair + prob_pair; prob_loss = 1 - prob_win;
    ev_Z(i) = prob_nonpair + 2*prob_pair - prob_loss;
end

T.ev_farmer_X = ev_X;
T.winrate_X = winrate_X;
T.nonpair_win_X = nonpair_X;
T.pair_win_X = pair_X;
T.twoFarmers = results.twoFarmers;
T.threeFarmers = results.threeFarmers;
% 添加联合分布列（条件于该剩余牌堆的概率），使用安全的列名 joint_m1_1_2 等
for k = 1:27
    col = jointColNames{k};
    T.(col) = results.jointWeights(:,k) / totalDeals_next;
end
T.prob_from_first = results.prob_first;

% 存储每个牌堆下的胜利权重（非概率）
T.farmerWinWeight_X = farmerWinWeight_X;
T.farmerWinWeight_Y = farmerWinWeight_Y;
T.farmerWinWeight_Z = farmerWinWeight_Z;
T.farmerWinNonPairWeight_X = farmerWinNonPairWeight_X;
T.farmerWinNonPairWeight_Y = farmerWinNonPairWeight_Y;
T.farmerWinNonPairWeight_Z = farmerWinNonPairWeight_Z;
T.farmerWinPairWeight_X = farmerWinPairWeight_X;
T.farmerWinPairWeight_Y = farmerWinPairWeight_Y;
T.farmerWinPairWeight_Z = farmerWinPairWeight_Z;
for k = 1:27
    colWeight = sprintf('%s_Weight', results.jointLabels{k});
    T.(colWeight) = results.jointWeights(:,k);
end
T.totalDeals = results.totalDeals_next;


outfn = fullfile(pwd, 'round2_results.csv');
writetable(T, outfn);
fprintf('Saved %s\n', outfn);
% print total elapsed time
elapsed = toc(tStart);
fprintf('Total elapsed time: %.2f seconds\n', elapsed);
