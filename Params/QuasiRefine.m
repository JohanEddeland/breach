function P = QuasiRefine(P, nb, varargin)
%QUASIREFINE Sample quasi-uniformly a parameter set. The number of
% uncertain parameters must be lower or equal to 40 (when using Sobol).
%
% Synopsis:  P = QuasiRefine(P, nb[, step][, 'strictlyInside'][, algo])
%
% Inputs:
%  - P    : The parameter set to refine. May contain many parameter vectors
%  - nb   : how many parameter set are generated for each set of parameter
%           values. If lower or equal to one, nothing is done. If nb is not
%           an integer, it is rounded toward 0.
%  - step : (Optional, default=0) number of generated parameter to skip
%  - strictlyInside : (Optional, default=not set) If set (i.e., write
%                     'strictlyInside' in the function call), all generated
%                     parameter sets are strictly inside the initial one.
%                     Otherwise, the center of each generated parameter set
%                     are inside the initial one, but the associated boxes
%                     may overtake the initial one. TODO: THE
%                     strictlyInside OPTION IS NOT AVAILABLE WITH USE OF
%                     SOBOL ALGORITHM.
%  - algo : (Optional, default='Halton') String defining which algorithm
%           should be used to generate random number used to generate new
%           parameter sets. Can be either 'Halton' or 'Sobol'.
%
% Output:
%  - P : The new parameter set
%
% Example (Lorentz84):
%   CreateSystem;
%   P = CreateParamSet(Sys); % Create default parameter set for system Sys
%   Ph = QuasiRefine(P, 1000); % Sample with 1000 points
%
%   SplotBoxPts(P); % Parameter set before sampling
%   SplotPts(Ph);   % plots the generated points
%
%See also RandomLogRefine LogNRefine Refine
%

%  process inputs
if(nb<=1)
    return;
end
nb = floor(nb);

if(nargin==2) % no optional parameter
    step = 1;
    strictlyInside = false;
    algo = 'halton';
elseif(nargin==3) % one optional parameter
    if ischar(varargin{1})
        strictlyInside = strcmpi(varargin{1}, 'strictlyinside');
        if isMethodValid(varargin{1})
            algo = varargin{1};
        else
            algo = 'halton';
        end
        step = 1;
    else
        strictlyInside = false;
        algo = 'halton';
        step = varargin{1};
    end
elseif(nargin==4) % two optional parameters
    if ischar(varargin{1})
        step = 1;
        strictlyInside = true;
        if isMethodValid(varargin{2})
            algo = varargin{2};
        else
            algo = 'halton';
        end
    else
        step = varargin{1};
        strictlyInside = strcmpi(varargin{2}, 'strictlyinside');
        if isMethodValid(varargin{2})
            algo = varargin{2};
        else
            algo = 'halton';
        end
    end
else % all optional parameters
    step = varargin{1};
    strictlyInside = strcmpi(varargin{2}, 'strictlyinside');
    if isMethodValid(varargin{3})
        algo = varargin{3};
    else
        algo = 'halton';
    end
end

% JOHAN CHANGE
%if numel(P.dim) > 10
%if evalin('base', 'exist(''testron_useFile'')')
    disp('Changing algorithm to TestronRefine');
    algo = 'testron';
%end
%end
% END JOHAN CHANGE

if(strcmpi(algo,'sobol') && numel(P.dim)>40)
    warning('QuasiRefine:InappropriateAlgo',...
        'The sobol algorithm is usable up to dimension 40, switched to halton algorithm.');
    algo = 'halton';
end

% proceed the refine part
if strcmpi(algo,'sobol')
    if(strictlyInside)
        P = SobolRefine(P, nb, step, 'strictlyInside');
    else
        P = SobolRefine(P, nb, step);
    end
% JOHAN CHANGE
elseif strcmpi(algo,'testron')
    P = TestronRefine(P, nb, step);
% END JOHAN CHANGE
else % default = halton
    if(strictlyInside)
        P = HaltonRefine(P, nb, step, 'strictlyInside');
    else
        P = HaltonRefine(P, nb, step);
    end
end

% manage traj_ref and traj_to_compute: we make the supposition that no
% generated parameter vector is equal to an previously computed parameter
% vector
[~,P.traj_to_compute] = unique(P.pts(1:P.DimP,:)','rows','first');
P.traj_ref = zeros(1,size(P.pts,2));
P.traj_to_compute = sort(reshape(P.traj_to_compute,1,[]));

end

function valid = isMethodValid(str)
    valid = ( strcmpi(str,'halton') || strcmpi(str,'sobol') );
end

