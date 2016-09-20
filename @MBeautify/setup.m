function setup()
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

fullRulesFile = MBeautify.RulesXMLFileFull;
fullRulesConfMFileName = MBeautify.RulesMFileFull;

if ~exist(fullRulesFile, 'file')
    MBeautify.writeSettingsXML(fullRulesFile);
end

resStruct = MBeautify.readSettingsXML(fullRulesFile);

MBeautify.writeConfigurationFile(resStruct, fullRulesConfMFileName);

fprintf('Configuration was successfully exported to:\n%s\n', fullRulesConfMFileName);
MBeautify.parsingUpToDate(false);

end

