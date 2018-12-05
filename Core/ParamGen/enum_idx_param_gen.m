classdef enum_idx_param_gen < param_gen
    % equal_param_gen enforces one param_out to be always equal to param_in
    
    properties
        domain_out
    end
    
    methods
        function this = enum_idx_param_gen(param, domain_out)
            this.params = {[param '_enum_idx']};
            this.domain = BreachDomain('enum', 1:length(domain_out.enum));
            this.domain_out = domain_out;
            this.params_out = {param};
            this.p0 = 1;
        end
        
        function p_out = computeParams(this, p_in)
            p_out = this.domain_out.enum(p_in); 
        end
    end
     
end