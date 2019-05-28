classdef alw_monitor < stl_monitor
    properties
        interval
    end
    
    methods
        function this = alw_monitor(formula)
            this = this@stl_monitor(formula);
            subphi = get_children(this.formula);
            subphi = subphi{1};
            this.formula = subphi;
            this.signals = this.signals(1:end-1);
            this.signals{end+1} = [this.formula_id '_violation'];
            this.signals{end+1} = [this.formula_id '_quant_sat'];
                
            this.interval = get_interval(formula);
            this.init_P();
        end
        
        function [v, t, Xout] = eval(this, t, X,p)
            global objToUse;
            [t, Xout] = this.computeSignals(t, X,p);
            idx  = this.get_time_idx_interval(t,p);
            Xout(end-1,:) = Xout(end,:)<0;         % violation flags
            Xout(end-1:end, ~idx) = NaN;
            
            % Xout(end, idx) array of obj function values inside alw()
            % t(idx) array of corresponding times
            
            % We want to use the same implementation as in
            % @STL_Formula/private/RobustAlways.m. However, since it's a
            % private function, we cannot reach it. Therefore, we have
            % copies called
            % alw_monitor_RobustAlways.m
            % alw_monitor_RobustAlways_v1.m
            % These function are in the Core/OutputGen folder. 
            time_values = t(idx);
            valarray = Xout(end,idx);
            I___ = [time_values(1) time_values(end)];
            switch objToUse
                case 'vbool'
                    %[time_values, valarray] = RobustAvEvRight(time_values, -valarray, I___);
                    %valarray = -valarray;
                    [~, val_output] = alw_monitor_RobustAlways(time_values, valarray, I___);
                    v = val_output(1);
                case 'standard'
                    v = min(valarray);
                case 'vbool_v1'
                    %[time_values, valarray] = RobustAvEvRight(time_values, -valarray, I___);
                    %valarray = -valarray;
                    [~, val_output] = alw_monitor_RobustAlways_v1(time_values, valarray, I___);
                    v = val_output(1);
                otherwise
                    error('Unknown objective function!');
            end
        end
        
        function st = disp(this)
            phi = this.formula;
            st = sprintf(['%s := alw_%s (%s)\n'], this.formula_id,this.interval,  disp(phi,1));
            
            if ~strcmp(get_type(phi),'predicate')
                st = [st '  where\n'];
                predicates = STL_ExtractPredicates(phi);
                for ip = 1:numel(predicates)
                    st =   sprintf([ st '%s := %s \n' ], get_id(predicates(ip)), disp(predicates(ip)));
                end
            end
            
            if nargout == 0
                fprintf(st);
            end
     
        end
        
        function plot_diagnosis(this, F)
            % Assumes F has data about this formula 
            
            F.AddSignals(this.signals_in);
            sig= this.signals{end};
            F.HighlightFalse(sig);
        end
    
    end
    
    methods  (Access=protected)
        function idx__ = get_time_idx_interval(this, t__, p__)
            t=0; 
            this.assign_params(p__);
            interval = eval(this.interval);
            idx__ = (t__>= interval(1))&(t__<=interval(end));
            if ~any(idx__)
                idx__(end) = 1;
            end
        end
        
        
    end
end