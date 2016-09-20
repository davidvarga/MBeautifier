classdef MBeautify
    
    properties(Constant)
        RulesXMLFile = 'MBeautyConfigurationRules.xml';
        RulesMFile = 'MBeautyConfigurationRules.m'
        SettingDirectory = [fileparts(fileparts(mfilename('fullpath'))), filesep, 'resources', filesep, 'settings'];
        RulesMFileFull = [fileparts(fileparts(mfilename('fullpath'))), filesep, 'resources', filesep, 'settings', filesep, 'MBeautyConfigurationRules.m'];
        RulesXMLFileFull = [fileparts(fileparts(mfilename('fullpath'))), filesep, 'resources', filesep, 'settings', filesep, 'MBeautyConfigurationRules.xml'];
        
        CommentTemplate = 'MBeautify_Comment.xml';
    end
    
    properties(Access = private)
        ParsingUpToDate = false;
    end
    
    methods (Static = true, Access = private)
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

    methods(Static = true)
        
        % Function to set-up MBeautifier for use
        %   - (optional) Writes the default settings XML file
        %   - Reads in the settings XML file
        %   - Writes the configuration M-file
        setup();
        
        % Entry point to use MBeautify
        % 
        beautify(source);
        
        createDefaultConfiguration();
         
    end
    
    methods(Static = true, Access = private )
        

        
        [result, nCurrentNewlines] = handleMaximalNewLines(line, nCurrentNewlines, maximalNewLines);
        operators = getAllOperators();
        
        [isSourceAvailable, codeBefore, codeToFormat, codeAfter, selectedPosition, additionalInfo] = handleSource(source);
        formattedSource = performFormatting(source, settingConf)
        writeConfigurationFile(resStruct, fullRulesConfMFileName);
        
        
        % Gets the structure of tokens used during the formatting
        tokenStructs = getTokenStruct();
        
        setDir = getSettingsDirectory()
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Writes the default settings XML file
        writeSettingsXML(fullFilePath);
        
        % Reads the settings XML file to a structure 
        res = readSettingsXML(file);
        
        configurationStruct = getConfigurationStruct();
        
        % StrConcat Util
        function retStr = strConcat( srcStr, varargin )
            
            retStr = srcStr;
            
            if nargin > 1
                retStr = [retStr, varargin{:}];
            else
                return;
            end
        end
        
    end
    
    
    
end

