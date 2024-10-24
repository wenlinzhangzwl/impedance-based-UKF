% Evaluates performance when there exists a mismatch between cell chemistries. 
% Corresponds to Table 4

clear
clc
close all

addpath(cd)
addpath("..\functions")
addpath("..\models")


% dataset_train = "Chan";
% dataset_test = "Mohtat";

dataset_train = "Mohtat";
dataset_test = "Chan";

modelstrs = ["linear", "GPR_UKF", "FNN_UKF"];
SOC_test = [20, 50, 80];

%% Train
info = set_info(dataset = dataset_train, filter_params = "optimized"); 
data = load_data(info.dataset, info, 0);


state_model = cell(length(modelstrs), 1); 
meas_model = cell(length(modelstrs), length(SOC_test)); 

for i = 1:length(modelstrs)

    tic

    info.modelstr = modelstrs(i); 
    
    state_model{i} = model_training(info, data, "state"); % train state model w/ all data

    for j = 1:length(SOC_test)
        meas_model{i, j} = model_training(info, data(data.SOC == SOC_test(j), :), "meas"); % train meas model @ each SOC
    end

    toc
end

model.state = state_model; 
model.meas = meas_model; 

clearvars -except dataset_train dataset_test modelstrs SOC_test model

%% Test

info = set_info( ...
    dataset = dataset_test, ...
    val_type = "UKF", ...
    filter_params = "optimized");
data = load_data(info.dataset, info, 0);
cells = unique(data.cellnum); 


for i = 1:length(modelstrs)

    info.modelstr = modelstrs(i); 

    for j = 1:length(SOC_test)
        
        resultsUKF(i, j) = state_estimation(...
            info = info,...
            model_state = model.state{i}, ...
            model_meas = model.meas{i, j}, ...
            data = data(data.SOC == SOC_test(j), :), ...
            SOC = SOC_test(j));
        rmse_UKF(i, j) = resultsUKF(i, j).rmse;

    end

end

clearvars -except dataset_train dataset_test modelstrs SOC_test model resultsUKF rmse_UKF


for i = 1:length(modelstrs)
    for j = 1:length(SOC_test)
        disp(modelstrs(i) + ", " + string(SOC_test(j)) + "% SOC: " + rmse_UKF(i, j))
    end
end

