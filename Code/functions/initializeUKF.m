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
                                % 8.73343910554121	8.66332007091452	0.736395465578162
                                % 0.450692260759606	4.26152860154911	0.395008155016101
                                % 0.446462276728014	9.97440854430263	1.09375000000000
                                % 7.85744049727082	9.93106802582005	1.25000000000000
                                % 9.22635980375262	9.52570519301230	1.25000000000000
                                % 6.46039023183038	9.79469122451337	3.51827574930614
                                par.P = 8; 
                                par.Q = 9; 
                                switch info.SOC
                                    case 100
                                        par.R = 5; 
                                    case {80, 65, 50, 35, 20}
                                        par.R = 1; 
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
                                par.Q = 2; % process noise covariance
                                par.R = 0.5; % measurement noise covariance
                            case "optimized"
                                switch info.SOC
                                    case 90 %1
                                        par_opt = [1    3       0.5];
                                    case 80 %2
                                        par_opt = [1    2.75    0.5];
                                    case 70 %3
                                        par_opt = [1    2.5     0.5];
                                    case 60 %4
                                        par_opt = [1    4       0.5];
                                    case 50 %5
                                        par_opt = [1    6       5];
                                    case 40 %6
                                        par_opt = [1    6       10];
                                    case 30 %7
                                        par_opt = [1    6       15];
                                    case 20 %8
                                        par_opt = [1    6       20];
                                    case 10 %9
                                        par_opt = [1    6       30];
                                        
                                end
                                
                                par.P = par_opt(1); 
                                par.Q = par_opt(2); 
                                par.R = par_opt(3); 
                    
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
        case "GPR_UKF"
            par.fx = @(SOH_prev, EFC) predict(model.state, table(SOH_prev, EFC)); 
            par.fz = @(SOH) predict(model.meas, SOH);
    end
    

end

function x = propogate_state_linear(model, x, n, dn)

    coeff = model.state; 
    if length(coeff) == 2 % 1st order
        a = coeff(1); 
        b = coeff(2); 
        m = dn; 
        x = x + a*m; 
    elseif length(coeff) == 3 % 2nd order
        a = coeff(1); 
        b = coeff(2); 
        c = coeff(3); 
        m = dn; 
        % % https://www.symbolab.com/solver/step-by-step/expand%20%20a%5Cleft(n%2Bm%5Cright)%5E%7B2%7D%2Bb%5Cleft(n%2Bm%5Cright)%2Bc%20-%5Cleft(a%5Ccdot%5Cleft(n%5Cright)%5E%7B2%7D%2Bb%5Cleft(n%5Cright)%2B%2Bc%5Cright)%20?or=input
         x = x + a*m^2 + b*m + 2*n*m*a; 
        % x = x + m * (2*a*m + b); 
    elseif length(coeff) == 4 % 3rd order
        a = coeff(1); 
        b = coeff(2); 
        c = coeff(3); 
        d = coeff(4); 
        m = dn; 
        % https://www.symbolab.com/solver/step-by-step/expand%20%20a%5Ccdot%5Cleft(n%2Bm%5Cright)%5E%7B4%7D%2Bb%5Cleft(n%2Bm%5Cright)%5E%7B3%7D%2B%2Bc%5Cleft(n%2Bm%5Cright)%5E%7B2%7D%2Bd%5Cleft(n%2Bm%5Cright)%2Be%20-%5Cleft(a%5Ccdot%20%5Cleft(n%5Cright)%5E%7B4%7D%2Bb%5Cleft(n%5Cright)%5E%7B3%7D%2B%2Bc%5Cleft(n%5Cright)%5E%7B2%7D%2Bd%5Cleft(n%5Cright)%2Be%5Cright)%20?or=input
        x = x + ...
            a*m^3 + b*m^2 + c*m + 3*m*a*n^2 + 3*n*a*m^2 + 2*n*m*b; 
    elseif length(coeff) == 5 % 4th order
        a = coeff(1); 
        b = coeff(2); 
        c = coeff(3); 
        d = coeff(4); 
        e = coeff(5);
        m = dn; 
        % https://www.symbolab.com/solver/step-by-step/expand%20%20a%5Ccdot%5Cleft(n%2Bm%5Cright)%5E%7B4%7D%2Bb%5Cleft(n%2Bm%5Cright)%5E%7B3%7D%2B%2Bc%5Cleft(n%2Bm%5Cright)%5E%7B2%7D%2Bd%5Cleft(n%2Bm%5Cright)%2Be%20-%5Cleft(a%5Ccdot%20%5Cleft(n%5Cright)%5E%7B4%7D%2Bb%5Cleft(n%5Cright)%5E%7B3%7D%2B%2Bc%5Cleft(n%5Cright)%5E%7B2%7D%2Bd%5Cleft(n%5Cright)%2Be%5Cright)%20?or=input
        x = x + ...
            a*m^4 + b*m^3 + 4*a*n*m^3 + ...
            c*m^2 + 6*a*n^2*m^2 + 3*b*n*m^2 + ...
            d*m + 4*a*n^3*m + 3*b*n^2*m + ...
            2*c*n*m; 
    end

end

function z = predict_meas_linear(model, SOH)
% predict measurement based on the SOH

    for i = 1:height(model)
        z(i, 1) = polyval(model(i, :), SOH);
    end

end
