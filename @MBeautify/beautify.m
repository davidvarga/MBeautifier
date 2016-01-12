function beautify(source)


% Handle the source
[isSourceAvailable, codeBefore, codeToFormat, codeAfter, selectedPosition, additionalInfo] = MBeautify.handleSource(source);
if ~isSourceAvailable
   return; 
end
currentSelection = selectedPosition;

% Get the current configuration
settingConf = MBeautify.getConfigurationStruct();
%
% % Use Matlab smart indent at first
% additionalInfo.smartIndentContents();

% Format the code
formattedSource = MBeautify.performFormatting(codeToFormat, settingConf);

% Save back the modified data then use Matlab samrt indent functionality
% Set back the selection
additionalInfo.Text = [codeBefore, formattedSource, codeAfter];
if ~isempty(currentSelection)
    additionalInfo.goToLine(currentSelection(1));
end
additionalInfo.smartIndentContents();
additionalInfo.makeActive();


end
