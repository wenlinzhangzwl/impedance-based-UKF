function [] = data_exploration(info, data)

    %% Degradation trend
    name_txt = "fig - degradation trend - " + info.dataset; 
    figure("Name",name_txt) 
    hold on
    plot(data.EFC, data.SOH, '.')
    grid on; 
    xlabel("Equivalent full cycles"); 
    ylabel("SOH (%)")
    % if info.dataset == "Chan"
    %     set(gca, "XScale", "log")
    % end
    set(gcf, 'Units', 'normalized', 'Position', [0.1, 0.1, 0.25, 0.3]); % [left, bottom, width, height]

    if info.figures.export
        
        exportgraphics(gcf, info.figures.folder + name_txt + ".png", 'Resolution',300)
        savefig(gcf, info.figures.folder + name_txt + ".fig")
    end

    %% HI evolution

    SOCs = unique(data.SOC); 
    
    name_txt = "fig - HI vs SOH - " + info.dataset; 
    figure("Name",name_txt) 

    for i = 1:length(SOCs) % for each SOC
        
        data_i = data(data.SOC == SOCs(i), :);
    
        subplot(2, ceil(length(SOCs)/2), i); 
        hold on
        plot(data_i.SOH, data_i.HI, '.');
        grid on
        title_txt = "SOC: " + string(SOCs(i)) + "%"; 
        title(title_txt)
        xlabel("SOH (%)")
        ylabel("Health indicator")
    
    end
    set(gcf, 'Units', 'normalized', 'Position', [0.1, 0.1, 0.6, 0.6]); % [left, bottom, width, height]

    if info.figures.export
        exportgraphics(gcf, info.figures.folder + name_txt + ".png", 'Resolution',300)
        savefig(gcf, info.figures.folder + name_txt + ".fig")
    end
end

