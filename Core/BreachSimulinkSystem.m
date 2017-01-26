classdef BreachSimulinkSystem < BreachOpenSystem
    % BreachSimulinkSystem Main class to interface Breach with Simulink systems
    %
    %   BrSys = BreachSimulinkSystem(mdl_name [,params, p0, signals, inputfn])
    %         
    %   Creates a BreachSystem interface to a Simulink model. 
    %
    %   Arguments: 
    %   mdl_name  -  a string naming a Simulink model.  
    %   params    -  cell array of strings | 'all'
    %   p0        -  (optional) default values for parameters
    %   signals   -  specifies signals to interface
    %   inputfn   -  specifies an input generator 
    %
    %   If params is not given or equal to 'all', the constructor will try 
    %   to discover automatically the tunable parameters in the model.
    %   If params is empty, then the only parameters for the model will be 
    %   input parameters (i.e., parameters used to generate input signals).
    %
    %   The constructor interfaces inputs, outputs and logged signals.
    %   Note that a BreachSimulinkSystem is a BreachOpenSystem, i.e., a 
    %   systems that can be composed with a BreachSignalGenerator for input
    %   generation. By default, a constant input generator is created for 
    %   each input of the model. Use SetInputGen method to set a different input. 
    %
    %
    %

    %See also BreachOpenSystem, signal_gen
    
    properties
        lookfor_scopes = false 
        sim_args = {}
    end
   
    methods
        
        function this = BreachSimulinkSystem(mdl_name, params, p0, signals, inputfn)

            if nargin==0
                return;
            end
            
            if ~exist(mdl_name)==4  %  create Simulink system with default options
                error('BreachSimulinkSystem first argument must be the name of a Simulink model.');
            end
            
            switch nargin
                case 1,
                    this.CreateInterface(mdl_name);
                case 2,
                    this.CreateInterface(mdl_name,params);
                case 3,
                    this.CreateInterface(mdl_name, params, p0);
                case 4, 
                    this.CreateInterface(mdl_name, params, p0, signals);
                case 5, 
                    this.CreateInterface(mdl_name, params, p0);
                    this.SetInputGen(inputfn);
            end
                    
            if isaSys(this.Sys) % Basically if interface was successfully created
                this.ParamRanges = [this.Sys.p(this.Sys.DimX+1:end) this.Sys.p(this.Sys.DimX+1:end)];
                this.SignalRanges = [];
                this.P = CreateParamSet(this.Sys);
                this.P.epsi(:,:) = 0;
            end
            
        end
        
        function SetupParallel(this)
           this.use_parallel = 1;
           gcp;
           this.Sys.Parallel = 1;
           spmd
             InitBreach;  
             gcs;   % loads simulink
             warning('off', 'Simulink:Commands:MdlFileChangedCloseManually'); % FIXME find out where the model is changed and not saved...
          end
        end    

        function CreateInterface(this, mdl, params, p0, signals)
                        
            %% Copy the model 
            %  Get Breach directory
            global BreachGlobOpt
            breach_dir = BreachGlobOpt.breach_dir;
            breach_data_dir = [breach_dir filesep 'Ext' filesep 'ModelsData' ];
            
            % Give it a name
            mdl_breach = [mdl '_breach']; 
            
            % Would be nice to check if mdl changed - could be done with
            % mdl.Get_CheckSum or sth similar
            load_system(mdl);
            close_system(mdl_breach,0);
            save_system(mdl,[breach_data_dir filesep mdl_breach]);
            close_system(mdl,0);
            load_system(mdl_breach);
            
            %% Adjust configuration parameters of the model
            cs = getActiveConfigSet(mdl_breach);
            
            % Do not change the order of the following commands. There are dependencies between the parameters.
            cs.set_param('GenerateReport', 'off');   % Create code generation report
            cs.set_param('LaunchReport', 'off');   % Open report automatically
            cs.set_param('OptimizeBlockIOStorage', 'on');   % Signal storage reuse
            cs.set_param('ExpressionFolding', 'on');   % Eliminate superfluous local variables (expression folding)
            cs.set_param('SaveFinalState', 'off');   % Final states
            cs.set_param('SignalLogging', 'on');   % Signal logging
            cs.set_param('SaveOutput', 'on');   % Output
            
            cs.set_param('LimitDataPoints', 'off');   % Limit data points to last
            cs.set_param('LoadExternalInput', 'on');   % Input
            cs.set_param('LoadInitialState', 'off');   % Initial state
            cs.set_param('ReturnWorkspaceOutputs', 'on');   % Save simulation output as single object
            
            %%  Solver pane - times
            t_end= str2num(cs.get_param('StopTime'));
            try
                t_step= str2num(cs.get_param('FixedStep'));
            catch % default fixed step is t_end/1000, unless MaxStep is set smaller
                t_step= t_end/1000;
                try
                    maxstep = cs.get_param('MaxStep');
                    t_step = min([t_step str2num(maxstep)]);
                catch
                end
            end
            
            cs.set_param('StartTime', '0.0');   % Start time
            cs.set_param('StopTime', 'tspan(end)');   % Stop time
            cs.set_param('SaveTime', 'on');   % Time
            cs.set_param('TimeSaveName', 'tout');   % Time
            
            %% Data Import/Export pane
            cs.set_param('ExternalInput', '[t__, u__]');   % Input
            cs.set_param('InspectSignalLogs', 'off');   % Record and inspect simulation output
            cs.set_param('OutputSaveName', 'yout');   % Output
            cs.set_param('ReturnWorkspaceOutputsName', 'out');   % Save simulation output as single object
            cs.set_param('SaveCompleteFinalSimState', 'off');   % Save complete SimState in final state
            cs.set_param('SaveFormat', 'StructureWithTime');   % Format
            cs.set_param('SignalLoggingName', 'logsout');   % Signal logging name
            
            if (verLessThan('matlab','R2011a'))
                error('Sorry, this version of Matlab is too old.')
            end
            cs.set_param('DSMLoggingName', 'dsmout');   % Data stores logging name
            cs.set_param('SignalLoggingSaveFormat', 'Dataset');   % Signal logging format
            
            %% Find and Log input signals
            
            in_blks = find_system(mdl_breach,'SearchDepth',1, 'BlockType', 'Inport');
            nb_inputs= numel(in_blks);
            sig_in = cell(1, nb_inputs);
            
            for iblk = 1:nb_inputs
                
                in_name = get_param(in_blks(iblk),'Name');
                in_name = regexprep(in_name,'\W','_');
                
                %Ensures port and its output line have the same name
                lh = get_param(in_blks(iblk), 'LineHandles');
                lh=lh{1}.Outport;
                set(lh, 'Name', in_name{1});
                
                %Get port number, makes sure sig_in is in the right order
                st_port_nb = get_param(in_blks(iblk),'Port');
                port_nb = str2num(st_port_nb{1});
                
                %Logs input
                set(lh,'DataLoggingName', 'Use signal name', 'DataLogging',1 ,'Name', in_name{1});
                sig_in{port_nb} = in_name{1};
            
            end
            
            if isempty(sig_in)
                pu = [];
                U.params = {};
                cs.set_param('LoadExternalInput', 'off');   % Input
            else
                const_input = constant_signal_gen(sig_in);
                U.params = const_input.params;
                pu = const_input.p0';
            end
            this.Sys.InputList= sig_in; % used by FindLoggedSignals 
            
            %% Find outputs
            o = find_system(mdl_breach,'SearchDepth',1, 'BlockType', 'Outport');
            
            sig_out= {};
            for i = 1:numel(o)
                nm = regexprep(o{i},[mdl_breach '/'],'');
                nm = regexprep(nm,'\W','_');
                sig_out = {sig_out{:}, nm};
                % ensure consistency of signal and output block name
                line_out = get_param(o{i}, 'LineHandles');
                set(line_out.Inport,'Name',nm);
                set_param(o{i},'Name', nm);
                
            end
                        
            %% Scope signals
            if this.lookfor_scopes
                sig_scopes = find_scope_signals(mdl_breach);
            end
            
            %% define parameters
            exclude = {'tspan','u__','t__'};
            assignin('base','tspan', 0:1);
        
            if ~exist('params','var')          
                [params, p0] = filter_vars(mdl_breach, exclude);
            elseif strcmp(params, 'all')
                [params, p0] = filter_vars(mdl_breach, exclude);               
            end 
            
            if ~exist('p0', 'var')||isempty(p0)
                p0 = zeros(1,numel(params));
            end
            
            params = [params U.params];
            
            %% find logged signals (including inputs and outputs)          
            this.Sys.mdl= mdl_breach;
            if ~exist('signals', 'var')
                signals = FindLoggedSignals(this);
                % Ensure inputs are at the end of signals:
                signals= setdiff(signals, sig_in);
                signals = [signals sig_in];
            else
                sig_log = FindLoggedSignals(this);
                found = ismember(signals, sig_log);
                
                if ~all(found)
                    not_found = find(~all(found));
                    warning('BreachSimulinkSystem:signal_not_found',['Signal ' signals{not_found} ' not found in model.']);  
                end
            end
            
            
            %% Create the Breach structure
            p0 = [zeros(1,numel(signals)) p0 pu];
            Sys = CreateSystem(signals, params, p0'); % define signals and parameters
            
            Sys.DimU = numel(sig_in);
            Sys.InputList= sig_in;
            Sys.InputOpt = [];
            
            Sys.type= 'Simulink';
            Sys.sim = @(Sys, pts, tspan) this.sim_breach(Sys,pts, tspan);
            Sys.mdl= [mdl '_breach'];
            Sys.Dir= breach_data_dir;
            Sys.tspan = 0:t_step:t_end;
            Sys.name = Sys.mdl;  % not great..
            
            save_system(mdl_breach);
            close_system(mdl_breach);
            
            this.Sys = Sys;
            
            % Initializes InputMap and input generator
            this.InputMap = containers.Map();
            idx=0;
            for input = this.Sys.InputList
                idx = idx+1;
                this.InputMap(input{1})=idx;
            end
            
            if (~isempty(sig_in))
                InputGen = BreachSignalGen({const_input});
                this.SetInputGen(InputGen);
            end     
        end
        
        function [tout, X] = sim_breach(this, Sys, tspan, pts)
            %
            % Generic wrapper function that runs a Simulink model and collect signal
            % data in Breach format (called by ComputeTraj)
            %
            
            mdl = Sys.mdl;
            load_system(mdl);
            num_signals = Sys.DimX;
            
            params = Sys.ParamList;
            for i = 1:numel(params)-num_signals
                assignin('base',params{i+num_signals},pts(i+num_signals));
            end
            
            assignin('base','tspan',tspan);
            if numel(tspan)>2
                set_param(mdl, 'OutputTimes', 'tspan',...
                    'OutputOption','SpecifiedOutputTimes');
            else
                set_param(mdl, 'OutputTimes', 'tspan',...
                    'OutputOption','RefineOutput');
            end
            
            try  
                if this.InputGenerator.statusMap.isKey('input_spec_false')
                    tout = this.InputGenerator.P.traj.time;
                    Xin = this.InputGenerator.P.traj.X;
                    X = NaN(Sys.DimX, numel(tout));
                    idx= this.GetInputSignalsIdx();
                    X(idx,:) = Xin;
                else
                    simout= sim(mdl, this.sim_args{:});
                    [tout, X] = GetXFrom_simout(this, simout);
                end
            catch
                s= lasterror;
                if numel(tspan)>1
                    tout = tspan;
                else
                    tout = [0 tspan];
                end
                warning(['An error was returned from Simulink:' s.message '\n Returning a null trajectory']);
                X = zeros(Sys.DimX, numel(tout));
            end
            this.InputGenerator.Reset()
        end
        
        function [tout, X] = GetXFrom_simout(this, simout)
            %
            % converts a simulink output to a data structure Breach can handle
            %
            
            signals= this.Sys.ParamList(1:this.Sys.DimX);           
            tout = simout.get('tout')';
            X=zeros(numel(signals), numel(tout));
            
            %% Outputs and scopes - go over logged signals and collect those we need
            Vars = simout.who;
            lenVars = numel(Vars);
            
            for iV = 1:lenVars
                Y = get(simout,Vars{iV});
                if ~isempty(Y)
                    
                    if ~strcmp(Vars{iV}, 'tout')&&~strcmp(Vars{iV},'logsout')&&(isstruct(Y))
                        for iS=1:numel(Y.signals)
                            
                            nbdim = size(double(Y.signals(iS).values),2);
                            signame = Y.signals(iS).label;
                            if (nbdim==1)
                                [lia, loc]= ismember(signame, signals);
                                if lia
                                    xx = interp1(Y.time, double(Y.signals(iS).values),tout, 'linear','extrap') ;
                                    X(loc,:) = xx;
                                end
                            else
                                for idim = 1:nbdim
                                    signamei = [signame '_' num2str(idim)  '_'];
                                    [lia, loc]= ismember(signamei, signals);
                                    if lia
                                        xx = interp1(Y.time, double(Y.signals(iS).values(:,idim)),tout, 'linear','extrap') ;
                                        X(loc,:) = xx;
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            %% logs - go over logged signals and collect those we need
            logs = simout.get('logsout');
            if ~isempty(logs)
                logs_names = logs.getElementNames();
                
                for ilg = 1:numel(logs_names)
                   
                    signame = logs_names{ilg};
                    sig = logs.getElement(signame);
                    nbdim = size(sig.Values.Data,2);

                    if (nbdim==1)
                        [lia, loc]= ismember(signame, signals);
                        if lia
                            xx = interp1(sig.Values.Time',double(sig.Values.Data(:,1)),tout, 'linear','extrap');
                            X(loc,:) = xx;
                        end
                    else
                        for idim = 1:nbdim
                            signamei = [signame '_' num2str(idim)  '_'];
                            [lia, loc]= ismember(signamei, signals);
                            if lia
                                xx = interp1(Y.time, double(Y.signals(iS).values(:,idim)),tout, 'linear','extrap') ;
                                X(loc,:) = xx;
                            end
                        end
                    end
                end
            end
        end
       
        
        function [tout, X, signals] = simout2X(this, simout)
            %
            % converts a simulink output to a data structure Breach can handle
            %
            
            tout = simout.get('tout')';
            X=[];
            
            %% Outputs and scopes
            Vars = simout.who;
            lenVars = numel(Vars);
            signals = {};
            
            for iV = 1:lenVars
                Y = get(simout,Vars{iV});
                if ~isempty(Y)
                    
                    if ~strcmp(Vars{iV}, 'tout')&&~strcmp(Vars{iV},'logsout')&&(isstruct(Y))
                        for iS=1:numel(Y.signals)
                            signame = Y.signals(iS).label;
                            if ~ismember(signame,signals)
                                
                                nbdim = size(double(Y.signals(iS).values),2);
                                try
                                    xx = interp1(Y.time, double(Y.signals(iS).values),tout, 'linear','extrap') ;
                                catch
                                    if (nbdim==1)
                                        xx = 0*tout;
                                    else
                                        xx = zeros(numel(tout), nbdim);
                                    end
                                end
                                
                                if (nbdim==1)
                                    X = [X; xx];
                                    signals = {signals{:} signame };
                                else
                                    X = [X; xx'];
                                    for idim = 1:nbdim
                                        signamei = [signame '_' num2str(idim)  '_'];
                                        signals = {signals{:} signamei};
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            logs = simout.get('logsout');
            
            if ~isempty(logs)
                logs_names = logs.getElementNames();
                
                %% logs
                for ilg = 1:numel(logs_names)
                    if ~(ismember(logs_names{ilg}, signals))
                        signame = logs_names{ilg};
                        if ~ismember(signame,signals)
                            
                            sig = logs.getElement(signame);
                            nbdim = size(sig.Values.Data,2);

                            % naming multidimensional signal= name_signal_i_
                            if nbdim==1
                                signals = {signals{:} signame};
                            else
                                for idim =1:nbdim
                                    signamei = [signame '_' num2str(idim)  '_'];
                                    signals = {signals{:} signamei};
                                end
                            end

                            
                            % getting signal data
                            for idim =1:nbdim
                                try
                                    xdata = interp1(sig.Values.Time',double(sig.Values.Data(:,idim)),tout, 'linear','extrap');
                                    X = [X ; xdata(1,:)];
                                end
                            end
                            
                        end
                    end
                end
            end
        end
       
        
        function sig_log = FindLoggedSignals(this)
            %
            % converts a simulink output to a data structure Breach can handle
            %
            
            %Run the model for time 0 to check proper initialization and collect signal names
            tspan = evalin('base', 'tspan;');
            assignin('base','tspan',[0 eps]);
            assignin('base','t__',0);
            assignin('base','u__',zeros(1, numel(this.Sys.InputList)));
            
            simout = sim(this.Sys.mdl);
            assignin('base','tspan',tspan);
            
            %% Outputs and scopes
            Vars = simout.who;
            lenVars = numel(Vars);
            sig_log = {};
            
            for iV = 1:lenVars
                Y = get(simout,Vars{iV});
                if ~isempty(Y)
                    
                    if ~strcmp(Vars{iV}, 'tout')&&~strcmp(Vars{iV},'logsout')&&(isstruct(Y))
                        for iS=1:numel(Y.signals)
                            signame = Y.signals(iS).label;
                            if ~ismember(signame,sig_log)
                                
                                nbdim = size(double(Y.signals(iS).values),2);
                                if (nbdim==1)
                                    sig_log = {sig_log{:} signame };
                                else
                                    for idim = 1:nbdim
                                        signamei = [signame '_' num2str(idim)  '_'];
                                        sig_log = {sig_log{:} signamei};
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            logs = simout.get('logsout');
            
            if ~isempty(logs)
                logs_names = logs.getElementNames();
                
                %% logs
                for ilg = 1:numel(logs_names)
                    if ~(ismember(logs_names{ilg}, sig_log))
                        signame = logs_names{ilg};
                        if ~ismember(signame,sig_log)
                            
                            sig = logs.getElement(signame);
                            nbdim = size(sig.Values.Data,2);
                            
                            % naming multidimensional signal= name_signal_i_
                            if nbdim==1
                                sig_log = {sig_log{:} signame};
                            else
                                for idim =1:nbdim
                                    signamei = [signame '_' num2str(idim)  '_'];
                                    sig_log = {sig_log{:} signamei};
                                end
                            end
                                                       
                        end
                    end
                end
            end
        end
        
        function disp(this)
            disp(['BreachSimulinkSystem intefacing model ' this.Sys.name '.']);
        end
        
        
        
    end
    
end
