function setup()
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

rootDir = fileparts(fileparts(mfilename('fullpath')));
setDir = [rootDir, filesep, 'resources', filesep, 'settings'];
defSetFile = fullfile(setDir, 'MBeautyRules.xml');




resStruct = MBeautify.readSettingsXML(defSetFile);


%% ToDo: Split to another file

operetorRules = resStruct.OperatorRules;
opFields = fields(operetorRules);
settingMFileString = ['function this = settingsConfiguration()', sprintf('\n'), ...
    'this = struct();', sprintf('\n'), sprintf('\n')];

for iOp = 1:numel(opFields)
    settingMFileString = strConcat(settingMFileString,sprintf('\n'));
    settingMFileString = strConcat(settingMFileString, ['this.', opFields{iOp}, ' = struct();'], sprintf('\n'));
    settingMFileString = strConcat(settingMFileString, ['this.', opFields{iOp}, '.ValueFrom = ''', operetorRules.(opFields{iOp}).ValueFrom, ''';'], sprintf('\n'));
    settingMFileString = strConcat(settingMFileString, ['this.', opFields{iOp}, '.ValueTo = ''', operetorRules.(opFields{iOp}).ValueTo, ''';'], sprintf('\n'));
    
    
end

settingMFileString = strConcat(settingMFileString, 'end');
fid = fopen(fullfile(setDir, 'settingsConfiguration.m'), 'w');
fwrite(fid, settingMFileString);
fclose(fid);

end

