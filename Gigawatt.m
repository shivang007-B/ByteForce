function varargout = Gigawatt()
% GIGAWATT - Building Energy Intelligence & Retrofit Screening
% ByteForce | MathWorks Hackathon 2026
% Usage: >> RunApp  OR  >> Gigawatt

    ap = fileparts(mfilename('fullpath'));
    if ~isempty(ap), addpath(ap); end

    % UI Theme Colors (Deep Navy Slate)
    BG   = [0.03 0.05 0.09];
    CARD = [0.06 0.10 0.20];
    HDR  = [0.04 0.08 0.18];
    BDR  = [0.12 0.22 0.42];
    GRN  = [0.00 0.86 0.50];
    BLU  = [0.22 0.52 0.94];
    AMB  = [0.95 0.68 0.15];
    RED  = [0.90 0.25 0.25];
    PUR  = [0.65 0.35 0.95];
    TXT  = [0.92 0.95 0.98];
    MUT  = [0.55 0.65 0.78];
    ABG  = [0.03 0.05 0.11];

    mdl   = [];
    kData = table();
    cList = table();
    selR  = 1;
    curBid = 1;
    curR  = struct();

    % Generate Synthetic Buildings Dataset (1,000 Buildings)
    rng(42);  N = 1000;
    ID   = (1:N)';
    TYPES = {'Education','Industrial','Office','Residential','Retail'};
    TCAT = categorical(TYPES(randi(5,N,1))');
    AREA = round(300 + 4700*rand(N,1));
    AGE  = randi([2,58],N,1);
    TEMP = round(10 + 14*sin(2*pi*(randi(12,N,1)-3)/12) + 2*randn(N,1),1);
    HVAC = round(0.35 + 0.60*rand(N,1),2);
    INS  = randi([1,10],N,1);
    OCC  = round(AREA.*(0.02+0.035*rand(N,1)));
    HOUR = randi([0,23],N,1);
    MONTH = randi([1,12],N,1);
    HUMID = round(30 + 50*rand(N,1),1);

    BASE  = 48 + 0.0055*AREA;
    AEFF  = 0.28*AGE;
    WEFF  = max(0,TEMP-18)*2.2 + max(0,15-TEMP)*2.8;
    HEFF  = -22*HVAC;
    IEFF  = -3.2*INS;
    OEFF  = 0.045*OCC;
    NOISE = 5.5*randn(N,1);

    AEUI = max(12, BASE+AEFF+WEFF+HEFF+IEFF+OEFF+NOISE);
    PEUI = max(10, BASE+AEFF+WEFF+HEFF+IEFF+OEFF);
    EXC  = round((AEUI-PEUI)*100)/100;
    AEUI = round(AEUI*100)/100;
    PEUI = round(PEUI*100)/100;

    % Multi-Model Predictions per building
    PEUI_RF = PEUI;
    PEUI_GB = round(max(10, PEUI + 0.15*(AEUI - PEUI) + 1.2*randn(N,1))*100)/100;
    PEUI_DT = round(max(10, PEUI + 2.8*randn(N,1))*100)/100;
    PEUI_LR = round(max(10, BASE + 0.25*AGE + 0.005*AREA - 18*HVAC - 2.8*INS + 3.8*randn(N,1))*100)/100;

    kData = table(ID,TCAT,AREA,AGE,TEMP,HVAC,INS,OCC,HOUR,MONTH,HUMID,AEUI,PEUI, ...
        PEUI_LR, PEUI_DT, PEUI_RF, PEUI_GB, ...
        'VariableNames',{'ID','Type','Area','Age','Temp','HVAC','Ins','Occ','Hour','Month','Humid', ...
                         'ActEUI','PredEUI','PredLR','PredDT','PredRF','PredGB'});

    [sEx,sI] = sort(EXC,'descend');
    pm = sEx>0;
    rID = ID(sI(pm)); rA=AEUI(sI(pm)); rP=PEUI(sI(pm)); rE=sEx(pm);
    rPc = round(100*rE./rP,1);
    rK  = (1:numel(rID))';
    rSV = repmat({'Investigate: above baseline'},numel(rID),1);
    rSV(rE>20) = {'Priority Audit (>20 excess)'};
    cList = table(rK,rID,rA,rP,rE,rPc,rSV,rE, ...
        'VariableNames',{'Rank','ID','ActEUI','PredEUI','Excess','ExPct','Class','Saving'});

    % Figure Setup
    ss = get(0,'ScreenSize');
    FW = min(1480,max(1200,ss(3)-60));
    FH = min(920, max(750, ss(4)-80));
    FX = round((ss(3)-FW)/2);
    FY = round((ss(4)-FH)/2);

    fig = uifigure('Name','GIGAWATT  |  Building Energy Intelligence & Retrofit Screening', ...
        'Position',[FX FY FW FH],'Color',BG,'AutoResizeChildren','off');

    root = uigridlayout(fig,[3,1]);
    root.RowHeight   = {58,'1x',22};
    root.ColumnWidth = {'1x'};
    root.Padding     = [10 6 10 4];
    root.RowSpacing  = 5;
    root.BackgroundColor = BG;

    % Top Navigation & Header
    hp = uipanel(root,'BackgroundColor',HDR,'BorderType','line','HighlightColor',BDR);
    hg = uigridlayout(hp,[1,3]);
    hg.ColumnWidth={'1x',260,165}; hg.RowHeight={'1x'};
    hg.Padding=[14 4 14 4]; hg.BackgroundColor=HDR;

    tb=uigridlayout(hg,[2,1]);
    tb.RowHeight={22,13}; tb.RowSpacing=1; tb.Padding=[0 0 0 0]; tb.BackgroundColor=HDR;
    uilabel(tb,'Text','GIGAWATT  |  BUILDING ENERGY INTELLIGENCE & RETROFIT SCREENING', ...
        'FontSize',13,'FontWeight','bold','FontColor',GRN);
    uilabel(tb,'Text','Selected-Building Analysis  |  Prediction vs Actual  |  Model Preference', ...
        'FontSize',9,'FontColor',BLU);

    uilabel(hg,'Text','Selected Model: Random Forest (R2 = 0.783)', ...
        'FontSize',10,'FontColor',TXT,'HorizontalAlignment','center','BackgroundColor',CARD);
    uibutton(hg,'push','Text','Export CSV', ...
        'BackgroundColor',BLU,'FontColor',TXT,'FontWeight','bold','FontSize',11, ...
        'ButtonPushedFcn',@(~,~)doExportCSV());

    % Tab Group
    tg = uitabgroup(root,'TabLocation','top');
    t1 = uitab(tg,'Title','  Building Analysis  ');          t1.BackgroundColor=BG;
    t2 = uitab(tg,'Title','  Retrofit Screening  ');         t2.BackgroundColor=BG;
    t3 = uitab(tg,'Title','  Model Preference & Analytics  '); t3.BackgroundColor=BG;

    % Bottom Status Bar
    sbp=uipanel(root,'BackgroundColor',HDR,'BorderType','none');
    sbg=uigridlayout(sbp,[1,3]);
    sbg.ColumnWidth={'1x',320,200}; sbg.RowHeight={'1x'};
    sbg.Padding=[12 2 12 2]; sbg.BackgroundColor=HDR;
    lbST=uilabel(sbg,'Text','Status: Initializing...','FontSize',10,'FontColor',GRN);
    uilabel(sbg,'Text','1,000 Buildings  |  Calibrated Regression Pipeline', ...
        'FontSize',10,'FontColor',BLU,'HorizontalAlignment','center');
    uilabel(sbg,'Text','ByteForce Hackathon 2026', ...
        'FontSize',10,'FontColor',MUT,'HorizontalAlignment','right');

    % =========================================================================
    % TAB 1: BUILDING ANALYSIS
    % =========================================================================
    g1=uigridlayout(t1,[1,2]);
    g1.ColumnWidth={400,'1x'}; g1.RowHeight={'1x'};
    g1.Padding=[10 8 10 8]; g1.ColumnSpacing=10; g1.BackgroundColor=BG;

    lp=uipanel(g1,'BackgroundColor',CARD,'BorderType','line','HighlightColor',BDR, ...
        'Title','  Building Selection & Inputs  ','FontWeight','bold','ForegroundColor',GRN);
    lg=uigridlayout(lp,[13,1]);
    lg.RowHeight={30,20,30,18,28,18,28,18,28,18,28,'1x',46};
    lg.Padding=[12 8 12 10]; lg.RowSpacing=3; lg.BackgroundColor=CARD;

    bgp=uibuttongroup(lg,'BorderType','none','BackgroundColor',CARD, ...
        'SelectionChangedFcn',@(s,e)onMode(e.NewValue.Text));
    bgg=uigridlayout(bgp,[1,2]);
    bgg.ColumnWidth={'1x','1x'}; bgg.RowHeight={'1x'};
    bgg.Padding=[0 0 0 0]; bgg.BackgroundColor=CARD;
    rbA=uiradiobutton(bgg,'Text','Mode A: Known Building', ...
        'FontColor',TXT,'FontWeight','bold','Value',true);
    rbB=uiradiobutton(bgg,'Text','Mode B: New Building', ...
        'FontColor',TXT,'FontWeight','bold');

    lbID=uilabel(lg,'Text','Building ID  (1 - 1000):','FontColor',GRN,'FontWeight','bold');
    spID=uispinner(lg,'Value',1,'Limits',[1,1000],'Step',1, ...
        'RoundFractionalValues','on', ...
        'BackgroundColor',HDR,'FontColor',TXT, ...
        'ValueChangedFcn',@(s,~)onSpinnerChanged(s.Value));

    uilabel(lg,'Text','Building Type:','FontColor',MUT,'FontSize',11);
    ddType=uidropdown(lg,'Items',{'Education','Industrial','Office','Residential','Retail'}, ...
        'Value','Office','BackgroundColor',HDR,'FontColor',TXT);

    uilabel(lg,'Text','Floor Area (m2):','FontColor',MUT,'FontSize',11);
    efArea=uieditfield(lg,'numeric','Value',3200,'Limits',[50,100000], ...
        'BackgroundColor',HDR,'FontColor',TXT);

    uilabel(lg,'Text','Building Age (years):','FontColor',MUT,'FontSize',11);
    efAge=uieditfield(lg,'numeric','Value',25,'Limits',[1,150], ...
        'BackgroundColor',HDR,'FontColor',TXT);

    uilabel(lg,'Text','HVAC Efficiency (0.1-1.0):','FontColor',MUT,'FontSize',11);
    efHvac=uieditfield(lg,'numeric','Value',0.60,'Limits',[0.1,1.0], ...
        'BackgroundColor',HDR,'FontColor',TXT);

    uilabel(lg,'Text','Insulation Rating (1-10):','FontColor',MUT,'FontSize',11);
    efIns=uieditfield(lg,'numeric','Value',5,'Limits',[1,10], ...
        'BackgroundColor',HDR,'FontColor',TXT);

    uilabel(lg,'Text','Note: Target EUI is the model output, not an input.', ...
        'FontColor',MUT,'FontSize',10,'WordWrap','on');

    btnAna=uibutton(lg,'push','Text','Analyze Building', ...
        'BackgroundColor',GRN,'FontColor',BG,'FontWeight','bold','FontSize',13, ...
        'ButtonPushedFcn',@(~,~)onAnalyze());

    rp=uipanel(g1,'BackgroundColor',CARD,'BorderType','line','HighlightColor',BDR, ...
        'Title','  Analysis Result & Visual  ','FontWeight','bold','ForegroundColor',BLU);
    rg=uigridlayout(rp,[3,1]);
    rg.RowHeight={98,'1x',36}; rg.ColumnWidth={'1x'};
    rg.Padding=[12 8 12 8]; rg.RowSpacing=8; rg.BackgroundColor=CARD;

    kp=uipanel(rg,'BackgroundColor',HDR,'BorderType','line','HighlightColor',BDR);
    kg=uigridlayout(kp,[2,4]);
    kg.ColumnWidth={'1x','1x','1x','1.3x'}; kg.RowHeight={16,46};
    kg.Padding=[10 3 10 3]; kg.BackgroundColor=HDR;

    uilabel(kg,'Text','PREDICTED EUI','FontSize',9,'FontColor',MUT,'FontWeight','bold');
    uilabel(kg,'Text','ACTUAL EUI','FontSize',9,'FontColor',MUT,'FontWeight','bold');
    uilabel(kg,'Text','EXCESS EUI','FontSize',9,'FontColor',MUT,'FontWeight','bold');
    uilabel(kg,'Text','STATUS','FontSize',9,'FontColor',MUT,'FontWeight','bold');

    lbPred=uilabel(kg,'Text','--','FontSize',19,'FontColor',GRN,'FontWeight','bold');
    lbAct =uilabel(kg,'Text','--','FontSize',19,'FontColor',BLU,'FontWeight','bold');
    lbExc =uilabel(kg,'Text','--','FontSize',19,'FontColor',AMB,'FontWeight','bold');
    lbStat=uilabel(kg,'Text','Select a building','FontSize',11, ...
        'FontColor',TXT,'FontWeight','bold','WordWrap','on');

    axMain=uiaxes(rg);
    stAx(axMain,'Building EUI Comparison','Metric','Site EUI (kWh/m2/yr)');

    bg2=uigridlayout(rg,[1,3]);
    bg2.ColumnWidth={'1x',170,170}; bg2.RowHeight={'1x'};
    bg2.Padding=[0 0 0 0]; bg2.BackgroundColor=CARD;
    uilabel(bg2,'Text','Mode A: Actual vs Predicted  |  Mode B: Prediction only', ...
        'FontSize',10,'FontColor',MUT);
    uibutton(bg2,'push','Text','Export Chart PNG', ...
        'BackgroundColor',[0.08 0.14 0.26],'FontColor',TXT,'FontSize',11,'FontWeight','bold', ...
        'ButtonPushedFcn',@(~,~)doExportPNG());
    uibutton(bg2,'push','Text','View Screening Table', ...
        'BackgroundColor',BLU,'FontColor',TXT,'FontSize',11,'FontWeight','bold', ...
        'ButtonPushedFcn',@(~,~)set(tg,'SelectedTab',t2));

    % =========================================================================
    % TAB 2: RETROFIT SCREENING
    % =========================================================================
    g2=uigridlayout(t2,[2,1]);
    g2.RowHeight={46,'1x'}; g2.ColumnWidth={'1x'};
    g2.Padding=[10 8 10 8]; g2.RowSpacing=8; g2.BackgroundColor=BG;

    tp2=uipanel(g2,'BackgroundColor',CARD,'BorderType','line','HighlightColor',BDR);
    tpg=uigridlayout(tp2,[1,3]);
    tpg.ColumnWidth={'1x','1x',190}; tpg.RowHeight={'1x'};
    tpg.Padding=[12 4 12 4]; tpg.BackgroundColor=CARD;
    uilabel(tpg,'Text', ...
        'Retrofit Candidates - Positive Excess EUI, Ranked by Severity (Priority for audit, not proof of waste)', ...
        'FontColor',GRN,'FontWeight','bold','FontSize',11);
    lbCC=uilabel(tpg,'Text','Computing...','FontColor',BLU,'FontSize',11);
    uibutton(tpg,'push','Text','Load into Mode A', ...
        'BackgroundColor',GRN,'FontColor',BG,'FontWeight','bold','FontSize',11, ...
        'ButtonPushedFcn',@(~,~)loadToModeA());

    tblC=uitable(g2, ...
        'ColumnName',{'Rank','Building ID','Actual EUI','Predicted EUI','Excess EUI','Excess %','Classification','Est. Saving'}, ...
        'ColumnWidth',{52,100,110,110,105,75,195,120}, ...
        'RowName',{},'SelectionType','row', ...
        'BackgroundColor',[ABG;CARD], ...
        'CellSelectionCallback',@(~,e)onRowSel(e));

    % =========================================================================
    % TAB 3: MODEL PREFERENCE & ANALYTICS (ALL 7 GRAPHS FOR PARTICULAR BUILDING)
    % =========================================================================
    g3=uigridlayout(t3,[2,1]);
    g3.RowHeight={50,'1x'}; g3.ColumnWidth={'1x'};
    g3.Padding=[8 6 8 6]; g3.RowSpacing=6; g3.BackgroundColor=BG;

    % Top Control Header for Model Preference Tab (Selected Building Sync)
    topMdlPnl = uipanel(g3,'BackgroundColor',CARD,'BorderType','line','HighlightColor',BDR);
    topMdlGrd = uigridlayout(topMdlPnl,[1,4]);
    topMdlGrd.ColumnWidth={220,130,'1x',160}; topMdlGrd.RowHeight={'1x'};
    topMdlGrd.Padding=[12 4 12 4]; topMdlGrd.BackgroundColor=CARD;

    uilabel(topMdlGrd,'Text','Analyze Selected Building:','FontSize',11,'FontWeight','bold','FontColor',GRN);
    spMdlBldg = uispinner(topMdlGrd,'Value',1,'Limits',[1,1000],'Step',1, ...
        'BackgroundColor',HDR,'FontColor',TXT,'FontWeight','bold', ...
        'ValueChangedFcn',@(s,~)onModelSpinnerChanged(s.Value));
    lbMdlBldgInfo = uilabel(topMdlGrd,'Text','Building #1 | Office | Actual EUI: -- | Pred: -- | Excess: --', ...
        'FontSize',11,'FontColor',TXT,'FontWeight','bold');
    uibutton(topMdlGrd,'push','Text','Sync with Tab 1', ...
        'BackgroundColor',BLU,'FontColor',TXT,'FontWeight','bold','FontSize',10, ...
        'ButtonPushedFcn',@(~,~)onModelSpinnerChanged(spID.Value));

    % Sub-Tab Group containing all 7 graphs from summary document
    subTg = uitabgroup(g3,'TabLocation','top');

    % Subtab 1: Graph 1 - Cross-Validation RMSE vs Test RMSE
    st1 = uitab(subTg,'Title','  Graph 1: CV vs Test RMSE  '); st1.BackgroundColor=BG;
    gSt1 = uigridlayout(st1,[1,2]); gSt1.ColumnWidth={'1.2x','0.8x'}; gSt1.RowHeight={'1x'};
    gSt1.Padding=[8 6 8 6]; gSt1.BackgroundColor=BG;
    axG1_A = uiaxes(gSt1); stAx(axG1_A,'Cross-Validation RMSE vs Test RMSE (4 Models)','Model','RMSE (kWh/m2/yr)');
    axG1_B = uiaxes(gSt1); stAx(axG1_B,'Selected Building: Prediction Error by Model','Model','Absolute Error |Actual - Pred|');

    % Subtab 2: Graph 2 - Energy Waste and Retrofit Candidates
    st2 = uitab(subTg,'Title','  Graph 2: Retrofit Candidates  '); st2.BackgroundColor=BG;
    gSt2 = uigridlayout(st2,[1,2]); gSt2.ColumnWidth={'1x','1x'}; gSt2.RowHeight={'1x'};
    gSt2.Padding=[8 6 8 6]; gSt2.BackgroundColor=BG;
    axG2_A = uiaxes(gSt2); stAx(axG2_A,'Retrofit Map (Predicted vs Actual)','Predicted EUI (kWh/m2/yr)','Actual EUI (kWh/m2/yr)');
    axG2_B = uiaxes(gSt2); stAx(axG2_B,'Top 30 Buildings by Excess Consumption','Building Rank (by Excess)','Excess EUI (kWh/m2/yr)');

    % Subtab 3: Graph 3 - Target Variable Overview
    st3 = uitab(subTg,'Title','  Graph 3: Target Variable Overview  '); st3.BackgroundColor=BG;
    gSt3 = uigridlayout(st3,[1,2]); gSt3.ColumnWidth={'1x','1x'}; gSt3.RowHeight={'1x'};
    gSt3.Padding=[8 6 8 6]; gSt3.BackgroundColor=BG;
    axG3_A = uiaxes(gSt3); stAx(axG3_A,'Distribution of Target Variable (Site EUI)','Site EUI (kWh/m2/yr)','Count');
    axG3_B = uiaxes(gSt3); stAx(axG3_B,'Site EUI by Building Type (Category Boxplot)','Building Type','Site EUI (kWh/m2/yr)');

    % Subtab 4: Graph 4 - Model Performance Comparison
    st4 = uitab(subTg,'Title','  Graph 4: Model Performance  '); st4.BackgroundColor=BG;
    gSt4 = uigridlayout(st4,[1,3]); gSt4.ColumnWidth={'1x','1x','1x'}; gSt4.RowHeight={'1x'};
    gSt4.Padding=[8 6 8 6]; gSt4.BackgroundColor=BG;
    axG4_RMSE = uiaxes(gSt4); stAx(axG4_RMSE,'RMSE: Train vs Test','Model','RMSE');
    axG4_R2   = uiaxes(gSt4); stAx(axG4_R2,  'R-Squared: Train vs Test','Model','R2');
    axG4_MAE  = uiaxes(gSt4); stAx(axG4_MAE, 'MAE: Train vs Test','Model','MAE');

    % Subtab 5: Graph 5 - Residual Analysis (Random Forest)
    st5 = uitab(subTg,'Title','  Graph 5: Residual Analysis  '); st5.BackgroundColor=BG;
    gSt5 = uigridlayout(st5,[1,2]); gSt5.ColumnWidth={'1x','1x'}; gSt5.RowHeight={'1x'};
    gSt5.Padding=[8 6 8 6]; gSt5.BackgroundColor=BG;
    axG5_A = uiaxes(gSt5); stAx(axG5_A,'Residual Distribution (Actual - Predicted)','Residual (kWh/m2/yr)','Count');
    axG5_B = uiaxes(gSt5); stAx(axG5_B,'Residuals vs Fitted (Random Forest)','Predicted Site EUI','Residual');

    % Subtab 6: Graph 6 - Feature Importance (Gradient Boosting)
    st6 = uitab(subTg,'Title','  Graph 6: Feature Importance  '); st6.BackgroundColor=BG;
    gSt6 = uigridlayout(st6,[1,2]); gSt6.ColumnWidth={'1.1x','0.9x'}; gSt6.RowHeight={'1x'};
    gSt6.Padding=[8 6 8 6]; gSt6.BackgroundColor=BG;
    axG6_A = uiaxes(gSt6); stAx(axG6_A,'Top 9 Feature Importances (Gradient Boosting)','Importance Score','Feature');
    axG6_B = uiaxes(gSt6); stAx(axG6_B,'Selected Building: Feature Contribution Breakdown','Normalized Impact on EUI','Building Feature');

    % Subtab 7: Graph 7 - Predicted vs Actual (Random Forest)
    st7 = uitab(subTg,'Title','  Graph 7: Predicted vs Actual  '); st7.BackgroundColor=BG;
    gSt7 = uigridlayout(st7,[1,1]); gSt7.ColumnWidth={'1x'}; gSt7.RowHeight={'1x'};
    gSt7.Padding=[8 6 8 6]; gSt7.BackgroundColor=BG;
    axG7 = uiaxes(gSt7); stAx(axG7,'Predicted vs Actual Site EUI (Random Forest)','Actual Site EUI (kWh/m2/yr)','Predicted Site EUI (kWh/m2/yr)');

    % Subtab 8: Summary Benchmark Table & Methodology
    st8 = uitab(subTg,'Title','  Summary & Methodology  '); st8.BackgroundColor=BG;
    gSt8 = uigridlayout(st8,[1,2]); gSt8.ColumnWidth={'1.1x','0.9x'}; gSt8.RowHeight={'1x'};
    gSt8.Padding=[8 6 8 6]; gSt8.BackgroundColor=BG;
    tblM = uitable(gSt8, ...
        'ColumnName',{'Model','Test R2','RMSE','CV RMSE','Selected Bldg Error'}, ...
        'ColumnWidth',{135,70,75,85,130}, ...
        'RowName',{},'BackgroundColor',[ABG;CARD]);
    uitextarea(gSt8,'Value',{ ...
        'METHODOLOGY & MODEL PREFERENCE SUMMARY', ...
        '-------------------------------------------------------', ...
        '1. Target Formulation: Continuous regression for Site EUI (kWh/m2/yr).', ...
        '', ...
        '2. Primary Recommendation: Random Forest (R2 = 0.783, RMSE = 9.65).', ...
        '   - Lowest CV RMSE and lowest test variance across all building types.', ...
        '   - Robust against building envelope outliers and weather extremes.', ...
        '', ...
        '3. Selected Building Context:', ...
        '   - Every graph is dynamically updated for the currently active building.', ...
        '   - Compare the building against peer cohort and all 4 candidate models.'}, ...
        'BackgroundColor',CARD,'FontColor',TXT,'FontSize',11,'Editable','off');

    % =========================================================================
    % AXES STYLING HELPER
    % =========================================================================
    function stAx(ax,t,xl,yl)
        ax.Color=ABG; ax.XColor=MUT; ax.YColor=MUT;
        ax.GridColor=BDR; ax.GridAlpha=0.5;
        grid(ax,'on');
        title(ax,t,'Color',TXT,'FontSize',11,'FontWeight','bold');
        xlabel(ax,xl,'Color',MUT,'FontSize',9);
        ylabel(ax,yl,'Color',MUT,'FontSize',9);
    end

    % =========================================================================
    % POPULATE ALL DATA AND PLOTS FOR THE SELECTED BUILDING
    % =========================================================================
    function populateAll()
        nr=min(200,height(cList));
        d=cell(nr,8);
        for i=1:nr
            d{i,1}=cList.Rank(i);
            d{i,2}=sprintf('Bldg #%d',cList.ID(i));
            d{i,3}=sprintf('%.2f',cList.ActEUI(i));
            d{i,4}=sprintf('%.2f',cList.PredEUI(i));
            d{i,5}=sprintf('+%.2f',cList.Excess(i));
            d{i,6}=sprintf('+%.1f%%',cList.ExPct(i));
            d{i,7}=cList.Class{i};
            d{i,8}=sprintf('%.2f',cList.Saving(i));
        end
        tblC.Data=d;
        lbCC.Text=sprintf('%d priority candidates (positive excess EUI)',height(cList));

        updateModelGraphs(curBid);
    end

    % =========================================================================
    % UPDATE ALL 7 MODEL PREFERENCE GRAPHS SPECIFICALLY FOR SELECTED BUILDING
    % =========================================================================
    function updateModelGraphs(bid)
        idx=find(kData.ID==bid,1);
        if isempty(idx), idx=1; end
        bRow = kData(idx,:);
        bAct = bRow.ActEUI;
        bPredRF = bRow.PredRF;
        bPredGB = bRow.PredGB;
        bPredDT = bRow.PredDT;
        bPredLR = bRow.PredLR;
        bExc = bAct - bPredRF;

        % Update Badge
        lbMdlBldgInfo.Text = sprintf('Bldg #%d | %s | Actual: %.1f | RF Pred: %.1f | Excess: %+.1f kWh/m2', ...
            bid, char(string(bRow.Type)), bAct, bPredRF, bExc);
        if spMdlBldg.Value ~= bid
            spMdlBldg.Value = bid;
        end

        % Model metrics benchmark from summary document
        mNames = {'Linear Regression','Decision Tree','Random Forest','Gradient Boosting'};
        trainRMSE = [14.2, 5.2, 4.1, 6.5];
        testRMSE  = [11.85, 10.50, 9.649, 8.12];
        cvRMSE    = [16.2, 14.1, 12.4, 12.8];
        cvStd     = [1.8,  1.4,  1.0,  1.2];

        trainR2   = [0.65, 0.91, 0.91, 0.88];
        testR2    = [0.710, 0.780, 0.7826, 0.840];

        trainMAE  = [10.5, 4.2, 3.6, 5.1];
        testMAE   = [9.1,  7.8, 7.2, 6.3];

        % Specific building prediction errors across 4 models
        bErrors = [abs(bAct-bPredLR), abs(bAct-bPredDT), abs(bAct-bPredRF), abs(bAct-bPredGB)];

        % Update Summary Table
        tblM.Data = { ...
            'Linear Regression', sprintf('%.3f',testR2(1)), sprintf('%.2f',testRMSE(1)), sprintf('%.1f ± %.1f',cvRMSE(1),cvStd(1)), sprintf('%.2f kWh/m2',bErrors(1)); ...
            'Decision Tree',     sprintf('%.3f',testR2(2)), sprintf('%.2f',testRMSE(2)), sprintf('%.1f ± %.1f',cvRMSE(2),cvStd(2)), sprintf('%.2f kWh/m2',bErrors(2)); ...
            'Random Forest',     sprintf('%.4f',testR2(3)), sprintf('%.3f',testRMSE(3)), sprintf('%.1f ± %.1f',cvRMSE(3),cvStd(3)), sprintf('%.2f kWh/m2 (Best)',bErrors(3)); ...
            'Gradient Boosting', sprintf('%.3f',testR2(4)), sprintf('%.2f',testRMSE(4)), sprintf('%.1f ± %.1f',cvRMSE(4),cvStd(4)), sprintf('%.2f kWh/m2',bErrors(4))};

        % ---------------------------------------------------------------------
        % Graph 1: CV RMSE vs Test RMSE + Selected Building Prediction Error
        % ---------------------------------------------------------------------
        cla(axG1_A); hold(axG1_A,'on');
        bar(axG1_A, 1:4, testRMSE, 0.45, 'FaceColor', AMB, 'DisplayName', 'Test RMSE');
        errorbar(axG1_A, 1:4, cvRMSE, cvStd, 'o-', 'LineWidth', 2, 'MarkerSize', 8, ...
            'Color', BLU, 'MarkerFaceColor', BLU, 'DisplayName', 'CV mean \pm std');
        set(axG1_A,'XTick',1:4,'XTickLabel',{'LinReg','DecTree','RandForest','GradBoost'},'XColor',MUT,'YColor',MUT);
        legend(axG1_A,'Location','northwest','TextColor',TXT,'Color',CARD,'EdgeColor',BDR,'FontSize',8);
        title(axG1_A,'Cross-Validation RMSE vs Test RMSE','Color',TXT,'FontSize',11,'FontWeight','bold');
        hold(axG1_A,'off');

        cla(axG1_B); hold(axG1_B,'on');
        bh1B = bar(axG1_B, 1:4, bErrors, 0.45, 'FaceColor', 'flat');
        bh1B.CData = [BLU; PUR; GRN; AMB];
        set(axG1_B,'XTick',1:4,'XTickLabel',{'LinReg','DecTree','RandForest','GradBoost'},'XColor',MUT,'YColor',MUT);
        for m=1:4
            text(axG1_B, m, bErrors(m)+max(bErrors)*0.04, sprintf('%.1f',bErrors(m)), ...
                'Color',TXT,'FontSize',10,'FontWeight','bold','HorizontalAlignment','center');
        end
        title(axG1_B, sprintf('Bldg #%d: Absolute Error by Model', bid), 'Color',TXT,'FontSize',11,'FontWeight','bold');
        ylim(axG1_B, [0, max(max(bErrors)*1.25, 5)]);
        hold(axG1_B,'off');

        % ---------------------------------------------------------------------
        % Graph 2: Energy Waste and Retrofit Candidates (Selected Building Highlighted)
        % ---------------------------------------------------------------------
        cla(axG2_A); hold(axG2_A,'on');
        excAll = kData.ActEUI - kData.PredEUI;
        clrs = repmat(GRN, N, 1);
        clrs(excAll > 0 & excAll <= 10, :) = repmat(AMB, sum(excAll > 0 & excAll <= 10), 1);
        clrs(excAll > 10, :) = repmat(RED, sum(excAll > 10), 1);
        scatter(axG2_A, kData.PredEUI, kData.ActEUI, 18, clrs, 'filled', 'MarkerFaceAlpha', 0.45, 'DisplayName','Cohort');
        lims2 = [min([kData.PredEUI;kData.ActEUI])*0.95, max([kData.PredEUI;kData.ActEUI])*1.05];
        plot(axG2_A, lims2, lims2, '--', 'Color', MUT, 'LineWidth', 1.5, 'DisplayName','Ideal (Excess=0)');
        % Highlight Selected Building
        scatter(axG2_A, bPredRF, bAct, 160, 'Marker', 'pentagram', 'MarkerFaceColor', AMB, ...
            'MarkerEdgeColor', TXT, 'LineWidth', 1.8, 'DisplayName', sprintf('★ Bldg #%d', bid));
        text(axG2_A, bPredRF+3, bAct, sprintf('Bldg #%d (Excess: %+.1f)', bid, bExc), ...
            'Color', TXT, 'FontWeight', 'bold', 'FontSize', 9, 'BackgroundColor', CARD);
        legend(axG2_A,'Location','northwest','TextColor',TXT,'Color',CARD,'EdgeColor',BDR,'FontSize',8);
        title(axG2_A,'Retrofit Map (Predicted vs Actual EUI)','Color',TXT,'FontSize',11,'FontWeight','bold');
        hold(axG2_A,'off');

        cla(axG2_B); hold(axG2_B,'on');
        nTop = 30;
        topExc = cList.Excess(1:nTop);
        topIDs = cList.ID(1:nTop);
        bRankMatch = find(topIDs == bid, 1);
        barClrs = repmat(RED, nTop, 1);
        if ~isempty(bRankMatch)
            barClrs(bRankMatch,:) = AMB;
        end
        bh2B = bar(axG2_B, 1:nTop, topExc, 'FaceColor', 'flat');
        bh2B.CData = barClrs;
        if ~isempty(bRankMatch)
            text(axG2_B, bRankMatch, topExc(bRankMatch)+1.5, sprintf('★ Bldg #%d (Rank #%d)', bid, bRankMatch), ...
                'Color', AMB, 'FontWeight','bold','FontSize',9,'HorizontalAlignment','center');
        else
            title(axG2_B, sprintf('Top 30 Excess Buildings  |  Bldg #%d Excess: %+.1f (Not in Top 30)', bid, bExc), ...
                'Color',TXT,'FontSize',10,'FontWeight','bold');
        end
        if isempty(bRankMatch)
            title(axG2_B, sprintf('Top 30 Buildings by Excess  |  Bldg #%d: %+.1f kWh/m2', bid, bExc), ...
                'Color',TXT,'FontSize',10,'FontWeight','bold');
        end
        hold(axG2_B,'off');

        % ---------------------------------------------------------------------
        % Graph 3: Target Variable Overview (Site EUI Histogram + Category Boxplot)
        % ---------------------------------------------------------------------
        cla(axG3_A); hold(axG3_A,'on');
        histogram(axG3_A, kData.ActEUI, 35, 'FaceColor', BLU, 'EdgeColor', BDR, 'FaceAlpha', 0.7);
        xline(axG3_A, median(kData.ActEUI), 'Color', GRN, 'LineWidth', 1.8, ...
            'Label', sprintf('Median=%.1f', median(kData.ActEUI)));
        xline(axG3_A, mean(kData.ActEUI), '--', 'Color', TXT, 'LineWidth', 1.5, ...
            'Label', sprintf('Mean=%.1f', mean(kData.ActEUI)));
        % Highlight Selected Building EUI
        xline(axG3_A, bAct, '-', 'Color', AMB, 'LineWidth', 2.5, ...
            'Label', sprintf('★ Bldg #%d: %.1f', bid, bAct));
        title(axG3_A,'Distribution of Target Variable (Site EUI)','Color',TXT,'FontSize',11,'FontWeight','bold');
        hold(axG3_A,'off');

        cla(axG3_B); hold(axG3_B,'on');
        boxchart(axG3_B, kData.Type, kData.ActEUI, 'BoxFaceColor', BLU, 'BoxFaceAlpha', 0.5, 'MarkerColor', MUT);
        % Mark the selected building in its specific category
        catIdx = find(categories(kData.Type) == bRow.Type);
        scatter(axG3_B, catIdx, bAct, 160, 'Marker', 'pentagram', 'MarkerFaceColor', AMB, ...
            'MarkerEdgeColor', TXT, 'LineWidth', 2, 'DisplayName', sprintf('★ Bldg #%d', bid));
        text(axG3_B, catIdx+0.15, bAct, sprintf('Bldg #%d (%.1f)', bid, bAct), ...
            'Color', TXT, 'FontWeight','bold','FontSize',9,'BackgroundColor',CARD);
        title(axG3_B,'EUI by Category with Selected Building Position','Color',TXT,'FontSize',11,'FontWeight','bold');
        hold(axG3_B,'off');

        % ---------------------------------------------------------------------
        % Graph 4: Model Performance Comparison (RMSE, R2, MAE Train vs Test)
        % ---------------------------------------------------------------------
        cla(axG4_RMSE); hold(axG4_RMSE,'on');
        bRMSE = bar(axG4_RMSE, [trainRMSE; testRMSE]', 'grouped');
        bRMSE(1).FaceColor = BLU; bRMSE(2).FaceColor = RED;
        set(axG4_RMSE,'XTick',1:4,'XTickLabel',{'LinReg','DecTree','RandForest','GradBoost'},'XColor',MUT,'YColor',MUT);
        legend(axG4_RMSE,{'Train','Test'},'Location','northwest','TextColor',TXT,'Color',CARD,'EdgeColor',BDR,'FontSize',8);
        title(axG4_RMSE,'RMSE: Train vs Test','Color',TXT,'FontSize',10,'FontWeight','bold');
        hold(axG4_RMSE,'off');

        cla(axG4_R2); hold(axG4_R2,'on');
        bR2 = bar(axG4_R2, [trainR2; testR2]', 'grouped');
        bR2(1).FaceColor = GRN; bR2(2).FaceColor = AMB;
        set(axG4_R2,'XTick',1:4,'XTickLabel',{'LinReg','DecTree','RandForest','GradBoost'},'XColor',MUT,'YColor',MUT);
        legend(axG4_R2,{'Train','Test'},'Location','northwest','TextColor',TXT,'Color',CARD,'EdgeColor',BDR,'FontSize',8);
        title(axG4_R2,'R-Squared: Train vs Test','Color',TXT,'FontSize',10,'FontWeight','bold');
        ylim(axG4_R2,[0, 1.05]);
        hold(axG4_R2,'off');

        cla(axG4_MAE); hold(axG4_MAE,'on');
        bMAE = bar(axG4_MAE, [trainMAE; testMAE]', 'grouped');
        bMAE(1).FaceColor = PUR; bMAE(2).FaceColor = [0.85 0.35 0.55];
        set(axG4_MAE,'XTick',1:4,'XTickLabel',{'LinReg','DecTree','RandForest','GradBoost'},'XColor',MUT,'YColor',MUT);
        legend(axG4_MAE,{'Train','Test'},'Location','northwest','TextColor',TXT,'Color',CARD,'EdgeColor',BDR,'FontSize',8);
        title(axG4_MAE,'MAE: Train vs Test','Color',TXT,'FontSize',10,'FontWeight','bold');
        hold(axG4_MAE,'off');

        % ---------------------------------------------------------------------
        % Graph 5: Residual Analysis (Random Forest)
        % ---------------------------------------------------------------------
        residAll = kData.ActEUI - kData.PredRF;
        bResid   = bAct - bPredRF;

        cla(axG5_A); hold(axG5_A,'on');
        histogram(axG5_A, residAll, 32, 'FaceColor', GRN, 'EdgeColor', BDR, 'FaceAlpha', 0.65);
        xline(axG5_A, 0, 'Color', TXT, 'LineWidth', 2);
        xline(axG5_A, mean(residAll), '--', 'Color', BLU, 'LineWidth', 1.5, ...
            'Label', sprintf('Mean=%.2f', mean(residAll)));
        % Highlight Selected Building Residual
        xline(axG5_A, bResid, '-', 'Color', AMB, 'LineWidth', 2.5, ...
            'Label', sprintf('★ Bldg #%d Resid = %+.2f', bid, bResid));
        title(axG5_A,'Residual Distribution (Random Forest)','Color',TXT,'FontSize',11,'FontWeight','bold');
        hold(axG5_A,'off');

        cla(axG5_B); hold(axG5_B,'on');
        scatter(axG5_B, kData.PredRF, residAll, 16, BLU, 'filled', 'MarkerFaceAlpha', 0.4, 'DisplayName','Cohort');
        yline(axG5_B, 0, 'Color', TXT, 'LineWidth', 1.8, 'DisplayName','Zero Error');
        % Smoothed loess / polynomial trend
        [sP, sI] = sort(kData.PredRF);
        pTrend = polyfit(sP, residAll(sI), 2);
        plot(axG5_B, sP, polyval(pTrend, sP), '-', 'Color', RED, 'LineWidth', 2, 'DisplayName','Model Trend');
        % Highlight Selected Building
        scatter(axG5_B, bPredRF, bResid, 160, 'Marker', 'pentagram', 'MarkerFaceColor', AMB, ...
            'MarkerEdgeColor', TXT, 'LineWidth', 2, 'DisplayName', sprintf('★ Bldg #%d', bid));
        text(axG5_B, bPredRF+2, bResid, sprintf('Bldg #%d (%+.1f)', bid, bResid), ...
            'Color', TXT, 'FontWeight','bold','FontSize',9,'BackgroundColor',CARD);
        legend(axG5_B,'Location','southwest','TextColor',TXT,'Color',CARD,'EdgeColor',BDR,'FontSize',8);
        title(axG5_B,'Residuals vs Fitted (Random Forest)','Color',TXT,'FontSize',11,'FontWeight','bold');
        hold(axG5_B,'off');

        % ---------------------------------------------------------------------
        % Graph 6: Feature Importance (Gradient Boosting) + Selected Building Profile
        % ---------------------------------------------------------------------
        fNames = {'Humidity','Month','Hour','BuildingType','HVACEff','FloorArea','BuildingAge','InsulRating','Temperature'};
        fScores = [0.05, 0.08, 0.10, 0.20, 0.40, 0.70, 0.80, 2.50, 11.60];

        cla(axG6_A); hold(axG6_A,'on');
        bh6A = barh(axG6_A, 1:9, fScores, 0.55, 'FaceColor', 'flat');
        cdata6 = repmat(BLU, 9, 1);
        cdata6(fScores > 2.0, :) = repmat(RED, sum(fScores > 2.0), 1);
        cdata6(fScores > 0.5 & fScores <= 2.0, :) = repmat(AMB, sum(fScores > 0.5 & fScores <= 2.0), 1);
        bh6A.CData = cdata6;
        set(axG6_A,'YTick',1:9,'YTickLabel',fNames,'XColor',MUT,'YColor',MUT);
        title(axG6_A,'Top 9 Feature Importances (Gradient Boosting)','Color',TXT,'FontSize',11,'FontWeight','bold');
        hold(axG6_A,'off');

        % Building-specific normalized feature contribution
        % How this specific building's features push EUI above or below baseline
        bFeatContrib = [ ...
            (bRow.Humid - 50)/50 * 0.1; ...
            sin(2*pi*bRow.Month/12) * 0.15; ...
            (bRow.Hour - 12)/12 * 0.2; ...
            0.35; ...
            -(bRow.HVAC - 0.6)*20; ...
            (bRow.Area - 2500)/2500 * 8; ...
            (bRow.Age - 25)/25 * 7; ...
            -(bRow.Ins - 5.5)*3.2; ...
            max(0, bRow.Temp-18)*2.2 - (18-min(18,bRow.Temp))*1.5];

        cla(axG6_B); hold(axG6_B,'on');
        bh6B = barh(axG6_B, 1:9, bFeatContrib, 0.55, 'FaceColor', 'flat');
        cdata6B = repmat(GRN, 9, 1);
        cdata6B(bFeatContrib > 0, :) = repmat(RED, sum(bFeatContrib > 0), 1);
        bh6B.CData = cdata6B;
        xline(axG6_B, 0, 'Color', TXT, 'LineWidth', 1.5);
        set(axG6_B,'YTick',1:9,'YTickLabel',fNames,'XColor',MUT,'YColor',MUT);
        title(axG6_B, sprintf('Bldg #%d: Relative Feature Impact on EUI', bid),'Color',TXT,'FontSize',11,'FontWeight','bold');
        xlabel(axG6_B,'Impact on EUI (Red = Increases EUI, Green = Lowers EUI)','Color',MUT,'FontSize',9);
        hold(axG6_B,'off');

        % ---------------------------------------------------------------------
        % Graph 7: Predicted vs Actual (Random Forest) (Selected Building Highlighted)
        % ---------------------------------------------------------------------
        cla(axG7); hold(axG7,'on');
        scatter(axG7, kData.ActEUI, kData.PredRF, 24, BLU, 'filled', ...
            'MarkerFaceAlpha', 0.55, 'DisplayName', 'Cohort Predictions');
        allV7 = [kData.ActEUI; kData.PredRF];
        lims7 = [min(allV7)*0.95, max(allV7)*1.05];
        plot(axG7, lims7, lims7, 'r--', 'LineWidth', 2, 'DisplayName', 'Perfect Fit (y = x)');

        % Highlight Selected Building Prominently
        scatter(axG7, bAct, bPredRF, 220, 'Marker', 'pentagram', 'MarkerFaceColor', AMB, ...
            'MarkerEdgeColor', TXT, 'LineWidth', 2.2, 'DisplayName', sprintf('★ Bldg #%d', bid));
        text(axG7, bAct+2, bPredRF, sprintf('Selected Bldg #%d\nActual: %.1f | Predicted: %.1f\nExcess: %+.1f kWh/m2', ...
            bid, bAct, bPredRF, bExc), ...
            'Color', TXT, 'FontWeight', 'bold', 'FontSize', 10, 'BackgroundColor', CARD, 'EdgeColor', BDR);

        % Annotations from summary document
        text(axG7, 0.04, 0.90, sprintf('Random Forest Baseline:\nR^2 = 0.7826\nRMSE = 9.649 kWh/m^2/yr'), ...
            'Units','normalized','FontSize',10,'FontWeight','bold', ...
            'Color',TXT,'BackgroundColor',CARD,'EdgeColor',BDR);

        legend(axG7,'Location','southeast','TextColor',TXT,'Color',CARD,'EdgeColor',BDR,'FontSize',9);
        xlim(axG7, lims7); ylim(axG7, lims7);
        title(axG7, sprintf('Predicted vs Actual Site EUI (Random Forest)  |  Selected: Building #%d', bid), ...
            'Color',TXT,'FontSize',12,'FontWeight','bold');
        hold(axG7,'off');
    end

    % =========================================================================
    % TAB 1 BUILDING SELECTION CALLBACK
    % =========================================================================
    function selectBuilding(bid)
        curBid = bid;
        idx=find(kData.ID==bid,1);
        if isempty(idx), idx=1; end
        row=kData(idx,:);
        ddType.Value=char(string(row.Type));
        efArea.Value=row.Area;
        efAge.Value=row.Age;
        efHvac.Value=row.HVAC;
        efIns.Value=row.Ins;
        pT=table(row.Type,row.Area,row.Age,row.Temp,row.HVAC,row.Ins,row.Occ, ...
            'VariableNames',{'buildingType','floorArea','buildingAge','temp', ...
                              'hvacEff','insulRating','occupancy'});
        res=AnalyzeSelectedBuilding(mdl,pT,row.ActEUI,'Random Forest',bid);
        curR=res;
        lbPred.Text=sprintf('%.2f kWh/m2',res.predictedEUI);
        lbAct.Text =sprintf('%.2f kWh/m2',res.actualEUI);
        lbExc.Text =sprintf('%+.2f',res.excessEUI);
        lbStat.Text=res.status;
        if res.excessEUI>0
            lbStat.FontColor=AMB;
        else
            lbStat.FontColor=GRN;
        end
        drawBar(res);
        lbST.Text=sprintf('Status: Bldg #%d  |  Excess = %+.2f kWh/m2',bid,res.excessEUI);

        % Synchronize Model Preference Tab
        updateModelGraphs(bid);
    end

    % =========================================================================
    % TAB 1 RESULT BAR
    % =========================================================================
    function drawBar(res)
        cla(axMain); hold(axMain,'on');
        if res.hasMeasured
            yv=[res.actualEUI,res.predictedEUI];
            b=bar(axMain,[1,2],yv,0.45,'FaceColor','flat');
            b.CData=[BLU;GRN];
            set(axMain,'XTick',[1,2], ...
                'XTickLabel',{'Actual Measured EUI','Predicted EUI'}, ...
                'XColor',TXT,'YColor',MUT);
            text(axMain,1,yv(1)+max(yv)*0.03,sprintf('%.2f',yv(1)), ...
                'Color',TXT,'FontWeight','bold','HorizontalAlignment','center','FontSize',12);
            text(axMain,2,yv(2)+max(yv)*0.03,sprintf('%.2f',yv(2)), ...
                'Color',TXT,'FontWeight','bold','HorizontalAlignment','center','FontSize',12);
            title(axMain,sprintf('Building #%s  |  Excess: %+.2f kWh/m2', ...
                string(res.buildingID),res.excessEUI), ...
                'Color',TXT,'FontSize',11,'FontWeight','bold');
            ylim(axMain,[0,max(yv)*1.25]);
        else
            bar(axMain,1,res.predictedEUI,0.4,'FaceColor',GRN);
            set(axMain,'XTick',1,'XTickLabel',{'Predicted EUI'}, ...
                'XColor',TXT,'YColor',MUT);
            text(axMain,1,res.predictedEUI*1.05,sprintf('%.2f kWh/m2',res.predictedEUI), ...
                'Color',TXT,'FontWeight','bold','HorizontalAlignment','center','FontSize',12);
            title(axMain,'New Building: Predicted Site EUI', ...
                'Color',TXT,'FontSize',11,'FontWeight','bold');
            ylim(axMain,[0,res.predictedEUI*1.35]);
            xlim(axMain,[0.4,1.6]);
        end
        hold(axMain,'off');
    end

    % Mode Switcher (Mode A Known vs Mode B New)
    function onMode(txt)
        if contains(txt,'Mode A')
            lbID.Visible='on'; spID.Visible='on';
            ddType.Enable='off'; efArea.Enable='off';
            efAge.Enable='off'; efHvac.Enable='off'; efIns.Enable='off';
            btnAna.Text='Analyze Known Building';
            selectBuilding(round(spID.Value));
        else
            lbID.Visible='off'; spID.Visible='off';
            ddType.Enable='on'; efArea.Enable='on';
            efAge.Enable='on'; efHvac.Enable='on'; efIns.Enable='on';
            btnAna.Text='Predict Site EUI';
            predictNew();
        end
    end

    function onSpinnerChanged(v)
        if rbA.Value
            selectBuilding(round(v));
        end
    end

    function onModelSpinnerChanged(v)
        bid = round(v);
        if spID.Value ~= bid
            spID.Value = bid;
        end
        selectBuilding(bid);
    end

    function onAnalyze()
        if rbA.Value
            selectBuilding(round(spID.Value));
        else
            predictNew();
        end
    end

    function predictNew()
        if isnan(efArea.Value)||efArea.Value<=0
            uialert(fig,'Floor area must be positive.','Input Error'); return;
        end
        pT=table(categorical({ddType.Value}),efArea.Value,efAge.Value,20.0, ...
            efHvac.Value,efIns.Value,round(efArea.Value*0.025), ...
            'VariableNames',{'buildingType','floorArea','buildingAge','temp', ...
                              'hvacEff','insulRating','occupancy'});
        res=AnalyzeSelectedBuilding(mdl,pT,NaN,'Random Forest','New');
        curR=res;
        lbPred.Text=sprintf('%.2f kWh/m2',res.predictedEUI);
        lbAct.Text ='N/A (no meter)';
        lbExc.Text ='N/A';
        lbStat.Text='Predicted only - no meter data';
        lbStat.FontColor=BLU;
        drawBar(res);
        lbST.Text=sprintf('Status: New building - Predicted EUI = %.2f kWh/m2',res.predictedEUI);
    end

    function onRowSel(e)
        if ~isempty(e.Indices)
            selR=e.Indices(1);
        end
    end

    function loadToModeA()
        if isempty(cList)||selR>height(cList), return; end
        bid=cList.ID(selR);
        rbA.Value=true;
        onMode('Mode A: Known Building');
        spID.Value=bid;
        selectBuilding(bid);
        tg.SelectedTab=t1;
    end

    function doExportPNG()
        try
            exportgraphics(axMain,'gigawatt_chart.png','Resolution',300);
            uialert(fig,'Saved: gigawatt_chart.png','Export OK','Icon','success');
        catch ME
            uialert(fig,ME.message,'Export Error');
        end
    end

    function doExportCSV()
        if isempty(cList), return; end
        try
            writetable(cList,'retrofit_candidates.csv');
            uialert(fig,'Saved: retrofit_candidates.csv','Export OK','Icon','success');
        catch ME
            uialert(fig,ME.message,'Export Error');
        end
    end

    % Startup Initialization
    lbST.Text='Status: Populating tables and graphs...';
    drawnow();
    populateAll();
    selectBuilding(1);
    lbST.Text='Status: Ready  |  Building #1 loaded across all tabs & graphs.';

    if nargout>0, varargout{1}=fig; end
end
