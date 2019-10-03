function opt = setup_global_nelder_mead(this, varargin)

this.solver = 'global_nelder_mead';
dim_pb = numel(this.params);
opt = struct( ...
    'num_corners', min(2^dim_pb, 10*dim_pb),...
    'num_quasi_rand_samples', 10*dim_pb, ...
    'quasi_rand_seed', 1, ...
    'local_max_obj_eval', this.max_obj_eval/2, ...
    'local_solver', 'nelder_mead',... 
    'local_options', optimset('Display', 'off') ...
    );

% JOHAN CHANGE
% Prevent "corner sampling", we want to do pure random initial sampling
% instead, this is for achieving similar results to with other algorithms
% (like Simulated Annealing).
% Setting num_corners = 0 will result to no "corner solve" in
% solve_global_nelder_mead.m. 
opt.num_corners = 0;
% END JOHAN CHANGE

if this.use_parallel
    opt.use_parallel = true;
end

% checks with what we have already
if isstruct(this.solver_options)
    fn = fieldnames(this.solver_options);
    for ifn = 1:numel(fn)
        field = fn{ifn};
        if isfield(opt, field)
            opt.(field) = this.solver_options.(field);
        end
    end
end

if nargin>2    
    opt = varargin2struct_breach(opt, varargin{:});
end

if (nargin >= 2)&&gui
    choices = struct( ...
        'use_param_set_as_init','bool',...
        'start_at_trial', 'int', ...
        'nb_new_trials',  'int', ...
        'nb_local_iter',  'int', ...
        'local_optim_options', 'string' ...
        );
    tips = struct( ...
        'use_param_set_as_init','Use the samples in the parameter set used to create the problem as initial trials. Otherwise, starts with corners, then quasi-random sampling.',...
        'start_at_trial', 'Skip the trials before that. Use 0 if this is the first time you are solving this problem.', ...
        'nb_new_trials',  'Number of initial parameters used before going into local optimization.', ...
        'nb_local_iter',  'Number of iteration of Nelder-Mead algorithm for each trial.', ...
        'local_optim_options', 'Advanced local solver options. ' ...
        );
    gui_opt = opt;
    gui_opt.local_optim_options = 'default optimset()';
    
    opt = BreachOptionGui('Choose options for solver global_nelder_mead', gui_opt, choices, tips);
    close(opt.dlg);
    
    return;
    %gui_opt = gu.output;
    %gui_opt.local_optim_options = opt.local_optim_options;
    %opt = gui_opt;
end

this.solver_options = opt;

end
