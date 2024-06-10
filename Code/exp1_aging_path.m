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
        data_test_j = data_test_i(data_test_i.SOC == SOCs(j), :); 

        % meas model
        meas_model_j = model_training(info, data_train_j, "meas");
        meas_err_j = model_validation(info, meas_model_j, data_test_j, "meas");
        meas_err_j = meas_err_j / (max(data_test_j.HI) - min(data_test_j.HI));

        % modelling results
        model{i, j}.state = state_model_i; 
        model{i, j}.meas = meas_model_j; 
        error.state(i, j) = state_err_i; 
        error.meas(i, j) = meas_err_j; 

        info.SOC = SOCs(j);

        % validate - openloop
        info.val_type = "openloop";
        resultsOL{i, j} = state_estimation(info, model{i,j}, data_test_j); 
        error.OL(i, j) = resultsOL{i, j}.rmse;
        
        % validate - "UKF"
        info.val_type = "UKF";
        resultsUKF{i, j} = state_estimation(info, model{i,j}, data_test_j);
        error.UKF(i, j) = resultsUKF{i, j}.rmse;

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
        data_test_j = data_test_i(data_test_i.SOC == SOCs(j), :); 

        % meas model
        meas_model_j = model_training(info, data_train_j, "meas");
        meas_err_j = model_validation(info, meas_model_j, data_test_j, "meas");
        deltaHI = max(data_test_j.HI) - min(data_test_j.HI); 
        if deltaHI == 0
            deltaHI = abs(mean(data_test_j.HI));
        end
        meas_err_j = meas_err_j / deltaHI;

        % modelling results
        model{i, j}.state = state_model_i; 
        model{i, j}.meas = meas_model_j; 
        error.state(i, j) = state_err_i; 
        error.meas(i, j) = meas_err_j; 

        info.SOC = SOCs(j);

        % validate - openloop
        info.val_type = "openloop";
        resultsOL{i, j} = state_estimation(info, model{i,j}, data_test_j); 
        error.OL(i, j) = resultsOL{i, j}.rmse;
        
        % validate - "UKF"
        info.val_type = "UKF";
        resultsUKF{i, j} = state_estimation(info, model{i,j}, data_test_j);
        error.UKF(i, j) = resultsUKF{i, j}.rmse;

    end
end

info2.error = error; 
info2.SOCs = SOCs; 
info2.dataset = info.dataset; 

clearvars -except info info1 info2


%% plot results
export = 0; 

%----------------------------------------------------------------------------------
% Estimator accuracy
[x1, y1] = fill_min_to_max(info1.SOCs', info1.error.UKF);
[x2, y2] = fill_min_to_max(info2.SOCs', info2.error.UKF);

name_txt = "exp1 - fig - Estimator accuracy - aging path"; 
figure("Name",  name_txt); 
hold on; 
plot(info1.SOCs, mean(info1.error.UKF, 1), '.-')
plot(info2.SOCs, mean(info2.error.UKF, 1), '.-')
fill(x1, y1, [0 0.4470 0.7410], 'EdgeColor', 'none', 'FaceAlpha', 0.2)
fill(x2, y2, [0.8500 0.3250 0.0980], 'EdgeColor', 'none', 'FaceAlpha', 0.2)
grid on
xlim([10, 100])
ylim([0.5, 4.5])
set(gcf, 'Units', 'normalized', 'Position', [0.1, 0.1, 0.3, 0.3]); % [left, bottom, width, height]
ylabel("Error")
xlabel("SOC")
legend("dataset1", "dataset2", Location="northwest")

if export
    exportgraphics(gcf, info.figures.folder + name_txt + ".png", 'Resolution',300)
    savefig(gcf, info.figures.folder + name_txt + ".fig")
end

clearvars -except info info1 info2 export

%----------------------------------------------------------------------------------
% Open vs closed loop, Chan
[x1, y1] = fill_min_to_max(info1.SOCs', info1.error.OL);
[x2, y2] = fill_min_to_max(info1.SOCs', info1.error.UKF);

name_txt = "exp1- fig - Open vs closed loop" + " - Chan"; 
figure("Name",  name_txt); 
hold on; 
plot(info1.SOCs, mean(info1.error.OL, 1), '.-')
plot(info1.SOCs, mean(info1.error.UKF, 1), '.-')
fill(x1, y1, [0 0.4470 0.7410], 'EdgeColor', 'none', 'FaceAlpha', 0.2)
fill(x2, y2, [0.8500 0.3250 0.0980], 'EdgeColor', 'none', 'FaceAlpha', 0.2)
grid on
xlim([10, 100])
ylim([0.5, 4.5])
set(gcf, 'Units', 'normalized', 'Position', [0.1, 0.1, 0.3, 0.3]); % [left, bottom, width, height]
ylabel("Error")
xlabel("SOC")
legend("State model", "UKF", Location="northwest")

if export
    exportgraphics(gcf, info.figures.folder + name_txt + ".png", 'Resolution',300)
    savefig(gcf, info.figures.folder + name_txt + ".fig")
end

clearvars -except info info1 info2 export


%----------------------------------------------------------------------------------
% Open vs closed loop, Mohtat
[x1, y1] = fill_min_to_max(info2.SOCs', info2.error.OL);
[x2, y2] = fill_min_to_max(info2.SOCs', info2.error.UKF);

name_txt = "exp1- fig - Open vs closed loop" + " - Mohtat"; 
figure("Name",  name_txt); 
hold on; 
plot(info2.SOCs, mean(info2.error.OL, 1), '.-')
plot(info2.SOCs, mean(info2.error.UKF, 1), '.-')
fill(x1, y1, [0 0.4470 0.7410], 'EdgeColor', 'none', 'FaceAlpha', 0.2)
fill(x2, y2, [0.8500 0.3250 0.0980], 'EdgeColor', 'none', 'FaceAlpha', 0.2)
grid on
xlim([10, 100])
ylim([0.5, 4.5])
set(gcf, 'Units', 'normalized', 'Position', [0.1, 0.1, 0.3, 0.3]); % [left, bottom, width, height]
ylabel("Error")
xlabel("SOC")
legend("State model", "UKF", Location="northwest")

if export
    exportgraphics(gcf, info.figures.folder + name_txt + ".png", 'Resolution',300)
    savefig(gcf, info.figures.folder + name_txt + ".fig")
end

clearvars -except info info1 info2 export

%----------------------------------------------------------------------------------
% State model accuracy
state_err1 = mean(info1.error.state)
state_err2 = mean(info2.error.state)

clearvars -except info info1 info2 export

%----------------------------------------------------------------------------------
% HI model accuracy
[x1, y1] = fill_min_to_max(info1.SOCs', info1.error.meas);
[x2, y2] = fill_min_to_max(info2.SOCs', info2.error.meas);

name_txt = "exp1 - fig - HI model accuracy"; 
figure("Name",  name_txt); 
hold on; 
plot(info1.SOCs, mean(info1.error.meas, 1), '.-')
plot(info2.SOCs, mean(info2.error.meas, 1), '.-')
fill(x1, y1, [0 0.4470 0.7410], 'EdgeColor', 'none', 'FaceAlpha', 0.2)
fill(x2, y2, [0.8500 0.3250 0.0980], 'EdgeColor', 'none', 'FaceAlpha', 0.2)
grid on
xlim([10, 100])
ylim([-0.05, 0.8])
set(gcf, 'Units', 'normalized', 'Position', [0.1, 0.1, 0.3, 0.3]); % [left, bottom, width, height]
ylabel("nRMSE")
xlabel("SOC")
legend("dataset1", "dataset2", Location="northeast")

if export
    exportgraphics(gcf, info.figures.folder + name_txt + ".png", 'Resolution',300)
    savefig(gcf, info.figures.folder + name_txt + ".fig")
end

clearvars -except info info1 info2 export

%% Functions
function [xfill, yfill] = fill_min_to_max(x, y)

    xfill = [x, fliplr(x)];
    
    yfill = [mean(y) + std(y), mean(y) - std(y)];

end
