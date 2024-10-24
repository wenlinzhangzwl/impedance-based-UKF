% Evaluates the state & measurement models
% Corresponds to Fig. 4 & 5


clear
clc
close all


addpath(cd)
addpath("..\functions")
addpath("..\models")
addpath("..\figures")
addpath("..\data")

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
    
    name_txt = "..\models\models_" + info.dataset + "_leave1out.mat";
    save(name_txt, "cells", "info", "modelstrs", "SOCs")

end

clearvars -except info cells SOCs modelstrs



%% Open-loop state model accuracy
clearvars -except info cells SOCs modelstrs

try
    switch info.dataset
        case "Chan"
            load("results_Chan_state_model_OL.mat");
        case "Mohtat"
            load("results_Mohtat_state_model_OL.mat");
    end

catch
    
    info.filter_params = "optimized";
    info.val_type = "openloop";
    
    for k = 1:length(modelstrs)
    
        info.modelstr = modelstrs(k);  % model structure
    
        for i = 1:height(cells)
    
            data_test = info.data.test{i, 1}; 
            for j = 2:length(SOCs)
                data_test = [data_test; info.data.test{i, j}];
            end
            [~, ind, ~] = unique(data_test.SOH); 
            data_test = data_test(ind, :);
    
            resultsOL(k, i) = state_estimation(...
                    info = info,...
                    model_state = info.model(k).state{i}, ...
                    model_meas = [], ...
                    data = data_test,...
                    SOC = SOCs(j));
            rmseOL(k, i) = resultsOL(k, i).rmse;
    
    
        end
    
    end
    
    name_txt = "..\models\results_" + info.dataset + "_state_model_OL.mat";
    save(name_txt, "cells", "SOCs", "modelstrs", "resultsOL", "rmseOL")
    
end

clearvars -except info cells SOCs modelstrs resultsOL rmseOL


%% Plot state model accuracy
% Fig. 4a & 4b

clearvars -except info cells SOCs modelstrs resultsOL rmseOL

export = 0; 

% Combine everything into a matrix for plotting
for k = 1:length(modelstrs)

    SOH_est_k = []; 
    SOH_ref_k = [];

    for i = 1:height(cells)
        SOH_est_k = [SOH_est_k; resultsOL(k, i).SOH_est];
        SOH_ref_k = [SOH_ref_k; resultsOL(k, i).SOH_ref];
    end
    
    SOH_est(:, k) = SOH_est_k; 
    SOH_ref(:, k) = SOH_ref_k; 
end


% plot state model open-loop accuracy
name_txt = "exp1 - modelling accuracy - state - all cells - " + info.dataset; 
figure('Name', name_txt)
hold on
for j = 1:length(modelstrs)
    plot(SOH_est(:, j), SOH_ref(:, j), '.')
end
plot([80:0.1:100], [80:0.1:100], '-', Color=[0, 0, 0])
legend_txt = ["PR"; "GPR"; "FNN"] + ": " + string(round(mean(rmseOL, 2), 2)) + "%";
legend(legend_txt, Location="northwest")
grid on
xlabel("Estimated SOH [%]")
ylabel("Reference SOH [%]")
set(gcf, 'Units', 'normalized', 'Position', [0.025, 0.3, 0.3, 0.4]); % [left, bottom, width, height]
if export
    exportgraphics(gcf, info.figures.folder + name_txt + ".png", 'Resolution',300)
end

%% Measurement model accuracy

clc

clearvars -except info cells SOCs modelstrs

% determine range of HI @ each SOC for normalization
for i = 1:height(SOCs)

    data_SOC = info.data.test{1, i};
    for j = 2:height(info.data.test)
        data_SOC = [data_SOC; info.data.test{j, i}];
    end

    HI_range(i) = max(data_SOC.HI) - min(data_SOC.HI);
end


info.HI_SOC = 80; % example SOC

for k = 1:length(modelstrs)

    info.modelstr = modelstrs(k);  % model structure
    meas_pred_k = []; 
    meas_ref_k = [];

    for i = 1:height(cells)

        for j = 1:height(SOCs)

            [meas_err(k, i, j), meas_pred_j, meas_ref_j] = model_validation( ...
                info, ...
                info.model(k).meas{i, j}, ...
                info.data.test{i, j}, ...
                "meas");  

            meas_nom_err(k, i, j) = meas_err(k, i, j)  / HI_range(j);

            if SOCs(j) == info.HI_SOC
                meas_pred_k = [meas_pred_k; meas_pred_j];
                meas_ref_k = [meas_ref_k; meas_ref_j];
            end
        end
    end

    meas_pred(:, k) = meas_pred_k; 
    meas_ref(:, k) = meas_ref_k; 

end


clearvars -except info cells SOCs modelstrs meas_err meas_nom_err meas_pred meas_ref


%% Plot measurement model accuracy
% Fig. 4c, 4d, 5

clearvars -except info cells SOCs modelstrs meas_err meas_nom_err meas_pred meas_ref

export = 0; 

% plot meas model accuracy @ 80% SOC
maxHI = max([meas_pred; meas_ref], [], "all");
minHI = min([meas_pred; meas_ref], [], "all");

name_txt = "exp1 - modelling accuracy - meas - " + info.dataset + " - SOC" + string(info.HI_SOC); 
figure('Name', name_txt)
hold on
for j = 1:length(modelstrs)
    plot(meas_pred(:, j), meas_ref(:, j), '.')
end
plot([minHI:0.01:maxHI], [minHI:0.01:maxHI], '-', Color=[0, 0, 0])
xlim([min(meas_pred, [], "all"), max(meas_pred, [], "all")])
ylim([min(meas_ref, [], "all"), max(meas_ref, [], "all")])
legend_txt = ["PR"; "GPR"; "FNN"] + ": " + string(round(mean(meas_err(:, :, SOCs == info.HI_SOC), 2), 2));
legend(legend_txt, Location="southeast")
grid on
xlabel("Estimated HI")
ylabel("Reference HI")
set(gcf, 'Units', 'normalized', 'Position', [0.025, 0.3, 0.3, 0.4]); % [left, bottom, width, height]
if export
    exportgraphics(gcf, info.figures.folder + name_txt + ".png", 'Resolution',300)
end


% plot meas model error at all SOCs
% (figure not included in paper)
err = squeeze(mean(meas_nom_err, 2)); 
name_txt = "exp1 - modelling accuracy - meas - all cells - " + info.dataset; 
figure('Name', name_txt)
hold on
plot(SOCs, err(1, :), '-o')
plot(SOCs, err(2, :), '-square')
plot(SOCs, err(3, :), '-^')
grid on
xlabel("SOC [%]"); 
ylabel("nRMSE [-]")
legend_txt = ["PR", "GPR", "FNN"]; 
legend(legend_txt, Location="northeast")
xlim([10, 100])
ylim([0, 0.3])
set(gcf, 'Units', 'normalized', 'Position', [0.35, 0.3, 0.3, 0.4]); % [left, bottom, width, height]
if export
    exportgraphics(gcf, info.figures.folder + name_txt + ".png", 'Resolution',300)
end



%% Functions
function [xfill, yfill] = fill_min_to_max(x, y)

    xfill = [x, fliplr(x)];
    
    yfill = [mean(y) + std(y), mean(y) - std(y)];
    % yfill = max(yfill, 0); 

end
