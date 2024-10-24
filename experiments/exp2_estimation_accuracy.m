% Evaluates the overall estimation accuracy via leave-one-out validation
% Corresponds to Fig. 6


clear
clc
close all

addpath(cd)
addpath("..\functions")
addpath("..\models")
addpath("..\figures")


info = set_info(dataset="Mohtat"); 

data = load_data(info.dataset, info, 0); 

cells = unique(data.cellnum); 
SOCs = unique(data.SOC);


%% Training

clearvars -except info cells SOCs data

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

end

clearvars -except info cells SOCs modelstrs



%% Overall modelling error

clearvars -except info cells SOCs modelstrs

try
    switch info.dataset
        case "Chan"
            load("results_Chan_leave1out.mat");
        case "Mohtat"
            load("results_Mohtat_leave1out.mat");
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
    
    for k = 1:length(modelstrs)
    
        tic 
    
        info_OL.modelstr = modelstrs(k);  % model structure
        info_UKF.modelstr = modelstrs(k);  % model structure
    
        for i = 1:height(cells)
    
            for j = 1:height(SOCs)
    
                % open-loop
                resultsOL(i, j, k) = state_estimation(...
                        info = info_OL,...
                        model_state = info.model(k).state{i}, ...
                        model_meas = info.model(k).meas{i, j}, ...
                        data = info.data.test{i, j},...
                        SOC = SOCs(j));
                rmseOL(i, j, k) = resultsOL(i, j, k).rmse;
    
                % UKF
                resultsUKF(i, j, k) = state_estimation(...
                        info = info_UKF,...
                        model_state = info.model(k).state{i}, ...
                        model_meas = info.model(k).meas{i, j}, ...
                        data = info.data.test{i, j},...
                        SOC = SOCs(j));
                rmse_UKF(i, j, k) = resultsUKF(i, j, k).rmse;
    
            end
    
    
    
        end
    
        toc
    
    end
    
    name_txt = "..\models\results_" + info.dataset + "_leave1out.mat";
    save(name_txt, "cells", "resultsOL", "resultsUKF", "rmseOL", "rmse_UKF", "SOCs")

end

clearvars -except info cells SOCs modelstrs resultsOL rmseOL resultsUKF rmse_UKF


%% Plot overall modelling error 
% Fig.6

clearvars -except info cells SOCs modelstrs resultsOL rmseOL resultsUKF rmse_UKF

% use this if want std plotted. 
% ----------------------------------------
% [x, y1] = fill_min_to_max(SOCs', state.err(:, :, 1));
% [~, y2] = fill_min_to_max(SOCs', state.err(:, :, 2));
% [~, y3] = fill_min_to_max(SOCs', state.err(:, :, 3));
% fill(x, y1, [0 0.4470 0.7410], 'EdgeColor', 'none', 'FaceAlpha', 0.2)
% fill(x, y2, [0.8500 0.3250 0.0980], 'EdgeColor', 'none', 'FaceAlpha', 0.2)
% fill(x, y3, [0.9290 0.6940 0.1250], 'EdgeColor', 'none', 'FaceAlpha', 0.2)
% ----------------------------------------

export = 0; 

err =  mean(rmse_UKF, 1); 
name_txt = "exp2 - estimation accuracy - all cells - "  + info.dataset; 
figure('Name', name_txt)
hold on
plot(SOCs, err(:, :, 1), '-o')
plot(SOCs, err(:, :, 2), '-square')
plot(SOCs, err(:, :, 3), '-^')
grid on
xlabel("SOC [%]"); 
ylabel("RMSE [%SOH]")
legend_txt = ["PR", "GPR", "FNN"]; 
legend(legend_txt, Location="northeast")
xlim([10, 100])
ylim([1, 3])
set(gcf, 'Units', 'normalized', 'Position', [0.35, 0.3, 0.3, 0.3]); % [left, bottom, width, height]
if export
    exportgraphics(gcf, info.figures.folder + name_txt + ".png", 'Resolution',300)
end



%% Functions
function [xfill, yfill] = fill_min_to_max(x, y)

    xfill = [x, fliplr(x)];
    
    yfill = [mean(y) + std(y), mean(y) - std(y)];
    % yfill = max(yfill, 0); 

end
