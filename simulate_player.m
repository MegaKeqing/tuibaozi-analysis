% simulate_player.m
% 蒙特卡洛模拟下注者行为
% 使用方法：在 MATLAB 中运行： simulate_player(Nsim, Nrounds, seed)
% 参数：Nsim（可选，默认 1e6），Nrounds（可选，默认 1），seed（可选，默认 1）
% 输出：final_wealth_counts.csv, final_wealth_stats.csv, final_wealth_hist10.csv, final_wealth_pdf.png

function simulate_player(Nsim, Nrounds, seed)
if nargin < 1, Nsim = 1e6; end % 模拟次数
if nargin < 2, Nrounds = 1; end % 轮数
if nargin < 3 || isempty(seed), seed = 1; end % 固定随机种子，便于复现
Nsim = double(Nsim);
rng(seed, 'twister');
% start timer
tStart = tic;

% 参数
W0 = 300;      % 初始资金
MIN_BANKRUPT = 30; % 小于则退出
MAX_BET = 10;  % 每次下注最大整数
subPerRound = 4; % 每轮内回合数

% 读入合并结果（包含 deck, kelly_f, source_file）
R = readtable('results.csv', 'TextType', 'string', 'VariableNamingRule', 'preserve');
nr = height(R);
if nr == 0
    error('results.csv empty');
end

% 不再依赖原始 round 文件：每轮初始化标准牌堆（8 种点数，各 4 张，共 32 张）
% 牌点用 1..8（与之前的 deck 字符串长度 8 对应）。初始牌堆为四份每种点数
initDeck = repmat((1:8)', 4, 1); % 列表形式，共 32 张

% 将 result.csv 中的 kelly_f mapping 为一个容器：deckKey -> f
fmap = containers.Map();
for i = 1:nr
    raw = string(R.deck(i));
    raw = strtrim(raw);
    % remove any non-digit characters and pad to 8 digits
    raw = regexprep(raw, '\D', '');
    if strlength(raw) < 8
        raw = pad(raw, 8, 'left', '0');
    end
    key = char(raw);
    if ismember('kelly_f', R.Properties.VariableNames) && ~isnan(R.kelly_f(i))
        fmap(key) = double(R.kelly_f(i));
    else
        fmap(key) = 0;
    end
end

% 分批模拟以节省内存
batch = 1e4; % 可调整
nBatches = ceil(Nsim / batch);
finalW = zeros(Nsim,1);
idxOut = 1;
for b = 1:nBatches
    nb = min(batch, Nsim - (b-1)*batch);
    for t = 1:nb
        W = W0;
        isBankrupt = false;
        % 每个 simulation 进行 Nrounds 轮，每轮开始初始化牌堆
        for rnum = 1:Nrounds
            deck = initDeck(randperm(numel(initDeck))); % shuffle
            pos = 1; % next card index
            for sub = 1:subPerRound
                %% 若剩余牌不足 8 张，则重新洗牌
                if numel(deck) - pos + 1 < 8
                    error('Not enough cards remaining for a new round.');
                end
                %% 构造当前牌堆 key：统计各点数余量（1..8），生成 8 位字符串
                counts = histcounts([deck(pos:end)], 0.5:1:8.5); % remaining counts
                % include remaining cards in counts; if pos>numel deck, counts zeros
                if isempty(counts), counts = zeros(1,8); end
                % Build the eight-digit lookup key without spaces.
                key = strjoin(arrayfun(@num2str, counts, 'UniformOutput', false),'');
                % lookup kelly f
                if isKey(fmap, key)
                    f = fmap(key);
                else
                    error('Deck key not found in fmap: %s', key);
                end

                %% 下注并结算：player 对三位农民各下注相同金额
                % bet = floor(f * W);
                bet = round(f * W, 0); % 四舍五入到整数
                bet = min(max(bet, 0), MAX_BET);
                % 确保三笔注总额不超过当前资金
                if 3 * bet > floor(W)
                    bet = floor(W / 3);
                end
                %% 发牌：地主 + 三农民，每人 2 张，顺序固定
                cards = deck(pos:pos+7); pos = pos + 8;
                % 即使本局不下注，牌局仍然发生，牌堆状态必须推进。
                if bet <= 0, continue; end
                % assign
                landlord = cards(1:2);
                farmer1 = cards(3:4); % 我们把 player 作为 farmer1 (Farmer X)
                farmer2 = cards(5:6);
                farmer3 = cards(7:8);

                %% 计算点数（内联替代嵌套函数，避免 MATLAB 嵌套定义错误）
                if landlord(1) == landlord(2)
                    s_land = 10 + landlord(1);
                else
                    s_land = mod(landlord(1) + landlord(2), 10);
                end

                if farmer1(1) == farmer1(2)
                    s_far1 = 10 + farmer1(1);
                else
                    s_far1 = mod(farmer1(1) + farmer1(2), 10);
                end

                if farmer2(1) == farmer2(2)
                    s_far2 = 10 + farmer2(1);
                else
                    s_far2 = mod(farmer2(1) + farmer2(2), 10);
                end

                if farmer3(1) == farmer3(2)
                    s_far3 = 10 + farmer3(1);
                else
                    s_far3 = mod(farmer3(1) + farmer3(2), 10);
                end
                %% 对每个农民分别结算（平局庄家赢）
                if s_far1 > s_land
                    % 若为豹子（两张牌相同），胜利支付双倍
                    if farmer1(1) == farmer1(2)
                        W = W + 2 * bet;
                    else
                        W = W + bet;
                    end
                else
                    W = W - bet;
                end
                if s_far2 > s_land
                    if farmer2(1) == farmer2(2)
                        W = W + 2 * bet;
                    else
                        W = W + bet;
                    end
                else
                    W = W - bet;
                end
                if s_far3 > s_land
                    if farmer3(1) == farmer3(2)
                        W = W + 2 * bet;
                    else
                        W = W + bet;
                    end
                else
                    W = W - bet;
                end
                if W < MIN_BANKRUPT
                    isBankrupt = true;
                    break;
                end
            end
            if isBankrupt, break; end
        end
        finalW(idxOut) = W;
        idxOut = idxOut + 1;
    end
    elapsedBatch = toc(tStart);
    fprintf('Batch %d/%d done (simulated %d) — elapsed %.2f s\n', b, nBatches, idxOut-1, elapsedBatch);
end

% 统计离散最终资产：每个资产值对应玩家数量（整数资产）并保存为 CSV
finalW = floor(finalW(:));
minW = min(finalW);
maxW = max(finalW);
% 生成从 minW 到 maxW 的计数向量
countsVec = zeros(maxW - minW + 1, 1);
if ~isempty(finalW)
    idx = finalW - minW + 1;
    countsVec = accumarray(idx, 1, [numel(countsVec), 1]);
end
wealths = (minW:maxW)';
Tcounts = table(wealths, countsVec, 'VariableNames', {'wealth','count'});
writetable(Tcounts, 'final_wealth_counts.csv');
% 统计关键指标
meanW = mean(finalW);
bankruptCount = sum(finalW < MIN_BANKRUPT);
bankruptRatio = bankruptCount / Nsim;
profitCount = sum(finalW > W0);
profitRatio = profitCount / Nsim;

fprintf('Monte Carlo finished: %d sims.\n', Nsim);
fprintf('Mean final wealth: %.4f\n', meanW);
fprintf('Bankruptcy: %d (ratio=%.4f)\n', bankruptCount, bankruptRatio);
fprintf('Profit (> %d): %d (ratio=%.4f)\n', W0, profitCount, profitRatio);

% 保存统计到 CSV
% 记录耗时
elapsedSec = toc(tStart);
stats = table(Nsim, Nrounds, seed, W0, MIN_BANKRUPT, MAX_BET, subPerRound, meanW, bankruptCount, bankruptRatio, profitCount, profitRatio, elapsedSec, ...
    'VariableNames', {'Nsim','Nrounds','seed','initialWealth','bankruptThreshold','maxBet','subRounds','meanW','bankruptCount','bankruptRatio','profitCount','profitRatio','elapsedSec'});
writetable(stats, 'final_wealth_stats.csv');

% 以 bin 宽度 10 绘制并保存概率直方（并保存为 CSV）
binWidth = 10;
edges10 = minW:binWidth:(maxW + binWidth);
countsBin = histcounts(finalW, edges10);
probBin = countsBin / sum(countsBin);
binCenters = edges10(1:end-1) + binWidth/2;
Tbin = table(binCenters', countsBin', probBin', 'VariableNames', {'binCenter','count','probability'});
writetable(Tbin, 'final_wealth_hist10.csv');

hf = figure('Visible','off');
bar(binCenters, probBin, 'FaceColor',[0 0.4470 0.7410]);
xlabel('Final wealth (bin centers)'); ylabel('Probability');
title(sprintf('Final wealth distribution (N=%d) Mean=%.2f', Nsim, meanW));
grid on;
saveas(hf, 'final_wealth_pdf.png');
close(hf);

fprintf('Elapsed time: %.2f seconds\n', elapsedSec);
fprintf('Saved final_wealth_counts.csv, final_wealth_stats.csv, final_wealth_hist10.csv, final_wealth_pdf.png\n');
end
