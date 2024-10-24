function output = format_data(data, state_or_meas)
% format data for training & validation of ML models

% to extract SOH_prev
% if used for training, outputs don't need to be the same height
% if used for testing, outputs need to be the same height
% data_state = [SOH, SOH_prev, EFC_prev, dEFC]
% data_meas = [HI, SOH]

    data = sortrows(data, ["cellnum", "EFC"], "ascend"); 

    if state_or_meas == "state"
    % multiple SOCs of the same SOH measurement
        
        % only keep the rows where cellnum + EFC + SOH is unique
        t = table(data.cellnum, data.EFC, data.SOH); 
        [~,ia,~] = unique(t,'rows');
        data = data(ia, :); 

        % find first data point of each cell
        cells = unique(data.cellnum); 
        ind = zeros([height(cells), 1]); 
        for i = 1:height(cells)
            ind(i) = find(data.cellnum == cells(i), 1); 
        end
    
        % record SOH_prev, EFC_prev & dEFC 
        data.SOH_prev = [0; data.SOH(1:end-1)];
        data.EFC_prev = [0; data.EFC(1:end-1)];
        data.dEFC = [0; data.EFC(2:end)-data.EFC(1:end-1)];

        % Remove first meas of each cell 
        data(ind, :) = [];
       
        % data_state = [SOH, SOH_prev, EFC_prev, dEFC]
        SOH = data.SOH; 
        SOH_prev = data.SOH_prev; 
        EFC_prev = data.EFC_prev;   
        dEFC = data.dEFC; 
        output = table(SOH, SOH_prev, EFC_prev, dEFC);

    elseif state_or_meas == "meas"
    % only has one SOC

        SOH = data.SOH; 
        HI = data.HI;   
        output = table(HI, SOH);
    end

end