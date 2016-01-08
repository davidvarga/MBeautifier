function writeConfigurationFile(resStruct, fullRulesConfMFileName)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

operetorRules = resStruct.OperatorRules;
opFields = fields(operetorRules);

[pathOfMFile, nameOfMFile] = fileparts(fullRulesConfMFileName); %#ok<ASGLU>

settingMFileString = ['function this = ', nameOfMFile, '()', sprintf('\n'), ...
    'this = struct();', sprintf('\n'), sprintf('\n')];

settingMFileString = [settingMFileString, 'this.OperatorRules = struct();', sprintf('\n'), sprintf('\n')];

for iOp = 1:numel(opFields)
    
    settingMFileString = MBeautify.strConcat(settingMFileString,sprintf('\n'));
    settingMFileString = MBeautify.strConcat(settingMFileString, ['this.OperatorRules.', opFields{iOp}, ' = struct();'], sprintf('\n'));
    
    valueFrom = regexptranslate('escape', operetorRules.(opFields{iOp}).ValueFrom);
    
    settingMFileString = MBeautify.strConcat(settingMFileString, ['this.OperatorRules.', opFields{iOp}, '.ValueFrom = ''', valueFrom, ''';'], sprintf('\n'));
    settingMFileString = MBeautify.strConcat(settingMFileString, ['this.OperatorRules.', opFields{iOp}, '.ValueTo = ''', operetorRules.(opFields{iOp}).ValueTo, ''';'], sprintf('\n'));   
end


settingMFileString = [settingMFileString, 'this.SpecialRules = struct();', sprintf('\n'), sprintf('\n')];

specialRules = resStruct.SpecialRules;
spFields = fields(specialRules);

for iSp = 1:numel(spFields)
    settingMFileString = MBeautify.strConcat(settingMFileString,sprintf('\n'));
    settingMFileString = MBeautify.strConcat(settingMFileString, ['this.SpecialRules.', spFields{iSp}, ' = struct();'], sprintf('\n'));
    settingMFileString = MBeautify.strConcat(settingMFileString, ['this.SpecialRules.', spFields{iSp}, 'Value = ''', specialRules.(spFields{iSp}).Value, ''';'], sprintf('\n'));
end

settingMFileString = MBeautify.strConcat(settingMFileString, 'end');

if exist(fullRulesConfMFileName, 'file')
    fileattrib(fullRulesConfMFileName, '+w');
end
fid = fopen(fullRulesConfMFileName, 'w');
fwrite(fid, settingMFileString);
fclose(fid);

end

