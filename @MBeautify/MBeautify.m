classdef MBeautify
    
    properties(Constant)
        %testcl = testclass();
        RulesFile = 'MBeautyRules.xml';
        CommentTemplate = 'MBeautify_Comment.xml';
    end
    
    methods(Static = true)
        
        beautify(source);
        tokenStructs = getTokenStruct();
        tokens = getAllTokens();
        [source, codeToFormat] = handleSource(sourceInput);
        setup();
         
    end
    
    methods(Static = true, Access = private )
        
        [result, nCurrentNewlines] = handleMaximalNewLines(line, nCurrentNewlines, maximalNewLines)
        res = readSettingsXML(file);
    end
    
    
    
end

