%% TestPipeline.m
% Self-contained validation script for the CL-03 energy prediction project.
%
% HOW TO USE
%   >> TestPipeline
%
% Each test prints PASS or FAIL. Final summary shows total pass/fail count.
% No external data files needed — synthetic data is generated inline.

clear; clc;
addpath(pwd);

fprintf('=========================================================\n');
fprintf('  CL-03 Pipeline Test Suite\n');
fprintf('=========================================================\n\n');

%% -------------------------------------------------------------------
%  Build synthetic dataset used by all tests
%% -------------------------------------------------------------------
rng(42);
n = 400;

buildingAge  = randi([1,50], n, 1);
floorArea    = 200 + 3000*rand(n,1);
temperature  = -5 + 35*rand(n,1);
humidity     = 30 + 50*rand(n,1);
hvacEff      = 0.5 + 0.5*rand(n,1);
insulRating  = randi([1,10], n,1);
month        = randi([1,12], n,1);
hour         = randi([0,23], n,1);

bTypes       = {'Office','Residential','Retail','Industrial','Education'};
BuildingType = categorical(bTypes(randi(5,n,1))');

EUI = 50 + 0.3*buildingAge + 0.005*floorArea + ...
      max(0,temperature-18)*2 + max(0,15-temperature)*3 + ...
      -20*hvacEff - 3*insulRating + 8*randn(n,1);
EUI = max(EUI, 5);
EUI(rand(n,1) < 0.05) = NaN;   % 5% missing target

smallData = table(buildingAge, floorArea, temperature, humidity, ...
    hvacEff, insulRating, month, hour, BuildingType, EUI, ...
    'VariableNames', {'BuildingAge','FloorArea','Temperature','Humidity', ...
                      'HVACEff','InsulRating','Month','Hour', ...
                      'BuildingType','OutputVar'});

fprintf('Synthetic dataset: %d rows x %d cols\n\n', height(smallData), width(smallData));

%% -------------------------------------------------------------------
%  Shared options
%% -------------------------------------------------------------------
preOpts.TargetVar      = 'OutputVar';
preOpts.RemoveCellCols = false;
preOpts.OutlierMethod  = 'iqr';
preOpts.IQRMultiplier  = 3.0;
preOpts.ImputeMethod   = 'median';
preOpts.Verbose        = false;

mdlOpts.TargetVar    = 'OutputVar';
mdlOpts.TestFraction = 0.25;
mdlOpts.CVFolds      = 3;
mdlOpts.NTreesRF     = 20;
mdlOpts.NTreesGB     = 20;
mdlOpts.LearnRateGB  = 0.1;
mdlOpts.RunSVR       = false;
mdlOpts.Verbose      = false;

%% -------------------------------------------------------------------
%  Pre-run preprocessing and model training once (shared by all tests)
%% -------------------------------------------------------------------
cleanData = HelperDataPreprocessing(smallData, preOpts);
[TM, R]   = BuildingRegressionModels(cleanData, mdlOpts);

%% -------------------------------------------------------------------
%  Test runner — simple flat list, no nested functions
%% -------------------------------------------------------------------
passed  = 0;
failed  = 0;
failLog = {};

function recordResult(name, msg)
    % Not used — results accumulated directly below
end

% Macro: run one test, print result, accumulate counts
% (Implemented as a local function at the bottom of the file)

%% -------------------------------------------------------------------
%  GROUP 1: HelperDataPreprocessing
%% -------------------------------------------------------------------
fprintf('--- Group 1: HelperDataPreprocessing ---\n');

name = 'Preprocessing runs without error';
try
    out = HelperDataPreprocessing(smallData, preOpts);
    if istable(out) && height(out) > 0
        [passed, failed] = ok(name, passed, failed);
    else
        [passed, failed] = fail(name, 'returned empty or non-table', passed, failed, failLog);
        failLog{end+1} = name;
    end
catch ME
    [passed, failed] = fail(name, ME.message, passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'Missing target rows removed';
try
    out = HelperDataPreprocessing(smallData, preOpts);
    if any(isnan(out.OutputVar))
        [passed, failed] = fail(name, 'NaN still in target', passed, failed, failLog);
        failLog{end+1} = name;
    else
        [passed, failed] = ok(name, passed, failed);
    end
catch ME
    [passed, failed] = fail(name, ME.message, passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'Output is a table';
try
    out = HelperDataPreprocessing(smallData, preOpts);
    if istable(out)
        [passed, failed] = ok(name, passed, failed);
    else
        [passed, failed] = fail(name, 'not a table', passed, failed, failLog);
        failLog{end+1} = name;
    end
catch ME
    [passed, failed] = fail(name, ME.message, passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'No NaN in numeric columns after preprocessing';
try
    out  = HelperDataPreprocessing(smallData, preOpts);
    cols = out.Properties.VariableNames;
    nanFound = false; badCol = '';
    for ci = 1:numel(cols)
        col = out.(cols{ci});
        if isnumeric(col) && any(isnan(col))
            nanFound = true; badCol = cols{ci}; break
        end
    end
    if nanFound
        [passed, failed] = fail(name, ['NaN in ' badCol], passed, failed, failLog);
        failLog{end+1} = name;
    else
        [passed, failed] = ok(name, passed, failed);
    end
catch ME
    [passed, failed] = fail(name, ME.message, passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'Row count reduced (missing/outlier removal)';
try
    out = HelperDataPreprocessing(smallData, preOpts);
    if height(out) < height(smallData)
        [passed, failed] = ok(name, passed, failed);
    else
        [passed, failed] = fail(name, 'row count not reduced', passed, failed, failLog);
        failLog{end+1} = name;
    end
catch ME
    [passed, failed] = fail(name, ME.message, passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'Categorical column preserved';
try
    out = HelperDataPreprocessing(smallData, preOpts);
    if ismember('BuildingType', out.Properties.VariableNames) && ...
            iscategorical(out.BuildingType)
        [passed, failed] = ok(name, passed, failed);
    else
        [passed, failed] = fail(name, 'BuildingType missing or not categorical', passed, failed, failLog);
        failLog{end+1} = name;
    end
catch ME
    [passed, failed] = fail(name, ME.message, passed, failed, failLog);
    failLog{end+1} = name;
end

%% -------------------------------------------------------------------
%  GROUP 2: BuildingRegressionModels — structure
%% -------------------------------------------------------------------
fprintf('\n--- Group 2: BuildingRegressionModels structure ---\n');

name = 'Returns trainedModels struct';
if isstruct(TM)
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, 'not a struct', passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'Returns results struct';
if isstruct(R)
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, 'not a struct', passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'At least 3 models trained';
if numel(R.modelNames) >= 3
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, sprintf('only %d models', numel(R.modelNames)), passed, failed, failLog);
    failLog{end+1} = name;
end

fields_to_check = {'modelNames','testRMSE','testR2','cvRMSE', ...
    'bestModel','bestPredictions','featureVars','trainData','testData','retrofit','predictions'};
for fi = 1:numel(fields_to_check)
    fname = fields_to_check{fi};
    name  = ['results.' fname ' exists'];
    if isfield(R, fname)
        [passed, failed] = ok(name, passed, failed);
    else
        [passed, failed] = fail(name, 'field missing', passed, failed, failLog);
        failLog{end+1} = name;
    end
end

%% -------------------------------------------------------------------
%  GROUP 3: Model quality
%% -------------------------------------------------------------------
fprintf('\n--- Group 3: Model quality ---\n');

name = 'All testRMSE values are positive';
if all(R.testRMSE(~isnan(R.testRMSE)) > 0)
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, 'non-positive RMSE found', passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'All testR2 values in [0, 1]';
r2vals = R.testR2(~isnan(R.testR2));
if all(r2vals >= 0) && all(r2vals <= 1)
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, sprintf('range [%.2f, %.2f]', min(r2vals), max(r2vals)), passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'All cvRMSE values are positive';
if all(R.cvRMSE(~isnan(R.cvRMSE)) > 0)
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, 'non-positive CV RMSE', passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'Train size + test size matches total';
total = height(cleanData);
if abs((R.trainSize + R.testSize) - total) <= 2
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, sprintf('%d+%d != %d', R.trainSize, R.testSize, total), passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'bestModel has lowest testRMSE';
[~, bi] = min(R.testRMSE);
if strcmp(R.bestModel, R.modelNames{bi})
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, sprintf('bestModel=%s, min is %s', R.bestModel, R.modelNames{bi}), passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'bestPredictions length equals testSize';
if numel(R.bestPredictions) == R.testSize
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, sprintf('length %d != testSize %d', numel(R.bestPredictions), R.testSize), passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'No NaN in bestPredictions';
if ~any(isnan(R.bestPredictions))
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, 'NaN found in predictions', passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'Test RMSE < 3x target std (sanity check)';
targetStd = std(cleanData.(R.targetVar), 'omitnan');
[~, bii]  = min(R.testRMSE);
if R.testRMSE(bii) < 3 * targetStd
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, sprintf('RMSE=%.2f > 3xStd=%.2f', R.testRMSE(bii), 3*targetStd), passed, failed, failLog);
    failLog{end+1} = name;
end

%% -------------------------------------------------------------------
%  GROUP 4: Random Forest
%% -------------------------------------------------------------------
fprintf('\n--- Group 4: Random Forest ---\n');

name = 'RandomForest model trained';
if isfield(TM, 'RandomForest') && ~isempty(TM.RandomForest)
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, 'TM.RandomForest missing or empty', passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'Feature importance exists (RandomForest)';
if isfield(R, 'featureImportance') && isfield(R.featureImportance, 'RandomForest') && ...
        any(R.featureImportance.RandomForest > 0)
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, 'importance missing or all zero', passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'Uncertainty struct exists';
if isfield(R, 'uncertainty')
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, 'R.uncertainty missing', passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'RF coverage95 is in (0, 1]';
if isfield(R, 'uncertainty') && isfield(R.uncertainty, 'RandomForest')
    cov = R.uncertainty.RandomForest.coverage95;
    if cov > 0 && cov <= 1
        [passed, failed] = ok(name, passed, failed);
    else
        [passed, failed] = fail(name, sprintf('coverage=%.3f', cov), passed, failed, failLog);
        failLog{end+1} = name;
    end
else
    [passed, failed] = fail(name, 'uncertainty.RandomForest missing', passed, failed, failLog);
    failLog{end+1} = name;
end

%% -------------------------------------------------------------------
%  GROUP 5: Gradient Boosting
%% -------------------------------------------------------------------
fprintf('\n--- Group 5: Gradient Boosting ---\n');

name = 'GradientBoosting model trained';
if isfield(TM, 'GradientBoosting') && ~isempty(TM.GradientBoosting)
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, 'TM.GradientBoosting missing', passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'Feature importance exists (GradientBoosting)';
if isfield(R, 'featureImportance') && isfield(R.featureImportance, 'GradientBoosting') && ...
        any(R.featureImportance.GradientBoosting > 0)
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, 'importance missing or all zero', passed, failed, failLog);
    failLog{end+1} = name;
end

%% -------------------------------------------------------------------
%  GROUP 6: Retrofit analysis
%% -------------------------------------------------------------------
fprintf('\n--- Group 6: Retrofit analysis ---\n');

name = 'retrofit.excessConsumption exists';
if isfield(R.retrofit, 'excessConsumption')
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, 'field missing', passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'retrofit.score exists';
if isfield(R.retrofit, 'score')
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, 'field missing', passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'retrofit.candidateFlag exists';
if isfield(R.retrofit, 'candidateFlag')
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, 'field missing', passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'nCandidates is non-negative';
if isfield(R.retrofit, 'nCandidates') && R.retrofit.nCandidates >= 0
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, 'negative or missing', passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'excessConsumption length equals testSize';
if numel(R.retrofit.excessConsumption) == R.testSize
    [passed, failed] = ok(name, passed, failed);
else
    [passed, failed] = fail(name, sprintf('length %d != testSize %d', ...
        numel(R.retrofit.excessConsumption), R.testSize), passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'HelperRetrofitAnalysis returns a table';
try
    rt = HelperRetrofitAnalysis(R, cleanData);
    if istable(rt) && height(rt) > 0
        [passed, failed] = ok(name, passed, failed);
    else
        [passed, failed] = fail(name, 'empty or not a table', passed, failed, failLog);
        failLog{end+1} = name;
    end
catch ME
    [passed, failed] = fail(name, ME.message, passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'retrofitTable has required columns';
try
    rt   = HelperRetrofitAnalysis(R, cleanData);
    reqC = {'Rank','ExcessEUI','WasteSeverity','PotentialSaving'};
    miss = reqC(~ismember(reqC, rt.Properties.VariableNames));
    if isempty(miss)
        [passed, failed] = ok(name, passed, failed);
    else
        [passed, failed] = fail(name, ['missing: ' strjoin(miss,',')], passed, failed, failLog);
        failLog{end+1} = name;
    end
catch ME
    [passed, failed] = fail(name, ME.message, passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'retrofitTable rows equal testSize';
try
    rt = HelperRetrofitAnalysis(R, cleanData);
    if height(rt) == R.testSize
        [passed, failed] = ok(name, passed, failed);
    else
        [passed, failed] = fail(name, sprintf('%d rows != testSize %d', height(rt), R.testSize), passed, failed, failLog);
        failLog{end+1} = name;
    end
catch ME
    [passed, failed] = fail(name, ME.message, passed, failed, failLog);
    failLog{end+1} = name;
end

%% -------------------------------------------------------------------
%  GROUP 7: Helper functions smoke tests
%% -------------------------------------------------------------------
fprintf('\n--- Group 7: Helper functions ---\n');

name = 'HelperAnalyzeResults runs without error';
try
    HelperAnalyzeResults(R);
    [passed, failed] = ok(name, passed, failed);
catch ME
    [passed, failed] = fail(name, ME.message, passed, failed, failLog);
    failLog{end+1} = name;
end

name = 'HelperVisualize runs without error';
try
    HelperVisualize(R, cleanData);
    [passed, failed] = ok(name, passed, failed);
catch ME
    [passed, failed] = fail(name, ME.message, passed, failed, failLog);
    failLog{end+1} = name;
end

%% -------------------------------------------------------------------
%  FINAL SUMMARY
%% -------------------------------------------------------------------
total = passed + failed;
fprintf('\n=========================================================\n');
fprintf('  TEST RESULTS:  %d / %d passed\n', passed, total);
if failed == 0
    fprintf('  ALL TESTS PASSED — pipeline is working correctly\n');
else
    fprintf('  %d test(s) FAILED:\n', failed);
    for i = 1:numel(failLog)
        fprintf('    [%d] %s\n', i, failLog{i});
    end
end
fprintf('=========================================================\n');

close all;


%% ===================================================================
%%  LOCAL FUNCTIONS  (must be at the bottom of the script file)
%% ===================================================================

function [p, f] = ok(name, p, f)
    fprintf('  %-55s  PASS\n', name);
    p = p + 1;
end

function [p, f] = fail(name, reason, p, f, ~)
    fprintf('  %-55s  FAIL  (%s)\n', name, reason);
    f = f + 1;
end
