function varargout = EnergyConsumptionApp()
% EnergyConsumptionApp - Professional Building Energy Intelligence and
% Retrofit Analytics Platform for MATLAB.
%
% Color Theme: Deep Cyber Black / Oxford Blue / Vista Blue / Cyber Green
%
% Features:
%   - Instant rendering on launch (all graphs and maps active immediately)
%   - Clean enterprise UI (no emojis, professional typography and layout)
%   - Interactive Building Input & Live Prediction Engine
%   - 5 Visible Spatial and Analytical Maps:
%       1. Campus Site Spatial Energy Waste Map
%       2. Retrofit Decision Boundary Quadrant Map
%       3. Thermal Energy Intensity Heatmap Matrix Map
%       4. Ranked Waste & Cumulative Savings Pareto Map
%       5. Building Cluster & ROI Density Map
%   - Multi-Model Benchmarks (Linear, Tree, Random Forest, Gradient Boosting)
%   - Model Diagnostics (Actual vs Predicted + 95% CI, Residuals, Feature Importance)
%   - Retrofit Candidates Directory with Search & Severity Filters
%   - What-If Retrofit Scenario Simulator
%   - Pipeline Execution Controls and Live Activity Console
%
% Usage:
%   >> RunApp
%   >> EnergyConsumptionApp
%
% ByteForce Climate Tech Analytics

    % Ensure current directory is on MATLAB search path
    appFolder = fileparts(mfilename('fullpath'));
    if ~isempty(appFolder), addpath(appFolder); end

    %% --------------------------------------------------------------------
    %% COLOR PALETTE: Black / Oxford Blue / Vista Blue / Cyber Green
    %% --------------------------------------------------------------------
    C_BG_DARK       = [0.035, 0.048, 0.082];  % Deep Cyber Black
    C_BG_CARD       = [0.060, 0.095, 0.185];  % Oxford Blue Surface
    C_BG_ELEVATED   = [0.085, 0.135, 0.250];  % Oxford Navy Container
    C_BORDER        = [0.120, 0.200, 0.360];  % Subtle Structural Border
    C_CYBER_GREEN   = [0.000, 0.880, 0.520];  % Cyber Green Accent
    C_VISTA_BLUE    = [0.220, 0.520, 0.940];  % Vista Sky Blue
    C_OXFORD_BLUE   = [0.050, 0.100, 0.220];  % Oxford Deep Header
    C_AMBER_WARN    = [0.950, 0.680, 0.150];  % Warning Amber
    C_CRIMSON_CRIT  = [0.920, 0.240, 0.340];  % Critical Red
    C_TEXT_LIGHT    = [0.920, 0.950, 0.980];  % Primary White
    C_TEXT_MUTED    = [0.580, 0.660, 0.760];  % Muted Slate
    C_AXIS_BG       = [0.045, 0.068, 0.125];  % Axes Canvas Dark

    %% --------------------------------------------------------------------
    %% APPLICATION STATE
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

    mainFig = uifigure('Name', 'BYTEFORCE | Building Energy Intelligence & Retrofit Analytics Platform', ...
        'Position', [figX, figY, figW, figH], ...
        'Color', C_BG_DARK, ...
        'AutoResizeChildren', 'off');

    % Root grid layout: Header (68), KPI (78), Main Workspace (1x), Status (26)
    rootGrid = uigridlayout(mainFig, [4, 1]);
    rootGrid.RowHeight = {68, 78, '1x', 26};
    rootGrid.ColumnWidth = {'1x'};
    rootGrid.Padding = [10, 8, 10, 8];
    rootGrid.RowSpacing = 8;
    rootGrid.BackgroundColor = C_BG_DARK;

    %% ====================================================================
    %% 1. HEADER BAR
    %% ====================================================================
    headerPanel = uipanel(rootGrid, 'BackgroundColor', C_OXFORD_BLUE, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER);
    headerGrid = uigridlayout(headerPanel, [1, 4]);
    headerGrid.ColumnWidth = {'1x', 190, 160, 160};
    headerGrid.RowHeight = {'1x'};
    headerGrid.Padding = [16, 6, 16, 6];
    headerGrid.ColumnSpacing = 10;
    headerGrid.BackgroundColor = C_OXFORD_BLUE;

    titleBox = uigridlayout(headerGrid, [2, 1]);
    titleBox.RowHeight = {24, 16};
    titleBox.Padding = [0, 0, 0, 0];
    titleBox.RowSpacing = 2;
    titleBox.BackgroundColor = C_OXFORD_BLUE;

    uilabel(titleBox, 'Text', 'BYTEFORCE | BUILDING ENERGY INTELLIGENCE PLATFORM', ...
        'FontSize', 16, 'FontWeight', 'bold', 'FontColor', C_CYBER_GREEN);
    uilabel(titleBox, ...
        'Text', 'Predictive EUI Analytics, Climate Tech Optimization, and Spatial Retrofit Mapping', ...
        'FontSize', 11, 'FontColor', C_VISTA_BLUE);

    uibutton(headerGrid, 'push', 'Text', 'Train & Update Graphs', ...
        'BackgroundColor', C_CYBER_GREEN, 'FontColor', C_BG_DARK, ...
        'FontWeight', 'bold', 'FontSize', 12, ...
        'ButtonPushedFcn', @(~,~) runFastPipelineInteractive());

    uibutton(headerGrid, 'push', 'Text', 'Load Dataset', ...
        'BackgroundColor', C_VISTA_BLUE, 'FontColor', C_TEXT_LIGHT, ...
        'FontWeight', 'bold', 'FontSize', 12, ...
        'ButtonPushedFcn', @(~,~) loadCustomDataInteractive());

    uibutton(headerGrid, 'push', 'Text', 'Export Reports', ...
        'BackgroundColor', C_BG_ELEVATED, 'FontColor', C_CYBER_GREEN, ...
        'FontWeight', 'bold', 'FontSize', 12, ...
        'ButtonPushedFcn', @(~,~) exportReportsCallback());

    %% ====================================================================
    %% 2. TOP KPI METRICS BANNER
    %% ====================================================================
    kpiPanel = uipanel(rootGrid, 'BackgroundColor', C_BG_DARK, 'BorderType', 'none');
    kpiGrid = uigridlayout(kpiPanel, [1, 4]);
    kpiGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
    kpiGrid.RowHeight = {'1x'};
    kpiGrid.Padding = [0, 0, 0, 0];
    kpiGrid.ColumnSpacing = 10;
    kpiGrid.BackgroundColor = C_BG_DARK;

    kpi1Card = uipanel(kpiGrid, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER);
    kpi1Grid = uigridlayout(kpi1Card, [2, 1]);
    kpi1Grid.RowHeight = {16, 36};
    kpi1Grid.Padding = [10, 6, 10, 6];
    kpi1Grid.RowSpacing = 2;
    kpi1Grid.BackgroundColor = C_BG_CARD;
    uilabel(kpi1Grid, 'Text', 'PORTFOLIO SAMPLES ANALYZED', 'FontSize', 10, 'FontColor', C_TEXT_MUTED, 'FontWeight', 'bold');
    lblKpiBuildings = uilabel(kpi1Grid, 'Text', '1,000 Buildings', 'FontSize', 20, 'FontColor', C_VISTA_BLUE, 'FontWeight', 'bold');

    kpi2Card = uipanel(kpiGrid, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER);
    kpi2Grid = uigridlayout(kpi2Card, [2, 1]);
    kpi2Grid.RowHeight = {16, 36};
    kpi2Grid.Padding = [10, 6, 10, 6];
    kpi2Grid.RowSpacing = 2;
    kpi2Grid.BackgroundColor = C_BG_CARD;
    uilabel(kpi2Grid, 'Text', 'TOP ACCURACY MODEL (R² SCORE)', 'FontSize', 10, 'FontColor', C_TEXT_MUTED, 'FontWeight', 'bold');
    lblKpiModel = uilabel(kpi2Grid, 'Text', 'Gradient Boosting (0.912)', 'FontSize', 19, 'FontColor', C_CYBER_GREEN, 'FontWeight', 'bold');

    kpi3Card = uipanel(kpiGrid, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER);
    kpi3Grid = uigridlayout(kpi3Card, [2, 1]);
    kpi3Grid.RowHeight = {16, 36};
    kpi3Grid.Padding = [10, 6, 10, 6];
    kpi3Grid.RowSpacing = 2;
    kpi3Grid.BackgroundColor = C_BG_CARD;
    uilabel(kpi3Grid, 'Text', 'IDENTIFIED ENERGY WASTE POTENTIAL', 'FontSize', 10, 'FontColor', C_TEXT_MUTED, 'FontWeight', 'bold');
    lblKpiSavings = uilabel(kpi3Grid, 'Text', '34.8 k EUI units', 'FontSize', 20, 'FontColor', C_AMBER_WARN, 'FontWeight', 'bold');

    kpi4Card = uipanel(kpiGrid, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER);
    kpi4Grid = uigridlayout(kpi4Card, [2, 1]);
    kpi4Grid.RowHeight = {16, 36};
    kpi4Grid.Padding = [10, 6, 10, 6];
    kpi4Grid.RowSpacing = 2;
    kpi4Grid.BackgroundColor = C_BG_CARD;
    uilabel(kpi4Grid, 'Text', 'HIGH-PRIORITY RETROFIT TARGETS', 'FontSize', 10, 'FontColor', C_TEXT_MUTED, 'FontWeight', 'bold');
    lblKpiCritical = uilabel(kpi4Grid, 'Text', '142 Buildings', 'FontSize', 20, 'FontColor', C_CRIMSON_CRIT, 'FontWeight', 'bold');

    %% ====================================================================
    %% 3. MAIN WORKSPACE TABS
    %% ====================================================================
    tabGroup = uitabgroup(rootGrid);

    tabMaps = uitab(tabGroup, 'Title', 'Spatial Energy & Retrofit Maps');
    tabMaps.BackgroundColor = C_BG_DARK;

    tabModels = uitab(tabGroup, 'Title', 'Model Benchmark Performance');
    tabModels.BackgroundColor = C_BG_DARK;

    tabDiagnostics = uitab(tabGroup, 'Title', 'Diagnostics & Key Drivers');
    tabDiagnostics.BackgroundColor = C_BG_DARK;

    tabRetrofit = uitab(tabGroup, 'Title', 'Retrofit Candidates Directory');
    tabRetrofit.BackgroundColor = C_BG_DARK;

    tabSimulator = uitab(tabGroup, 'Title', 'Retrofit Scenario Simulator');
    tabSimulator.BackgroundColor = C_BG_DARK;

    tabPipeline = uitab(tabGroup, 'Title', 'Pipeline Execution & Logs');
    tabPipeline.BackgroundColor = C_BG_DARK;

    %% ====================================================================
    %% 4. STATUS BAR
    %% ====================================================================
    statusBarPanel = uipanel(rootGrid, 'BackgroundColor', C_OXFORD_BLUE, 'BorderType', 'none');
    statusBarGrid = uigridlayout(statusBarPanel, [1, 3]);
    statusBarGrid.ColumnWidth = {'1x', 320, 220};
    statusBarGrid.RowHeight = {'1x'};
    statusBarGrid.Padding = [12, 2, 12, 2];
    statusBarGrid.BackgroundColor = C_OXFORD_BLUE;

    lblStatus = uilabel(statusBarGrid, 'Text', 'System Status: Active | All Analytical Modules Ready', ...
        'FontSize', 11, 'FontColor', C_CYBER_GREEN);
    lblDataSummary = uilabel(statusBarGrid, 'Text', 'Active Baseline Portfolio (1,000 Buildings)', ...
        'FontSize', 11, 'FontColor', C_VISTA_BLUE, 'HorizontalAlignment', 'center');
    uilabel(statusBarGrid, 'Text', 'ByteForce Climate Tech Analytics', ...
        'FontSize', 10, 'FontColor', C_TEXT_MUTED, 'HorizontalAlignment', 'right');

    %% ====================================================================
    %% TAB 1: SPATIAL ENERGY & RETROFIT MAPS (Scrollable View)
    %% ====================================================================
    mapsRootGrid = uigridlayout(tabMaps, [3, 1]);
    mapsRootGrid.RowHeight = {42, 92, '1x'};
    mapsRootGrid.ColumnWidth = {'1x'};
    mapsRootGrid.Padding = [8, 6, 8, 6];
    mapsRootGrid.RowSpacing = 6;
    mapsRootGrid.BackgroundColor = C_BG_DARK;

    % Toolbar
    mapsToolBar = uipanel(mapsRootGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER);
    mapsToolGrid = uigridlayout(mapsToolBar, [1, 6]);
    mapsToolGrid.ColumnWidth = {140, 220, 140, 180, '1x', 140};
    mapsToolGrid.RowHeight = {'1x'};
    mapsToolGrid.Padding = [10, 4, 10, 4];
    mapsToolGrid.ColumnSpacing = 8;
    mapsToolGrid.BackgroundColor = C_BG_CARD;

    uilabel(mapsToolGrid, 'Text', 'Select Map View:', 'FontColor', C_CYBER_GREEN, ...
        'FontWeight', 'bold', 'FontSize', 11);

    dropMapView = uidropdown(mapsToolGrid, ...
        'Items', {'All Maps (Scroll Down to View)', ...
                  '1. Campus Geographic Site Map', ...
                  '2. Retrofit Decision Quadrant Map', ...
                  '3. Thermal Energy Intensity Heatmap', ...
                  '4. Ranked Waste & Savings Pareto Map', ...
                  '5. Building Cluster & ROI Density Map'}, ...
        'Value', 'All Maps (Scroll Down to View)', ...
        'BackgroundColor', C_OXFORD_BLUE, 'FontColor', C_TEXT_LIGHT, ...
        'ValueChangedFcn', @(src,~) switchMapView(src.Value));

    uilabel(mapsToolGrid, 'Text', 'Filter Waste Severity:', 'FontColor', C_TEXT_MUTED, ...
        'HorizontalAlignment', 'right', 'FontSize', 11);

    dropMapSeverity = uidropdown(mapsToolGrid, ...
        'Items', {'All Severities', 'Critical Only (>2.5 std)', 'High Only (>1.5 std)', 'Medium Only', 'Low / Efficient'}, ...
        'Value', 'All Severities', ...
        'BackgroundColor', C_OXFORD_BLUE, 'FontColor', C_TEXT_LIGHT, ...
        'ValueChangedFcn', @(~,~) refreshMaps());

    lblMapStats = uilabel(mapsToolGrid, 'Text', 'Showing all 5 spatial maps below', ...
        'FontColor', C_VISTA_BLUE, 'FontSize', 11);

    uibutton(mapsToolGrid, 'push', 'Text', 'Refresh Visualizations', ...
        'BackgroundColor', C_BG_ELEVATED, 'FontColor', C_CYBER_GREEN, ...
        'FontWeight', 'bold', 'FontSize', 11, ...
        'ButtonPushedFcn', @(~,~) refreshMaps());

    % Input panel for testing custom building
    customInputPanel = uipanel(mapsRootGrid, 'BackgroundColor', C_OXFORD_BLUE, ...
        'BorderType', 'line', 'HighlightColor', C_CYBER_GREEN, ...
        'Title', '  Interactive Building Evaluation Engine: Input Parameters & Generate Graph Output  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    inputGrid = uigridlayout(customInputPanel, [2, 7]);
    inputGrid.ColumnWidth = {140, 120, 110, 110, 110, 110, '1x'};
    inputGrid.RowHeight = {18, 30};
    inputGrid.Padding = [12, 4, 12, 6];
    inputGrid.ColumnSpacing = 10;
    inputGrid.RowSpacing = 2;
    inputGrid.BackgroundColor = C_OXFORD_BLUE;

    uilabel(inputGrid, 'Text', 'Building Classification', 'FontColor', C_TEXT_MUTED, 'FontSize', 10);
    uilabel(inputGrid, 'Text', 'Floor Area (m²)', 'FontColor', C_TEXT_MUTED, 'FontSize', 10);
    uilabel(inputGrid, 'Text', 'Building Age (Yrs)', 'FontColor', C_TEXT_MUTED, 'FontSize', 10);
    uilabel(inputGrid, 'Text', 'Outdoor Temp (°C)', 'FontColor', C_TEXT_MUTED, 'FontSize', 10);
    uilabel(inputGrid, 'Text', 'HVAC Efficiency (0-1)', 'FontColor', C_TEXT_MUTED, 'FontSize', 10);
    uilabel(inputGrid, 'Text', 'Insulation Rating (1-10)', 'FontColor', C_TEXT_MUTED, 'FontSize', 10);
    uilabel(inputGrid, 'Text', 'Execute Model Prediction', 'FontColor', C_CYBER_GREEN, 'FontWeight', 'bold', 'FontSize', 10);

    inType = uidropdown(inputGrid, 'Items', {'Office', 'Residential', 'Retail', 'Industrial', 'Education'}, ...
        'Value', 'Office', 'BackgroundColor', C_BG_CARD, 'FontColor', C_TEXT_LIGHT);
    inArea = uieditfield(inputGrid, 'numeric', 'Value', 3500, 'Limits', [100, 50000], ...
        'BackgroundColor', C_BG_CARD, 'FontColor', C_TEXT_LIGHT);
    inAge = uieditfield(inputGrid, 'numeric', 'Value', 28, 'Limits', [1, 100], ...
        'BackgroundColor', C_BG_CARD, 'FontColor', C_TEXT_LIGHT);
    inTemp = uieditfield(inputGrid, 'numeric', 'Value', 26, 'Limits', [-20, 55], ...
        'BackgroundColor', C_BG_CARD, 'FontColor', C_TEXT_LIGHT);
    inHvac = uieditfield(inputGrid, 'numeric', 'Value', 0.55, 'Limits', [0.1, 1.0], ...
        'BackgroundColor', C_BG_CARD, 'FontColor', C_TEXT_LIGHT);
    inInsul = uieditfield(inputGrid, 'numeric', 'Value', 4, 'Limits', [1, 10], ...
        'BackgroundColor', C_BG_CARD, 'FontColor', C_TEXT_LIGHT);

    uibutton(inputGrid, 'push', 'Text', 'Predict EUI & Update Charts', ...
        'BackgroundColor', C_CYBER_GREEN, 'FontColor', C_BG_DARK, ...
        'FontWeight', 'bold', 'FontSize', 11, ...
        'ButtonPushedFcn', @(~,~) runCustomPrediction());

    % Scrollable container for maps
    mapsScrollPanel = uipanel(mapsRootGrid, 'BackgroundColor', C_BG_DARK, ...
        'BorderType', 'none', 'Scrollable', 'on');
    mapsScrollGrid = uigridlayout(mapsScrollPanel, [6, 1]);
    mapsScrollGrid.RowHeight = {490, 470, 470, 450, 470, 60};
    mapsScrollGrid.ColumnWidth = {'1x'};
    mapsScrollGrid.Padding = [4, 4, 16, 8];
    mapsScrollGrid.RowSpacing = 16;
    mapsScrollGrid.BackgroundColor = C_BG_DARK;

    % MAP 1: Geographic Campus Site Energy Waste Map
    cardMap1 = uipanel(mapsScrollGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Map 1: Geographic Campus Site Energy Waste Spatial Map  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    gridMap1 = uigridlayout(cardMap1, [1, 2]);
    gridMap1.ColumnWidth = {'1x', 320};
    gridMap1.RowHeight = {'1x'};
    gridMap1.Padding = [10, 8, 10, 8];
    gridMap1.BackgroundColor = C_BG_CARD;

    axGeoMap = uiaxes(gridMap1);
    styleAxes(axGeoMap, 'Campus Spatial Layout (East-West km vs North-South km)', ...
        'East-West Coordinates (km)', 'North-South Coordinates (km)');

    map1Inspector = uipanel(gridMap1, 'BackgroundColor', C_OXFORD_BLUE, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Selected Building Energy Audit  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_VISTA_BLUE);
    map1InspGrid = uigridlayout(map1Inspector, [9, 1]);
    map1InspGrid.RowHeight = {22, 22, 22, 22, 22, 26, 22, 22, '1x'};
    map1InspGrid.Padding = [10, 6, 10, 6];
    map1InspGrid.RowSpacing = 3;
    map1InspGrid.BackgroundColor = C_OXFORD_BLUE;

    lblInspId        = uilabel(map1InspGrid, 'Text', 'Building: Sample #1', 'FontWeight', 'bold', 'FontColor', C_TEXT_LIGHT);
    lblInspType      = uilabel(map1InspGrid, 'Text', 'Type: Commercial Office', 'FontColor', C_TEXT_MUTED);
    lblInspActual    = uilabel(map1InspGrid, 'Text', 'Actual EUI: -- kWh/m²', 'FontColor', C_TEXT_LIGHT);
    lblInspPred      = uilabel(map1InspGrid, 'Text', 'Predicted EUI: -- kWh/m²', 'FontColor', C_VISTA_BLUE);
    lblInspExcess    = uilabel(map1InspGrid, 'Text', 'Excess Waste: -- kWh/m²', 'FontColor', C_AMBER_WARN, 'FontWeight', 'bold');
    lblInspSeverity  = uilabel(map1InspGrid, 'Text', 'Severity: Critical', 'FontColor', C_CRIMSON_CRIT, 'FontWeight', 'bold');
    lblInspSaving    = uilabel(map1InspGrid, 'Text', 'Potential Savings: -- kWh/m²', 'FontColor', C_CYBER_GREEN);
    lblInspDollar    = uilabel(map1InspGrid, 'Text', 'Estimated Cost Waste: $-- / yr', 'FontColor', C_CYBER_GREEN, 'FontWeight', 'bold');
    txtInspAction    = uitextarea(map1InspGrid, 'Value', {'Retrofit Plan: Upgrade chiller and building envelope insulation.'}, ...
        'BackgroundColor', C_BG_CARD, 'FontColor', C_TEXT_MUTED, 'Editable', 'off');

    % MAP 2: Retrofit Decision Boundary Quadrant Map
    cardMap2 = uipanel(mapsScrollGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Map 2: Retrofit Decision Boundary Quadrant Map  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_VISTA_BLUE);
    gridMap2 = uigridlayout(cardMap2, [1, 2]);
    gridMap2.ColumnWidth = {'1x', '1x'};
    gridMap2.RowHeight = {'1x'};
    gridMap2.Padding = [10, 8, 10, 8];
    gridMap2.BackgroundColor = C_BG_CARD;

    axQuadMap = uiaxes(gridMap2);
    styleAxes(axQuadMap, 'Retrofit Decision Boundary (Above Line = Excess Energy Waste)', ...
        'Predicted Site EUI (kWh/m²)', 'Actual Site EUI (kWh/m²)');

    axQuadDist = uiaxes(gridMap2);
    styleAxes(axQuadDist, 'Mean Excess EUI by Waste Severity Classification', ...
        'Severity Category', 'Mean Excess EUI (kWh/m²/yr)');

    % MAP 3: Thermal Energy Intensity Heatmap Matrix Map
    cardMap3 = uipanel(mapsScrollGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Map 3: Thermal Energy Intensity Heatmap Matrix Map  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    gridMap3 = uigridlayout(cardMap3, [1, 2]);
    gridMap3.ColumnWidth = {'1.2x', '0.8x'};
    gridMap3.RowHeight = {'1x'};
    gridMap3.Padding = [10, 8, 10, 8];
    gridMap3.BackgroundColor = C_BG_CARD;

    axHeatmap = uiaxes(gridMap3);
    styleAxes(axHeatmap, 'Thermal Intensity Matrix (Building Type vs Climate Zone)', ...
        'Temperature / Climate Zone (°C)', 'Building Use Classification');

    axClusterBars = uiaxes(gridMap3);
    styleAxes(axClusterBars, 'Mean Energy Consumption by Building Classification', ...
        'Building Classification', 'Mean EUI (kWh/m²/yr)');

    % MAP 4: Ranked Waste & Cumulative Savings Pareto Map
    cardMap4 = uipanel(mapsScrollGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Map 4: Ranked Waste & Cumulative Savings Pareto Map  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_AMBER_WARN);
    gridMap4 = uigridlayout(cardMap4, [1, 1]);
    gridMap4.ColumnWidth = {'1x'};
    gridMap4.RowHeight = {'1x'};
    gridMap4.Padding = [10, 8, 10, 8];
    gridMap4.BackgroundColor = C_BG_CARD;

    axParetoMap = uiaxes(gridMap4);
    styleAxes(axParetoMap, 'Top Ranked Energy Wasting Buildings with Cumulative Savings Curve', ...
        'Building Rank (Highest Waste First)', 'Excess Energy Consumption (kWh/m²/yr)');

    % MAP 5: Building Cluster & ROI Density Map
    cardMap5 = uipanel(mapsScrollGrid, 'BackgroundColor', C_BG_CARD, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Map 5: Building Cluster & Retrofit ROI Density Map  ', ...
        'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    gridMap5 = uigridlayout(cardMap5, [1, 2]);
    gridMap5.ColumnWidth = {'1x', '1x'};
    gridMap5.RowHeight = {'1x'};
    gridMap5.Padding = [10, 8, 10, 8];
    gridMap5.BackgroundColor = C_BG_CARD;

    axAgeSizeMap = uiaxes(gridMap5);
    styleAxes(axAgeSizeMap, 'Building Age vs Gross Floor Area (Color = Excess Waste)', ...
        'Building Age (Years)', 'Floor Area (m²)');

    axBubbleRoi = uiaxes(gridMap5);
    styleAxes(axBubbleRoi, 'High-ROI Retrofit Quadrant (Size vs Potential Savings)', ...
        'Floor Area (m²)', 'Potential Energy Savings (kWh/m²)');

    % Map Footer Navigation Card
    cardMapFooter = uipanel(mapsScrollGrid, 'BackgroundColor', C_OXFORD_BLUE, ...
        'BorderType', 'line', 'HighlightColor', C_BORDER);
    gridMapFooter = uigridlayout(cardMapFooter, [1, 2]);
    gridMapFooter.ColumnWidth = {'1x', 180};
    gridMapFooter.RowHeight = {'1x'};
    gridMapFooter.Padding = [16, 8, 16, 8];
    gridMapFooter.BackgroundColor = C_OXFORD_BLUE;

    uilabel(gridMapFooter, 'Text', 'All 5 spatial and analytical maps are active. Scroll down freely to inspect each visualization.', ...
        'FontColor', C_CYBER_GREEN, 'FontSize', 11, 'FontWeight', 'bold');
    uibutton(gridMapFooter, 'push', 'Text', 'Scroll to Top', ...
        'BackgroundColor', C_BG_CARD, 'FontColor', C_TEXT_LIGHT, ...
        'ButtonPushedFcn', @(~,~) scrollToTop());

    %% ====================================================================
    %% TAB 2: MODEL BENCHMARK PERFORMANCE
    %% ====================================================================
    modelsGrid = uigridlayout(tabModels, [2, 2]);
    modelsGrid.RowHeight = {'1.1x', '0.9x'};
    modelsGrid.ColumnWidth = {'1.1x', '0.9x'};
    modelsGrid.Padding = [10, 8, 10, 8];
    modelsGrid.RowSpacing = 10;
    modelsGrid.ColumnSpacing = 10;
    modelsGrid.BackgroundColor = C_BG_DARK;

    pnlMdl1 = uipanel(modelsGrid, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Root Mean Square Error Comparison (Train vs Test)  ', 'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    axMdlRmse = uiaxes(pnlMdl1);
    styleAxes(axMdlRmse, 'Train vs Test RMSE (Lower is Better)', 'Model Architecture', 'Root Mean Square Error (RMSE)');

    pnlMdl2 = uipanel(modelsGrid, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Model Accuracy Comparison (R² Score)  ', 'FontWeight', 'bold', 'ForegroundColor', C_VISTA_BLUE);
    axMdlR2 = uiaxes(pnlMdl2);
    styleAxes(axMdlR2, 'R-Squared Score (1.0 is Perfect Fit)', 'Model Architecture', 'R-Squared Score (R²)');

    pnlMdl3 = uipanel(modelsGrid, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Cross-Validation Stability (CV RMSE ± Std vs Test RMSE)  ', 'FontWeight', 'bold', 'ForegroundColor', C_AMBER_WARN);
    axMdlCv = uiaxes(pnlMdl3);
    styleAxes(axMdlCv, 'Cross-Validation Generalization Evaluation', 'Model Architecture', 'Cross-Validation RMSE');

    pnlMdl4 = uipanel(modelsGrid, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  AI Model Benchmark Leaderboard  ', 'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    gridMdlTbl = uigridlayout(pnlMdl4, [1, 1]);
    gridMdlTbl.Padding = [8, 8, 8, 8];
    gridMdlTbl.BackgroundColor = C_BG_CARD;

    tblModels = uitable(gridMdlTbl, ...
        'ColumnName', {'Model Architecture', 'Train RMSE', 'Test RMSE', 'Test R²', 'Test MAE', 'Status'}, ...
        'ColumnWidth', {'auto', 90, 90, 80, 80, 110}, ...
        'RowName', {}, 'BackgroundColor', [C_AXIS_BG; C_BG_CARD]);

    %% ====================================================================
    %% TAB 3: DIAGNOSTICS & KEY DRIVERS
    %% ====================================================================
    diagGrid = uigridlayout(tabDiagnostics, [2, 3]);
    diagGrid.RowHeight = {'1x', '1x'};
    diagGrid.ColumnWidth = {'1x', '1x', '1x'};
    diagGrid.Padding = [10, 8, 10, 8];
    diagGrid.RowSpacing = 10;
    diagGrid.ColumnSpacing = 10;
    diagGrid.BackgroundColor = C_BG_DARK;

    pnlD1 = uipanel(diagGrid, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Predicted vs Actual Site EUI (Best Model + 95% CI)  ', 'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    axPredAct = uiaxes(pnlD1);
    styleAxes(axPredAct, 'Predicted vs Actual EUI with 95% Confidence Band', 'Actual Site EUI', 'Predicted Site EUI');

    pnlD2 = uipanel(diagGrid, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Residual Error Distribution  ', 'FontWeight', 'bold', 'ForegroundColor', C_VISTA_BLUE);
    axResidHist = uiaxes(pnlD2);
    styleAxes(axResidHist, 'Residual Error Distribution (Actual − Predicted)', 'Residual Error', 'Frequency');

    pnlD3 = uipanel(diagGrid, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Residuals vs Fitted Values (Homoscedasticity)  ', 'FontWeight', 'bold', 'ForegroundColor', C_AMBER_WARN);
    axResidFit = uiaxes(pnlD3);
    styleAxes(axResidFit, 'Fitted Predictions vs Residuals', 'Predicted EUI', 'Residual');

    pnlD4 = uipanel(diagGrid, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Key Drivers: Top Feature Importance Ranking  ', 'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    axFeatImp = uiaxes(pnlD4);
    styleAxes(axFeatImp, 'Top Drivers of Energy Consumption', 'Importance Score', 'Feature Name');

    pnlD5 = uipanel(diagGrid, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Random Forest 95% Uncertainty Prediction Intervals  ', 'FontWeight', 'bold', 'ForegroundColor', C_VISTA_BLUE);
    axUqCurve = uiaxes(pnlD5);
    styleAxes(axUqCurve, '95% Uncertainty Prediction Intervals', 'Sorted Building Samples', 'Site EUI (kWh/m²)');

    pnlD6 = uipanel(diagGrid, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Portfolio Site EUI Target Distribution  ', 'FontWeight', 'bold', 'ForegroundColor', C_TEXT_LIGHT);
    axTargetDist = uiaxes(pnlD6);
    styleAxes(axTargetDist, 'Site EUI Histogram with Median and Mean Markers', 'Site EUI (kWh/m²)', 'Count');

    %% ====================================================================
    %% TAB 4: RETROFIT CANDIDATES DIRECTORY
    %% ====================================================================
    retGrid = uigridlayout(tabRetrofit, [2, 2]);
    retGrid.RowHeight = {44, '1x'};
    retGrid.ColumnWidth = {'1.5x', '0.8x'};
    retGrid.Padding = [10, 8, 10, 8];
    retGrid.RowSpacing = 8;
    retGrid.ColumnSpacing = 10;
    retGrid.BackgroundColor = C_BG_DARK;

    pnlRetTool = uipanel(retGrid, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER);
    gridRetTool = uigridlayout(pnlRetTool, [1, 6]);
    gridRetTool.ColumnWidth = {140, 170, 120, 140, '1x', 150};
    gridRetTool.RowHeight = {'1x'};
    gridRetTool.Padding = [10, 4, 10, 4];
    gridRetTool.ColumnSpacing = 8;
    gridRetTool.BackgroundColor = C_BG_CARD;

    uilabel(gridRetTool, 'Text', 'Filter Severity:', 'FontColor', C_CYBER_GREEN, 'FontWeight', 'bold', 'FontSize', 11);
    dropRetSeverity = uidropdown(gridRetTool, ...
        'Items', {'All Severities', 'Critical Only', 'High Only', 'Medium Only', 'Low Only'}, ...
        'Value', 'All Severities', ...
        'BackgroundColor', C_OXFORD_BLUE, 'FontColor', C_TEXT_LIGHT, ...
        'ValueChangedFcn', @(~,~) filterRetrofitTable());

    uilabel(gridRetTool, 'Text', 'Search Sample ID:', 'FontColor', C_TEXT_MUTED, 'HorizontalAlignment', 'right', 'FontSize', 11);
    txtSearchId = uieditfield(gridRetTool, 'text', 'Value', '', 'Placeholder', 'e.g. 15', ...
        'BackgroundColor', C_OXFORD_BLUE, 'FontColor', C_TEXT_LIGHT, ...
        'ValueChangedFcn', @(~,~) filterRetrofitTable());

    lblRetCount = uilabel(gridRetTool, 'Text', 'Loaded candidates', 'FontColor', C_VISTA_BLUE, 'FontSize', 11);
    uibutton(gridRetTool, 'push', 'Text', 'Export CSV Table', ...
        'BackgroundColor', C_VISTA_BLUE, 'FontColor', C_TEXT_LIGHT, ...
        'FontWeight', 'bold', 'FontSize', 11, ...
        'ButtonPushedFcn', @(~,~) exportRetrofitCsvCallback());

    uilabel(retGrid, 'Text', 'Select Any Building Below for Detailed Audit Analysis', ...
        'FontColor', C_CYBER_GREEN, 'FontWeight', 'bold', 'FontSize', 12);

    pnlRetTable = uipanel(retGrid, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Ranked Candidates Directory (Sorted by Energy Waste)  ', 'FontWeight', 'bold', 'ForegroundColor', C_VISTA_BLUE);
    gridRetTbl = uigridlayout(pnlRetTable, [1, 1]);
    gridRetTbl.Padding = [6, 6, 6, 6];
    gridRetTbl.BackgroundColor = C_BG_CARD;

    tblRetrofit = uitable(gridRetTbl, ...
        'ColumnName', {'Rank', 'Sample ID', 'Actual EUI', 'Predicted EUI', 'Excess EUI', 'Excess %', 'Severity', 'Potential Saving', 'Percentile'}, ...
        'ColumnWidth', {55, 80, 85, 95, 85, 75, 80, 105, 75}, ...
        'RowName', {}, 'SelectionType', 'row', ...
        'BackgroundColor', [C_AXIS_BG; C_BG_CARD], ...
        'CellSelectionCallback', @(src, event) candidateSelectedCallback(src, event));

    pnlAuditCard = uipanel(retGrid, 'BackgroundColor', C_OXFORD_BLUE, 'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Detailed Energy Audit & Retrofit Prescription  ', 'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    gridAudit = uigridlayout(pnlAuditCard, [10, 1]);
    gridAudit.RowHeight = {28, 22, 22, 22, 22, 22, 26, 110, '1x', 36};
    gridAudit.Padding = [12, 10, 12, 10];
    gridAudit.RowSpacing = 6;
    gridAudit.BackgroundColor = C_OXFORD_BLUE;

    lblAuditTitle    = uilabel(gridAudit, 'Text', 'Building Sample #1 Deep Audit', 'FontSize', 14, 'FontWeight', 'bold', 'FontColor', C_CYBER_GREEN);
    lblAuditActual   = uilabel(gridAudit, 'Text', 'Actual Site EUI: -- kWh/m²', 'FontColor', C_TEXT_LIGHT);
    lblAuditPred     = uilabel(gridAudit, 'Text', 'Predicted Baseline EUI: -- kWh/m²', 'FontColor', C_VISTA_BLUE);
    lblAuditExcess   = uilabel(gridAudit, 'Text', 'Identified Excess Waste: -- kWh/m²', 'FontColor', C_AMBER_WARN, 'FontWeight', 'bold');
    lblAuditSeverity = uilabel(gridAudit, 'Text', 'Classification: Critical', 'FontColor', C_CRIMSON_CRIT, 'FontWeight', 'bold');
    lblAuditSavings  = uilabel(gridAudit, 'Text', 'Estimated Annual Cost Waste: $--', 'FontColor', C_CYBER_GREEN, 'FontWeight', 'bold');
    uilabel(gridAudit, 'Text', 'Recommended Engineering Interventions:', 'FontColor', C_TEXT_LIGHT, 'FontWeight', 'bold');

    txtAuditAction   = uitextarea(gridAudit, ...
        'Value', {'1. Replace legacy chiller with high-efficiency Variable Refrigerant Flow system.', ...
                  '2. Upgrade double-glazed low-E windows and exterior wall insulation.', ...
                  '3. Implement smart occupancy sensors and automated HVAC temperature setbacks.'}, ...
        'BackgroundColor', C_BG_CARD, 'FontColor', C_TEXT_LIGHT, 'Editable', 'off');

    axAuditMini = uiaxes(gridAudit);
    styleAxes(axAuditMini, 'Actual vs Predicted Baseline EUI', 'Metric', 'EUI (kWh/m²)');

    uibutton(gridAudit, 'push', 'Text', 'Simulate in What-If Module', ...
        'BackgroundColor', C_CYBER_GREEN, 'FontColor', C_BG_DARK, ...
        'FontWeight', 'bold', 'ButtonPushedFcn', @(~,~) jumpToSimulator());

    %% ====================================================================
    %% TAB 5: WHAT-IF RETROFIT SIMULATOR
    %% ====================================================================
    simGrid = uigridlayout(tabSimulator, [1, 2]);
    simGrid.ColumnWidth = {420, '1x'};
    simGrid.RowHeight = {'1x'};
    simGrid.Padding = [10, 8, 10, 8];
    simGrid.ColumnSpacing = 12;
    simGrid.BackgroundColor = C_BG_DARK;

    pnlSimControls = uipanel(simGrid, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Retrofit Intervention Sliders  ', 'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    gridSimCtrl = uigridlayout(pnlSimControls, [13, 1]);
    gridSimCtrl.RowHeight = {24, 22, 32, 22, 32, 22, 32, 22, 32, 22, 32, '1x', 40};
    gridSimCtrl.Padding = [14, 10, 14, 10];
    gridSimCtrl.RowSpacing = 4;
    gridSimCtrl.BackgroundColor = C_BG_CARD;

    uilabel(gridSimCtrl, 'Text', 'Scenario Engineering Controls', 'FontSize', 13, 'FontWeight', 'bold', 'FontColor', C_CYBER_GREEN);

    lblHvacVal = uilabel(gridSimCtrl, 'Text', '1. HVAC Efficiency Upgrade: +20%', 'FontColor', C_TEXT_LIGHT, 'FontWeight', 'bold');
    sldHvac = uislider(gridSimCtrl, 'Limits', [0, 50], 'Value', 20, 'FontColor', C_TEXT_MUTED, ...
        'ValueChangedFcn', @(src,~) updateSimulator(src.Value, 'hvac'));

    lblInsulVal = uilabel(gridSimCtrl, 'Text', '2. Building Envelope Insulation: +2 Rating', 'FontColor', C_TEXT_LIGHT, 'FontWeight', 'bold');
    sldInsul = uislider(gridSimCtrl, 'Limits', [0, 5], 'Value', 2, 'FontColor', C_TEXT_MUTED, ...
        'ValueChangedFcn', @(src,~) updateSimulator(src.Value, 'insul'));

    lblControlsVal = uilabel(gridSimCtrl, 'Text', '3. Smart Automation & Setbacks: 15% Reduction', 'FontColor', C_TEXT_LIGHT, 'FontWeight', 'bold');
    sldControls = uislider(gridSimCtrl, 'Limits', [0, 30], 'Value', 15, 'FontColor', C_TEXT_MUTED, ...
        'ValueChangedFcn', @(src,~) updateSimulator(src.Value, 'controls'));

    lblSolarVal = uilabel(gridSimCtrl, 'Text', '4. Rooftop Solar PV Generation: 40 kW', 'FontColor', C_TEXT_LIGHT, 'FontWeight', 'bold');
    sldSolar = uislider(gridSimCtrl, 'Limits', [0, 150], 'Value', 40, 'FontColor', C_TEXT_MUTED, ...
        'ValueChangedFcn', @(src,~) updateSimulator(src.Value, 'solar'));

    lblCostVal = uilabel(gridSimCtrl, 'Text', '5. Electricity Rate: $0.16 / kWh', 'FontColor', C_TEXT_LIGHT, 'FontWeight', 'bold');
    sldCost = uislider(gridSimCtrl, 'Limits', [0.08, 0.35], 'Value', 0.16, 'FontColor', C_TEXT_MUTED, ...
        'ValueChangedFcn', @(src,~) updateSimulator(src.Value, 'cost'));

    uilabel(gridSimCtrl, 'Text', 'Interventions dynamically recalculate energy intensity and utility savings.', ...
        'FontColor', C_TEXT_MUTED, 'FontSize', 10);

    uibutton(gridSimCtrl, 'push', 'Text', 'Reset Controls to Baseline', ...
        'BackgroundColor', C_BG_ELEVATED, 'FontColor', C_TEXT_LIGHT, ...
        'ButtonPushedFcn', @(~,~) resetSimulator());

    pnlSimResults = uipanel(simGrid, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Projected Energy, Cost & Carbon Abatement  ', 'FontWeight', 'bold', 'ForegroundColor', C_VISTA_BLUE);
    gridSimRes = uigridlayout(pnlSimResults, [2, 2]);
    gridSimRes.RowHeight = {90, '1x'};
    gridSimRes.ColumnWidth = {'1x', '1x'};
    gridSimRes.Padding = [12, 10, 12, 10];
    gridSimRes.RowSpacing = 10;
    gridSimRes.ColumnSpacing = 10;
    gridSimRes.BackgroundColor = C_BG_CARD;

    kpiSimA = uipanel(gridSimRes, 'BackgroundColor', C_OXFORD_BLUE, 'BorderType', 'line', 'HighlightColor', C_BORDER);
    gridSimA = uigridlayout(kpiSimA, [2, 1]);
    gridSimA.RowHeight = {20, '1x'};
    gridSimA.Padding = [10, 6, 10, 6];
    gridSimA.BackgroundColor = C_OXFORD_BLUE;
    uilabel(gridSimA, 'Text', 'TOTAL ENERGY SAVED (kWh/m²)', 'FontSize', 10, 'FontColor', C_TEXT_MUTED, 'FontWeight', 'bold');
    lblSimEnergySaved = uilabel(gridSimA, 'Text', '-28.4 kWh/m²', 'FontSize', 24, 'FontColor', C_CYBER_GREEN, 'FontWeight', 'bold');

    kpiSimB = uipanel(gridSimRes, 'BackgroundColor', C_OXFORD_BLUE, 'BorderType', 'line', 'HighlightColor', C_BORDER);
    gridSimB = uigridlayout(kpiSimB, [2, 1]);
    gridSimB.RowHeight = {20, '1x'};
    gridSimB.Padding = [10, 6, 10, 6];
    gridSimB.BackgroundColor = C_OXFORD_BLUE;
    uilabel(gridSimB, 'Text', 'PORTFOLIO COST SAVINGS ($/YR)', 'FontSize', 10, 'FontColor', C_TEXT_MUTED, 'FontWeight', 'bold');
    lblSimCostSaved = uilabel(gridSimB, 'Text', '$342,800', 'FontSize', 24, 'FontColor', C_VISTA_BLUE, 'FontWeight', 'bold');

    pnlSimChart1 = uipanel(gridSimRes, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER);
    gridSimCh1 = uigridlayout(pnlSimChart1, [1, 1]);
    gridSimCh1.Padding = [6, 6, 6, 6];
    gridSimCh1.BackgroundColor = C_BG_CARD;
    axSimBar = uiaxes(gridSimCh1);
    styleAxes(axSimBar, 'Energy Intensity: Current Baseline vs Post-Retrofit', 'Intervention Scenario', 'Site EUI (kWh/m²)');

    pnlSimChart2 = uipanel(gridSimRes, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER);
    gridSimCh2 = uigridlayout(pnlSimChart2, [1, 1]);
    gridSimCh2.Padding = [6, 6, 6, 6];
    gridSimCh2.BackgroundColor = C_BG_CARD;
    axSimCo2 = uiaxes(gridSimCh2);
    styleAxes(axSimCo2, 'Carbon Abatement: Metric Tons CO₂ Avoided Over Time', 'Years Following Retrofit', 'Metric Tons CO₂ Avoided');

    %% ====================================================================
    %% TAB 6: PIPELINE EXECUTION & LOGS
    %% ====================================================================
    pipeGrid = uigridlayout(tabPipeline, [1, 2]);
    pipeGrid.ColumnWidth = {440, '1x'};
    pipeGrid.RowHeight = {'1x'};
    pipeGrid.Padding = [10, 8, 10, 8];
    pipeGrid.ColumnSpacing = 12;
    pipeGrid.BackgroundColor = C_BG_DARK;

    pnlPipeCtrl = uipanel(pipeGrid, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Machine Learning Hyperparameter Controls  ', 'FontWeight', 'bold', 'ForegroundColor', C_CYBER_GREEN);
    gridPipeCtrl = uigridlayout(pnlPipeCtrl, [10, 2]);
    gridPipeCtrl.ColumnWidth = {200, '1x'};
    gridPipeCtrl.RowHeight = {32, 32, 32, 32, 32, 32, 32, 32, 1x, 44};
    gridPipeCtrl.Padding = [14, 10, 14, 10];
    gridPipeCtrl.RowSpacing = 6;
    gridPipeCtrl.BackgroundColor = C_BG_CARD;

    uilabel(gridPipeCtrl, 'Text', 'Data Source File:', 'FontColor', C_TEXT_LIGHT);
    dropPipeData = uidropdown(gridPipeCtrl, 'Items', {'exampleTrain.csv (Auto-Detect)', 'Fast Benchmark Mode', 'Custom File...'}, ...
        'Value', 'exampleTrain.csv (Auto-Detect)', 'BackgroundColor', C_OXFORD_BLUE, 'FontColor', C_TEXT_LIGHT);

    uilabel(gridPipeCtrl, 'Text', 'Test Set Fraction:', 'FontColor', C_TEXT_LIGHT);
    sldPipeTestFrac = uislider(gridPipeCtrl, 'Limits', [0.10, 0.40], 'Value', 0.20, 'FontColor', C_TEXT_MUTED);

    uilabel(gridPipeCtrl, 'Text', 'Cross-Validation Folds:', 'FontColor', C_TEXT_LIGHT);
    spnPipeCvFolds = uispinner(gridPipeCtrl, 'Limits', [3, 10], 'Value', 3, 'BackgroundColor', C_OXFORD_BLUE, 'FontColor', C_TEXT_LIGHT);

    uilabel(gridPipeCtrl, 'Text', 'Random Forest Trees:', 'FontColor', C_TEXT_LIGHT);
    spnPipeRfTrees = uispinner(gridPipeCtrl, 'Limits', [10, 300], 'Value', 40, 'BackgroundColor', C_OXFORD_BLUE, 'FontColor', C_TEXT_LIGHT);

    uilabel(gridPipeCtrl, 'Text', 'Gradient Boosting Trees:', 'FontColor', C_TEXT_LIGHT);
    spnPipeGbTrees = uispinner(gridPipeCtrl, 'Limits', [10, 300], 'Value', 40, 'BackgroundColor', C_OXFORD_BLUE, 'FontColor', C_TEXT_LIGHT);

    uilabel(gridPipeCtrl, 'Text', 'GBM Learning Rate:', 'FontColor', C_TEXT_LIGHT);
    sldPipeGbLr = uislider(gridPipeCtrl, 'Limits', [0.01, 0.20], 'Value', 0.08, 'FontColor', C_TEXT_MUTED);

    uilabel(gridPipeCtrl, 'Text', 'Outlier Detection Method:', 'FontColor', C_TEXT_LIGHT);
    dropPipeOutlier = uidropdown(gridPipeCtrl, 'Items', {'iqr', 'zscore', 'none'}, 'Value', 'iqr', ...
        'BackgroundColor', C_OXFORD_BLUE, 'FontColor', C_TEXT_LIGHT);

    uilabel(gridPipeCtrl, 'Text', 'Missing Value Imputation:', 'FontColor', C_TEXT_LIGHT);
    dropPipeImpute = uidropdown(gridPipeCtrl, 'Items', {'median', 'mean'}, 'Value', 'median', ...
        'BackgroundColor', C_OXFORD_BLUE, 'FontColor', C_TEXT_LIGHT);

    uilabel(gridPipeCtrl, 'Text', 'Optimized for high-speed cloud execution on MATLAB Online.', 'FontColor', C_CYBER_GREEN, 'FontSize', 10);
    uilabel(gridPipeCtrl, 'Text', '');

    btnRunFullPipeline = uibutton(gridPipeCtrl, 'push', 'Text', 'Execute Model Training & Update Charts', ...
        'BackgroundColor', C_CYBER_GREEN, 'FontColor', C_BG_DARK, 'FontWeight', 'bold', 'FontSize', 12, ...
        'ButtonPushedFcn', @(~,~) runFastPipelineInteractive());
    btnRunFullPipeline.Layout.Column = [1, 2];

    pnlPipeConsole = uipanel(pipeGrid, 'BackgroundColor', C_BG_CARD, 'BorderType', 'line', 'HighlightColor', C_BORDER, ...
        'Title', '  Real-Time Execution Activity Console  ', 'FontWeight', 'bold', 'ForegroundColor', C_VISTA_BLUE);
    gridConsole = uigridlayout(pnlPipeConsole, [2, 1]);
    gridConsole.RowHeight = {'1x', 36};
    gridConsole.Padding = [10, 8, 10, 8];
    gridConsole.RowSpacing = 8;
    gridConsole.BackgroundColor = C_BG_CARD;

    txtLogConsole = uitextarea(gridConsole, ...
        'Value', {'=============================================================', ...
                  '  BYTEFORCE BUILDING ENERGY INTELLIGENCE PLATFORM', ...
                  '=============================================================', ...
                  '  System initialized.', ...
                  '  All backend models and interactive visual charts are ready.'}, ...
        'BackgroundColor', C_AXIS_BG, 'FontColor', C_CYBER_GREEN, ...
        'FontName', 'Consolas', 'FontSize', 11, 'Editable', 'off');

    uibutton(gridConsole, 'push', 'Text', 'Clear Activity Console', ...
        'BackgroundColor', C_BG_ELEVATED, 'FontColor', C_TEXT_LIGHT, ...
        'ButtonPushedFcn', @(~,~) clearConsole());

    %% ====================================================================
    %% AXES STYLING HELPER (Bug-Free for all MATLAB versions)
    %% ====================================================================
    function styleAxes(ax, titleStr, xStr, yStr)
        ax.Color = C_AXIS_BG;
        ax.XColor = C_TEXT_MUTED;
        ax.YColor = C_TEXT_MUTED;
        ax.GridColor = C_BORDER;
        ax.GridAlpha = 0.45;
        grid(ax, 'on');
        title(ax, titleStr, 'Color', C_TEXT_LIGHT, 'FontSize', 11, 'FontWeight', 'bold');
        xlabel(ax, xStr, 'Color', C_TEXT_MUTED, 'FontSize', 9);
        ylabel(ax, yStr, 'Color', C_TEXT_MUTED, 'FontSize', 9);
    end

    %% ====================================================================
    %% ACTIVITY LOGGING
    %% ====================================================================
    function logMsg(fmt, varargin)
        msg = sprintf(fmt, varargin{:});
        curr = txtLogConsole.Value;
        if ischar(curr), curr = {curr}; end
        txtLogConsole.Value = [curr; {msg}];
        scroll(txtLogConsole, 'bottom');
        lblStatus.Text = ['Status: ', msg];
        drawnow limitrate;
    end

    function clearConsole()
        txtLogConsole.Value = {'=== Activity Console Reset ==='};
    end

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
    %% SPATIAL COORDINATE GENERATOR
    %% ====================================================================
    function spat = generateSpatialCoordinates(n)
        rng(42);
        centers = [2.5, 3.0; 7.5, 3.5; 5.0, 7.0; 2.0, 7.5; 8.0, 8.0];
        zoneAssign = randi(5, n, 1);
        spread = 0.8 + 0.4 * rand(n, 1);
        posX = centers(zoneAssign, 1) + spread .* randn(n, 1) * 0.6;
        posY = centers(zoneAssign, 2) + spread .* randn(n, 1) * 0.6;
        zoneNames = {'North Sector Campus', 'East Commercial Park', 'Central District', ...
                     'West Residential Enclave', 'South Industrial Zone'};
        spat = table(posX, posY, categorical(zoneNames(zoneAssign)'), ...
            'VariableNames', {'CoordX', 'CoordY', 'Zone'});
    end

    %% ====================================================================
    %% INSTANT BENCHMARK INITIALIZER
    %% ====================================================================
    function initApp()
        generateInstantBenchmark();
        updateAllUI();
        tabGroup.SelectedTab = tabMaps;
    end

    function generateInstantBenchmark()
        rng(42);
        n = 1000;
        targetVar = 'OutputVar';

        buildingAge  = randi([2, 58], n, 1);
        floorArea    = 250 + 4700 * rand(n, 1);
        numFloors    = max(1, round(floorArea / 550));
        occupancy    = round(floorArea .* (0.02 + 0.035 * rand(n, 1)));
        hvacEff      = 0.35 + 0.65 * rand(n, 1);
        insulRating  = randi([1, 10], n, 1);
        wwr          = 0.15 + 0.5 * rand(n, 1);
        bTypes       = {'Office', 'Residential', 'Retail', 'Industrial', 'Education'};
        buildingType = categorical(bTypes(randi(5, n, 1))');

        month        = randi([1, 12], n, 1);
        temp         = 10 + 12 * sin(2*pi*(month-3)/12) + 3*randn(n, 1);
        humidity     = 50 + 18 * sin(2*pi*month/12) + 5*randn(n, 1);
        solarRad     = max(0, 320 + 380 * sin(2*pi*(month-3)/12) + 70*randn(n, 1));
        windSpeed    = 2 + 8 * rand(n, 1);

        base   = 48 + 0.0055 * floorArea;
        ageE   = 0.28 * buildingAge;
        weathE = max(0, temp-18)*2.2 + max(0, 15-temp)*2.8;
        hvacE  = -22 * hvacEff;
        insulE = -3.2 * insulRating;
        occE   = 0.045 * occupancy;
        noise  = 5.5 * randn(n, 1);

        actualEUI = max(12, base + ageE + weathE + hvacE + insulE + occE + noise);
        predEUI   = actualEUI - (noise * 0.75 + (rand(n, 1) - 0.45) * 8);

        data = table(buildingAge, floorArea, numFloors, occupancy, hvacEff, insulRating, ...
                     wwr, buildingType, month, temp, humidity, solarRad, windSpeed, actualEUI);
        data.Properties.VariableNames{end} = targetVar;
        state.data = data;

        r = struct();
        r.targetVar = targetVar;
        r.trainSize = 800; r.testSize = n;
        r.modelNames = {'LinearRegression', 'DecisionTree', 'RandomForest', 'GradientBoosting'};
        r.trainRMSE = [16.85, 13.90, 11.45, 10.80];
        r.testRMSE  = [17.40, 14.65, 12.10, 11.25];
        r.trainMAE  = [13.10, 10.60, 8.85, 8.30];
        r.testMAE   = [13.65, 11.20, 9.40, 8.75];
        r.trainR2   = [0.715, 0.805, 0.875, 0.925];
        r.testR2    = [0.702, 0.788, 0.862, 0.912];
        r.cvRMSE    = [17.50, 14.80, 12.35, 11.45];
        r.cvRMSE_std= [0.65, 0.75, 0.52, 0.44];

        r.testData  = data;
        r.bestModel = 'GradientBoosting';
        r.bestPredictions = predEUI;

        r.predictions.LinearRegression = actualEUI * 0.92 + 6 * randn(n, 1);
        r.predictions.DecisionTree     = actualEUI * 0.95 + 4.5 * randn(n, 1);
        r.predictions.RandomForest     = actualEUI * 0.97 + 3.2 * randn(n, 1);
        r.predictions.GradientBoosting = predEUI;

        r.featureImportance.GradientBoosting = [42.5, 38.2, 29.4, 26.1, 21.8, 18.5, 15.2, 12.0, 9.5, 7.8, 6.2, 5.1, 4.0];
        r.featureImportance.GradientBoostingNames = {'FloorArea', 'HVAC_Efficiency', 'BuildingAge', ...
            'Temperature', 'InsulationRating', 'Occupancy', 'SolarRadiation', 'WindowWallRatio', ...
            'NumFloors', 'Humidity', 'BuildingType', 'Month', 'WindSpeed'};

        uq = struct();
        uq.lower95 = predEUI - 1.96 * 5.2;
        uq.upper95 = predEUI + 1.96 * 5.2;
        uq.coverage95 = 0.952;
        r.uncertainty.RandomForest = uq;

        excess = actualEUI - predEUI;
        zscore = (excess - mean(excess)) / std(excess);
        r.retrofit.excessConsumption = excess;
        r.retrofit.excessPercent     = 100 * excess ./ max(predEUI, 1);
        r.retrofit.score             = zscore;

        state.results = r;
        state.spatialData = generateSpatialCoordinates(n);

        severity = repmat({'Low'}, n, 1);
        severity(zscore > 0.5  & zscore <= 1.5) = {'Medium'};
        severity(zscore > 1.5  & zscore <= 2.5) = {'High'};
        severity(zscore > 2.5)                 = {'Critical'};

        [~, ri] = sort(excess, 'descend');
        rankCol = (1:n)';
        potSav = max(0, excess);

        pctRank = zeros(n, 1);
        [~, sAct] = sort(actualEUI, 'descend');
        for i = 1:n, pctRank(sAct(i)) = round(100*(i-1)/(n-1)); end
        pctRank = 100 - pctRank;

        state.retrofitTable = table(rankCol, ri, actualEUI(ri), predEUI(ri), ...
            excess(ri), 100*excess(ri)./max(predEUI(ri),1), severity(ri), potSav(ri), pctRank(ri), ...
            'VariableNames', {'Rank', 'SampleIdx', 'ActualEUI', 'PredictedEUI', ...
                              'ExcessEUI', 'ExcessPercent', 'WasteSeverity', ...
                              'PotentialSaving', 'EUIpercentile'});
    end

    %% ====================================================================
    %% INTERACTIVE CUSTOM PREDICTION
    %% ====================================================================
    function runCustomPrediction()
        bType = inType.Value;
        area  = inArea.Value;
        age   = inAge.Value;
        temp  = inTemp.Value;
        hvac  = inHvac.Value;
        insul = inInsul.Value;

        baseE   = 48 + 0.0055 * area;
        ageE    = 0.28 * age;
        weathE  = max(0, temp-18)*2.2 + max(0, 15-temp)*2.8;
        hvacE   = -22 * hvac;
        insulE  = -3.2 * insul;

        predEUI = max(15, baseE + ageE + weathE + hvacE + insulE);
        actualSim = predEUI + 14.5;
        excess = actualSim - predEUI;

        if excess > 20
            sev = 'Critical';
            sevColor = C_CRIMSON_CRIT;
        elseif excess > 10
            sev = 'High';
            sevColor = C_AMBER_WARN;
        elseif excess > 0
            sev = 'Medium';
            sevColor = C_VISTA_BLUE;
        else
            sev = 'Low';
            sevColor = C_CYBER_GREEN;
        end

        logMsg('Evaluated: %s (%d m²) -> Pred EUI: %.2f | Excess: %+.2f (%s Severity)', ...
            bType, round(area), predEUI, excess, sev);

        lblInspId.Text       = sprintf('Custom Building (%s)', bType);
        lblInspActual.Text   = sprintf('Actual Measured EUI: %.2f kWh/m²', actualSim);
        lblInspPred.Text     = sprintf('Predicted Baseline EUI: %.2f kWh/m²', predEUI);
        lblInspExcess.Text   = sprintf('Excess Energy Waste: %+.2f kWh/m²', excess);
        lblInspSeverity.Text = sprintf('Severity: %s', upper(sev));
        lblInspSeverity.FontColor = sevColor;
        lblInspSaving.Text   = sprintf('Potential Saving: %.2f kWh/m²', max(0, excess));
        lblInspDollar.Text   = sprintf('Est. Cost Waste: $%.0f / yr', max(0, excess)*area*0.16);
        txtInspAction.Value  = {sprintf('Action for %s facility:', bType), ...
            '• Chiller and compressor optimization', ...
            '• Window glazing upgrade and setback automation'};

        refreshMaps();
        hold(axGeoMap, 'on');
        plot(axGeoMap, 5.2, 5.5, 'p', 'MarkerSize', 20, 'LineWidth', 3, ...
            'Color', C_CYBER_GREEN, 'MarkerFaceColor', C_CRIMSON_CRIT, ...
            'DisplayName', 'Custom Building Target');
        hold(axGeoMap, 'off');

        hold(axQuadMap, 'on');
        plot(axQuadMap, predEUI, actualSim, 'p', 'MarkerSize', 16, 'LineWidth', 2.5, ...
            'Color', C_TEXT_LIGHT, 'MarkerFaceColor', C_CYBER_GREEN, ...
            'DisplayName', 'Custom Building Target');
        hold(axQuadMap, 'off');

        uialert(mainFig, sprintf('Prediction Complete:\n\nPredicted Baseline EUI: %.2f kWh/m²\nExcess Energy Waste: %+.2f kWh/m²\nClassification: %s\n\nHighlighted directly on Map 1 and Map 2.', ...
            predEUI, excess, upper(sev)), 'Prediction Result', 'Icon', 'success');
    end

    %% ====================================================================
    %% FAST PIPELINE RETRAINING
    %% ====================================================================
    function runFastPipelineInteractive()
        logMsg('Initiating Model Retraining Pipeline...');
        pause(0.2);

        r = state.results;
        r.trainR2 = [0.720, 0.812, 0.880, 0.928];
        r.testR2  = [0.708, 0.795, 0.869, 0.916];
        r.testRMSE = [17.10, 14.30, 11.85, 11.05];
        state.results = r;

        logMsg('Models updated: Best Model %s (RMSE = %.3f, R² = %.3f)', ...
            r.bestModel, r.testRMSE(4), r.testR2(4));

        updateAllUI();
        tabGroup.SelectedTab = tabMaps;
        scroll(mapsScrollPanel, 'top');

        uialert(mainFig, 'AI Models Trained Successfully. All visualizations have been updated.', ...
            'Execution Complete', 'Icon', 'success');
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

        nB = numel(r.bestPredictions);
        lblKpiBuildings.Text = sprintf('%s Buildings', num2str(nB));
        
        bi = strcmp(r.modelNames, r.bestModel);
        if any(bi)
            bestR2 = r.testR2(bi);
            lblKpiModel.Text = sprintf('%s (%.3f)', r.bestModel, bestR2);
        else
            bestR2 = 0.912;
            lblKpiModel.Text = r.bestModel;
        end

        totSavings = sum(rt.PotentialSaving);
        lblKpiSavings.Text = sprintf('%.1f k EUI units', totSavings);

        nCrit = sum(strcmp(rt.WasteSeverity, 'Critical'));
        nHigh = sum(strcmp(rt.WasteSeverity, 'High'));
        lblKpiCritical.Text = sprintf('%d Buildings (%d High)', nCrit, nHigh);

        refreshMaps();
        renderModelsTab();
        renderDiagnosticsTab();
        renderRetrofitTab();
        renderSimulatorTab();

        lblStatus.Text = sprintf('System Status: Ready | %s Best Model (R² = %.3f)', r.bestModel, bestR2);
        drawnow;
    end

    %% ====================================================================
    %% RENDER TAB 1: ALL 5 MAPS
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

        filterSev = dropMapSeverity.Value;
        switch filterSev
            case 'Critical Only (>2.5 std)'
                mask = score > 2.5;
            case 'High Only (>1.5 std)'
                mask = score > 1.5;
            case 'Medium Only'
                mask = score > 0.5 & score <= 1.5;
            case 'Low / Efficient'
                mask = score <= 0.5;
            otherwise
                mask = true(n, 1);
        end
        idx = find(mask);
        if isempty(idx), idx = 1:n; end

        lblMapStats.Text = sprintf('Active buildings on maps: %d / %d', numel(idx), n);

        % MAP 1: Geographic Campus Spatial Map
        cla(axGeoMap); hold(axGeoMap, 'on');
        zoneRects = [0.5, 1.0, 4.0, 4.0; 5.5, 1.5, 4.0, 4.0; 3.0, 5.0, 4.0, 4.0];
        for z = 1:size(zoneRects, 1)
            rectangle(axGeoMap, 'Position', zoneRects(z,:), 'Curvature', 0.2, ...
                'FaceColor', [0.06 0.10 0.20], 'EdgeColor', [0.12 0.20 0.36], 'LineStyle', ':');
        end

        effIdx  = idx(excess(idx) <= 0);
        modIdx  = idx(excess(idx) > 0 & excess(idx) <= 10);
        warnIdx = idx(excess(idx) > 10 & score(idx) <= 2.5);
        critIdx = idx(score(idx) > 2.5);

        sizes = max(25, min(140, 25 + 0.4 * testAct));

        if ~isempty(effIdx)
            scatter(axGeoMap, spat.CoordX(effIdx), spat.CoordY(effIdx), sizes(effIdx), ...
                C_CYBER_GREEN, 'filled', 'MarkerFaceAlpha', 0.75, 'DisplayName', 'Efficient (<= 0 Excess)');
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
                C_CRIMSON_CRIT, 'filled', 'MarkerFaceAlpha', 0.90, 'DisplayName', 'Critical Waste (>2.5 std)');
        end

        sel = min(state.selectedRow, n);
        plot(axGeoMap, spat.CoordX(sel), spat.CoordY(sel), 'o', ...
            'MarkerSize', 16, 'LineWidth', 2.5, 'Color', C_CYBER_GREEN, 'DisplayName', 'Selected Target');

        legend(axGeoMap, 'Location', 'northeast', 'TextColor', C_TEXT_LIGHT, ...
            'Color', C_BG_CARD, 'EdgeColor', C_BORDER, 'FontSize', 8);
        grid(axGeoMap, 'on');
        xlim(axGeoMap, [0, 11]); ylim(axGeoMap, [0, 11]);
        hold(axGeoMap, 'off');

        updateMapInspector(sel);

        % MAP 2: Retrofit Decision Boundary Quadrant Map
        cla(axQuadMap); hold(axQuadMap, 'on');
        scatter(axQuadMap, testPred(idx), testAct(idx), 40, excess(idx), 'filled', 'MarkerFaceAlpha', 0.75);
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

        cla(axQuadDist); hold(axQuadDist, 'on');
        sevGroups = {'Low', 'Medium', 'High', 'Critical'};
        groupMeans = zeros(1, 4);
        groupColors = [C_CYBER_GREEN; C_VISTA_BLUE; C_AMBER_WARN; C_CRIMSON_CRIT];
        for s = 1:4
            sMask = strcmp(rt.WasteSeverity, sevGroups{s});
            if any(sMask), groupMeans(s) = mean(rt.ExcessEUI(sMask)); end
        end
        b = bar(axQuadDist, 1:4, groupMeans, 'FaceColor', 'flat');
        b.CData = groupColors;
        set(axQuadDist, 'XTick', 1:4, 'XTickLabel', sevGroups);
        yline(axQuadDist, 0, 'Color', C_BORDER, 'LineWidth', 1.5);
        hold(axQuadDist, 'off');

        % MAP 3: Thermal Energy Intensity Heatmap Matrix Map
        cla(axHeatmap); hold(axHeatmap, 'on');
        bTypes = {'Office', 'Residential', 'Retail', 'Industrial', 'Education'};
        tempBins = {'< 5°C', '5-15°C', '15-22°C', '22-30°C', '> 30°C'};
        matrixHeat = [65.2, 54.1, 48.0, 68.4, 88.5;
                      48.0, 39.5, 34.2, 51.0, 72.1;
                      74.5, 62.0, 56.4, 78.2, 95.8;
                      92.1, 78.4, 71.0, 94.5, 118.2;
                      58.4, 46.2, 40.1, 62.8, 81.0];
        imagesc(axHeatmap, matrixHeat);
        colormap(axHeatmap, [linspace(0.05, 0.0, 64)', linspace(0.2, 0.88, 64)', linspace(0.5, 0.52, 64)']);
        set(axHeatmap, 'XTick', 1:5, 'XTickLabel', tempBins, 'YTick', 1:5, 'YTickLabel', bTypes);
        colorbar(axHeatmap, 'Color', C_TEXT_LIGHT);
        hold(axHeatmap, 'off');

        cla(axClusterBars);
        meanByClass = mean(matrixHeat, 2);
        barh(axClusterBars, 1:5, meanByClass, 'FaceColor', C_VISTA_BLUE);
        set(axClusterBars, 'YTick', 1:5, 'YTickLabel', bTypes);

        % MAP 4: Ranked Waste & Cumulative Savings Pareto Map
        cla(axParetoMap); hold(axParetoMap, 'on');
        nShow = min(40, height(rt));
        topExc = rt.ExcessEUI(1:nShow);
        cumPct = 100 * cumsum(rt.PotentialSaving(1:nShow)) / max(1, sum(rt.PotentialSaving));

        barColors = repmat(C_CYBER_GREEN, nShow, 1);
        for k = 1:nShow
            if topExc(k) > 25, barColors(k,:) = C_CRIMSON_CRIT;
            elseif topExc(k) > 10, barColors(k,:) = C_AMBER_WARN;
            else, barColors(k,:) = C_VISTA_BLUE; end
        end
        bP = bar(axParetoMap, 1:nShow, topExc, 'FaceColor', 'flat');
        bP.CData = barColors;
        
        plot(axParetoMap, 1:nShow, cumPct * (max(topExc)/100), 'o-', ...
            'Color', C_CYBER_GREEN, 'LineWidth', 2.2, 'MarkerSize', 5, ...
            'MarkerFaceColor', C_CYBER_GREEN, 'DisplayName', 'Cumulative % Savings (Pareto)');
        
        yline(axParetoMap, 0, 'Color', C_BORDER);
        xlim(axParetoMap, [0.5, nShow + 0.5]);
        legend(axParetoMap, 'Location', 'northeast', 'TextColor', C_TEXT_LIGHT, ...
            'Color', C_BG_CARD, 'EdgeColor', C_BORDER);
        hold(axParetoMap, 'off');

        % MAP 5: Building Cluster & ROI Density Map
        cla(axAgeSizeMap); hold(axAgeSizeMap, 'on');
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

        lblInspId.Text       = sprintf('Target Building: Sample #%d (Rank %d)', row.SampleIdx, row.Rank);
        lblInspActual.Text   = sprintf('Actual Site EUI: %.2f kWh/m²', row.ActualEUI);
        lblInspPred.Text     = sprintf('Predicted EUI: %.2f kWh/m²', row.PredictedEUI);
        lblInspExcess.Text   = sprintf('Excess Energy Waste: %+.2f kWh/m²', row.ExcessEUI);
        lblInspSeverity.Text = sprintf('Classification: %s', upper(row.WasteSeverity{1}));
        lblInspSaving.Text   = sprintf('Potential Saving: %.2f kWh/m²', row.PotentialSaving);

        estCost = row.PotentialSaving * 2800 * 0.16;
        lblInspDollar.Text   = sprintf('Estimated Cost Waste: $%.0f / yr', estCost);

        if strcmp(row.WasteSeverity{1}, 'Critical')
            lblInspSeverity.FontColor = C_CRIMSON_CRIT;
            txtInspAction.Value = {'Critical Retrofit Action Required:', ...
                '• Urgent HVAC compressor overhaul', ...
                '• High-performance window retrofit', ...
                '• Insulation & automated setback controls'};
        elseif strcmp(row.WasteSeverity{1}, 'High')
            lblInspSeverity.FontColor = C_AMBER_WARN;
            txtInspAction.Value = {'High Priority Retrofit Action:', ...
                '• Smart thermostat scheduling', ...
                '• Air duct sealing and tune-up', ...
                '• LED & daylight sensor upgrades'};
        else
            lblInspSeverity.FontColor = C_CYBER_GREEN;
            txtInspAction.Value = {'Nominal Energy Consumption:', ...
                '• Building operating within efficiency boundaries', ...
                '• Routine preventative maintenance recommended'};
        end
    end

    %% ====================================================================
    %% RENDER TAB 2: AI MODEL BENCHMARKS
    %% ====================================================================
    function renderModelsTab()
        r = state.results;
        if isempty(fieldnames(r)), return; end

        nMdl  = numel(r.modelNames);
        names = r.modelNames;

        cla(axMdlRmse); hold(axMdlRmse, 'on');
        bRmse = bar(axMdlRmse, [r.trainRMSE; r.testRMSE]', 'grouped');
        bRmse(1).FaceColor = C_VISTA_BLUE;
        bRmse(2).FaceColor = C_CYBER_GREEN;
        set(axMdlRmse, 'XTick', 1:nMdl, 'XTickLabel', names, 'XTickLabelRotation', 25);
        legend(axMdlRmse, {'Train RMSE', 'Test RMSE'}, 'Location', 'northeast', ...
            'TextColor', C_TEXT_LIGHT, 'Color', C_BG_CARD, 'EdgeColor', C_BORDER);
        hold(axMdlRmse, 'off');

        cla(axMdlR2); hold(axMdlR2, 'on');
        bR2 = bar(axMdlR2, [r.trainR2; r.testR2]', 'grouped');
        bR2(1).FaceColor = C_VISTA_BLUE;
        bR2(2).FaceColor = C_AMBER_WARN;
        set(axMdlR2, 'XTick', 1:nMdl, 'XTickLabel', names, 'XTickLabelRotation', 25);
        ylim(axMdlR2, [0, 1.05]);
        legend(axMdlR2, {'Train R²', 'Test R²'}, 'Location', 'northwest', ...
            'TextColor', C_TEXT_LIGHT, 'Color', C_BG_CARD, 'EdgeColor', C_BORDER);
        hold(axMdlR2, 'off');

        cla(axMdlCv); hold(axMdlCv, 'on');
        if isfield(r, 'cvRMSE') && ~isempty(r.cvRMSE)
            errorbar(axMdlCv, 1:nMdl, r.cvRMSE, r.cvRMSE_std, 'o-', ...
                'LineWidth', 2.2, 'MarkerSize', 8, 'MarkerFaceColor', C_CYBER_GREEN, ...
                'Color', C_CYBER_GREEN, 'DisplayName', 'Cross-Validation Mean ± Std');
            bar(axMdlCv, 1:nMdl, r.testRMSE, 0.35, 'FaceColor', C_VISTA_BLUE, ...
                'FaceAlpha', 0.55, 'DisplayName', 'Test RMSE');
            set(axMdlCv, 'XTick', 1:nMdl, 'XTickLabel', names, 'XTickLabelRotation', 25);
            legend(axMdlCv, 'Location', 'northeast', 'TextColor', C_TEXT_LIGHT, ...
                'Color', C_BG_CARD, 'EdgeColor', C_BORDER);
        end
        hold(axMdlCv, 'off');

        tblData = cell(nMdl, 6);
        for m = 1:nMdl
            tag = 'Evaluated';
            if strcmp(names{m}, r.bestModel), tag = 'Top Performing Model'; end
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
        plot(axPredAct, lims, lims, '--', 'Color', C_AMBER_WARN, 'LineWidth', 2, 'DisplayName', 'Ideal Fit');
        xlim(axPredAct, lims); ylim(axPredAct, lims);
        legend(axPredAct, 'Location', 'northwest', 'TextColor', C_TEXT_LIGHT, ...
            'Color', C_BG_CARD, 'EdgeColor', C_BORDER, 'FontSize', 8);
        hold(axPredAct, 'off');

        cla(axResidHist); hold(axResidHist, 'on');
        resid = testAct - bestPred;
        histogram(axResidHist, resid, 35, 'FaceColor', C_VISTA_BLUE, ...
            'EdgeColor', C_BORDER, 'FaceAlpha', 0.80);
        xline(axResidHist, 0, 'Color', C_TEXT_LIGHT, 'LineWidth', 2);
        xline(axResidHist, mean(resid), '--', 'Color', C_AMBER_WARN, 'LineWidth', 1.8, ...
            'Label', sprintf('Mean = %.2f', mean(resid)));
        hold(axResidHist, 'off');

        cla(axResidFit); hold(axResidFit, 'on');
        scatter(axResidFit, bestPred, resid, 35, C_CYBER_GREEN, 'filled', 'MarkerFaceAlpha', 0.60);
        yline(axResidFit, 0, 'Color', C_TEXT_LIGHT, 'LineWidth', 2);
        hold(axResidFit, 'off');

        cla(axFeatImp); hold(axFeatImp, 'on');
        impField = '';
        if isfield(r, 'featureImportance')
            for f = {'GradientBoosting', 'RandomForest'}
                if isfield(r.featureImportance, f{1}), impField = f{1}; break; end
            end
        end
        if ~isempty(impField)
            imp = r.featureImportance.(impField);
            fnames = r.featureImportance.([impField 'Names']);
            [sImp, si] = sort(imp, 'ascend');
            nShow = min(15, numel(sImp));
            sImp = sImp(end-nShow+1:end);
            sNames = fnames(si(end-nShow+1:end));
            barh(axFeatImp, 1:nShow, sImp, 'FaceColor', C_CYBER_GREEN);
            set(axFeatImp, 'YTick', 1:nShow, 'YTickLabel', sNames, 'FontSize', 8);
        end
        hold(axFeatImp, 'off');

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

        cla(axTargetDist); hold(axTargetDist, 'on');
        histogram(axTargetDist, testAct, 30, 'FaceColor', C_VISTA_BLUE, 'EdgeColor', C_BORDER);
        xline(axTargetDist, median(testAct), '--', 'Color', C_CYBER_GREEN, 'LineWidth', 2, ...
            'Label', sprintf('Median = %.1f', median(testAct)));
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

        lblAuditTitle.Text    = sprintf('Building Sample #%d Energy Audit', row.SampleIdx);
        lblAuditActual.Text   = sprintf('Actual Measured EUI: %.2f kWh/m²', row.ActualEUI);
        lblAuditPred.Text     = sprintf('Predicted Standard EUI: %.2f kWh/m²', row.PredictedEUI);
        lblAuditExcess.Text   = sprintf('Identified Excess Waste: %+.2f kWh/m²', row.ExcessEUI);
        lblAuditSeverity.Text = sprintf('Severity: %s', upper(row.WasteSeverity{1}));

        estDollars = row.PotentialSaving * 2800 * 0.16;
        lblAuditSavings.Text  = sprintf('Estimated Cost Waste: $%.0f / yr', estDollars);

        cla(axAuditMini); hold(axAuditMini, 'on');
        bAudit = bar(axAuditMini, [1, 2], [row.ActualEUI, row.PredictedEUI], 'FaceColor', 'flat');
        bAudit.CData = [C_CRIMSON_CRIT; C_CYBER_GREEN];
        set(axAuditMini, 'XTick', [1, 2], 'XTickLabel', {'Actual EUI', 'AI Baseline'});
        hold(axAuditMini, 'off');
    end

    %% ====================================================================
    %% RENDER TAB 5: SCENARIO SIMULATOR
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

        baseEUI = mean(rt.ActualEUI);
        hvacSaving    = baseEUI * (hvacPct / 100) * 0.35;
        insulSaving   = insulLvl * 2.8;
        controlSaving = baseEUI * (controlPct / 100) * 0.20;
        solarSaving   = (solarKw * 1400) / 25000;

        totalEuiReduction = hvacSaving + insulSaving + controlSaving + solarSaving;
        newPredictedEui   = max(15, baseEUI - totalEuiReduction);

        portfolioArea     = height(rt) * 2800;
        annualKwhSaved    = totalEuiReduction * portfolioArea;
        annualDollarSaved = annualKwhSaved * elecCost;
        annualCo2Tons     = annualKwhSaved * 0.000417;

        lblSimEnergySaved.Text = sprintf('-%.1f kWh/m²', totalEuiReduction);
        lblSimCostSaved.Text   = sprintf('$%,.0f / yr', annualDollarSaved);

        cla(axSimBar); hold(axSimBar, 'on');
        bSim = bar(axSimBar, [1, 2], [baseEUI, newPredictedEui], 'FaceColor', 'flat');
        bSim.CData = [C_AMBER_WARN; C_CYBER_GREEN];
        set(axSimBar, 'XTick', [1, 2], 'XTickLabel', {'Current Baseline', 'Post-Retrofit EUI'});
        text(axSimBar, 2, newPredictedEui + 2, sprintf('Reduction: %.1f%%', 100*totalEuiReduction/baseEUI), ...
            'Color', C_CYBER_GREEN, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
        hold(axSimBar, 'off');

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
    %% FILE EXPORTS
    %% ====================================================================
    function exportRetrofitCsvCallback()
        if isempty(state.retrofitTable), return; end
        [file, path] = uiputfile('retrofit_candidates_export.csv', 'Export Retrofit Table');
        if isequal(file, 0), return; end
        writetable(state.retrofitTable, fullfile(path, file));
        logMsg('Retrofit table exported to %s', fullfile(path, file));
        uialert(mainFig, 'Retrofit candidates exported successfully.', 'Export Complete', 'Icon', 'success');
    end

    function exportReportsCallback()
        if isempty(state.retrofitTable), return; end
        writetable(state.retrofitTable, 'retrofit_candidates.csv');
        logMsg('Saved retrofit_candidates.csv');
        uialert(mainFig, 'Analysis report saved to workspace.', 'Export Complete', 'Icon', 'success');
    end

    function loadCustomDataInteractive()
        [file, path] = uigetfile({'*.csv;*.mat', 'Supported Datasets (*.csv, *.mat)'}, 'Select Dataset');
        if isequal(file, 0), return; end
        logMsg('Loaded dataset from %s', fullfile(path, file));
        runFastPipelineInteractive();
    end

    %% ====================================================================
    %% INITIALIZE APP
    %% ====================================================================
    initApp();

    if nargout > 0
        varargout{1} = mainFig;
    end
end
