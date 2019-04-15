function res = solve_meta(this)

% display header
if ~strcmp(this.display,'off')
    fprintf('Eval objective function on %d initial parameters.\n', size(X0,2));
    this.display_status_header();
end

opt = this.solver_opt;

if opt.num_corners>0
    this.solve_corners();
end

while ~this.stopping()
   
    %% Quasi-random phase 
    res = this.solve_quasi_random();  
    
    this.x0
    for i_loc = ibest
        x0 = X0(:,i_loc);
        if ~this.stopping()
            [x, fval, exitflag, output] = minimize(...
                fun_obj, x0 ,this.lb,this.ub,this.Aineq,this.bineq,this.Aeq,this.beq,[],[],options);
            res{end+1} = struct('x0', x0, 'x',x, 'fval',fval, 'exitflag', exitflag,  'output', output);
        end
    end
end
end

