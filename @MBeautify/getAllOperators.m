function operators = getAllOperators()
% MBeautify.getAllOperators returns all operators in a cell array

persistent operatorsStored;

if isempty(operatorsStored) || ~MBeautify.parsingUpToDate()
    
    confStruct = MBeautify.getConfigurationStruct();
    fieldList = fields(confStruct.OperatorRules);
    operators = cell(numel(fieldList), 1);
    
    for i = 1:numel(fieldList)
        operators{i} = confStruct.OperatorRules.(fieldList{i}).ValueFrom;
    end
    operatorsStored = operators;
else
    operators = operatorsStored;
end
end
