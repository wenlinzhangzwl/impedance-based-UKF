function error = model_validation(info, model, data, state_or_meas)

    %% Model accuracy

    switch info.modelstr
        case "linear"

            if state_or_meas == "state"
                input = data.EFC;
                ref = data.SOH; 
            elseif state_or_meas == "meas"
                input = data.SOH;
                ref = data.HI; 
            end
            pred = polyval(model, input);

        case "GPR_UKF"

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

    if info.plot_figures == 1

        if state_or_meas == "state"
                figure("WindowStyle","docked", 'Name', "Testing, State Model")
                hold on
                plot(ref, pred, '.')
                plot([80:100], [80:100], '-', Color='red')
                xlabel("Actual SOH")
                ylabel("Estimated SOH")
                grid on
                title("SOH, rmse = " + string(round(error, 2)))
            elseif state_or_meas == "meas"
                figure("WindowStyle","docked", 'Name', "Testing, Meas Model")
                hold on
                plot(ref, pred, '.')
                plot([-2:2], [-2:2], '-', Color='red')
                xlabel("Actual HI")
                ylabel("Estimated HI")
                grid on
                title("HI, rmse = " + string(round(error, 2)))
        end    

        
    end

end














