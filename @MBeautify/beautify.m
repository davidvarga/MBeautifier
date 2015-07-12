function beautify(source)


% Handle the source
[codeToFormat, additionalInfo] = MBeautify.handleSource(source);
currentSelection = additionalInfo.Selection;

% Get the current configuration
settingConf = MBeautify.getConfigurationStruct();
%
% % Use Matlab smart indent at first
% additionalInfo.smartIndentContents();

% Format the code
formattedSource = MBeautify.performFormatting(codeToFormat, settingConf);

% Save back the modified data then use Matlab samrt indent functionality
% Set back the selection
additionalInfo.Text = formattedSource;
if ~isempty(currentSelection)
    additionalInfo.goToLine(currentSelection(1));
end
additionalInfo.smartIndentContents();
additionalInfo.makeActive();


end
