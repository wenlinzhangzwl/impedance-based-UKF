function par = initializeUKF(info, model, par_opt)

    %% set P, Q, R
    if exist("par_opt", "var")
        par.P = par_opt(1); 
        par.Q = par_opt(2); 
        par.R = par_opt(3); 
    else
        switch info.dataset
            case "Chan"
                switch info.modelstr
                    case "linear"
                        switch info.filter_params
                            case "initial"
                                par.P = 0.1; % initial state prediction covariance
                                par.Q = 5; % process noise covariance
                                par.R = 10; % measurement noise covariance
                            case "optimized"
                                par.P = 0.1;
                                par.Q = 5;
                                par.R = 8;
                                switch info.SOC
                                    case 100
                                        par.R = 20; 
                                    case {80, 65, 50, 35}
                                        par.R = 8; 
                                    case 20
                                        % changing R doesn't change results
                                        par.R = 8; 
                                end

                        end
                        
                    case "GPR_UKF"
                        switch info.filter_params
                            case "initial"
                                par.P = 1; % state prediction covariance
                                par.Q = 1; % process noise covariance
                                par.R = 1; % measurement noise covariance
                            case "optimized"
                                par.P = 0.05;
                                par.Q = 0.5;
                                par.R = 2;
                                switch info.SOC
                                    case 100
                                        par.R = 5; 
                                end
                        end
                    case "FNN_UKF"
                        switch info.filter_params
                            case "initial"
                                par.P = 1; % state prediction covariance
                                par.Q = 1; % process noise covariance
                                par.R = 1; % measurement noise covariance
                            case "optimized"
                                par.P = 0.25;
                                par.Q = 0.5; 
                                par.R = 0.5;

                                switch info.SOC
                                    case 100
                                        par.R = 8;
                                    case 20
                                        par.R = 2;
                                end
                        end
                end
            case "Mohtat"
                switch info.modelstr
                    case "linear"
                        switch info.filter_params
                            case "initial"
                                par.P = 5; % state prediction covariance
                                par.Q = 2; % process noise covariance
                                par.R = 1; % measurement noise covariance
                            case "optimized"
                                par.P = 5;
                                par.Q = 2;
                                switch info.SOC
                                    case {90, 80, 70, 60}
                                        par.R = 1;
                                    case 50
                                        par.R = 0.5;
                                    case {30, 40}
                                        par.R = 0.3;
                                    case 20
                                        par.R = 0.2; 
                                    case 10
                                        % changing R cannot significantly improve results
                                        par.R = 0.1;
                                end
                        end
                    case "GPR_UKF"
                        switch info.filter_params
                            case "initial"
                                par.P = 1; % state prediction covariance
                                par.Q = 1; % process noise covariance
                                par.R = 1; % measurement noise covariance
                            case "optimized"
                                par.P = 0.25;
                                par.Q = 2;
                                par.R = 3;
                        end
                    case "FNN_UKF"
                        switch info.filter_params
                            case "initial"
                                par.P = 1; % state prediction covariance
                                par.Q = 1; % process noise covariance
                                par.R = 1; % measurement noise covariance
                            case "optimized"
                                par.P = 1;
                                par.Q = 8; 
                                par.R = 0.5;

                                switch info.SOC
                                    case 90
                                        par.R = 8; % 8
                                end
                        end
                end 
        end
    end

    
    %% state equations
    switch info.modelstr
        case "linear"
            par.fx = @(SOH, n, dn) propogate_state_linear(model, SOH, n, dn); 
            par.fz = @(SOH) predict_meas_linear(model.meas, SOH);
            par.fsoh = @(n) polyval(model.state, n);
        case {"GPR_UKF", "FNN_UKF"}
            par.fx = @(SOH_prev, EFC_prev, dEFC) predict(model.state, table(SOH_prev, EFC_prev, dEFC)); 
            par.fz = @(SOH) predict(model.meas, SOH);
    end
    

end


function z = predict_meas_linear(model, SOH)
% predict measurement based on the SOH

    for i = 1:height(model)
        z(i, 1) = polyval(model(i, :), SOH);
    end

end


