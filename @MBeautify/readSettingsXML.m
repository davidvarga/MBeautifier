function res = readSettingsXML()
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here


xmlFile = 'D:\MATLAB\test.xml';

XMLDoc = xmlread(xmlFile);

allOperandItems = XMLDoc.getElementsByTagName('OperatorPaddingRule');

for iOperator = 0:allOperandItems.getLength()-1
    
   currentOperand = allOperandItems.item(iOperator);
   key = currentOperand.getElementsByTagName('Key').item(0).getTextContent();
   valueFrom = currentOperand.getElementsByTagName('ValueFrom').item(0).getTextContent();
    valueTo = currentOperand.getElementsByTagName('ValueTo').item(0).getTextContent();
    
end




end

