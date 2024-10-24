function [lambda, Wm, Wc] = set_sigma_point_weights(L)

    % L: number of states

    % Set up UKF parameters
    alpha = 1; % Scaling parameter, spread of sigma points around mean
    beta = 2; % Parameter for incorporating prior knowledge, 2 is optimal for Gaussian
    ki = 0; % Secondary scaling parameter, usually set to 0
    lambda = alpha^2 * (L + ki) - L;

    % Sigma point weights
    Wm = zeros(1, 2 * L + 1); % Weights for mean, [1 x 2L+1]
    Wc = zeros(1, 2 * L + 1); % Weights for covariance, [1 x 2L+1]
    Wm(1) = lambda / (L + lambda);
    Wc(1) = lambda / (L + lambda) + (1 - alpha^2 + beta);
    for i = 2 : 2*L+1 % 2L+1 sigma points where L is the number of states
        Wm(i) = 1 / (2 * (L + lambda));
        Wc(i) = 1 / (2 * (L + lambda));
    end

end
