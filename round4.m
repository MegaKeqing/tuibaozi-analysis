% round4.m
% 计算第四回合所有可能的牌堆分布及每种牌堆下的胜率/统计，结果保存为 CSV
% 运行：在 MATLAB 中切换到脚本目录，运行： round4

clearvars -except; clc;

% start timer for total runtime
tStart = tic;

ranks = 1:8; nRanks = numel(ranks);

% 生成36种玩家点数组合
playerComb = [];
for i = 1:nRanks
    v = zeros(1,nRanks); v(i) = 2; playerComb = [playerComb; v];
    for j = i+1:nRanks
        v = zeros(1,nRanks); v(i)=1; v(j)=1; playerComb = [playerComb; v];
    end
end
nComb = size(playerComb,1); assert(nComb==36);

% 点数与对子标记
playerPoint = zeros(nComb,1); playerIsPair = false(nComb,1);
for k = 1:nComb
    cnt = playerComb(k,:); idx = find(cnt>0);
    if any(cnt==2)
        r = find(cnt==2); playerPoint(k) = 10 + r; playerIsPair(k) = true;
    else
        playerPoint(k) = mod(sum(idx),10);
    end
end

% 预计算阶乘 (0..8)
fact = arrayfun(@factorial,0:8);

% 直接枚举第四回合的所有可能牌堆（和为8，且每项在0..4）
fprintf('Enumerating all fourth-round pile configurations (sum=8, 0..4 each)...\n');
total = 8; num_values = nRanks;
piles = [];
for c1 = 0:4
    for c2 = 0:4
        for c3 = 0:4
            for c4 = 0:4
                for c5 = 0:4
                    if c1+c2+c3+c4+c5 > total, continue; end
                    for c6 = 0:4
                        if c1+c2+c3+c4+c5+c6 > total, continue; end
                        for c7 = 0:4
                            if c1+c2+c3+c4+c5+c6+c7 > total, continue; end
                            for c8 = 0:4
                                if c1+c2+c3+c4+c5+c6+c7+c8 == total
                                    piles = [piles; [c1,c2,c3,c4,c5,c6,c7,c8]];
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

deckStates = piles;
nFourth = size(deckStates,1);
fprintf('Found %d fourth-round piles.\n', nFourth);

% 计算每个牌堆在原始32张牌中被留下的概率： P(c) = prod_i nchoosek(4, c_i) / nchoosek(32,8)
denomAll = nchoosek(32,8);
deckProb = zeros(nFourth,1);
for i = 1:nFourth
    ci = deckStates(i,:);
    mult = 1;
    for r = 1:num_values
        mult = mult * nchoosek(4, ci(r));
    end
    deckProb(i) = mult / denomAll;
end

% Step: 对每个第四回合牌堆计算胜率（与 round3 类似，但 remTotal=8）
fprintf('Computing win stats for each fourth-round pile...\n');
results = struct(); results.deck = cell(nFourth,1); results.prob_from_prior = deckProb;
results.win_X = zeros(nFourth,1); results.win_Y = zeros(nFourth,1); results.win_Z = zeros(nFourth,1);
results.twoFarmers = zeros(nFourth,1); results.threeFarmers = zeros(nFourth,1);
results.farmerWinPair_X = zeros(nFourth,1); results.farmerWinPair_Y = zeros(nFourth,1); results.farmerWinPair_Z = zeros(nFourth,1);
results.farmerWinNonPair_X = zeros(nFourth,1); results.farmerWinNonPair_Y = zeros(nFourth,1); results.farmerWinNonPair_Z = zeros(nFourth,1);
results.totalDeals_next = zeros(nFourth,1);
% joint distribution (X,Y,Z) storage: 27 combinations
results.jointWeights = zeros(nFourth, 27);
results.jointLabels = cell(27,1);

remTotal = 8; % 第四回合牌堆总牌数
totalDeals_next = nchoosek(remTotal,2) * nchoosek(remTotal-2,2) * nchoosek(remTotal-4,2) * nchoosek(remTotal-6,2);

% prepare joint labels and safe column names for 27 combinations
vals = [-1, 1, 2];
jointColNames = cell(27,1);
cnt = 0;
for ix = 1:3
    for iy = 1:3
        for iz = 1:3
            cnt = cnt + 1;
            results.jointLabels{cnt} = sprintf('%d_%d_%d', vals(ix), vals(iy), vals(iz));
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

for idx = 1:nFourth
    rem = deckStates(idx,:);
    results.deck{idx} = sprintf('%d%d%d%d%d%d%d%d', rem);
    results.totalDeals_next(idx) = totalDeals_next;

    totalW = 0; fw = zeros(3,1); fwPair = zeros(3,1); fwNon = zeros(3,1); twoW = 0; threeW = 0;
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
                    w4 = 1;
                    for r = 1:nRanks
                        % 使用 fact 数组： fact(n+1) = factorial(n)
                        w4 = w4 * (fact(rem(r)+1) / (fact(rem(r) - t(r) + 1) * fact(aM(r)+1) * fact(aX(r)+1) * fact(aY(r)+1) * fact(aZ(r)+1)));
                    end
                    totalW = totalW + w4;
                    winX = (pX > pM); winY = (pY > pM); winZ = (pZ > pM);
                    if winX
                        fw(1) = fw(1) + w4; if isPairX, fwPair(1)=fwPair(1)+w4; else fwNon(1)=fwNon(1)+w4; end
                    end
                    if winY
                        fw(2) = fw(2) + w4; if isPairY, fwPair(2)=fwPair(2)+w4; else fwNon(2)=fwNon(2)+w4; end
                    end
                    if winZ
                        fw(3) = fw(3) + w4; if isPairZ, fwPair(3)=fwPair(3)+w4; else fwNon(3)=fwNon(3)+w4; end
                    end
                    % accumulate joint state weight: -1 lose, 1 win non-pair, 2 win pair
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
                    pos = @(v) (v==-1)*1 + (v==1)*2 + (v==2)*3;
                    pi1 = pos(sx); pj = pos(sy); pk = pos(sz);
                    ind = (pi1-1)*9 + (pj-1)*3 + pk;
                    jRow(ind) = jRow(ind) + w4;
                    nW = winX + winY + winZ;
                    if nW >= 2, twoW = twoW + w4; end
                    if nW == 3, threeW = threeW + w4; end
                end
            end
        end
    end

    % 归一化为概率
    if abs(totalW - totalDeals_next) > 1e-6 * totalDeals_next
        warning('totalW (%.0f) differs from totalDeals_next (%.0f) for deck %s', totalW, totalDeals_next, results.deck{idx});
    end
    if totalDeals_next == 0
        results.win_X(idx)=NaN; results.win_Y(idx)=NaN; results.win_Z(idx)=NaN;
    else
        results.win_X(idx) = fw(1) / totalDeals_next;
        results.win_Y(idx) = fw(2) / totalDeals_next;
        results.win_Z(idx) = fw(3) / totalDeals_next;
        results.twoFarmers(idx) = twoW / totalDeals_next;
        results.threeFarmers(idx) = threeW / totalDeals_next;
    end
    results.farmerWinPair_X(idx)=fwPair(1); results.farmerWinPair_Y(idx)=fwPair(2); results.farmerWinPair_Z(idx)=fwPair(3);
    results.farmerWinNonPair_X(idx)=fwNon(1); results.farmerWinNonPair_Y(idx)=fwNon(2); results.farmerWinNonPair_Z(idx)=fwNon(3);
    results.jointWeights(idx, :) = jRow;
    elapsed_iter = toc(tStart);
    fprintf(' processed %d / %d (%.1fs)\n', idx, nFourth, elapsed_iter);
end

% 保存 CSV，参考 round1/round2/round3 格式
fprintf('Saving round4_results.csv...\n');
n = nFourth;
ev_X = zeros(n,1); ev_Y = zeros(n,1); ev_Z = zeros(n,1);
winrate_X = results.win_X; winrate_Y = results.win_Y; winrate_Z = results.win_Z;
nonpair_X = zeros(n,1); nonpair_Y = zeros(n,1); nonpair_Z = zeros(n,1);
pair_X = zeros(n,1); pair_Y = zeros(n,1); pair_Z = zeros(n,1);
farmerWinWeight_X = zeros(n,1); farmerWinWeight_Y = zeros(n,1); farmerWinWeight_Z = zeros(n,1);

for i = 1:n
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

    prob_nonpair = nonpair_X(i); prob_pair = pair_X(i); prob_win = prob_nonpair + prob_pair; prob_loss = 1 - prob_win;
    ev_X(i) = prob_nonpair + 2*prob_pair - prob_loss;
    prob_nonpair = nonpair_Y(i); prob_pair = pair_Y(i); prob_win = prob_nonpair + prob_pair; prob_loss = 1 - prob_win;
    ev_Y(i) = prob_nonpair + 2*prob_pair - prob_loss;
    prob_nonpair = nonpair_Z(i); prob_pair = pair_Z(i); prob_win = prob_nonpair + prob_pair; prob_loss = 1 - prob_win;
    ev_Z(i) = prob_nonpair + 2*prob_pair - prob_loss;
end

T = table;
T.deck = results.deck;
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
T.prob_from_prior = results.prob_from_prior;

T.farmerWinWeight_X = farmerWinWeight_X; T.farmerWinWeight_Y = farmerWinWeight_Y; T.farmerWinWeight_Z = farmerWinWeight_Z;
T.farmerWinNonPairWeight_X = results.farmerWinNonPair_X; T.farmerWinNonPairWeight_Y = results.farmerWinNonPair_Y; T.farmerWinNonPairWeight_Z = results.farmerWinNonPair_Z;
T.farmerWinPairWeight_X = results.farmerWinPair_X; T.farmerWinPairWeight_Y = results.farmerWinPair_Y; T.farmerWinPairWeight_Z = results.farmerWinPair_Z;
% 添加联合分布列（条件概率）和原始权重列
for k = 1:27
    colW = sprintf('%s_Weight', results.jointLabels{k});
    T.(colW) = results.jointWeights(:,k);
end
T.totalDeals = results.totalDeals_next;

outfn = fullfile(pwd, 'round4_results.csv');
writetable(T, outfn);
fprintf('Saved %s\n', outfn);
% print total elapsed time
elapsed = toc(tStart);
fprintf('Total elapsed time: %.2f seconds\n', elapsed);
