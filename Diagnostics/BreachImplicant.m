classdef BreachImplicant
    properties
        Intervals
        SignificantTime
    end
    
    methods
        function obj = BreachImplicant(obj)
            obj.Intervals = [];
            obj.SignificantTime = {};
        end 
        
        function obj = addInterval (obj, begin_value, end_value)
            if (end_value >= begin_value)
                interval.begin = begin_value;
                interval.end = end_value;
                obj.Intervals = [obj.Intervals, interval];
            end
        end
        
        function obj = setSignificantTime (obj, significant_time)
            obj.SignificantTime = significant_time;
        end
        
        function intervals = getIntervals(obj)
            intervals = obj.Intervals;
        end 
        
        function interval = getInterval(obj, index)
            if (index > length(obj.Intervals))
                interval = [];
            else
                interval = obj.Intervals(index);
            end
        end 
        
        function size = getIntervalsSize(obj) 
            size = length(obj.Intervals);
        end
        
        function significant_time = getSignificantTime(obj)
            significant_time = obj.SignificantTime;
        end
    end
end