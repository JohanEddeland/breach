clear;
InitBreach;
 
M = csvread('Data_1.csv');
RPM = M(:,[1:2]);
speed = M(:,[1,3]);
t = transpose(M(:,1));
 
% Interface workspace data with a Breach object
workspace_data = from_workspace_signal_gen({'speed','RPM'});
B = BreachSignalGen({workspace_data});
B.Sim(t);
 
% define the formula
phi1 = STL_Formula('phi1', '(alw (speed[t]<vmax and speed[t]>=0)) and (alw (RPM[t]<rpm_max))');
phi1 = set_params(phi1,{'vmax', 'rpm_max'}, [160 4500]);
phi1 = set_out_signal_names(phi1, {'speed', 'RPM'});

% Set up the Breach requirement
MyReq = BreachRequirement(phi1);
[v, V] = MyReq.Eval_IO(B,'out','rel');
MyReq.Explain(B, phi1);
%MyReq.PlotRobustSat(phi1);



