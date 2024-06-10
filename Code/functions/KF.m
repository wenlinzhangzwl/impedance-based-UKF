function [SOH_est, debugging_info] = KF(info, model, z_meas, n)

    z_meas = z_meas'; 
    
    x_init = 0.95; 
    P = 1e0; % state prediction covariance
    Q = 1e0; % process noise covariance
    R = 1e0*eye(height(z_meas)); % measurement noise covariance
    
    F = 1; 
    G = model.state(1); 
    H = model.meas(:, 1); 
    I = model.meas(:, 2); 

    x = zeros(height(z_meas), 1); 
    z = zeros(size(z_meas)); 
    u = n(2:end) - n(1:end-1); 

    x(1) = x_init; 
    for i = 2:width(z_meas)
        x(i) = F * x(i-1) + G * u(i-1);  
        z(:, i) = H * x(i) + I; 
    end
end

