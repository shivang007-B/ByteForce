function HelperAnalyzeResults(results)
% HelperAnalyzeResults  Print a structured performance report for all
% trained models, including CV scores, overfitting analysis, uncertainty
% calibration, and feature importance ranking.
%
% SYNTAX
%   HelperAnalyzeResults(results)
%
% INPUT
%   results - Struct returned by BuildingRegressionModels

if isempty(results) || ~isstruct(results)
    warning('HelperAnalyzeResults: results is empty or not a struct.'); return
end
n = numel(results.modelNames);
if n == 0
    warning('HelperAnalyzeResults: no models found in results.'); return
end

sep = repmat('=',1,90);
fprintf('\n%s\n', sep);
fprintf('  ENERGY CONSUMPTION MODEL PERFORMANCE REPORT\n');
fprintf('  Target: %s  |  Train: %d samples  |  Test: %d samples\n', ...
    results.targetVar, results.trainSize, results.testSize);
fprintf('%s\n', sep);

%% 1. Performance table
fprintf('\n%-22s  %9s %9s  %9s %9s  %8s %8s  %15s\n', ...
    'Model','Tr.RMSE','Te.RMSE','Tr.MAE','Te.MAE','Tr.R2','Te.R2','CV RMSE');
fprintf('%s\n', repmat('-',1,90));

for i = 1:n
    if isfield(results,'cvRMSE') && numel(results.cvRMSE) >= i
        cvStr = sprintf('%.3f ± %.3f', results.cvRMSE(i), results.cvRMSE_std(i));
    else
        cvStr = 'N/A';
    end
    fprintf('%-22s  %9.3f %9.3f  %9.3f %9.3f  %8.4f %8.4f  %15s\n', ...
        results.modelNames{i}, ...
        results.trainRMSE(i), results.testRMSE(i), ...
        results.trainMAE(i),  results.testMAE(i), ...
        results.trainR2(i),   results.testR2(i), ...
        cvStr);
end

%% 2. Best model
fprintf('\n');
[~, bi] = min(results.testRMSE);
fprintf('Best model : %s\n', results.modelNames{bi});
fprintf('  Test RMSE = %.3f\n', results.testRMSE(bi));
fprintf('  Test MAE  = %.3f\n', results.testMAE(bi));
fprintf('  Test R2   = %.4f\n', results.testR2(bi));
if isfield(results,'cvRMSE') && numel(results.cvRMSE) >= bi
    fprintf('  CV RMSE   = %.3f (± %.3f)\n', ...
        results.cvRMSE(bi), results.cvRMSE_std(bi));
end

%% 3. Overfitting analysis
fprintf('\nOverfitting check (train RMSE vs test RMSE):\n');
fprintf('  Negative gap = train error is LOWER than test error (normal).\n');
fprintf('  Large negative gap (< -15%%) may indicate overfitting.\n\n');
for i = 1:n
    gap = 100 * (results.trainRMSE(i) - results.testRMSE(i)) ...
              / (results.testRMSE(i) + eps);
    if     gap < -20,  flag = '  *** LIKELY OVERFITTING';
    elseif gap < -10,  flag = '  (mild overfit)';
    elseif gap >  15,  flag = '  (underfitting?)';
    else,              flag = '  OK';
    end
    fprintf('  %-22s  gap = %+6.1f%%  %s\n', results.modelNames{i}, gap, flag);
end

%% 4. Model ranking
fprintf('\nModel ranking by test RMSE:\n');
[sRMSE, ri] = sort(results.testRMSE);
for k = 1:n
    fprintf('  %d. %-22s  RMSE=%.3f  R2=%.4f\n', ...
        k, results.modelNames{ri(k)}, sRMSE(k), results.testR2(ri(k)));
end

%% 5. Uncertainty calibration
if isfield(results,'uncertainty') && isfield(results.uncertainty,'RandomForest')
    u = results.uncertainty.RandomForest;
    fprintf('\nUncertainty (Random Forest, 95%% prediction intervals):\n');
    fprintf('  Mean prediction std  = %.3f\n', mean(u.predStd));
    fprintf('  Interval coverage    = %.1f%%  (target ~95%%)\n', u.coverage95*100);
    if u.coverage95 < 0.85
        fprintf('  Warning: coverage below 85%% — intervals may be too narrow.\n');
    elseif u.coverage95 > 0.99
        fprintf('  Note: coverage near 100%% — intervals may be too wide.\n');
    end
end

%% 6. Feature importance
impPrinted = false;
for mdlName = {'GradientBoosting','RandomForest'}
    if isfield(results,'featureImportance') && ...
            isfield(results.featureImportance, mdlName{1})
        imp    = results.featureImportance.(mdlName{1});
        fnames = results.featureImportance.([mdlName{1} 'Names']);
        [sImp, si] = sort(imp,'descend');
        nShow = min(15, numel(sImp));
        fprintf('\nTop %d feature importances (%s):\n', nShow, mdlName{1});
        for k = 1:nShow
            bar = repmat('|', 1, max(1, round(20 * sImp(k)/sImp(1))));
            fprintf('  %2d. %-25s  %.4f  %s\n', ...
                k, fnames{si(k)}, sImp(k), bar);
        end
        impPrinted = true;
        break
    end
end
if ~impPrinted
    fprintf('\nFeature importance not available (tree ensemble not trained).\n');
end

%% 7. Retrofit summary
if isfield(results,'retrofit')
    r = results.retrofit;
    fprintf('\nRetrofit / Energy Waste Summary (test set):\n');
    fprintf('  Candidates flagged        : %d / %d\n', ...
        r.nCandidates, numel(results.bestPredictions));
    fprintf('  Total potential savings   : %.1f (sum of positive excess)\n', ...
        sum(max(0, r.excessConsumption)));
    fprintf('  Max single-building excess: %.1f\n', max(r.excessConsumption));
end

fprintf('\n%s\n\n', sep);
end
