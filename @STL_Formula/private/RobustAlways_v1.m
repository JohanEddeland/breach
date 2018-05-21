function [time_values, valarray] = RobustAlways_v1(time_values, valarray, I___)

indicesToRemove = [];

for valIndex = 1:length(valarray)
    thisTime = time_values(valIndex);
    
    % Start time is currentTime + first element of I___
    startTime = thisTime + I___(1);
    
    % End time is startTime + second element of I___
    endTime = startTime + I___(2);
    
    timeIntervalIndex = find(time_values >= startTime & time_values <= endTime);
    
    partialTime = time_values(timeIntervalIndex);
    partialValarray = valarray(timeIntervalIndex);
    
    if isempty(partialTime)
        % There is no signal in the time we are looking at
        % Just remove this point from valarray and time_values
        time_values(valIndex) = [];
        valarray(valIndex) = [];
    else
        partialRob = PartialRobustAlways(partialTime, partialValarray);
        
        % Check if we can reduce the size of time_values and valarray by
        % removing this element (if it is the same as the element before
        if valIndex == 1 || valIndex == length(valarray)
            % We cannot remove the first or the last element
            valarray(valIndex) = partialRob;
        elseif valarray(valIndex - 1) == partialRob
            % The value is the same as the previous one
            % We don't need to add a new value - instead, we can remove this
            % time step from the time_values and valarray vectors later on
            indicesToRemove(end+1) = valIndex; %#ok<*AGROW>
        else
            valarray(valIndex) = partialRob;
        end
    end
    
end

% Remove the indices that are just "duplicates" of the value at the
% previous time stamp
time_values(indicesToRemove) = [];
valarray(indicesToRemove) = [];

end

function partialRob = PartialRobustAlways(time_values, valarray)
% Handle the case with only ONE value
% (We have no time to integrate over -> division by zero)
% Fix this by just returning the single value
if numel(valarray) == 1
    partialRob = valarray;
    return
end


rho = min(valarray(1:end-1));

if rho < 0
    % The spec fails - we will integrate over the faulty intervals
    %     timesLessThanZero = time_values(valarray < 0);
    %     valLessThanZero = valarray(valarray < 0);
    %
    %     partialRob = 0; % Summing variable
    %     for k = 1:numel(timesLessThanZero)-1
    %         partialRob = partialRob + valLessThanZero(k)*(timesLessThanZero(k+1) - timesLessThanZero(k));
    %     end
    partialRob = 0;
    totalTimeIntegrated = 0;
    for k = 1:numel(valarray)-1
        if valarray(k) < 0
            partialRob = partialRob + valarray(k)*(time_values(k+1) - time_values(k));
            totalTimeIntegrated = totalTimeIntegrated + (time_values(k+1) - time_values(k));
        end
    end
    
    % Assert that the partialRob is negative - otherwise our additive
    % semantics are not sound with regards to the standard semantics
    assert(partialRob < 0);
else
    % The spec does not fail
    % Take the inverse of the integral of the inverse
    if rho == 0
        % Avoid division by zero: Just set the robustness to zero
        partialRob = 0;
    else
        % Do the actual calculations
        % Note that all values in valarray are strictly positive
        partialRob = 0;
        for k = 1:numel(valarray)-1
            partialRob = partialRob + valarray(k)*(time_values(k+1) - time_values(k));
        end
    end
end
end