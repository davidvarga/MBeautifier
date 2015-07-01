function tokenStructs = getTokenStruct()
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here


tokenStructs = containers.Map;
tokenStructs('ContinueToken') = newStruct('...', '#MBeutyCont#');
tokenStructs('StringToken') = newStruct('', '#MBeutyString#');
tokenStructs('TransposeToken') = newStruct('''', '#MBeutyTransp#');
tokenStructs('NonConjTransposeToken') = newStruct('.''', '#MBeutyNonConjTransp#');

    function retStruct = newStruct(storedValue, replacementString)
        retStruct = struct('StoredValue', storedValue, 'Token', replacementString);
    end




end

