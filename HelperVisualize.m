function HelperVisualize(results, data)
% HelperVisualize  Comprehensive visualisation suite for the energy
% consumption prediction pipeline (CL-03 challenge).
%
% SYNTAX
%   HelperVisualize(results, data)
%
% FIGURES PRODUCED
%   1. Model comparison      — RMSE / R2 / MAE bar charts
%   2. CV RMSE               — error-bar plot vs test RMSE
%   3. Target distribution   — histogram + by-category box plots
%   4. Predicted vs Actual   — scatter for best model with 95% CI band
%   5. Residual analysis     — histogram and fitted-vs-residual scatter
%   6. Feature importance    — horizontal bar chart
%   7. Retrofit map          — excess consumption coloured scatter + bar
%   8. Uncertainty intervals — sample of predictions with CI band

if isempty(results) || ~isstruct(results)
    warning('HelperVisualize: results is empty.'); return
end

target   = results.targetVar;
testAct  = results.testData.(target);
bestPred = results.bestPredictions;
nMdl     = numel(results.modelNames);
names    = results.modelNames;
colors   = lines(nMdl);

%% ----------------------------------------------------------------
%  Figure 1: Model Performance Comparison
%% ----------------------------------------------------------------
f1 = figure('Name','Model Performance','NumberTitle','off', ...
            'Position',[40 40 1300 420]);

subplot(1,3,1)
bh = bar([results.trainRMSE; results.testRMSE]','grouped');
bh(1).FaceColor = [0.25 0.55 0.85]; bh(2).FaceColor = [0.90 0.40 0.20];
set(gca,'XTick',1:nMdl,'XTickLabel',names,'XTickLabelRotation',30)
ylabel('RMSE'); title('RMSE: Train vs Test')
legend('Train','Test','Location','best'); grid on; box off

subplot(1,3,2)
bh2 = bar([results.trainR2; results.testR2]','grouped');
bh2(1).FaceColor = [0.20 0.70 0.40]; bh2(2).FaceColor = [0.90 0.75 0.10];
set(gca,'XTick',1:nMdl,'XTickLabel',names,'XTickLabelRotation',30)
ylabel('R^2'); title('R-Squared: Train vs Test'); ylim([0 1])
legend('Train','Test','Location','best'); grid on; box off

subplot(1,3,3)
bh3 = bar([results.trainMAE; results.testMAE]','grouped');
bh3(1).FaceColor = [0.55 0.20 0.80]; bh3(2).FaceColor = [0.80 0.20 0.45];
set(gca,'XTick',1:nMdl,'XTickLabel',names,'XTickLabelRotation',30)
ylabel('MAE'); title('MAE: Train vs Test')
legend('Train','Test','Location','best'); grid on; box off

sgtitle('Model Performance Comparison','FontSize',13,'FontWeight','bold')

%% ----------------------------------------------------------------
%  Figure 2: Cross-Validation RMSE
%% ----------------------------------------------------------------
if isfield(results,'cvRMSE') && ~isempty(results.cvRMSE)
    figure('Name','CV RMSE','NumberTitle','off','Position',[40 510 720 360])
    errorbar(1:nMdl, results.cvRMSE, results.cvRMSE_std, ...
        'o-','LineWidth',2,'MarkerSize',8, ...
        'MarkerFaceColor',[0.20 0.60 0.90],'Color',[0.10 0.40 0.75])
    hold on
    bar(1:nMdl, results.testRMSE, 0.4, ...
        'FaceColor',[0.92 0.75 0.20],'FaceAlpha',0.5)
    set(gca,'XTick',1:nMdl,'XTickLabel',names,'XTickLabelRotation',30)
    ylabel('RMSE'); title('Cross-Validation RMSE vs Test RMSE')
    legend('CV mean ± std','Test RMSE','Location','best')
    grid on; box off
end

%% ----------------------------------------------------------------
%  Figure 3: Target Distribution
%% ----------------------------------------------------------------
figure('Name','Target Distribution','NumberTitle','off','Position',[800 40 920 420])

subplot(1,2,1)
histogram(data.(target), 40, 'FaceColor',[0.20 0.60 0.80], ...
    'EdgeColor','white','FaceAlpha',0.85)
xlabel('Site EUI (kWh/m^2/yr)'); ylabel('Count')
title('Distribution of Target Variable'); grid on; box off
xline(median(data.(target),'omitnan'),'r--','LineWidth',1.8, ...
    'Label',sprintf('Median=%.1f',median(data.(target),'omitnan')))
xline(mean(data.(target),'omitnan'),'b--','LineWidth',1.5, ...
    'Label',sprintf('Mean=%.1f',mean(data.(target),'omitnan')))

subplot(1,2,2)
% Find a categorical column for grouping (take first one)
catCol = '';
for c = data.Properties.VariableNames
    if iscategorical(data.(c{1})) && ~strcmp(c{1},target)
        catCol = c{1}; break
    end
end
if ~isempty(catCol)
    boxplot(data.(target), data.(catCol), ...
        'ColorGroup', data.(catCol), 'Notch','off')
    xlabel(catCol); ylabel('Site EUI'); title('EUI by Category')
    set(gca,'XTickLabelRotation',30); grid on; box off
else
    qqplot(data.(target))
    title('Q-Q Plot of Target Variable')
end
sgtitle('Target Variable Overview','FontSize',13,'FontWeight','bold')

%% ----------------------------------------------------------------
%  Figure 4: Predicted vs Actual (best model) + uncertainty band
%% ----------------------------------------------------------------
figure('Name',sprintf('Predicted vs Actual — %s',results.bestModel), ...
       'NumberTitle','off','Position',[800 510 620 520])

hasUQ = isfield(results,'uncertainty') && ...
        isfield(results.uncertainty,'RandomForest') && ...
        strcmp(results.bestModel,'RandomForest');

if hasUQ
    u = results.uncertainty.RandomForest;
    % Sort by actual for clean ribbon
    [sAct, si] = sort(testAct);
    fill([sAct; flipud(sAct)], ...
         [u.lower95(si); flipud(u.upper95(si))], ...
         [0.82 0.92 1.0],'EdgeColor','none','FaceAlpha',0.55)
    hold on
end

scatter(testAct, bestPred, 35, [0.15 0.45 0.75], ...
    'filled','MarkerFaceAlpha',0.55); hold on
allV = [testAct; bestPred];
lims = [min(allV)*0.97, max(allV)*1.03];
plot(lims, lims, 'r--', 'LineWidth',2)
xlabel('Actual Site EUI'); ylabel('Predicted Site EUI')

bi    = strcmp(results.modelNames, results.bestModel);
r2val = results.testR2(bi);
rmse  = results.testRMSE(bi);
title(sprintf('Predicted vs Actual  (%s)', results.bestModel))
lgStrs = {'Predictions','Perfect fit'};
if hasUQ, lgStrs = [{'95% CI'}, lgStrs]; end
legend(lgStrs,'Location','best')
text(0.04,0.93,sprintf('R^2 = %.4f\nRMSE = %.3f',r2val,rmse), ...
    'Units','normalized','FontSize',11,'FontWeight','bold', ...
    'BackgroundColor','w','EdgeColor',[0.7 0.7 0.7])
grid on; box off; axis square

%% ----------------------------------------------------------------
%  Figure 5: Residual Analysis
%% ----------------------------------------------------------------
resid = testAct - bestPred;
figure('Name','Residual Analysis','NumberTitle','off','Position',[40 40 920 420])

subplot(1,2,1)
histogram(resid, 38, 'FaceColor',[0.40 0.72 0.42], ...
    'EdgeColor','white','FaceAlpha',0.85)
xlabel('Residual (Actual − Predicted)'); ylabel('Count')
title('Residual Distribution'); grid on; box off
xline(0,'k-','LineWidth',2)
xline(mean(resid),'r--','LineWidth',1.5, ...
    'Label',sprintf('Mean=%.2f',mean(resid)))

subplot(1,2,2)
scatter(bestPred, resid, 35, [0.72 0.30 0.30], ...
    'filled','MarkerFaceAlpha',0.50)
xlabel('Predicted (EUI)'); ylabel('Residual')
title('Residuals vs Fitted'); grid on; box off
yline(0,'k-','LineWidth',2)
% Simple lowess trend line (requires Statistics Toolbox smooth)
try
    xSort = sort(bestPred);
    [~,si2] = sort(bestPred);
    ySmooth = smooth(bestPred(si2), resid(si2), 0.25, 'loess');
    plot(bestPred(si2), ySmooth, 'b-','LineWidth',1.8)
catch
end

sgtitle(sprintf('Residual Analysis — %s',results.bestModel), ...
    'FontSize',13,'FontWeight','bold')

%% ----------------------------------------------------------------
%  Figure 6: Feature Importance
%% ----------------------------------------------------------------
impField = '';
if isfield(results,'featureImportance')
    for f = {'GradientBoosting','RandomForest'}
        if isfield(results.featureImportance, f{1})
            impField = f{1}; break
        end
    end
end

if ~isempty(impField)
    imp    = results.featureImportance.(impField);
    fnames = results.featureImportance.([impField 'Names']);
    [sImp, si] = sort(imp,'ascend');
    nShow  = min(20, numel(sImp));
    sImp   = sImp(end-nShow+1:end);
    sNames = fnames(si(end-nShow+1:end));

    figure('Name',sprintf('Feature Importance — %s',impField), ...
           'NumberTitle','off','Position',[800 40 760 520])
    bh = barh(1:nShow, sImp);
    % Colour by importance quartile
    q1v = prctile(sImp,25); q3v = prctile(sImp,75);
    cdata = repmat([0.20 0.55 0.85], nShow, 1);
    cdata(sImp > q3v, :) = repmat([0.90 0.30 0.20], sum(sImp>q3v), 1);
    cdata(sImp > q1v & sImp <= q3v, :) = ...
        repmat([0.95 0.75 0.10], sum(sImp>q1v & sImp<=q3v), 1);
    bh.FaceColor = 'flat'; bh.CData = cdata;
    set(gca,'YTick',1:nShow,'YTickLabel',sNames,'FontSize',9)
    xlabel('Importance Score')
    title(sprintf('Top %d Feature Importances (%s)',nShow,impField))
    grid on; box off
end

%% ----------------------------------------------------------------
%  Figure 7: Retrofit Candidate Map
%% ----------------------------------------------------------------
if isfield(results,'retrofit')
    r   = results.retrofit;
    exc = r.excessConsumption;
    n2  = numel(testAct);

    figure('Name','Retrofit Analysis','NumberTitle','off', ...
           'Position',[40 510 1050 440])

    subplot(1,2,1)
    % Colour by excess band
    clr = zeros(n2,3);
    clr(exc <= 0,            :) = repmat([0.20 0.72 0.30], sum(exc<=0),           1);
    clr(exc > 0 & exc <= 10, :) = repmat([0.95 0.82 0.10], sum(exc>0&exc<=10),    1);
    clr(exc > 10,            :) = repmat([0.88 0.20 0.20], sum(exc>10),            1);
    scatter(bestPred, testAct, 50, clr, 'filled','MarkerFaceAlpha',0.70)
    hold on
    lims2 = [min([bestPred;testAct])*0.95, max([bestPred;testAct])*1.05];
    plot(lims2,lims2,'k--','LineWidth',1.8)
    xlabel('Predicted EUI'); ylabel('Actual EUI')
    title('Retrofit Map (above line = excess use)')
    h1=scatter(nan,nan,50,[0.20 0.72 0.30],'filled');
    h2=scatter(nan,nan,50,[0.95 0.82 0.10],'filled');
    h3=scatter(nan,nan,50,[0.88 0.20 0.20],'filled');
    legend([h1 h2 h3],{'≤0 excess','0-10 excess','>10 excess'}, ...
        'Location','best')
    grid on; box off

    subplot(1,2,2)
    nTop = min(30, n2);
    [sortedExc, ~] = sort(exc,'descend');
    barColors = zeros(nTop,3);
    barColors(sortedExc(1:nTop)> 0,:) = repmat([0.88 0.20 0.20],sum(sortedExc(1:nTop)>0),1);
    barColors(sortedExc(1:nTop)<=0,:) = repmat([0.20 0.72 0.30],sum(sortedExc(1:nTop)<=0),1);
    bh7 = bar(1:nTop, sortedExc(1:nTop),'FaceColor','flat');
    bh7.CData = barColors;
    xlabel('Building rank (by excess)'); ylabel('Excess EUI')
    title(sprintf('Top %d Buildings by Excess Consumption',nTop))
    yline(0,'k-','LineWidth',1.5); grid on; box off

    sgtitle('Energy Waste & Retrofit Candidates','FontSize',13,'FontWeight','bold')
end

%% ----------------------------------------------------------------
%  Figure 8: Uncertainty Interval Sample Plot
%% ----------------------------------------------------------------
if isfield(results,'uncertainty') && ...
        isfield(results.uncertainty,'RandomForest')
    u    = results.uncertainty.RandomForest;
    nSmp = min(80, numel(testAct));
    [~, si] = sort(testAct);
    idx = si(round(linspace(1,numel(si),nSmp)));

    figure('Name','Prediction Uncertainty','NumberTitle','off', ...
           'Position',[800 510 820 420])

    x = 1:nSmp;
    fill([x, fliplr(x)], ...
         [u.lower95(idx)', fliplr(u.upper95(idx)')], ...
         [0.82 0.92 1.0],'EdgeColor','none','FaceAlpha',0.60)
    hold on
    plot(x, bestPred(idx),'b-','LineWidth',1.8)
    plot(x, testAct(idx), 'ro','MarkerSize',5, ...
        'MarkerFaceColor',[0.90 0.20 0.20],'LineStyle','none')
    xlabel('Samples (sorted by actual EUI)')
    ylabel('Site EUI')
    title(sprintf('Random Forest: Predictions ± 95%% Interval  (coverage=%.1f%%)', ...
        u.coverage95*100))
    legend({'95% CI','Predicted','Actual'},'Location','best')
    grid on; box off
end

fprintf('Visualisations complete (%d figures).\n', ...
    5 + ~isempty(impField) + isfield(results,'retrofit') + ...
    (isfield(results,'uncertainty') && isfield(results.uncertainty,'RandomForest')));
end
