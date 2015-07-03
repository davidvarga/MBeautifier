function setup()
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

rootDir = fileparts(fileparts(mfilename('fullpath')));
setDir = [rootDir, filesep, 'resources', filesep, 'settings'];
defSetFile = fullfile(setDir, 'MBeautyRules.xml');




resStruct = MBeautify.readSettingsXML(defSetFile);


end

