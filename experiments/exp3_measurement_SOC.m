% Evaluates performance when there exists a mismatch between training & testing SOC
% Corresponds to Fig. 7


clear
clc
close all

addpath(cd)
addpath("..\functions")
addpath("..\models")
addpath("..\figures")


dataset = "Mohtat"; 

%% Training
try
    switch info.dataset
        case "Chan"
            load("models_Chan_leave1out.mat");
        case "Mohtat"
            load("models_Mohtat_leave1out.mat");
    end

catch
   
    % Train/test split
    data_train = cell(height(cells), height(SOCs)); 
    data_test = cell(height(cells), height(SOCs)); 
    
    for i = 1:height(cells)
    
        data_train_i = data(data.cellnum ~= cells(i), :); % n-1 cells
        data_test_i = data(data.cellnum == cells(i), :); % 1 cell
    
        for j = 1:height(SOCs)
            data_train{i, j} = data_train_i(data_train_i.SOC == SOCs(j), :); 
            data_test{i, j} = data_test_i(data_test_i.SOC == SOCs(j), :); 
        end
    end
    
    % Model training
    modelstrs = ["linear", "GPR_UKF", "FNN_UKF"];
    
    for k = 1:length(modelstrs)
    
        tic
    
        info.modelstr = modelstrs(k); 
    
        state_model = cell(height(cells), 1); 
        meas_model = cell(height(cells), height(SOCs)); 
    
        for i = 1:height(cells)
    
            state_model{i} = model_training(info, data_train{i, 1}, "state"); % state model
    
            if info.modelstr == "linear"
                for j = 1:height(SOCs)
                    meas_model{i, j} = model_training(info, data_train{i, j}, "meas"); % meas model
                end
            else
                parfor j = 1:height(SOCs)
                    meas_model{i, j} = model_training(info, data_train{i, j}, "meas"); % meas model
                end
            end
        end
    
        info.data.test = data_test; 
        info.model(k).state = state_model; 
        info.model(k).meas = meas_model; 
    
        toc
    end
    
    name_txt = "..\models\models_" + info.dataset + "_leave1out.mat";
    save(name_txt, "cells", "info", "modelstrs", "SOCs")

end

clearvars -except info cells SOCs modelstrs dataset

%% Testing

clearvars -except info cells SOCs modelstrs dataset

try
    switch dataset
        case "Chan"
            load("results_Chan_SOCmismatch.mat");
        case "Mohtat"
            load("results_Mohtat_SOCmismatch.mat");
    end

catch

    info.filter_params = "optimized";
    info_OL = info;
    info_OL.val_type = "openloop";
    info_OL.data = [];
    info_OL.model = [];
    info_UKF = info;
    info_UKF.val_type = "UKF";
    info_UKF.data = [];
    info_UKF.model = [];
    
    
    for m = 1:length(modelstrs)
    
        tic 
    
        info_OL.modelstr = modelstrs(m);  % model structure
        info_UKF.modelstr = modelstrs(m);  % model structure
    
        for i = 1:height(cells)
    
            for j = 1:height(SOCs) % training SOC
    
                for k = 1:height(SOCs) % testing SOC
    
                    resultsUKF(i, j, k, m) = state_estimation(...
                            info = info_UKF,...
                            model_state = info.model(m).state{i}, ... % model on cell i
                            model_meas = info.model(m).meas{i, j}, ... % model on SOC j
                            data = info.data.test{i, k},... % test on SOC k
                            SOC = SOCs(j));
                    rmse_UKF(i, j, k, m) = resultsUKF(i, j, k, m).rmse;
    
                end
            end
    
        end
    
        toc
    
    end
    
    name_txt = "..\models\results_" + info.dataset + "_SOCmismatch.mat";
    save(name_txt, "cells", "modelstrs", "resultsUKF", "rmse_UKF", "SOCs")

end

clearvars -except info cells SOCs modelstrs resultsUKF rmse_UKF

%% plot results
% Fig. 7

export = 0; 

err = round(squeeze(mean(rmse_UKF, 1)), 1); 

for i = 1:length(modelstrs)

    name_txt = "exp3 - SOC mismatch - " + info.dataset + " - "  + modelstrs(i); 
    figure("Name",  name_txt); 


    hm = heatmap(SOCs, SOCs, err(:,:, i), ...
        'Colormap', parula , ...
        'ColorLimits',[1.5, 3.5]);


    xlabel("Training SOC [%]")
    ylabel("Testing SOC [%]")
    set(gcf, 'Units', 'normalized', 'Position', [0.1, 0.1, 0.4, 0.4]); % [left, bottom, width, height]
    if export
        exportgraphics(gcf, info.figures.folder + name_txt + ".png", 'Resolution',300)
        % savefig(gcf, info.figures.folder + name_txt + ".fig")
    end

end

