function tokenStructs = getTokenStruct()
% MBeautify.getTokenStruct returns the tokens used in replacement

% Persistent variable to serve as cache
persistent tokenStructStored;
if isempty(tokenStructStored)
    
    tokenStructs = containers.Map;
    tokenStructs('ContinueToken') = newStruct('...', '#MBeutyCont#');
    tokenStructs('StringToken') = newStruct('', '#MBeutyString#');
    tokenStructs('ArrayElementToken') = newStruct('', '#MBeutyArrayElement#');
    tokenStructs('TransposeToken') = newStruct('''', '#MBeutyTransp#');
    tokenStructs('NonConjTransposeToken') = newStruct('.''', '#MBeutyNonConjTransp#');
    tokenStructs('NormNotationPlus') = newStruct('+', '#MBeauty_OP_NormNotationPlus');
    tokenStructs('NormNotationMinus') = newStruct('-', '#MBeauty_OP_NormNotationMinus');
    tokenStructs('UnaryPlus') = newStruct('+', '#MBeauty_OP_UnaryPlus');
    tokenStructs('UnaryMinus') = newStruct('-', '#MBeauty_OP_UnaryMinus');
    
    tokenStructStored = tokenStructs;
else
    tokenStructs = tokenStructStored;
end

    function retStruct = newStruct(storedValue, replacementString)
        retStruct = struct('StoredValue', storedValue, 'Token', replacementString);
    end
end

