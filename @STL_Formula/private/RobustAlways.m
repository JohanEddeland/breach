function [time_values, valarray] = RobustAlways(time_values, valarray, I___)

% Calculate standard rho
rho = min(valarray);

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
    partialRob = partialRob / totalTimeIntegrated;
    
    % Assert that the partialRob is negative - otherwise our additive
    % semantics are not sound with regards to the standard semantics
    assert(partialRob < 0);
    
    valarray = partialRob*ones(size(valarray));
else
    % The spec does not fail
    % Take the inverse of the integral of the inverse
    if rho == 0
        % Avoid division by zero: Just set the robustness to zero
        valarray = zeros(size(valarray));
    else
        % Do the actual calculations
        % Note that all values in valarray are strictly positive
        partialRob = 0;
        for k = 1:numel(valarray)-1
            partialRob = partialRob + (1/valarray(k))*(time_values(k+1) - time_values(k));
        end
        partialRob = 1/partialRob;
        valarray = partialRob*ones(size(valarray));
    end
end

% % Calculate rho1
% rho1 = 0;
% for k = 1:length(time_values)-1
%     rho1 = rho1 + valarray(k)*(time_values(k+1) - time_values(k));
% end
% rho1 = rho1 / (time_values(end) - time_values(1));
% 
% if rho < 0
%     % Do nothing, since we want to keep the valarray as it is
% else
%     valarray = rho1*ones(size(valarray));
% end


end