function [val_opt, Popt]  = SOptimProp(Sys, P, prop, opt)
%
% SOPTIMPROP optimizes the satisfaction of a property
%
% Synopsis: [val_opt, Popt]  = SOptimProp(Sys, P0, phi, opt)
%
% Input:
%    - P0 is a parameter set for Sys. Parameter values in P0 are used for
%                  initializing the optimization algorithm
%    - phi is a QMITL property
%    - opt is an option structure with the following fields :
%
%        - tspan  : the time domain computation of the trajectories
%        - tau    : time for the evaluation of phi (default first tspan
%                   value)
%        - params : (mandatory) variable (search) parameters
%        - lbound : (mandatory) lower bounds for the search domain
%        - ubound : (mandatory) upper bounds for the search domain
%        - MaxIter : (mandatory) max number of optimization iteration
%        - OptimType : 'Max' (default), 'Min' or 'Zero'
%        - StopWhenFound : set to 1 to compute satisfaction for initial
%                          parameters in P0 then stops whenever  a positive
%                          ('Max') or negative ('Min') solution is found
%        - StopWhenFoundInit : same as above except that it does not
%                              necessarily compute all trajectories in P0
%
% Output:
%    - val_opt : the truth value of phi for the param set Sopt. It is a
%                scalar if StopWhenFound or StopWhenFoundInit it sets to 1.
%                Otherwize, it is a vector of size 1 x size(P.pts,2).

%    - Popt    : if StopWhenFound or StopWhenFoundInit is set to 1, and a
%                set of parameter values leading to a negative (resp.
%                positive) truth value of phi is found, Popt is this
%                parameter set.
%                Otherwize, it contains the optimum found for each set of
%                parameter values in P.

%% process options

global Ptmp; % temporary param set used to get non variables parameter values in optim func
global found; % non empty if we found a positive or negative truth value of prop
global StopWhenFound; % cf doc
global fopt; % best truth value of prop found for the current initial set of value in P
global traj_opt; % trajectory leading to fopt truth value of prop

found = [];
if isfield(opt, 'tspan')
    tspan = opt.tspan;
elseif isfield(Sys, 'tspan')
    tspan = Sys.tspan;
elseif isfield(P, 'traj')
    tspan = P.traj(1).time;
else
    tspan = 0:.2:10;
end

if isfield(opt,'tau')
    tau = opt.tau;
    if tspan(1) > tau
        tspan = [tau tspan];
    end
else
    tau = tspan(1);
end

if isfield(opt,'params')
    dim = FindParam(P,opt.params);
    dim = dim(dim<size(P.pts,1)); % keep only existing parameters (either system or constraint parameter)
else
    dim = P.dim;
end

if isfield(opt,'OptimType')
    OptimType = lower(opt.OptimType); % to avoid case mistake, we convert to lower case
else
    OptimType = 'max';
end

if isfield(opt,'MaxIter')
    MaxIter = opt.MaxIter;
end

if isfield(opt,'StopWhenFound')
    StopWhenFound = opt.StopWhenFound;
else
    StopWhenFound = 0;
end

if isfield(opt,'StopWhenFoundInit')
    StopWhenFoundInit = opt.StopWhenFoundInit;
    StopWhenFound = StopWhenFound | StopWhenFoundInit;
else
    StopWhenFoundInit = 0;
end

%% Initial values
options = optimset('MaxIter', MaxIter);

if (StopWhenFoundInit)
    rfprintf_reset();
    val = zeros(1,size(P.pts,2));
    for i = 1:size(P.pts, 2)
        Ptmp = Sselect(P,i);
        Ptmp = ComputeTraj(Sys, Ptmp, tspan);
        val(i) = QMITL_Eval(Sys, prop, Ptmp, Ptmp.traj, tau);
        status = ['Init ' num2str(i) '/' num2str(size(P.pts, 2)) ' Robustness value: ' num2str(val(i))];
        rfprintf(status);
        
        switch OptimType
            case 'max'
                if val(i)>0
                    val_opt = val(i);
                    Popt = Ptmp;
                    return;
                end
                
            case 'min'
                if val(i)<0
                    val_opt = val(i);
                    Popt = Ptmp;
                    return;
                end
        end
        
        if i==1
            Popt = Ptmp;
        else
            Popt = SConcat(Popt, Ptmp);
        end
    end
else
    Popt = ComputeTraj(Sys, P, tspan);
    [Popt, val] = SEvalProp(Sys, Popt, prop, tau);
    Ptmp = Sselect(Popt,1);
end


switch OptimType
    case 'max'
        [~, iv] = sort(-val);
        fun = @(x) fun_max(x, Sys, prop, tspan, tau);
        if val(iv(1))>0 % if the highest value is positive
            found = val(iv(1));
        end
        
    case 'min'
        [~, iv] = sort(val);
        fun = @(x) fun_min(x, Sys, prop, tspan, tau);
        if val(iv(1))<0 % if the lowest value is negative
            found = val(iv(1));
        end
        
    case 'zero'
        [~, iv] = sort(abs(val));
        fun = @(x) fun_zero(x, Sys, prop, tspan, tau);
end

if (StopWhenFound)&&(~isempty(found))
    Popt = Sselect(Popt,i);
    val_opt = found;
    return ;
end

%% Main Loop
val_opt = val(iv(1));

if (MaxIter==0)
    return;
end

val_opt = zeros(numel(iv)); % avoid to increase val_opt size in the loop
k=0;
for i = iv
    k = k+1;
    if isfield(opt, 'lbound')
        lbound = opt.lbound;
    else
        lbound = P.pts(dim,i)-P.epsi(:,i);  % ERROR : THE ORDER OF params AND P.dim MAY DIFFER !!
    end
    
    if isfield(opt, 'ubound')
        ubound = opt.ubound;
    else
        ubound = P.pts(dim,i)+P.epsi(:,i);  % ERROR : THE ORDER OF params AND P.dim MAY DIFFER !!
    end
    
    fprintf('\nOptimize from init point %d/%d Initial value: %g\n', k, numel(iv), val(i));
    rfprintf_reset();
    x0 = P.pts(dim,i);
    fopt = val(i); % we initialize with the only truth value computed for this set of values
    traj_opt = Popt.traj(Popt.traj_ref(i));           % <--- !!! NOT SURE OF THAT (but I guess it is correct)
    [x, val_opt(k)] = optimize(fun,x0,lbound,ubound,[],[],[],[],[],[],options,'NelderMead');
    fprintf('\n');
    Popt.pts(dim,i) = x;
    Popt.traj(Popt.traj_ref(i)) = traj_opt;
    Popt.Xf(:,i) = traj_opt.X(:,end);
    
    if (StopWhenFound)&&(~isempty(found))
        Popt = Sselect(Popt,i);
        val_opt = val_opt(k);
        break ;
    end
end

% max function returns the opposite of the truth value
if strcmp(OptimType,'max')
    val_opt = -val_opt;
end


end

function val = fun_max(x, Sys, prop, tspan, tau)
global Ptmp fopt traj_opt found StopWhenFound

if (~isempty(found)&&StopWhenFound) %positive value found, do not need to continue
    val = -found; % optimize tries to minimize the objective function, so
    return ;          % we provide it -val instead of val
end

Ptmp.pts(Ptmp.dim)=x;
Ptmp = ComputeTraj(Sys, Ptmp, tspan);
val = QMITL_Eval(Sys, prop, Ptmp, Ptmp.traj(1), tau);

if (val>0)
    found = val;
end

if (val>fopt)
    fopt = val;
    traj_opt = Ptmp.traj;
end

status = ['Robustness value: ' num2str(val) ' Current optimal: ' num2str(fopt)];
rfprintf(status);
val = -val; % optimize tries to minimize the objective function, so we
            % provide it -val instead of val
end

function val = fun_min(x, Sys, prop, tspan, tau)
global Ptmp found StopWhenFound fopt traj_opt

if (~isempty(found)&&StopWhenFound) %negative value found, do not need to continue
    val = found;
    return ;
end

Ptmp.pts(Ptmp.dim)=x;
Ptmp = ComputeTraj(Sys, Ptmp, tspan);
val = QMITL_Eval(Sys, prop, Ptmp, Ptmp.traj(1), tau);

if (val<0)
    found = val;
end

if (val<fopt)
    fopt = val;
    traj_opt = Ptmp.traj;
end

status = ['Robustness value: ' num2str(val) ' Current optimal: ' num2str(fopt)];
rfprintf(status);
end

function val = fun_zero(x, Sys, prop, tspan, tau)
global Ptmp fopt traj_opt
Ptmp.pts(Ptmp.dim)=x;
Ptmp = ComputeTraj(Sys, Ptmp, tspan);
val = QMITL_Eval(Sys, prop, Ptmp, Ptmp.traj(1), tau);
status = ['Robustness value: ' num2str(val) ];
rfprintf(status);
if (abs(val)<fopt)
    fopt = abs(val);
    traj_opt = Ptmp.traj;
end

val = abs(val);

end

