function [P, val] = SEvalProp(Sys, P, phis, tau, ipts, bool_plot, break_level)
%SEVALPROP Eval property for previously computed trajectories
%
% Usage: [Pf, val] = SEvalProp(Sys, P, phis[ , tau[, ipts[, bool_plot[, break_level ]]]])
%
% Inputs:
%  - Sys         : system
%  - P           : Param set with trajectories
%  - phis        : QMITL property(ies)
%  - tau         : Time instant(s) when to estimate properties. If not
%                  provided, the time instants considered for computing the
%                  trajectory are used. It may be a scalar, in which case,
%                  all the formula are evaluated at this time point, or it
%                  may be an array of size 1 x numel(phis), thus
%                  indicating the time point of evaluation of each formula.
%  - ipts        : Indices of parameter vectors for which the properties is
%                  evaluated (Optional, Default=all parameter sets).
%  - break_level : (Optional) defines the depth of breaking of props. If
%                  lower or equal to 1, it is ignored. If greater or equal
%                  to two, SEvalProp answers the evaluation of the props
%                  and all sub-formula of props until the depth provided.
%
% Outputs:
%  - Pf  : param set with prop_namse, prop and prop_values fields
%  - val : an array containing the quantitative satisfaction of properties
%          for each trajectory at the first time point of tau. The
%          dimension of val is numel(props) x numel(ipts)
%
%See also QMITL_Formula CreateParamSet ComputeTraj Sselect
%


% check arguments

if ~exist('break_level','var')
    break_level = 0;
end

if(break_level>0)
    nprops = [];
    for ii = 1:numel(phis)
        broken_props = QMITL_Break(phis(ii),break_level);
        nprops = [ nprops broken_props(:) ]; %#ok<AGROW>
    end
    phis = nprops;
end

if ~exist('bool_plot','var')
    bool_plot = 0;
end

if(~exist('ipts','var')||isempty(ipts))
    ipts = 1:size(P.pts,2);
end

if ~exist('tau','var')
    tau = [];
elseif isscalar(tau)
    tau = ones(1,numel(phis))*tau;
end

%if ~iscell(props)
%    props = {props};
%end

if ~isfield(P,'props')
    P.props = [];
end

if ~isfield(P,'props_names')
    P.props_names = {} ;
end

if ~isfield(P,'traj_ref')
    P.traj_ref = 1:numel(P.traj);
end

% setup plots if needed
if(bool_plot)
    figure;
    nb_prop = numel(phis);
    if isfield(Sys,'time_mult')
        time_mult = Sys.time_mult;
    else
        time_mult = 1;
    end
end

val = zeros(numel(phis),numel(ipts)); %initialize array containing truth values for each property and each param set
props_values(1:numel(ipts)) = deal(struct()); % Temporary line containing the evaluation of the formula
for np = 1:numel(phis) % for each property
    
    phi = phis(np);  % phi = current formula
    phi_name =  get_id(phi);
    i_phi = find_prop(P,phi_name);
    
    if(bool_plot)
        subplot(nb_prop, 1, np);
        hold on;
        xlabel('tau');
        title(disp(phi), 'Interpreter','none');
    end
    
    if(i_phi==0)
        % if the property does not exist in P, we add it to P
        P.props_names = [P.props_names {phi_name}];
        P.props = [P.props phi];
        i_phi = numel(P.props_names);
    end
    
    phi = QMITL_OptimizePredicates(Sys,phi);
    fprintf(['Checking ' phi_name  '\n'...
             '[             25%%           50%%            75%%               ]\n ']);
    iprog = 0; %idx of progression bar
    
    for ii = ipts % we compute the truch value of prop for each param set
        traj_tmp = P.traj(P.traj_ref(ii));
        Ptmp = Sselect(P,ii);
        if isempty(tau)
            [props_values(ii).val, props_values(ii).tau] = QMITL_Eval(Sys, phi, Ptmp, traj_tmp);
        else
            [props_values(ii).val, props_values(ii).tau] = QMITL_Eval(Sys, phi, Ptmp, traj_tmp, tau(np));
        end
        val(np,ii) = props_values(ii).val(1);
        if isnan(val(np,ii))
            warning('SEvalProp:NaNEval','Warning: property evaluated to NaN');
        end
        
        while(floor(60*ii/numel(ipts))>iprog)
            fprintf('^');
            iprog = iprog+1;
        end
        
        % plot property values
        if(bool_plot)
            phi_tspan = props_values(ii).tau;
            phi_val = props_values(ii).val;
            plot(phi_tspan*time_mult, phi_val);
            plot([phi_tspan(1) phi_tspan(end)]*time_mult, [0 0],'-k');
            stairs(phi_tspan*time_mult, (phi_val>0)*max(abs(phi_val))/2,'-r','LineWidth', 4);
            YLim = get(gca, 'YLim');
            YLim(1) = min([-max(abs(phi_val))/2, YLim(1)]);
            set(gca,'YLim', YLim);
            grid on;
        end
    end
    P.props_values(i_phi,:) = props_values; % we copy all evaluation in once to avoid inconsistent parameter set
    
    fprintf('\n');
end

end

function idx = find_prop(P,st)
%FIND_PROP finds the index of a property in a parameter set.
%
% Synopsis: idx = find_prop(P,st)
%
% Input:
%  - P  the parameter set containing the evaluation of properties
%  - st a string describing the name of the searched property
%
% Output:
%  - the index of the property evaluation if found, 0 otherwize
%

if ~isfield(P,'props_names')
    idx = 0;
    return;
else
    for idx = 1:numel(P.props_names)
        if strcmp(st,P.props_names{idx})
            return;
        end
    end
end

idx=0; % in case it is not found

end

