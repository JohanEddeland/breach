classdef BreachSamplesPlot < handle
    
    properties
        BrSet
        Fig
        params
        data
        summary
        ax
    end
        
    
    properties (Access=protected)
        x_axis = 'idx'
        y_axis = 'auto'
        z_axis
        idx_tipped
        pos_plot
        neg_plot
        all_plot
    end
    
    methods
        
        function this = BreachSamplesPlot(BrSet, params)
        % BreachSamplesPlot Initial implementation meant to navigate the summary of a BreachRequirement evaluation    
            switch nargin
                case 0
                    return;
            end
            
            this.BrSet = BrSet;
            this.Fig = figure;
            
            if exist('params','var')
                if ischar(params)
                    this.params = {params};
                else
                    this.params =params;
                end
            else
                this.params = {};
            end
       
             this.summary = BrSet.GetSummary(); % all data should be there 
             this.update_plot();
        
        end
        
        function update_data(this)
            
            num_samples = this.summary.num_traces_evaluated;
            signature = this.summary.signature; 
            
            % variables
            if isfield(signature,'variables_idx')
                this.data.variables = signature.params(signature.variables_idx);
            else 
                this.data.variables = {};
            end
            
            vals = this.summary.requirements.rob;
            all_pts = 1:num_samples;
            
            this.data.all_pts.idx = all_pts;
            
            % satisfied requirements
            vals_pos = vals';
            vals_pos(vals'<=0) = 0;
            
            % falsified requirements
            vals_neg = vals';
            vals_neg(vals'>=0) = 0;
             
            % idx pos and neg
            num_vals_pos = sum(vals_pos>=0&vals_neg==0,1);
            num_vals_neg = sum(vals_neg<0,1);
            idx_pos = num_vals_pos  >0;
            idx_neg = num_vals_neg >0; 
            
            if any(idx_pos)
                this.data.pos_pts.idx_traj= all_pts(idx_pos);
                this.data.pos_pts.idx = arrayfun(@(c)(find(this.BrSet.P.traj_ref==c,1)),this.data.pos_pts.idx_traj);
                this.data.pos_pts.v_sum_pos = sum(vals_pos(:,idx_pos),1);
                this.data.pos_pts.v_num_pos = num_vals_pos(idx_pos);
            end
            
            if any(idx_neg)
                this.data.neg_pts.idx_traj= all_pts(idx_neg);
                this.data.neg_pts.idx = arrayfun(@(c)(find(this.BrSet.P.traj_ref==c,1)),this.data.neg_pts.idx_traj);
                this.data.neg_pts.v_sum_neg = sum(vals_neg(:, idx_neg),1);
                this.data.neg_pts.v_num_neg = -num_vals_neg(idx_neg);
            end
              
        end
        
        function update_plot(this)
            
            this.update_data();
            figure(this.Fig);
            if isempty(this.ax)
                this.ax = axes();
            else
                axes(this.ax)
            end
            cla;
            grid on;
    
            %% Are we plotting a BreachSet or BreachRequirement?
            % checks if there's any pos or neg stuff
            has_pos = isfield(this.data, 'pos_pts'); 
            has_neg = isfield(this.data, 'neg_pts');
            if has_pos||has_neg
                if has_pos 
                    pos_idx = this.data.pos_pts.idx;
                    pos_idx_traj = this.data.pos_pts.idx_traj;
                    switch this.x_axis
                        case 'idx'
                            xdata_pos = pos_idx_traj;
                        otherwise  % assumes parameter name
                            xdata_pos = this.BrSet.GetParam(this.x_axis, pos_idx);
                    end
                    
                    switch this.y_axis
                        case 'idx'
                            ydata_pos = pos_idx_traj;
                        case 'auto'
                            if strcmp(this.x_axis,'idx')&&(numel(this.BrSet.req_monitors)==1)||...
                                    has_neg&&~has_pos||...
                                    has_pos&&~has_neg
                                    ydata_pos = this.data.pos_pts.v_sum_pos;
                            else
                                ydata_pos = this.data.neg_pts.v_num_neg;
                            end
            
                        case 'sum'
                            ydata_pos = this.data.pos_pts.v_sum_pos;
                        case 'num'
                            ydata_pos = this.data.pos_pts.v_num_pos;
                        otherwise
                            ydata_pos = this.BrSet.GetParam(this.y_axis, pos_idx);
                    end
                end
                
                if has_neg
                    neg_idx = this.data.neg_pts.idx;
                    neg_idx_traj = this.data.neg_pts.idx_traj;

                    switch this.x_axis
                        case 'idx'
                            xdata_neg = neg_idx_traj;
                        otherwise  % assumes parameter name
                            xdata_neg = this.BrSet.GetParam(this.x_axis, neg_idx);
                    end
                    
                    switch this.y_axis
                        case 'idx'
                            ydata_neg = neg_idx;
                        case 'auto'
                            if strcmp(this.x_axis,'idx')&&(numel(this.BrSet.req_monitors)==1)||...
                                    has_neg&&~has_pos||...
                                    has_pos&&~has_neg
                                    ydata_neg = this.data.neg_pts.v_sum_neg;
                                    plot_sum();
                            else
                                ydata_neg = this.data.neg_pts.v_num_neg;
                                plot_num();
                            end
                        case 'sum'
                            ydata_neg = this.data.neg_pts.v_sum_neg;
                            plot_sum();
                        case 'num'
                            ydata_neg = this.data.neg_pts.v_num_neg;
                            plot_num();
                        otherwise
                            ydata_neg = this.BrSet.GetParam(this.y_axis, neg_idx);
                            plot_param();
                    end
                end
                
              if has_pos
                set(this.pos_plot, 'UserData', pos_idx_traj);
              end
              if has_neg
                set(this.neg_plot, 'UserData', neg_idx_traj);
              end
              
            else
                
            
            end
            
            function plot_param()
                if has_pos
                    this.pos_plot = plot(xdata_pos,ydata_pos,'.g', 'MarkerSize', 20);
                end
                hold on;
                if has_neg
                    this.neg_plot = plot(xdata_neg,ydata_neg,'.r', 'MarkerSize', 20);
                end
                grid on;
                xlabel(this.x_axis, 'Interpreter', 'None');
                ylabel(this.y_axis, 'Interpreter', 'None');
            end
            
            
            function plot_sum()
                if has_pos
                    this.pos_plot = plot(xdata_pos,ydata_pos,'.g', 'MarkerSize', 20);
                end
                hold on;
                if has_neg
                     this.neg_plot = plot(xdata_neg,ydata_neg,'.r', 'MarkerSize', 20);
                end
                grid on;
                xlabel(this.x_axis, 'Interpreter', 'None');
                ylabel('Cumulative satisfactions/violations');
            end
     
            function plot_num()
                if has_pos
                    ydata_pos = this.data.pos_pts.v_num_pos;
                    this.pos_plot = bar(xdata_pos, ydata_pos ,0.5,'g');
                end
                hold on;
                grid on;
                if has_neg
                    ydata_neg = this.data.neg_pts.v_num_neg;
                    this.neg_plot = bar(xdata_neg, ydata_neg ,0.5,'r');
                end
                xlabel(this.x_axis, 'Interpreter', 'None');
                ylabel('Num. requirement falsified/satisfied');
                set(gca, 'YLim', [min(ydata_neg)-.1, max(ydata_pos)+.1],  'Ytick', ceil(min(ydata_neg)-.1):1:floor(max(ydata_pos)+.1));
            end   
            h = title('Left click on data to get details, right click to plot signals/diagnosis', 'FontWeight', 'normal', 'FontSize', 10);
            
            
            %% Datacursor mode customization
            cursor_h = datacursormode(this.Fig);
            cursor_h.UpdateFcn = @myupdatefcn;
            cursor_h.SnapToDataVertex = 'on';
            datacursormode on
            
            function [txt] = myupdatefcn(obj,event_obj)
                pos = event_obj.Position;
                ipos = find(event_obj.Target.XData==pos(1)&event_obj.Target.YData==pos(2),1); 
                if isequal(this.neg_plot, event_obj.Target)
                    itraj = neg_idx_traj(ipos); 
                elseif isequal(this.pos_plot, event_obj.Target)
                    itraj = pos_idx_traj(ipos);
                elseif isequal(this.plot, event_obj.Target)
                    itraj = find(this.BrSet.P.traj_ref==ipos,1);
                end
                    
                this.idx_tipped = itraj;
           
                txt{1} = ['idx trace:' num2str(itraj)] ;
                
                for irr = 1:numel(this.summary.requirements.names)
                    txt{end+1} = [this.summary.requirements.names{irr} ':' num2str(this.summary.requirements.rob(itraj, irr))];
                end
                ipts = find(this.BrSet.P.traj_ref==itraj,1);
                if isfield(this.summary.signature, 'variables_idx')
                    txt{end+1} = '--------------';
                    for irr = 1:numel(this.summary.signature.variables_idx)
                        var_name = this.summary.signature.params{this.summary.signature.variables_idx(irr)};
                        var_value = this.BrSet.GetParam(var_name, ipts);
                        txt{end+1} = [var_name ': ' num2str(var_value)];
                    end
                end
            end
            
            %% Context menu
            cm = uicontextmenu;
            uimenu(cm, 'Label', 'Open signals plot','Callback', @ctxtfn_signals_plot)
            
            top_diag = uimenu(cm, 'Label', ['Plot diagnosis']);
            for ir = 1:numel(this.summary.requirements.names)
                uimenu(top_diag,'Label', this.summary.requirements.names{ir},'Callback', @(o,e)ctxtfn_plot_diagnosis(ir, o, e));
            end
            
            top_x = uimenu(cm, 'Label', ['Change x-axis']);
            uimenu(top_x, 'Label', 'idx','Callback',@(o,e)(this.set_x_axis('idx')));
            for ip = 1:numel(this.data.variables)
                uimenu(top_x, 'Label', this.data.variables{ip},'Callback',@(o,e)(this.set_x_axis(this.data.variables{ip})));
            end
         
            top_y = uimenu(cm, 'Label', ['Change y-axis']);
            uimenu(top_y, 'Label', 'idx','Callback',@(o,e)(this.set_y_axis('idx')));
            uimenu(top_y, 'Label', 'auto','Callback',@(o,e)(this.set_y_axis('auto')));
            uimenu(top_y, 'Label', 'sum','Callback',@(o,e)(this.set_y_axis('sum')));
            uimenu(top_y, 'Label', 'num','Callback',@(o,e)(this.set_y_axis('num')));
            for ip = 1:numel(this.data.variables)
                uimenu(top_y, 'Label', this.data.variables{ip},'Callback',@(o,e)(this.set_y_axis(this.data.variables{ip})));
            end
         
            set(cursor_h, 'UIContextMenu', cm);
         
            function ctxtfn_plot_diagnosis(ir, o,e)
                if isempty(this.idx_tipped)
                    it = 1;
                else
                    it = this.idx_tipped(1);
                end
                F = this.BrSet.PlotDiagnosis(ir, it);
                set(F.Fig,'Name', ['Trace idx= ' num2str(it)]);
            end
            
            function ctxtfn_signals_plot(o,e)
                if isempty(this.idx_tipped)
                    it = 1;
                else
                    it = this.idx_tipped(1);
                end
                sig = this.summary.signature.signals{1};
                F = BreachSignalsPlot(this.BrSet,sig, it);
                set(F.Fig,'Name', ['Trace idx= ' num2str(it)]);
            end
            
        end
  
        function set_x_axis(this, param)
            current_axis = this.x_axis;
            try
                this.x_axis = param;
                cla(this.ax,'reset');
                this.update_plot();
            catch ME
                g = warndlg(sprintf('Error: %s', ME.message));
                uiwait(g);
                this.set_x_axis(current_axis)
            end
        end
            
     
        function set_y_axis(this, param)
            current_axis = this.y_axis;
            try
                this.y_axis = param;
                cla(this.ax,'reset');
                this.update_plot();
            catch ME
                g= warndlg(sprintf('Error: %s', ME.message));
                uiwait(g);
                this.set_y_axis(current_axis)
            end
        
        end
        
     
        
        
        function update_plot_old(this)
            num_samples = this.summary.num_traces_evaluated;
            figure(this.Fig);
            clf;
            grid on;
      
            vals = this.summary.requirements.rob;
            all_pts = 1:num_samples;
           
            % satisfied requirements
            vals_pos = vals';
            vals_pos(vals'<=0) = 0;
            
            % falsified requirements
            vals_neg = vals';
            vals_neg(vals'>=0) = 0;
             
            % idx pos and neg
            num_vals_pos = sum(vals_pos>=0&vals_neg==0,1);
            num_vals_neg = sum(vals_neg<0,1);
            idx_pos = num_vals_pos  >0;
            idx_neg = num_vals_neg >0; 
            
            % Attempt to pick the most interesting plot  
            
            if size(vals_pos,1)==1|| (all(idx_pos)&&(~any(idx_neg))) ||(all(idx_neg)&&(~any(idx_pos)) )  % only one requirement or all positive or all negative
                plot_sum();
            else
                plot_num();
            end
                
            function plot_sum()
                if any(idx_pos)
                    y_pos = sum(vals_pos(:,idx_pos),1);
                    plot(all_pts(idx_pos),y_pos,'.g', 'MarkerSize', 20);
                end
                
                hold on;
                if any(idx_neg)
                    y_neg = sum(vals_neg(:, idx_neg),1);
                    plot(all_pts(idx_neg),y_neg,'.r', 'MarkerSize', 20);
                end
                grid on;
                xlabel('idx trace');
                set(gca, 'Xtick', []);
                ylabel('Cumulative satisfactions/violations');
            end
     
            function plot_num()
                if any(idx_pos)
                    y_pos = num_vals_pos(idx_pos);
                    bar(all_pts(idx_pos), y_pos ,0.1,'g');
                end
                hold on;
                if any(idx_neg)
                    y_neg = -num_vals_neg(idx_neg);
                    bar(all_pts(idx_neg),y_neg,0.1,'r');
                end
                grid on;
                xlabel('idx trace');
                ylabel('Num. requirement falsified/satisfied');
                set(gca, 'YLim', [min(y_neg)-.1, max(y_pos)+.1],  'Ytick', ceil(min(y_neg)-.1):1:floor(max(y_pos)+.1));
            end   
            h = title('Left click on data to get details, right click to plot signals/diagnosis', 'FontWeight', 'normal', 'FontSize', 10);
           
            
            %% Datacursor mode customization
            cursor_h = datacursormode(this.Fig);
            cursor_h.UpdateFcn = @myupdatefcn;
            cursor_h.SnapToDataVertex = 'on';
            datacursormode on
            
            function [txt] = myupdatefcn(obj,event_obj)
                pos = event_obj.Position;
                itraj = pos(1);
                ipts = find(this.BrSet.BrSet.P.traj_ref==itraj,1);
                val = pos(2);
                this.idx_tipped = itraj;
           
                txt{1} = ['idx trace:' num2str(itraj)] ;
                
                for irr = 1:numel(this.summary.requirements.names)
                    if (this.summary.requirements.rob(itraj, irr)*val>0||(this.summary.requirements.rob(itraj, irr) ==0&&val>=0)) 
                        txt{end+1} = [this.summary.requirements.names{irr} ':' num2str(this.summary.requirements.rob(itraj, irr))];
                    end
                end
               
                if isfield(this.summary.signature, 'variables_idx')
                    txt{end+1} = '--------------';
                    for irr = 1:numel(this.summary.signature.variables_idx)
                        var_name = this.summary.signature.params{this.summary.signature.variables_idx(irr)};
                        var_value = this.BrSet.GetParam(var_name, itraj);
                        txt{end+1} = [var_name ': ' num2str(var_value)];
                    end
                end
            end
            
            %% Context menu
            cm = uicontextmenu;
            uimenu(cm, 'Label', 'Open signals plot','Callback', @ctxtfn_signals_plot)
            top = uimenu(cm, 'Label', ['Plot diagnosis']);
            for ir = 1:numel(this.summary.requirements.names)
                uimenu(top,'Label', this.summary.requirements.names{ir},'Callback', @(o,e)ctxtfn_plot_diagnosis(ir, o, e));
            end
            
            set(cursor_h, 'UIContextMenu', cm);
         
            function ctxtfn_plot_diagnosis(ir, o,e)
                if isempty(this.idx_tipped)
                    it = 1;
                else
                    it = this.idx_tipped(1);
                end
                F = this.BrSet.PlotDiagnosis(ir, it);
                set(F.Fig,'Name', ['Trace idx= ' num2str(it)]);
            end
            
            function ctxtfn_signals_plot(o,e)
                if isempty(this.idx_tipped)
                    it = 1;
                else
                    it = this.idx_tipped(1);
                end
                sig = this.summary.signature.signals{1};
                F = BreachSignalsPlot(this.BrSet,sig, it);
                set(F.Fig,'Name', ['Trace idx= ' num2str(it)]);
            end
            
        end
    end
end

