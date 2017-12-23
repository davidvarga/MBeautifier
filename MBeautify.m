classdef MBeautify
    % Provides static methods to perform code formatting targeting file(s), the currently active editor page or the
    % current selection in editor.
    %   The rules of the formatting are defined in the "MBeautyConfigurationRules.xml" in the resources directory. This
    %   file can be modified to affect the formatting.
    %   Important: Runtime, the M equivalent of this XML file is used, which is created whenever the "setup" static
    %   method is called, therefore always call this method if the XML file has been modified.
    %   To restore the XML file to the default configuration, the "createDefaultConfiguration" static method can be
    %   called.
    %
    %   Example usage:
    %
    %   MBeautify.setup(); % Creates the default rules
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
    
    properties(Access = private, Constant)
        RulesXMLFile = 'MBeautyConfigurationRules.xml';
        RulesMFile = 'MBeautyConfigurationRules.m'
        SettingDirectory = [fileparts(mfilename('fullpath')), filesep, 'resources', filesep, 'settings'];
        RulesMFileFull = [fileparts(mfilename('fullpath')), filesep, 'resources', filesep, 'settings', filesep, 'MBeautyConfigurationRules.m'];
        RulesXMLFileFull = [fileparts(mfilename('fullpath')), filesep, 'resources', filesep, 'settings', filesep, 'MBeautyConfigurationRules.xml'];
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
            
            MBeautify.writeConfigurationFile(MBeautify.readSettingsXML());
            
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
            formatter = MFormatter(MBeautify.getConfigurationStruct());
            document.Text = formatter.performFormatting(document.Text);
            
            document.smartIndentContents();
            
            if nargin >= 2
                if exist(outFile, 'file')
                    fileattrib(outFile, '+w');
                end
                
                document.saveAs(outFile)
                document.close();
            end
        end
        
        function formatFiles(directory, fileFilter)
            % Formats the files in-place (files are overwritten) in the specified directory, collected by the specified filter.
            % The file filter is a wildcard expression used by the dir command.
            
            files = dir(fullfile(directory, fileFilter));
            
            for iF = 1:numel(files)
                file = fullfile(directory, files(iF).name);
                MBeautify.formatFile(file, file);
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
            formatter = MFormatter(MBeautify.getConfigurationStruct());
            formattedSource = formatter.performFormatting(codeToFormat);
            
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
            formatter = MFormatter(MBeautify.getConfigurationStruct());
            currentEditorPage.Text = formatter.performFormatting(currentEditorPage.Text);
            
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
        
        function createShortcut(mode)
            % Creates a shortcut with the selected mode: 'editorpage', 'editorselection', 'file'. The shortcut adds
            % MBeauty to the Matlab path and executes the following command:
            %   'editorpage' - MBeauty.formatCurrentEditorPage
            %   'editorselection' - MBeauty.formatEditorSelection
            %   'file' - MBeauty.formatFile
            
            MBeautyShortcuts.createShortcut(mode);
        end
        
    end
    
    %% Private helpers
    
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
        
        function configurationStruct = getConfigurationStruct()
            % MBeautify.getConfigurationStruct returns the configuration struct from the rules file
            
            % Persistent variable to store the returned rules
            % If MBeautify.setup was not called, the stored struct should be returned
            persistent configurationStructStored;
            
            if isempty(configurationStructStored) || ~MBeautify.parsingUpToDate()
                currCD = cd();
                cd(MBeautify.SettingDirectory);
                configurationStruct = eval(MBeautify.RulesMFile(1:end - 2));
                cd(currCD)
                configurationStructStored = configurationStruct;
                MBeautify.parsingUpToDate(true);
            else
                configurationStruct = configurationStructStored;
            end
            
        end
        
        
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
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Writes the default settings XML file
        function writeSettingsXML()
            % MBeautify.writeSettingsXML creates the default configuration XML structure to the configuration XML file.
            
            docNode = com.mathworks.xml.XMLUtils.createDocument('MBeautifyRuleConfiguration');
            docRootNode = docNode.getDocumentElement();
            
            operatorPaddings = docNode.createElement('OperatorPadding');
            docRootNode.appendChild(operatorPaddings);
            
            specialRules = docNode.createElement('SpecialRules');
            docRootNode.appendChild(specialRules);
            
            %% Add operator rules
            operatorPaddings = appendOperatorPaddingRule('ShortCircuitAnd', '&amp;&amp;', ' &amp;&amp; ', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('ShortCircuitOr', '||', ' || ', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('LogicalAnd', '&amp;', ' &amp; ', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('LogicalOr', '|', ' | ', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('LessEquals', '&lt;=', ' &lt;= ', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('Less', '&lt;', ' &lt; ', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('GreaterEquals', '&gt;=', ' &gt;= ', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('Greater', '&gt;', ' &gt; ', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('Equals', '==', ' == ', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('NotEquals', '~=', ' ~= ', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('Assignment', '=', ' = ', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('Plus', '+', ' + ', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('Minus', '-', ' - ', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('ElementWiseMultiplication', '.*', ' .* ', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('Multiplication', '*', ' * ', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('RightArrayDivision', './', ' ./ ', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('LeftArrayDivision', '.\', ' .\ ', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('Division', '/', ' / ', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('LeftDivision', '\', ' \ ', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('ElementWisePower', '.^', '.^', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('Power', '^', '^', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('Not', '~', ' ~', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('Comma', ',', ', ', operatorPaddings, docNode);
            operatorPaddings = appendOperatorPaddingRule('SemiColon', ';', '; ', operatorPaddings, docNode);
            appendOperatorPaddingRule('Colon', ':', ':', operatorPaddings, docNode);
            
            %% Add special rules
            specialRules = appendSpecialRule('MaximalNewLines', '2', specialRules, docNode);
            specialRules = appendSpecialRule('AddCommasToMatrices', '1', specialRules, docNode);
            specialRules = appendSpecialRule('AddCommasToCellArrays', '1', specialRules, docNode);
            specialRules = appendSpecialRule('CellArrayIndexing_ArithmeticOperatorPadding', '0', specialRules, docNode);
            appendSpecialRule('MatrixIndexing_ArithmeticOperatorPadding', '0', specialRules, docNode);
            
            xmlwrite(MBeautify.RulesXMLFileFull, docNode);
            
            fprintf('Default configuration XML has been created:\n%s\n', MBeautify.RulesXMLFileFull);
            
            
            function operatorPaddings = appendOperatorPaddingRule(key, valueFrom, valueTo, operatorPaddings, docNode)
                opPaddingRule = docNode.createElement('OperatorPaddingRule');
                
                keyElement = docNode.createElement('Key');
                keyElement.appendChild(docNode.createTextNode(key));
                
                valueFromElement = docNode.createElement('ValueFrom');
                valueFromElement.appendChild(docNode.createTextNode(valueFrom));
                
                valueToElement = docNode.createElement('ValueTo');
                valueToElement.appendChild(docNode.createTextNode(valueTo));
                
                opPaddingRule.appendChild(keyElement);
                opPaddingRule.appendChild(valueFromElement);
                opPaddingRule.appendChild(valueToElement);
                
                operatorPaddings.appendChild(opPaddingRule);
                
            end
            
            function specialRules = appendSpecialRule(key, value, specialRules, docNode)
                specialRule = docNode.createElement('SpecialRule');
                
                keyElement = docNode.createElement('Key');
                keyElement.appendChild(docNode.createTextNode(key));
                
                valueElement = docNode.createElement('Value');
                valueElement.appendChild(docNode.createTextNode(value));
                
                specialRule.appendChild(keyElement);
                specialRule.appendChild(valueElement);
                
                specialRules.appendChild(specialRule);
                
            end
            
        end
        
        % Reads the settings XML file to a structure
        function settingsStruct = readSettingsXML()
            % MBeautify.readSettingsXML reads the configuration XML file to a structure.
            
            settingsStruct = struct('OperatorRules', struct(), 'SpecialRules', struct());
            
            XMLDoc = xmlread(MBeautify.RulesXMLFileFull);
            
            allOperatorItems = XMLDoc.getElementsByTagName('OperatorPaddingRule');
            operatorNode = settingsStruct.OperatorRules;
            
            for iOperator = 0:allOperatorItems.getLength() -1
                
                currentOperator = allOperatorItems.item(iOperator);
                
                key = char(currentOperator.getElementsByTagName('Key').item(0).getTextContent().toString());
                operatorNode.(key) = struct();
                operatorNode.(key).ValueFrom = removeXMLEscaping(char(currentOperator.getElementsByTagName('ValueFrom').item(0).getTextContent().toString()));
                operatorNode.(key).ValueTo = removeXMLEscaping(char(currentOperator.getElementsByTagName('ValueTo').item(0).getTextContent().toString()));
            end
            
            settingsStruct.OperatorRules = operatorNode;
            
            allSpecialItems = XMLDoc.getElementsByTagName('SpecialRule');
            specialRulesNode = settingsStruct.SpecialRules;
            
            for iSpecRule = 0:allSpecialItems.getLength() -1
                
                currentRule = allSpecialItems.item(iSpecRule);
                
                key = char(currentRule.getElementsByTagName('Key').item(0).getTextContent().toString());
                specialRulesNode.(key) = struct();
                specialRulesNode.(key).Value = char(currentRule.getElementsByTagName('Value').item(0).getTextContent().toString());
            end
            
            settingsStruct.SpecialRules = specialRulesNode;
            
            function escapedValue = removeXMLEscaping(value)
                escapedValue = regexprep(value, '&lt;', '<');
                escapedValue = regexprep(escapedValue, '&amp;', '&');
                escapedValue = regexprep(escapedValue, '&gt;', '>');
                
            end
            
        end
        
      
    end
end

