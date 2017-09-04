function res = solve_global_nelder_mead(this)

% Global variable - objective function to use
global objToUse;

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
    objToUse = 'standard';
    parfor k = size(storedFval,2) + 1:nTrajectoriesPreCalculated
        % This loop performs standard robustness calculations
        loadedVars = load(['trajectories/' num2str(k) '.mat']); % Loads tmpP, paramValues
        tmpP = loadedVars.tmpP;
        paramValues = loadedVars.paramValues;
        try
            [rob, ~] = STL_Eval(this.BrSys.Sys, ... % Breach system
                this.Spec, ... % Specification
                tmpP, ... % Parameter set
                tmpP.traj, ... % Trajectory
                t_phi); % Time to evaluate objective function

            testronInitRes(k) = rob;
            testronX0(:,k) = paramValues;
        catch ME
            % Sometimes, we haven't logged all signals needed for the specific
            % requirement
            testronInitRes(k) = inf(size(testronInitRes(k)));
            testronX0(:,k) = paramValues;
            numFailed = numFailed + 1; % Set the flag
        end
    end
    
    objToUse = '&+';
    parfor k = size(storedFval,2) + 1:nTrajectoriesPreCalculated
        % This loop performs "And plus" robustness calculations
        loadedVars = load(['trajectories/' num2str(k) '.mat']); % Loads tmpP, paramValues
        tmpP = loadedVars.tmpP;
        paramValues = loadedVars.paramValues;
        try
            [robAndPlus, ~] = STL_Eval(this.BrSys.Sys, ... % Breach system
                this.Spec, ... % Specification
                tmpP, ... % Parameter set
                tmpP.traj, ... % Trajectory
                t_phi); % Time to evaluate objective function

            testronAndPlusRes(k) = robAndPlus;
        catch ME
            % Sometimes, we haven't logged all signals needed for the specific
            % requirement
            testronAndPlusRes(k) = inf(size(testronAndPlusRes(k)));
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
            objToUse = 'standard';
            [rob, ~] = STL_Eval(this.BrSys.Sys, ... % Breach system
                this.Spec, ... % Specification
                tmpP, ... % Parameter set
                tmpP.traj, ... % Trajectory
                t_phi); % Time to evaluate objective function
            
            % Then, perform robustness calculation with &+
            objToUse = '&+';
            [robAndPlus, ~] = STL_Eval(this.BrSys.Sys, ... % Breach system
                this.Spec, ... % Specification
                tmpP, ... % Parameter set
                tmpP.traj, ... % Trajectory
                t_phi); % Time to evaluate objective function
            
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

% Time to calculate for how long we should falsify
if nTrajectoriesPreCalculated > 0
    % We can calculate how long time this specific STL formula takes to
    % evaluate for each trajectory
    timePerTraj = timeToEvaluateTrajs/nTrajectoriesPreCalculated;
    
    % Assume simulation takes 60s, and we want 30min in total for this
    % requirement
    % We also want to give half of the time to global optimization, half to
    % local optimization
    
    % Time for global: (60s + timePerTraj)*n, where n is number of sampled
    % initial parameters X0
    % Setting equal to 1800s (=30m) gives n = 1800/(60 + timePerTraj)
    n_samples = floor(1800/(60 + timePerTraj));
else
    % We don't know how long this specific STL formula takes to calculate
    % robustness for one trajectory.
    % This only happens for the first falsification of a Simulink version
    % Solution: Guess n_samples
    n_samples = 60;
end


% Initialize the parameter vectors
X0 = init_basic_X0(this, n_samples);

% Store the number of parameters used
numParams = size(X0,1);
save('numParams.mat', 'numParams');

% Calculate when falsification will end
d = rem(now,1);
disp(['Starting falsification at ' datestr(d,13) ' with maximum time 1800 seconds.']);
disp(['Falsification will end by ' datestr(d + (1800/(24*3600)),13)]);

% We must add timeToEvaluateTrajs to the maximum time, since according to
% Breach the falsification has already started (but we see
% timeToEvaluateTrajs as a pre-process to falsification).
this.max_time = 1800 + timeToEvaluateTrajs;

% display header
fprintf('Eval objective function on %d initial parameters.\n', size(X0,2));

objToUse = 'standard';
res = FevalInit(this, X0);

andPlusProblem = this.copy();
andPlusProblem.verbose = 0;
objToUse = '&+';
resAndPlus = FevalInit(andPlusProblem, X0);

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
    rfprintf_reset()
    fprintf('Local optimization using Nelder-Mead algorithm\n');
    
    % Collect and sort solutions
    [~, ibest] = sort(res.fval);
    options = optimset(this.solver_options.local_optim_options, 'MaxIter',this.solver_options.nb_local_iter);
    for i_loc= ibest
        x0 = X0(:,i_loc);
        if ~this.stopping()
            optimize(@(x)this.objective_wrapper(x),x0 ,this.lb,this.ub,this.Aineq,this.bineq,this.Aeq,this.beq,[],[],options,'NelderMead');
        end
    end
end

end