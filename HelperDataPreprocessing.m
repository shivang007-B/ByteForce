function data = HelperDataPreprocessing(data, options)
% HelperDataPreprocessing  Clean and feature-engineer the WiDS/ASHRAE
% building energy table before model training.
%
% SYNTAX
%   data = HelperDataPreprocessing(data)
%   data = HelperDataPreprocessing(data, options)
%
% INPUTS
%   data    - Raw table as returned by readtable on exampleTrain.csv
%             (or any compatible building energy CSV).
%   options - Struct with optional fields:
%       .TargetVar        Name of response column      ('OutputVar')
%       .RemoveCellCols   Drop cell/string columns      (false)
%       .OutlierMethod    'iqr' | 'zscore' | 'none'    ('iqr')
%       .IQRMultiplier    Fence multiplier for IQR      (3.0)
%       .ZScoreThresh     Threshold when method=zscore  (4.0)
%       .ImputeMethod     'median' | 'mean'             ('median')
%       .Verbose          Print progress                (true)
%
% OUTPUT
%   data - Cleaned table with imputed values and (where applicable)
%          engineered features added.

if nargin < 2 || isempty(options), options = struct(); end
options = defopt(options, 'TargetVar',      'OutputVar');
options = defopt(options, 'RemoveCellCols', false);
options = defopt(options, 'OutlierMethod',  'iqr');
options = defopt(options, 'IQRMultiplier',  3.0);
options = defopt(options, 'ZScoreThresh',   4.0);
options = defopt(options, 'ImputeMethod',   'median');
options = defopt(options, 'Verbose',        true);

vlog   = @(fmt,varargin) vprintf(options.Verbose, fmt, varargin{:});
target = options.TargetVar;

vlog('=== Data Preprocessing ===\n');
vlog('Input : %d rows x %d columns\n', height(data), width(data));

%% 1. Remove exact duplicate rows
nBefore = height(data);
[~, ui] = unique(table2array(varfun(@(x) ...
    string(x), data, 'OutputFormat','table')), 'rows', 'stable');
data = data(ui, :);
vlog('Duplicate rows removed : %d\n', nBefore - height(data));

%% 2. Identify column types
cols       = data.Properties.VariableNames;
isCellCol  = cellfun(@(c) iscell(data.(c)) || isstring(data.(c)), cols);
isNumCol   = cellfun(@(c) isnumeric(data.(c)),                    cols);
isTargetCol = strcmp(cols, target);

%% 3. Handle cell / categorical columns
if options.RemoveCellCols
    % Drop all non-numeric columns except target
    dropCols = cols(isCellCol & ~isTargetCol);
    if ~isempty(dropCols)
        data = removevars(data, dropCols);
        vlog('Removed %d non-numeric columns.\n', numel(dropCols));
    end
else
    % Convert cell columns to categorical (tree models handle these fine)
    cellCols = cols(isCellCol & ~isTargetCol);
    for c = 1:numel(cellCols)
        col = data.(cellCols{c});
        if iscell(col)
            % Replace empty / missing strings
            emptyMask = cellfun(@(x) isempty(x) || ...
                (ischar(x) && strcmpi(strtrim(x),'')), col);
            col(emptyMask) = {'Unknown'};
            data.(cellCols{c}) = categorical(col);
        elseif isstring(col)
            col(col == "" | ismissing(col)) = "Unknown";
            data.(cellCols{c}) = categorical(col);
        end
    end
    vlog('Converted %d text columns to categorical.\n', numel(cellCols));
end

%% 4. Drop rows with missing target
cols = data.Properties.VariableNames;   % refresh after possible removevars
if ismember(target, cols)
    missMask = isnan(data.(target));
    vlog('Rows with missing target (%s): %d  → removed\n', target, sum(missMask));
    data = data(~missMask, :);
end

%% 5. Outlier removal in target
if ismember(target, data.Properties.VariableNames)
    y = data.(target);
    switch lower(options.OutlierMethod)
        case 'iqr'
            q1 = prctile(y,25); q3 = prctile(y,75);
            fence = options.IQRMultiplier * (q3 - q1);
            badMask = y < (q1 - fence) | y > (q3 + fence);
        case 'zscore'
            z = (y - mean(y,'omitnan')) ./ (std(y,'omitnan') + eps);
            badMask = abs(z) > options.ZScoreThresh;
        otherwise
            badMask = false(height(data),1);
    end
    vlog('Outlier rows removed (%s method, target) : %d\n', ...
        options.OutlierMethod, sum(badMask));
    data = data(~badMask, :);
end

%% 6. Impute missing numeric features
cols    = data.Properties.VariableNames;
isNumC  = cellfun(@(c) isnumeric(data.(c)), cols);
nImputed = 0;
for c = 1:numel(cols)
    if ~isNumC(c) || strcmp(cols{c}, target), continue; end
    col   = data.(cols{c});
    nMiss = sum(isnan(col));
    if nMiss == 0, continue; end
    if strcmp(options.ImputeMethod, 'mean')
        fillVal = mean(col, 'omitnan');
    else
        fillVal = median(col, 'omitnan');
    end
    if isnan(fillVal), fillVal = 0; end
    col(isnan(col))  = fillVal;
    data.(cols{c})   = col;
    nImputed         = nImputed + nMiss;
end
vlog('Missing numeric values imputed (%s) : %d cells\n', ...
    options.ImputeMethod, nImputed);

%% 7. Target must be positive (EUI is always > 0)
if ismember(target, data.Properties.VariableNames)
    negMask = data.(target) <= 0;
    if any(negMask)
        vlog('Rows with non-positive target removed : %d\n', sum(negMask));
        data = data(~negMask, :);
    end
end

%% 8. Remove near-zero-variance columns (> 99% same value)
cols   = data.Properties.VariableNames;
isNumC = cellfun(@(c) isnumeric(data.(c)), cols);
dropNZV = {};
for c = 1:numel(cols)
    if ~isNumC(c) || strcmp(cols{c}, target), continue; end
    col = data.(cols{c});
    if numel(unique(col)) <= 1
        dropNZV{end+1} = cols{c}; %#ok<AGROW>
    elseif mode(col) == col(1)
        % More than 99% the same value
        modeCount = sum(col == mode(col));
        if modeCount / numel(col) > 0.99
            dropNZV{end+1} = cols{c}; %#ok<AGROW>
        end
    end
end
if ~isempty(dropNZV)
    data = removevars(data, dropNZV);
    vlog('Near-zero-variance columns removed : %d\n', numel(dropNZV));
end

vlog('Output: %d rows x %d columns\n', height(data), width(data));
vlog('=== Preprocessing complete ===\n\n');
end

%% -------------------------------------------------------------------
function s = defopt(s, f, v)
if ~isfield(s,f), s.(f) = v; end
end

function vprintf(verbose, fmt, varargin)
if verbose, fprintf(fmt, varargin{:}); end
end
