function configurationStruct = getConfigurationStruct()
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

currCD = cd();
cd(MBeautify.SettingDirectory);
configurationStruct = eval(MBeautify.RulesMFile(1:end-2));
cd(currCD);

end

