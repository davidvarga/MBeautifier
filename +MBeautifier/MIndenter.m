classdef MIndenter < handle
    % Performs code indenting. Should not be used directly but only by
    % MBeautify.
    
    properties (Constant)
        Delimiters = {' ', '\f', '\n', '\r', '\t', '\v', ...
            ','};
        KeywordsIncrease = {'function', 'classdef', 'properties', ...
            'methods', 'if', 'for', 'parfor', 'switch', 'try', 'while', ...
            'arguments', 'enumeration'};
        KeywordsSandwich = {'else', 'elseif', 'case', 'otherwise', ...
            'catch'};
        KeywordsDecrease = {'end', 'end;'};
    end
    
    properties (Access = private)
        Configuration;
    end
    
    methods
        function obj = MIndenter(configuration)
            % Creates a new formatter using the passed configuration.
            obj.Configuration = configuration;
        end
        
        function indentedSource = performIndenting(obj, source)
            % indentation strategy:
            % allfunctions (default) = AllFunctionIndent
            % nestedfunctions = MixedFunctionIndent (MATLAB default)
            % noindent = ClassicFunctionIndent
            strategy = obj.Configuration.specialRule('Indentation_Strategy').Value;
            
            % determine indent string
            indentationCharacter = obj.Configuration.specialRule('IndentationCharacter').Value;
            indentationCount = obj.Configuration.specialRule('IndentationCount').ValueAsDouble;
            if strcmpi(indentationCharacter, 'white-space')
                indent = ' ';
                for i = 2:indentationCount
                    indent = [' ', indent];
                end
            elseif strcmpi(indentationCharacter, 'tab')
                indent = '\t';
            else
                warning('MBeautifier:IllegalSetting:IndentationCharacter', 'MBeautifier: The indentation character must be set to "white-space" or "tab". MBeautifier using MATLAB defaults.');
                indent = '    ';
            end
            
            % TODO
            makeBlankLinesEmpty = obj.Configuration.specialRule('Indentation_TrimBlankLines').ValueAsDouble;
            
            % currently in continuation mode (line before ended with ...)?
            continuationMode = 0;
            % layer of indentatino (next line)
            layerNext = 0;
            % this stack keeps track of the keywords
            stack = {};
            
            % start indenting
            newLine = MBeautifier.Constants.NewLine;
            lines = regexp(source, newLine, 'split');
            for linect = 1:numel(lines)
                % layer of indentation (current line)
                layer = layerNext;
                
                % remove existing indentation and whitespace
                lines{linect} = strtrim(lines{linect});
                
                % remove strings and comments for processing
                line = regexprep(lines{linect}, '(".*")|(''.*'')|(%.*)', '');

                % split line in words
                pattern = ['[', obj.joinString(obj.Delimiters, '|'), ']'];
                words = regexp(line, pattern, 'split');
                % ignore empty lines and comments
                if (~isempty(line) && (line(1) ~= '%'))
                    % find keywords and adjust indent
                    for wordct = 1:numel(words)
                        % detect end of line comments
                        if (strcmp(words{wordct}, '%'))
                            break;
                        end
                        
                        % look for keywords that increase indent
                        if (sum(strcmp(words{wordct}, obj.KeywordsIncrease)))
                            layerNext = layerNext + 1;
                            % push keyword onto stack
                            stack = [stack, words{wordct}];
                            
                            % correction for function keywords according to
                            % configuration
                            if (strcmp(stack{end}, 'function'))
                                switch lower(strategy)
                                    case 'nestedfunctions'
                                        if (numel(stack) == 1)
                                            % top level function
                                            layerNext = layerNext - 1;
                                        else
                                            if (strcmp(stack{end-1}, 'function'))
                                                % nested function
                                                layer = layer + 1;
                                                layerNext = layerNext + 1;
                                            else
                                                % class method
                                                % do nothing
                                            end
                                        end
                                    case 'noindent'
                                        layerNext = layerNext - 1;
                                    otherwise
                                end
                            end
                            
                            % correction for switch
                            if (strcmp(stack{end}, 'switch'))
                                layerNext = layerNext + 1;
                            end
                        end
                        
                        % look for sandwich keywords
                        if (sum(strcmp(words{wordct}, obj.KeywordsSandwich)))
                            if (wordct == 1)
                                % at the beginning, decrease only current indent
                                layer = layer - 1;
                            end
                        end
                        
                        % look for end that decreases the indent
                        if (sum(strcmp(words{wordct}, obj.KeywordsDecrease)))
                            if (wordct == 1)
                                % end at the beginning decreases indent of this line
                                layer = layer - 1;
                            end
                            % inline end may alter the indent of the next line
                            layerNext = layerNext - 1;
                            
                            if isempty(stack)
                               continue 
                            end
                            
                            % correction for function keywords according to
                            % configuration
                            if (strcmp(stack{end}, 'function'))
                                switch lower(strategy)
                                    case 'nestedfunctions'
                                        if (numel(stack) == 1)
                                            % top level function
                                            layerNext = layerNext + 1;
                                        else
                                            if (strcmp(stack{end-1}, 'function'))
                                                % nested function
                                                layer = layer - 1;
                                            else
                                                % class method
                                                % do nothing
                                            end
                                        end
                                    case 'noindent'
                                        if (wordct == 1)
                                            % end at the beginning decreases indent of this line
                                            layer = layer + 1;
                                        end
                                        layerNext = layerNext + 1;
                                    otherwise
                                        % do nothing
                                end
                            end
                            
                            % correction for switch
                            if (strcmp(stack{end}, 'switch'))
                                if (wordct == 1)
                                    % end at the beginning decreases indent of this line
                                    layer = layer - 1;
                                end
                                layerNext = layerNext - 1;
                            end
                            
                            % pop keyword
                            stack(end) = [];
                        end
                    end
                    
                    % look for continuation lines
                    if (strcmp(words{end}, '...'))
                        if (~continuationMode)
                            continuationMode = 1;
                            layerNext = layerNext + 1;
                        end
                    else
                        if (continuationMode)
                            continuationMode = 0;
                            layerNext = layerNext - 1;
                        end
                    end
                end
                
                % add correct indentation
                for ict = 1:layer
                    if ~makeBlankLinesEmpty || ~isempty(lines{linect})
                        lines{linect} = [indent, lines{linect}];
                    end
                end
            end

            indentedSource = obj.joinString(lines, MBeautifier.Constants.NewLine);
        end
    end
    
    methods (Access = private, Static)
        % TODO: Create a public utility function
       function outStr = joinString(cellStr, delim)
            outStr = '';
            for i = 1:numel(cellStr)
                outStr = [outStr, cellStr{i}, delim];
            end
            
            outStr(end-numel(delim)+1:end) = '';
        end 
    end
end
