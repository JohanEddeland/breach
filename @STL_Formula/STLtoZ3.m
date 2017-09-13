function z3Info = STLtoZ3(phi, z3Info)

if nargin == 1
    % No z3Info supplied
    z3Info = struct();
    z3Info.z3String = [];
    z3Info.signals = {};
end

switch (phi.type)
    
    case 'predicate'
        phiString = disp(phi);
        
        % To format the predicate for Z3, we need to 
        % - Remove [t], [t - 10*dt] etc
        % - Replace parameters by their actual values
        %   (i.e., AcDamp_negTq should be replaced by 0)
        
        % Remove [t], [t - 10*dt] etc
        leftIndexes = strfind(phiString, '[');
        rightIndexes = strfind(phiString, ']');
        while ~isempty(leftIndexes)
            phiString(leftIndexes(1):rightIndexes(1)) = '';
            leftIndexes = strfind(phiString, '[');
            rightIndexes = strfind(phiString, ']');
        end

        z3Info.z3String = phiString;
        
    
    %TODO: FIX IMPLEMENTATION FOR ALL BELOW CASES! CHECK THAT THEY ARE
    %CORRECT AND CAN WORK WITH Z3PY!!!
    case 'not'
        
        z3Info.z3String = [STLtoZ3(phi.phi, z3Info) phi] ;
        
    case 'always'
        
    case 'eventually'
        
    case 'and'
        z3Info.z3String = [STLtoZ3(phi.phi1, z3Info) STLtoZ3(phi.phi2, z3Info) phi];
        
    case 'or'
        
    case '=>'
        
    case 'until'
end

z3Info.signals = STL_ExtractSignals(phi);

if nargin == 1
    % Replace parameters by their actual values
    allParams = get_params(phi);
    fieldNames = fieldnames(allParams);
    for k = 1:length(allParams)
        paramValue = getfield(allParams, fieldNames{k});
        z3Info.z3String = strrep(z3Info.z3String, fieldNames{k}, num2str(paramValue));
    end
end
end

