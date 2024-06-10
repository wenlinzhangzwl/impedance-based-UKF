clear
clc
close all

addpath("functions")

%% Chan
info = set_info(...
    filter_params="optimized",...
    model_structure="linear",...
    dataset="Chan"); 

data = load_data("Chan", info, 0); 

cells = unique(data.cellnum); 
SOCs = unique(data.SOC);

for i = 1:height(cells)
    
    % train/test split
    data_train_i = data(data.cellnum ~= cells(i), :); 
    data_test_i = data(data.cellnum == cells(i), :); 

    % state model
    state_model_i = model_training(info, data_train_i, "state");
    state_err_i = model_validation(info, state_model_i, data_test_i, "state");

    for j = 1:height(SOCs)
        data_train_j = data_train_i(data_train_i.SOC == SOCs(j), :); 

        % meas model
        meas_model_j = model_training(info, data_train_j, "meas");

        for k = 1:height(SOCs)

            data_test_k = data_test_i(data_test_i.SOC == SOCs(k), :); 

            % test meas model
            meas_err_j = model_validation(info, meas_model_j, data_test_k, "meas");
            meas_err_j = meas_err_j / (max(data_test_k.HI) - min(data_test_k.HI));
    
            % modelling results
            model{i, j, k}.state = state_model_i; 
            model{i, j, k}.meas = meas_model_j; 
            error.state(i, j, k) = state_err_i; 
            error.meas(i, j, k) = meas_err_j; 
    
            info.SOC = SOCs(j);
    
            % validate - openloop
            info.val_type = "openloop";
            resultsOL{i, j, k} = state_estimation(info, model{i,j}, data_test_k); 
            error.OL(i, j, k) = resultsOL{i, j, k}.rmse;
            
            % validate - "UKF"
            info.val_type = "UKF";
            resultsUKF{i, j, k} = state_estimation(info, model{i,j}, data_test_k);
            error.UKF(i, j, k) = resultsUKF{i, j, k}.rmse;

        end

    end
end

info1.error = error; 
info1.SOCs = SOCs; 
info1.dataset = info.dataset; 

clearvars -except info info1

%% Mohtat
info = set_info(...
    filter_params="optimized",...
    model_structure="linear",...
    dataset="Mohtat"); 

data = load_data("Mohtat", info, 0); 

cells = unique(data.cellnum); 
SOCs = unique(data.SOC);

for i = 1:height(cells)

    % train/test split
    data_train_i = data(data.cellnum ~= cells(i), :); 
    data_test_i = data(data.cellnum == cells(i), :); 

    % state model
    state_model_i = model_training(info, data_train_i, "state");
    state_err_i = model_validation(info, state_model_i, data_test_i, "state");

    for j = 1:height(SOCs)
        data_train_j = data_train_i(data_train_i.SOC == SOCs(j), :); 

        % meas model
        meas_model_j = model_training(info, data_train_j, "meas");

        for k = 1:height(SOCs)

            data_test_k = data_test_i(data_test_i.SOC == SOCs(k), :); 

            % test meas model
            meas_err_j = model_validation(info, meas_model_j, data_test_k, "meas");
            meas_err_j = meas_err_j / (max(data_test_k.HI) - min(data_test_k.HI));

            % modelling results
            model{i, j, k}.state = state_model_i; 
            model{i, j, k}.meas = meas_model_j; 
            error.state(i, j, k) = state_err_i; 
            error.meas(i, j, k) = meas_err_j; 

            info.SOC = SOCs(j);

            % validate - openloop
            info.val_type = "openloop";
            resultsOL{i, j, k} = state_estimation(info, model{i,j}, data_test_k); 
            error.OL(i, j, k) = resultsOL{i, j, k}.rmse;

            % validate - "UKF"
            info.val_type = "UKF";
            resultsUKF{i, j, k} = state_estimation(info, model{i,j}, data_test_k);
            error.UKF(i, j, k) = resultsUKF{i, j, k}.rmse;

        end

    end
end

info2.error = error; 
info2.SOCs = SOCs; 
info2.dataset = info.dataset; 

clearvars -except info info1 info2
%% plot results

export = 0; 

% Estimator accuracy - Chan
err = round(squeeze(mean(info1.error.UKF, 1))', 1); 
name_txt = "exp2 - fig - Estimator accuracy - SOC" + " - Chan"; 
figure("Name",  name_txt); 
heatmap(info1.SOCs, info1.SOCs, err, 'Colormap', parula);
xlabel("Training SOC")
ylabel("Testing SOC")
set(gcf, 'Units', 'normalized', 'Position', [0.1, 0.1, 0.4, 0.4]); % [left, bottom, width, height]
if export
    exportgraphics(gcf, info.figures.folder + name_txt + ".png", 'Resolution',300)
    savefig(gcf, info.figures.folder + name_txt + ".fig")
end


%----------------------------------------------------------------------------------
% Estimator accuracy - Mohtat
err = round(squeeze(mean(info2.error.UKF, 1))', 1); 
name_txt = "exp2 - fig - Estimator accuracy - SOC" + " - Mohtat"; 
figure("Name",  name_txt); 
heatmap(info2.SOCs, info2.SOCs, err, 'Colormap', parula);
xlabel("Training SOC")
ylabel("Testing SOC")
set(gcf, 'Units', 'normalized', 'Position', [0.1, 0.1, 0.4, 0.4]); % [left, bottom, width, height]
if export
    exportgraphics(gcf, info.figures.folder + name_txt + ".png", 'Resolution',300)
    savefig(gcf, info.figures.folder + name_txt + ".fig")
end