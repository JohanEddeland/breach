function res = solve_global_nelder_mead(this)

% JOHAN ADDED
nTrajectoriesPreCalculated = length(dir('trajectories/*.mat'));
fprintf(['TESTRON: Calculating robustness for ' ...
    num2str(nTrajectoriesPreCalculated) ' pre-calculated trajectories\n']);
testronInitRes = inf(1, nTrajectoriesPreCalculated);
testronAndPlusRes = inf(1, nTrajectoriesPreCalculated);
testronX0 = zeros(size(this.x0,1), nTrajectoriesPreCalculated);
t_phi = 0; % Warning: This is probably only correct for alw_[0,tf] specs

tic; % Measure time it takes to calculate robustness for all trajs
load('nextReqToBeFalsified'); % Loads currentReq
if exist(['robValues/' currentReq '.mat'],'file')
    load(['robValues/' currentReq '.mat']); % Loads storedFval, storedX0
    testronInitRes(1:size(storedFval,2)) = storedFval;
    testronAndPlusRes(1:size(storedFval,2)) = storedAndPlusVal;
    testronX0(:,1:size(storedFval,2)) = storedX0;
else
    storedX0 = [];
    storedAndPlusVal = [];
    storedFval = [];
end

numFailed = 0; % Flag

if this.use_parallel
    % Parallel computations
    evalin('base','objToUse = ''standard'';');
    parfor k = size(storedFval,2) + 1:nTrajectoriesPreCalculated
        % This loop performs standard robustness calculations
        loadedVars = load(['trajectories/' num2str(k) '.mat']); % Loads tmpP, paramValues
        tmpP = loadedVars.tmpP;
        paramValues = loadedVars.paramValues;
        try
            [rob, ~] = STL_Eval(this.BrSys.Sys, this.Spec, tmpP, tmpP.traj,t_phi);

            testronInitRes(k) = rob;
            testronAndPlusRes(k) = robAndPlus;
            testronX0(:,k) = paramValues;
        catch ME
            % Sometimes, we haven't logged all signals needed for the specific
            % requirement
            testronInitRes(k) = inf(size(testronInitRes(k)));
            testronAndPlusRes(k) = inf(size(testronAndPlusRes(k)));
            testronX0(:,k) = paramValues;
            numFailed = numFailed + 1; % Set the flag
        end
    end
    
    % Then, perform robustness calculation with &+
    evalin('base','objToUse = ''&+'';');
    parfor k = size(storedFval,2) + 1:nTrajectoriesPreCalculated
        % This loop performs standard robustness calculations
        loadedVars = load(['trajectories/' num2str(k) '.mat']); % Loads tmpP, paramValues
        tmpP = loadedVars.tmpP;
        paramValues = loadedVars.paramValues;
        try
            [rob, ~] = STL_Eval(this.BrSys.Sys, this.Spec, tmpP, tmpP.traj,t_phi);

            testronInitRes(k) = rob;
            testronAndPlusRes(k) = robAndPlus;
            testronX0(:,k) = paramValues;
        catch ME
            % Sometimes, we haven't logged all signals needed for the specific
            % requirement
            testronInitRes(k) = inf(size(testronInitRes(k)));
            testronAndPlusRes(k) = inf(size(testronAndPlusRes(k)));
            testronX0(:,k) = paramValues;
        end
    end
else
    % Serial computations
    for k = size(storedFval,2) + 1:nTrajectoriesPreCalculated
        if mod(k,50)==0
            fprintf(['(' num2str(k) ' finished)\n']);
        end
        load(['trajectories/' num2str(k) '.mat']); % Loads tmpP, paramValues
        try
            % First, perform standard robustness calculation
            evalin('base','objToUse = ''standard'';');
            [rob, ~] = STL_Eval(this.BrSys.Sys, this.Spec, tmpP, tmpP.traj,t_phi);
            
            % Then, perform robustness calculation with &+
            evalin('base','objToUse = ''&+'';');
            [robAndPlus, ~] = STL_Eval(this.BrSys.Sys, this.Spec, tmpP, tmpP.traj,t_phi);
            
            testronInitRes(k) = rob;
            testronAndPlusRes(k) = robAndPlus;
            testronX0(:,k) = paramValues;
            fprintf('.');
        catch ME
            % Sometimes, we haven't logged all signals needed for the specific
            % requirement
            testronInitRes(k) = inf(size(testronInitRes(k)));
            testronAndPlusRes(k) = inf(size(testronAndPlusRes(k)));
            testronX0(:,k) = paramValues;
            numFailed = numFailed + 1; % Set the flag
            fprintf('x');
            %break;
        end
    end
end
fprintf('\n');
timeToEvaluateTrajs = toc;
disp(['TESTRON: ' num2str(nTrajectoriesPreCalculated) ' robustness calculations completed in ' ...
    num2str(timeToEvaluateTrajs) ' seconds (failed ' ...
    num2str(numFailed) '/' num2str(nTrajectoriesPreCalculated) ...
    ' evaluations)']);

% Store the number of parameters used
numParams = size(X0,1);
save('numParams.mat', 'numParams');

evalin('base','objToUse = ''standard'';');
res = FevalInit(this, X0);

evalin('base','objToUse = ''&+'';');
andPlusProblem = this.copy();
andPlusProblem.verbose = 0;
resAndPlus = FevalInit(andPlusProblem, X0);
evalin('base', 'objToUse = ''standard'';');

res.fval = [testronInitRes, res.fval];
storedFval = res.fval;
resAndPlus.fval = [testronAndPlusRes, resAndPlus.fval];
storedAndPlusVal = resAndPlus.fval;
X0 = [testronX0, X0];
storedX0 = X0;


save(['robValues/' currentReq '.mat'], 'storedFval', 'storedAndPlusVal', 'storedX0');
% END JOHAN ADDED
this.solver_options.start_at_trial = this.solver_options.start_at_trial+this.solver_options.nb_new_trials;

if (this.solver_options.nb_local_iter>0) && (~this.stopping)
    fun_obj = @(x)(min(this.objective(x),[],1)); % for multi-objective support

    rfprintf_reset()
    if ~strcmp(this.display,'off')   
        fprintf('\nStarting local optimization using Nelder-Mead algorithm\n');
        this.display_status_header();
    end
    % Collect and sort solutions
    [~, ibest] = sort(max(res_init.fval,[],1));
    options = optimset(this.solver_options.local_optim_options, 'MaxIter',this.solver_options.nb_local_iter);
    flag_Cont = true;
    if this.use_parallel&&false % FIXME: behavior need be more thoroughly tested/verified 
        num_works = this.BrSys.Sys.Parallel;
        options = optimset(options, 'Display', 'off');
        options = optimset(options, 'UseParallel', true);
        while flag_Cont
            fun = @(x0) optimize(...
                fun_obj,x0,this.lb,this.ub,this.Aineq,this.bineq,this.Aeq,this.beq,[],[],options,'NelderMead');
            for idx = 1:num_works
                x0 = X0(:,idx);
                F(idx) = parfeval(fun, 4, x0);
            end
            for idx = 1:num_works
                [completedIdx, x, fval, exitflag, output] = fetchNext(F); 
                res{end+1} = struct('x',x, 'fval',fval, 'exitflag', exitflag,  'output', output);
                % update the nb_obj_eval
                this.nb_obj_eval = this.nb_obj_eval + output.funcCount;
                this.X_log = [this.X_log output.logs];
                if fval < 0 || this.nb_obj_eval > this.max_obj_eval
                    cancel(F);
                    flag_Cont = false;
                    break;
                end
            end
            
        end 
    else

        for i_loc = ibest
            x0 = X0(:,i_loc);           
            if ~this.stopping()
                options = optimset(options, 'Display', 'off');
                [x, fval, exitflag, output] = optimize(...
                    fun_obj, x0 ,this.lb,this.ub,this.Aineq,this.bineq,this.Aeq,this.beq,[],[],options,'NelderMead');
                res{end+1} = struct('x',x, 'fval',fval, 'exitflag', exitflag,  'output', output);
            end
       end
    end
end

end
