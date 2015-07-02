function tokens = getAllTokens()
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

tokStruct = MBeautify.getTokenStruct();

vals = tokStruct.values;
tokens = cell(1,numel(vals));

for iValue = 1:numel(vals)
    tokens{iValue} = vals{iValue}.Token;
end

end

