classdef BreachOpenSystem < BreachSystem
    % BreachOpenSystem  a BreachSystem derivated class with an input generator.
    %
    %   BreachOpenSystem Properties
    %        InputGenerator - BreachSystem generating inputs.
    %
    %   BreachOpenSystem Methods
    %        SetInputGen - takes a BreachSystem as argument and makes it the input generator.
    %                      Can be seen as serial composition of two BreachSystems.
    %        Sim         - the Sim method for BreachOpenSystems accepts
    %                      input as a third argument, when given, it bypasses
    %                      the input generator. The input format is an array
    %                      where the first column is time.
    %
    %See also signal_gen
    
    properties
        InputMap       % Maps input signals to idx in the input generator
        InputGenerator % BreachSystem responsible for generating inputs
        use_precomputed_inputs = false % if true, will fetch traces in InputGenerator  
    end
    
    methods
        
        function  this = BreachOpenSystem(varargin)
            this=this@BreachSystem(varargin{:});
        end
        
        function Sim(this,tspan,U)

            evalin('base', this.InitFn);
            this.CheckinDomainParam();
            
            if this.use_precomputed_inputs % Input generator drives the thing 
                ig_params  = this.InputGenerator.GetSysParamList();
                all_pts_u = this.InputGenerator.GetParam(ig_params);
                this.SetParam(ig_params, all_pts_u);
            end
            
            if ~exist('tspan','var')
                if this.hasTraj()
                    tspan = this.P.traj{1}.time;
                else
                    tspan = this.Sys.tspan;
                end
            end
            Sys = this.Sys;
            if exist('U','var') % in this case, the InputGenerator becomes a trace object
                % TODO: handles multiple input signals - or use an
                % from_workspace_signal_gen?
                
                if isnumeric(U)
                    DimU = this.InputMap.Count();
                    if size(U, 2)~=DimU+1;
                        err_msg= fprintf('Input must be an array with %d columns, first one being time.',DimU);
                        error(err_msg);
                    end
                    Us.t = U(:,1);
                    Us.u = U(:,2:end);
                else
                    Us = U;
                end
                InputGen = BreachTraceSystem(this.InputMap.keys,U);
                this.SetInputGen(InputGen);
                Sys = this.Sys;
                Sys.init_u = @(~, pts, tspan) (Us);
            end
            
            this.P = ComputeTraj(Sys, this.P, tspan);

            this.CheckinDomainTraj();
            if this.verbose>=1
                this.dispTraceStatus();
            end
        end
        
        % we merge parameters of the input generator with those of the
        % system, but keep both BreachObjects
        function SetInputGen(this, IG)
            % BreachOpenSystem.SetInputGen Attach a BreachSystem as input generator.
                        
            % look for property parameters and save them
            PropParams={};
            if ~isempty(this.P)
                PropParams = this.P.ParamList(this.P.DimP+1:end);
                PropParamsValues = GetParam(this.P, PropParams);
            end
            
            inputs = this.Sys.InputList;
            
            % First remove parameters from previous input generator
            Sys = this.Sys;
            idx_prev_inputs = this.GetParamsInputIdx();
            if (~isempty(idx_prev_inputs))
                idx_not_prev_inputs = boolean(ones(1, numel(Sys.ParamList)));
                idx_not_prev_inputs(idx_prev_inputs) = 0;
                Sys.ParamList = Sys.ParamList(idx_not_prev_inputs);
                Sys.p = Sys.p(idx_not_prev_inputs);
                Sys.DimP = numel(Sys.ParamList);
                this.Sys = Sys;
                this.Domains = this.Domains(idx_not_prev_inputs); % remove domains as well
            end
            
            if ischar(IG)
                pref = 'UniStep';
                if regexp(IG, [pref '[0-9]+'])
                    cp = str2num(IG(numel(pref)+1:end));
                    IG = struct('type','UniStep','cp', cp*ones(1, numel(inputs)));
                else
                    pref = 'VarStep';
                    if regexp(IG, [pref '[0-9]+'])
                        cp = str2num(IG(numel(pref)+1:end));
                        IG = struct('type','VarStep','cp', cp*ones(1, numel(inputs)));
                    end
                end
            end
            
            % IG can be a struct, a signal generator, or a BreachSystem
            DimU = this.InputMap.Count;
            if (isstruct(IG))
                if ~isfield(IG,'type')
                    error('Input generator must be a struct with fields ''type'', ''cp'' at least')
                end
                
                if isscalar(IG.cp)
                    IG.cp = IG.cp*ones(1, DimU);
                end
                
                if ~isfield(IG,'method')
                    IG.method= 'previous';
                end
                
                if ischar(IG.method)
                    IG.method = {IG.method};
                end
                
                if numel(IG.method)==1
                    method = IG.method{1};
                    IG.method = cell(1,DimU);
                    for iu = 1:DimU
                        IG.method{iu} = method;
                    end
                end
                
                switch(IG.type)
                    case 'UniStep'
                        sg = fixed_cp_signal_gen(inputs, IG.cp, IG.method);
                        IG = BreachSignalGen({sg});
                    case 'VarStep'
                        sg = var_cp_signal_gen(inputs, IG.cp, IG.method);
                        IG = BreachSignalGen({sg});
                end
            elseif iscell(IG)
                mm = methods(IG{1});
                if any(strcmp(mm,'computeSignals'))
                    IG = BreachSignalGen(IG);
                else
                    if ~any(strcmp(mm, 'Sim'))
                        error('Input generator should be a struct, a signal_gen, a cell array of signal_gen, or a BreachSignalGen object');
                    end
                end
            else
                mm = methods(IG);
                if any(strcmp(mm,'computeSignals'))
                    IG = BreachSignalGen({IG});
                else
                    if ~any(strcmp(mm, 'Sim'))
                        error('Input generator should be a struct, a signal_gen derived object or a BreachSignalGen object');
                    end
                end
            end
            
            % Check Consistency - IG must construct signals for all signals in this.InputList
            for input = this.InputMap.keys
                idx= FindParam(IG.Sys,input);
                if idx<=IG.Sys.DimX
                    this.InputMap(input{1}) = idx;
                else
                    error(['Input ' input{1} ' is not provided by input generator.']);
                end
            end
            
            this.InputGenerator = IG;
            
            % Adds parameters for new input generator
            i_params = IG.Sys.DimX+1:IG.Sys.DimP;
            this.Sys = SetParam(this.Sys, IG.Sys.ParamList(i_params), IG.P.pts(i_params,1));
            this.Sys.DimP = numel(this.Sys.ParamList);
            
            % Resets P and ranges
            this.SignalRanges = [];
            this.P = CreateParamSet(this.Sys);
            this.P.epsi(:,:) = 0;
            
            % Restore property parameter
            if ~isempty(PropParams)
                this.P = SetParam(this.P, PropParams, PropParamsValues);
            end
            % Sets the new input function for ComputeTraj
            % FIXME?: tilde?
            this.Sys.init_u = @(~, pts, tspan) (InitU(this,pts,tspan));
            
            % Copy Domains of input generator
            IGdomains = IG.GetDomain(IG.P.ParamList);
            for ip = 1:numel(IG.P.ParamList)
                parami = IG.P.ParamList{ip};
                [~, found] = FindParam(this.P, parami);
                if (found)
                    this.SetDomain(parami, IGdomains(ip));
                end
            end
            
            % Copy or init ParamSrc
            
            %% Init param sources, if not done already
            for ip = IG.P.DimX+1:numel(IG.P.ParamList)
                p  =IG.P.ParamList{ip};
                if IG.ParamSrc.isKey(p)
                    this.ParamSrc(p) = IG.ParamSrc(p);
                end
                if  ~this.ParamSrc.isKey(p)
                   this.ParamSrc(p) = BreachParam(p); 
                end
            end

        end
        
        function [params, idx] = GetPlantParamList(this)
            idx_inputs = this.GetParamsInputIdx();
            if isempty(idx_inputs)
                idx = this.Sys.DimX+1:this.Sys.DimP;
            else
                idx = this.Sys.DimX+1:idx_inputs(1)-1;
            end
            params = this.Sys.ParamList(idx);
        end
        
        function [params, idx] = GetInputParamList(this)
            idx = this.GetParamsInputIdx();
            params = this.P.ParamList(idx);
        end
        
        function idx = GetParamsInputIdx(this)
            if isempty(this.InputGenerator)
                [~, idx] = FindParamsInput(this.Sys);
            else
                ig_params = this.InputGenerator.Sys.DimX+1:this.InputGenerator.Sys.DimP;
                idx = FindParam(this.Sys, this.InputGenerator.Sys.ParamList(ig_params));
            end
        end
        
        function AddInputSpec(this, varargin)
            this.InputGenerator.AddSpec(varargin{:});
        end
        
        function SetInputSpec(this, varargin)
            this.InputGenerator.SetSpec(varargin{:});
            this.InputGenerator.AddSpec(varargin{:});
        end
        
        % calling the Input generator -
        % there might be saving to do if inputs are pre-generated
        function U = InitU(this, pts, tspan)
            
            idx_u = this.GetParamsInputIdx();
            pts_u = pts(idx_u);
            [~, ig_params]  = this.InputGenerator.GetSysParamList();
            
            if this.use_precomputed_inputs
                all_pts_u = this.InputGenerator.GetParam(ig_params);
                for ip =1:size(all_pts_u, 2)
                    if isequal(pts_u, all_pts_u(:,ip))
                        i_traj  = ip;
                        break
                    end
                end
                U.t = this.InputGenerator.P.traj{i_traj}.time';
                U.u= this.InputGenerator.P.traj{i_traj}.X';  % assumes only input generator has only the input signals
                                                                              % I know this will break on me eventually, hopefully not today   
            else
                
                this.InputGenerator.P = SetParam(this.InputGenerator.P,ig_params,pts_u); % FIXME: legacy use
                this.InputGenerator.Sim(tspan);
                
                % if an inputspec is violated, sabotage U into NaN
                if ~isempty(this.InputGenerator.Specs)
                    Uspecs = this.InputGenerator.Specs.values();
                    for ip = 1:numel(Uspecs)
                        rob = this.InputGenerator.CheckSpec(Uspecs{ip});
                        if rob<0
                            this.InputGenerator.addStatus(1,'input_spec_false', 'A specification on inputs is not satisfied.')
                            U.t=NaN;
                            U.u=NaN;
                            return;
                        end
                    end
                end
                
                U.t = this.InputGenerator.P.traj{1}.time;
                if size(U.t, 1)==1
                    U.t=U.t';
                end
                
                U.u = zeros(numel(U.t), this.InputGenerator.Sys.DimX);
                idx_mdl = 0;
                for input= this.Sys.InputList % Sys.InputList is in the same order as the model
                    idx_mdl = idx_mdl+1;
                    idx =  FindParam(this.InputGenerator.P, input{1});
                    U.u(:,idx_mdl) = this.InputGenerator.P.traj{1}.X(idx,:)';
                end
            end
        end
        
        function hsi = SetInputGenGUI(this)
            hsi= signal_gen_gui(this);
        end
        
        function idx = GetInputSignalsIdx(this)
            [idx, status] = FindParam(this.Sys, this.Sys.InputList);
            idx = idx(status~=0);
        end
        
        function PrintSignals(this)
            if isempty(this.SignalRanges)
                disp( '---  SIGNALS  ---')
                for isig = 1:this.Sys.DimX
                    fprintf('%s %s\n', this.P.ParamList{isig}, this.get_signal_attributes_string(this.P.ParamList{isig}));
                end
            else
                fprintf('---  SIGNALS  --- (%d traces)\n', numel(this.P.traj));
                for isig = 1:this.Sys.DimX
                    fprintf('%s %s in  [%g, %g]\n', this.Sys.ParamList{isig}, this.get_signal_attributes_string(this.P.ParamList{isig}),this.SignalRanges(isig,1),this.SignalRanges(isig,2));
                end
            end
            disp(' ');
            if ~isempty(this.sigMap)
                this.PrintAliases();
            end
        end
        
        function atts = get_signal_attributes(this, sig)
            % returns nature to be included in signature
            % should req_input, additional_test_data_signal,
            
            atts = {};
            [idx, found] = this.FindSignalsIdx(sig);
            if found
            sig = this.P.ParamList{idx}; 
            else
                atts = union(atts, {'unknown'});
            end
            
            if ismember(sig, this.InputGenerator.P.ParamList(1:this.InputGenerator.P.DimX))
                atts = union(atts,{'model_input'});
            elseif ismember(sig, this.P.ParamList(1:this.P.DimX))
                atts = union(atts, {'model_output'});
            end
        end
        
        function atts = get_param_attributes(this, param)
            % returns nature to be included in signature
            % should req_input, additional_test_data_signal,
            atts = get_param_attributes@BreachSet(this, param);
            
            if ismember(param, this.InputGenerator.P.ParamList(this.InputGenerator.P.DimX+1:end))
                atts = [atts {'input_param'}];
            else
                atts = [atts {'model_param'}];
            end
        end
    end
end

