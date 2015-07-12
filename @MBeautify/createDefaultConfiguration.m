function createDefaultConfiguration()
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

buttonName = questdlg('This will overwrite the current configuration XML file!', ...
    'Overwrite current configuration?', ...
    'Continue', 'Cancel', 'Cancel');


switch buttonName,
    case 'Continue',
        
        fullRulesFile = MBeautify.RulesXMLFileFull;
        MBeautify.writeSettingsXML(fullRulesFile);
        
end 

end

