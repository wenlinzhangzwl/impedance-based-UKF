function SOH_est = UKF(info, model, data, par_opt)

    % Initialize
    x_init = data.SOH(1);

    % Filter parameters
    if exist("par_opt", "var")
        par = initializeUKF(info, model, par_opt); 
    else
        par = initializeUKF(info, model); 
    end

    % UKF setup
    [lambda, Wm, Wc] = set_sigma_point_weights(height(x_init)); 

    % run UKF
    x_est= runUKF(info, data.EFC, par, lambda, Wm, Wc, x_init, data.HI'); 

    % Output results
    SOH_est = x_est';

end