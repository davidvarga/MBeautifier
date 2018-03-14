classdef MFormatter < handle
    % Performs the actual code formatting. Should not be used directly but only by MBeautify.
    
    properties (Access = private)
        SettingConfiguration;
        AllOperators;
        
        % Properties used during the formatting
        StringTokenStructs;
        BlockCommentDepth;
        IsInBlockComment;
        
        MatrixIndexingOperatorPadding;
        CellArrayIndexingOperatorPadding;
    end
    
    properties(Access = private, Constant)
        WhiteSpaceToken = '#MBeauty_WhiteSpace_Token#';
        ContainerOpeningBrackets = {'[', '{', '('};
        ContainerClosingBrackets = {']', '}', ')'};
        TokenStruct = MFormatter.getTokenStruct();
    end
    
    methods
        
        function obj = MFormatter(settingConfiguration)
            % Creates a new formatter using the passed configuration.
            
            obj.SettingConfiguration = settingConfiguration;
            
            obj.MatrixIndexingOperatorPadding = str2double(obj.SettingConfiguration.SpecialRules.MatrixIndexing_ArithmeticOperatorPaddingValue);
            obj.CellArrayIndexingOperatorPadding = str2double(obj.SettingConfiguration.SpecialRules.CellArrayIndexing_ArithmeticOperatorPaddingValue);
            
            % Init run-time members
            obj.StringTokenStructs = {};
            obj.BlockCommentDepth = 0;
            obj.IsInBlockComment = false;
            
            % All of these because of performance reasons
            % Update the setting configuration with more members: mostly tokens and regular expressions that can be
            % calculated only once, and it costs a lot if they are calculated for every line.
            
            fieldList = fields(obj.SettingConfiguration.OperatorRules);
            obj.AllOperators = cell(numel(fieldList), 1);
            
            wsTokenLength = numel(obj.WhiteSpaceToken);
            
            for i = 1:numel(fieldList)
                
                obj.AllOperators{i} = obj.SettingConfiguration.OperatorRules.(fieldList{i}).ValueFrom;
                obj.SettingConfiguration.OperatorRules.(fieldList{i}).OperatorToken = ['#MBeauty_OP_', fieldList{i}, '#'];
                
                tokenizedReplaceString = strrep(obj.SettingConfiguration.OperatorRules.(fieldList{i}).ValueTo, ...
                    ' ', obj.WhiteSpaceToken);
                % Calculate the starting WS count
                leadingWSNum = 0;
                matchCell = regexp(tokenizedReplaceString, ['^(', obj.WhiteSpaceToken, ')+'], 'match');
                if numel(matchCell)
                    leadingWSNum = numel(matchCell{1}) / wsTokenLength;
                end
                
                % Calculate ending whitespace count
                endingWSNum = 0;
                matchCell = regexp(tokenizedReplaceString, ['(', obj.WhiteSpaceToken, ')+$'], 'match');
                if numel(matchCell)
                    endingWSNum = numel(matchCell{1}) / wsTokenLength;
                end
                
                obj.SettingConfiguration.OperatorRules.(fieldList{i}).ReplacementPattern = ...
                    ['\s*(', obj.WhiteSpaceToken, '){0,', num2str(leadingWSNum), '}', ...
                    obj.SettingConfiguration.OperatorRules.(fieldList{i}).OperatorToken, ...
                    '(', obj.WhiteSpaceToken, '){0,', num2str(endingWSNum), '}\s*'];
                
                
                if numel(regexp(obj.SettingConfiguration.OperatorRules.(fieldList{i}).ValueFrom, '\+|\-|\/|\*'))
                    if ~str2double(obj.SettingConfiguration.SpecialRules.MatrixIndexing_ArithmeticOperatorPaddingValue)
                        obj.SettingConfiguration.OperatorRules.(fieldList{i}).MatrixIndexingReplacementPattern = ...
                            ['\s*(', obj.WhiteSpaceToken, '){0,0}', ...
                            obj.SettingConfiguration.OperatorRules.(fieldList{i}).OperatorToken, ...
                            '(', obj.WhiteSpaceToken, '){0,0}\s*'];
                    else
                        obj.SettingConfiguration.OperatorRules.(fieldList{i}).MatrixIndexingReplacementPattern = ...
                            obj.SettingConfiguration.OperatorRules.(fieldList{i}).ReplacementPattern;
                    end
                    
                    if ~str2double(obj.SettingConfiguration.SpecialRules.CellArrayIndexing_ArithmeticOperatorPaddingValue)
                        obj.SettingConfiguration.OperatorRules.(fieldList{i}).CellArrayIndexingReplacementPattern = ...
                            ['\s*(', obj.WhiteSpaceToken, '){0,0}', ...
                            obj.SettingConfiguration.OperatorRules.(fieldList{i}).OperatorToken, ...
                            '(', obj.WhiteSpaceToken, '){0,0}\s*'];
                    else
                        obj.SettingConfiguration.OperatorRules.(fieldList{i}).CellArrayIndexingReplacementPattern = ...
                            obj.SettingConfiguration.OperatorRules.(fieldList{i}).ReplacementPattern;
                    end
                end
            end
        end
        
        function formattedSource = performFormatting(obj, source)
            % Performs formatting on the specified source.
            
            obj.StringTokenStructs = {};
            obj.BlockCommentDepth = 0;
            obj.IsInBlockComment = false;
            
            nMaximalNewLines = str2double(obj.SettingConfiguration.SpecialRules.MaximalNewLinesValue);
            nSectionPrecedingNewlines = str2double(obj.SettingConfiguration.SpecialRules.SectionPrecedingNewlineCountValue);
            formatSectionPrecedingNewlines = nSectionPrecedingNewlines >= 0;
            nSectionTrailingNewlines = str2double(obj.SettingConfiguration.SpecialRules.SectionTrailingNewlineCountValue);
            formatSectionTrailingNewlines = nSectionTrailingNewlines >= 0;
            newLine = sprintf('\n');
            
            contTokenStruct = MFormatter.TokenStruct.ContinueToken;
            
            textArray = regexp(source, newLine, 'split');
            
            replacedTextArray = {};
            isInContinousLine = 0;
            containerDepth = 0;
            contLineArray = cell(0, 2);
            isSectionSeparator = false;
            
            nNewLinesFound = 0;
            for j = 1:numel(textArray)
                line = textArray{j};
                
                %% Process the maximal new-line count
                if isempty(strtrim(line))
                    nNewLinesFound = nNewLinesFound + 1;
                    
                    if nNewLinesFound > nMaximalNewLines || ...
                            (formatSectionTrailingNewlines && isSectionSeparator && nNewLinesFound > nSectionTrailingNewlines)
                        continue;
                    end
                    
                    replacedTextArray = [replacedTextArray, sprintf('\n')];
                    continue;
                    
                else
                    if isSectionSeparator && formatSectionTrailingNewlines && (nNewLinesFound - nSectionTrailingNewlines < 0)
                        for i = 1:abs(nNewLinesFound - nSectionTrailingNewlines)
                            replacedTextArray = [replacedTextArray, sprintf('\n')];
                        end
                    end
                
                    nNewLinesFound = 0;
                end
                
                
                
                %% Determine the position where the line shall be splitted into code and comment
                [actCode, actComment, splittingPos, isSectionSeparator] = obj.findComment(line);
                
                if isSectionSeparator && formatSectionPrecedingNewlines
                    replacedTextArray = MFormatter.handleTrailingEmptyLines(replacedTextArray, nSectionPrecedingNewlines);      
                end
                
                
                %% Check for line continousment (...)
                % Continous lines have to be converted into one single code line to perform replacement on it
                % The continousment characters have to be replaced by tokens and the comments of the lines must be stored
                % After replacement, the continuosment has to be re-created along with the comments.
                
                trimmedCode = strtrim(actCode);
                if ~numel(trimmedCode)
                    actCodeFinal = '';
                else
                    containerDepth = containerDepth + obj.calculateContainerDepthDeltaOfLine(trimmedCode);
                    
                    % Auto append "..." to the lines of continuous containers 
                    if containerDepth && ~(numel(trimmedCode) >= 3 && strcmp(trimmedCode(end - 2:end), '...'))
                        if strcmp(trimmedCode(end), ',') || strcmp(trimmedCode(end), ';')
                            actCode = [trimmedCode, ' ...'];
                        else
                            actCode = [actCode, '; ...'];
                        end
                        
                    end
                    
                    trimmedCode = strtrim(actCode);
                    
                    % Line ends with "..."
                    if (numel(trimmedCode) >= 3 && strcmp(trimmedCode(end - 2:end), '...')) ...
                            || (isequal(splittingPos, 1) && isInContinousLine)
                        isInContinousLine = true;
                        contLineArray{end + 1, 1} = actCode;
                        contLineArray{end, 2} = actComment;
                        % Step to next line
                        continue;
                    else
                        % End of cont line
                        if isInContinousLine
                            isInContinousLine = false;
                            contLineArray{end + 1, 1} = actCode;
                            contLineArray{end, 2} = actComment;
                            
                            % Build the line for replacement
                            replacedLines = '';
                            for iLine = 1:size(contLineArray, 1) -1
                                tempRow = strtrim(contLineArray{iLine, 1});
                                tempRow = [tempRow(1:end - 3), [' ', contTokenStruct.Token, ' ']];
                                tempRow = regexprep(tempRow, ['\s+', contTokenStruct.Token, '\s+'], [' ', contTokenStruct.Token, ' ']);
                                replacedLines = [replacedLines, tempRow];
                            end
                            replacedLines = [replacedLines, actCode];
                            
                            % Replace
                            actCodeFinal = obj.performReplacements(replacedLines);
                            
                            % Re-create the original structure
                            splitToLine = regexp(actCodeFinal, contTokenStruct.Token, 'split');
                            
                            line = '';
                            for iSplitLine = 1:numel(splitToLine) -1
                                line = [line, strtrim(splitToLine{iSplitLine}), [' ', contTokenStruct.StoredValue, ' '], contLineArray{iSplitLine, 2}, newLine];
                            end
                            
                            line = [line, strtrim(splitToLine{end}), actComment]; %#ok<*AGROW>
                            replacedTextArray = [replacedTextArray, {line, sprintf('\n')}];
                            contLineArray = cell(0, 2);
                            
                            continue;
                        end
                        
                    end
                    
                    actCodeFinal = obj.performReplacements(actCode);
                end
                
                if ~obj.IsInBlockComment
                    line = [strtrim(actCodeFinal), ' ', actComment];
                else
                    line = [strtrim(actCodeFinal), actComment];
                end
                replacedTextArray = [replacedTextArray, [line, sprintf('\n')]];
            end
            % The last new-line must be removed: inner new-lines are removed by the split, the last one is an additional one
            if numel(replacedTextArray) && numel(strtrim(replacedTextArray{end}))
                replacedTextArray{end} = strtrim(replacedTextArray{end});
            end
            
            nEndingNewlines = str2double(obj.SettingConfiguration.SpecialRules.EndingNewlineCountValue);
            formatEndingNewlines = nEndingNewlines >= 0;
            if formatEndingNewlines
                
                replacedTextArray = MFormatter.handleTrailingEmptyLines(replacedTextArray, nEndingNewlines);
                
                replacedTextArray{end} = strtrim(replacedTextArray{end});
            end
            
            formattedSource = [replacedTextArray{:}];
        end
    end
       
    methods (Access = private, Static)
        
        function textArray = handleTrailingEmptyLines(textArray, neededEmptyLineCount)
            precedingNewLines = MFormatter.getPrecedingNewlineCount(textArray);
            
            newLineDelta = neededEmptyLineCount - precedingNewLines;
            
            if newLineDelta < 0
                for i = 1:abs(newLineDelta)
                    textArray(end) = [];
                end
            elseif newLineDelta > 0
                for i = 1:newLineDelta
                    textArray = [textArray, sprintf('\n')];
                end
                
            end
            
        end
        
        function count = getPrecedingNewlineCount(textArray)
            count = 0;
            for i = numel(textArray):-1:1
                if isempty(strtrim(textArray{i}))
                    count = count + 1;
                else
                    return;
                end
            end
        end
        
        function outStr = joinString(cellStr, delim)
            
            outStr = '';
            for i = 1:numel(cellStr)
                outStr = [outStr, cellStr{i}, delim];
            end
            
            outStr(end-numel(delim)+1:end) = '';
            
        end
        
        function tokenStructs = getTokenStruct()
            % Returns the tokens used in replacement.
            
            % Persistent variable to serve as cache
            persistent tokenStructStored;
            if isempty(tokenStructStored)
                
                tokenStructs = struct();
                tokenStructs.ContinueToken = newStruct('...', '#MBeutyCont#');
                tokenStructs.StringToken = newStruct('', '#MBeutyString#');
                tokenStructs.ArrayElementToken = newStruct('', '#MBeutyArrayElement#');
                tokenStructs.TransposeToken = newStruct('''', '#MBeutyTransp#');
                tokenStructs.NonConjTransposeToken = newStruct('.''', '#MBeutyNonConjTransp#');
                tokenStructs.NormNotationPlus = newStruct('+', '#MBeauty_OP_NormNotationPlus');
                tokenStructs.NormNotationMinus = newStruct('-', '#MBeauty_OP_NormNotationMinus');
                tokenStructs.UnaryPlus = newStruct('+', '#MBeauty_OP_UnaryPlus');
                tokenStructs.UnaryMinus = newStruct('-', '#MBeauty_OP_UnaryMinus');
                
                tokenStructStored = tokenStructs;
            else
                tokenStructs = tokenStructStored;
            end
            
            function retStruct = newStruct(storedValue, replacementString)
                retStruct = struct('StoredValue', storedValue, 'Token', replacementString);
            end
        end
        
        function code = restoreTransponations(code)
            % Restores transponation tokens to original transponation signs.
            
            trnspTokStruct = MFormatter.TokenStruct.TransposeToken;
            nonConjTrnspTokStruct = MFormatter.TokenStruct.NonConjTransposeToken;
            
            code = regexprep(code, trnspTokStruct.Token, trnspTokStruct.StoredValue);
            code = regexprep(code, nonConjTrnspTokStruct.Token, nonConjTrnspTokStruct.StoredValue);
        end
        
        function actCode = replaceTransponations(actCode)
            % Replaces transponation signs in the code with tokens.
            
            trnspTokStruct = MFormatter.TokenStruct.TransposeToken;
            nonConjTrnspTokStruct = MFormatter.TokenStruct.NonConjTransposeToken;
            
            charsIndicateTranspose = '[a-zA-Z0-9\)\]\}\.]';
            
            tempCode = '';
            isLastCharDot = false;
            isLastCharTransp = false;
            isInStr = false;
            for iStr = 1:numel(actCode)
                actChar = actCode(iStr);
                
                if isequal(actChar, '''')
                    % .' => NonConj transpose
                    if isLastCharDot
                        tempCode = [tempCode(1:end - 1), nonConjTrnspTokStruct.Token];
                        isLastCharTransp = true;
                    else
                        if isLastCharTransp
                            tempCode = [tempCode, trnspTokStruct.Token];
                        else
                            if numel(tempCode) && ~isInStr && numel(regexp(tempCode(end), charsIndicateTranspose))
                                tempCode = [tempCode, trnspTokStruct.Token];
                                isLastCharTransp = true;
                            else
                                tempCode = [tempCode, actChar];
                                isInStr = ~isInStr;
                                isLastCharTransp = false;
                            end
                        end
                    end
                    
                    isLastCharDot = false;
                elseif isequal(actChar, '.') && ~isInStr
                    isLastCharDot = true;
                    tempCode = [tempCode, actChar];
                    isLastCharTransp = false;
                else
                    isLastCharDot = false;
                    tempCode = [tempCode, actChar];
                    isLastCharTransp = false;
                end
            end
            actCode = tempCode;
        end
    end
    
    
    methods (Access = private)
        function actCodeTemp = replaceStrings(obj, actCode)
            % Replaces strings in the code with string tokens while filling StringTokenStructs member to store the
            % original values.
            
            %% Strings
            splittedCode = regexp(actCode, '''', 'split');
            
            obj.StringTokenStructs = cell(1, ceil(numel(splittedCode) / 2));
            strArray = cell(1, numel(splittedCode));
            
            for iSplit = 1:numel(splittedCode)
                % Not string
                if ~isequal(mod(iSplit, 2), 0)
                    strArray{iSplit} = splittedCode{iSplit};
                else % String
                    strTokenStruct = MFormatter.TokenStruct.StringToken;
                    
                    strArray{iSplit} = strTokenStruct.Token;
                    strTokenStruct.StoredValue = splittedCode{iSplit};
                    obj.StringTokenStructs{iSplit} = strTokenStruct;
                end
            end
            
            obj.StringTokenStructs = obj.StringTokenStructs(cellfun(@(x) ~isempty(x), obj.StringTokenStructs));
            actCodeTemp = [strArray{:}];
        end
        
        function actCodeFinal = restoreStrings(obj, actCodeTemp)
            % Replaces string tokens with the original string from the StringTokenStructs member.
            
            strTokStructs = obj.StringTokenStructs;
            splitByStrTok = regexp(actCodeTemp, MFormatter.TokenStruct.StringToken.Token, 'split');
            
            if numel(strTokStructs)
                actCodeFinal = '';
                for iSplit = 1:numel(strTokStructs)
                    actCodeFinal = [actCodeFinal, splitByStrTok{iSplit}, '''', strTokStructs{iSplit}.StoredValue, ''''];
                end
                
                if numel(splitByStrTok) > numel(strTokStructs)
                    actCodeFinal = [actCodeFinal, splitByStrTok{end}];
                end
            else
                actCodeFinal = actCodeTemp;
            end
        end
        
        function code = performReplacements(obj, code) 
            % Wrapper around code replacement: Replace transponations -> replace strings -> perform other replacements
            % (operators, containers, ...) -> restore strings -> restore transponations.
            
            code = obj.replaceStrings(obj.replaceTransponations(code));
            code = obj.performFormattingSingleLine(code, false, '', false);
            code = obj.restoreTransponations(obj.restoreStrings(code));
        end
        
        function [actCode, actComment, splittingPos, isSectionSeparator] = findComment(obj, line)
            % Splits a continous line into code and comment parts.
            
            %% Set the variables
            retComm = -1;
            exclamationPos = -1;
            actCode = line;
            actComment = '';
            splittingPos = -1;
            isSectionSeparator = false;
            
            trimmedLine = strtrim(line);
            
            %% Handle some special cases
            if isempty(trimmedLine)
                return;
            elseif strcmp(trimmedLine, '%{')
                retComm = 1;
                obj.IsInBlockComment = true;
                obj.BlockCommentDepth = obj.BlockCommentDepth + 1;
            elseif strcmp(trimmedLine, '%}') && obj.IsInBlockComment
                retComm = 1;
                
                obj.BlockCommentDepth = obj.BlockCommentDepth - 1;
                obj.IsInBlockComment = obj.BlockCommentDepth > 0;
            else
                if obj.IsInBlockComment
                    retComm = 1;
                    obj.IsInBlockComment = true;
                end
            end
            
            if isequal(trimmedLine(1), '%') || (numel(trimmedLine) > 7 && isequal(trimmedLine(1:7), 'import '))
                retComm = 1;
            elseif isequal(trimmedLine(1), '!')
                exclamationPos = 1;
            end
            
            splittingPos = max(retComm, exclamationPos);
            
            if isequal(splittingPos, 1)
                actCode = '';
                actComment = line;
                
                if ~obj.IsInBlockComment && ...
                    numel(regexp(trimmedLine, '^%%(\s+|$)'))
                    isSectionSeparator = true;
                end
                return
            end
            
            %% Searh for comment signs(%) and exclamation marks(!)
            
            exclamationInd = strfind(line, '!');
            commentSignIndexes = strfind(line, '%');
            contIndexes = strfind(line, '...');
            
            if ~iscell(exclamationInd)
                exclamationInd = num2cell(exclamationInd);
            end
            if ~iscell(commentSignIndexes)
                commentSignIndexes = num2cell(commentSignIndexes);
            end
            if ~iscell(contIndexes)
                contIndexes = num2cell(contIndexes);
            end
            
            % Make the union of indexes of '%' and '!' symbols then sort them
            indexUnion = [commentSignIndexes, exclamationInd, contIndexes];
            indexUnion = sortrows(indexUnion(:))';
            
            % Iterate through the union
            commentSignCount = numel(indexUnion);
            if ~commentSignCount
                retComm = -1;
                exclamationPos = -1;
            else
                
                for iCommSign = 1:commentSignCount
                    currentIndex = indexUnion{iCommSign};
                    
                    % Check all leading parts that can be "code"
                    % Replace transponation (and noin-conjugate transponations) to avoid not relevant matches
                    possibleCode = obj.replaceTransponations(line(1:currentIndex - 1));
                    
                    % The line is currently "not in string"
                    if isequal(mod(numel(strfind(possibleCode, '''')), 2), 0)
                        if ismember(currentIndex, [commentSignIndexes{:}])
                            retComm = currentIndex;
                        elseif ismember(currentIndex, [exclamationInd{:}])
                            exclamationPos = currentIndex;
                        else
                            % Branch of '...'
                            retComm = currentIndex + 3;
                        end
                        
                        break;
                    end
                end
            end
            
            splittingPos = max(retComm, exclamationPos);
            
            if isequal(splittingPos, 1)
                actCode = '';
                actComment = line;
            elseif splittingPos == -1
                actCode = line;
                actComment = '';
            else
                actCode = line(1:max(splittingPos - 1, 1));
                actComment = strtrim(line(splittingPos:end));
            end  
        end
        
        function data = performFormattingSingleLine(obj, data, doIndexing, contType, isContainerElement)
            % Performs formatting on a code snippet, where the strings and transponations are already replaced:
            % operator, container formatting
            
            if isempty(data)
                return;
            end
            
            if nargin < 3
                doIndexing = false;
            end
            
            if nargin < 4
                contType = '';
            end
            
            setConfigOperatorFields = fields(obj.SettingConfiguration.OperatorRules);
            % At this point, the data contains one line of code, but all user-defined strings enclosed in '' are replaced by #MBeutyString#
            
            % Old-style function calls, such as 'subplot 211' or 'disp Hello World' -> return unchanged
            if numel(regexp(data, '^[a-zA-Z0-9_]+\s+[^(=]'))
                
                splitData = regexp(strtrim(data), ' ', 'split');
                % The first elemen is not a keyword and does not exist (function on the path)
                if numel(splitData) && ~any(strcmp(splitData{1}, iskeyword())) && exist(splitData{1}) %#ok<EXIST>
                    return
                end
            end
            
            % Process matrixes and cell arrays
            % All containers are processed element wised. The replaced containers are placed into a map where the key is a token
            % inserted to the original data
            [data, arrayMapCell] = obj.replaceContainer(data);
            
            % Convert all operators like + * == etc to #MBeauty_OP_whatever# tokens
            opBuffer = {};
            operatorList = obj.AllOperators;
            operatorAppearance = regexp(data, operatorList);
            
            if ~isempty([operatorAppearance{:}])
                for iOpConf = 1:numel(setConfigOperatorFields)
                    currField = setConfigOperatorFields{iOpConf};
                    currOpStruct = obj.SettingConfiguration.OperatorRules.(currField);
                    dataNew = regexprep(data, ['\s*', currOpStruct.ValueFrom, '\s*'], currOpStruct.OperatorToken);
                    if ~strcmp(data, dataNew)
                        opBuffer{end + 1} = currField;
                    end
                    data = dataNew;
                end
            end
            
            % Remove all duplicate space
            data = regexprep(data, '\s+', ' ');
            keywords = iskeyword();
            
            % Handle special + and - cases:
            % 	- unary plus/minus, such as in (+1): replace #MBeauty_OP_Plus/Minus# by #MBeauty_OP_UnaryPlus/Minus#
            %   - normalized number format, such as 7e-3: replace #MBeauty_OP_Plus/Minus# by #MBeauty_OP_NormNotation_Plus/Minus#
            % Then convert UnaryPlus tokens to '+' signs same for minus)
            plusMinusCell = {'Plus', 'Minus'};
            unaryPlusOperatorPresent = false;
            unaryMinusOperatorPresent = false;
            normPlusOperatorPresent = false;
            normMinusOperatorPresent = false;
            
            for iOpConf = 1:numel(plusMinusCell)
                
                if any(strcmp(plusMinusCell{iOpConf}, opBuffer))
                    
                    currField = plusMinusCell{iOpConf};
                    isPlus = isequal(currField, 'Plus');
                    
                    opToken = obj.SettingConfiguration.OperatorRules.(currField).OperatorToken;
                    
                    splittedData = regexp(data, opToken, 'split');
                    
                    replaceTokens = {};
                    for iSplit = 1:numel(splittedData) -1
                        beforeItem = strtrim(splittedData{iSplit});
                        if ~isempty(beforeItem) && numel(regexp(beforeItem, ...
                                ['([0-9a-zA-Z_)}\]\.]|', MFormatter.TokenStruct.TransposeToken.Token, '|#MBeauty_ArrayToken_\d+#)$'])) && ...
                                (~numel(regexp(beforeItem, ['(?=^|\s)(', MFormatter.joinString(keywords', '|'), ')$'])) || doIndexing)
                            % + or - is a binary operator after:
                            %    - numbers [0-9.],
                            %    - variable names [a-zA-Z0-9_] or
                            %    - closing brackets )}]
                            %    - transpose signs ', here represented as #MBeutyTransp#
                            %    - keywords
                            
                            % Special treatment for E: 7E-3 or 7e+4 normalized notation
                            % In this case the + and - signs are not operators so shoud be skipped
                            if numel(beforeItem) > 1 && strcmpi(beforeItem(end), 'e') && numel(regexp(beforeItem(end - 1), '[0-9.]'))
                                if isPlus
                                    replaceTokens{end + 1} = MFormatter.TokenStruct.NormNotationPlus.Token;
                                    normPlusOperatorPresent = true;
                                else
                                    replaceTokens{end + 1} = MFormatter.TokenStruct.NormNotationMinus.Token;
                                    normMinusOperatorPresent = true;
                                end  
                            else
                                replaceTokens{end + 1} = opToken;
                            end
                        else
                            if isPlus
                                replaceTokens{end + 1} = MFormatter.TokenStruct.UnaryPlus.Token;
                                unaryPlusOperatorPresent = true;
                            else
                                replaceTokens{end + 1} = MFormatter.TokenStruct.UnaryMinus.Token;
                                unaryMinusOperatorPresent = true;
                            end
                        end
                    end
                    
                    replacedSplittedData = cell(1, numel(replaceTokens) + numel(splittedData));
                    tokenIndex = 1;
                    for iSplit = 1:numel(splittedData)
                        replacedSplittedData{iSplit * 2 - 1} = splittedData{iSplit};
                        if iSplit < numel(splittedData)
                            replacedSplittedData{iSplit * 2} = replaceTokens{tokenIndex};
                        end
                        tokenIndex = tokenIndex + 1;
                    end
                    data = [replacedSplittedData{:}];
                end
            end
            
            %%
            % At this point the data is in a completely tokenized representation, e.g.'x#MBeauty_OP_Plus#y' instead of the 'x + y'.
            % Now go backwards and replace the tokens by the real operators
            
            % Special tokens: Unary Plus/Minus, Normalized Number Format
            % Performance tweak: only if there were any unary or norm operators
            if unaryPlusOperatorPresent
                data = regexprep(data, ['\s*', MFormatter.TokenStruct.UnaryPlus.Token, '\s*'], [' ', MFormatter.TokenStruct.UnaryPlus.StoredValue]);
            end
            if unaryMinusOperatorPresent
                data = regexprep(data, ['\s*', MFormatter.TokenStruct.UnaryMinus.Token, '\s*'], [' ', MFormatter.TokenStruct.UnaryMinus.StoredValue]);
            end
            if normPlusOperatorPresent
                data = regexprep(data, ['\s*', MFormatter.TokenStruct.NormNotationPlus.Token, '\s*'], MFormatter.TokenStruct.NormNotationPlus.StoredValue);
            end
            if normMinusOperatorPresent
                data = regexprep(data, ['\s*', MFormatter.TokenStruct.NormNotationMinus.Token, '\s*'], MFormatter.TokenStruct.NormNotationMinus.StoredValue);
            end
            
            
            
            % Replace all other operators
            for iOpConf = 1:numel(setConfigOperatorFields)
                
                currField = setConfigOperatorFields{iOpConf};
                
                if any(strcmp(currField, opBuffer))
                    
                    currOpStruct = obj.SettingConfiguration.OperatorRules.(currField);
                    
                    valTo = currOpStruct.ValueTo;
                    if doIndexing && ~isempty(contType) && numel(regexp(currOpStruct.ValueFrom, '\+|\-|\/|\*'))
                        if strcmp(contType, 'matrix')
                            replacementPattern = currOpStruct.MatrixIndexingReplacementPattern;
                            if ~obj.MatrixIndexingOperatorPadding
                                valTo = strrep(valTo, ' ', '');
                            end
                            
                        elseif strcmp(contType, 'cell')
                            replacementPattern = currOpStruct.CellArrayIndexingReplacementPattern;
                            if ~obj.CellArrayIndexingOperatorPadding
                                valTo = strrep(valTo, ' ', '');
                            end
                        end
                    else
                        
                        replacementPattern = currOpStruct.ReplacementPattern;
                    end
                    
                    tokenizedReplaceString = strrep(valTo, ' ', obj.WhiteSpaceToken);
                    
                    % Replace only the amount of whitespace tokens that are actually needed by the operator rule
                    data = regexprep(data, replacementPattern, tokenizedReplaceString);
                end
            end
            
            if ~isContainerElement && ~str2double(obj.SettingConfiguration.SpecialRules.AllowMultipleStatementsPerLineValue)
                data = regexprep(data, ';(?!\s*$)', ';\n');
            end
            
            data = regexprep(data, obj.WhiteSpaceToken, ' ');
            
            data = regexprep(data, ' \)', ')');
            data = regexprep(data, ' \]', ']');
            data = regexprep(data, '\( ', '(');
            data = regexprep(data, '\[ ', '[');
            
            % TODO: keyword formatting here could be done
            data = regexprep(data, '^function(?=#MBeauty_ArrayToken_\d+#)', 'function ');
            
            % Restore containers
            data = obj.restoreContainers(data, arrayMapCell);
            
            % Fix semicolon whitespace at end of line
            data = regexprep(data, '\s+;\s*$', ';');
        end
        
        function ret = calculateContainerDepthDeltaOfLine(obj, code)
            % Calculates the delta of container depth in a single code line.
            
            % Pre-check for opening and closing brackets: the final delta has to be calculated after the transponations and the
            % strings are replaced, which are time consuming actions
            ret = 0;
            if numel(regexp(code, '{|[')) || numel(regexp(code, '}|]'))
                actCodeTemp = obj.replaceStrings(obj.replaceTransponations(code));
                ret = numel(regexp(actCodeTemp, '{|[')) - numel(regexp(actCodeTemp, '}|]'));
            end
        end
        
        function [containerBorderIndexes, maxDepth] = calculateContainerDepths(obj, data)
            % Calculates the container boundaries with container depth for a continous code line.
            
            containerBorderIndexes = {};
            depth = 1;
            maxDepth = 1;
            for i = 1:numel(data)
                borderFound = true;
                if any(strcmp(data(i), obj.ContainerOpeningBrackets))
                    newDepth = depth + 1;
                    maxDepth = newDepth;
                elseif any(strcmp(data(i), obj.ContainerClosingBrackets))
                    newDepth = depth - 1;
                    depth = depth - 1;
                else
                    borderFound = false;
                end
                
                if borderFound
                    containerBorderIndexes{end + 1, 1} = i;
                    containerBorderIndexes{end, 2} = depth;
                    depth = newDepth;
                end
            end
        end
        
        function [data, arrayMap] = replaceContainer(obj, data)
            % Replaces containers in a code line with container tokens while storing the original container contents in
            % the second output argument.
            
            arrayMap = containers.Map();
            if isempty(data)
                return
            end
            
            data = regexprep(data, '\s+;', ';');
            
            operatorArray = {'+', '-', '&', '&&', '|', '||', '/', './', '\', '.\', '*', '.*', ':', '^', '.^', '~'};
            contTokenStruct = MFormatter.TokenStruct.ContinueToken;
            
            [containerBorderIndexes, maxDepth] = obj.calculateContainerDepths(data);
            
            id = 0;
            
            while maxDepth > 0
                
                if isempty(containerBorderIndexes)
                    break;
                end
                
                indexes = find([containerBorderIndexes{:, 2}] == maxDepth, 2);
                
                if ~numel(indexes) || mod(numel(indexes), 2) ~= 0
                    maxDepth = maxDepth - 1;
                    continue;
                end
                
                openingBracket = data(containerBorderIndexes{indexes(1), 1});
                closingBracket = data(containerBorderIndexes{indexes(2), 1});
                
                isContainerIndexing = numel(regexp(data(1:containerBorderIndexes{indexes(1), 1}), ['[a-zA-Z0-9_]\s*[', openingBracket, ']$']));
                preceedingKeyWord = false;
                if isContainerIndexing
                    keywords = iskeyword();
                    prevStr = strtrim(data(1:containerBorderIndexes{indexes(1), 1} - 1));
                    
                    if numel(prevStr) >= 2
                        
                        for i = 1:numel(keywords)
                            if numel(regexp(prevStr, ['(\s|^)', keywords{i}, '$']))
                                isContainerIndexing = false;
                                preceedingKeyWord = true;
                                break;
                            end
                        end
                    end
                end
                
                doIndexing = isContainerIndexing;
                contType = '';
                if doIndexing
                    if strcmp(openingBracket, '(')
                        doIndexing = true;
                        contType = 'matrix';
                    elseif strcmp(openingBracket, '{')
                        doIndexing = true;
                        contType = 'cell';
                    else
                        doIndexing = false;
                    end
                end
                
                str = data(containerBorderIndexes{indexes(1), 1}:containerBorderIndexes{indexes(2), 1});
                str = regexprep(str, '\s+', ' ');
                str = regexprep(str, [openingBracket, '\s+'], openingBracket);
                str = regexprep(str, ['\s+', closingBracket], closingBracket);
                
                if ~strcmp(openingBracket, '(')
                    if doIndexing
                        strNew = strtrim(str);
                        strNew = [strNew(1), strtrim(obj.performFormattingSingleLine(strNew(2:end - 1), doIndexing, contType, true)), strNew(end)];
                    else
                        elementsCell = regexp(str, ' ', 'split');
                        
                        firstElem = strtrim(elementsCell{1});
                        lastElem = strtrim(elementsCell{end});
                        
                        if numel(elementsCell) == 1
                            elementsCell{1} = firstElem(2:end - 1);
                        else
                            elementsCell{1} = firstElem(2:end);
                            elementsCell{end} = lastElem(1:end - 1);
                        end
                        
                        for iElem = 1:numel(elementsCell)
                            elem = strtrim(elementsCell{iElem});
                            if numel(elem) && strcmp(elem(1), ',')
                                elem = elem(2:end);
                            end
                            elementsCell{iElem} = elem;
                        end
                        
                        isInCurlyBracket = 0;
                        for elemInd = 1:numel(elementsCell) -1
                            
                            currElem = strtrim(elementsCell{elemInd});
                            nextElem = strtrim(elementsCell{elemInd + 1});
                            
                            if ~numel(currElem)
                                continue;
                            end
                            
                            isInCurlyBracket = isInCurlyBracket || numel(strfind(currElem, openingBracket));
                            isInCurlyBracket = isInCurlyBracket && ~numel(strfind(currElem, closingBracket));
                            
                            currElemStripped = regexprep(currElem, ['[', openingBracket, closingBracket, ']'], '');
                            nextElemStripped = regexprep(nextElem, ['[', openingBracket, closingBracket, ']'], '');
                            
                            currElem = strtrim(obj.performFormattingSingleLine(currElem, doIndexing, contType, true));
                            
                            if strcmp(openingBracket, '[')
                                addCommas = str2double(obj.SettingConfiguration.SpecialRules.AddCommasToMatricesValue);
                            else
                                addCommas = str2double(obj.SettingConfiguration.SpecialRules.AddCommasToCellArraysValue);
                            end
                            
                            if numel(currElem) && addCommas && ...
                                    ~(strcmp(currElem(end), ',') || strcmp(currElem(end), ';')) && ~isInCurlyBracket && ...
                                    ~strcmp(currElem, contTokenStruct.Token) && ...
                                    ~any(strcmp(currElemStripped, operatorArray)) && ~any(strcmp(nextElemStripped, operatorArray)) && ...
                                    ~numel(regexp(currElemStripped, '^@#MBeauty_ArrayToken_\d+#$'))
                                
                                elementsCell{elemInd} = [currElem, '#MBeauty_OP_Comma#'];
                            else
                                elementsCell{elemInd} = [currElem, ' '];
                            end
                        end
                        
                        elementsCell{end} = strtrim(obj.performFormattingSingleLine(elementsCell{end}, doIndexing, contType, true));
                        
                        strNew = [openingBracket, elementsCell{:}, closingBracket];
                    end
                else
                    strNew = strtrim(str);
                    strNew = [strNew(1), strtrim(obj.performFormattingSingleLine(strNew(2:end - 1), doIndexing, contType, true)), strNew(end)];
                end
                
                datacell = cell(1, 3);
                if containerBorderIndexes{indexes(1), 1} == 1
                    datacell{1} = '';
                else
                    
                    datacell{1} = data(1:containerBorderIndexes{indexes(1), 1} - 1);
                    if isContainerIndexing
                        datacell{1} = strtrim(datacell{1});
                    elseif preceedingKeyWord
                        datacell{1} = strtrim(datacell{1});
                        datacell{1} = [datacell{1}, ' '];
                    end
                end
                
                if containerBorderIndexes{indexes(2), 1} == numel(data)
                    datacell{end} = '';
                else
                    datacell{end} = data(containerBorderIndexes{indexes(2), 1} + 1:end);
                end
                
                idAsStr = num2str(id);
                idStr = [repmat('0', 1, 5 - numel(idAsStr)), idAsStr];
                tokenOfCUrElem = ['#MBeauty_ArrayToken_', idStr, '#'];
                arrayMap(tokenOfCUrElem) = strNew;
                id = id + 1;
                datacell{2} = tokenOfCUrElem;
                data = [datacell{:}];
                
                containerBorderIndexes = obj.calculateContainerDepths(data);
            end
        end
        
        function data = restoreContainers(obj, data, map)
            % Replaces container tokens with the original container contents.
            
            arrayTokenList = map.keys();
            if isempty(arrayTokenList)
                return;
            end
            
            for iKey = numel(arrayTokenList):-1:1
                data = regexprep(data, arrayTokenList{iKey}, regexptranslate('escape', map(arrayTokenList{iKey})));
            end
            
            data = regexprep(data, obj.SettingConfiguration.OperatorRules.Comma.OperatorToken, ...
                obj.SettingConfiguration.OperatorRules.Comma.ValueTo);
        end
        
    end
end
