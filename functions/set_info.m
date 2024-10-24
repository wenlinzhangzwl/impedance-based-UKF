function info = set_info(varargin)

    % Create an input parser object
    p = inputParser;
    
    % Add optional parameters with default values
    addParameter(p, 'plot_figures', 3);
    addParameter(p, 'filter_params', ""); % initial, optimized
    addParameter(p, 'model_structure', ""); % linear, GPR_UKF, FNN_UKF
    addParameter(p, 'dataset', ""); % Chan, Mohtat
    addParameter(p, 'figures_folder', "..\figures\");
    addParameter(p, 'models_folder', "..\models\");
    addParameter(p, 'figures_export', 0);
    addParameter(p, 'val_type', ""); % openloop, UKF
    
    % Parse the inputs
    parse(p, varargin{:});
    

    % Set parameters
    info.plot_figures = p.Results.plot_figures; % 0 = none, 1 = all, 2 = results, 3 = for paper
    info.filter_params = p.Results.filter_params; % "initial", "optimized"
    info.modelstr = p.Results.model_structure; % linear, GPR_UKF, GPR
    info.dataset = p.Results.dataset; % Mohtat, Chan
    info.figures.folder = p.Results.figures_folder; 
    info.figures.export = p.Results.figures_export; 
    info.models_folder = p.Results.models_folder; 
    info.val_type = p.Results.val_type;
end

