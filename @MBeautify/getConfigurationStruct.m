function configurationStruct = getConfigurationStruct()
% MBeautify.getConfigurationStruct returns the configuration struct from the rules file

% Persistent variable to store the returned rules
% If MBeatify.setup was not called, the stored struct should be returned
persistent configurationStructStored;

if isempty(configurationStructStored) || ~MBeautify.parsingUpToDate()
    currCD = cd();
    cd(MBeautify.SettingDirectory);
    configurationStruct = eval(MBeautify.RulesMFile(1:end-2));
    cd(currCD)
    configurationStructStored = configurationStruct;
    MBeautify.parsingUpToDate(true);
else
    configurationStruct = configurationStructStored;
end

end


