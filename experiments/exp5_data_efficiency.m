% Evaluates the data efficiency by gradually reducing the number of cells
% used in training
% Corresponds to Fig. 8


clear
clc
close all

addpath(cd)
addpath("..\functions")
addpath("..\models")
addpath("..\data")
addpath("..\figures")

dataset = "Mohtat";
modelstrs = ["linear", "GPR_UKF", "FNN_UKF"];
SOC_test = 80; 

info = set_info(...
    filter_params = "optimized", ...
    dataset = dataset, ...
    val_type = "UKF"); 
data = load_data(info.dataset, info, 0);

%% Train

try
    switch info.dataset
        case "Chan"
            load("models_Chan_data_efficiency_SOC80.mat")
        case "Mohtat"
            load("models_Mohtat_data_efficiency_SOC80.mat")
    end

catch
    
    cells = unique(data.cellnum); 
    cells2 = [cells; cells];
    ntrain = [2:15]; % # of cells used for training
    
    data_train = cell(length(modelstrs), length(ntrain), height(cells)); 
    data_test = cell(length(modelstrs), length(ntrain), height(cells)); 
    state_model = cell(length(modelstrs), length(ntrain), height(cells)); 
    meas_model = cell(length(modelstrs), length(ntrain), height(cells)); 
    
    
    for i = 1:length(modelstrs)
    
        tic
    
        info.modelstr = modelstrs(i); 
    
        for j = 1:length(ntrain)
    
            n = ntrain(j); % # of cells used for training 
    
            if info.modelstr == "linear"
    
                for k = 1:height(cells)  % sliding window of size j, N times
    
                    cells_j = cells2(k:k+n-1); % cells for training
    
                    % train/test split
                    data_train{i, j, k} = data(ismember(data.cellnum, cells_j) & data.SOC == SOC_test, :); 
                    data_test{i, j, k} = data(~ismember(data.cellnum, cells_j) & data.SOC == SOC_test, :); 
    
                    % state & meas models
                    state_model{i, j, k} = model_training(info, data_train{i, j, k}, "state");
                    meas_model{i, j, k} = model_training(info, data_train{i, j, k}, "meas");
    
                end
    
            else
    
                parfor k = 1:height(cells)  % sliding window of size j, N times
    
                    cells_j = cells2(k:k+n-1); % cells for training
    
                    % train/test split
                    data_train{i, j, k} = data(ismember(data.cellnum, cells_j) & data.SOC == SOC_test, :); 
                    data_test{i, j, k} = data(~ismember(data.cellnum, cells_j) & data.SOC == SOC_test, :); 
    
                    % state & meas models
                    state_model{i, j, k} = model_training(info, data_train{i, j, k}, "state");
                    meas_model{i, j, k} = model_training(info, data_train{i, j, k}, "meas");
                end
    
            end
        end
    
        toc
    end
    
    model.state = state_model; 
    model.meas = meas_model; 
    
    name_txt = info.models_folder + "models_" + info.dataset + "_data_efficiency_SOC" + string(SOC_test) + ".mat";
    save(name_txt, "SOC_test", "cells", "cells2", "data_test", "dataset", "info", "model", "modelstrs", "ntrain")

end

clearvars -except dataset modelstrs SOC_test info ...
    cells cells2 ntrain data_test model


%% Test

try
    switch info.dataset
        case "Chan"
            load("results_Chan_data_efficiency_SOC80.mat")
        case "Mohtat"
            load("results_Mohtat_data_efficiency_SOC80.mat")
    end

catch

    resultsUKF = cell(length(modelstrs), length(ntrain), height(cells)); 
    err = zeros(length(modelstrs), length(ntrain), height(cells)); 
    
    for i = 1:length(modelstrs)
    
        tic
    
        info.modelstr = modelstrs(i); 
    
        for j = 1:length(ntrain)
    
            n = ntrain(j); % # of cells used for training 
    
            parfor k = 1:height(cells)  % sliding window of size j, N times
            % If out of memory, clear all other processes. Need about 21G
    
                cells_j = cells2(k:k+n-1); % cells for training
    
                resultsUKF{i, j, k} = state_estimation( ...
                    info = info, ...
                    model_state = model.state{i, j, k}, ...
                    model_meas = model.meas{i, j, k}, ...
                    SOC = SOC_test, ...
                    data = data_test{i, j, k}); 
                err(i, j, k) = resultsUKF{i, j, k}.rmse;
    
            end
        end
    
        toc
    end
    
    name_txt = info.models_folder + "results_" + info.dataset + "_data_efficiency_SOC" + string(SOC_test) + ".mat";
    save(name_txt, "SOC_test", "err", "modelstrs", "ntrain", "resultsUKF")

end

clearvars -except modelstrs SOC_test info ...
    ntrain data_test model ...
    resultsUKF err


%% Plot

export = 0; 

name_txt = "exp5 - data efficiency - " + info.dataset; 
figure("Name",  name_txt); 
hold on

colours = {[0 0.4470 0.7410], [0.8500 0.3250 0.0980], [0.9290 0.6940 0.1250]};
markers = ["o", "square", "^"];
for i = 1:length(modelstrs)
    err_i = squeeze(err(i, :, :)); 

    err_mean = mean(err_i, 2); 
    plot(ntrain, err_mean, markers(i), Color=colours{i})

end

% plot standard deviation
for i = 1:length(modelstrs)
    err_i = squeeze(err(i, :, :)); 

    [x, y] = plot_margins(ntrain, err_i');
    fill(x, y, colours{i}, 'EdgeColor', 'none', 'FaceAlpha', 0.2)
end

grid on
xlim([2, 12])
ylim([0.5, 4.5])
xlabel("# of training cells")
ylabel("RMSE [%SOH]")
legend(["PR", "GPR", "FNN"])

set(gcf, 'Units', 'normalized', 'Position', [0.1, 0.1, 0.3, 0.35]); % [left, bottom, width, height]
if export
    exportgraphics(gcf, info.figures.folder + name_txt + ".png", 'Resolution',300)
    % savefig(gcf, info.figures.folder + name_txt + ".fig")
end