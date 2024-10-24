% Plots the degradation trend & HI evolution trend of either of the two datasets. 
% Corresponds to Fig. 2 & 3. 

clear
clc
close all


addpath(cd)
addpath("..\functions")
addpath("..\models")
addpath("..\figures")
addpath("..\data")

dataset = "Mohtat";
switch dataset
    case "Mohtat"
        load("data\data_Mohtat2021.mat")
        data(data.SOC == 0, :) = [];
    case "Chan"
        load("data\data_Chan2022.mat")
        data(data.SOC == 25, :) = [];
end
data = data(data.SOH >= 80, :); % cut to 80% SOH



export = 0; 

% plot degradation trend
name_txt = "exp0 - degradation trend - " + dataset; 
figure(Name= name_txt)
plot(data.EFC, data.SOH, '.')
grid on
xlabel("Equivalent full cycles")
ylabel("SOH [%]")
set(gcf, 'Units', 'normalized', 'Position', [0.025, 0.3, 0.3, 0.35]); % [left, bottom, width, height]
if export
    exportgraphics(gcf, "..\figures\" + name_txt + ".png", 'Resolution',300)
end


% plot HI vs SOH @ 80% SOC
data = data(data.SOC == 80, :); 
name_txt = "exp0 - HI vs SOH - SOC80 - " + dataset; 
figure(Name= name_txt)
plot(data.SOH, data.HI, '.')
grid on
xlabel("SOH [%]")
ylabel("HI")
set(gcf, 'Units', 'normalized', 'Position', [0.025, 0.3, 0.3, 0.35]); % [left, bottom, width, height]
if export
    exportgraphics(gcf, "..\figures\" + name_txt + ".png", 'Resolution',300)
end