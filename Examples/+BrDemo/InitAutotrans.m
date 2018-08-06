% Init Model with two inputs 

mdl = 'Autotrans_shift';
BrAutotrans_nominal = BreachSimulinkSystem(mdl);
BrAutotrans_nominal.SetTime(0:.01:40); % default simulation time
BrAutotrans_nominal.SetInputGen('VarStep2') 
BrAutotrans_nominal.PrintAll()

%% Set input values (other than 0) 
% Accelerate for 20 s at 100%
BrAutotrans_nominal.SetParam( 'throttle_dt0', 20);
BrAutotrans_nominal.SetParam( 'throttle_u0', 100);
BrAutotrans_nominal.SetParam( 'brake_u0', 0);
BrAutotrans_nominal.SetParam( 'brake_dt0', 20);
     
% Brake ever after
BrAutotrans_nominal.SetParam( 'throttle_u1', 0);
BrAutotrans_nominal.SetParam( 'brake_u1', 325);

%% Ranges
BrAutotrans_ranges = BrAutotrans_nominal.copy();

% Acceleration
BrAutotrans_ranges.SetParamRanges( 'throttle_u0', [0 100]);
BrAutotrans_ranges.SetParamRanges( 'throttle_dt0', [0 40]);
BrAutotrans_ranges.SetParamRanges( 'throttle_u1', [0 100]);
     
% Braking
BrAutotrans_ranges.SetParamRanges( 'brake_u0', [0 325]);
BrAutotrans_ranges.SetParamRanges( 'brake_dt0', [0  20]);
BrAutotrans_ranges.SetParamRanges( 'brake_u1', [0 325]);
