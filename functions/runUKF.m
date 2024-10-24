function [x_est] = runUKF(info, EFC, par, lambda, Wm, Wc, x_init, z_meas)

    L = height(x_init); % number of states
    m = height(z_meas); % number of measurements

    x_k = x_init; 
    P_k = par.P; 

    % empty vector to store results
    x_est = zeros(L, width(z_meas));
    residual = zeros(m, width(z_meas)); 

    % iteration
    x_est(1) = x_init; 

    for k = 2:height(EFC) % for each measurement point

        switch info.val_type 
            case "openloop"
                switch info.modelstr
                    case "linear"
                        x_est(:, k) = par.fx(x_est(k-1), EFC(k-1), EFC(k)-EFC(k-1));
                    case {"GPR_UKF", "FNN_UKF"}
                        x_est(:, k) = par.fx(x_est(k-1), EFC(k-1), EFC(k)-EFC(k-1));
                end
            case "UKF"
                switch info.modelstr
                    case "linear"
                        [x_pred_k, x_mean_k, P_k] = state_prediction(info, x_k, P_k, L, lambda, par, EFC(k-1), EFC(k)-EFC(k-1), Wm, Wc); 
                    case {"GPR_UKF", "FNN_UKF"}
                        [x_pred_k, x_mean_k, P_k] = state_prediction(info, x_k, P_k, L, lambda, par, EFC(k-1), EFC(k)-EFC(k-1), Wm, Wc);  
                end
                
                [z_pred_k, z_mean_k, S_k] = measurement_prediction(m, L, x_pred_k, par, Wm, Wc); 
    
                K_k = kalman_gain(L, m, Wc, x_pred_k, x_mean_k, z_pred_k, z_mean_k, S_k); 
            
                [x_k, P_k] = state_update(x_mean_k, z_meas(:, k), par, P_k, K_k, S_k); 
            
                % AUKF: Update process & measurement noise covariances
                if info.val_type == "AUKF"
        
                    % calcualte residual
                    switch info.state_vars
                        case 'SOH'
                            z_updated = par.fz(x_k); 
                        case 'bias'
                            z_updated = par.fz(x_k, EFC(k));
                        case 'slope'
                    end
                    residual(:, k) = z_meas(:, k) - z_updated;
                    
                    M = 10; 
                    if k >= M
                        [par.Q, par.R] = update_covariances(M, k, residual, K_k, L, Wc, z_mean_k, z_updated);
                    end
                end
        
                % store results
                x_est(:, k) = x_k;

        end
        

    end

end



function [x_pred, x_mean, P] = state_prediction(info, x_prev, P, L, lambda, par, EFC_prev, dEFC, Wm, Wc)
% State prediction

    % compute sigma points, each represents an x value
    sigma_points = find_sigma_points(x_prev, P, lambda); 

    % Cap points to 105 for NN to avoid P approaching INF, which will lead to failure in calculating chol(P)
    if info.modelstr == "FNN_UKF"
        sigma_points = min(sigma_points, [105, 105, 105]);
    end

    % predict state for each sigma point
    switch info.modelstr
        case "linear"
            x_pred = par.fx(sigma_points, EFC_prev, dEFC);
        case {"GPR_UKF", "FNN_UKF"}
            x_pred = par.fx(sigma_points', EFC_prev*ones(length(sigma_points), 1), dEFC*ones(length(sigma_points), 1));
            x_pred = x_pred';
    end

    % weighted average
    x_mean = sum(Wm .* x_pred, 2);

    % state covariance
    P = zeros(L, L); % state covariance, [LxL]
    for i = 1 : 2*L+1
        P = P + Wc(i) * (x_pred(:, i) - x_mean) * (x_pred(:, i) - x_mean)';
    end
    P = P + par.Q;

end

function output = find_sigma_points(x_mean, P, lambda)

    L = height(x_mean); 

    % matrix = sqrt((L + lambda)*P); 
    % x1 = zeros(L, 2*L); 
    % for i = 1:L
    %     x(:, i) = x_mean + matrix(:, i); 
    %     x(:, L+i) = x_mean - matrix(:, i); 
    % end
    % x1 = [x_mean, x];

    x2 = [x_mean, ...
         x_mean + chol(P) * sqrt(L + lambda), ...
         x_mean - chol(P) * sqrt(L + lambda)];  % Cholesky decomposition, [L x 2L+1]

    % %Sigma points around reference point
    % %Inputs:
    % %       x: reference point
    % %       P: covariance
    % %       c: coefficient
    % %Output:
    % %       X: Sigma points
    % A = sqrt(L+lambda)*chol(P)';
    % Y = x_mean(:,ones(1,numel(x_mean)));
    % x3 = [x_mean Y+A Y-A]; 

    output = x2; 
end

function [z_pred, z_mean, S] = measurement_prediction(m, L, x_pred, par, Wm, Wc)

    % predicted measurement for each sigma point
    z_pred = zeros(m, 2*L+1); % [m x 2L+1]
    for i = 1 : 2*L+1 
        z_pred(:, i) = par.fz(x_pred(:, i));
    end

    % weighted average
    z_mean = sum(Wm .* z_pred, 2);

    % innovation covaraince
    S = zeros(m, m); % innovation covariance, [mxm]
    for i = 1 : 2*L+1 % for each sigma point
        S = S + Wc(i) * (z_pred(:, i) - z_mean) * (z_pred(:, i) - z_mean)';
    end
    S = S + par.R;

end

function K = kalman_gain(L, m, Wc, x_pred, x_mean, z_pred, z_mean, S)

    % cross-covariance between state and measurements
    Pxz = zeros(L, m); % [L x m]
    for i = 1:2*L+1
        Pxz = Pxz + Wc(i) * (x_pred(:, i) - x_mean) * (z_pred(:, i) - z_mean)';
    end

    % Kalman gain
    id1 = 'MATLAB:nearlySingularMatrix'; 
    id2 = 'MATLAB:illConditionedMatrix';
    warning('off',id1)
    warning('off',id2)
    K = Pxz / S; % [1 x m]
    warning('on',id1)
    warning('on',id2)

end

function [x, P] = state_update(x_mean, z_actual, par, P, K, S)
    % update state estimate and covariance
    innovation = z_actual - par.fz(x_mean);
    x = x_mean + K * innovation; 
    P = P - K * S * K';
end

function [Q, R] = update_covariances(M, k, residual, K, L, Wc, z_prior, z_updated)

    % residual covariance
    C_res = zeros(height(residual), height(residual));

    % average C for the last M points
    for i = k-M+1:k
        C_res = C_res + residual(:, i) * residual(:, i)'; 
    end
    C_res = 1/M * C_res; 

    % update process noise covariance
    Q = K * C_res * K';

    % update measurement noise covariance
    for i = 1:2*L+1 % for each sigma point
        temp = z_prior - z_updated; 
        C_meas = Wc(i) * (temp * temp'); 
    end
    R = C_res + C_meas; 
end


