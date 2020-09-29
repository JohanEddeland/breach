function [res, R] = ComputeMorrisSensi(R, B, num_path, objFunctions, randomSeed)
%% ComputeMorrisSensi compute sensitivities using Morris method for all requirement in R. Assumes B is a set with ranges.
%
%  Note: if B is a BreachSimulinkSystem with no traces, we compute the
%  Morris samples and corresponding traces and stores them in B. If B
%  already contains Morris samples and traces they are not re-computed.

if nargin < 5
    randomSeed = 1;
end

opt = struct('num_path', num_path, ...      % number of paths, i.e., set of
    ...                % samples providing 1 pair of samples per dim
    'rand_seed', randomSeed, ...    % random seed for reproducibility
    'size_grid', 100 ...     % number of grid levels, intervals in each dim
    );

[vars, iv] = B.GetVariables(); % variables and indices
    
if ~isfield(B.P, 'opt_morris')||~isequal(opt, B.P.opt_morris)  
    ranges = B.GetParamRanges(iv);    
    Sys= CreateSystem({},vars, ranges(:,1));
    P  = CreateParamSet(Sys, vars, ranges);        
    r = opt.num_path;
    p = opt.size_grid;
    s = opt.rand_seed;
    Pr = pRefine(P,p,r,s);
    X0 = Pr.pts;
    B.ResetParamSet;
    B.SetParam(vars, X0)
    B.P.opt_morris=opt;
    B.P.D = Pr.D;       
end

% Check if B is using parallel computation - in that case, do it for R as
% well
if isprop(B, 'use_parallel')
    R.Sys.use_parallel = B.use_parallel;
end

R.Eval(B, objFunctions);

for objFunctionCounter = 1:numel(objFunctions)
    for ir =  1:numel(R.req_monitors)
        res{objFunctionCounter, ir}.params = vars;        
        res{objFunctionCounter, ir}.rob = R.traces_vals(B.P.traj_ref,ir, objFunctionCounter)';
        [res{objFunctionCounter, ir}.mu, res{objFunctionCounter, ir}.mustar, res{objFunctionCounter, ir}.sigma, res{objFunctionCounter, ir}.sigmastar, res{objFunctionCounter, ir}.EE] = EEffects(res{objFunctionCounter, ir}.rob, B.P.D, opt.size_grid);
        %res{objFunctionCounter, ir}.R = R;
        %fprintf(['\nSensitivities for ' R.req_monitors{ir}.name]);
        %display_morris_result(res{objFunctionCounter, ir});
    end
end

end
