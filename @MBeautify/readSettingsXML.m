function settingsStruct = readSettingsXML()
% MBeautify.readSettingsXML reads the configuration XML file to a structure.

settingsStruct = struct('OperatorRules', struct(), 'SpecialRules', struct());

XMLDoc = xmlread(MBeautify.RulesXMLFileFull);

allOperatorItems = XMLDoc.getElementsByTagName('OperatorPaddingRule');
operatorNode = settingsStruct.OperatorRules;

for iOperator = 0:allOperatorItems.getLength() - 1
    
    currentOperator = allOperatorItems.item(iOperator);
    
    key = char(currentOperator.getElementsByTagName('Key').item(0).getTextContent().toString());
    operatorNode.(key) = struct();
    operatorNode.(key).ValueFrom = removeXMLEscaping(char(currentOperator.getElementsByTagName('ValueFrom').item(0).getTextContent().toString()));
    operatorNode.(key).ValueTo = removeXMLEscaping(char(currentOperator.getElementsByTagName('ValueTo').item(0).getTextContent().toString()));
end

settingsStruct.OperatorRules = operatorNode;

allSpecialItems = XMLDoc.getElementsByTagName('SpecialRule');
specialRulesNode = settingsStruct.SpecialRules;

for iSpecRule = 0:allSpecialItems.getLength() - 1
    
    currentRule = allSpecialItems.item(iSpecRule);
    
    key = char(currentRule.getElementsByTagName('Key').item(0).getTextContent().toString());
    specialRulesNode.(key) = struct();
    specialRulesNode.(key).Value = char(currentRule.getElementsByTagName('Value').item(0).getTextContent().toString());
end

settingsStruct.SpecialRules = specialRulesNode;

end

function escapedValue = removeXMLEscaping(value)
escapedValue = regexprep(value, '&lt;', '<');
escapedValue = regexprep(escapedValue, '&amp;', '&');
escapedValue = regexprep(escapedValue, '&gt;', '>');

end


