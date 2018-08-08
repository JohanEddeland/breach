classdef BreachDiagnostics
    methods (Static)
        function [out_implicant, error] = diag_not_f(in, in_implicant, value)
            [out_implicant, error] = diag_unary_plogic (in, in_implicant, value);
        end  
        
        function [out_implicant, error] = diag_not_t(in, in_implicant, value)
            [out_implicant, error] = diag_unary_plogic (in, in_implicant, value);
        end    
        
        function [out1_implicant, out2_implicant, error] = diag_or_t(in1, in2, in_implicant, value);
            error = 0;
            out_implicant = BreachImplicant;
            
            size = in_implicant.getIntervalsSize();
            for(i = 1:size)
                interval = in_implicant.getInterval(i);
                t1 = in1.times;
                t2 = in2.times;
                v1 = in1.values;
                v2 = in2.values;
                itv = [interval.begin, interval.end];
                
                t_new = union(union(t1, t2), itv, 'sorted');
                v1_new = interp1(t1, v1, t_new);
                v2_new = interp1(t2, v2, t_new);
            end
        end
    end        
    
    methods (Access = private)
        
        function [out_implicant, error] = diag_unary_plogic(in, in_implicant, value)
            error = 0;
            out_implicant = in_implicant;
        end

    end
end