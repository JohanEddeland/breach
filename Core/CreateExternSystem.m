function Sys = CreateExternSystem(name, vars, params, p0, simfn)
% CREATESYSTEM creates a system with or without custom external simulator     
%
% Synopsis: Sys = CreateSystem(name, vars, params, p0)
%  
% Creates a system structure Sys to be used with Breach and an external
% simulator, e.g. Simulink.  
% 
% Example:   
%
%   signals = {'s0','s1'};  % variables for signals values
%
%   params = {'p0','p1','p2'};  % parameters related to signal or to be
%                               % used in temporal logic formulas
%
%   p0 = [0 0 0 ];    % default for parameters p0,p1 and p2
%
%   Sys = CreateExternSystem(name, signals ,params, p0); % creates the Sys structure
%
  
  Sys.name = name;
  Sys.DimX = numel(vars);
  Sys.DimU =0; 
  Sys.DimP = numel(vars)+numel(params); 
  Sys.ParamList = {vars{:} params{:}};
  Sys.x0 = zeros(1,numel(vars));  
  
  if (~exist('p0'))
      Sys.p = zeros(1, Sys.DimP);
  else
      Sys.p = [Sys.x0 p0];
      Sys.x0(1:Sys.DimX)= p0(1:Sys.DimX); 
  end
  
  if exist('simfn','var')
      Sys.type = 'Extern';
      Sys.sim = simfn;
  else
      Sys.type = 'traces';
  end
  
  Sys.Dir = pwd;