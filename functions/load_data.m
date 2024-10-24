function data = load_data(dataset, info, explore)

    % load data
    switch dataset
        case "Mohtat"
            load("data\data_Mohtat2021.mat")
            data(data.SOC == 0, :) = [];
        case "Chan"
            load("data\data_Chan2022.mat")
            data(data.SOC == 25, :) = [];
    end
    
    data = data(data.SOH >= 80, :); % cut to 80% SOH

    if explore
        data_exploration(info, data); % explore data
    end

    % if dataset == "Chan" && info.modelstr == "linear"
        data.EFC = log(data.EFC); 
    % end

end

