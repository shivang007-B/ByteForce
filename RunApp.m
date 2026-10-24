%% RunApp.m
% Launcher for the GIGAWATT Building Energy Intelligence Platform.
% Conforms to the GIGAWATT Frontend & Backend Integration Guide.
%
% Usage:
%   >> RunApp
%   >> Gigawatt

clc;
fprintf('=========================================================\n');
fprintf('  GIGAWATT | Building Energy Intelligence & Retrofit Screening\n');
fprintf('  Launching App...\n');
fprintf('=========================================================\n\n');

% Ensure path is added
currDir = fileparts(mfilename('fullpath'));
if isempty(currDir), currDir = pwd; end
addpath(currDir);

% Launch Gigawatt App
app = Gigawatt();
fprintf('GIGAWATT App successfully launched.\n');
