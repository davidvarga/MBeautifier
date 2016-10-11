classdef MBeautify
    
    properties(Constant)
        RulesXMLFile = 'MBeautyConfigurationRules.xml';
        RulesMFile = 'MBeautyConfigurationRules.m'
        SettingDirectory = [fileparts(fileparts(mfilename('fullpath'))), filesep, 'resources', filesep, 'settings'];
        RulesMFileFull = [fileparts(fileparts(mfilename('fullpath'))), filesep, 'resources', filesep, 'settings', filesep, 'MBeautyConfigurationRules.m'];
        RulesXMLFileFull = [fileparts(fileparts(mfilename('fullpath'))), filesep, 'resources', filesep, 'settings', filesep, 'MBeautyConfigurationRules.xml'];
    end
    
    properties(Access = private)
        ParsingUpToDate = false;
    end
    
    methods(Static = true, Access = private)
        % Method to mimic a static data member
        % Indicates that the token parsing is up to date or the rules file should be reparsed
        function val = parsingUpToDate(val)
            persistent currentval;
            if isempty(currentval)
                currentval = true;
            end
            if nargin >= 1
                currentval = val;
            end
            
            val = currentval;
        end
    end
    
    %% Public API
    
    methods(Static = true)
        
        function setup()
            % MBeautify.setup() initializes MBeautifier for first use and usable to update the formatting configuration.
            % It optionally writes the default settings XML file, reads in the settings XML file and then writes the
            % configuration M-file which will be used in runtime.
            
            
            if ~exist(MBeautify.RulesXMLFileFull, 'file')
                MBeautify.writeSettingsXML();
            end
            
            resStruct = MBeautify.readSettingsXML();
            
            MBeautify.writeConfigurationFile(resStruct);
            
            fprintf('Configuration was successfully exported to:\n%s\n', MBeautify.RulesMFileFull);
            MBeautify.parsingUpToDate(false);
        end
        
        function createDefaultConfiguration()
            % Writes the default configuration XML file.
            
            MBeautify.writeSettingsXML();
        end
        
        function formatFile(file, outFile)
            % Formats the file specified in the first argument. The file is opened in the Matlab Editor. If the second
            % argument is also specified, the formatted source is saved to this file. Otherwise the formatted input
            % file remains opened in the Matlab Editor. The input and the output file can be the same.
            if ~exist(file, 'file')
                return;
            end
            
            document = matlab.desktop.editor.openDocument(file);
            % Format the code
            document.Text = MBeautify.performFormatting(document.Text);
            document.smartIndentContents();
            
            if nargin >= 2
                if exist(outFile, 'file')
                    fileattrib(outFile, '+w');
                end
                
                document.saveAs(outFile)
                document.close();
            end
        end
        
        function formatEditorSelection(doSave)
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
            if currentSelection(1) > 1
                lineBeforePosition = [currentSelection(1) - 1, 1, currentSelection(1) - 1, Inf];
                
                currentEditorPage.Selection = lineBeforePosition;
                lineBeforeText = currentEditorPage.SelectedText;
                
                while lineBeforePosition(1) > 1 && ~isempty(strtrim(lineBeforeText))
                    lineBeforePosition = [lineBeforePosition(1) - 1, 1, lineBeforePosition(1) - 1, Inf];
                    currentEditorPage.Selection = lineBeforePosition;
                    lineBeforeText = currentEditorPage.SelectedText;
                end
            end
            expandedSelection = [lineBeforePosition(1), 1, expandedSelection(3), Inf];
            
            % Search for the first empty line after the selection
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
            
            endReached = isequal(lineAfterSelection(1), currentSelection(1));
            
            expandedSelection = [expandedSelection(1), 1, lineAfterSelection(3), Inf];
            
            if isequal(currentSelection(1), 1)
                codeBefore = '';
            else
                codeBeforeSelection = [1, 1, expandedSelection(1), Inf];
                currentEditorPage.Selection = codeBeforeSelection;
                codeBefore = currentEditorPage.SelectedText;
            end
            
            if endReached
                codeAfter = '';
            else
                codeAfterSelection = [expandedSelection(3) + 1, 1, Inf, Inf];
                currentEditorPage.Selection = codeAfterSelection;
                codeAfter = currentEditorPage.SelectedText;
                
            end
            
            currentEditorPage.Selection = expandedSelection;
            codeToFormat = currentEditorPage.SelectedText;
            selectedPosition = currentEditorPage.Selection;
            
            % Format the code
            formattedSource = MBeautify.performFormatting(codeToFormat);
            
            % Save back the modified data then use Matlab samrt indent functionality
            % Set back the selection
            currentEditorPage.Text = [codeBefore, formattedSource, codeAfter];
            if ~isempty(selectedPosition)
                currentEditorPage.goToLine(selectedPosition(1));
            end
            currentEditorPage.smartIndentContents();
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
            currentEditorPage.Text = MBeautify.performFormatting(currentEditorPage.Text);
            % Set back the selection
            if ~isempty(selectedPosition)
                currentEditorPage.goToLine(selectedPosition(1));
            end
            % Use Smart Indent
            currentEditorPage.smartIndentContents();
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
        
    end
    
    %% Private helpers
    
    methods(Static = true, Access = private)
     
        operators = getAllOperators();
        
        formattedSource = performFormatting(source);
        writeConfigurationFile(resStruct);
        
        % Gets the structure of tokens used during the formatting
        tokenStructs = getTokenStruct();
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Writes the default settings XML file
        writeSettingsXML();
        
        % Reads the settings XML file to a structure
        res = readSettingsXML();
        
        configurationStruct = getConfigurationStruct();
    end
    
    
end


