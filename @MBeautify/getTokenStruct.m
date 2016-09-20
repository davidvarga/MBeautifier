function tokenStructs = getTokenStruct()
% Returns the tokens used in replacement

% Persistent variable to serve as cache
persistent tokenStructStored;
if isempty(tokenStructStored)
    
    tokenStructs = containers.Map;
    tokenStructs('ContinueToken') = newStruct('...', '#MBeutyCont#');
    tokenStructs('StringToken') = newStruct('', '#MBeutyString#');
    tokenStructs('ArrayElementToken') = newStruct('', '#MBeutyArrayElement#');
    tokenStructs('TransposeToken') = newStruct('''', '#MBeutyTransp#');
    tokenStructs('NonConjTransposeToken') = newStruct('.''', '#MBeutyNonConjTransp#');
    tokenStructStored = tokenStructs;
else
    tokenStructs = tokenStructStored;
end

    function retStruct = newStruct(storedValue, replacementString)
        retStruct = struct('StoredValue', storedValue, 'Token', replacementString);
    end
end

