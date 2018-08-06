classdef req_monitor < output_gen
    properties
        name
    end
    methods (Abstract)
         eval(this, t, X,p)
    end
    
end