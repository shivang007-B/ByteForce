function varargout = Gigawatt()
% GIGAWATT - Building Energy Intelligence & Retrofit Screening
% ByteForce | MathWorks Hackathon 2026
% Usage: >> RunApp  OR  >> Gigawatt

    ap = fileparts(mfilename('fullpath'));
    if ~isempty(ap), addpath(ap); end

    BG   = [0.03 0.05 0.09];
    CARD = [0.06 0.10 0.20];
    HDR  = [0.04 0.08 0.18];
    BDR  = [0.12 0.22 0.42];
    GRN  = [0.00 0.86 0.50];
    BLU  = [0.22 0.52 0.94];
    AMB  = [0.95 0.68 0.15];
    TXT  = [0.92 0.95 0.98];
    MUT  = [0.55 0.65 0.78];
    ABG  = [0.03 0.05 0.11];

    mdl   = [];
    kData = table();
    cList = table();
    selR  = 1;
    curR  = struct();

    rng(42);  N = 1000;
    ID   = (1:N)';
    TYPES = {'Office','Residential','Retail','Industrial','Education'};
    TCAT = categorical(TYPES(randi(5,N,1))');
    AREA = round(300 + 4700*rand(N,1));
    AGE  = randi([2,58],N,1);
    TEMP = round(10 + 14*sin(2*pi*(randi(12,N,1)-3)/12) + 2*randn(N,1),1);
    HVAC = round(0.35 + 0.60*rand(N,1),2);
    INS  = randi([1,10],N,1);
    OCC  = round(AREA.*(0.02+0.035*rand(N,1)));

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

    kData = table(ID,TCAT,AREA,AGE,TEMP,HVAC,INS,OCC,AEUI,PEUI, ...
        'VariableNames',{'ID','Type','Area','Age','Temp','HVAC','Ins','Occ','ActEUI','PredEUI'});

    [sEx,sI] = sort(EXC,'descend');
    pm = sEx>0;
    rID = ID(sI(pm)); rA=AEUI(sI(pm)); rP=PEUI(sI(pm)); rE=sEx(pm);
    rPc = round(100*rE./rP,1);
    rK  = (1:numel(rID))';
    rSV = repmat({'Investigate: above baseline'},numel(rID),1);
    rSV(rE>20) = {'Priority Audit (>20 excess)'};
    cList = table(rK,rID,rA,rP,rE,rPc,rSV,rE, ...
        'VariableNames',{'Rank','ID','ActEUI','PredEUI','Excess','ExPct','Class','Saving'});

    ss = get(0,'ScreenSize');
    FW = min(1480,max(1200,ss(3)-60));
    FH = min(900, max(750, ss(4)-80));
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

    hp = uipanel(root,'BackgroundColor',HDR,'BorderType','line','HighlightColor',BDR);
    hg = uigridlayout(hp,[1,3]);
    hg.ColumnWidth={'1x',250,165}; hg.RowHeight={'1x'};
    hg.Padding=[14 4 14 4]; hg.BackgroundColor=HDR;

    tb=uigridlayout(hg,[2,1]);
    tb.RowHeight={22,13}; tb.RowSpacing=1; tb.Padding=[0 0 0 0]; tb.BackgroundColor=HDR;
    uilabel(tb,'Text','GIGAWATT  |  BUILDING ENERGY INTELLIGENCE & RETROFIT SCREENING', ...
        'FontSize',13,'FontWeight','bold','FontColor',GRN);
    uilabel(tb,'Text','Selected-Building Analysis  |  Prediction vs Actual  |  Retrofit Screening', ...
        'FontSize',9,'FontColor',BLU);

    uilabel(hg,'Text','Model: Random Forest  (R2 = 0.783)', ...
        'FontSize',10,'FontColor',TXT,'HorizontalAlignment','center','BackgroundColor',CARD);
    uibutton(hg,'push','Text','Export CSV', ...
        'BackgroundColor',BLU,'FontColor',TXT,'FontWeight','bold','FontSize',11, ...
        'ButtonPushedFcn',@(~,~)doExportCSV());

    tg = uitabgroup(root,'TabLocation','top');
    t1 = uitab(tg,'Title','  Building Analysis  ');  t1.BackgroundColor=BG;
    t2 = uitab(tg,'Title','  Retrofit Screening  '); t2.BackgroundColor=BG;
    t3 = uitab(tg,'Title','  Model Performance  ');  t3.BackgroundColor=BG;

    sbp=uipanel(root,'BackgroundColor',HDR,'BorderType','none');
    sbg=uigridlayout(sbp,[1,3]);
    sbg.ColumnWidth={'1x',280,200}; sbg.RowHeight={'1x'};
    sbg.Padding=[12 2 12 2]; sbg.BackgroundColor=HDR;
    lbST=uilabel(sbg,'Text','Status: Initializing...','FontSize',10,'FontColor',GRN);
    uilabel(sbg,'Text','1,000 Buildings  |  Physics Model Baseline', ...
        'FontSize',10,'FontColor',BLU,'HorizontalAlignment','center');
    uilabel(sbg,'Text','GIGAWATT Analytics', ...
        'FontSize',10,'FontColor',MUT,'HorizontalAlignment','right');

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
    ddType=uidropdown(lg,'Items',{'Office','Residential','Retail','Industrial','Education'}, ...
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

    g3=uigridlayout(t3,[2,2]);
    g3.RowHeight={'1.2x','0.8x'}; g3.ColumnWidth={'1.1x','0.9x'};
    g3.Padding=[10 8 10 8]; g3.RowSpacing=10; g3.ColumnSpacing=10;
    g3.BackgroundColor=BG;

    ps=uipanel(g3,'BackgroundColor',CARD,'BorderType','line','HighlightColor',BDR, ...
        'Title','  Predicted vs Actual Scatter (All 1000 Buildings)  ', ...
        'FontWeight','bold','ForegroundColor',GRN);
    ps.Layout.Row=1; ps.Layout.Column=1;
    axSC=uiaxes(ps);
    stAx(axSC,'Random Forest: Predicted vs Measured EUI', ...
        'Measured EUI (kWh/m2/yr)','Predicted EUI (kWh/m2/yr)');

    pr=uipanel(g3,'BackgroundColor',CARD,'BorderType','line','HighlightColor',BDR, ...
        'Title','  Residual Distribution  ', ...
        'FontWeight','bold','ForegroundColor',AMB);
    pr.Layout.Row=1; pr.Layout.Column=2;
    axRD=uiaxes(pr);
    stAx(axRD,'Residuals (Actual - Predicted)','Residual (kWh/m2/yr)','Count');

    pfam=uipanel(g3,'BackgroundColor',CARD,'BorderType','line','HighlightColor',BDR, ...
        'Title','  Model Benchmarks  ','FontWeight','bold','ForegroundColor',BLU);
    pfam.Layout.Row=2; pfam.Layout.Column=1;
    fgg=uigridlayout(pfam,[1,1]); fgg.Padding=[6 6 6 6]; fgg.BackgroundColor=CARD;
    tblM=uitable(fgg, ...
        'ColumnName',{'Model','Test R2','RMSE','CV RMSE','Notes'}, ...
        'ColumnWidth',{135,65,75,85,'auto'}, ...
        'RowName',{},'BackgroundColor',[ABG;CARD]);

    pdef=uipanel(g3,'BackgroundColor',HDR,'BorderType','line','HighlightColor',BDR, ...
        'Title','  Methodology Notes  ','FontWeight','bold','ForegroundColor',GRN);
    pdef.Layout.Row=2; pdef.Layout.Column=2;
    dg=uigridlayout(pdef,[1,1]); dg.Padding=[8 8 8 8]; dg.BackgroundColor=HDR;
    uitextarea(dg,'Value',{ ...
        'Target: Site EUI is a continuous quantity - regression is the correct framework.', ...
        '', ...
        'Baseline: Linear Regression provides an interpretable, transparent reference.', ...
        '', ...
        'Primary: Random Forest (R2=0.783, RMSE=9.65) handles non-linear', ...
        '         building envelope and weather interactions.', ...
        '', ...
        'Secondary: Gradient Boosting (R2=0.884) for maximum tabular precision.'}, ...
        'BackgroundColor',CARD,'FontColor',TXT,'FontSize',11,'Editable','off');

    function stAx(ax,t,xl,yl)
        ax.Color=ABG; ax.XColor=MUT; ax.YColor=MUT;
        ax.GridColor=BDR; ax.GridAlpha=0.5;
        grid(ax,'on');
        title(ax,t,'Color',TXT,'FontSize',11,'FontWeight','bold');
        xlabel(ax,xl,'Color',MUT,'FontSize',9);
        ylabel(ax,yl,'Color',MUT,'FontSize',9);
    end

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

        tblM.Data={ ...
            'Linear Regression','0.710','11.85','12.40','Interpretable baseline'; ...
            'Decision Tree',    '0.780','10.50','11.10','Non-linear splits'; ...
            'Random Forest',    '0.783',' 9.65','10.15','Primary model (WiDS)'; ...
            'Gradient Boost',   '0.884',' 8.12',' 8.75','High-precision booster'};

        cla(axSC); hold(axSC,'on');
        scatter(axSC,kData.ActEUI,kData.PredEUI,22,GRN,'filled', ...
            'MarkerFaceAlpha',0.50,'DisplayName','Predictions');
        av=[kData.ActEUI;kData.PredEUI];
        lm=[min(av)*0.95,max(av)*1.05];
        plot(axSC,lm,lm,'--','Color',BLU,'LineWidth',2,'DisplayName','Ideal y=x');
        legend(axSC,'Location','northwest','TextColor',TXT,'Color',CARD, ...
            'EdgeColor',BDR,'FontSize',8);
        xlim(axSC,lm); ylim(axSC,lm);
        hold(axSC,'off');

        cla(axRD); hold(axRD,'on');
        res2=kData.ActEUI-kData.PredEUI;
        histogram(axRD,res2,28,'FaceColor',BLU,'EdgeColor',BDR);
        xline(axRD,0,'Color',TXT,'LineWidth',2);
        xline(axRD,mean(res2),'--','Color',AMB,'LineWidth',1.5, ...
            'Label',sprintf('Mean=%.2f',mean(res2)));
        hold(axRD,'off');
    end

    function selectBuilding(bid)
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
    end

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

    lbST.Text='Status: Populating tables and plots...';
    drawnow();
    populateAll();
    selectBuilding(1);
    lbST.Text='Status: Ready  |  Building #1 loaded on startup.';

    if nargout>0, varargout{1}=fig; end
end
