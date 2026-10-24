function varargout = EnergyConsumptionApp()
% EnergyConsumptionApp - Alias launcher for GIGAWATT Building Energy Platform.
% Redirects to Gigawatt.m conforming to the GIGAWATT integration guide.
%
% Usage:
%   >> EnergyConsumptionApp
%   >> Gigawatt

    currDir = fileparts(mfilename('fullpath'));
    if ~isempty(currDir), addpath(currDir); end

    app = Gigawatt();

    if nargout > 0
        varargout{1} = app;
    end
end
