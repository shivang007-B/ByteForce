%% =========================================================================
%  EnergyConsumptionPipeline.m
%  CL-03 — Predicting Energy Consumption for a Building
%  MathWorks Climate Tech Hackathon
% =========================================================================
%
%  WHAT THIS SCRIPT DOES
%  ---------------------
%  1. Loads the WiDS 2022 dataset (exampleTrain.csv or train.csv).
%  2. Cleans and preprocesses data (imputation, outlier removal).
%  3. Trains 4 regression models with building-aware train/test split:
%       - Linear Regression
%       - Pruned Decision Tree
%       - Random Forest (+ 95% prediction intervals)
%       - Gradient Boosting
%  4. Evaluates each model on unseen test data (RMSE, MAE, R2, CV RMSE).
%  5. Identifies feature drivers via importance scores.
%  6. Ranks buildings by excess energy use (retrofit candidates).
%  7. Generates 8 visualisation figures.
%  8. Saves all results to .mat and .csv files.
%
%  REQUIREMENTS
%  ------------
%  - MATLAB R2020b or later
%  - Statistics and Machine Learning Toolbox
%
%  DATASET
%  -------
%  Place exampleTrain.csv (from exampleTrain.zip) in the same folder.
%  Alternatively use the full WiDS 2022 train.csv from Kaggle.
%  The script auto-generates synthetic data if no CSV is found.
%
%  USAGE
%  -----
%  Run this script directly:   >> EnergyConsumptionPipeline
%  Or adjust options below and re-run.
%
% =========================================================================

clear; clc;
addpath(pwd);
rng(42);

fprintf('=========================================================\n');
fprintf('  CL-03: Building Energy Consumption Prediction\n');
fprintf('=========================================================\n\n');

%% -----------------------------------------------------------------------
%%  CONFIGURATION  (edit these to tune the pipeline)
%% -----------------------------------------------------------------------

DATA_FILE   = 'exampleTrain.csv';   % primary data file to look for
TARGET_VAR  = 'OutputVar';          % response column name

% Preprocessing options
preOpts.TargetVar      = TARGET_VAR;
preOpts.RemoveCellCols = false;     % false = keep as categorical
preOpts.OutlierMethod  = 'iqr';     % 'iqr' | 'zscore' | 'none'
preOpts.IQRMultiplier  = 3.0;
preOpts.ImputeMethod   = 'median';
preOpts.Verbose        = true;

% Model options
mdlOpts.TargetVar    = TARGET_VAR;
mdlOpts.TestFraction = 0.20;        % 20% of data held out for testing
mdlOpts.CVFolds      = 5;           % 5-fold cross-validation
mdlOpts.NTreesRF     = 100;         % Random Forest trees
mdlOpts.NTreesGB     = 100;         % Gradient Boosting rounds
mdlOpts.LearnRateGB  = 0.05;        % GBM learning rate
mdlOpts.RunSVR       = false;       % SVR is slow; set true to include
mdlOpts.Verbose      = true;

%% -----------------------------------------------------------------------
%%  STEP 1: Load data
%% -----------------------------------------------------------------------
fprintf('STEP 1 — Loading data\n');
fprintf('%s\n', repmat('-',1,50));

data = loadData(DATA_FILE, TARGET_VAR);
fprintf('Loaded  : %d rows x %d columns\n\n', height(data), width(data));

%% -----------------------------------------------------------------------
%%  STEP 2: Exploratory Data Analysis (quick summary)
%% -----------------------------------------------------------------------
fprintf('STEP 2 — Exploratory Data Analysis\n');
fprintf('%s\n', repmat('-',1,50));
quickEDA(data, TARGET_VAR);

%% -----------------------------------------------------------------------
%%  STEP 3: Preprocessing
%% -----------------------------------------------------------------------
fprintf('STEP 3 — Preprocessing\n');
fprintf('%s\n', repmat('-',1,50));
data = HelperDataPreprocessing(data, preOpts);

%% -----------------------------------------------------------------------
%%  STEP 4: Train models
%% -----------------------------------------------------------------------
fprintf('STEP 4 — Training models\n');
fprintf('%s\n', repmat('-',1,50));
[trainedModels, results] = BuildingRegressionModels(data, mdlOpts);

%% -----------------------------------------------------------------------
%%  STEP 5: Performance report
%% -----------------------------------------------------------------------
fprintf('\nSTEP 5 — Performance report\n');
fprintf('%s\n', repmat('-',1,50));
HelperAnalyzeResults(results);

%% -----------------------------------------------------------------------
%%  STEP 6: Retrofit / energy waste analysis
%% -----------------------------------------------------------------------
fprintf('STEP 6 — Retrofit analysis\n');
fprintf('%s\n', repmat('-',1,50));
retrofitTable = HelperRetrofitAnalysis(results, data);

%% -----------------------------------------------------------------------
%%  STEP 7: Visualisations
%% -----------------------------------------------------------------------
fprintf('STEP 7 — Generating visualisations\n');
fprintf('%s\n', repmat('-',1,50));
HelperVisualize(results, data);

%% -----------------------------------------------------------------------
%%  STEP 8: Save outputs
%% -----------------------------------------------------------------------
fprintf('\nSTEP 8 — Saving outputs\n');
fprintf('%s\n', repmat('-',1,50));

save('energy_results.mat', 'trainedModels', 'results', 'retrofitTable', '-v7.3');
fprintf('Model results saved  : energy_results.mat\n');

if ~isempty(retrofitTable)
    writetable(retrofitTable, 'retrofit_candidates.csv');
    fprintf('Retrofit table saved : retrofit_candidates.csv\n');
end

% Save per-model predictions to CSV
saveModelPredictions(results);

%% -----------------------------------------------------------------------
%%  STEP 9: Final summary
%% -----------------------------------------------------------------------
printSummary(results, retrofitTable);

fprintf('\n=========================================================\n');
fprintf('  Pipeline complete.\n');
fprintf('  Open energy_results.mat  to explore trained models.\n');
fprintf('  Open retrofit_candidates.csv  for the retrofit table.\n');
fprintf('=========================================================\n');


%% =======================================================================
%%  LOCAL FUNCTIONS
%% =======================================================================

function data = loadData(csvFile, targetVar)
% Try several sources in order of preference.

    % 1. CSV in working directory
    candidates = {csvFile, 'train.csv', 'building_energy_data.csv'};
    for i = 1:numel(candidates)
        if exist(candidates{i}, 'file')
            fprintf('  Reading %s ...\n', candidates{i});
            opts = detectImportOptions(candidates{i});
            opts.MissingRule = 'fill';
            data = readtable(candidates{i}, opts);
            % Rename target if needed
            if ismember('site_eui', data.Properties.VariableNames) && ...
                    ~ismember(targetVar, data.Properties.VariableNames)
                data.Properties.VariableNames{'site_eui'} = targetVar;
            end
            return
        end
    end

    % 2. .mat file from previous run
    if exist('building_energy_data.mat','file')
        fprintf('  Loading building_energy_data.mat ...\n');
        S = load('building_energy_data.mat');
        f = fieldnames(S); data = S.(f{1});
        return
    end

    % 3. Synthetic fallback
    fprintf('  No data file found. Generating synthetic data ...\n');
    fprintf('  (place exampleTrain.csv in this folder for real results)\n\n');
    data = generateSyntheticData(targetVar);
    save('building_energy_data.mat','data');
end

% -------------------------------------------------------------------------
function data = generateSyntheticData(targetVar)
% Synthetic dataset that mimics the WiDS 2022 structure:
%   - Building metadata: age, size, type, occupancy, efficiency
%   - Weather: temperature, humidity, solar, wind
%   - Time: month, hour, day-of-week
%   - Anonymised continuous features (Var-style)

    rng(42);
    n = 2000;
    fprintf('  Generating %d synthetic rows ...\n', n);

    % Building features
    buildingAge   = randi([1,60],   n,1);
    floorArea     = 200 + 4800*rand(n,1);
    numFloors     = max(1, round(floorArea/600));
    occupancy     = round(floorArea .* (0.02 + 0.04*rand(n,1)));
    hvacEff       = 0.4 + 0.6*rand(n,1);
    insulRating   = randi([1,10], n,1);
    wwr           = 0.1 + 0.5*rand(n,1);
    bTypes        = {'Office','Residential','Retail','Industrial','Education'};
    buildingType  = categorical(bTypes(randi(5,n,1))');

    % Weather
    month       = randi([1,12], n,1);
    temp        = 10 + 12*sin(2*pi*(month-3)/12) + 3*randn(n,1);
    humidity    = 50 + 20*sin(2*pi*month/12) + 5*randn(n,1);
    solarRad    = max(0, 300 + 400*sin(2*pi*(month-3)/12) + 80*randn(n,1));
    windSpeed   = 2 + 10*rand(n,1);
    hour        = randi([0,23], n,1);
    dayOfWeek   = randi([1,7],  n,1);

    % Some anonymised numeric features (like WiDS Var columns)
    Var2  = rand(n,1)*100;
    Var3  = rand(n,1);
    Var5  = rand(n,1)*100;
    Var8  = rand(n,1);
    Var9  = randi([1,16], n,1);
    Var11 = randi([1,16], n,1);

    % Energy Use Intensity (target, kWh/m2/yr)
    base     = 50 + 0.005*floorArea;
    ageEff   = 0.3 * buildingAge;
    weatherE = max(0,temp-18)*2 + max(0,15-temp)*3;
    hvacE    = -20 * hvacEff;
    insulE   = -3  * insulRating;
    occE     = 0.05 * occupancy;
    noise    = 8 * randn(n,1);

    eui = base + ageEff + weatherE + hvacE + insulE + occE + noise;
    eui = max(eui, 5);

    % 5% missing in target
    missIdx = rand(n,1) < 0.05;
    eui(missIdx) = NaN;

    data = table(buildingAge, floorArea, numFloors, occupancy, ...
        hvacEff, insulRating, wwr, buildingType, ...
        month, temp, humidity, solarRad, windSpeed, ...
        hour, dayOfWeek, Var2, Var3, Var5, Var8, Var9, Var11, eui);
    data.Properties.VariableNames{end} = targetVar;
end

% -------------------------------------------------------------------------
function quickEDA(data, targetVar)
    cols = data.Properties.VariableNames;
    numCols = sum(cellfun(@(c) isnumeric(data.(c)), cols));
    catCols = sum(cellfun(@(c) iscell(data.(c)) || ...
                  isstring(data.(c)) || iscategorical(data.(c)), cols));

    fprintf('  Total features   : %d\n', width(data)-1);
    fprintf('  Numeric columns  : %d\n', numCols);
    fprintf('  Categorical cols : %d\n', catCols);

    if ismember(targetVar, cols)
        y = data.(targetVar);
        fprintf('\n  Target (%s) statistics:\n', targetVar);
        fprintf('    Min    = %.3f\n', min(y,[],'omitnan'));
        fprintf('    Max    = %.3f\n', max(y,[],'omitnan'));
        fprintf('    Mean   = %.3f\n', mean(y,'omitnan'));
        fprintf('    Median = %.3f\n', median(y,'omitnan'));
        fprintf('    Std    = %.3f\n', std(y,'omitnan'));
        fprintf('    NaN%%   = %.1f%%\n', 100*mean(isnan(y)));
    end

    % Count total missing values
    numMissing = 0;
    for c = 1:numel(cols)
        col = data.(cols{c});
        if isnumeric(col)
            numMissing = numMissing + sum(isnan(col));
        end
    end
    fprintf('\n  Total missing numeric cells : %d\n\n', numMissing);
end

% -------------------------------------------------------------------------
function saveModelPredictions(results)
    try
        actual = results.testData.(results.targetVar);
        T = table(actual, 'VariableNames', {'Actual'});
        for i = 1:numel(results.modelNames)
            nm = results.modelNames{i};
            if isfield(results.predictions, nm)
                T.(nm) = results.predictions.(nm);
            end
        end
        writetable(T, 'model_predictions.csv');
        fprintf('Predictions saved    : model_predictions.csv\n');
    catch
        % non-critical
    end
end

% -------------------------------------------------------------------------
function printSummary(results, retrofitTable)
    sep = repmat('=',1,60);
    fprintf('\n%s\n', sep);
    fprintf('  FINAL SUMMARY\n');
    fprintf('%s\n', sep);
    fprintf('  Training samples : %d\n', results.trainSize);
    fprintf('  Test samples     : %d\n', results.testSize);
    fprintf('\n  MODEL RESULTS:\n');
    for i = 1:numel(results.modelNames)
        tag = '';
        if strcmp(results.modelNames{i}, results.bestModel)
            tag = '  ◄ BEST';
        end
        fprintf('    %-22s  RMSE=%-8.3f  R2=%.4f%s\n', ...
            results.modelNames{i}, results.testRMSE(i), results.testR2(i), tag);
    end
    fprintf('\n  RETROFIT:\n');
    if ~isempty(retrofitTable)
        nCrit = sum(strcmp(retrofitTable.WasteSeverity,'Critical'));
        nHigh = sum(strcmp(retrofitTable.WasteSeverity,'High'));
        fprintf('    Critical waste buildings : %d\n', nCrit);
        fprintf('    High waste buildings     : %d\n', nHigh);
        fprintf('    Total potential savings  : %.2f EUI units\n', ...
            sum(retrofitTable.PotentialSaving));
    end
    fprintf('%s\n', sep);
end
