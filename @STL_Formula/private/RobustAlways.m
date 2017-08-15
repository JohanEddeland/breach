function [time_values, valarray] = RobustAlways(time_values, valarray, I___)

% Calculate standard rho
rho = min(valarray);

% Calculate rho1
rho1 = 0;
for k = 1:length(time_values)-1
    rho1 = rho1 + valarray(k)*(time_values(k+1) - time_values(k));
end
rho1 = rho1 / (time_values(end) - time_values(1));

% Calculate rho2
rho2 = 0;
for k = 1:length(time_values)-1
    rho2 = rho2 + valarray(k)*valarray(k)*(time_values(k+1) - time_values(k));
end
rho2 = rho2 / (time_values(end) - time_values(1));
rho2 = sqrt(rho2);

%fprintf('=======\nrho: %.3f \nrho1: %.3f \nrho2: %.3f\n',rho,rho1,rho2);

% Initialize rho, rho1 and rho2 to base workspace
if ~evalin('base','exist(''testron_rho'')')
    assignin('base','testron_rho',[]);
end
if ~evalin('base','exist(''testron_rho1'')')
    assignin('base','testron_rho1',[]);
end
if ~evalin('base','exist(''testron_rho2'')')
    assignin('base','testron_rho2',[]);
end

% Save rho, rho1, rho2 to base workspace
evalin('base',['testron_rho(end+1) = ' num2str(rho) ';']);
evalin('base',['testron_rho1(end+1) = ' num2str(rho1) ';']);
evalin('base',['testron_rho2(end+1) = ' num2str(rho2) ';']);

try
    obj_to_use = evalin('base','testron_obj_to_use;');
catch
    obj_to_use = 'standard';
end

if strcmp(obj_to_use,'standard')
    % Do nothing, keep valarray as it is. 
    valarray = valarray + 0.000001; % Margin issues
    [time_values, valarray] = RobustEv(time_values, -valarray, I___);
    valarray = -valarray;
elseif strcmp(obj_to_use,'rho1')
    if rho < 0
        % Do nothing, since we want to keep the valarray as it is
    else
        valarray = rho1*ones(size(valarray));
    end
elseif strcmp(obj_to_use,'rho2')
    if rho < 0
        % Do nothing, since we want to keep the valarray as it is
    else
        valarray = rho2*ones(size(valarray));
    end
else
    disp('Unknown objective function')
end



end