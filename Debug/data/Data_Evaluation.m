clear;
InitBreach;
 
M = csvread('Data_1.csv');
x = M(:,[1:2]);
g = M(:,[1,3]);
t = transpose(M(:,1));
 
% Interface workspace data with a Breach object
workspace_data = from_workspace_signal_gen({'x','g'});
B = BreachSignalGen({workspace_data});
B.Sim(t);
 
% Load STL file and associate with the Breach object
STL_ReadFile('Data_Spec.stl');

% Compute qualitative and quantitative semantics
close all;
warning('off','STL_Eval:Inf_or_Nan');
figure; B.PlotRobustSat(phi);
figure; B.PlotIORobustSat(phi, 'in', 'rel');
figure; B.PlotIORobustSat(phi, 'in', 'abs');
figure; B.PlotIORobustSat(phi, 'out', 'rel');
figure; B.PlotIORobustSat(phi, 'out', 'abs');