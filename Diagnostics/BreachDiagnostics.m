classdef BreachDiagnostics
    methods (Static)
        function [out_implicant, error] = diag_not_f(in, in_implicant, value)
            [out_implicant, error] = BreachDiagnostics.diag_unary_plogic (in, in_implicant, value);
        end  
        
        function [out_implicant, error] = diag_not_t(in, in_implicant, value)
            [out_implicant, error] = BreachDiagnostics.diag_unary_plogic (in, in_implicant, value);
        end    
        
        function [out1_implicant, out2_implicant, error] = diag_or_f(in1, in2, in_implicant, value)
            out1_implicant = in_implicant;
            out2_implicant = in_implicant;
            error = 0;
        end
        
        function [out1_implicant, out2_implicant, error] = diag_or_t(in1, in2, in_implicant, value)
            error = 0;
            [out1_implicant, out2_implicant] = ...
                BreachDiagnostics.diag_binary_plogic(BreachOperator.OR, in1, in2, in_implicant, value);
        end
        
        function [out1_implicant, out2_implicant, error] = diag_and_f(in1, in2, in_implicant, value)
            error = 0;
            [out1_implicant, out2_implicant] = ...
                BreachDiagnostics.diag_binary_plogic(BreachOperator.AND, in1, in2, in_implicant, value);
        end    
        
        function [out1_implicant, out2_implicant, error] = diag_and_t(in1, in2, in_implicant, value)
            out1_implicant = in_implicant;
            out2_implicant = in_implicant;
            error = 0;
        end
             
        function [out1_implicant, out2_implicant, error] = diag_implies_f(in1, in2, in_implicant, value)
            out1_implicant = in_implicant;
            out2_implicant = in_implicant;
            error = 0;
        end
        
        function [out1_implicant, out2_implicant, error] = diag_implies_t(in1, in2, in_implicant, value)
            error = 0;
            [out1_implicant, out2_implicant] = ...
                BreachDiagnostics.diag_binary_plogic(BreachOperator.IMPLIES, in1, in2, in_implicant, value);
        end
        
        function [out1_implicant, out2_implicant, error] = diag_iff_f(in1, in2, in_implicant, value)
            out1_implicant = in_implicant;
            out2_implicant = in_implicant;
            error = 0;
        end
        
        function [out1_implicant, out2_implicant, error] = diag_iff_t(in1, in2, in_implicant, value)
            out1_implicant = in_implicant;
            out2_implicant = in_implicant;
            error = 0;
        end
        
        function [out1_implicant, out2_implicant, error] = diag_xor_f(in1, in2, in_implicant, value)
            out1_implicant = in_implicant;
            out2_implicant = in_implicant;
            error = 0;
        end
        
        function [out1_implicant, out2_implicant, error] = diag_xor_t(in1, in2, in_implicant, value)
            out1_implicant = in_implicant;
            out2_implicant = in_implicant;
            error = 0;
        end
        
        function [out_implicant, error] = diag_ev_false_t(in, bound, in_implicant, value)
            out_implicant = BreachImplicant;
            size = in_implicant.getIntervalsSize();
            for(i=0:size)
                interval = in_implicant.getInterval(i);
                new_interval = [interval.begin + bound.begin, interval.end + bound.end];
                out_implicant = [out_implicant, new_interval];
            end
        end
        
        function [out_implicant, error] = diag_ev_t(in, in_implicant, value)
            out1_implicant = in_implicant;
            out2_implicant = in_implicant;
            error = 0;
        end
    end
    
    methods(Static,Access=private)
        function [out_implicant, error] = diag_unary_plogic(in, in_implicant, value)
            error = 0;
            out_implicant = in_implicant;
        end
        
        function [out1_implicant, out2_implicant] = diag_binary_plogic(operator, in1, in2, in_implicant, value)
            out1_implicant = BreachImplicant;
            out2_implicant = BreachImplicant;
            
            size = in_implicant.getIntervalsSize();
            for(i = 1:size)
                interval = in_implicant.getInterval(i);
                
                out1_tmp = BreachDiagnostics.diag_signal_restrict_to_interval(in1, interval);
                out2_tmp = BreachDiagnostics.diag_signal_restrict_to_interval(in2, interval);
                
                [out1_tmp out2_tmp] = BreachDiagnostics.diag_two_signals_normalize_sampling (out1_tmp, out2_tmp);
                
                begin_time = out1_tmp.times(1);
                v1 = out1_tmp.times(1);
                v2 = out2_tmp.times(1);
                old_value = TwoBitValue.getValue(v1,v2);
                
                for(j=2:length(out1_tmp.times))
                    t = out1_tmp.times(j);
                    v1 = out1_tmp.values(j);
                    v2 = out2_tmp.values(j);
                    
                    new_value = TwoBitValue.getValue(v1,v2);
                    
                    if (new_value ~= old_value || j == length(out1_tmp.times))
                        end_time = t;
                        [out1_implicant, out2_implicant] = BreachDiagnostics.diag_binary_plogic_update_implicants( ...
                            operator, old_value, out1_implicant, out1_implicant, begin_time, end_time);
                        begin_time = t;
                        old_value = new_value;
                    end
                end
            end
        end    
        
        function [out1, out2] = diag_binary_plogic_update_implicants(oper, value, in1, in2, btime, etime)
            out1 = in1;
            out2 = in2;
            switch(oper)
                case BreachOperator.OR
                    if (value == TwoBitValue.FT)
                        out2 = in2.addInterval(btime, etime);
                    elseif (value == TwoBitValue.TF || value == TwoBitValue.TT)
                        out1 = in1.addInterval(btime, etime);
                    end
                case BreachOperator.AND
                    if (value == TwoBitValue.FT || value == TwoBitValue.FF)
                        out1 = in1.addInterval(btime, etime);
                    elseif (value == TwoBitValue.TF)
                        out2 = in2.addInterval(btime, etime);
                    end
                case BreachOperator.IMPLIES
                    if (value == TwoBitValue.TT)
                        out2 = in2.addInterval(btime, etime);
                    elseif (value == TwoBitValue.FF || value == TwoBitValue.FT)
                        out1 = in1.addInterval(btime, etime);
                    end
            end
        end
        
        function [out] = diag_signal_restrict_to_interval(in, interval)
            t = in.times;
            v = in.values;
            itv = [interval.begin, interval.end];
            
            t_tmp = union(t, itv,'sorted');
            v_tmp = interp1(t, v, t_tmp);
            
            size = length(t_tmp);
            t_out = [];
            v_out = [];
            for (i=1:size)
                if(t_tmp(i) >= interval.begin && t_tmp(i) <= interval.end)
                    t_out = [t_out t_tmp(i)];
                    v_out = [v_out v_tmp(i)];
                end
            end
            
            out.times = t_out;
            out.values = v_out;     
        end    
        
        function [out1, out2] = diag_two_signals_normalize_sampling(in1, in2)
            t1 = in1.times;
            v1 = in1.values;
            t2 = in2.times;
            v2 = in2.values;
            
            t_tmp = union(t1, t2, 'sorted');
            v1_tmp = interp1(t1, v1, t_tmp);
            v2_tmp = interp1(t2, v2, t_tmp);
            
            out1.times = t_tmp;
            out1.values = v1_tmp;
            out2.times = t_tmp;
            out2.values = v2_tmp;
        end

    end
end