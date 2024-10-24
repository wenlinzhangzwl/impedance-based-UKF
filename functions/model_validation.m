function [error, pred, ref] = model_validation(info, model, data, state_or_meas)

    data = sortrows(data, "SOH", "descend");

    switch info.modelstr
        case "linear"
            if state_or_meas == "state"

                %----------------------------------------------------
                % Scripts used to calculate modelling accuracy in v3.
                % Evaluates fit of the polynomial to data.
                % Cannot be used to evaluate the ML models. Need to
                % actually calculate the OL performance instead. 
                %
                % input = data.EFC;
                % ref = data.SOH; 
                % pred = polyval(model, input);
                %----------------------------------------------------

                % to be compatible w/ function "propogate_state_linear"
                state_model = model; 
                clearvars model
                model.state = state_model; 

                % only take unique SOH values
                [~, ind, ~] = unique(data.SOH, "stable");
                data = data(ind, :); 
    
                % reference SOH
                ref = data.SOH(2:end); 

                % estimate SOH based on SOH_prev, n_prev & n
                SOH_prev = data.SOH(1:end-1); 
                n_prev = data.EFC(1:end-1); 
                dn = data.EFC(2:end) - data.EFC(1:end-1); 
                pred = propogate_state_linear(model, SOH_prev, n_prev, dn);

            elseif state_or_meas == "meas"
                input = data.SOH;
                ref = data.HI; 
                pred = polyval(model, input);
            end
            

        case {"GPR_UKF", "FNN_UKF"}

            if state_or_meas == "state"
                data_state = format_data(data, "state");
                input = data_state(:, 2:end); 
                ref = data_state.SOH; 

            elseif state_or_meas == "meas"
                data_meas = format_data(data, "meas");
                input = data_meas.SOH;
                ref = data_meas.HI; 

            end    
            pred = predict(model, input);
    end
    
    error = rmse(ref, pred);


end














