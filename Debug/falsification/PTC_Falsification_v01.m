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

pedal_angle_gen = pulse_signal_gen({'Pedal_Angle'}); % Generate a pulse signal for pedal angle

engine_gen = constant_signal_gen({'Engine_Speed'}); 
        
InputGen = BreachSignalGen({pedal_angle_gen, engine_gen});
                    
InputGen.SetParam({'Engine_Speed_u0'},...
                        [1100]);

InputGen.SetParam({'Pedal_Angle_base_value', 'Pedal_Angle_pulse_period', ...
                         'Pedal_Angle_pulse_amp','Pedal_Angle_pulse_width'}, ... 
                         [0 15 30 .5]);

BrAFC.SetInputGen(InputGen);

%% Creating a Falsification Problem
% Given a requirement R and some parameter range, we want to find a
% parameter value for which the system violates R.

%% 
% First we create the parameter search domain and load specifications. 
AFC_Falsify = BrAFC.copy();
AFC_Falsify.SetParamRanges({'Pedal_Angle_pulse_period', 'Pedal_Angle_pulse_amp','Engine_Speed_u0'}, [10 20; 10 60; 900 1100 ]);
STL_ReadFile('AFC_example_spec.stl');

%% 
% Then we create the falsification problem and solve it.
falsif_pb = FalsificationProblem(AFC_Falsify, Overshoot_req);
falsif_pb.solve();

%% 
% That's it. The default solver found a trace violating the specification
% AF_alw_ok. 

%% Getting and Plotting the Falsifying Trace

figure; falsif_pb.BrSet_Logged.PlotSignals; % Plot all traces
figure; falsif_pb.BrSet_Best.PlotSignals; % Plot best trace
figure; falsif_pb.BrSet_Best.PlotRobustSat(Overshoot_req); % Plot best robustness



%% Trying a Harder Falsification Instance
% We were able to falsify AF_alw_ok which says that AF should stay within 1% of
% AFref. What if we soften the requirement and make it 5% ? 

Overshoot_req2 = set_params(Overshoot_req, 'tol', 0.05);
falsif_pb2 = FalsificationProblem(AFC_Falsify, Overshoot_req2);
res = falsif_pb2.solve();

figure; falsif_pb2.BrSet_Logged.PlotSignals; % Plot all traces
figure; falsif_pb2.BrSet_Best.PlotSignals; % Plot best trace
figure;falsif_pb2.BrSet_Best.PlotRobustSat(Overshoot_req2); % Plot best robustness


%% Trying piecewise constant input signal

clear BrAFC pedal_angle_gen InputGen AFC_Falsify falsif_pb

BrAFC = BreachSimulinkSystem(mdl, 'all', [], {}, [], 'Verbose',0,'SimInModelsDataFolder', false); 

pedal_angle_gen      = fixed_cp_signal_gen({'Pedal_Angle'}, ... % signal name
                                       3,...                % number of control points
                                      {'previous'});       % interpolation method 

InputGen = BreachSignalGen({pedal_angle_gen, engine_gen});   
                                  
InputGen.SetParam({'Pedal_Angle_u0','Pedal_Angle_u1','Pedal_Angle_u2'},...
                   [20 20 20]);
               
BrAFC.SetInputGen(InputGen);

AFC_Falsify = BrAFC.copy();
AFC_Falsify.SetParamRanges({'Pedal_Angle_u0', 'Pedal_Angle_u1','Pedal_Angle_u2','Engine_Speed_u0'}, [10 60; 10 60; 10 60; 900 1100 ]);

falsif_pb = FalsificationProblem(AFC_Falsify, Overshoot_req);
falsif_pb.solve();
               
figure; falsif_pb.BrSet_Logged.PlotSignals; % Plot all traces
figure; falsif_pb.BrSet_Best.PlotSignals; % Plot best trace
figure; falsif_pb.BrSet_Best.PlotRobustSat(Overshoot_req); % Plot best robustness
