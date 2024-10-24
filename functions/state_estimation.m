function output = state_estimation(varargin)
    
%% Input variable handling
    % Create an input parser object
    p = inputParser;
    
    % Add optional parameters with default values
    addParameter(p, 'info', 0);
    addParameter(p, 'model_state', 0);
    addParameter(p, 'model_meas', 0);
    addParameter(p, 'data', 0);
    addParameter(p, 'SOC', 0);
    addParameter(p, 'par_opt', []);
    parse(p, varargin{:});
    
    % Set parameters
    info = p.Results.info;
    model.state = p.Results.model_state;
    model.meas = p.Results.model_meas;
    data = p.Results.data;
    SOC = p.Results.SOC;
    par_opt = p.Results.par_opt; 


%% State estimation

    if exist("SOC", "var") % allows parfor loop to work
        info.SOC = SOC; 
    end

    cells = unique(data.cellnum); 

    SOH_est = []; 
    SOH_ref = [];

    for i = 1:length(cells)

        % divide into cells
        data_i = data(data.cellnum == cells(i), :);
        data_i = sortrows(data_i, "EFC", {'ascend'}); 

        % estimation
        if ~isempty(par_opt)
            SOH_est_i = UKF(info, model, data_i, par_opt);
        else
            SOH_est_i = UKF(info, model, data_i);
        end


        % store results (individual cell)
        individual(i).SOH_est = SOH_est_i; 
        individual(i).SOH_ref = data_i.SOH;
        individual(i).EFC = data_i.EFC; 
        individual(i).rmse_i = rmse(SOH_est_i, data_i.SOH); 
        SOH_est = [SOH_est; SOH_est_i]; 
        SOH_ref = [SOH_ref; data_i.SOH];

    end

   individual = struct2table(individual, 'AsArray', true);
   
    %% Output
    output.SOH_est = SOH_est; 
    output.SOH_ref = SOH_ref; 
    % output.individual = individual; % do not export individual cell data to save memory
    % output.rmse = mean(output.individual.rmse_i);
    output.rmse = mean(individual.rmse_i);
    
    % plot
    if info.plot_figures == 1

        figure("WindowStyle","docked", 'Name', "Testing, Estimator")
        hold on
        plot(SOH_est, SOH_ref, '.')
        plot([80:100], [80:100], '-', Color='red')
        xlabel("Estimated SOH")
        ylabel("Actual SOH")
        grid on
        title("SOH, rmse = " + string(round(output.rmse, 2)))

        
        for i = 1:height(individual)
            figure("WindowStyle","docked", 'Name', "Testing, Cell")
            hold on
            plot(individual.SOH_ref{i}, individual.EFC{i}, '.-')
            plot(individual.SOH_est{i}, individual.EFC{i}, '.-')
            title("rmse = " + string(round(output.individual.rmse_i(i), 2)))
            xlabel("EFC")
            ylabel("SOH")
            legend("Actual", "Estimated")
            grid on
        end
        
        

    end

end














