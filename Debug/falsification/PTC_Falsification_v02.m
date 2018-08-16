% This script runs a sequence of falsification analyses for a powertrain
% control (PTC) benchmark model.
%
% J. Kapinski
% 8-2018

clear;
InitBreach;

fuel_inj_tol = 1.0; 
MAF_sensor_tol = 1.0;
AF_sensor_tol = 1.0; 
pump_tol = 1.;
kappa_tol=1; 
tau_ww_tol=1;
fault_time=50;
kp = 0.04;
ki = 0.14;

warning('off', 'Simulink:LoadSave:EncodingMismatch')
mdl = 'AbstractFuelControl';

BrAFC = BreachSimulinkSystem(mdl, 'all', [], {}, [], 'Verbose',0,'SimInModelsDataFolder', false); 

%% 
% First we create the parameter search domain and load specifications. 

STL_ReadFile('AFC_example_spec.stl');

%% Piecewise constant input signal

pedal_angle_gen = fixed_cp_signal_gen({'Pedal_Angle'}, ... % signal name
                                       3,...                % number of control points
                                      {'previous'});       % interpolation method 
                                  
engine_gen = constant_signal_gen({'Engine_Speed'}); 

InputGen = BreachSignalGen({pedal_angle_gen, engine_gen});   
                                  
InputGen.SetParam({'Pedal_Angle_u0','Pedal_Angle_u1','Pedal_Angle_u2','Engine_Speed_u0'},...
                   [30 30 30 1000]);
               
BrAFC.SetInputGen(InputGen);

BrAFC.SetParamRanges({'Pedal_Angle_u0', 'Pedal_Angle_u1','Pedal_Angle_u2','Engine_Speed_u0'}, [10 60; 10 60; 10 60; 900 1100 ]);

%% Stating and Solving a Falsification Problem

AFC_Falsify = BrAFC.copy();

AFC_Falsify = FalsificationProblem(AFC_Falsify, Overshoot_req);
AFC_Falsify.setup_solver('cmaes');
AFC_Falsify.solve();
               
figure; AFC_Falsify.BrSet_Best.PlotRobustSat(Overshoot_req); % Plot best robustness


%% Stating and Solving the Same Falsification Problem, but with Combined IO Robustness

AFC_Falsify_Rio = BrAFC.copy();

AFC_Falsify_Rio = FalsificationProblem(AFC_Falsify_Rio, Overshoot_req);
AFC_Falsify_Rio.set_IO_robustness_mode('combined');
AFC_Falsify_Rio.setup_solver('cmaes');
AFC_Falsify_Rio.solve();
               
figure; AFC_Falsify_Rio.BrSet_Best.PlotIORobustSat(Overshoot_req,'out','rel'); % Plot best robustness
figure; AFC_Falsify_Rio.BrSet_Best.PlotIORobustSat(Overshoot_req,'in','abs'); % Plot best robustness

