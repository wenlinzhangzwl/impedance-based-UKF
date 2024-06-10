clear
clc
close all

addpath("functions")

info1 = set_info(filter_params="optimized", model_structure="linear", dataset="Chan"); 
data1 = load_data("Chan", info1, 0); 
cells1 = unique(data1.cellnum); 
SOCs1 = unique(data1.SOC);

info2 = info1; 
info2.dataset="Mohtat"; 
data2 = load_data("Mohtat", info2, 0); 
cells2 = unique(data2.cellnum); 
SOCs2 = unique(data2.SOC);

name_txt = "exp3 - fig - Estimator accuracy - chemistry"; 
figure("Name",  name_txt); 

for SOC_level = [20, 50, 80]

    clearvars -except info1 data1 cells1 SOCs1 info2 data2 cells2 SOCs2 SOC_level name_txt
    
    %% Train on dataset1 (Chan), test on dataset2 (Mohtat)
    
    info = info1; 
    info.SOC = SOC_level;
    
    % train/test split
    data_train = data1(data1.SOC == SOC_level, :);
    data_test = data2(data2.SOC == SOC_level, :);
    % if info.modelstr == "linear"
    %     data_test.EFC = log(data_test.EFC); 
    % end
    
    % state model
    state_model = model_training(info, data_train, "state");
    state_err = model_validation(info, state_model, data_test, "state");
    
    % meas model
    meas_model = model_training(info, data_train, "meas");
    meas_err = model_validation(info, meas_model, data_test, "meas");
    meas_err = meas_err / (max(data_test.HI) - min(data_test.HI));
    
    % modelling results
    model.state = state_model; 
    model.meas = meas_model; 
    error.state = state_err; 
    error.meas = meas_err; 
    
    % validate - openloop
    info.val_type = "openloop";
    resultsOL = state_estimation(info, model, data_test); 
    error.OL = resultsOL.rmse;
    
    % validate - "UKF"
    info.val_type = "UKF";
    resultsUKF = state_estimation(info, model, data_test);
    error.UKF = resultsUKF.rmse;
    
    error1 = error; 
    
    %% Train on dataset2 (Mohtat), test on dataset1 (Chan)
    
    info = info2; 
    info.SOC = SOC_level;
    
    % train/test split
    data_train = data2(data2.SOC == SOC_level, :);
    data_test = data1(data1.SOC == SOC_level, :);
    
    % state model
    state_model = model_training(info, data_train, "state");
    state_err = model_validation(info, state_model, data_test, "state");
    
    % meas model
    meas_model = model_training(info, data_train, "meas");
    meas_err = model_validation(info, meas_model, data_test, "meas");
    meas_err = meas_err / (max(data_test.HI) - min(data_test.HI));
    
    % modelling results
    model.state = state_model; 
    model.meas = meas_model; 
    error.state = state_err; 
    error.meas = meas_err; 
    
    % validate - openloop
    info.val_type = "openloop";
    resultsOL = state_estimation(info, model, data_test); 
    error.OL = resultsOL.rmse;
    
    % validate - "UKF"
    info.val_type = "UKF";
    resultsUKF = state_estimation(info, model, data_test);
    error.UKF = resultsUKF.rmse;
    
    error2 = error; 
    
    %% Plot results
    
    err_20 = [1.84771, 1.92656]; % Chan, Mohtat
    err_50 = [1.77609, 1.82137];
    err_80 = [1.64015, 1.83743];
    
    if SOC_level == 20
        err = [err_20(1), error2.UKF;...
               error1.UKF, err_20(2)];
        subplot(1, 3, 1)
    elseif SOC_level == 50
        err = [err_50(1), error2.UKF;...
               error1.UKF, err_50(2)];
        subplot(1, 3, 2)
    elseif SOC_level == 80
        err = [err_80(1), error2.UKF;...
               error1.UKF, err_80(2)];
        subplot(1, 3, 3)
    end
    err = round(err, 1); 
    
    heatmap([1, 2], [1, 2], err)
    xlabel("Training dataset")
    ylabel("Testing dataset")
    title("SOC: " + string(SOC_level) + "%")

end

export = 0; 
set(gcf, 'Units', 'normalized', 'Position', [0.1, 0.1, 0.4, 0.2]); % [left, bottom, width, height]
if export
    exportgraphics(gcf, info.figures.folder + name_txt + ".png", 'Resolution',300)
    savefig(gcf, info.figures.folder + name_txt + ".fig")
end