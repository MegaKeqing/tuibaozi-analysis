% merge_kelly_results.m
% 从 round1_results.csv..round4_results.csv 提取 `deck`,`ev_farmer_X`,`kelly_f` 并合并到 result.csv

files = {'round1_results.csv','round2_results.csv','round3_results.csv','round4_results.csv'};
outfn = fullfile(pwd, 'results.csv');
cols = {'deck','ev_farmer_X','kelly_f'};
merged = table();

for k = 1:numel(files)
    fn = fullfile(pwd, files{k});
    if ~isfile(fn)
        fprintf('Skipping missing file: %s\n', files{k});
        continue;
    end
    % Preserve deck leading zeros by forcing deck column to string if present
    try
        opts = detectImportOptions(fn, 'TextType', 'string');
        if ismember('deck', opts.VariableNames)
            opts = setvartype(opts, 'deck', 'string');
        end
        T = readtable(fn, opts);
    catch
        % fallback
        T = readtable(fn, 'VariableNamingRule', 'preserve', 'TextType', 'string');
    end
    % prepare subtable with required columns; if 缺失则填充 NaN
    sub = table();
    for c = 1:numel(cols)
        name = cols{c};
        if ismember(name, T.Properties.VariableNames)
            sub.(name) = T.(name);
        else
            % create column of appropriate length filled with NaN
            n = height(T);
            sub.(name) = repmat(nan, n, 1);
        end
    end
    % 可选：保留来源信息
    % 规范 deck：如果存在则补齐为 8 位（保留前导零）
    if ismember('deck', sub.Properties.VariableNames)
        d = sub.deck;
        if ~isstring(d)
            d = string(d);
        end
        d = strtrim(d);
        for ii = 1:numel(d)
            if strlength(d(ii)) < 8
                d(ii) = pad(d(ii), 8, 'left', '0');
            end
        end
        sub.deck = d;
    end
    % sub.source_file = repmat(string(files{k}), height(sub), 1);
    merged = [merged; sub];
end

if isempty(merged)
    error('No input files found or all empty. Nothing to write.');
end

% 写出 CSV（包含 source_file 列）
writetable(merged, outfn);
fprintf('Wrote merged results to %s (rows=%d)\n', outfn, height(merged));
