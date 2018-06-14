classdef BreachSamplesPlot < handle
    
    properties
        BrSet
        Fig
        params
        summary
    end
    
    properties (Access=protected)
        idx_tipped
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
       
             this.summary = BrSet.GetSummary();
             this.update_plot();
        end
        
        
        function update_plot(this)
            num_samples = this.summary.num_traces_evaluated;
            figure(this.Fig);
            clf;
            grid on;
            vals = this.summary.requirements.rob;
            all_pts = 1:num_samples;
            vals_pos = vals;
            vals_pos(vals<=0) = 0;
            vals_pos = sum(vals_pos,2);
            vals_neg = vals;
            vals_neg(vals>=0) = 0;
            vals_neg = sum(vals_neg,2);
            pos_pts = all_pts(vals_pos>0|~vals_neg<0);
            neg_pts = all_pts(vals_neg<0);
            plot(pos_pts, vals_pos(vals_pos>0|~vals_neg<0),'.g', 'MarkerSize', 30);
            hold on;
            plot(neg_pts, vals_neg(vals_neg<0),'.r', 'MarkerSize', 30);
            grid on;
            xlabel Samples;
            set(gca, 'Xtick', []); 
            ylabel('Cumulative satisfactions/violations');
       
            %% Datacursor mode customization
            cursor_h = datacursormode(this.Fig);
            cursor_h.UpdateFcn = @myupdatefcn;
            cursor_h.SnapToDataVertex = 'on';
            datacursormode on
            
            
            function [txt] = myupdatefcn(obj,event_obj)
                pos = event_obj.Position;
                ipts = pos(1);
                val = pos(2);
                txt = cell(1, numel(this.summary.requirements.names)+1);
                txt{1} = ['idx:' num2str(ipts)];
                for irr = 1:numel(this.summary.requirements.names)
                    txt{irr+1} = [this.summary.requirements.names{irr} ':' num2str(this.summary.requirements.rob(ipts, irr))];
                end
                this.idx_tipped = ipts;
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
                this.BrSet.PlotDiagnosis(ir, this.idx_tipped);
            end
            
            function ctxtfn_signals_plot(o,e)
                BreachSignalsPlot(this.BrSet, this.idx_tipped);
            end
            
        end
    end
end

