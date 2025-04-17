classdef MBeautify
    % Provides static methods to perform code formatting targeting file(s), the currently active editor page or the
    % current selection in editor.
    %   The rules of the formatting are defined in the "MBeautyConfigurationRules.xml" in the resources directory. This
    %   file can be modified to affect the formatting.
    %
    %   Example usage:
    %
    %   MBeautify.formatCurrentEditorPage(); % Formats the current page in editor without saving
    %   MBeautify.formatCurrentEditorPage(); % Formats the current page in editor with saving
    %   MBeautify.formatFile('D:\testFile.m', 'D:\testFileNew.m'); % Formats the first file into the second file
    %   MBeautify.formatFile('D:\testFile.m', 'D:\testFile.m'); % Formats the first file in-place
    %   MBeautify.formatFiles('D:\mydir', '*.m'); % Formats all files in the specified diretory in-place
    %
    %   Shortcuts:
    %
    %   Shortcuts can be automatically created for "formatCurrentEditorPage", "formatEditorSelection" and
    %   "formatFile" methods by executing MBeautify.createShortcut() in order with the parameter 'editorpage',
    %   'editorselection' or 'file'.
    %   The created shortcuts add MBeauty to the Matlab path also (therefore no preparation of the path is needed additionally).
    
    properties (Access = private, Constant)
        RulesXMLFile = 'MBeautyConfigurationRules.xml';
        SettingDirectory = [fileparts(mfilename('fullpath')), filesep, 'resources', filesep, 'settings'];
        RulesMFileFull = [fileparts(mfilename('fullpath')), filesep, 'resources', filesep, 'settings', filesep, 'MBeautyConfigurationRules.m'];
        RulesXMLFileFull = [fileparts(mfilename('fullpath')), filesep, 'resources', filesep, 'settings', filesep, 'MBeautyConfigurationRules.xml'];
    end
    
    %% Public API
    
    methods (Static = true)
        
        function formatFileNoEditor(file, outFile)
            % Format file outside of editor
            % function formatFileNoEditor(file, outFile)
            %
            % Formats the file specified in the first argument. If the
            % second argument is also specified, the formatted source is
            % saved to this file. The input and the output file can be the
            % same, in which case the format operation is carried out
            % in-place.
            %
            if ~exist(file, 'file')
                return;
            end
            
            text = fileread(file);
            
            % Format the code
            configuration = MBeautify.getConfiguration();
            formatter = MBeautifier.MFormatter(configuration);
            text = formatter.performFormatting(text);
            
            % Indent the code
            indenter = MBeautifier.MIndenter(configuration);
            text = indenter.performIndenting(text);
            
            if (nargin == 1)
                outFile = file;
            end
            
            % write formatted text to file
            fid = fopen(outFile, 'wt');
            fprintf(fid, '%s', text);
            fclose(fid);
        end
        
        function formatFile(file, outFile)
            % Format file in editor
            % function formatFile(file, outFile)
            %
            % Formats the file specified in the first argument. The file is opened in the Matlab Editor. If the second
            % argument is also specified, the formatted source is saved to this file and it is closed if it wasn't already
            % open in the Editor. Otherwise the formatted input file remains opened in the Matlab Editor.
            % The input and the output file can be the same.
            if ~exist(file, 'file')
                return;
            end
            
            isOpen = matlab.desktop.editor.isOpen(file);
            document = matlab.desktop.editor.openDocument(file);
            % Format the code
            configuration = MBeautify.getConfiguration();
            formatter = MBeautifier.MFormatter(configuration);
            document.Text = formatter.performFormatting(document.Text);
            
            MBeautify.indentPage(document, configuration);
            
            if nargin >= 2
                if exist(outFile, 'file')
                    fileattrib(outFile, '+w');
                end
                
                document.saveAs(outFile)
                if ~isOpen
                    document.close();
                end
            end
        end
        
        function formatFiles(directory, fileFilter, recurse, editor)
            % Format multiple files in-place. Supports file type filtering and subfolder recursion
            % function formatFiles(directory, fileFilter, recurse)
            %
            % Formats the files in-place (files are overwritten) in the
            % specified directory, collected by the specified filter and optionally recurse subfolders.
            % The file filter is a wildcard expression used by the dir
            % command. Defaults to '*.m'
            %
            % Recurse defaults to false. Set true to recurse subfolders of directory.
            % Editor defaults to true.  Set to false to format files outside the editor.
            
            if nargin < 2
                fileFilter = '*.m';
            end
            
            if ~exist('recurse','var') || isempty(recurse)
                recurse = false;
            end
            
            if ~exist('editor','var') || isempty(editor)
                editor = true;
            end
            
            if recurse
                directory = fullfile(directory, '**');
            end
            
            files = dir(fullfile(directory, fileFilter));
            
            for iF = 1:numel(files)
                file = fullfile(files(iF).folder, files(iF).name);
                if editor
                    MBeautify.formatFile(file, file);
                else
                    MBeautify.formatFileNoEditor(file, file);
                end
            end
        end
        
        function formatEditorSelection(doSave)
            %
            % function formatEditorSelection(doSave)
            %
            % Performs formatting on selection of the currently active Matlab Editor page.
            % The selection is automatically extended until the first empty line above and below.
            % This method can be useful for large files, but using "formatCurrentEditorPage" is always suggested.
            % Optionally saves the file (if it is possible) and it is forced on the first argument (true). By default
            % the file is not saved.
            
            currentEditorPage = matlab.desktop.editor.getActive();
            
            if isempty(currentEditorPage)
                return;
            end
            
            currentSelection = currentEditorPage.Selection;
            
            if isempty(currentEditorPage.SelectedText)
                return;
            end
            
            if nargin == 0
                doSave = false;
            end
            
            % Expand the selection from the beginnig of the first line to the end of the last line
            expandedSelection = [currentSelection(1), 1, currentSelection(3), Inf];
            
            
            % Search for the first empty line before the selection
            
            % First test the first line of the selection for emptiness
            currentEditorPage.Selection = [currentSelection(1), 1,  currentSelection(1), Inf];
            if (isempty(strtrim(currentEditorPage.SelectedText)))
                lineBeforePosition = currentSelection(1);
            else
                % Otherwise look for the first empty line before
                if currentSelection(1) > 1
                    lineBeforePosition = [currentSelection(1) - 1, 1, currentSelection(1) - 1, Inf];
                    
                    currentEditorPage.Selection = lineBeforePosition;
                    lineBeforeText = currentEditorPage.SelectedText;
                    
                    while lineBeforePosition(1) > 1 && ~isempty(strtrim(lineBeforeText))
                        lineBeforePosition = [lineBeforePosition(1) - 1, 1, lineBeforePosition(1) - 1, Inf];
                        currentEditorPage.Selection = lineBeforePosition;
                        lineBeforeText = currentEditorPage.SelectedText;
                    end
                else
                    lineBeforePosition = 1;
                end
            end
            
            
            expandedSelection = [lineBeforePosition(1), 1, expandedSelection(3), Inf];
            
            % Search for the first empty line after the selection
            % First test the last line of the selection for emptiness
            currentEditorPage.Selection = [currentSelection(3), 1, currentSelection(3), Inf];
            if (isempty(strtrim(currentEditorPage.SelectedText)))
                lineAfterSelection = [currentSelection(3), 1, currentSelection(3), Inf];
            else
                % Otherwise look for the first empty line after
                lineAfterSelection = [currentSelection(3) + 1, 1, currentSelection(3) + 1, Inf];
                currentEditorPage.Selection = lineAfterSelection;
                lineAfterText = currentEditorPage.SelectedText;
                beforeselect = currentSelection(1);
                while ~isequal(lineAfterSelection(1), beforeselect) && ~isempty(strtrim(lineAfterText))
                    beforeselect = lineAfterSelection(1);
                    lineAfterSelection = [lineAfterSelection(1) + 1, 1, lineAfterSelection(1) + 1, Inf];
                    currentEditorPage.Selection = lineAfterSelection;
                    lineAfterText = currentEditorPage.SelectedText;
                end
            end
          
           
            endReached = isequal(lineAfterSelection(1), currentSelection(1));
            expandedSelection = [expandedSelection(1), 1, lineAfterSelection(3), Inf];
            
            if isequal(expandedSelection(1), 1)
                codeBefore = '';
            else
                codeBeforeSelection = [1, 1, expandedSelection(1), Inf];
                currentEditorPage.Selection = codeBeforeSelection;
                codeBefore = [currentEditorPage.SelectedText, MBeautifier.Constants.NewLine];
            end
            
            if endReached
                codeAfter = '';
            else
                codeAfterSelection = [expandedSelection(3), 1, Inf, Inf];
                currentEditorPage.Selection = codeAfterSelection;
                codeAfter = currentEditorPage.SelectedText;
            end
            
            currentEditorPage.Selection = expandedSelection;
            codeToFormat = currentEditorPage.SelectedText;
            selectedPosition = currentEditorPage.Selection;
            
            % Format the code
            configuration = MBeautify.getConfiguration();
            formatter = MBeautifier.MFormatter(configuration);
            formattedSource = formatter.performFormatting(codeToFormat);
            
            % Save back the modified data then use Matlab samrt indent functionality
            % Set back the selection
            currentEditorPage.Text = [codeBefore, formattedSource, codeAfter];
            MBeautify.indentPage(currentEditorPage, configuration);
            if ~isempty(selectedPosition)
                currentEditorPage.goToPositionInLine(selectedPosition(1), selectedPosition(2));
            end
            currentEditorPage.Selection = expandedSelection;
            currentEditorPage.makeActive();
            
            % Save if it is possible
            if doSave
                fileName = currentEditorPage.Filename;
                if exist(fileName, 'file') && numel(fileparts(fileName))
                    fileattrib(fileName, '+w');
                    currentEditorPage.saveAs(currentEditorPage.Filename)
                end
            end
        end
        
        function formatCurrentEditorPage(doSave)
            % Performs formatting on the currently active Matlab Editor page.
            % function formatCurrentEditorPage(doSave)
            %
            % Optionally saves the file (if it is possible) and it is forced on the first argument (true). By default
            % the file is not saved.
            
            currentEditorPage = matlab.desktop.editor.getActive();
            if isempty(currentEditorPage)
                return;
            end
            
            if nargin == 0
                doSave = false;
            end
            
            selectedPosition = currentEditorPage.Selection;
            
            % Format the code
            configuration = MBeautify.getConfiguration();
            formatter = MBeautifier.MFormatter(configuration);
            currentEditorPage.Text = formatter.performFormatting(currentEditorPage.Text);
            
            % Use Smart Indent
            MBeautify.indentPage(currentEditorPage, configuration);

            % Set back the selection
            if ~isempty(selectedPosition)
                currentEditorPage.goToPositionInLine(selectedPosition(1), selectedPosition(2));
            end
            
            currentEditorPage.makeActive();
            
            % Save if it is possible
            if doSave
                fileName = currentEditorPage.Filename;
                if exist(fileName, 'file') && numel(fileparts(fileName))
                    fileattrib(fileName, '+w');
                    currentEditorPage.saveAs(currentEditorPage.Filename)
                end
            end
        end
        
        function createShortcut(mode)
            % Adds MBeauty to path and creates shortcut in Matlab editor
            % function createShortcut(mode)
            %
            % Creates a shortcut with the selected mode: 'editorpage', 'editorselection', 'file'. The shortcut adds
            % MBeauty to the Matlab path and executes the following command:
            %   'editorpage' - MBeauty.formatCurrentEditorPage
            %   'editorselection' - MBeauty.formatEditorSelection
            %   'file' - MBeauty.formatFile
            
            MBeautyShortcuts.createShortcut(mode);
        end
    end
    
    %% Private helpers
    
    methods (Static = true, Access = private)
        function indentPage(editorPage, configuration)
            %
            % function indentPage(editorPage, configuration)
            %
            
            indentationStrategy = configuration.specialRule('Indentation_Strategy').Value;
            originalPreference = com.mathworks.services.Prefs.getStringPref('EditorMFunctionIndentType');
            
            switch lower(indentationStrategy)
                case 'allfunctions'
                    com.mathworks.services.Prefs.setStringPref('EditorMFunctionIndentType', 'AllFunctionIndent');
                case 'nestedfunctions'
                    com.mathworks.services.Prefs.setStringPref('EditorMFunctionIndentType', 'MixedFunctionIndent');
                case 'noindent'
                    com.mathworks.services.Prefs.setStringPref('EditorMFunctionIndentType', 'ClassicFunctionIndent');
            end
            
            editorPage.smartIndentContents();
            
            % Restore original settings, if necessary
            if (length(originalPreference) > 0 && originalPreference ~= com.mathworks.services.Prefs.getStringPref('EditorMFunctionIndentType'))
                com.mathworks.services.Prefs.setStringPref('EditorMFunctionIndentType', originalPreference);
            end
            
            indentationCharacter = configuration.specialRule('IndentationCharacter').Value;
            indentationCount = configuration.specialRule('IndentationCount').ValueAsDouble;
            makeBlankLinesEmpty = configuration.specialRule('Indentation_TrimBlankLines').ValueAsDouble;
            
            if strcmpi(indentationCharacter, 'white-space') && indentationCount == 4 && ~makeBlankLinesEmpty
                return
            end
            
            if strcmpi(indentationCharacter, 'white-space')
                regexIndentCharacter = ' ';
            elseif strcmpi(indentationCharacter, 'tab')
                regexIndentCharacter = '\t';
            else
                warning('MBeautifier:IllegalSetting:IndentationCharacter', 'MBeautifier: The indentation character must be set to "white-space" or "tab". MBeautifier using MATLAB defaults.');
                regexIndentCharacter = ' ';
                indentationCount = 4;
            end
            
            neededIndentation = regexIndentCharacter;
            for i = 2:indentationCount
                neededIndentation = [neededIndentation, regexIndentCharacter];
            end
            
            newLine = MBeautifier.Constants.NewLine;
            textArray = regexp(editorPage.Text, newLine, 'split');
            
            skipIndentation = strcmpi(indentationCharacter, 'white-space') && indentationCount == 4;
            
            for i = 1:numel(textArray)
                cText = textArray{i};
                if ~skipIndentation
                    [~, ~, whiteSpaceCount] = regexp(cText, '^( )+', 'match');
                    if isempty(whiteSpaceCount)
                        whiteSpaceCount = 0;
                    end
                    
                    amountOfReplace = floor(whiteSpaceCount/4);
                    if amountOfReplace == 0
                        continue
                    end
                    
                    searchString = '    ';
                    replaceString = neededIndentation;
                    for iAmount = 2:amountOfReplace
                        searchString = [searchString, '    '];
                        replaceString = [replaceString, neededIndentation];
                    end
                    
                    cText = regexprep(cText, ['^', searchString], replaceString);
                end
                
                if makeBlankLinesEmpty
                    trimmedLine = strtrim(cText);
                    if isempty(trimmedLine)
                        cText = trimmedLine;
                    end
                end
                
                textArray{i} = cText;
            end
            
            editorPage.Text = strjoin(textArray, '\n');
        end
        
        function configuration = getConfiguration()
            %
            % function configuration = getConfiguration()
            %
            
            [parent, file, ext] = fileparts(MBeautify.RulesXMLFileFull);
            path = java.nio.file.Paths.get(parent, [file, ext]);
            
            if ~path.toFile.exists()
                error('MBeautifier:Configuration:ConfigurationFileDoesNotExist', 'The configuration XML file is missing!');
            end
            
            bytes = java.nio.file.Files.readAllBytes(path);
            md = java.security.MessageDigest.getInstance('md5');
            currentChecksum = javax.xml.bind.DatatypeConverter.printHexBinary(md.digest(bytes));
            storedChecksum = getappdata(0, 'MBeautifier_ConfigurationChecksum');
            if isempty(storedChecksum)
                storedChecksum = '';
            end
            configuration = [];
            if strcmpi(currentChecksum, storedChecksum)
                configuration = getappdata(0, 'MBeautifier_ConfigurationObject');
            end
            if isempty(configuration)
                configuration = MBeautifier.Configuration.Configuration.fromFile(MBeautify.RulesXMLFileFull);
                setappdata(0, 'MBeautifier_ConfigurationChecksum', currentChecksum);
                setappdata(0, 'MBeautifier_ConfigurationObject', configuration);
            end
        end
    end
end
