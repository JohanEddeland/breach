classdef BreachImplicant
    properties
        Intervals
        SampleTime
        SampleValue
    end
    
    methods
        function obj = BreachImplicant(obj)
            obj.Intervals = [];
            obj.SampleTime = {};
            obj.SampleValue = {};
        end 
        
        function obj = addInterval (obj, begin_value, end_value)
            if (end_value >= begin_value)
                interval.begin = begin_value;
                interval.end = end_value;
                obj.Intervals = [obj.Intervals, interval];
            end
        end
        
        function obj = setSignificantSample (obj, sample_time, sample_value)
            obj.SampleTime = sample_time;
            obj.SampleValue = sample_value;
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
        
        function sample_time = getSampleTime(obj)
            sample_time = obj.SampleTime;
        end
        
        function sample_value = getSampleValue(obj)
            sample_value = obj.SampleValue;
        end
    end
end