function [trainedModels, results] = BuildingRegressionModels(data, options)
% BuildingRegressionModels  Train and evaluate multiple regression models
% for building energy consumption prediction (CL-03 challenge).
%
% SYNTAX
%   [trainedModels, results] = BuildingRegressionModels(data)
%   [trainedModels, results] = BuildingRegressionModels(data, options)
%
% INPUTS
%   data    - Table produced by HelperDataPreprocessing.  Must contain the
%             column 'OutputVar' (site EUI, the prediction target).
%             Optional column 'BuildingID' enables building-level splits so
%             the model is tested on UNSEEN buildings (core challenge req.).
%
%   options - Struct with any of these fields (all have defaults):
%       .TargetVar      Column name of response          ('OutputVar')
%       .TestFraction   Fraction held out for test       (0.20)
%       .CVFolds        Number of cross-validation folds (5)
%       .NTreesRF       Trees in Random Forest           (100)
%       .NTreesGB       Boosting rounds for GBM          (100)
%       .LearnRateGB    GBM learning rate                (0.05)
%       .RunSVR         Include SVR (slow on large data) (false)
%       .Verbose        Print progress to console        (true)
%
% OUTPUTS
%   trainedModels - Struct; one field per model (e.g. .RandomForest)
%   results       - Struct with:
%       .modelNames, .trainRMSE/.testRMSE, .trainMAE/.testMAE,
%       .trainR2/.testR2, .cvRMSE/.cvRMSE_std
%       .predictions       - struct of per-model test predictions
%       .bestModel         - name of best model by test RMSE
%       .bestPredictions   - test predictions from best model
%       .featureImportance - importance scores + names
%       .uncertainty       - 95% prediction intervals (Random Forest)
%       .retrofit          - excess consumption scores per test sample
%       .featureVars       - feature column names used
%       .trainData/.testData, .trainModel/.testModel

%% 0. Default options
if nargin < 2 || isempty(options), options = struct(); end
options = defopt(options, 'TargetVar',    'OutputVar');
options = defopt(options, 'TestFraction', 0.20);
options = defopt(options, 'CVFolds',      5);
options = defopt(options, 'NTreesRF',     100);
options = defopt(options, 'NTreesGB',     100);
options = defopt(options, 'LearnRateGB',  0.05);
options = defopt(options, 'RunSVR',       false);
options = defopt(options, 'Verbose',      true);

vlog = @(fmt, varargin) vprintf(options.Verbose, fmt, varargin{:});
target = options.TargetVar;

%% 1. Validate
if ~istable(data)
    error('BuildingRegressionModels:badInput', 'data must be a MATLAB table.');
end
if ~ismember(target, data.Properties.VariableNames)
    error('BuildingRegressionModels:missingTarget', ...
          'Table must contain column ''%s''.', target);
end

% Drop rows where target is missing
missing_y = isnan(data.(target));
if any(missing_y)
    vlog('Dropping %d rows with missing %s.\n', sum(missing_y), target);
    data = data(~missing_y, :);
end

%% 2. Identify feature columns
allCols = data.Properties.VariableNames;

% Look for a building-ID column (building-level split > random split)
bidCol = '';
for c = allCols
    if any(strcmpi(c{1}, {'BuildingID','building_id','id','ID'}))
        bidCol = c{1};
        break;
    end
end
hasBID = ~isempty(bidCol);

% Feature columns = everything except target (and BuildingID)
featureVars = allCols(~strcmp(allCols, target));
if hasBID
    modelFeatureVars = featureVars(~strcmp(featureVars, bidCol));
else
    modelFeatureVars = featureVars;
end

%% 3. Train / test split
rng(42);
if hasBID
    vlog('Building-level split — no building appears in both train and test.\n');
    uBuildings = unique(data.(bidCol));
    nB         = numel(uBuildings);
    perm       = randperm(nB);
    nTest      = max(1, round(options.TestFraction * nB));
    testBld    = uBuildings(perm(1:nTest));
    testMask   = ismember(data.(bidCol), testBld);
else
    vlog('Random row-level split (no BuildingID column found).\n');
    n        = height(data);
    perm     = randperm(n);
    nTest    = round(options.TestFraction * n);
    testMask = false(n, 1);
    testMask(perm(1:nTest)) = true;
end

trainData = data(~testMask, :);
testData  = data( testMask, :);

% Subset to model features + target
trainModel = trainData(:, [modelFeatureVars, {target}]);
testModel  = testData( :, [modelFeatureVars, {target}]);

vlog('Train: %d rows  |  Test: %d rows\n', height(trainModel), height(testModel));

testActual = testModel.(target);

%% 4. Cross-validation fold assignment
K = options.CVFolds;
if hasBID
    % Building-level CV folds
    uTrain  = unique(trainData.(bidCol));
    nTrain  = numel(uTrain);
    bfolds  = mod(randperm(nTrain)-1, K) + 1;
    cvFolds = zeros(height(trainData), 1);
    for b = 1:nTrain
        cvFolds(ismember(trainData.(bidCol), uTrain(b))) = bfolds(b);
    end
    cvType = 'building-level';
else
    cvFolds = crossvalind('Kfold', height(trainData), K);
    cvType  = 'row-level';
end
vlog('CV: %d-fold %s\n', K, cvType);

%% 5. Initialise results struct
results = struct();
results.trainSize   = height(trainModel);
results.testSize    = height(testModel);
results.modelNames  = {};
results.trainRMSE   = []; results.testRMSE  = [];
results.trainMAE    = []; results.testMAE   = [];
results.trainR2     = []; results.testR2    = [];
results.cvRMSE      = []; results.cvRMSE_std = [];
results.featureVars = modelFeatureVars;
results.targetVar   = target;
results.trainData   = trainData;
results.testData    = testData;
results.trainModel  = trainModel;
results.testModel   = testModel;
results.predictions = struct();
results.cvResults   = struct();

trainedModels = struct();

%% ---------------------------------------------------------------
%  MODEL 1: Linear Regression
%% ---------------------------------------------------------------
vlog('\n[1/5] Linear Regression...\n');
try
    mdl_lr = fitlm(trainModel, target);
    trPred = predict(mdl_lr, trainModel);
    tePred = predict(mdl_lr, testModel);
    [trR, trM, trR2] = metrics(trainModel.(target), trPred);
    [teR, teM, teR2] = metrics(testActual, tePred);
    cv = cv_score(trainModel, target, 'LR', K, cvFolds);
    trainedModels.LinearRegression = mdl_lr;
    results = append_results(results, 'LinearRegression', trR,teR,trM,teM,trR2,teR2,cv);
    results.predictions.LinearRegression = tePred;
    vlog('  Train RMSE=%.3f  Test RMSE=%.3f  CV RMSE=%.3f±%.3f\n', trR,teR,mean(cv),std(cv));
catch ME
    warning('LinearRegression failed: %s', ME.message);
end

%% ---------------------------------------------------------------
%  MODEL 2: Decision Tree (pruned)
%% ---------------------------------------------------------------
vlog('\n[2/5] Decision Tree...\n');
try
    minLeaf = max(5, round(height(trainModel)*0.005));
    mdl_dt  = fitrtree(trainModel, target, ...
        'MinLeafSize', minLeaf, 'MaxNumSplits', 150, 'PruneCriterion','mse');
    mdl_dt  = prune(mdl_dt, 'Level', round(mdl_dt.PruneList(end)*0.25));
    trPred  = predict(mdl_dt, trainModel);
    tePred  = predict(mdl_dt, testModel);
    [trR,trM,trR2] = metrics(trainModel.(target), trPred);
    [teR,teM,teR2] = metrics(testActual, tePred);
    cv = cv_score(trainModel, target, 'DT', K, cvFolds);
    trainedModels.DecisionTree = mdl_dt;
    results = append_results(results,'DecisionTree',trR,teR,trM,teM,trR2,teR2,cv);
    results.predictions.DecisionTree = tePred;
    vlog('  Train RMSE=%.3f  Test RMSE=%.3f  CV RMSE=%.3f±%.3f\n', trR,teR,mean(cv),std(cv));
catch ME
    warning('DecisionTree failed: %s', ME.message);
end

%% ---------------------------------------------------------------
%  MODEL 3: Random Forest  +  Uncertainty Quantification
%% ---------------------------------------------------------------
vlog('\n[3/5] Random Forest (%d trees)...\n', options.NTreesRF);
try
    minLeafRF = max(3, round(height(trainModel)*0.002));
    mdl_rf = fitrensemble(trainModel, target, ...
        'Method',            'Bag', ...
        'NumLearningCycles', options.NTreesRF, ...
        'Learners',          templateTree('MinLeafSize', minLeafRF));

    trPred = predict(mdl_rf, trainModel);
    tePred = predict(mdl_rf, testModel);
    [trR,trM,trR2] = metrics(trainModel.(target), trPred);
    [teR,teM,teR2] = metrics(testActual, tePred);
    cv = cv_score(trainModel, target, 'RF', K, cvFolds, options.NTreesRF);

    trainedModels.RandomForest = mdl_rf;
    results = append_results(results,'RandomForest',trR,teR,trM,teM,trR2,teR2,cv);
    results.predictions.RandomForest = tePred;

    % --- Uncertainty: std across individual trees as proxy for CI ---
    try
        nTrees    = numel(mdl_rf.Trained);
        treeP     = zeros(height(testModel), nTrees);
        for t = 1:nTrees
            treeP(:,t) = predict(mdl_rf.Trained{t}, testModel);
        end
        pStd = std(treeP, 0, 2);
        lo95 = tePred - 1.96*pStd;
        hi95 = tePred + 1.96*pStd;
        coverage = mean((testActual >= lo95) & (testActual <= hi95));
        results.uncertainty.RandomForest.predStd   = pStd;
        results.uncertainty.RandomForest.lower95   = lo95;
        results.uncertainty.RandomForest.upper95   = hi95;
        results.uncertainty.RandomForest.coverage95 = coverage;
        vlog('  95%% interval coverage = %.1f%%\n', coverage*100);
    catch
        % uncertainty is optional; don't fail the whole model
    end

    % Feature importance
    imp = predictorImportance(mdl_rf);
    results.featureImportance.RandomForest      = imp;
    results.featureImportance.RandomForestNames = modelFeatureVars;

    vlog('  Train RMSE=%.3f  Test RMSE=%.3f  CV RMSE=%.3f±%.3f\n', trR,teR,mean(cv),std(cv));
catch ME
    warning('RandomForest failed: %s', ME.message);
end

%% ---------------------------------------------------------------
%  MODEL 4: Gradient Boosting (LSBoost)
%% ---------------------------------------------------------------
vlog('\n[4/5] Gradient Boosting (%d rounds, lr=%.3f)...\n', ...
    options.NTreesGB, options.LearnRateGB);
try
    mdl_gb = fitrensemble(trainModel, target, ...
        'Method',            'LSBoost', ...
        'NumLearningCycles', options.NTreesGB, ...
        'LearnRate',         options.LearnRateGB, ...
        'Learners',          templateTree('MaxNumSplits', 8, 'MinLeafSize', 5));

    trPred = predict(mdl_gb, trainModel);
    tePred = predict(mdl_gb, testModel);
    [trR,trM,trR2] = metrics(trainModel.(target), trPred);
    [teR,teM,teR2] = metrics(testActual, tePred);
    cv = cv_score(trainModel, target, 'GB', K, cvFolds, options.NTreesGB, options.LearnRateGB);

    trainedModels.GradientBoosting = mdl_gb;
    results = append_results(results,'GradientBoosting',trR,teR,trM,teM,trR2,teR2,cv);
    results.predictions.GradientBoosting = tePred;

    imp_gb = predictorImportance(mdl_gb);
    results.featureImportance.GradientBoosting      = imp_gb;
    results.featureImportance.GradientBoostingNames = modelFeatureVars;

    vlog('  Train RMSE=%.3f  Test RMSE=%.3f  CV RMSE=%.3f±%.3f\n', trR,teR,mean(cv),std(cv));
catch ME
    warning('GradientBoosting failed: %s', ME.message);
end

%% ---------------------------------------------------------------
%  MODEL 5: SVR  (optional)
%% ---------------------------------------------------------------
if options.RunSVR
    vlog('\n[5/5] Support Vector Regression...\n');
    try
        mdl_svr = fitrsvm(trainModel, target, ...
            'KernelFunction', 'rbf', ...
            'KernelScale',    'auto', ...
            'Standardize',    true, ...
            'BoxConstraint',  1, ...
            'Epsilon',        0.1);
        trPred = predict(mdl_svr, trainModel);
        tePred = predict(mdl_svr, testModel);
        [trR,trM,trR2] = metrics(trainModel.(target), trPred);
        [teR,teM,teR2] = metrics(testActual, tePred);
        cv = cv_score(trainModel, target, 'SVR', K, cvFolds);
        trainedModels.SVR = mdl_svr;
        results = append_results(results,'SVR',trR,teR,trM,teM,trR2,teR2,cv);
        results.predictions.SVR = tePred;
        vlog('  Train RMSE=%.3f  Test RMSE=%.3f  CV RMSE=%.3f±%.3f\n', trR,teR,mean(cv),std(cv));
    catch ME
        warning('SVR failed: %s', ME.message);
    end
else
    vlog('\n[5/5] SVR skipped (options.RunSVR=false).\n');
end

%% 6. Best model
[~, bi]           = min(results.testRMSE);
results.bestModel = results.modelNames{bi};
results.bestPredictions = results.predictions.(results.bestModel);

vlog('\nBest model: %s  (Test RMSE=%.3f, R2=%.4f)\n', ...
    results.bestModel, results.testRMSE(bi), results.testR2(bi));

%% 7. Retrofit / energy-waste scoring
results = retrofit_scores(results, testData, results.bestPredictions, testActual);

end  % ---- end main function ----


%% ===================================================================
%%  PRIVATE HELPER FUNCTIONS
%% ===================================================================

function [rmse, mae, r2] = metrics(actual, pred)
res  = actual(:) - pred(:);
rmse = sqrt(mean(res.^2));
mae  = mean(abs(res));
sst  = sum((actual(:) - mean(actual(:))).^2);
if sst == 0, r2 = 0; else, r2 = max(0, 1 - sum(res.^2)/sst); end
end

% -------------------------------------------------------------------
function results = append_results(results, name, trR,teR,trM,teM,trR2,teR2,cv)
results.modelNames{end+1}  = name;
results.trainRMSE(end+1)   = trR;
results.testRMSE(end+1)    = teR;
results.trainMAE(end+1)    = trM;
results.testMAE(end+1)     = teM;
results.trainR2(end+1)     = trR2;
results.testR2(end+1)      = teR2;
results.cvRMSE(end+1)      = mean(cv, 'omitnan');
results.cvRMSE_std(end+1)  = std(cv,  0, 'omitnan');
results.cvResults.(name).RMSE = cv;
end

% -------------------------------------------------------------------
function cv = cv_score(data, target, mtype, K, folds, varargin)
cv = nan(K, 1);
for k = 1:K
    tr = data(folds ~= k, :);
    va = data(folds == k, :);
    if height(tr) < 10 || height(va) < 1, continue; end
    try
        switch mtype
            case 'LR'
                m = fitlm(tr, target);
            case 'DT'
                m = fitrtree(tr, target, 'MinLeafSize', 10);
            case 'RF'
                nT = 30;
                if ~isempty(varargin), nT = min(varargin{1}, 30); end
                m = fitrensemble(tr, target, 'Method','Bag', ...
                    'NumLearningCycles', nT, ...
                    'Learners', templateTree('MinLeafSize',5));
            case 'GB'
                nT = 30; lr = 0.1;
                if numel(varargin)>=1, nT = min(varargin{1},30); end
                if numel(varargin)>=2, lr = varargin{2}; end
                m = fitrensemble(tr, target, 'Method','LSBoost', ...
                    'NumLearningCycles',nT, 'LearnRate',lr, ...
                    'Learners', templateTree('MaxNumSplits',6,'MinLeafSize',5));
            case 'SVR'
                m = fitrsvm(tr, target, 'KernelFunction','rbf', ...
                    'KernelScale','auto', 'Standardize',true);
            otherwise
                continue
        end
        p = predict(m, va);
        [cv(k),~,~] = metrics(va.(target), p);
    catch
        % leave NaN
    end
end
cv = cv(~isnan(cv));
if isempty(cv), cv = NaN; end
end

% -------------------------------------------------------------------
function results = retrofit_scores(results, testData, bestPreds, actual)
% Rank test samples by excess consumption above model prediction.
exc     = actual - bestPreds;           % positive = using MORE than expected
excPct  = 100 * exc ./ max(bestPreds, 1);
zScore  = (exc - mean(exc)) ./ (std(exc) + eps);

results.retrofit.excessConsumption = exc;
results.retrofit.excessPercent     = excPct;
results.retrofit.score             = zScore;
results.retrofit.potentialSavings  = max(0, exc);

% Flag top-20% absolute consumers AND high z-score as candidates
thresh80 = prctile(actual, 80);
results.retrofit.candidateFlag = (zScore > 1.0) | (actual > thresh80);
results.retrofit.nCandidates   = sum(results.retrofit.candidateFlag);
results.retrofit.threshold80   = thresh80;

[~, results.retrofit.rankedIdx] = sort(exc, 'descend');

% EUI if floor area available
vars = testData.Properties.VariableNames;
for fa_name = {'FloorArea','floor_area','GrossFloorArea'}
    if ismember(fa_name{1}, vars)
        fa = testData.(fa_name{1});
        fa(fa <= 0 | isnan(fa)) = nanmedian(fa(fa>0));
        results.retrofit.EUI_actual    = actual    ./ fa;
        results.retrofit.EUI_predicted = bestPreds ./ fa;
        break
    end
end

fprintf('\nRetrofit candidates (test set): %d / %d\n', ...
    results.retrofit.nCandidates, numel(actual));
end

% -------------------------------------------------------------------
function s = defopt(s, f, v)
if ~isfield(s,f), s.(f) = v; end
end

function vprintf(verbose, fmt, varargin)
if verbose, fprintf(fmt, varargin{:}); end
end
