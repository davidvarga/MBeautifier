function writeSettingsXML(fullFilePath)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

docNode = com.mathworks.xml.XMLUtils.createDocument('MBeautifyRuleConfiguration');
docRootNode = docNode.getDocumentElement();

operatorPaddings = docNode.createElement('OperatorPadding');
docRootNode.appendChild(operatorPaddings);

specialRules = docNode.createElement('SpecialRules');
docRootNode.appendChild(specialRules);

%% Add operator rules
operatorPaddings = appendOperatorPaddingRule('ShortCircuitAnd', '&amp;&amp;', ' &amp;&amp; ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('ShortCircuitOr', '||', ' || ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('LogicalAnd', '&amp;', ' &amp; ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('LogicalOr', '|', ' | ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('LessEquals', '&lt;=', ' &lt;= ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('Less', '&lt;', ' &lt; ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('GreaterEquals', '&gt;=', ' &gt;= ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('Greater', '&gt;', ' &gt; ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('Equals', '==', ' == ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('NotEquals', '~=', ' ~= ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('Assignment', '=', ' = ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('Plus', '+', ' + ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('Minus', '-', ' - ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('ElementWiseMultiplication', '.*', ' .* ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('Multiplication', '*', ' * ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('RightArrayDivision', './', ' ./ ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('LeftArrayDivision', '.\', ' .\ ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('Division', '/', ' / ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('LeftDivision', '\', ' \ ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('ElementWisePower', '.^', ' .^ ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('Power', '^', ' ^ ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('Not', '~', ' ~', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('Comma', ',', ', ', operatorPaddings, docNode);
operatorPaddings = appendOperatorPaddingRule('SemiColon', ';', '; ', operatorPaddings, docNode);
appendOperatorPaddingRule('Colon', ':', ':', operatorPaddings, docNode);

%% Add special rules
specialRules = appendSpecialRule('MaximalNewLines', '2', specialRules, docNode);
appendSpecialRule('AddCommasToMatrices', '1', specialRules, docNode);


 xmlFileName = fullFilePath;
 xmlwrite(xmlFileName,docNode);
 
fprintf('Default configuration XML has been created:\n%s\n', xmlFileName);



end

function operatorPaddings = appendOperatorPaddingRule(key, valueFrom, valueTo, operatorPaddings, docNode)
    opPaddingRule = docNode.createElement('OperatorPaddingRule');

    keyElement = docNode.createElement('Key');
    keyElement.appendChild(docNode.createTextNode(key));
    
    valueFromElement = docNode.createElement('ValueFrom');
    valueFromElement.appendChild(docNode.createTextNode(valueFrom));
    
    valueToElement = docNode.createElement('ValueTo');
    valueToElement.appendChild(docNode.createTextNode(valueTo));
    
    opPaddingRule.appendChild(keyElement);
    opPaddingRule.appendChild(valueFromElement);
    opPaddingRule.appendChild(valueToElement);
    
    operatorPaddings.appendChild(opPaddingRule);
    
end

function specialRules = appendSpecialRule(key, value, specialRules, docNode)
    specialRule = docNode.createElement('SpecialRule');

    keyElement = docNode.createElement('Key');
    keyElement.appendChild(docNode.createTextNode(key));
    
    valueElement = docNode.createElement('Value');
    valueElement.appendChild(docNode.createTextNode(value));
    
    specialRule.appendChild(keyElement);
    specialRule.appendChild(valueElement);

    
    specialRules.appendChild(specialRule);
    
end

