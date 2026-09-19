function kelly_ratio(fn)
% kelly_ratio  Add equal-stake Kelly strategy columns to a result CSV.
% 读取 round1_results.csv，根据三门联合分布计算最优凯利下注比例 f
% 目标：最大化 E[ log(1 + f*X + f*Y + f*Z) ]，其中 X,Y,Z 的取值为 {-1,1,2}
% 运行：在 MATLAB 中切换到脚本目录，运行： kelly_ratio

if nargin < 1 || strlength(string(fn)) == 0
    fn = 'round1_results.csv';
end
fn = fullfile(pwd, char(fn));
T = readtable(fn, 'VariableNamingRule', 'preserve');
vars = T.Properties.VariableNames;

% 找到 joint_* 概率列（不包含 Weight）
jointCols = startsWith(vars, 'joint_');
jointCols = find(jointCols);
if isempty(jointCols)
    error('No joint_* columns found in %s', fn);
end

% 解析 joint_* 列名以构造每列对应的 X+Y+Z 值（更稳健，避免假设列数27）
jointNames = vars(jointCols);
m = numel(jointNames);
sumR = zeros(m,1);
for j = 1:m
    nm = jointNames{j};
    parts = split(nm, '_');
    % 找到代表 X,Y,Z 的 token（'m1' -> -1, '1' -> 1, '2' -> 2）
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
    sumR(j) = sum(valsToken(end-2:end));
    % fprintf('Parsed %s: sumR=%d\n', nm, sumR(j));
end

n = height(T);
kelly_f = zeros(n,1);
kelly_log_growth = zeros(n,1);
kelly_growth = zeros(n,1);
negG_root = zeros(n,1);

LB = 0; UB = 0.33;
% safety margin
epsb = 1e-12;
LB = LB + epsb; UB = UB - epsb;

for i = 1:n
    p = table2array(T(i, jointCols));
    p = p(:); % column vector
    % % numerical cleanup
    % p(p<0) = 0;
    % if sum(p) > 0
    %     p = p / sum(p);
    % end

    % feasible domain: require 1 + f * sumR(k) > 0 for all k with p(k)>0
    active = p > 0;
    s_active = sumR(active);
    % fprintf('Row %d: active outcomes=%d, s_active=[%s]\n', i, sum(active), num2str(s_active'));

    % 如果该行的期望收益为负（ev_farmer_X < 0），则跳过计算并置为0
    if any(strcmp(vars, 'ev_farmer_X')) && T.ev_farmer_X(i) < 0
        continue;
    end

    % compute initial guess x0 from CSV if available: ev_farmer_X / std_XYZ^2
    if ismember('std_XYZ', vars) && ismember('ev_farmer_X', vars) && isfinite(T.std_XYZ(i)) && T.std_XYZ(i) > 0
        x0 = T.ev_farmer_X(i) / (T.std_XYZ(i)^2);
    else
        x0 = (LB + UB) / 2;
    end
    % project x0 into feasible [LB,UB]
    x0 = min(max(x0, LB), UB);
    % fprintf('Row %d: init x0=%.6f (from ev/std projection), domain [%.6g, %.6g]\n', i, x0, LB, UB);

    % refine using Newton's method (maximize G) with projection to [a,b]
    % G(f) = sum p .* log(1 + f*s), G' = sum p .* s./(1+f*s), G'' = -sum p .* s.^2./(1+f*s).^2
    fcur = x0;
    maxNewton = 50;
    tolG = 1e-10;
    success = false;
    for nit = 1:maxNewton
        denom = 1 + fcur .* s_active;
        if any(denom <= 0)
            break;
        end
        gG = sum(p(active) .* (s_active ./ denom));
        H = -sum(p(active) .* ((s_active.^2) ./ (denom.^2)));
        if ~isfinite(gG) || ~isfinite(H)
            break;
        end
        if abs(gG) < tolG
            success = true; break;
        end
        if H == 0
            % fallback to gradient step
            delta = sign(gG) * min(1e-3, UB-LB);
        else
            delta = - gG / H; % Newton step (H<0 for concave G)
        end
        % damp and project to keep in domain and within [LB,UB]
        alpha = 1.0;
        ftrial = fcur + alpha * delta;
        % backtracking: reduce alpha until feasible and objective improves
        Gold = sum(p(active) .* log1p(fcur .* s_active));
        while true
            ftrial = min(max(ftrial, LB), UB);
            if any(1 + ftrial .* s_active <= 0)
                alpha = alpha * 0.5;
                if alpha < 1e-12, break; end
                ftrial = fcur + alpha * delta; continue;
            end
            Gtrial = sum(p(active) .* log1p(ftrial .* s_active));
            if Gtrial >= Gold || alpha < 1e-12
                break;
            else
                alpha = alpha * 0.5;
                ftrial = fcur + alpha * delta;
            end
        end
        if alpha < 1e-12
            break;
        end
        % accept step
        if abs(ftrial - fcur) < 1e-12
            fcur = ftrial; success = true; break;
        end
        fcur = ftrial;
    end
    if success
        fopt = fcur;
    else
        % fallback to grid best
        fopt = x0;
    end

    % final check: if invalid, set 0
        % if ev_farmer_X < 0 then do not bet
        if any(strcmp(vars, 'ev_farmer_X'))
            if T.ev_farmer_X(i) < 0
                fopt = 0;
            end
        end
    if any(1 + fopt * s_active <= 0) || ~isfinite(fopt)
        fopt = 0;
    end
    kelly_f(i) = fopt;

    if fopt > 0
        safeNegG = @(f) (-sum(p(active) .* log1p(f .* s_active)));
        froot = fzero(safeNegG, [fopt, UB]);
    else
        froot = 0;
    end
    negG_root(i) = froot;
    % Geometric growth implied by the Kelly objective.
    if fopt == 0 || sum(p) == 0
        kelly_log_growth(i) = 0;
        kelly_growth(i) = 0;
    else
        logGrowth = sum(p(active) .* log1p(fopt .* s_active));
        kelly_log_growth(i) = logGrowth * 100;
        kelly_growth(i) = expm1(logGrowth) * 100;
    end
end

% 将结果写入表并保存为 CSV
% 若已存在旧的 kelly_f 列，先移除它
if ismember('kelly_f', T.Properties.VariableNames)
    T.kelly_f = [];
end
T = addvars(T, kelly_f, 'After', 'sharpe_XYZ', 'NewVariableNames', 'kelly_f');

% 插入 max_ratio 列，放在 kelly_f 之后
if ismember('max_ratio', T.Properties.VariableNames)
    T.max_ratio = [];
end
T = addvars(T, negG_root, 'After', 'kelly_f', 'NewVariableNames', 'max_ratio');

% 插入 kelly_growth 列，放在 max_ratio 之后
if ismember('kelly_log_growth', T.Properties.VariableNames)
    T.kelly_log_growth = [];
end
T = addvars(T, kelly_log_growth, 'After', 'max_ratio', 'NewVariableNames', 'kelly_log_growth');

if ismember('kelly_growth', T.Properties.VariableNames)
    T.kelly_growth = [];
end
T = addvars(T, kelly_growth, 'After', 'kelly_log_growth', 'NewVariableNames', 'kelly_growth');


writetable(T, fn);
fprintf('Wrote kelly_f and kelly_growth into %s (kelly_f as 3rd column)\n', fn);
end
