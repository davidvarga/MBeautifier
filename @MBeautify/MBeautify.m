classdef MBeautify
    
    properties(Constant)
        %testcl = testclass();
        FormatTemplate = 'MBeautify_Format.xml';
        CommentTemplate = 'MBeautify_Comment.xml';
    end
    
    methods(Static = true)
        
        beautify(source);
        tokenStructs = getTokenStruct();
        tokens = getAllTokens();
        [source, codeToFormat] = handleSource(sourceInput);
        
        %% ToDO: go to private
        res = readSettingsXML();
        
    end
    
    methods(Static = true, Access = private )
        
        [result, nCurrentNewlines] = handleMaximalNewLines(line, nCurrentNewlines, maximalNewLines)
        
    end
    
    
    
end

