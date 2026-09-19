% compute_first_round_probabilities.m
% 计算第一回合农民、二门、黑子精确概率（按点数组合的真实权重）
clearvars; clc;

% 参数
ranks = 1:8;
nRanks = numel(ranks);

% 列出单个玩家能拿到的所有点数"组合"（无顺序，允许对子）
% 用长度8的计数向量表示，每行和为2
playerComb = []; % 每行是长度8的非负整数和为2的向量
for i = 1:nRanks
    % pair of i
    v = zeros(1,nRanks); v(i) = 2;
    playerComb = [playerComb; v];
    for j = i+1:nRanks
        % one card i, one card j
        v = zeros(1,nRanks); v(i)=1; v(j)=1;
        playerComb = [playerComb; v];
    end
end
% 验证数量应为36
nComb = size(playerComb,1);
assert(nComb==36);

% 预计算每个玩家组合的点数值与是否豹子
playerPoint = zeros(nComb,1);
playerIsPair = false(nComb,1);
for k = 1:nComb
    cnt = playerComb(k,:);
    idx = find(cnt>0);
    if any(cnt==2)
        % pair
        r = find(cnt==2);
        playerPoint(k) = 10 + r; % 豹子点数 = 10 + rank
        playerIsPair(k) = true;
    else
        % two different ranks
        rsum = sum(idx); % idx contains the two ranks
        playerPoint(k) = mod(rsum,10); % (r1 + r2) mod 10
    end
end

% 预计算0..4的阶乘
fact = arrayfun(@factorial,0:4);

% 常量：总发牌数（组合数，无顺序）
totalDeals = nchoosek(32,2) * nchoosek(30,2) * nchoosek(28,2) * nchoosek(26,2);

% 累加器
totalWeight = 0;
farmerWinWeight = zeros(3,1); % X,Y,Z 对地主获胜的加权计数
twoFarmersWinWeight = 0; % 二门（>=2 farmers win）
threeFarmersWinWeight = 0; % 黑子（3 farmers win）
% 新增统计：豹子/非豹子的总权重与胜利权重
farmerTotalPairWeight = zeros(3,1);
farmerTotalNonPairWeight = zeros(3,1);
farmerWinPairWeight = zeros(3,1);
farmerWinNonPairWeight = zeros(3,1);

% 准备 (X,Y,Z) 联合分布的标签与安全表列名（27 种组合）
vals = [-1, 1, 2];
jointLabels = cell(27,1);
jointColNames = cell(27,1);
cntJ = 0;
for ix = 1:3
    for iy = 1:3
        for iz = 1:3
            cntJ = cntJ + 1;
            jointLabels{cntJ} = sprintf('%d_%d_%d', vals(ix), vals(iy), vals(iz));
            % safe name: joint_m1_1_2 etc.
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
            jointColNames{cntJ} = sprintf('joint_%s_%s_%s', sx, sy, sz);
        end
    end
end

% 用于累计当前脚本的 27 个联合权重（原始权重 w）
jRow = zeros(1,27);

% 进度打印设置
totalIterations = nComb^4;
iterCount = 0;
printInterval = 100000; % 每多少个组合打印一次进度

% 遍历四名玩家（顺序：地主 M, 农民 X, Y, Z）
% 四层循环 36^4 ≈ 1.68M，MATLAB 可接受
for iM = 1:nComb
    aM = playerComb(iM,:);
    pM = playerPoint(iM);
    isPairM = playerIsPair(iM);
    for iX = 1:nComb
        aX = playerComb(iX,:);
        pX = playerPoint(iX);
        isPairX = playerIsPair(iX);
        for iY = 1:nComb
            aY = playerComb(iY,:);
            pY = playerPoint(iY);
            isPairY = playerIsPair(iY);
            for iZ = 1:nComb
                aZ = playerComb(iZ,:);
                pZ = playerPoint(iZ);
                isPairZ = playerIsPair(iZ);

                % 计数迭代（包含不合法情况）并周期性打印进度
                iterCount = iterCount + 1;
                if mod(iterCount, printInterval) == 0
                    fprintf('Progress: %d / %d (%.2f%%)\n', iterCount, totalIterations, 100*iterCount/totalIterations);
                end

                % 每个点数 r 的总发出张数 t_r
                t = aM + aX + aY + aZ;
                if any(t > 4)
                    continue; % 不合法组合，超过某点数的4张限制
                end

                % 计算该点数局面的花色分配权重 w(D)
                % w = prod_r 4! / ( (4-tr)! * aM(r)! * aX(r)! * aY(r)! * aZ(r)! )
                w = 1;
                for r = 1:nRanks
                    denom = fact(4 - t(r) + 1) * fact(aM(r)+1) * fact(aX(r)+1) * fact(aY(r)+1) * fact(aZ(r)+1);
                    % 注意上面使用fact索引偏移（因为fact array 从 0 到 4 存放）
                    % 实际值： numerator = fact(4), denom = fact(4-tr)*fact(aM)*...
                    % numerator = factorial(4);
                    % denom = factorial(4 - t(r)) * factorial(aM(r)) * factorial(aX(r)) * factorial(aY(r)) * factorial(aZ(r));
                    w = w * (24 / denom);
                end

                % 累计总权重
                totalWeight = totalWeight + w;

                % 统计豹子/非豹子的总权重（仅对合法组合计数）
                if isPairX
                    farmerTotalPairWeight(1) = farmerTotalPairWeight(1) + w;
                else
                    farmerTotalNonPairWeight(1) = farmerTotalNonPairWeight(1) + w;
                end
                if isPairY
                    farmerTotalPairWeight(2) = farmerTotalPairWeight(2) + w;
                else
                    farmerTotalNonPairWeight(2) = farmerTotalNonPairWeight(2) + w;
                end
                if isPairZ
                    farmerTotalPairWeight(3) = farmerTotalPairWeight(3) + w;
                else
                    farmerTotalNonPairWeight(3) = farmerTotalNonPairWeight(3) + w;
                end

                % 判断每个农民是否战胜地主（点数更大，平局地主胜）
                % 规则：点数比较，点数相同时地主胜
                winX = (pX > pM);
                winY = (pY > pM);
                winZ = (pZ > pM);

                if winX
                    farmerWinWeight(1) = farmerWinWeight(1) + w;
                    if isPairX
                        farmerWinPairWeight(1) = farmerWinPairWeight(1) + w;
                    else
                        farmerWinNonPairWeight(1) = farmerWinNonPairWeight(1) + w;
                    end
                end
                if winY
                    farmerWinWeight(2) = farmerWinWeight(2) + w;
                    if isPairY
                        farmerWinPairWeight(2) = farmerWinPairWeight(2) + w;
                    else
                        farmerWinNonPairWeight(2) = farmerWinNonPairWeight(2) + w;
                    end
                end
                if winZ
                    farmerWinWeight(3) = farmerWinWeight(3) + w;
                    if isPairZ
                        farmerWinPairWeight(3) = farmerWinPairWeight(3) + w;
                    else
                        farmerWinNonPairWeight(3) = farmerWinNonPairWeight(3) + w;
                    end
                end

                % 构造联合状态并累计联合权重：-1 表示输，1 表示赢但非豹子，2 表示赢且为豹子
                if winX
                    if isPairX
                        sx = 2;
                    else
                        sx = 1;
                    end
                else
                    sx = -1;
                end
                if winY
                    if isPairY
                        sy = 2;
                    else
                        sy = 1;
                    end
                else
                    sy = -1;
                end
                if winZ
                    if isPairZ
                        sz = 2;
                    else
                        sz = 1;
                    end
                else
                    sz = -1;
                end

                % map (-1,1,2) -> 1..3
                pos = @(v) (v==-1)*1 + (v==1)*2 + (v==2)*3;
                pi1 = pos(sx); pj = pos(sy); pk = pos(sz);
                ind = (pi1-1)*9 + (pj-1)*3 + pk;
                jRow(ind) = jRow(ind) + w;

                nWinners = winX + winY + winZ;
                if nWinners >= 2
                    twoFarmersWinWeight = twoFarmersWinWeight + w;
                end
                if nWinners == 3
                    threeFarmersWinWeight = threeFarmersWinWeight + w;
                end

            end
        end
    end
end

% 验证权重和是否等于总发牌数
fprintf('Total weight sum = %.0f\n', totalWeight);
fprintf('TotalDeals = %.0f\n', totalDeals);
if abs(totalWeight - totalDeals) > 1e-6 * totalDeals
    warning('权重和与总发牌数不匹配，可能存在错误或浮点精度问题。');
end

% 计算概率
prob_farmer = farmerWinWeight / totalDeals;
prob_two = twoFarmersWinWeight / totalDeals;
prob_three = threeFarmersWinWeight / totalDeals;

% 输出结果
fprintf('第一回合精确概率（按点数组合权重）:\n');
fprintf(' 农民 X 胜率 = %.12f, 期望收益 = %.6f\n', prob_farmer(1), (2*farmerWinNonPairWeight(1)/totalDeals)+3*farmerWinPairWeight(1)/totalDeals-1);
fprintf(' 农民 Y 胜率 = %.12f, 期望收益 = %.6f\n', prob_farmer(2), 2*farmerWinNonPairWeight(2)/totalDeals+3*farmerWinPairWeight(2)/totalDeals-1);
fprintf(' 农民 Z 胜率 = %.12f, 期望收益 = %.6f\n', prob_farmer(3), 2*farmerWinNonPairWeight(3)/totalDeals+3*farmerWinPairWeight(3)/totalDeals-1);
fprintf(' 二门（>=2农民胜）概率 = %.12f, 期望收益 = %.6f\n', prob_two, 2*twoFarmersWinWeight / totalDeals - 1);
fprintf(' 黑子（3农民全胜）概率 = %.12f, 期望收益 = %.6f\n', prob_three, 4*threeFarmersWinWeight / totalDeals - 1);

% 输出豹子/非豹子条件胜率
fprintf('\n农民豹子/非豹子条件胜率（P(胜|类型)）：\n');
for k = 1:3
    if farmerTotalPairWeight(k) > 0
        pw_pair = farmerWinPairWeight(k) / farmerTotalPairWeight(k);
    else
        pw_pair = NaN;
    end
    if farmerTotalNonPairWeight(k) > 0
        pw_nonpair = farmerWinNonPairWeight(k) / farmerTotalNonPairWeight(k);
    else
        pw_nonpair = NaN;
    end
    fprintf(' 农民 %d: P(胜|豹子) = %.12f, P(胜|非豹子) = %.12f\n', k, pw_pair, pw_nonpair);
end

% 打印胜利情况下豹子/非豹子的原始权重和占比
fprintf('\n豹子获胜局数 = [%.0f  %.0f  %.0f]\n', farmerWinPairWeight(1), farmerWinPairWeight(2), farmerWinPairWeight(3));
fprintf('非豹子获胜局数 = [%.0f  %.0f  %.0f]\n', farmerWinNonPairWeight(1), farmerWinNonPairWeight(2), farmerWinNonPairWeight(3));
fprintf('二门获胜局数 = %.0f\n', twoFarmersWinWeight);
fprintf('黑子获胜局数 = %.0f\n', threeFarmersWinWeight);
fprintf('\n胜利样本中豹子/非豹子占比（按权重）：\n');
for k = 1:3
    winSum = farmerWinPairWeight(k) + farmerWinNonPairWeight(k);
    if winSum > 0
        prop_pair = farmerWinPairWeight(k) / winSum;
        prop_nonpair = farmerWinNonPairWeight(k) / winSum;
    else
        prop_pair = NaN; prop_nonpair = NaN;
    end
    fprintf(' 农民 %d: 豹子占比 = %.12f, 非豹子占比 = %.12f\n', k, prop_pair, prop_nonpair);
end

% 计算每位农民的期望收益（对单注1单位）：
% 规则：非豹子获胜赔付1，豹子获胜赔付2，地主胜（包含平局）下注输1
prob_win_nonpair = farmerWinNonPairWeight / totalDeals;
prob_win_pair = farmerWinPairWeight / totalDeals;
prob_win = prob_win_nonpair + prob_win_pair;
prob_loss = 1 - prob_win;
% 期望值（单位：每押1）： EV = P_nonpair*1 + P_pair*2 - P_loss*1
ev_farmer = prob_win_nonpair + 2*prob_win_pair - prob_loss;

% 保存结果到 CSV
deck_state = '44444444';
T = table;

T.deck = {deck_state};
T.ev_farmer_X = ev_farmer(1);
T.winrate_X = prob_win(1);
T.nonpair_win_X = prob_win_nonpair(1);
T.pair_win_X = prob_win_pair(1);
T.twoFarmers = prob_two;
T.threeFarmers = prob_three;
% 添加联合分布列（条件于该剩余牌堆的概率），使用安全的列名 joint_m1_1_2 等
for k = 1:27
    col = jointColNames{k};
    T.(col) = jRow(k) / totalDeals;
end
T.prob_from_first = 1.0; % 第一回合初始状态，概率为1

T.farmerWinWeight_X = farmerWinWeight(1);
T.farmerWinWeight_Y = farmerWinWeight(2);
T.farmerWinWeight_Z = farmerWinWeight(3);
T.farmerWinNonPairWeight_X = farmerWinNonPairWeight(1);
T.farmerWinNonPairWeight_Y = farmerWinNonPairWeight(2);
T.farmerWinNonPairWeight_Z = farmerWinNonPairWeight(3);
T.farmerWinPairWeight_X = farmerWinPairWeight(1);
T.farmerWinPairWeight_Y = farmerWinPairWeight(2);
T.farmerWinPairWeight_Z = farmerWinPairWeight(3);
for k = 1:27
    colW = sprintf('%s_Weight', jointLabels{k});
    T.(colW) = jRow(k);
end
T.totalDeals = totalDeals;

outfn = fullfile(pwd, 'round1_results.csv');
writetable(T, outfn);
fprintf('\n结果已保存到 %s\n', outfn);