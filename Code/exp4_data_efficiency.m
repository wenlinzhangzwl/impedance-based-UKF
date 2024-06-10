clear
clc
% close all

addpath("functions")

mincells = 2; 
maxcells = 10; 

name_txt = "exp4 - fig - Estimator accuracy - data efficiency"; 
figure("Name",  name_txt); 

for SOC_level = [20, 50, 80]


    %% Chan
    info = set_info(...
        filter_params="optimized",...
        model_structure="linear",...
        dataset="Chan"); 
    
    data = load_data("Chan", info, 0); 
    
    cells = unique(data.cellnum); 
    cells2 = [cells; cells];
    
    for i = 2:height(cells)-1 % using 1, 2, ..., N-1 cells for training

        for j = 1:height(cells) % sliding window N times

            cells_j = cells2(j:j+i-1);
        
            % train/test split
            data_train_j = data(ismember(data.cellnum, cells_j) & data.SOC == SOC_level, :); 
            data_test_j = data(~ismember(data.cellnum, cells_j) & data.SOC == SOC_level, :); 
        
            % state model
            state_model_j = model_training(info, data_train_j, "state");
            state_err_j = model_validation(info, state_model_j, data_test_j, "state");

            % meas model
            meas_model_j = model_training(info, data_train_j, "meas");
            meas_err_j = model_validation(info, meas_model_j, data_test_j, "meas");
            meas_err_j = meas_err_j / (max(data_test_j.HI) - min(data_test_j.HI));

            % modelling results
            model{i, j}.state = state_model_j; 
            model{i, j}.meas = meas_model_j; 
            error.state(i, j) = state_err_j; 
            error.meas(i, j) = meas_err_j; 

            info.SOC = SOC_level;

            % validate - openloop
            info.val_type = "openloop";
            resultsOL{i, j} = state_estimation(info, model{i, j}, data_test_j); 
            error.OL(i, j) = resultsOL{i, j}.rmse;

            % validate - "UKF"
            info.val_type = "UKF";
            resultsUKF{i, j} = state_estimation(info, model{i, j}, data_test_j);
            error.UKF(i, j) = resultsUKF{i, j}.rmse;
            
        end
    end
    
    error1.state = mean(error.state, 2);
    error1.meas = mean(error.meas, 2);
    error1.OL = mean(error.OL, 2);
    error1.UKF = mean(error.UKF, 2);
    error1.state_max = max(error.state, [], 2);
    error1.meas_max = max(error.meas, [], 2);
    error1.OL_max = max(error.OL, [], 2);
    error1.UKF_max = max(error.UKF, [], 2);
    error1.state_min = min(error.state, [], 2);
    error1.meas_min = min(error.meas, [], 2);
    error1.OL_min = min(error.OL, [], 2);
    error1.UKF_min = min(error.UKF, [], 2);
    
    clearvars -except SOC_level error1 name_txt mincells maxcells
    
    %% Mohtat
    info = set_info(...
        filter_params="optimized",...
        model_structure="linear",...
        dataset="Mohtat"); 
    
    data = load_data("Mohtat", info, 0); 
    
    cells = unique(data.cellnum); 
    cells2 = [cells; cells];
    
    for i = 1:height(cells)-1 % using 1, 2, ..., N-1 cells for training

        for j = 1:height(cells) % sliding window N times

            cells_j = cells2(j:j+i-1);
        
            % train/test split
            data_train_j = data(ismember(data.cellnum, cells_j) & data.SOC == SOC_level, :); 
            data_test_j = data(~ismember(data.cellnum, cells_j) & data.SOC == SOC_level, :); 
        
            % state model
            state_model_j = model_training(info, data_train_j, "state");
            state_err_j = model_validation(info, state_model_j, data_test_j, "state");

            % meas model
            meas_model_j = model_training(info, data_train_j, "meas");
            meas_err_j = model_validation(info, meas_model_j, data_test_j, "meas");
            meas_err_j = meas_err_j / (max(data_test_j.HI) - min(data_test_j.HI));

            % modelling results
            model{i, j}.state = state_model_j; 
            model{i, j}.meas = meas_model_j; 
            error.state(i, j) = state_err_j; 
            error.meas(i, j) = meas_err_j; 

            info.SOC = SOC_level;

            % validate - openloop
            info.val_type = "openloop";
            resultsOL{i, j} = state_estimation(info, model{i, j}, data_test_j); 
            error.OL(i, j) = resultsOL{i, j}.rmse;

            % validate - "UKF"
            info.val_type = "UKF";
            resultsUKF{i, j} = state_estimation(info, model{i, j}, data_test_j);
            error.UKF(i, j) = resultsUKF{i, j}.rmse;
            
        end
    end
    
    error2.state = mean(error.state, 2);
    error2.meas = mean(error.meas, 2);
    error2.OL = mean(error.OL, 2);
    error2.UKF = mean(error.UKF, 2);
    error2.state_max = max(error.state, [], 2);
    error2.meas_max = max(error.meas, [], 2);
    error2.OL_max = max(error.OL, [], 2);
    error2.UKF_max = max(error.UKF, [], 2);
    error2.state_min = min(error.state, [], 2);
    error2.meas_min = min(error.meas, [], 2);
    error2.OL_min = min(error.OL, [], 2);
    error2.UKF_min = min(error.UKF, [], 2);

    clearvars -except SOC_level error1 error2 name_txt info mincells maxcells

    %% Plot results


    if SOC_level == 20
        subplot(1, 3, 1)
    elseif SOC_level == 50
        subplot(1, 3, 2)
    elseif SOC_level == 80
        subplot(1, 3, 3)
    end

    hold on
    x1 = [mincells:length(error1.UKF), fliplr([mincells:length(error1.UKF)])]';
    y1 = [error1.UKF_max(mincells:end); fliplr(error1.UKF_min(mincells:end))];
    x2 = [mincells:length(error2.UKF), fliplr([mincells:length(error2.UKF)])]';
    y2 = [error2.UKF_max(mincells:end); fliplr(error2.UKF_min(mincells:end))];

    plot([mincells:length(error1.UKF)], error1.UKF(mincells:end), '.-')
    plot([mincells:length(error2.UKF)], error2.UKF(mincells:end), '.-')
    fill(x1, y1, [0 0.4470 0.7410], 'EdgeColor', 'none', 'FaceAlpha', 0.2)
    fill(x2, y2, [0.8500 0.3250 0.0980], 'EdgeColor', 'none', 'FaceAlpha', 0.2)

    grid on
    xlim([mincells, maxcells])
    ylim([0, 6.5])
    xlabel("# of training cells")
    ylabel("Error")
    title("SOC: " + string(SOC_level) + "%")
    legend(["dataset1", "dataset2"])
end

export =0; 
set(gcf, 'Units', 'normalized', 'Position', [0.1, 0.1, 0.5, 0.25]); % [left, bottom, width, height]
if export
    exportgraphics(gcf, info.figures.folder + name_txt + ".png", 'Resolution',300)
    savefig(gcf, info.figures.folder + name_txt + ".fig")
end