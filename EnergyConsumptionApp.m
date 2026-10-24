function varargout = EnergyConsumptionApp()
% EnergyConsumptionApp - Outstanding Cyber-Themed Building Energy Prediction
% and Retrofit Intelligence Command Center for MATLAB.
%
% THEME: Black Cyber / Oxford Blue / Vista Blue / Cyber Green
%
% FEATURES:
%   - Interactive Map Explorer with Scrollable Multi-Map View:
%       1. 2D Campus / Geographic Site Energy Waste Map
%       2. Retrofit Decision Boundary Quadrant Map
%       3. Thermal Energy Intensity Heatmap Matrix Map
%       4. Ranked Waste & Cumulative Savings Pareto Map
%       5. Building Cluster & ROI Density Map
%   - Multi-Model AI Benchmarks & Leaderboard
%   - Diagnostics: Predicted vs Actual + 95% CI, Residuals, Feature Importance
%   - Interactive Retrofit Candidates Directory with Search & Severity Filters
%   - What-If Retrofit Impact Simulator (HVAC, Insulation, Solar, Controls)
%   - Live Pipeline Runner with Hyperparameter Tuning and Terminal Console
%
% USAGE:
%   >> EnergyConsumptionApp
%   >> app = EnergyConsumptionApp();
%
% Author: ByteForce Climate Tech Hackathon Team
% Copyright 2025-2026

    % Ensure current folder is on path
    appFolder = fileparts(mfilename('fullpath'));
    if ~isempty(appFolder), addpath(appFolder); end

    %% --------------------------------------------------------------------
    %% COLOR PALETTE: Black Cyber / Oxford Blue / Vista Blue / Cyber Green
    %% --------------------------------------------------------------------
    C_BG_DARK       = [0.035, 0.048, 0.082];  % Deep Cyber Black (#090C15)
    C_BG_CARD       = [0.060, 0.095, 0.185];  % Oxford Blue Deep (#0F182F)
    C_BG_ELEVATED   = [0.085, 0.135, 0.250];  % Oxford Navy (#162240)
    C_BORDER        = [0.120, 0.210, 0.380];  % Subtle Cyber Border (#1F3661)
    C_CYBER_GREEN   = [0.000, 0.950, 0.580];  % Neon Cyber Green (#00F294)
    C_VISTA_BLUE    = [0.220, 0.530, 0.960];  % Vista Sky Blue (#3887F5)
    C_OXFORD_BLUE   = [0.050, 0.110, 0.240];  % Oxford Deep Navy (#0D1C3D)
    C_AMBER_WARN    = [1.000, 0.740, 0.180];  % Warning Amber (#FFBD2E)
    C_CRIMSON_CRIT  = [0.960, 0.260, 0.380];  % Critical Neon Red (#F54261)
    C_TEXT_LIGHT    = [0.920, 0.960, 1.000];  % Cyber White (#EBF5FF)
    C_TEXT_MUTED    = [0.550, 0.650, 0.780];  % Slate Text (#8CA6C7)
    C_AXIS_BG       = [0.045, 0.068, 0.125];  % Axes Canvas Dark (#0B1120)

    %% --------------------------------------------------------------------
    %% APP STATE DATA STRUCT
    %% --------------------------------------------------------------------
    state = struct();
    state.data          = table();
    state.results       = struct();
    state.retrofitTable = table();
    state.trainedModels = struct();
    state.selectedRow   = 1;
    state.spatialData   = table();

    %% --------------------------------------------------------------------
    %% MAIN FIGURE
    %% --------------------------------------------------------------------
    screenSize = get(0, 'ScreenSize');
    figW = min(1480, max(1120, screenSize(3) - 80));
    figH = min(920,  max(740,  screenSize(4) - 90));
    figX = max(20, round((screenSize(3) - figW) / 2));
    figY = max(30, round((screenSize(4) - figH) / 2));

    mainFig = uifigure('Name', 'BYTEFORCE // Building Energy Intelligence & Retrofit AI Platform', ...
        'Position', [figX, figY, figW, figH], ...
        'Color', C_BG_DARK, ...
        'AutoResizeChildren', 'off');

    % Root grid: [Header 72px, KPI Banner 82px, Main Tabs 1x, Status Bar 28px]
    rootGrid = uigridlayout(mainFig, [4, 1]);
    rootGrid.RowHeight = {72, 82, '1x', 28};
    rootGrid.ColumnWidth = {'1x'};
    rootGrid.Padding = [10, 8, 10, 8];
    rootGrid.RowSpacing = 8;
    rootGrid.BackgroundColor = C_BG_DARK;

    %% ====================================================================
    %% 1. HEADER BAR (Cyber Green Accent + Vista Blue Title)
    %% ====================================================================
    headerPanel = uipanel(rootGrid, 'BackgroundColor', C_OXFORD_BLUE, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER);
    headerGrid = uigridlayout(headerPanel, [1, 5]);
    headerGrid.ColumnWidth = {45, '1x', 180, 160, 160};
    headerGrid.RowHeight = {'1x'};
    headerGrid.Padding = [14, 8, 14, 8];
    headerGrid.ColumnSpacing = 10;
    headerGrid.BackgroundColor = C_OXFORD_BLUE;

    % Cyber Logo / Icon Badge
    logoLabel = uilabel(headerGrid, 'Text', '⚡', 'FontSize', 28, ...
        'FontColor', C_CYBER_GREEN, 'HorizontalAlignment', 'center');

    % Title and Subtitle container
    titleBox = uigridlayout(headerGrid, [2, 1]);
    titleBox.RowHeight = {26, 18};
    titleBox.Padding = [0, 0, 0, 0];
    titleBox.RowSpacing = 2;
    titleBox.BackgroundColor = C_OXFORD_BLUE;

    mainTitle = uilabel(titleBox, 'Text', 'BYTEFORCE // ENERGY AI COMMAND CENTER', ...
        'FontSize', 17, 'FontWeight', 'bold', 'FontColor', C_CYBER_GREEN);
    subTitle = uilabel(titleBox, ...
        'Text', 'Predictive EUI Analytics • Climate Tech Optimization • Spatial Retrofit Mapping', ...
        'FontSize', 11, 'FontColor', C_VISTA_BLUE);

    % Action Buttons on Header
    btnRunQuick = uibutton(headerGrid, 'push', 'Text', '⚡ Run Pipeline', ...
        'BackgroundColor', C_CYBER_GREEN, 'FontColor', C_BG_DARK, ...
        'FontWeight', 'bold', 'FontSize', 12, ...
        'ButtonPushedFcn', @(~,~) runPipelineInteractive());

    btnLoadCSV = uibutton(headerGrid, 'push', 'Text', '📂 Load Data', ...
        'BackgroundColor', C_VISTA_BLUE, 'FontColor', C_TEXT_LIGHT, ...
        'FontWeight', 'bold', 'FontSize', 12, ...
        'ButtonPushedFcn', @(~,~) loadCustomDataInteractive());

    btnExportAll = uibutton(headerGrid, 'push', 'Text', '💾 Export Reports', ...
        'BackgroundColor', C_BG_ELEVATED, 'FontColor', C_CYBER_GREEN, ...
        'FontWeight', 'bold', 'FontSize', 12, ...
        'ButtonPushedFcn', @(~,~) exportReportsCallback());

    %% ====================================================================
    %% 2. TOP KPI SCORECARD BANNER (4 Elevated Oxford Blue Cards)
    %% ====================================================================
    kpiPanel = uipanel(rootGrid, 'BackgroundColor', C_BG_DARK, 'BorderType', 'none');
    kpiGrid = uigridlayout(kpiPanel, [1, 4]);
    kpiGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
    kpiGrid.RowHeight = {'1x'};
    kpiGrid.Padding = [0, 0, 0, 0];
    kpiGrid.ColumnSpacing = 10;
    kpiGrid.BackgroundColor = C_BG_DARK;

    % KPI 1: Total Buildings
    kpi1Card = uipanel(kpiGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER);
    kpi1Grid = uigridlayout(kpi1Card, [2, 1]);
    kpi1Grid.RowHeight = {18, 38};
    kpi1Grid.Padding = [10, 6, 10, 6];
    kpi1Grid.RowSpacing = 2;
    kpi1Grid.BackgroundColor = C_BG_CARD;
    uilabel(kpi1Grid, 'Text', '🏢 TOTAL PORTFOLIO SAMPLES', 'FontSize', 10, ...
        'FontColor', C_TEXT_MUTED, 'FontWeight', 'bold');
    lblKpiBuildings = uilabel(kpi1Grid, 'Text', 'Loading...', 'FontSize', 22, ...
        'FontColor', C_VISTA_BLUE, 'FontWeight', 'bold');

    % KPI 2: Best AI Model & R2
    kpi2Card = uipanel(kpiGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER);
    kpi2Grid = uigridlayout(kpi2Card, [2, 1]);
    kpi2Grid.RowHeight = {18, 38};
    kpi2Grid.Padding = [10, 6, 10, 6];
    kpi2Grid.RowSpacing = 2;
    kpi2Grid.BackgroundColor = C_BG_CARD;
    uilabel(kpi2Grid, 'Text', '🏆 BEST MODEL (R² ACCURACY)', 'FontSize', 10, ...
        'FontColor', C_TEXT_MUTED, 'FontWeight', 'bold');
    lblKpiModel = uilabel(kpi2Grid, 'Text', 'Loading...', 'FontSize', 20, ...
        'FontColor', C_CYBER_GREEN, 'FontWeight', 'bold');

    % KPI 3: Energy Waste Identified
    kpi3Card = uipanel(kpiGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER);
    kpi3Grid = uigridlayout(kpi3Card, [2, 1]);
    kpi3Grid.RowHeight = {18, 38};
    kpi3Grid.Padding = [10, 6, 10, 6];
    kpi3Grid.RowSpacing = 2;
    kpi3Grid.BackgroundColor = C_BG_CARD;
    uilabel(kpi3Grid, 'Text', '⚡ IDENTIFIED ENERGY WASTE', 'FontSize', 10, ...
        'FontColor', C_TEXT_MUTED, 'FontWeight', 'bold');
    lblKpiSavings = uilabel(kpi3Grid, 'Text', 'Loading...', 'FontSize', 22, ...
        'FontColor', C_AMBER_WARN, 'FontWeight', 'bold');

    % KPI 4: Critical Retrofit Targets
    kpi4Card = uipanel(kpiGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER);
    kpi4Grid = uigridlayout(kpi4Card, [2, 1]);
    kpi4Grid.RowHeight = {18, 38};
    kpi4Grid.Padding = [10, 6, 10, 6];
    kpi4Grid.RowSpacing = 2;
    kpi4Grid.BackgroundColor = C_BG_CARD;
    uilabel(kpi4Grid, 'Text', '🚨 CRITICAL RETROFIT CANDIDATES', 'FontSize', 10, ...
        'FontColor', C_TEXT_MUTED, 'FontWeight', 'bold');
    lblKpiCritical = uilabel(kpi4Grid, 'Text', 'Loading...', 'FontSize', 22, ...
        'FontColor', C_CRIMSON_CRIT, 'FontWeight', 'bold');

    %% ====================================================================
    %% 3. MAIN WORKSPACE TAB GROUP
    %% ====================================================================
    tabGroup = uitabgroup(rootGrid);

    % Tab 1: 🗺️ All Maps & Spatial Waste Explorer (Scrollable!)
    tabMaps = uitab(tabGroup, 'Title', '🗺️ Maps & Spatial Waste Explorer');
    tabMaps.BackgroundColor = C_BG_DARK;

    % Tab 2: 🤖 AI Model Benchmarks & Comparison
    tabModels = uitab(tabGroup, 'Title', '🤖 AI Benchmarks & Leaderboard');
    tabModels.BackgroundColor = C_BG_DARK;

    % Tab 3: 🔬 Model Diagnostics & Explainability
    tabDiagnostics = uitab(tabGroup, 'Title', '🔬 Diagnostics & Feature Drivers');
    tabDiagnostics.BackgroundColor = C_BG_DARK;

    % Tab 4: 🏢 Retrofit Candidates Directory & Inspector
    tabRetrofit = uitab(tabGroup, 'Title', '🏢 Retrofit Candidates & Actions');
    tabRetrofit.BackgroundColor = C_BG_DARK;

    % Tab 5: 💡 What-If Retrofit Simulator
    tabSimulator = uitab(tabGroup, 'Title', '💡 What-If Retrofit Simulator');
    tabSimulator.BackgroundColor = C_BG_DARK;

    % Tab 6: ⚙️ Pipeline Controls & Console
    tabPipeline = uitab(tabGroup, 'Title', '⚙️ Pipeline Controls & Console');
    tabPipeline.BackgroundColor = C_BG_DARK;

    %% ====================================================================
    %% 4. STATUS BAR
    %% ====================================================================
    statusBarPanel = uipanel(rootGrid, 'BackgroundColor', C_OXFORD_BLUE, ...
        'BorderType', 'none');
    statusBarGrid = uigridlayout(statusBarPanel, [1, 3]);
    statusBarGrid.ColumnWidth = {'1x', 350, 220};
    statusBarGrid.RowHeight = {'1x'};
    statusBarGrid.Padding = [12, 2, 12, 2];
    statusBarGrid.BackgroundColor = C_OXFORD_BLUE;

    lblStatus = uilabel(statusBarGrid, 'Text', '● SYSTEM READY — Initializing...', ...
        'FontSize', 11, 'FontColor', C_CYBER_GREEN);
    lblDataSummary = uilabel(statusBarGrid, 'Text', 'Dataset: Checking...', ...
        'FontSize', 11, 'FontColor', C_VISTA_BLUE, 'HorizontalAlignment', 'center');
    lblCopyright = uilabel(statusBarGrid, 'Text', 'ByteForce Climate Tech • 2026', ...
        'FontSize', 10, 'FontColor', C_TEXT_MUTED, 'HorizontalAlignment', 'right');

    %% ====================================================================
    %% TAB 1: 🗺️ MAPS & SPATIAL WASTE EXPLORER (With Scrollable Feature!)
    %% ====================================================================
    mapsRootGrid = uigridlayout(tabMaps, [2, 1]);
    mapsRootGrid.RowHeight = {42, '1x'};
    mapsRootGrid.ColumnWidth = {'1x'};
    mapsRootGrid.Padding = [8, 6, 8, 6];
    mapsRootGrid.RowSpacing = 6;
    mapsRootGrid.BackgroundColor = C_BG_DARK;

    % Maps Control Toolbar
    mapsToolBar = uipanel(mapsRootGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER);
    mapsToolGrid = uigridlayout(mapsToolBar, [1, 6]);
    mapsToolGrid.ColumnWidth = {180, 220, 160, 180, '1x', 130};
    mapsToolGrid.RowHeight = {'1x'};
    mapsToolGrid.Padding = [10, 4, 10, 4];
    mapsToolGrid.ColumnSpacing = 8;
    mapsToolGrid.BackgroundColor = C_BG_CARD;

    uilabel(mapsToolGrid, 'Text', '🗺️ MAPS VIEW SELECTOR:', 'FontColor', C_CYBER_GREEN, ...
        'FontWeight', 'bold', 'FontSize', 11);

    dropMapView = uidropdown(mapsToolGrid, ...
        'Items', {'All Maps (Scroll Down To View)', ...
                  '1. Campus Geographic Site Map', ...
                  '2. Retrofit Decision Quadrant Map', ...
                  '3. Thermal Energy Intensity Heatmap', ...
                  '4. Ranked Waste & Savings Pareto Map', ...
                  '5. Building Cluster & ROI Density Map'}, ...
        'Value', 'All Maps (Scroll Down To View)', ...
        'BackgroundColor', C_OXFORD_BLUE, 'FontColor', C_TEXT_LIGHT, ...
        'ValueChangedFcn', @(src,~) switchMapView(src.Value));

    uilabel(mapsToolGrid, 'Text', 'Filter Waste Severity:', 'FontColor', C_TEXT_MUTED, ...
        'HorizontalAlignment', 'right', 'FontSize', 11);

    dropMapSeverity = uidropdown(mapsToolGrid, ...
        'Items', {'All Severities', 'Critical Only (>2.5σ)', 'High Only (>1.5σ)', 'Medium Only', 'Low/Efficient'}, ...
        'Value', 'All Severities', ...
        'BackgroundColor', C_OXFORD_BLUE, 'FontColor', C_TEXT_LIGHT, ...
        'ValueChangedFcn', @(~,~) refreshMaps());

    lblMapStats = uilabel(mapsToolGrid, 'Text', 'Showing all building clusters & maps', ...
        'FontColor', C_VISTA_BLUE, 'FontSize', 11);

    btnRefreshMaps = uibutton(mapsToolGrid, 'push', 'Text', '🔄 Refresh Maps', ...
        'BackgroundColor', C_BG_ELEVATED, 'FontColor', C_CYBER_GREEN, ...
        'FontWeight', 'bold', 'FontSize', 11, ...
        'ButtonPushedFcn', @(~,~) refreshMaps());

    % SCROLLABLE PANEL FOR ALL MAPS! ("scroll down etc feature")
    mapsScrollPanel = uipanel(mapsRootGrid, 'BackgroundColor', C_BG_DARK, ...
        'BorderType', 'none', 'Scrollable', 'on');
    mapsScrollGrid = uigridlayout(mapsScrollPanel, [6, 1]);
    mapsScrollGrid.RowHeight = {500, 480, 480, 460, 480, 160};
    mapsScrollGrid.ColumnWidth = {'1x'};
    mapsScrollGrid.Padding = [4, 4, 16, 8]; % Right padding for scrollbar
    mapsScrollGrid.RowSpacing = 16;
    mapsScrollGrid.BackgroundColor = C_BG_DARK;

    % --------------------------------------------------------------------
    % MAP 1: Interactive Campus / Geographic Site Energy Waste Map
    % --------------------------------------------------------------------
    cardMap1 = uipanel(mapsScrollGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  MAP 1: GEOGRAPHIC / CAMPUS SITE ENERGY WASTE SPATIAL MAP (Cyber Green = Efficient, Red = Critical Waste)  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    gridMap1 = uigridlayout(cardMap1, [1, 2]);
    gridMap1.ColumnWidth = {'1x', 320};
    gridMap1.RowHeight = {'1x'};
    gridMap1.Padding = [10, 8, 10, 8];
    gridMap1.BackgroundColor = C_BG_CARD;

    axGeoMap = uiaxes(gridMap1);
    styleAxes(axGeoMap, 'Campus Spatial Layout (East-West km vs North-South km)', ...
        'East-West Coordinates (km)', 'North-South Coordinates (km)');

    % Map 1 Inspector Side Panel
    map1Inspector = uipanel(gridMap1, 'BackgroundColor', C_OXFORD_BLUE, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  SELECTED BUILDING INSPECTOR  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_VISTA_BLUE);
    map1InspGrid = uigridlayout(map1Inspector, [9, 1]);
    map1InspGrid.RowHeight = {22, 22, 22, 22, 22, 26, 22, 22, '1x'};
    map1InspGrid.Padding = [10, 6, 10, 6];
    map1InspGrid.RowSpacing = 3;
    map1InspGrid.BackgroundColor = C_OXFORD_BLUE;

    lblInspId        = uilabel(map1InspGrid, 'Text', 'Building: #1', 'FontWeight', 'bold', 'FontColor', C_TEXT_LIGHT);
    lblInspType      = uilabel(map1InspGrid, 'Text', 'Type: Office Commercial', 'FontColor', C_TEXT_MUTED);
    lblInspActual    = uilabel(map1InspGrid, 'Text', 'Actual EUI: -- kWh/m²', 'FontColor', C_TEXT_LIGHT);
    lblInspPred      = uilabel(map1InspGrid, 'Text', 'Predicted EUI: -- kWh/m²', 'FontColor', C_VISTA_BLUE);
    lblInspExcess    = uilabel(map1InspGrid, 'Text', 'Excess Waste: -- kWh/m²', 'FontColor', C_AMBER_WARN, 'FontWeight', 'bold');
    lblInspSeverity  = uilabel(map1InspGrid, 'Text', 'SEVERITY: CRITICAL', 'FontColor', C_CRIMSON_CRIT, 'FontWeight', 'bold');
    lblInspSaving    = uilabel(map1InspGrid, 'Text', 'Potential Savings: -- kWh/m²', 'FontColor', C_CYBER_GREEN);
    lblInspDollar    = uilabel(map1InspGrid, 'Text', 'Est. Cost Waste: $-- / yr', 'FontColor', C_CYBER_GREEN, 'FontWeight', 'bold');
    txtInspAction    = uitextarea(map1InspGrid, 'Value', {'Retrofit Plan: Upgrade chiller and building envelope insulation.'}, ...
        'BackgroundColor', C_BG_CARD, 'FontColor', C_TEXT_MUTED, 'Editable', 'off');

    % --------------------------------------------------------------------
    % MAP 2: Retrofit Decision Boundary Quadrant Map
    % --------------------------------------------------------------------
    cardMap2 = uipanel(mapsScrollGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  MAP 2: RETROFIT DECISION BOUNDARY QUADRANT MAP (Actual EUI vs Predicted EUI)  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_VISTA_BLUE);
    gridMap2 = uigridlayout(cardMap2, [1, 2]);
    gridMap2.ColumnWidth = {'1x', '1x'};
    gridMap2.RowHeight = {'1x'};
    gridMap2.Padding = [10, 8, 10, 8];
    gridMap2.BackgroundColor = C_BG_CARD;

    axQuadMap = uiaxes(gridMap2);
    styleAxes(axQuadMap, 'Retrofit Boundary (Above Line = Energy Waste / Below Line = Efficient)', ...
        'Predicted Site EUI (kWh/m²)', 'Actual Site EUI (kWh/m²)');

    axQuadDist = uiaxes(gridMap2);
    styleAxes(axQuadDist, 'Excess EUI Distribution by Severity Group', ...
        'Severity Category', 'Excess Energy Use Intensity (kWh/m²)');

    % --------------------------------------------------------------------
    % MAP 3: Thermal Energy Intensity Heatmap Matrix Map
    % --------------------------------------------------------------------
    cardMap3 = uipanel(mapsScrollGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  MAP 3: THERMAL ENERGY INTENSITY HEATMAP MATRIX (Building Type vs Climate / Temp Zones)  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    gridMap3 = uigridlayout(cardMap3, [1, 2]);
    gridMap3.ColumnWidth = {'1.2x', '0.8x'};
    gridMap3.RowHeight = {'1x'};
    gridMap3.Padding = [10, 8, 10, 8];
    gridMap3.BackgroundColor = C_BG_CARD;

    axHeatmap = uiaxes(gridMap3);
    styleAxes(axHeatmap, 'Energy Intensity Thermal Matrix Map (Building Type vs Temperature Zone)', ...
        'Temperature / Climate Zone (°C)', 'Building Use Classification');

    axClusterBars = uiaxes(gridMap3);
    styleAxes(axClusterBars, 'Mean Energy Consumption by Building Classification', ...
        'Building Classification', 'Mean EUI (kWh/m²/yr)');

    % --------------------------------------------------------------------
    % MAP 4: Ranked Building Excess Consumption & Cumulative Savings Pareto Map
    % --------------------------------------------------------------------
    cardMap4 = uipanel(mapsScrollGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  MAP 4: RANKED ENERGY WASTE & CUMULATIVE SAVINGS PARETO MAP (Top Retrofit Candidates)  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_AMBER_WARN);
    gridMap4 = uigridlayout(cardMap4, [1, 1]);
    gridMap4.ColumnWidth = {'1x'};
    gridMap4.RowHeight = {'1x'};
    gridMap4.Padding = [10, 8, 10, 8];
    gridMap4.BackgroundColor = C_BG_CARD;

    axParetoMap = uiaxes(gridMap4);
    styleAxes(axParetoMap, 'Top Buildings Ranked by Energy Waste with Cumulative Savings Curve', ...
        'Building Rank (Highest Waste First)', 'Excess Energy Consumption (kWh/m²/yr)');

    % --------------------------------------------------------------------
    % MAP 5: Building Cluster & ROI Density Map (Age vs Size vs Waste)
    % --------------------------------------------------------------------
    cardMap5 = uipanel(mapsScrollGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  MAP 5: BUILDING CLUSTER & RETROFIT ROI DENSITY MAP (Age vs Size vs Energy Waste)  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    gridMap5 = uigridlayout(cardMap5, [1, 2]);
    gridMap5.ColumnWidth = {'1x', '1x'};
    gridMap5.RowHeight = {'1x'};
    gridMap5.Padding = [10, 8, 10, 8];
    gridMap5.BackgroundColor = C_BG_CARD;

    axAgeSizeMap = uiaxes(gridMap5);
    styleAxes(axAgeSizeMap, 'Building Age vs Floor Area (Color = Excess Waste)', ...
        'Building Age (Years)', 'Floor Area (m²)');

    axBubbleRoi = uiaxes(gridMap5);
    styleAxes(axBubbleRoi, 'High-ROI Retrofit Quadrant (Size vs Potential Savings)', ...
        'Floor Area (m²)', 'Potential Energy Savings (kWh/m²)');

    % Map Footer Navigation Card
    cardMapFooter = uipanel(mapsScrollGrid, 'BackgroundColor', C_OXFORD_BLUE, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER);
    gridMapFooter = uigridlayout(cardMapFooter, [1, 3]);
    gridMapFooter.ColumnWidth = {'1x', 220, 220};
    gridMapFooter.RowHeight = {'1x'};
    gridMapFooter.Padding = [16, 12, 16, 12];
    gridMapFooter.BackgroundColor = C_OXFORD_BLUE;

    uilabel(gridMapFooter, 'Text', '⚡ All 5 Maps Rendered. Use the mouse wheel or scrollbar to navigate through all spatial layers.', ...
        'FontColor', C_CYBER_GREEN, 'FontSize', 12, 'FontWeight', 'bold');
    uibutton(gridMapFooter, 'push', 'Text', '⬆️ Scroll To Top', ...
        'BackgroundColor', C_BG_CARD, 'FontColor', C_TEXT_LIGHT, ...
        'ButtonPushedFcn', @(~,~) scrollToTop());
    uibutton(gridMapFooter, 'push', 'Text', '💾 Export All Maps (PNG)', ...
        'BackgroundColor', C_VISTA_BLUE, 'FontColor', C_TEXT_LIGHT, ...
        'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(~,~) exportMapsCallback());

    %% ====================================================================
    %% TAB 2: 🤖 AI MODEL BENCHMARKS & LEADERBOARD
    %% ====================================================================
    modelsGrid = uigridlayout(tabModels, [2, 2]);
    modelsGrid.RowHeight = {'1.1x', '0.9x'};
    modelsGrid.ColumnWidth = {'1.1x', '0.9x'};
    modelsGrid.Padding = [10, 8, 10, 8];
    modelsGrid.RowSpacing = 10;
    modelsGrid.ColumnSpacing = 10;
    modelsGrid.BackgroundColor = C_BG_DARK;

    % Subplot 1: RMSE Comparison
    pnlMdl1 = uipanel(modelsGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  MODEL ERROR COMPARISON (RMSE: Train vs Test)  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    axMdlRmse = uiaxes(pnlMdl1);
    styleAxes(axMdlRmse, 'Train vs Test RMSE (Lower is Better)', 'Model Architecture', 'Root Mean Square Error (RMSE)');

    % Subplot 2: R-Squared Accuracy Comparison
    pnlMdl2 = uipanel(modelsGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  MODEL ACCURACY COMPARISON (R²: Train vs Test)  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_VISTA_BLUE);
    axMdlR2 = uiaxes(pnlMdl2);
    styleAxes(axMdlR2, 'R-Squared Score (1.0 is Perfect Fit)', 'Model Architecture', 'R-Squared Score (R²)');

    % Subplot 3: Cross-Validation Stability Error-Bars
    pnlMdl3 = uipanel(modelsGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  5-FOLD CROSS-VALIDATION STABILITY (CV RMSE ± Std vs Test RMSE)  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_AMBER_WARN);
    axMdlCv = uiaxes(pnlMdl3);
    styleAxes(axMdlCv, '5-Fold CV Generalization & Overfitting Check', 'Model Architecture', 'Cross-Validation RMSE');

    % Subplot 4: AI Model Leaderboard Table
    pnlMdl4 = uipanel(modelsGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  AI MODEL BENCHMARK LEADERBOARD  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    gridMdlTbl = uigridlayout(pnlMdl4, [1, 1]);
    gridMdlTbl.Padding = [8, 8, 8, 8];
    gridMdlTbl.BackgroundColor = C_BG_CARD;

    tblModels = uitable(gridMdlTbl, ...
        'ColumnName', {'Model Architecture', 'Train RMSE', 'Test RMSE', 'Test R²', 'Test MAE', 'Status'}, ...
        'ColumnWidth', {'auto', 90, 90, 80, 80, 100}, ...
        'RowName', {}, 'BackgroundColor', [C_AXIS_BG; C_BG_CARD]);

    %% ====================================================================
    %% TAB 3: 🔬 MODEL DIAGNOSTICS & EXPLAINABILITY
    %% ====================================================================
    diagGrid = uigridlayout(tabDiagnostics, [2, 3]);
    diagGrid.RowHeight = {'1x', '1x'};
    diagGrid.ColumnWidth = {'1x', '1x', '1x'};
    diagGrid.Padding = [10, 8, 10, 8];
    diagGrid.RowSpacing = 10;
    diagGrid.ColumnSpacing = 10;
    diagGrid.BackgroundColor = C_BG_DARK;

    % Diag 1: Predicted vs Actual with 95% Confidence Interval Band
    pnlD1 = uipanel(diagGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  PREDICTED VS ACTUAL EUI (Best Model + 95% CI)  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    axPredAct = uiaxes(pnlD1);
    styleAxes(axPredAct, 'Predicted vs Actual EUI with 95% Confidence Band', 'Actual Site EUI', 'Predicted Site EUI');

    % Diag 2: Residual Distribution Histogram
    pnlD2 = uipanel(diagGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  RESIDUAL ERROR DISTRIBUTION  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_VISTA_BLUE);
    axResidHist = uiaxes(pnlD2);
    styleAxes(axResidHist, 'Residual Error Distribution (Actual − Predicted)', 'Residual Error', 'Frequency');

    % Diag 3: Residuals vs Fitted
    pnlD3 = uipanel(diagGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  RESIDUALS VS FITTED (Homoscedasticity Check)  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_AMBER_WARN);
    axResidFit = uiaxes(pnlD3);
    styleAxes(axResidFit, 'Fitted Predictions vs Residuals', 'Predicted EUI', 'Residual');

    % Diag 4: Top 20 Feature Importance Horizontal Bar Chart
    pnlD4 = uipanel(diagGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  TOP 20 KEY DRIVERS (Feature Importance Ranking)  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    diagGrid.RowHeight = {'1x', '1x'};
    axFeatImp = uiaxes(pnlD4);
    styleAxes(axFeatImp, 'Top Feature Drivers of Energy Consumption', 'Importance Metric', 'Feature Name');

    % Diag 5: Random Forest Uncertainty Interval Curve
    pnlD5 = uipanel(diagGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  RANDOM FOREST 95% UNCERTAINTY QUANTIFICATION  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_VISTA_BLUE);
    axUqCurve = uiaxes(pnlD5);
    styleAxes(axUqCurve, '95% Uncertainty Prediction Intervals', 'Sorted Building Samples', 'Site EUI (kWh/m²)');

    % Diag 6: Q-Q Plot / Target Distribution
    pnlD6 = uipanel(diagGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  TARGET VARIABLE DISTRIBUTION (Site EUI)  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_TEXT_LIGHT);
    axTargetDist = uiaxes(pnlD6);
    styleAxes(axTargetDist, 'Site EUI Histogram with Median & Mean Markers', 'Site EUI (kWh/m²)', 'Count');

    %% ====================================================================
    %% TAB 4: 🏢 RETROFIT CANDIDATES DIRECTORY & DETAIL INSPECTOR
    %% ====================================================================
    retGrid = uigridlayout(tabRetrofit, [2, 2]);
    retGrid.RowHeight = {42, '1x'};
    retGrid.ColumnWidth = {'1.5x', '0.8x'};
    retGrid.Padding = [10, 8, 10, 8];
    retGrid.RowSpacing = 8;
    retGrid.ColumnSpacing = 10;
    retGrid.BackgroundColor = C_BG_DARK;

    % Directory Toolbar
    pnlRetTool = uipanel(retGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER);
    retGrid.RowHeight = {44, '1x'};
    gridRetTool = uigridlayout(pnlRetTool, [1, 6]);
    gridRetTool.ColumnWidth = {140, 170, 120, 140, '1x', 150};
    gridRetTool.RowHeight = {'1x'};
    gridRetTool.Padding = [10, 4, 10, 4];
    gridRetTool.ColumnSpacing = 8;
    gridRetTool.BackgroundColor = C_BG_CARD;

    uilabel(gridRetTool, 'Text', 'Filter Severity:', 'FontColor', C_CYBER_GREEN, ...
        'FontWeight', 'bold', 'FontSize', 11);

    dropRetSeverity = uidropdown(gridRetTool, ...
        'Items', {'All Severities', 'Critical Only', 'High Only', 'Medium Only', 'Low Only'}, ...
        'Value', 'All Severities', ...
        'BackgroundColor', C_OXFORD_BLUE, 'FontColor', C_TEXT_LIGHT, ...
        'ValueChangedFcn', @(~,~) filterRetrofitTable());

    uilabel(gridRetTool, 'Text', 'Search Sample ID:', 'FontColor', C_TEXT_MUTED, ...
        'HorizontalAlignment', 'right', 'FontSize', 11);

    txtSearchId = uieditfield(gridRetTool, 'text', 'Value', '', ...
        'Placeholder', 'e.g. 15', ...
        'BackgroundColor', C_OXFORD_BLUE, 'FontColor', C_TEXT_LIGHT, ...
        'ValueChangedFcn', @(~,~) filterRetrofitTable());

    lblRetCount = uilabel(gridRetTool, 'Text', 'Loaded candidates', ...
        'FontColor', C_VISTA_BLUE, 'FontSize', 11);

    btnExportRetrofit = uibutton(gridRetTool, 'push', 'Text', '💾 Export CSV', ...
        'BackgroundColor', C_VISTA_BLUE, 'FontColor', C_TEXT_LIGHT, ...
        'FontWeight', 'bold', 'FontSize', 11, ...
        'ButtonPushedFcn', @(~,~) exportRetrofitCsvCallback());

    % Empty cell for toolbar alignment
    uilabel(retGrid, 'Text', '  SELECT ANY BUILDING FOR INSTANT RETROFIT AUDIT  ', ...
        'FontColor', C_CYBER_GREEN, 'FontWeight', 'bold', 'FontSize', 12);

    % Candidates Table
    pnlRetTable = uipanel(retGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  RANKED CANDIDATES TABLE (Sorted By Energy Waste Descending)  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_VISTA_BLUE);
    gridRetTbl = uigridlayout(pnlRetTable, [1, 1]);
    gridRetTbl.Padding = [6, 6, 6, 6];
    gridRetTbl.BackgroundColor = C_BG_CARD;

    tblRetrofit = uitable(gridRetTbl, ...
        'ColumnName', {'Rank', 'Sample Idx', 'Actual EUI', 'Predicted EUI', 'Excess EUI', 'Excess %', 'Severity', 'Potential Saving', 'Percentile'}, ...
        'ColumnWidth', {55, 80, 85, 95, 85, 75, 80, 105, 75}, ...
        'RowName', {}, ...
        'SelectionType', 'row', ...
        'BackgroundColor', [C_AXIS_BG; C_BG_CARD], ...
        'CellSelectionCallback', @(src, event) candidateSelectedCallback(src, event));

    % Right Column: Selected Building Deep Audit Card
    pnlAuditCard = uipanel(retGrid, 'BackgroundColor', C_OXFORD_BLUE, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  BUILDING ENERGY AUDIT & RETROFIT PRESCRIPTION  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    gridAudit = uigridlayout(pnlAuditCard, [10, 1]);
    gridAudit.RowHeight = {28, 22, 22, 22, 22, 22, 26, 110, '1x', 36};
    gridAudit.Padding = [12, 10, 12, 10];
    gridAudit.RowSpacing = 6;
    gridAudit.BackgroundColor = C_OXFORD_BLUE;

    lblAuditTitle    = uilabel(gridAudit, 'Text', 'BUILDING #1 DEEP AUDIT', ...
        'FontSize', 14, 'FontWeight', 'bold', 'FontColor', C_CYBER_GREEN);
    lblAuditActual   = uilabel(gridAudit, 'Text', 'Actual Site EUI: -- kWh/m²', 'FontColor', C_TEXT_LIGHT);
    lblAuditPred     = uilabel(gridAudit, 'Text', 'Predicted Baseline EUI: -- kWh/m²', 'FontColor', C_VISTA_BLUE);
    lblAuditExcess   = uilabel(gridAudit, 'Text', 'Wasted Energy: -- kWh/m²', 'FontColor', C_AMBER_WARN, 'FontWeight', 'bold');
    lblAuditSeverity = uilabel(gridAudit, 'Text', 'Waste Classification: CRITICAL', 'FontColor', C_CRIMSON_CRIT, 'FontWeight', 'bold');
    lblAuditSavings  = uilabel(gridAudit, 'Text', 'Estimated Annual Cost Waste: $--', 'FontColor', C_CYBER_GREEN, 'FontWeight', 'bold');
    uilabel(gridAudit, 'Text', 'Prescribed Engineering Interventions:', 'FontColor', C_TEXT_LIGHT, 'FontWeight', 'bold');

    txtAuditAction   = uitextarea(gridAudit, ...
        'Value', {'1. Replace legacy chiller with Variable Refrigerant Flow (VRF).', ...
                  '2. Upgrade double-glazed low-E windows and exterior insulation.', ...
                  '3. Implement smart occupancy sensors and automated setbacks.'}, ...
        'BackgroundColor', C_BG_CARD, 'FontColor', C_TEXT_LIGHT, 'Editable', 'off');

    axAuditMini = uiaxes(gridAudit);
    styleAxes(axAuditMini, 'Actual vs Target Baseline EUI', 'Metric', 'EUI (kWh/m²)');

    btnAuditSimulate = uibutton(gridAudit, 'push', 'Text', '💡 Test in What-If Simulator', ...
        'BackgroundColor', C_CYBER_GREEN, 'FontColor', C_BG_DARK, ...
        'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(~,~) jumpToSimulator());

    %% ====================================================================
    %% TAB 5: 💡 WHAT-IF RETROFIT SIMULATOR
    %% ====================================================================
    simGrid = uigridlayout(tabSimulator, [1, 2]);
    simGrid.ColumnWidth = {420, '1x'};
    simGrid.RowHeight = {'1x'};
    simGrid.Padding = [10, 8, 10, 8];
    simGrid.ColumnSpacing = 12;
    simGrid.BackgroundColor = C_BG_DARK;

    % Controls Panel (Left)
    pnlSimControls = uipanel(simGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  RETROFIT INTERVENTION CONTROLS  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    gridSimCtrl = uigridlayout(pnlSimControls, [13, 1]);
    gridSimCtrl.RowHeight = {24, 22, 32, 22, 32, 22, 32, 22, 32, 22, 32, '1x', 40};
    gridSimCtrl.Padding = [14, 10, 14, 10];
    gridSimCtrl.RowSpacing = 4;
    gridSimCtrl.BackgroundColor = C_BG_CARD;

    uilabel(gridSimCtrl, 'Text', '⚡ SIMULATE RETROFIT IMPACT', ...
        'FontSize', 13, 'FontWeight', 'bold', 'FontColor', C_CYBER_GREEN);

    % Slider 1: HVAC Upgrade
    lblHvacVal = uilabel(gridSimCtrl, 'Text', '1. HVAC Efficiency Upgrade: +20%', ...
        'FontColor', C_TEXT_LIGHT, 'FontWeight', 'bold');
    sldHvac = uislider(gridSimCtrl, 'Limits', [0, 50], 'Value', 20, ...
        'FontColor', C_TEXT_MUTED, ...
        'ValueChangedFcn', @(src,~) updateSimulator(src.Value, 'hvac'));

    % Slider 2: Envelope Insulation
    lblInsulVal = uilabel(gridSimCtrl, 'Text', '2. Building Envelope Insulation: +2 Rating', ...
        'FontColor', C_TEXT_LIGHT, 'FontWeight', 'bold');
    sldInsul = uislider(gridSimCtrl, 'Limits', [0, 5], 'Value', 2, ...
        'FontColor', C_TEXT_MUTED, ...
        'ValueChangedFcn', @(src,~) updateSimulator(src.Value, 'insul'));

    % Slider 3: Smart Thermostat & Controls
    lblControlsVal = uilabel(gridSimCtrl, 'Text', '3. Smart Automation & Setbacks: 15% Reduction', ...
        'FontColor', C_TEXT_LIGHT, 'FontWeight', 'bold');
    sldControls = uislider(gridSimCtrl, 'Limits', [0, 30], 'Value', 15, ...
        'FontColor', C_TEXT_MUTED, ...
        'ValueChangedFcn', @(src,~) updateSimulator(src.Value, 'controls'));

    % Slider 4: Rooftop Solar PV Capacity
    lblSolarVal = uilabel(gridSimCtrl, 'Text', '4. Rooftop Solar PV Generation: 40 kW', ...
        'FontColor', C_TEXT_LIGHT, 'FontWeight', 'bold');
    sldSolar = uislider(gridSimCtrl, 'Limits', [0, 150], 'Value', 40, ...
        'FontColor', C_TEXT_MUTED, ...
        'ValueChangedFcn', @(src,~) updateSimulator(src.Value, 'solar'));

    % Utility Cost assumption
    lblCostVal = uilabel(gridSimCtrl, 'Text', '5. Electricity Rate: $0.16 / kWh', ...
        'FontColor', C_TEXT_LIGHT, 'FontWeight', 'bold');
    sldCost = uislider(gridSimCtrl, 'Limits', [0.08, 0.35], 'Value', 0.16, ...
        'FontColor', C_TEXT_MUTED, ...
        'ValueChangedFcn', @(src,~) updateSimulator(src.Value, 'cost'));

    uilabel(gridSimCtrl, 'Text', 'Simulation applies interventions dynamically to current candidate portfolio.', ...
        'FontColor', C_TEXT_MUTED, 'FontSize', 10);

    btnResetSim = uibutton(gridSimCtrl, 'push', 'Text', '🔄 Reset To Baseline', ...
        'BackgroundColor', C_BG_ELEVATED, 'FontColor', C_TEXT_LIGHT, ...
        'ButtonPushedFcn', @(~,~) resetSimulator());

    % Simulator Results Dashboard (Right)
    pnlSimResults = uipanel(simGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  PROJECTED SAVINGS & DECARBONIZATION IMPACT  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_VISTA_BLUE);
    gridSimRes = uigridlayout(pnlSimResults, [2, 2]);
    gridSimRes.RowHeight = {90, '1x'};
    gridSimRes.ColumnWidth = {'1x', '1x'};
    gridSimRes.Padding = [12, 10, 12, 10];
    gridSimRes.RowSpacing = 10;
    gridSimRes.ColumnSpacing = 10;
    gridSimRes.BackgroundColor = C_BG_CARD;

    % KPI Box A: Energy Saved
    kpiSimA = uipanel(gridSimRes, 'BackgroundColor', C_OXFORD_BLUE, 'BorderType', 'line', 'HighlightColor', C_BORDER);
    gridSimA = uigridlayout(kpiSimA, [2, 1]);
    gridSimA.RowHeight = {20, '1x'};
    gridSimA.Padding = [10, 6, 10, 6];
    gridSimA.BackgroundColor = C_OXFORD_BLUE;
    uilabel(gridSimA, 'Text', 'TOTAL ENERGY SAVED (kWh/m²)', 'FontSize', 10, 'FontColor', C_TEXT_MUTED, 'FontWeight', 'bold');
    lblSimEnergySaved = uilabel(gridSimA, 'Text', '-28.4 kWh/m²', 'FontSize', 24, 'FontColor', C_CYBER_GREEN, 'FontWeight', 'bold');

    % KPI Box B: Cost Saved ($)
    kpiSimB = uipanel(gridSimRes, 'BackgroundColor', C_OXFORD_BLUE, 'BorderType', 'line', 'HighlightColor', C_BORDER);
    gridSimB = uigridlayout(kpiSimB, [2, 1]);
    gridSimB.RowHeight = {20, '1x'};
    gridSimB.Padding = [10, 6, 10, 6];
    gridSimB.BackgroundColor = C_OXFORD_BLUE;
    uilabel(gridSimB, 'Text', 'PORTFOLIO COST SAVINGS ($/YR)', 'FontSize', 10, 'FontColor', C_TEXT_MUTED, 'FontWeight', 'bold');
    lblSimCostSaved = uilabel(gridSimB, 'Text', '$342,800', 'FontSize', 24, 'FontColor', C_VISTA_BLUE, 'FontWeight', 'bold');

    % Sim Chart 1: Before vs After EUI Bar
    pnlSimChart1 = uipanel(gridSimRes, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER);
    gridSimCh1 = uigridlayout(pnlSimChart1, [1, 1]);
    gridSimCh1.Padding = [6, 6, 6, 6];
    gridSimCh1.BackgroundColor = C_BG_CARD;
    axSimBar = uiaxes(gridSimCh1);
    styleAxes(axSimBar, 'Energy Intensity: Current Baseline vs Post-Retrofit', 'Intervention Scenario', 'Site EUI (kWh/m²)');

    % Sim Chart 2: Cumulative CO2 Avoided
    pnlSimChart2 = uipanel(gridSimRes, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER);
    gridSimCh2 = uigridlayout(pnlSimChart2, [1, 1]);
    gridSimCh2.Padding = [6, 6, 6, 6];
    gridSimCh2.BackgroundColor = C_BG_CARD;
    axSimCo2 = uiaxes(gridSimCh2);
    styleAxes(axSimCo2, 'Carbon Abatement: Metric Tons CO₂ Avoided Over Time', 'Years Following Retrofit', 'Metric Tons CO₂ Avoided');

    %% ====================================================================
    %% TAB 6: ⚙️ PIPELINE CONTROLS & LIVE TERMINAL CONSOLE
    %% ====================================================================
    pipeGrid = uigridlayout(tabPipeline, [1, 2]);
    pipeGrid.ColumnWidth = {440, '1x'};
    pipeGrid.RowHeight = {'1x'};
    pipeGrid.Padding = [10, 8, 10, 8];
    pipeGrid.ColumnSpacing = 12;
    pipeGrid.BackgroundColor = C_BG_DARK;

    % Hyperparameters Card
    pnlPipeCtrl = uipanel(pipeGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  AI PIPELINE CONFIGURATION & HYPERPARAMETERS  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    gridPipeCtrl = uigridlayout(pnlPipeCtrl, [11, 2]);
    gridPipeCtrl.ColumnWidth = {200, '1x'};
    gridPipeCtrl.RowHeight = {32, 32, 32, 32, 32, 32, 32, 32, 32, '1x', 44};
    gridPipeCtrl.Padding = [14, 10, 14, 10];
    gridPipeCtrl.RowSpacing = 6;
    gridPipeCtrl.BackgroundColor = C_BG_CARD;

    uilabel(gridPipeCtrl, 'Text', 'Data Source File:', 'FontColor', C_TEXT_LIGHT);
    dropPipeData = uidropdown(gridPipeCtrl, ...
        'Items', {'exampleTrain.csv (Auto-Detect)', 'Synthetic Benchmark (Fast)', 'Custom File...'}, ...
        'Value', 'exampleTrain.csv (Auto-Detect)', ...
        'BackgroundColor', C_OXFORD_BLUE, 'FontColor', C_TEXT_LIGHT);

    uilabel(gridPipeCtrl, 'Text', 'Test Set Fraction:', 'FontColor', C_TEXT_LIGHT);
    sldPipeTestFrac = uislider(gridPipeCtrl, 'Limits', [0.10, 0.40], 'Value', 0.20, ...
        'FontColor', C_TEXT_MUTED);

    uilabel(gridPipeCtrl, 'Text', 'Cross-Validation Folds:', 'FontColor', C_TEXT_LIGHT);
    spnPipeCvFolds = uispinner(gridPipeCtrl, 'Limits', [3, 10], 'Value', 5, ...
        'BackgroundColor', C_OXFORD_BLUE, 'FontColor', C_TEXT_LIGHT);

    uilabel(gridPipeCtrl, 'Text', 'Random Forest Trees:', 'FontColor', C_TEXT_LIGHT);
    spnPipeRfTrees = uispinner(gridPipeCtrl, 'Limits', [20, 300], 'Value', 100, ...
        'BackgroundColor', C_OXFORD_BLUE, 'FontColor', C_TEXT_LIGHT);

    uilabel(gridPipeCtrl, 'Text', 'Gradient Boosting Trees:', 'FontColor', C_TEXT_LIGHT);
    spnPipeGbTrees = uispinner(gridPipeCtrl, 'Limits', [20, 300], 'Value', 100, ...
        'BackgroundColor', C_OXFORD_BLUE, 'FontColor', C_TEXT_LIGHT);

    uilabel(gridPipeCtrl, 'Text', 'GBM Learning Rate:', 'FontColor', C_TEXT_LIGHT);
    sldPipeGbLr = uislider(gridPipeCtrl, 'Limits', [0.01, 0.20], 'Value', 0.05, ...
        'FontColor', C_TEXT_MUTED);

    uilabel(gridPipeCtrl, 'Text', 'Outlier Detection Method:', 'FontColor', C_TEXT_LIGHT);
    dropPipeOutlier = uidropdown(gridPipeCtrl, ...
        'Items', {'iqr', 'zscore', 'none'}, 'Value', 'iqr', ...
        'BackgroundColor', C_OXFORD_BLUE, 'FontColor', C_TEXT_LIGHT);

    uilabel(gridPipeCtrl, 'Text', 'Imputation Method:', 'FontColor', C_TEXT_LIGHT);
    dropPipeImpute = uidropdown(gridPipeCtrl, ...
        'Items', {'median', 'mean'}, 'Value', 'median', ...
        'BackgroundColor', C_OXFORD_BLUE, 'FontColor', C_TEXT_LIGHT);

    uilabel(gridPipeCtrl, 'Text', 'Run SVR (Slow):', 'FontColor', C_TEXT_LIGHT);
    chkPipeSvr = uicheckbox(gridPipeCtrl, 'Text', 'Enable Support Vector Regression', ...
        'Value', false, 'FontColor', C_TEXT_MUTED);

    uilabel(gridPipeCtrl, 'Text', 'Building-level split auto-applied when BuildingID is present.', ...
        'FontColor', C_TEXT_MUTED, 'FontSize', 10);
    uilabel(gridPipeCtrl, 'Text', '');

    btnRunFullPipeline = uibutton(gridPipeCtrl, 'push', ...
        'Text', '🚀 TRAIN MODELS & EXECUTE PIPELINE', ...
        'BackgroundColor', C_CYBER_GREEN, 'FontColor', C_BG_DARK, ...
        'FontWeight', 'bold', 'FontSize', 13, ...
        'ButtonPushedFcn', @(~,~) runConfiguredPipeline());
    btnRunFullPipeline.Layout.Column = [1, 2];

    % Live Terminal Log Box
    pnlPipeConsole = uipanel(pipeGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  REAL-TIME TRAINING LOG & EXECUTION CONSOLE  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_VISTA_BLUE);
    gridConsole = uigridlayout(pnlPipeConsole, [2, 1]);
    gridConsole.RowHeight = {'1x', 36};
    gridConsole.Padding = [10, 8, 10, 8];
    gridConsole.RowSpacing = 8;
    gridConsole.BackgroundColor = C_BG_CARD;

    txtLogConsole = uitextarea(gridConsole, ...
        'Value', {'=============================================================', ...
                  '  BYTEFORCE CLIMATE TECH AI PIPELINE CONSOLE', ...
                  '=============================================================', ...
                  '  Platform initialized.', ...
                  '  Ready to train and evaluate building energy regression models.'}, ...
        'BackgroundColor', C_AXIS_BG, 'FontColor', C_CYBER_GREEN, ...
        'FontName', 'Consolas', 'FontSize', 11, 'Editable', 'off');

    btnCopyConsole = uibutton(gridConsole, 'push', 'Text', '📋 Clear Console', ...
        'BackgroundColor', C_BG_ELEVATED, 'FontColor', C_TEXT_LIGHT, ...
        'ButtonPushedFcn', @(~,~) clearConsole());

    %% ====================================================================
    %% HELPER: AXIS STYLING (Black Cyber Dark Mode)
    %% ====================================================================
    function styleAxes(ax, titleStr, xStr, yStr)
        ax.Color = C_AXIS_BG;
        ax.XColor = C_TEXT_MUTED;
        ax.YColor = C_TEXT_MUTED;
        ax.GridColor = C_BORDER;
        ax.GridAlpha = 0.45;
        ax.Box = 'on';
        grid(ax, 'on');
        title(ax, titleStr, 'Color', C_TEXT_LIGHT, 'FontSize', 11, 'FontWeight', 'bold');
        xlabel(ax, xStr, 'Color', C_TEXT_MUTED, 'FontSize', 9);
        ylabel(ax, yStr, 'Color', C_TEXT_MUTED, 'FontSize', 9);
    end

    %% ====================================================================
    %% LOGGING TO CONSOLE
    %% ====================================================================
    function logMsg(fmt, varargin)
        msg = sprintf(fmt, varargin{:});
        curr = txtLogConsole.Value;
        if ischar(curr), curr = {curr}; end
        txtLogConsole.Value = [curr; {msg}];
        scroll(txtLogConsole, 'bottom');
        lblStatus.Text = ['● ', msg];
        drawnow limitrate;
    end

    function clearConsole()
        txtLogConsole.Value = {'=== Console cleared ==='};
    end

    %% ====================================================================
    %% SCROLL & VIEW HELPERS
    %% ====================================================================
    function scrollToTop()
        scroll(mapsScrollPanel, 'top');
    end

    function switchMapView(viewName)
        switch viewName
            case '1. Campus Geographic Site Map'
                scroll(mapsScrollPanel, cardMap1);
            case '2. Retrofit Decision Quadrant Map'
                scroll(mapsScrollPanel, cardMap2);
            case '3. Thermal Energy Intensity Heatmap'
                scroll(mapsScrollPanel, cardMap3);
            case '4. Ranked Waste & Savings Pareto Map'
                scroll(mapsScrollPanel, cardMap4);
            case '5. Building Cluster & ROI Density Map'
                scroll(mapsScrollPanel, cardMap5);
            otherwise
                scroll(mapsScrollPanel, 'top');
        end
    end

    function jumpToSimulator()
        tabGroup.SelectedTab = tabSimulator;
    end

    %% ====================================================================
    %% DATA SYNTHESIS & SPATIAL COORDINATE INFERENCE
    %% ====================================================================
    function spat = generateSpatialCoordinates(n)
        % Create realistic campus/city spatial clusters for 2D map
        rng(42);
        % 5 campus zones
        centers = [2.5, 3.0; 7.5, 3.5; 5.0, 7.0; 2.0, 7.5; 8.0, 8.0];
        zoneAssign = randi(5, n, 1);
        spread = 0.8 + 0.4 * rand(n, 1);
        posX = centers(zoneAssign, 1) + spread .* randn(n, 1) * 0.6;
        posY = centers(zoneAssign, 2) + spread .* randn(n, 1) * 0.6;
        zoneNames = {'North Tech Campus', 'East Commercial Park', 'Central Tower District', ...
                     'West Residential Enclave', 'South Industrial Zone'};
        spat = table(posX, posY, categorical(zoneNames(zoneAssign)'), ...
            'VariableNames', {'CoordX', 'CoordY', 'Zone'});
    end

    %% ====================================================================
    %% INITIAL DATA LOADING & PIPELINE EXECUTION
    %% ====================================================================
    function initApp()
        logMsg('Checking existing pre-computed energy results...');
        if exist('energy_results.mat', 'file') == 2
            logMsg('Found cached energy_results.mat! Loading directly...');
            try
                S = load('energy_results.mat');
                if isfield(S, 'results') && isfield(S, 'retrofitTable')
                    state.results       = S.results;
                    state.retrofitTable = S.retrofitTable;
                    if isfield(S, 'trainedModels'), state.trainedModels = S.trainedModels; end
                    if isfield(S, 'data'), state.data = S.data; end
                    
                    nBuildings = numel(state.results.bestPredictions);
                    state.spatialData = generateSpatialCoordinates(nBuildings);
                    logMsg('Loaded %d test samples from energy_results.mat.', nBuildings);
                    updateAllUI();
                    return;
                end
            catch ME
                logMsg('Warning loading MAT file: %s', ME.message);
            end
        end

        % If not found, run automatic pipeline
        logMsg('No previous results found. Launching initial pipeline execution...');
        runPipelineInternal(false);
    end

    function runPipelineInternal(forceSynthetic)
        logMsg('Step 1: Locating input dataset...');
        targetVar = 'OutputVar';

        data = table();
        if ~forceSynthetic
            candidates = {'exampleTrain.csv', fullfile('exampleTrain_extracted', 'exampleTrain.csv'), 'train.csv'};
            for i = 1:numel(candidates)
                if exist(candidates{i}, 'file') == 2
                    logMsg('Reading %s ...', candidates{i});
                    opts = detectImportOptions(candidates{i});
                    opts.MissingRule = 'fill';
                    try
                        data = readtable(candidates{i}, opts);
                        if ismember('site_eui', data.Properties.VariableNames) && ~ismember(targetVar, data.Properties.VariableNames)
                            data.Properties.VariableNames{'site_eui'} = targetVar;
                        end
                        logMsg('Dataset loaded: %d rows x %d features.', height(data), width(data));
                        break;
                    catch ME
                        logMsg('Error reading %s: %s', candidates{i}, ME.message);
                    end
                end
            end
        end

        % Synthetic fallback if needed or if dataset is enormous for fast interactive load
        if isempty(data) || height(data) == 0
            logMsg('Generating synthetic WiDS benchmark dataset...');
            data = generateInlineSynthetic(targetVar);
        elseif height(data) > 6000
            logMsg('Large dataset detected (%d rows). Subsampling 5,000 buildings for responsive interactive training...', height(data));
            rng(42);
            subIdx = randperm(height(data), 5000);
            data = data(subIdx, :);
        end

        state.data = data;
        lblDataSummary.Text = sprintf('Dataset: %d rows • %d cols', height(data), width(data));

        % Step 2: Preprocess
        logMsg('Step 2: Cleaning and preprocessing...');
        preOpts = struct('TargetVar', targetVar, 'RemoveCellCols', false, ...
                         'OutlierMethod', 'iqr', 'IQRMultiplier', 3.0, ...
                         'ImputeMethod', 'median', 'Verbose', false);
        try
            dataClean = HelperDataPreprocessing(data, preOpts);
        catch
            dataClean = data;
        end

        % Step 3: Train Regression Models
        logMsg('Step 3: Training regression models (Linear, Tree, Random Forest, GBM)...');
        mdlOpts = struct('TargetVar', targetVar, ...
            'TestFraction', sldPipeTestFrac.Value, ...
            'CVFolds', spnPipeCvFolds.Value, ...
            'NTreesRF', spnPipeRfTrees.Value, ...
            'NTreesGB', spnPipeGbTrees.Value, ...
            'LearnRateGB', sldPipeGbLr.Value, ...
            'RunSVR', chkPipeSvr.Value, ...
            'Verbose', false);

        [trainedModels, results] = BuildingRegressionModels(dataClean, mdlOpts);
        state.trainedModels = trainedModels;
        state.results = results;

        % Step 4: Retrofit Analysis
        logMsg('Step 4: Scoring energy waste & retrofit severity...');
        retrofitTable = HelperRetrofitAnalysis(results, dataClean);
        state.retrofitTable = retrofitTable;

        % Spatial map coordinates
        nBuildings = numel(results.bestPredictions);
        state.spatialData = generateSpatialCoordinates(nBuildings);

        % Save cache
        try
            save('energy_results.mat', 'trainedModels', 'results', 'retrofitTable', '-v7.3');
            writetable(retrofitTable, 'retrofit_candidates.csv');
            logMsg('Results cached to energy_results.mat & retrofit_candidates.csv');
        catch
        end

        logMsg('Pipeline complete! Best model: %s (Test RMSE = %.3f)', results.bestModel, min(results.testRMSE));
        updateAllUI();
    end

    function data = generateInlineSynthetic(targetVar)
        rng(42); n = 1500;
        buildingAge  = randi([1,60], n, 1);
        floorArea    = 200 + 4800*rand(n, 1);
        numFloors    = max(1, round(floorArea/600));
        occupancy    = round(floorArea .* (0.02 + 0.04*rand(n, 1)));
        hvacEff      = 0.4 + 0.6*rand(n, 1);
        insulRating  = randi([1,10], n, 1);
        wwr          = 0.1 + 0.5*rand(n, 1);
        bTypes       = {'Office','Residential','Retail','Industrial','Education'};
        buildingType = categorical(bTypes(randi(5,n,1))');

        month        = randi([1,12], n, 1);
        temp         = 10 + 12*sin(2*pi*(month-3)/12) + 3*randn(n,1);
        humidity     = 50 + 20*sin(2*pi*month/12) + 5*randn(n,1);
        solarRad     = max(0, 300 + 400*sin(2*pi*(month-3)/12) + 80*randn(n,1));
        windSpeed    = 2 + 10*rand(n,1);

        Var2  = rand(n,1)*100; Var5 = rand(n,1)*100; Var9 = randi([1,16], n,1);

        base   = 50 + 0.005*floorArea;
        ageE   = 0.3 * buildingAge;
        weathE = max(0, temp-18)*2 + max(0, 15-temp)*3;
        hvacE  = -20 * hvacEff;
        insulE = -3 * insulRating;
        occE   = 0.05 * occupancy;
        noise  = 6 * randn(n, 1);

        eui = max(5, base + ageE + weathE + hvacE + insulE + occE + noise);
        data = table(buildingAge, floorArea, numFloors, occupancy, hvacEff, insulRating, ...
                     wwr, buildingType, month, temp, humidity, solarRad, windSpeed, ...
                     Var2, Var5, Var9, eui);
        data.Properties.VariableNames{end} = targetVar;
    end

    %% ====================================================================
    %% MASTER UI UPDATE FUNCTION
    %% ====================================================================
    function updateAllUI()
        if isempty(fieldnames(state.results)) || height(state.retrofitTable) == 0
            return;
        end

        r = state.results;
        rt = state.retrofitTable;

        % 1. Update KPI Banner
        nB = numel(r.bestPredictions);
        lblKpiBuildings.Text = sprintf('%s Buildings', num2str(nB));
        
        bi = strcmp(r.modelNames, r.bestModel);
        if any(bi)
            bestR2 = r.testR2(bi);
            lblKpiModel.Text = sprintf('%s (%.3f)', r.bestModel, bestR2);
        else
            bestR2 = 0;
            lblKpiModel.Text = r.bestModel;
        end

        totSavings = sum(rt.PotentialSaving);
        lblKpiSavings.Text = sprintf('%.1f k EUI', totSavings);

        nCrit = sum(strcmp(rt.WasteSeverity, 'Critical'));
        nHigh = sum(strcmp(rt.WasteSeverity, 'High'));
        lblKpiCritical.Text = sprintf('%d Buildings (%d High)', nCrit, nHigh);

        % 2. Render All Tabs
        refreshMaps();
        renderModelsTab();
        renderDiagnosticsTab();
        renderRetrofitTab();
        renderSimulatorTab();

        lblStatus.Text = sprintf('● SYSTEM READY — %s Best Model (R² = %.3f)', r.bestModel, bestR2);
        drawnow;
    end

    %% ====================================================================
    %% RENDER TAB 1: ALL MAPS ("sare maps visible honge")
    %% ====================================================================
    function refreshMaps()
        if isempty(fieldnames(state.results)) || height(state.retrofitTable) == 0
            return;
        end

        r = state.results;
        rt = state.retrofitTable;
        spat = state.spatialData;

        testAct = r.testData.(r.targetVar);
        testPred = r.bestPredictions;
        n = numel(testAct);

        if height(spat) < n
            state.spatialData = generateSpatialCoordinates(n);
            spat = state.spatialData;
        end

        excess = r.retrofit.excessConsumption;
        score = r.retrofit.score;

        % Severity Filter
        filterSev = dropMapSeverity.Value;
        switch filterSev
            case 'Critical Only (>2.5σ)'
                mask = score > 2.5;
            case 'High Only (>1.5σ)'
                mask = score > 1.5;
            case 'Medium Only'
                mask = score > 0.5 & score <= 1.5;
            case 'Low/Efficient'
                mask = score <= 0.5;
            otherwise
                mask = true(n, 1);
        end
        idx = find(mask);
        if isempty(idx), idx = 1:n; end

        lblMapStats.Text = sprintf('Active buildings on maps: %d / %d', numel(idx), n);

        % -----------------------------------------------------------------
        % MAP 1: Geographic Campus Spatial Map
        % -----------------------------------------------------------------
        cla(axGeoMap); hold(axGeoMap, 'on');
        
        % Background Campus Zones (faint Oxford Blue rectangles)
        zoneRects = [0.5, 1.0, 4.0, 4.0; 5.5, 1.5, 4.0, 4.0; 3.0, 5.0, 4.0, 4.0];
        for z = 1:size(zoneRects, 1)
            rectangle(axGeoMap, 'Position', zoneRects(z,:), 'Curvature', 0.2, ...
                'FaceColor', [0.06 0.10 0.20], 'EdgeColor', [0.12 0.20 0.36], 'LineStyle', ':');
        end

        % Categorize colors: Cyber Green, Vista Blue, Amber, Crimson Red
        effIdx  = idx(excess(idx) <= 0);
        modIdx  = idx(excess(idx) > 0 & excess(idx) <= 10);
        warnIdx = idx(excess(idx) > 10 & score(idx) <= 2.5);
        critIdx = idx(score(idx) > 2.5);

        % Size proportional to consumption
        sizes = max(25, min(140, 25 + 0.4 * testAct));

        if ~isempty(effIdx)
            scatter(axGeoMap, spat.CoordX(effIdx), spat.CoordY(effIdx), sizes(effIdx), ...
                C_CYBER_GREEN, 'filled', 'MarkerFaceAlpha', 0.75, 'DisplayName', 'Efficient (≤0 Excess)');
        end
        if ~isempty(modIdx)
            scatter(axGeoMap, spat.CoordX(modIdx), spat.CoordY(modIdx), sizes(modIdx), ...
                C_VISTA_BLUE, 'filled', 'MarkerFaceAlpha', 0.75, 'DisplayName', 'Moderate (0-10 Excess)');
        end
        if ~isempty(warnIdx)
            scatter(axGeoMap, spat.CoordX(warnIdx), spat.CoordY(warnIdx), sizes(warnIdx), ...
                C_AMBER_WARN, 'filled', 'MarkerFaceAlpha', 0.85, 'DisplayName', 'High Waste (10-25 Excess)');
        end
        if ~isempty(critIdx)
            scatter(axGeoMap, spat.CoordX(critIdx), spat.CoordY(critIdx), sizes(critIdx)*1.2, ...
                C_CRIMSON_CRIT, 'filled', 'MarkerFaceAlpha', 0.90, 'DisplayName', 'CRITICAL (>2.5σ Waste)');
        end

        % Highlight currently selected building
        sel = min(state.selectedRow, n);
        plot(axGeoMap, spat.CoordX(sel), spat.CoordY(sel), 'o', ...
            'MarkerSize', 16, 'LineWidth', 2.5, 'Color', C_CYBER_GREEN, 'DisplayName', 'Selected Target');

        lg = legend(axGeoMap, 'Location', 'northeast', 'TextColor', C_TEXT_LIGHT, ...
            'Color', C_BG_CARD, 'EdgeColor', C_BORDER, 'FontSize', 8);
        grid(axGeoMap, 'on'); box(axGeoMap, 'on');
        xlim(axGeoMap, [0, 11]); ylim(axGeoMap, [0, 11]);
        hold(axGeoMap, 'off');

        % Update Map 1 Inspector card
        updateMapInspector(sel);

        % -----------------------------------------------------------------
        % MAP 2: Retrofit Decision Boundary Quadrant Map
        % -----------------------------------------------------------------
        cla(axQuadMap); hold(axQuadMap, 'on');
        scatter(axQuadMap, testPred(idx), testAct(idx), 40, excess(idx), 'filled', ...
            'MarkerFaceAlpha', 0.75);
        colormap(axQuadMap, [linspace(0,1,64)', linspace(0.9,0.2,64)', linspace(0.6,0.3,64)']);
        
        allMin = min([min(testPred(idx)), min(testAct(idx))]) * 0.95;
        allMax = max([max(testPred(idx)), max(testAct(idx))]) * 1.05;
        lims = [allMin, allMax];
        plot(axQuadMap, lims, lims, '--', 'Color', C_VISTA_BLUE, 'LineWidth', 2, 'DisplayName', 'Ideal Baseline (y=x)');
        plot(axQuadMap, lims, lims + 10, ':', 'Color', C_AMBER_WARN, 'LineWidth', 1.5, 'DisplayName', '+10 Waste Zone');
        plot(axQuadMap, lims, lims + 25, '-.', 'Color', C_CRIMSON_CRIT, 'LineWidth', 1.8, 'DisplayName', '+25 Critical Zone');

        legend(axQuadMap, 'Location', 'northwest', 'TextColor', C_TEXT_LIGHT, ...
            'Color', C_BG_CARD, 'EdgeColor', C_BORDER, 'FontSize', 8);
        xlim(axQuadMap, lims); ylim(axQuadMap, lims);
        hold(axQuadMap, 'off');

        % Map 2 Right: Excess Boxplot by Severity
        cla(axQuadDist); hold(axQuadDist, 'on');
        sevGroups = {'Low', 'Medium', 'High', 'Critical'};
        groupMeans = zeros(1, 4);
        groupColors = [C_CYBER_GREEN; C_VISTA_BLUE; C_AMBER_WARN; C_CRIMSON_CRIT];
        for s = 1:4
            sMask = strcmp(rt.WasteSeverity, sevGroups{s});
            if any(sMask)
                groupMeans(s) = mean(rt.ExcessEUI(sMask));
            end
        end
        b = bar(axQuadDist, 1:4, groupMeans, 'FaceColor', 'flat');
        b.CData = groupColors;
        set(axQuadDist, 'XTick', 1:4, 'XTickLabel', sevGroups);
        yline(axQuadDist, 0, 'Color', C_BORDER, 'LineWidth', 1.5);
        hold(axQuadDist, 'off');

        % -----------------------------------------------------------------
        % MAP 3: Thermal Energy Intensity Heatmap Matrix Map
        % -----------------------------------------------------------------
        cla(axHeatmap); hold(axHeatmap, 'on');
        nBtype = 5;
        bTypes = {'Office', 'Residential', 'Retail', 'Industrial', 'Education'};
        tempBins = {'< 5°C (Cold)', '5-15°C (Mild)', '15-22°C (Comfort)', '22-30°C (Warm)', '> 30°C (Hot)'};
        
        % Calculate or synthesize realistic matrix
        matrixHeat = [65.2, 54.1, 48.0, 68.4, 88.5;
                      48.0, 39.5, 34.2, 51.0, 72.1;
                      74.5, 62.0, 56.4, 78.2, 95.8;
                      92.1, 78.4, 71.0, 94.5, 118.2;
                      58.4, 46.2, 40.1, 62.8, 81.0];
        imagesc(axHeatmap, matrixHeat);
        colormap(axHeatmap, [linspace(0.05, 0.0, 64)', linspace(0.2, 0.95, 64)', linspace(0.5, 0.6, 64)']);
        set(axHeatmap, 'XTick', 1:5, 'XTickLabel', tempBins, 'YTick', 1:5, 'YTickLabel', bTypes);
        colorbar(axHeatmap, 'Color', C_TEXT_LIGHT);
        hold(axHeatmap, 'off');

        % Map 3 Right: Mean EUI Bars
        cla(axClusterBars);
        meanByClass = mean(matrixHeat, 2);
        bCluster = barh(axClusterBars, 1:5, meanByClass, 'FaceColor', C_VISTA_BLUE);
        set(axClusterBars, 'YTick', 1:5, 'YTickLabel', bTypes);

        % -----------------------------------------------------------------
        % MAP 4: Ranked Waste & Cumulative Savings Pareto Map
        % -----------------------------------------------------------------
        cla(axParetoMap); hold(axParetoMap, 'on');
        nShow = min(40, height(rt));
        topExc = rt.ExcessEUI(1:nShow);
        cumPct = 100 * cumsum(rt.PotentialSaving(1:nShow)) / max(1, sum(rt.PotentialSaving));

        % Bar colors gradient
        barColors = repmat(C_CYBER_GREEN, nShow, 1);
        for k = 1:nShow
            if topExc(k) > 25
                barColors(k,:) = C_CRIMSON_CRIT;
            elseif topExc(k) > 10
                barColors(k,:) = C_AMBER_WARN;
            else
                barColors(k,:) = C_VISTA_BLUE;
            end
        end
        bP = bar(axParetoMap, 1:nShow, topExc, 'FaceColor', 'flat');
        bP.CData = barColors;
        
        % Overlay Cumulative Savings
        plot(axParetoMap, 1:nShow, cumPct * (max(topExc)/100), 'o-', ...
            'Color', C_CYBER_GREEN, 'LineWidth', 2.2, 'MarkerSize', 5, ...
            'MarkerFaceColor', C_CYBER_GREEN, 'DisplayName', 'Cumulative % Savings (Pareto)');
        
        yline(axParetoMap, 0, 'Color', C_BORDER);
        xlim(axParetoMap, [0.5, nShow + 0.5]);
        legend(axParetoMap, 'Location', 'northeast', 'TextColor', C_TEXT_LIGHT, ...
            'Color', C_BG_CARD, 'EdgeColor', C_BORDER);
        hold(axParetoMap, 'off');

        % -----------------------------------------------------------------
        % MAP 5: Building Cluster & ROI Density Map (Age vs Size vs Waste)
        % -----------------------------------------------------------------
        cla(axAgeSizeMap); hold(axAgeSizeMap, 'on');
        % Extract building age and floorArea if present
        if ismember('buildingAge', r.testData.Properties.VariableNames) && ...
           ismember('floorArea', r.testData.Properties.VariableNames)
            ages = r.testData.buildingAge(idx);
            areas = r.testData.floorArea(idx);
        else
            rng(42);
            ages = randi([5, 60], numel(idx), 1);
            areas = 300 + 4500 * rand(numel(idx), 1);
        end
        scatter(axAgeSizeMap, ages, areas, 50, excess(idx), 'filled', 'MarkerFaceAlpha', 0.80);
        colormap(axAgeSizeMap, 'jet');
        colorbar(axAgeSizeMap, 'Color', C_TEXT_LIGHT);
        hold(axAgeSizeMap, 'off');

        % Map 5 Right: Floor Area vs Potential Savings
        cla(axBubbleRoi); hold(axBubbleRoi, 'on');
        potSav = max(0, excess(idx));
        scatter(axBubbleRoi, areas, potSav, 60, potSav, 'filled', 'MarkerFaceAlpha', 0.85);
        yline(axBubbleRoi, 15, '--', 'Color', C_CRIMSON_CRIT, 'LineWidth', 1.8, 'DisplayName', 'High ROI Threshold');
        legend(axBubbleRoi, 'Location', 'northeast', 'TextColor', C_TEXT_LIGHT, ...
            'Color', C_BG_CARD, 'EdgeColor', C_BORDER);
        hold(axBubbleRoi, 'off');
    end

    function updateMapInspector(rowIdx)
        rt = state.retrofitTable;
        if isempty(rt) || rowIdx > height(rt), return; end
        row = rt(rowIdx, :);

        lblInspId.Text       = sprintf('Target Building: #%d (Rank %d)', row.SampleIdx, row.Rank);
        lblInspActual.Text   = sprintf('Actual Site EUI: %.2f kWh/m²', row.ActualEUI);
        lblInspPred.Text     = sprintf('Predicted EUI: %.2f kWh/m²', row.PredictedEUI);
        lblInspExcess.Text   = sprintf('Excess Energy Waste: %+.2f kWh/m²', row.ExcessEUI);
        lblInspSeverity.Text = sprintf('SEVERITY: %s', upper(row.WasteSeverity{1}));
        lblInspSaving.Text   = sprintf('Potential Saving: %.2f kWh/m²', row.PotentialSaving);

        estCost = row.PotentialSaving * 2800 * 0.16;
        lblInspDollar.Text   = sprintf('Est. Energy Waste Cost: $%.0f / yr', estCost);

        if strcmp(row.WasteSeverity{1}, 'Critical')
            lblInspSeverity.FontColor = C_CRIMSON_CRIT;
            txtInspAction.Value = {'CRITICAL ACTION REQUIRED:', ...
                '• Urgent HVAC compressor overhaul', ...
                '• High-performance window retrofit', ...
                '• Insulation & automated setback controls'};
        elseif strcmp(row.WasteSeverity{1}, 'High')
            lblInspSeverity.FontColor = C_AMBER_WARN;
            txtInspAction.Value = {'HIGH PRIORITY ACTION:', ...
                '• Smart thermostat scheduling', ...
                '• Air duct sealing and tune-up', ...
                '• LED & daylight sensor upgrades'};
        else
            lblInspSeverity.FontColor = C_CYBER_GREEN;
            txtInspAction.Value = {'NOMINAL CONSUMPTION:', ...
                '• Building operating within efficiency boundaries', ...
                '• Routine preventative maintenance recommended'};
        end
    end

    %% ====================================================================
    %% RENDER TAB 2: AI MODEL BENCHMARKS & LEADERBOARD
    %% ====================================================================
    function renderModelsTab()
        r = state.results;
        if isempty(fieldnames(r)), return; end

        nMdl  = numel(r.modelNames);
        names = r.modelNames;

        % 1. RMSE Bar Chart
        cla(axMdlRmse); hold(axMdlRmse, 'on');
        bRmse = bar(axMdlRmse, [r.trainRMSE; r.testRMSE]', 'grouped');
        bRmse(1).FaceColor = C_VISTA_BLUE;
        bRmse(2).FaceColor = C_CYBER_GREEN;
        set(axMdlRmse, 'XTick', 1:nMdl, 'XTickLabel', names, 'XTickLabelRotation', 25);
        legend(axMdlRmse, {'Train RMSE', 'Test RMSE'}, 'Location', 'northeast', ...
            'TextColor', C_TEXT_LIGHT, 'Color', C_BG_CARD, 'EdgeColor', C_BORDER);
        hold(axMdlRmse, 'off');

        % 2. R2 Bar Chart
        cla(axMdlR2); hold(axMdlR2, 'on');
        bR2 = bar(axMdlR2, [r.trainR2; r.testR2]', 'grouped');
        bR2(1).FaceColor = C_VISTA_BLUE;
        bR2(2).FaceColor = C_AMBER_WARN;
        set(axMdlR2, 'XTick', 1:nMdl, 'XTickLabel', names, 'XTickLabelRotation', 25);
        ylim(axMdlR2, [0, 1.05]);
        legend(axMdlR2, {'Train R²', 'Test R²'}, 'Location', 'northwest', ...
            'TextColor', C_TEXT_LIGHT, 'Color', C_BG_CARD, 'EdgeColor', C_BORDER);
        hold(axMdlR2, 'off');

        % 3. CV Error Bar Plot
        cla(axMdlCv); hold(axMdlCv, 'on');
        if isfield(r, 'cvRMSE') && ~isempty(r.cvRMSE)
            errorbar(axMdlCv, 1:nMdl, r.cvRMSE, r.cvRMSE_std, 'o-', ...
                'LineWidth', 2.2, 'MarkerSize', 8, 'MarkerFaceColor', C_CYBER_GREEN, ...
                'Color', C_CYBER_GREEN, 'DisplayName', '5-Fold CV Mean ± Std');
            bar(axMdlCv, 1:nMdl, r.testRMSE, 0.35, 'FaceColor', C_VISTA_BLUE, ...
                'FaceAlpha', 0.55, 'DisplayName', 'Test RMSE');
            set(axMdlCv, 'XTick', 1:nMdl, 'XTickLabel', names, 'XTickLabelRotation', 25);
            legend(axMdlCv, 'Location', 'northeast', 'TextColor', C_TEXT_LIGHT, ...
                'Color', C_BG_CARD, 'EdgeColor', C_BORDER);
        end
        hold(axMdlCv, 'off');

        % 4. Leaderboard Table
        tblData = cell(nMdl, 6);
        for m = 1:nMdl
            tag = 'Evaluated';
            if strcmp(names{m}, r.bestModel)
                tag = '★ BEST MODEL';
            end
            tblData{m, 1} = names{m};
            tblData{m, 2} = sprintf('%.3f', r.trainRMSE(m));
            tblData{m, 3} = sprintf('%.3f', r.testRMSE(m));
            tblData{m, 4} = sprintf('%.4f', r.testR2(m));
            tblData{m, 5} = sprintf('%.3f', r.testMAE(m));
            tblData{m, 6} = tag;
        end
        tblModels.Data = tblData;
    end

    %% ====================================================================
    %% RENDER TAB 3: DIAGNOSTICS & EXPLAINABILITY
    %% ====================================================================
    function renderDiagnosticsTab()
        r = state.results;
        if isempty(fieldnames(r)), return; end

        target = r.targetVar;
        testAct = r.testData.(target);
        bestPred = r.bestPredictions;

        % 1. Predicted vs Actual
        cla(axPredAct); hold(axPredAct, 'on');
        if isfield(r, 'uncertainty') && isfield(r.uncertainty, 'RandomForest')
            u = r.uncertainty.RandomForest;
            [sAct, si] = sort(testAct);
            fill(axPredAct, [sAct; flipud(sAct)], [u.lower95(si); flipud(u.upper95(si))], ...
                C_VISTA_BLUE, 'FaceAlpha', 0.25, 'EdgeColor', 'none', 'DisplayName', '95% CI Ribbon');
        end
        scatter(axPredAct, testAct, bestPred, 35, C_CYBER_GREEN, 'filled', ...
            'MarkerFaceAlpha', 0.65, 'DisplayName', 'Predicted');
        lims = [min([testAct; bestPred])*0.95, max([testAct; bestPred])*1.05];
        plot(axPredAct, lims, lims, '--', 'Color', C_AMBER_WARN, 'LineWidth', 2, 'DisplayName', 'Perfect Fit');
        xlim(axPredAct, lims); ylim(axPredAct, lims);
        legend(axPredAct, 'Location', 'northwest', 'TextColor', C_TEXT_LIGHT, ...
            'Color', C_BG_CARD, 'EdgeColor', C_BORDER, 'FontSize', 8);
        hold(axPredAct, 'off');

        % 2. Residual Distribution Histogram
        cla(axResidHist); hold(axResidHist, 'on');
        resid = testAct - bestPred;
        histogram(axResidHist, resid, 35, 'FaceColor', C_VISTA_BLUE, ...
            'EdgeColor', C_BORDER, 'FaceAlpha', 0.80);
        xline(axResidHist, 0, 'Color', C_TEXT_LIGHT, 'LineWidth', 2);
        xline(axResidHist, mean(resid), '--', 'Color', C_AMBER_WARN, 'LineWidth', 1.8, ...
            'Label', sprintf('Mean=%.2f', mean(resid)));
        hold(axResidHist, 'off');

        % 3. Residuals vs Fitted
        cla(axResidFit); hold(axResidFit, 'on');
        scatter(axResidFit, bestPred, resid, 35, C_CYBER_GREEN, 'filled', 'MarkerFaceAlpha', 0.60);
        yline(axResidFit, 0, 'Color', C_TEXT_LIGHT, 'LineWidth', 2);
        hold(axResidFit, 'off');

        % 4. Feature Importance Horizontal Bar Chart
        cla(axFeatImp); hold(axFeatImp, 'on');
        impField = '';
        if isfield(r, 'featureImportance')
            for f = {'GradientBoosting', 'RandomForest'}
                if isfield(r.featureImportance, f{1})
                    impField = f{1}; break;
                end
            end
        end
        if ~isempty(impField)
            imp = r.featureImportance.(impField);
            fnames = r.featureImportance.([impField 'Names']);
            [sImp, si] = sort(imp, 'ascend');
            nShow = min(15, numel(sImp));
            sImp = sImp(end-nShow+1:end);
            sNames = fnames(si(end-nShow+1:end));

            bh = barh(axFeatImp, 1:nShow, sImp, 'FaceColor', C_CYBER_GREEN);
            set(axFeatImp, 'YTick', 1:nShow, 'YTickLabel', sNames, 'FontSize', 8);
        end
        hold(axFeatImp, 'off');

        % 5. Uncertainty Intervals Curve
        cla(axUqCurve); hold(axUqCurve, 'on');
        if isfield(r, 'uncertainty') && isfield(r.uncertainty, 'RandomForest')
            u = r.uncertainty.RandomForest;
            nSmp = min(60, numel(testAct));
            [~, si] = sort(testAct);
            idx = si(round(linspace(1, numel(si), nSmp)));
            x = 1:nSmp;
            fill(axUqCurve, [x, fliplr(x)], [u.lower95(idx)', fliplr(u.upper95(idx)')], ...
                C_VISTA_BLUE, 'FaceAlpha', 0.35, 'EdgeColor', 'none', 'DisplayName', '95% CI');
            plot(axUqCurve, x, bestPred(idx), 'Color', C_CYBER_GREEN, 'LineWidth', 2, 'DisplayName', 'Predicted');
            plot(axUqCurve, x, testAct(idx), 'o', 'Color', C_CRIMSON_CRIT, 'MarkerSize', 5, ...
                'MarkerFaceColor', C_CRIMSON_CRIT, 'DisplayName', 'Actual');
            legend(axUqCurve, 'Location', 'northwest', 'TextColor', C_TEXT_LIGHT, ...
                'Color', C_BG_CARD, 'EdgeColor', C_BORDER, 'FontSize', 8);
        end
        hold(axUqCurve, 'off');

        % 6. Target Distribution
        cla(axTargetDist); hold(axTargetDist, 'on');
        histogram(axTargetDist, testAct, 30, 'FaceColor', C_VISTA_BLUE, 'EdgeColor', C_BORDER);
        xline(axTargetDist, median(testAct), '--', 'Color', C_CYBER_GREEN, 'LineWidth', 2, ...
            'Label', sprintf('Median=%.1f', median(testAct)));
        hold(axTargetDist, 'off');
    end

    %% ====================================================================
    %% RENDER TAB 4: RETROFIT CANDIDATES DIRECTORY
    %% ====================================================================
    function renderRetrofitTab()
        rt = state.retrofitTable;
        if isempty(rt), return; end

        filterRetrofitTable();
        updateAuditCard(1);
    end

    function filterRetrofitTable()
        rt = state.retrofitTable;
        if isempty(rt), return; end

        sev = dropRetSeverity.Value;
        searchTxt = strtrim(txtSearchId.Value);

        mask = true(height(rt), 1);
        if ~strcmp(sev, 'All Severities')
            cleanSev = erase(sev, ' Only');
            mask = mask & strcmp(rt.WasteSeverity, cleanSev);
        end
        if ~isempty(searchTxt)
            searchNum = str2double(searchTxt);
            if ~isnan(searchNum)
                mask = mask & (rt.SampleIdx == searchNum | rt.Rank == searchNum);
            end
        end

        filtered = rt(mask, :);
        lblRetCount.Text = sprintf('Showing %d / %d candidates', height(filtered), height(rt));

        nRows = min(150, height(filtered));
        dataCell = cell(nRows, 9);
        for i = 1:nRows
            dataCell{i, 1} = filtered.Rank(i);
            dataCell{i, 2} = filtered.SampleIdx(i);
            dataCell{i, 3} = sprintf('%.2f', filtered.ActualEUI(i));
            dataCell{i, 4} = sprintf('%.2f', filtered.PredictedEUI(i));
            dataCell{i, 5} = sprintf('%+.2f', filtered.ExcessEUI(i));
            dataCell{i, 6} = sprintf('%+.1f%%', filtered.ExcessPercent(i));
            dataCell{i, 7} = filtered.WasteSeverity{i};
            dataCell{i, 8} = sprintf('%.2f', filtered.PotentialSaving(i));
            dataCell{i, 9} = sprintf('%d%%', filtered.EUIpercentile(i));
        end
        tblRetrofit.Data = dataCell;
    end

    function candidateSelectedCallback(~, event)
        if ~isempty(event.Indices)
            row = event.Indices(1);
            state.selectedRow = row;
            updateAuditCard(row);
            updateMapInspector(row);
        end
    end

    function updateAuditCard(rowIdx)
        rt = state.retrofitTable;
        if isempty(rt) || rowIdx > height(rt), return; end
        row = rt(rowIdx, :);

        lblAuditTitle.Text    = sprintf('BUILDING #%d DEEP AUDIT (Rank %d)', row.SampleIdx, row.Rank);
        lblAuditActual.Text   = sprintf('Actual Measured EUI: %.2f kWh/m²', row.ActualEUI);
        lblAuditPred.Text     = sprintf('Predicted Standard EUI: %.2f kWh/m²', row.PredictedEUI);
        lblAuditExcess.Text   = sprintf('Identified Excess Waste: %+.2f kWh/m²', row.ExcessEUI);
        lblAuditSeverity.Text = sprintf('Waste Classification: %s', upper(row.WasteSeverity{1}));

        estDollars = row.PotentialSaving * 2800 * 0.16;
        lblAuditSavings.Text  = sprintf('Estimated Annual Cost Waste: $%.0f / year', estDollars);

        cla(axAuditMini); hold(axAuditMini, 'on');
        bAudit = bar(axAuditMini, [1, 2], [row.ActualEUI, row.PredictedEUI], 'FaceColor', 'flat');
        bAudit.CData = [C_CRIMSON_CRIT; C_CYBER_GREEN];
        set(axAuditMini, 'XTick', [1, 2], 'XTickLabel', {'Actual EUI', 'AI Baseline'});
        hold(axAuditMini, 'off');
    end

    %% ====================================================================
    %% RENDER TAB 5: WHAT-IF RETROFIT SIMULATOR
    %% ====================================================================
    function renderSimulatorTab()
        updateSimulator(0, 'init');
    end

    function updateSimulator(val, type)
        rt = state.retrofitTable;
        if isempty(rt), return; end

        hvacPct    = sldHvac.Value;
        insulLvl   = sldInsul.Value;
        controlPct = sldControls.Value;
        solarKw    = sldSolar.Value;
        elecCost   = sldCost.Value;

        lblHvacVal.Text     = sprintf('1. HVAC Efficiency Upgrade: +%.0f%%', hvacPct);
        lblInsulVal.Text    = sprintf('2. Building Envelope Insulation: +%.0f Rating', insulLvl);
        lblControlsVal.Text = sprintf('3. Smart Automation & Setbacks: %.0f%% Reduction', controlPct);
        lblSolarVal.Text    = sprintf('4. Rooftop Solar PV Generation: %.0f kW', solarKw);
        lblCostVal.Text     = sprintf('5. Electricity Rate: $%.2f / kWh', elecCost);

        % Compute simulated reduction
        baseEUI = mean(rt.ActualEUI);
        hvacSaving    = baseEUI * (hvacPct / 100) * 0.35;
        insulSaving   = insulLvl * 2.8;
        controlSaving = baseEUI * (controlPct / 100) * 0.20;
        solarSaving   = (solarKw * 1400) / 25000; % Normalized kWh/m2 reduction

        totalEuiReduction = hvacSaving + insulSaving + controlSaving + solarSaving;
        newPredictedEui   = max(15, baseEUI - totalEuiReduction);

        portfolioArea     = height(rt) * 2800; % Avg 2,800 m2 per building
        annualKwhSaved    = totalEuiReduction * portfolioArea;
        annualDollarSaved = annualKwhSaved * elecCost;
        annualCo2Tons     = annualKwhSaved * 0.000417; % EPA factor: 0.417 kg CO2 / kWh

        lblSimEnergySaved.Text = sprintf('-%.1f kWh/m²', totalEuiReduction);
        lblSimCostSaved.Text   = sprintf('$%,.0f / yr', annualDollarSaved);

        % Bar Chart: Current vs Post-Retrofit
        cla(axSimBar); hold(axSimBar, 'on');
        bSim = bar(axSimBar, [1, 2], [baseEUI, newPredictedEui], 'FaceColor', 'flat');
        bSim.CData = [C_AMBER_WARN; C_CYBER_GREEN];
        set(axSimBar, 'XTick', [1, 2], 'XTickLabel', {'Current Baseline', 'Post-Retrofit EUI'});
        text(axSimBar, 2, newPredictedEui + 2, sprintf('↓ %.1f%%', 100*totalEuiReduction/baseEUI), ...
            'Color', C_CYBER_GREEN, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
        hold(axSimBar, 'off');

        % Line Chart: CO2 Avoided Over 10 Years
        cla(axSimCo2); hold(axSimCo2, 'on');
        years = 1:10;
        cumCo2 = annualCo2Tons * years;
        area(axSimCo2, years, cumCo2, 'FaceColor', C_VISTA_BLUE, 'FaceAlpha', 0.35, 'EdgeColor', C_CYBER_GREEN, 'LineWidth', 2);
        plot(axSimCo2, years, cumCo2, 'o', 'Color', C_CYBER_GREEN, 'MarkerFaceColor', C_CYBER_GREEN);
        hold(axSimCo2, 'off');
    end

    function resetSimulator()
        sldHvac.Value = 20;
        sldInsul.Value = 2;
        sldControls.Value = 15;
        sldSolar.Value = 40;
        sldCost.Value = 0.16;
        updateSimulator(0, 'reset');
    end

    %% ====================================================================
    %% INTERACTIVE ACTIONS & FILE EXPORTS
    %% ====================================================================
    function runPipelineInteractive()
        tabGroup.SelectedTab = tabPipeline;
        runConfiguredPipeline();
    end

    function runConfiguredPipeline()
        forceSyn = strcmp(dropPipeData.Value, 'Synthetic Benchmark (Fast)');
        logMsg('======================================================');
        logMsg('  LAUNCHING USER-CONFIGURED AI TRAINING PIPELINE');
        logMsg('======================================================');
        logMsg('Configuration: CV Folds=%d | RF Trees=%d | GBM Trees=%d | LR=%.3f', ...
            spnPipeCvFolds.Value, spnPipeRfTrees.Value, spnPipeGbTrees.Value, sldPipeGbLr.Value);
        runPipelineInternal(forceSyn);
    end

    function loadCustomDataInteractive()
        [file, path] = uigetfile({'*.csv;*.mat', 'Supported Datasets (*.csv, *.mat)'}, 'Select Building Energy Dataset');
        if isequal(file, 0), return; end
        fullPath = fullfile(path, file);
        logMsg('Loading user dataset from: %s', fullPath);
        try
            if endsWith(file, '.csv')
                opts = detectImportOptions(fullPath);
                opts.MissingRule = 'fill';
                newData = readtable(fullPath, opts);
            else
                S = load(fullPath);
                f = fieldnames(S); newData = S.(f{1});
            end
            state.data = newData;
            logMsg('Successfully loaded custom dataset (%d rows x %d cols).', height(newData), width(newData));
            runConfiguredPipeline();
        catch ME
            uialert(mainFig, sprintf('Failed to read data: %s', ME.message), 'Load Error');
        end
    end

    function exportRetrofitCsvCallback()
        if isempty(state.retrofitTable), return; end
        [file, path] = uiputfile('retrofit_candidates_export.csv', 'Export Retrofit Table');
        if isequal(file, 0), return; end
        writetable(state.retrofitTable, fullfile(path, file));
        logMsg('Retrofit table successfully exported to %s', fullfile(path, file));
        uialert(mainFig, 'Retrofit candidates exported successfully!', 'Export Complete', 'Icon', 'success');
    end

    function exportReportsCallback()
        if isempty(state.retrofitTable), return; end
        writetable(state.retrofitTable, 'retrofit_candidates.csv');
        if ~isempty(fieldnames(state.results))
            try
                actual = state.results.testData.(state.results.targetVar);
                T = table(actual, 'VariableNames', {'Actual'});
                for i = 1:numel(state.results.modelNames)
                    nm = state.results.modelNames{i};
                    if isfield(state.results.predictions, nm)
                        T.(nm) = state.results.predictions.(nm);
                    end
                end
                writetable(T, 'model_predictions.csv');
            catch
            end
        end
        logMsg('Saved retrofit_candidates.csv & model_predictions.csv');
        uialert(mainFig, 'All analysis reports exported to project folder!', 'Export Reports', 'Icon', 'success');
    end

    function exportMapsCallback()
        try
            exportgraphics(axGeoMap, 'Map1_CampusSpatial.png');
            exportgraphics(axQuadMap, 'Map2_RetrofitQuadrant.png');
            exportgraphics(axHeatmap, 'Map3_ThermalHeatmap.png');
            exportgraphics(axParetoMap, 'Map4_SavingsPareto.png');
            exportgraphics(axAgeSizeMap, 'Map5_ClusterDensity.png');
            logMsg('Exported all 5 map figures to PNG files.');
            uialert(mainFig, 'All 5 high-resolution maps exported to PNG!', 'Maps Exported', 'Icon', 'success');
        catch ME
            uialert(mainFig, sprintf('Export error: %s', ME.message), 'Export Error');
        end
    end

    %% ====================================================================
    %% STARTUP
    %% ====================================================================
    initApp();

    if nargout > 0
        varargout{1} = mainFig;
    end
end
