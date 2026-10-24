%% RunApp.m
% One-click launcher for the BYTEFORCE Building Energy Intelligence App.
% Run this in MATLAB:
%   >> RunApp
%
% Features:
%   - Checks environment and toolboxes
%   - Adds current path
%   - Launches EnergyConsumptionApp UI

clc;
fprintf('=========================================================\n');
fprintf('  BYTEFORCE // Building Energy Intelligence & Retrofit AI\n');
fprintf('  Launching Cyber-Themed Frontend Command Center...\n');
fprintf('=========================================================\n\n');

% Add path
currDir = fileparts(mfilename('fullpath'));
if isempty(currDir), currDir = pwd; end
addpath(currDir);

% Launch App
app = EnergyConsumptionApp();
fprintf('App successfully launched! Enjoy exploring all maps & models.\n');
