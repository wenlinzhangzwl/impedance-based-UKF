function data = load_data(dataset, info, explore)

    % load data
    switch dataset
        case "Mohtat"
            load("..\Data\Mohtat2021.mat");
            data(data.SOC == 0, :) = [];
        case "Chan"
            load("..\Data\Chan2022.mat");
            data(data.SOC == 25, :) = [];
    end
    
    data = data(data.SOH >= 80, :); % cut to 80% SOH

    if explore
        data_exploration(info, data); % explore data
    end

    data.EFC = log(data.EFC); 

end

