%% init Breach
InitBreach;

%% Model setting
mdl = 'Autotrans_shift';
Br = BreachSimulinkSystem(mdl); 
Br.SetTime(0:.01:50); %time setep setting

%% Set log
Br.SetupDiskCaching('DiskCachingRoot', [pwd filesep 'allLogFalsify'], 'StoreTracesOnDisk', true);

%% define the formula
phi = STL_Formula('phi', '(alw (speed[t]<vmax)) and (alw (RPM[t]<rpm_max))');
phi = set_params(phi,{'vmax', 'rpm_max'}, [160 4500]);

%% define input generator
throttle_input_gen = fixed_cp_signal_gen('throttle', 4, 'previous');
brake_input_gen = fixed_cp_signal_gen('brake', 3, 'linear');
InputGen = BreachSignalGen({throttle_input_gen, brake_input_gen});
Br.SetInputGen(InputGen)
Br.PrintParams();

%% define domain
Br.SetDomain({'throttle_u0','throttle_u1','throttle_u2','throttle_u3'},'double',[0 100;0 100;0 100;0 100]); %same data type to all 4 cp
Br.SetDomain({'brake_u0','brake_u1','brake_u2'},'double',[0 1;0 1;0 1]); %again, same range to all 3 cp
                     
%% solve falsification
falsif_pb = FalsificationProblem(Br, phi);
falsif_pb.max_obj_eval = 20;  %overwrite max_obj_eval. (Defalut setting is inf.(BreachProblem.m))
falsif_pb.StopAtFalse = false;
falsif_pb.max_time = Inf;
% solves using the default solver
%falsif_pb.SetupParallel(4);
falsif_pb.freq_update = 1;  % Decide the frequency of display on the display
falsif_pb.solve();

%% Parallel Falsification and Logging
Bpb_log =falsif_pb.GetBrSet_Logged();
F = BreachSamplesPlot(Bpb_log)

%% collect the falsifying trace 
%BrFalse = falsif_pb.GetBrSet_False();
%Ffalse = BreachSamplesPlot(BrFalse)
