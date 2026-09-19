function compute_stds(fn)
% compute_stds  Add standard-deviation and Sharpe-ratio columns to a result CSV.
% Usage: compute_stds('round1_results.csv')
% 从 round1_results.csv 读取 joint_* 概率列，计算每行的 X 的标准差 和 (X+Y+Z)/3 的标准差
% 并将两列插入到 ev_farmer_X 之后，保存回 CSV

if nargin < 1 || strlength(string(fn)) == 0
    fn = 'round1_results.csv';
end
fn = fullfile(pwd, char(fn));
T = readtable(fn, 'VariableNamingRule', 'preserve');
vars = T.Properties.VariableNames;

% 找到 joint_* 概率列
jointCols = find(startsWith(vars, 'joint_'));
if isempty(jointCols)
    error('No joint_* columns found in %s', fn);
end

% 解析 joint 列名，提取每列的 X, Y, Z 值
jointNames = vars(jointCols);
m = numel(jointNames);
X = zeros(m,1); Y = zeros(m,1); Z = zeros(m,1);
for j = 1:m
    nm = jointNames{j};
    parts = split(nm, '_');
    valsToken = [];
    for t = 1:numel(parts)
        tok = parts{t};
        if strcmp(tok, 'm1')
            valsToken(end+1) = -1; %#ok<AGROW>
        elseif strcmp(tok, '1')
            valsToken(end+1) = 1; %#ok<AGROW>
        elseif strcmp(tok, '2')
            valsToken(end+1) = 2; %#ok<AGROW>
        end
    end
    if numel(valsToken) < 3
        error('Unable to parse joint column name: %s', nm);
    end
    % 使用最后三个 token 作为 X,Y,Z（与其它脚本解析方式一致）
    toks = valsToken(end-2:end);
    X(j) = toks(1); Y(j) = toks(2); Z(j) = toks(3);
    % fprintf('Parsed %d joint columns. Sample: %s -> X=%d, Y=%d, Z=%d\n', m, jointNames{j}, X(j), Y(j), Z(j));
end


% 读取概率矩阵（n x m）
P = table2array(T(:, jointCols));
P = double(P);
n = size(P,1);

% 归一化每行（若存在数值误差），并处理全零行
% rowsum = sum(P,2);
% Pnorm = zeros(size(P));
% idx = rowsum > 0;
% Pnorm(idx, :) = P(idx, :) ./ rowsum(idx);
Pnorm = P; % 先直接使用原始概率，后续可根据需要进行数值清理

% 计算 E[X], E[X^2] -> std(X)
Ex = Pnorm * X;           % n x 1
Ex2 = Pnorm * (X.^2);
varX = Ex2 - Ex.^2;
varX(varX < 0) = 0;       % 数值保护
std_X = sqrt(varX);

% 计算 S = X+Y+Z，(X+Y+Z)/3 的标准差
S = X + Y + Z;
Es = Pnorm * S;
Es2 = Pnorm * (S.^2);
varS = Es2 - Es.^2;
varS(varS < 0) = 0;
std_S = sqrt(varS);
std_XYZ = std_S / 3;
fprintf('Ex = %.4f, Es/3 = %.4f, std_X = %.4f, std_XYZ = %.4f\n', Ex(1), Es(1)/3, std_X(1), std_XYZ(1));

% 计算 Sharpe 比（以无风险利率 0 为基准）：Sharpe = E[return] / std(return)
% 对于 X，期望为 Ex；对于 (X+Y+Z)/3，期望为 Es/3
sharpe_X = zeros(n,1);
sharpe_XYZ = zeros(n,1);
% 防止除以 0
nonzero = std_X > 0;
sharpe_X(nonzero) = Ex(nonzero) ./ std_X(nonzero);
nonzero2 = std_XYZ > 0;
sharpe_XYZ(nonzero2) = (Es(nonzero2) ./ 3) ./ std_XYZ(nonzero2);

% 准备插入表格：列名为 std_X 和 std_XYZ，放在 ev_farmer_X 之后
% 如果已有相同列，先移除
if ismember('std_X', vars)
    T.std_X = [];
end
if ismember('std_XYZ', vars)
    T.std_XYZ = [];
end
if ismember('sharpe_X', vars)
    T.sharpe_X = [];
end
if ismember('sharpe_XYZ', vars)
    T.sharpe_XYZ = [];
end

if any(strcmp(vars, 'ev_farmer_X'))
    % 插入到 ev_farmer_X 之后：先 std，再 sharpe
    T = addvars(T, std_X, 'After', 'ev_farmer_X', 'NewVariableNames', 'std_X');
    T = addvars(T, std_XYZ, 'After', 'std_X', 'NewVariableNames', 'std_XYZ');
    T = addvars(T, sharpe_X, 'After', 'std_XYZ', 'NewVariableNames', 'sharpe_X');
    T = addvars(T, sharpe_XYZ, 'After', 'sharpe_X', 'NewVariableNames', 'sharpe_XYZ');
else
    % 如果没有 ev_farmer_X，则追加到末尾
    T.std_X = std_X;
    T.std_XYZ = std_XYZ;
    T.sharpe_X = sharpe_X;
    T.sharpe_XYZ = sharpe_XYZ;
end

% 保存回 CSV
writetable(T, fn);
fprintf('Wrote std_X and std_XYZ into %s (inserted after ev_farmer_X when present)\n', fn);
end
