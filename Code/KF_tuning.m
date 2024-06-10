% This script is used to tune the filter parameters for main.m
% The first half of the script is identical to main.m
% The second half is modified to allow tuning

clear
clc

addpath("functions")

% settings
info.plot_figures = 3; % 0 = none, 1 = all, 2 = results, 3 = for paper
info.filter_params = "initial"; % "initial", "optimized"
info.modelstr = "linear"; % linear, GPR_UKF, GPR
info.dataset = "Chan"; % Mohtat, Chan
info.val_type = "UKF";

% load data
switch info.dataset
    case "Mohtat"
        load("C:\Users\wenli\OneDrive\SCHOOL\02 - Projects\7 - Experimental Data\Online datasets\Mohtat2021\data_all.mat");
        data(data.SOC == 0, :) = [];
    case "Chan"
        load("C:\Users\wenli\OneDrive\SCHOOL\02 - Projects\7 - Experimental Data\Online datasets\Chan2022\all_data.mat");
        data(data.SOC == 25, :) = [];
end

data = data(data.SOH >= 80, :); % cut to 80% SOH

% randomly divide into subsets
cells = unique(data.cellnum); 
perm = randperm(height(cells));
ncell = floor(height(cells)/4); 
groups{1} = cells(perm(1:ncell)); 
groups{2} = cells(perm(ncell+1:2*ncell)); 
groups{3} = cells(perm(2*ncell+1:3*ncell)); 
groups{4} = cells(perm(3*ncell+1:height(cells))); 
info.groups = groups'; 

%%
clc
clearvars -except info data

%---------------------------------------------------------
SOCs = unique(data.SOC);
par_optimized = [];

for i = 1:length(SOCs)

    info.SOC = SOCs(i);
    data_i = data(data.SOC == info.SOC, :); 

    % train model 
    model.state = model_training(info, data_i, "state");
    model.meas = model_training(info, data_i, "meas");

    % Define the objective function to minimize (PSO fitness function)
    fitnessFunc = @(param) objectiveFunction(param, info, data_i, model);

    
    lb = [0.1, 0.1, 0.1]; % Lower bounds
    ub = [10, 10, 10]; % Upper bounds
    nvars = 3;  % Number of variables

    options = optimoptions('ga', ...
                           'Display', 'diagnose',...
                           'UseParallel', true,...
                           'PlotFcns', {@gaplotbestf @gaplotbestindiv},...
                           'FunctionTolerance', 0.01, ...
                           'PopInitRange', [lb; ub],...
                           'PopulationSize', 20,... 
                           'Generations', 10,...
                           'InitialPopulation', [1, 1, 1]); %
    par_optimized = [par_optimized; ...
        ga(fitnessFunc, nvars, [], [], [], [], lb, ub, [], [], options)];

end

beep

% Define the objective function for PSO optimization
function cost = objectiveFunction(par, info, data, model)

    % % randomly select a group of cells from the 4
    % cells = info.groups{randi(4)}'; 
    
    cells = unique(data.cellnum); 

    rmse_i = []; 

    for i = 1:length(cells)
        data_test = data(ismember(data.cellnum, cells(i)), :); 
        result_i = state_estimation(info, model, data_test, par);
        rmse_i = [rmse_i; result_i.rmse]; 
    end

    cost = mean(rmse_i); 


end