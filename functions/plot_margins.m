function [xfill, yfill] = plot_margins(x, y)
% Plots the standard deviation
% 
% x is the independent variable
% 
% y can be a matrix. 
% Average is taken across the rows (dim 1). May need to transpose
% 
% Example: 
% [x1, y1] = plot_margins(info1.SOCs', info1.error.UKF);
% [x2, y2] = plot_margins(info2.SOCs', info2.error.UKF);
% fill(x1, y1)
% fill(x2, y2)

    xfill = [x, fliplr(x)];
    
    yfill = [mean(y) + std(y), mean(y) - std(y)];

    yfill = max(yfill, 0); 

end