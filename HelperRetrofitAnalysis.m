function retrofitTable = HelperRetrofitAnalysis(results, data)
% HelperRetrofitAnalysis  Identify and rank buildings by energy waste.
%
% A building that consumes MORE than the model predicts — given its size,
% age, and weather context — is likely wasting energy through poor
% insulation, inefficient HVAC, or operational issues. This function ranks
% test buildings by that excess and provides a printable summary.
%
% SYNTAX
%   retrofitTable = HelperRetrofitAnalysis(results, data)
%
% INPUTS
%   results - Struct from BuildingRegressionModels
%   data    - Full dataset table (used for context columns)
%
% OUTPUT
%   retrofitTable - Table with one row per test building, columns:
%       Rank, SampleIdx, ActualEUI, PredictedEUI, ExcessEUI,
%       ExcessPercent, WasteSeverity, PotentialSaving, EUIpercentile

sep = repmat('=',1,72);
fprintf('\n%s\n', sep);
fprintf('  RETROFIT CANDIDATE ANALYSIS\n');
fprintf('%s\n', sep);

if ~isfield(results,'retrofit')
    warning('HelperRetrofitAnalysis: no retrofit data in results.'); 
    retrofitTable = table(); return
end

r          = results.retrofit;
testActual = results.testData.(results.targetVar);
bestPreds  = results.bestPredictions;
n          = numel(testActual);

exc        = r.excessConsumption;    % actual - predicted
excPct     = r.excessPercent;
score      = r.score;                % z-score of excess

%% Waste severity classification
severity = repmat({'Low'},    n, 1);
severity(score > 0.5  & score <= 1.5) = {'Medium'};
severity(score > 1.5  & score <= 2.5) = {'High'};
severity(score > 2.5)                 = {'Critical'};

%% EUI percentile within test set
[~, rankOrder]  = sort(testActual,'descend');
pctRank         = zeros(n,1);
for i = 1:n
    pctRank(rankOrder(i)) = round(100*(i-1)/(n-1));
end
pctRank = 100 - pctRank;   % 100 = highest consumer

%% Potential saving = positive excess only
potSaving = max(0, exc);

%% Build output table (sorted by excess descending)
[~, ri] = sort(exc,'descend');
retrofitTable = table( ...
    (1:n)', ...
    (ri), ...
    testActual(ri), ...
    bestPreds(ri), ...
    exc(ri), ...
    excPct(ri), ...
    severity(ri), ...
    potSaving(ri), ...
    pctRank(ri), ...
    'VariableNames', {'Rank','SampleIdx','ActualEUI','PredictedEUI', ...
                      'ExcessEUI','ExcessPercent','WasteSeverity', ...
                      'PotentialSaving','EUIpercentile'});

%% Print summary
fprintf('\nTest set: %d buildings  |  Model: %s\n', n, results.bestModel);
[~,bi] = strcmp(results.modelNames, results.bestModel);
fprintf('Model test R2: %.4f  |  Test RMSE: %.3f\n\n', ...
    results.testR2(find(strcmp(results.modelNames,results.bestModel))), ...
    results.testRMSE(find(strcmp(results.modelNames,results.bestModel))));

fprintf('Waste severity breakdown:\n');
for sv = {'Critical','High','Medium','Low'}
    cnt = sum(strcmp(retrofitTable.WasteSeverity, sv{1}));
    bar_s = repmat('*', 1, max(1,round(20*cnt/n)));
    fprintf('  %-10s : %4d  (%.1f%%)  %s\n', sv{1}, cnt, 100*cnt/n, bar_s);
end

fprintf('\nTop 15 retrofit candidates:\n');
fprintf('%-5s %-9s %-12s %-12s %-11s %-9s %-10s\n', ...
    'Rank','Idx','Actual EUI','Pred EUI','Excess EUI','Excess%%','Severity');
fprintf('%s\n', repmat('-',1,68));
for i = 1:min(15, height(retrofitTable))
    row = retrofitTable(i,:);
    fprintf('%-5d %-9d %-12.2f %-12.2f %-11.2f %-9.1f %-10s\n', ...
        row.Rank, row.SampleIdx, row.ActualEUI, row.PredictedEUI, ...
        row.ExcessEUI, row.ExcessPercent, row.WasteSeverity{1});
end

fprintf('\nTotal potential savings (test set) : %.2f EUI units\n', ...
    sum(retrofitTable.PotentialSaving));
fprintf('Average saving per Critical/High   : %.2f EUI units\n', ...
    mean(retrofitTable.PotentialSaving( ...
        strcmp(retrofitTable.WasteSeverity,'Critical') | ...
        strcmp(retrofitTable.WasteSeverity,'High'))));

fprintf('\nInterpretation:\n');
fprintf('  Excess EUI = Actual EUI - Predicted EUI\n');
fprintf('  Positive excess means the building uses MORE energy than\n');
fprintf('  expected given its characteristics and local weather.\n');
fprintf('  These buildings are strong candidates for retrofitting.\n');
fprintf('%s\n\n', sep);
end
