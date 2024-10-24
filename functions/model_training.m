function model = model_training(info, data, state_or_meas)

    
    switch info.modelstr
        case "linear"

            data = sortrows(data, "EFC", "ascend");

            EFC = data.EFC; 
            SOH = data.SOH; 
            HI = data.HI; 

            if state_or_meas == "state"
                % SOH vs EFC model
                coeff_state = polyfit(EFC, SOH, 2);
                model = coeff_state; 
            elseif state_or_meas == "meas"
                % HI vs SOH model
                coeff_meas = polyfit(SOH, HI, 1);
                model = coeff_meas; 
            end

        case "GPR_UKF"

            if state_or_meas == "state"
                data_state = format_data(data, "state");

                % State: SOH_k = f(SOH_k-1, EFC_k-1, dEFC)
                model = fitrgp(data_state, "SOH",...
                    "KernelFunction","exponential",...
                    "BasisFunction","constant",...
                    "Standardize",true);

            elseif state_or_meas == "meas"
                data_meas = format_data(data, "meas");

                % Meas: HI_k = g(SOH_k)
                model = fitrgp(data_meas, "HI",...
                    "KernelFunction","exponential",...
                    "BasisFunction","constant",...
                    "Standardize",true);
            end
        
        case "FNN_UKF"

            if state_or_meas == "state"
                data_state = format_data(data, "state");

                % State: SOH_k = f(SOH_k-1, EFC_k-1, dEFC)
                model = fitrnet(data_state, "SOH",...
                    "LayerSizes", 3, ...
                    "Activations", "relu",...
                    "Standardize",true);

            elseif state_or_meas == "meas"
                data_meas = format_data(data, "meas");

                % Meas: HI_k = g(SOH_k)
                model = fitrnet(data_meas, "HI",...
                    "LayerSizes", 3, ...
                    "Activations", "relu",...
                    "Standardize",true);
            end

        case "GPR"
            data.cellnum = []; 
            data.n = [];
            model = fitrgp(data, "SOH",...
                "KernelFunction","matern52",...
                "BasisFunction","constant",...
                "Standardize",true);
    end

end