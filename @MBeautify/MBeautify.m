classdef MBeautify
    
    properties(Constant)
        RulesXMLFile = 'MBeautyConfigurationRules.xml';
        RulesMFile = 'MBeautyConfigurationRules.m'
        SettingDirectory = [fileparts(fileparts(mfilename('fullpath'))), filesep, 'resources', filesep, 'settings'];
        RulesMFileFull = [fileparts(fileparts(mfilename('fullpath'))), filesep, 'resources', filesep, 'settings', filesep, 'MBeautyConfigurationRules.m'];
        RulesXMLFileFull = [fileparts(fileparts(mfilename('fullpath'))), filesep, 'resources', filesep, 'settings', filesep, 'MBeautyConfigurationRules.xml'];
        
        CommentTemplate = 'MBeautify_Comment.xml';
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
        
        [codeBefore, codeToFormat, codeAfter, selectedPosition, additionalInfo] = handleSource(source);
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
        
    end
    
    
    
end

