function writeConfigurationFile(resStruct)
% MBeautify.writeConfigurationFile creates the configuration M file from the structure of the configuration XML file.

operetorRules = resStruct.OperatorRules;
opFields = fields(operetorRules);

[pathOfMFile, nameOfMFile] = fileparts(MBeautify.RulesMFileFull); %#ok<ASGLU>

settingMFileString = ['function this = ', nameOfMFile, '()', sprintf('\n'), ...
    'this = struct();', sprintf('\n'), sprintf('\n')];

settingMFileString = [settingMFileString, 'this.OperatorRules = struct();', sprintf('\n'), sprintf('\n')];

for iOp = 1:numel(opFields)
    
    settingMFileString = [settingMFileString, sprintf('\n')];
    settingMFileString = [settingMFileString, ['this.OperatorRules.', opFields{iOp}, ' = struct();'], sprintf('\n')];
    
    valueFrom = regexptranslate('escape', operetorRules.(opFields{iOp}).ValueFrom);
    valueTo = regexptranslate('escape', operetorRules.(opFields{iOp}).ValueTo);
    
    settingMFileString = [settingMFileString, ['this.OperatorRules.', opFields{iOp}, '.ValueFrom = ''', valueFrom, ''';'], sprintf('\n')];
    settingMFileString = [settingMFileString, ['this.OperatorRules.', opFields{iOp}, '.ValueTo = ''', valueTo, ''';'], sprintf('\n')];
end


settingMFileString = [settingMFileString, 'this.SpecialRules = struct();', sprintf('\n'), sprintf('\n')];

specialRules = resStruct.SpecialRules;
spFields = fields(specialRules);

for iSp = 1:numel(spFields)
    settingMFileString = [settingMFileString, sprintf('\n')]; %#ok<*AGROW>
    settingMFileString = [settingMFileString, ['this.SpecialRules.', spFields{iSp}, ' = struct();'], sprintf('\n')];
    settingMFileString = [settingMFileString, ['this.SpecialRules.', spFields{iSp}, 'Value = ''', specialRules.(spFields{iSp}).Value, ''';'], sprintf('\n')];
end

settingMFileString = [settingMFileString, 'end'];

if exist(MBeautify.RulesMFileFull, 'file')
    fileattrib(MBeautify.RulesMFileFull, '+w');
end
fid = fopen(MBeautify.RulesMFileFull, 'w');
fwrite(fid, settingMFileString);
fclose(fid);

end


