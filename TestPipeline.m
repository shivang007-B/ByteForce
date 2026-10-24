%% TestPipeline.m
% Self-contained validation script for the CL-03 energy prediction project.
%
% HOW TO USE
%   >> TestPipeline
%
% Each test prints PASS or FAIL with a reason.
% A final summary shows how many tests passed out of the total.
% No external data files are needed — synthetic data is generated inline.

clear; clc;
addpath(pwd);

fprintf('=========================================================\n');
fprintf('  CL-03 Pipeline Test Suite\n');
fprintf('=========================================================\n\n');

passed = 0;
failed = 0;
failLog = {};

%% -----------------------------------------------------------------------
%  Helper: run a test and record result
%% -----------------------------------------------------------------------
    function runTest(name, testFcn)
        fprintf('%-55s', name);
        try
            msg = testFcn();
            if isempty(msg)
                fprintf('  PASS\n');
                passed = passed + 1;
            else
                fprintf('  FAIL  (%s)\n', msg);
                failed = failed + 1;
                failLog{end+1} = sprintf('%s: %s', name, msg);
            end
        catch ME
            fprintf('  FAIL  (ERROR: %s)\n', ME.message);
            failed = failed + 1;
            failLog{end+1} = sprintf('%s: %s', name, ME.message);
        end
    end

%% -----------------------------------------------------------------------
%  Build a small synthetic dataset used by all tests
%% -----------------------------------------------------------------------
rng(42);
n = 400;

% Numeric features
buildingAge  = randi([1,50], n, 1);
floorArea    = 200 + 3000*rand(n,1);
temperature  = -5 + 35*rand(n,1);
humidity     = 30 + 50*rand(n,1);
hvacEff      = 0.5 + 0.5*rand(n,1);
insulRating  = randi([1,10], n,1);
month        = randi([1,12], n,1);
hour         = randi([0,23], n,1);

% Categorical feature
bTypes      = {'Office','Residential','Retail','Industrial','Education'};
BuildingType = categorical(bTypes(randi(5,n,1))');

% Target: realistic energy model with noise
EUI = 50 + 0.3*buildingAge + 0.005*floorArea + ...
      max(0,temperature-18)*2 + max(0,15-temperature)*3 + ...
      -20*hvacEff - 3*insulRating + 8*randn(n,1);
EUI = max(EUI, 5);

% Introduce 5% missing target values (realistic)
EUI(rand(n,1) < 0.05) = NaN;

smallData = table(buildingAge, floorArea, temperature, humidity, ...
    hvacEff, insulRating, month, hour, BuildingType, EUI, ...
    'VariableNames', {'BuildingAge','FloorArea','Temperature','Humidity', ...
                      'HVACEff','InsulRating','Month','Hour', ...
                      'BuildingType','OutputVar'});

fprintf('Synthetic dataset: %d rows x %d cols\n\n', height(smallData), width(smallData));

%% -----------------------------------------------------------------------
%  TEST GROUP 1: HelperDataPreprocessing
%% -----------------------------------------------------------------------
fprintf('--- Group 1: HelperDataPreprocessing ---\n');

    runTest('Preprocessing runs without error', @() testPreprocessRuns(smallData));
    runTest('Missing target rows removed', @() testMissingTargetRemoved(smallData));
    runTest('Output is still a table', @() testOutputIsTable(smallData));
    runTest('No NaN in numeric columns after preprocess', @() testNoNaN(smallData));
    runTest('Row count reduced (outliers/missing removed)', @() testRowCountReduced(smallData));
    runTest('Categorical column preserved', @() testCatPreserved(smallData));

%% -----------------------------------------------------------------------
%  TEST GROUP 2: BuildingRegressionModels — structure
%% -----------------------------------------------------------------------
fprintf('\n--- Group 2: BuildingRegressionModels (structure) ---\n');

% Get clean data for model tests
preOpts.TargetVar = 'OutputVar';
preOpts.Verbose   = false;
cleanData = HelperDataPreprocessing(smallData, preOpts);

mdlOpts.TargetVar    = 'OutputVar';
mdlOpts.TestFraction = 0.25;
mdlOpts.CVFolds      = 3;
mdlOpts.NTreesRF     = 20;   % small for speed
mdlOpts.NTreesGB     = 20;
mdlOpts.LearnRateGB  = 0.1;
mdlOpts.RunSVR       = false;
mdlOpts.Verbose      = false;

[TM, R] = BuildingRegressionModels(cleanData, mdlOpts);

    runTest('Returns trainedModels struct', @() checkStruct(TM));
    runTest('Returns results struct',       @() checkStruct(R));
    runTest('At least 3 models trained',    @() checkMinModels(R, 3));
    runTest('results.modelNames populated', @() checkField(R,'modelNames'));
    runTest('results.testRMSE populated',   @() checkField(R,'testRMSE'));
    runTest('results.testR2 populated',     @() checkField(R,'testR2'));
    runTest('results.cvRMSE populated',     @() checkField(R,'cvRMSE'));
    runTest('results.bestModel set',        @() checkNonEmpty(R.bestModel));
    runTest('results.bestPredictions set',  @() checkField(R,'bestPredictions'));
    runTest('results.featureVars set',      @() checkField(R,'featureVars'));
    runTest('results.trainData set',        @() checkField(R,'trainData'));
    runTest('results.testData set',         @() checkField(R,'testData'));
    runTest('results.retrofit set',         @() checkField(R,'retrofit'));
    runTest('results.predictions struct',   @() checkField(R,'predictions'));

%% -----------------------------------------------------------------------
%  TEST GROUP 3: Model quality checks
%% -----------------------------------------------------------------------
fprintf('\n--- Group 3: Model quality ---\n');

    runTest('All testRMSE values are positive',  @() checkPositive(R.testRMSE));
    runTest('All testR2 values are in [0,1]',    @() checkR2Range(R.testR2));
    runTest('All cvRMSE values are positive',    @() checkPositive(R.cvRMSE));
    runTest('Train size + test size = total',    @() checkSplitSum(R, height(cleanData)));
    runTest('Best model has lowest testRMSE',    @() checkBestModel(R));
    runTest('Predictions length = test size',    @() checkPredLen(R));
    runTest('No NaN in bestPredictions',         @() checkNoNaN(R.bestPredictions));
    runTest('Test RMSE < 3x target std (sanity)',@() checkRMSESanity(R, cleanData));

%% -----------------------------------------------------------------------
%  TEST GROUP 4: Random Forest specific
%% -----------------------------------------------------------------------
fprintf('\n--- Group 4: Random Forest ---\n');

    runTest('RandomForest trained',              @() checkFieldVal(TM,'RandomForest'));
    runTest('Feature importance exists (RF)',    @() checkFeatImp(R,'RandomForest'));
    runTest('Uncertainty struct exists',         @() checkField(R,'uncertainty'));
    runTest('RF coverage95 is in (0,1]',         @() checkCoverage(R));

%% -----------------------------------------------------------------------
%  TEST GROUP 5: Gradient Boosting
%% -----------------------------------------------------------------------
fprintf('\n--- Group 5: Gradient Boosting ---\n');

    runTest('GradientBoosting trained',          @() checkFieldVal(TM,'GradientBoosting'));
    runTest('Feature importance exists (GB)',    @() checkFeatImp(R,'GradientBoosting'));

%% -----------------------------------------------------------------------
%  TEST GROUP 6: Retrofit analysis
%% -----------------------------------------------------------------------
fprintf('\n--- Group 6: Retrofit analysis ---\n');

    runTest('retrofit.excessConsumption set',    @() checkField(R.retrofit,'excessConsumption'));
    runTest('retrofit.score set',               @() checkField(R.retrofit,'score'));
    runTest('retrofit.candidateFlag set',       @() checkField(R.retrofit,'candidateFlag'));
    runTest('nCandidates is non-negative',      @() checkNonNeg(R.retrofit.nCandidates));
    runTest('Excess length = test size',        @() checkExcLen(R));

retrofitTable = HelperRetrofitAnalysis(R, cleanData);
    runTest('HelperRetrofitAnalysis returns table',  @() checkIsTable(retrofitTable));
    runTest('retrofitTable has Rank column',         @() checkTableCol(retrofitTable,'Rank'));
    runTest('retrofitTable has ExcessEUI column',    @() checkTableCol(retrofitTable,'ExcessEUI'));
    runTest('retrofitTable has WasteSeverity column',@() checkTableCol(retrofitTable,'WasteSeverity'));
    runTest('retrofitTable rows = test size',        @() checkTableRows(retrofitTable, R.testSize));

%% -----------------------------------------------------------------------
%  TEST GROUP 7: Helper functions smoke tests
%% -----------------------------------------------------------------------
fprintf('\n--- Group 7: Helper functions ---\n');

    runTest('HelperAnalyzeResults runs without error', @() testAnalyze(R));
    runTest('HelperVisualize runs without error',      @() testVisualize(R, cleanData));

%% -----------------------------------------------------------------------
%  FINAL SUMMARY
%% -----------------------------------------------------------------------
total = passed + failed;
fprintf('\n=========================================================\n');
fprintf('  TEST RESULTS:  %d / %d passed\n', passed, total);
if failed == 0
    fprintf('  *** ALL TESTS PASSED — pipeline is working correctly ***\n');
else
    fprintf('  %d test(s) FAILED:\n', failed);
    for i = 1:numel(failLog)
        fprintf('    [%d] %s\n', i, failLog{i});
    end
end
fprintf('=========================================================\n');

% Close figures generated during visualise test
close all;


%% =======================================================================
%%  TEST IMPLEMENTATION FUNCTIONS
%% =======================================================================

function msg = testPreprocessRuns(data)
    opts.TargetVar = 'OutputVar'; opts.Verbose = false;
    out = HelperDataPreprocessing(data, opts);
    if istable(out) && height(out) > 0, msg = ''; else, msg = 'returned empty or non-table'; end
end

function msg = testMissingTargetRemoved(data)
    opts.TargetVar = 'OutputVar'; opts.Verbose = false;
    out = HelperDataPreprocessing(data, opts);
    if any(isnan(out.OutputVar)), msg = 'NaN still present in target';
    else, msg = ''; end
end

function msg = testOutputIsTable(data)
    opts.TargetVar = 'OutputVar'; opts.Verbose = false;
    out = HelperDataPreprocessing(data, opts);
    if istable(out), msg = ''; else, msg = 'not a table'; end
end

function msg = testNoNaN(data)
    opts.TargetVar = 'OutputVar'; opts.Verbose = false;
    out = HelperDataPreprocessing(data, opts);
    cols = out.Properties.VariableNames;
    for c = 1:numel(cols)
        col = out.(cols{c});
        if isnumeric(col) && any(isnan(col))
            msg = sprintf('NaN found in column %s', cols{c}); return
        end
    end
    msg = '';
end

function msg = testRowCountReduced(data)
    opts.TargetVar = 'OutputVar'; opts.Verbose = false;
    out = HelperDataPreprocessing(data, opts);
    if height(out) < height(data), msg = '';
    else, msg = 'row count not reduced (expected missing/outlier removal)'; end
end

function msg = testCatPreserved(data)
    opts.TargetVar = 'OutputVar'; opts.Verbose = false;
    out = HelperDataPreprocessing(data, opts);
    if ismember('BuildingType', out.Properties.VariableNames)
        if iscategorical(out.BuildingType), msg = '';
        else, msg = 'BuildingType not categorical'; end
    else
        msg = 'BuildingType column missing';
    end
end

function msg = checkStruct(s)
    if isstruct(s), msg = ''; else, msg = 'not a struct'; end
end

function msg = checkMinModels(R, minN)
    if numel(R.modelNames) >= minN, msg = '';
    else, msg = sprintf('only %d models trained', numel(R.modelNames)); end
end

function msg = checkField(s, f)
    if isfield(s, f), msg = ''; else, msg = sprintf('field .%s missing', f); end
end

function msg = checkNonEmpty(val)
    if ~isempty(val), msg = ''; else, msg = 'is empty'; end
end

function msg = checkPositive(vec)
    if all(vec(~isnan(vec)) > 0), msg = '';
    else, msg = 'contains non-positive values'; end
end

function msg = checkR2Range(vec)
    if all(vec(~isnan(vec)) >= 0 & vec(~isnan(vec)) <= 1), msg = '';
    else, msg = sprintf('R2 out of [0,1]: min=%.3f max=%.3f', min(vec), max(vec)); end
end

function msg = checkSplitSum(R, total)
    s = R.trainSize + R.testSize;
    if abs(s - total) <= 2, msg = '';   % allow ±2 for rounding
    else, msg = sprintf('train(%d)+test(%d)=%d != total(%d)', ...
        R.trainSize, R.testSize, s, total); end
end

function msg = checkBestModel(R)
    [~,bi] = min(R.testRMSE);
    if strcmp(R.bestModel, R.modelNames{bi}), msg = '';
    else, msg = sprintf('bestModel=%s but min RMSE is %s', ...
        R.bestModel, R.modelNames{bi}); end
end

function msg = checkPredLen(R)
    n = numel(R.bestPredictions);
    if n == R.testSize, msg = '';
    else, msg = sprintf('predictions length %d != testSize %d', n, R.testSize); end
end

function msg = checkNoNaN(vec)
    if ~any(isnan(vec)), msg = ''; else, msg = 'contains NaN'; end
end

function msg = checkRMSESanity(R, data)
    targetStd = std(data.(R.targetVar), 'omitnan');
    [~,bi] = min(R.testRMSE);
    if R.testRMSE(bi) < 3 * targetStd, msg = '';
    else, msg = sprintf('best RMSE=%.3f > 3x std=%.3f (model likely broken)', ...
        R.testRMSE(bi), targetStd); end
end

function msg = checkFieldVal(s, f)
    if isfield(s,f) && ~isempty(s.(f)), msg = '';
    else, msg = sprintf('field .%s missing or empty', f); end
end

function msg = checkFeatImp(R, mdlName)
    if isfield(R,'featureImportance') && isfield(R.featureImportance, mdlName)
        imp = R.featureImportance.(mdlName);
        if ~isempty(imp) && any(imp > 0), msg = '';
        else, msg = 'importance vector empty or all zero'; end
    else
        msg = sprintf('featureImportance.%s not found', mdlName);
    end
end

function msg = checkCoverage(R)
    if isfield(R,'uncertainty') && isfield(R.uncertainty,'RandomForest')
        c = R.uncertainty.RandomForest.coverage95;
        if c > 0 && c <= 1, msg = '';
        else, msg = sprintf('coverage95=%.3f out of (0,1]', c); end
    else
        msg = 'uncertainty.RandomForest not found';
    end
end

function msg = checkNonNeg(val)
    if val >= 0, msg = ''; else, msg = 'negative value'; end
end

function msg = checkExcLen(R)
    n = numel(R.retrofit.excessConsumption);
    if n == R.testSize, msg = '';
    else, msg = sprintf('excess length %d != testSize %d', n, R.testSize); end
end

function msg = checkIsTable(t)
    if istable(t) && height(t) > 0, msg = ''; else, msg = 'not a table or empty'; end
end

function msg = checkTableCol(t, col)
    if ismember(col, t.Properties.VariableNames), msg = '';
    else, msg = sprintf('column %s missing', col); end
end

function msg = checkTableRows(t, expected)
    if height(t) == expected, msg = '';
    else, msg = sprintf('has %d rows, expected %d', height(t), expected); end
end

function msg = testAnalyze(R)
    HelperAnalyzeResults(R);
    msg = '';
end

function msg = testVisualize(R, data)
    HelperVisualize(R, data);
    msg = '';
end
