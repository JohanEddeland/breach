function res = solve_corners(this)
% Generate corners, group them by signals if possible/relevant
% 

BrC = BreachSet(this.params);
num_corners =  this.solver_options.num_corners;

if this.solver_options.group_by_inputs
    
    % Creates BreachSet with one param per group
    sigs = this.BrSys.InputGenerator.GetAllSignalsList();
    grouparams = this.params;
    ig=1;  
    for is = 1:numel(sigs)
        groupin = intersect(this.BrSys.expand_param_name([sigs{is} '_u']), this.params);
        if ~isempty(groupin)            
            groupinputs{ig} = groupin;
            groupinputs_reps{ig} = [sigs{is} '_group'];
            grouparams = setdiff(grouparams, groupinputs{ig});
            ig = ig+1;
        end
    end
    if isempty(grouparams)
        BrC_group = BreachSet(groupinputs_reps);
    else
        BrC_group = BreachSet(['grouparam' groupinputs_reps]); % TEST ME!
    end
    
    % Sample group BreachSet
    gparams= BrC_group.GetParamList(); 
    for ig = 1:numel(gparams)
        BrC_group.SetDomain(gparams{ig}, BreachDomain('enum', [1 2], [1 2]));
    end
    BrC_group.CornerSample(num_corners);
    
    % Extract concrete corners
    X0 = zeros(numel(this.params), size(BrC_group.P.pts, 2)); 
    if ~isempty(grouparams)  % TEST ME!
        for ig = 1:numel(grouparams)  
            idx = strcmp(this.params, grouparams{ig});
            which_corn = BrC_group.GetParam(grouparams{ig}); 
            corn_vals =  [this.lb(idx) this.ub(idx)];
            X0(idx,:) =  arrayfun(@(c)(corn_vals(c)), which_corn);   
        end
    end
    for ig = 1:numel(groupinputs_reps)
            which_corn = BrC_group.GetParam(groupinputs_reps{ig}); 
            for ip = 1:numel(groupinputs{ig})
                idx = strcmp(this.params, groupinputs{ig}{ip});
                corn_vals =  [this.lb(idx) this.ub(idx)];
                X0(idx,:) =  arrayfun(@(c)(corn_vals(c)), which_corn);
            end
    end
    if size(X0,2)<num_corners % complete with normal corners 
        BrC.CornerSample(num_corners);
        X0 = unique([X0 BrC.GetParams(this.params)]', 'rows','stable')';
        X0 = X0(:, 1:num_corners);
    end
    
else
    BrC.CornerSample(num_corners);
    X0 = BrC.GetParams(this.params);
end


if ~strcmp(this.display,'off')
    fprintf('\n Running %g corners\n', size(X0, 2));
    this.display_status_header();
end

res = this.FevalInit(X0);
this.add_res(res); 

end
