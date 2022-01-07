classdef MFormatter < handle
    % Performs the actual code formatting. Should not be used directly but only by MBeautify.

    properties (Access = private)
        Configuration;
        AllOperators;

        DirectiveDirector;
        StringMemory;

        % Properties used during the formatting
        BlockCommentDepth;
        IsInBlockComment;

        MatrixIndexingOperatorPadding;
        CellArrayIndexingOperatorPadding;
    end

    properties (Access = private, Constant)
        TokenStruct = MBeautifier.MFormatter.getTokenStruct();
    end

    methods
        function obj = MFormatter(configuration)
            % Creates a new formatter using the passed configuration.

            obj.Configuration = configuration;

            obj.MatrixIndexingOperatorPadding = configuration.specialRule('MatrixIndexing_ArithmeticOperatorPadding').ValueAsDouble;
            obj.CellArrayIndexingOperatorPadding = configuration.specialRule('CellArrayIndexing_ArithmeticOperatorPadding').ValueAsDouble;

            % Init run-time members
            obj.StringMemory = [];
            obj.BlockCommentDepth = 0;
            obj.IsInBlockComment = false;
            obj.AllOperators = configuration.operatorCharacters();
        end

        function formattedSource = performFormatting(obj, source)
            % Performs formatting on the specified source.

            obj.BlockCommentDepth = 0;
            obj.IsInBlockComment = false;
            obj.DirectiveDirector = MBeautifier.DirectiveDirector();

            nMaximalNewLines = obj.Configuration.specialRule('MaximalNewLines').ValueAsDouble;
            nSectionPrecedingNewlines = obj.Configuration.specialRule('SectionPrecedingNewlineCount').ValueAsDouble;
            formatSectionPrecedingNewlines = nSectionPrecedingNewlines >= 0;
            nSectionTrailingNewlines = obj.Configuration.specialRule('SectionTrailingNewlineCount').ValueAsDouble;
            formatSectionTrailingNewlines = nSectionTrailingNewlines >= 0;
            newLine = MBeautifier.Constants.NewLine;

            contTokenStruct = MBeautifier.MFormatter.TokenStruct.ContinueToken;
            textArray = regexp(source, newLine, 'split');

            replacedTextArray = {};
            isInContinousLine = 0;
            containerDepth = 0;
            contLineArray = cell(0, 2);
            isSectionSeparator = false;

            isFormattingOff = false;

            nNewLinesFound = 0;
            for j = 1:numel(textArray)
                line = textArray{j};

                %% Check for directives if ...
                % ... NOT in continous line
                % ... NOT in block comment
                if ~isInContinousLine && ~obj.IsInBlockComment
                    directiveChange = obj.DirectiveDirector.updateFromLine(line);
                    if ~isequal(directiveChange.Type, MBeautifier.DirectiveChangeType.NONE)
                        switch (lower(directiveChange.DirectiveName))
                            case 'format'
                                if isequal(directiveChange.Type, MBeautifier.DirectiveChangeType.REMOVED)
                                    isFormattingOff = false;
                                elseif isequal(directiveChange.Type, MBeautifier.DirectiveChangeType.ADDED) || isequal(directiveChange.Type, MBeautifier.DirectiveChangeType.CHANGED)
                                    isFormattingOff = numel(directiveChange.Directive.Values) > 0 && strcmpi(directiveChange.Directive.Values{1}, 'off');
                                end
                            otherwise
                                % Ignore
                        end
                    end
                end

                if isFormattingOff
                    replacedTextArray = [replacedTextArray, line, MBeautifier.Constants.NewLine];
                    continue
                end

                %% Process the maximal new-line count
                if isempty(strtrim(line))
                    nNewLinesFound = nNewLinesFound + 1;

                    if nNewLinesFound > nMaximalNewLines || ...
                            (formatSectionTrailingNewlines && isSectionSeparator && nNewLinesFound > nSectionTrailingNewlines)
                        continue;
                    end

                    replacedTextArray = [replacedTextArray, MBeautifier.Constants.NewLine];
                    continue;

                else
                    if isSectionSeparator && formatSectionTrailingNewlines && (nNewLinesFound - nSectionTrailingNewlines < 0)
                        for i = 1:abs(nNewLinesFound-nSectionTrailingNewlines)
                            replacedTextArray = [replacedTextArray, MBeautifier.Constants.NewLine];
                        end
                    end

                    nNewLinesFound = 0;
                end

                %% Determine the position where the line shall be splitted into code and comment
                [actCode, actComment, splittingPos, isSectionSeparator] = obj.findComment(line);

                if isSectionSeparator && formatSectionPrecedingNewlines
                    replacedTextArray = MBeautifier.MFormatter.handleTrailingEmptyLines(replacedTextArray, nSectionPrecedingNewlines);
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
                    if containerDepth && ~(numel(trimmedCode) >= 3 && strcmp(trimmedCode(end-2:end), '...'))
                        if strcmp(trimmedCode(end), ',') || strcmp(trimmedCode(end), ';')
                            actCode = [trimmedCode, ' ...'];
                        else
                            actCode = [actCode, '; ...'];
                        end
                    end

                    trimmedCode = strtrim(actCode);

                    % Line ends with "..."
                    if (numel(trimmedCode) >= 3 && strcmp(trimmedCode(end-2:end), '...')) ...
                            || (isequal(splittingPos, 1) && isInContinousLine)
                        isInContinousLine = true;
                        contLineArray{end+1, 1} = actCode;
                        contLineArray{end, 2} = actComment;
                        % Step to next line
                        continue;
                    else
                        % End of cont line
                        if isInContinousLine
                            isInContinousLine = false;
                            contLineArray{end+1, 1} = actCode;
                            contLineArray{end, 2} = actComment;

                            % Build the line for replacement
                            replacedLines = '';
                            for iLine = 1:size(contLineArray, 1) - 1
                                tempRow = strtrim(contLineArray{iLine, 1});
                                tempRow = [tempRow(1:end-3), [' ', contTokenStruct.Token, ' ']];
                                tempRow = regexprep(tempRow, ['\s+', contTokenStruct.Token, '\s+'], [' ', contTokenStruct.Token, ' ']);
                                replacedLines = [replacedLines, tempRow];
                            end
                            replacedLines = [replacedLines, actCode];

                            % Replace
                            actCodeFinal = obj.performReplacements(replacedLines);

                            % Re-create the original structure

                            if numel(contLineArray)
                                [startIndices, endIndices] = regexp(actCodeFinal, '\s*#MBeutyCont(|Matrix|Curly)#');
                                inliningwasDone = ~numel(startIndices);

                                if inliningwasDone
                                    fullComment = obj.buildContinousLineCommentAsPrecedingLines(contLineArray);

                                    if isempty(fullComment)
                                        line = actCodeFinal;
                                    else
                                        line = [fullComment, newLine, actCodeFinal];
                                    end

                                    lastComment = contLineArray{end, 2};
                                    if ~isempty(strtrim(lastComment))
                                        if ~numel(regexp(lastComment, '^\s*%'))
                                            lastComment = ['% ', lastComment];
                                        end
                                        line = [line, ' ', lastComment];
                                    end

                                else
                                    linesAreMathing = numel(startIndices) == size(contLineArray, 1) - 1;

                                    line = '';
                                    prevComment = '';
                                    lastEndIndex = 0;
                                    for iMatch = 1:numel(startIndices)
                                        partBefore = strtrim(actCodeFinal(lastEndIndex+1:startIndices(iMatch)-1));
                                        token = actCodeFinal(startIndices(iMatch):endIndices(iMatch));
                                        lastEndIndex = endIndices(iMatch);
                                        if linesAreMathing
                                            line = [line, partBefore, [' ', contTokenStruct.StoredValue, ' '], contLineArray{iMatch, 2}, newLine];
                                        else
                                            line = [line, partBefore, [' ', contTokenStruct.StoredValue, ' '], newLine];
                                        end
                                    end
                                    if ~linesAreMathing
                                        fullComment = obj.buildContinousLineCommentAsPrecedingLines(contLineArray);
                                        if ~isempty(fullComment)
                                            line = [fullComment, newLine, line];
                                        end
                                    end

                                    line = [line, actCodeFinal(lastEndIndex+1:end), ' ', actComment];
                                    trimmedPrevComment = strtrim(prevComment);
                                    if ~isempty(trimmedPrevComment)
                                        if ~strcmpi(trimmedPrevComment(1), '%')
                                            trimmedPrevComment = ['% ', trimmedPrevComment];
                                        end
                                        line = [trimmedPrevComment, newLine, line];
                                    end
                                end
                            else
                                line = [line, actComment];
                            end

                            replacedTextArray = [replacedTextArray, [line, MBeautifier.Constants.NewLine]];
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
                replacedTextArray = [replacedTextArray, [line, MBeautifier.Constants.NewLine]];
            end
            % The last new-line must be removed: inner new-lines are removed by the split, the last one is an additional one
            if numel(replacedTextArray) && numel(strtrim(replacedTextArray{end}))
                replacedTextArray{end} = strtrim(replacedTextArray{end});
            end

            nStartingNewlines = obj.Configuration.specialRule('StartingNewlineCount').ValueAsDouble;
            formatEndingNewlines = nStartingNewlines >= 0;
            if formatEndingNewlines
                replacedTextArray = MBeautifier.MFormatter.handleStartingEmptyLines(replacedTextArray, nStartingNewlines);
            end

            nEndingNewlines = obj.Configuration.specialRule('EndingNewlineCount').ValueAsDouble;
            formatEndingNewlines = nEndingNewlines >= 0;
            if formatEndingNewlines
                replacedTextArray = MBeautifier.MFormatter.handleTrailingEmptyLines(replacedTextArray, nEndingNewlines);

                replacedTextArray{end} = strtrim(replacedTextArray{end});
            end

            formattedSource = [replacedTextArray{:}];
        end
    end

    methods (Access = private, Static)
        function textArray = handleStartingEmptyLines(textArray, neededEmptyLineCount)
            followingNewLines = MBeautifier.MFormatter.getFollowingNewlineCount(textArray);

            newLineDelta = neededEmptyLineCount - followingNewLines;

            if newLineDelta < 0
                textArray(1:abs(newLineDelta)) = [];
            elseif newLineDelta > 0
                textArray = [repmat({MBeautifier.Constants.NewLine}, 1, newLineDelta), textArray];
            end
        end

        function count = getFollowingNewlineCount(textArray)
            count = 0;
            for i = 1:numel(textArray)
                if isempty(strtrim(textArray{i}))
                    count = count + 1;
                else
                    return;
                end
            end
        end

        function textArray = handleTrailingEmptyLines(textArray, neededEmptyLineCount)
            precedingNewLines = MBeautifier.MFormatter.getPrecedingNewlineCount(textArray);

            newLineDelta = neededEmptyLineCount - precedingNewLines;

            if newLineDelta < 0
                for i = 1:abs(newLineDelta)
                    textArray(end) = [];
                end
            elseif newLineDelta > 0
                textArray = [textArray, repmat({MBeautifier.Constants.NewLine}, 1, newLineDelta)];
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
                % MBD:Format:Off
                tokenStructs = struct();
                tokenStructs.ContinueToken = newStruct('...', '#MBeutyCont#');
                tokenStructs.ContinueMatrixToken = newStruct('...', '#MBeutyContMatrix#');
                tokenStructs.ContinueCurlyToken = newStruct('...', '#MBeutyContCurly#');
                tokenStructs.ArrayElementToken = newStruct('', '#MBeutyArrayElement#');
                tokenStructs.TransposeToken = newStruct('''', '#MBeutyTransp#');
                tokenStructs.NonConjTransposeToken = newStruct('.''', '#MBeutyNonConjTransp#');
                tokenStructs.NormNotationPlus = newStruct('+', '#MBeautifier_OP_NormNotationPlus');
                tokenStructs.NormNotationMinus = newStruct('-', '#MBeautifier_OP_NormNotationMinus');
                tokenStructs.UnaryPlus = newStruct('+', '#MBeautifier_OP_UnaryPlus');
                tokenStructs.UnaryMinus = newStruct('-', '#MBeautifier_OP_UnaryMinus');
                % MBeautifierDirective:Format:On
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

            trnspTokStruct = MBeautifier.MFormatter.TokenStruct.TransposeToken;
            nonConjTrnspTokStruct = MBeautifier.MFormatter.TokenStruct.NonConjTransposeToken;

            code = regexprep(code, trnspTokStruct.Token, trnspTokStruct.StoredValue);
            code = regexprep(code, nonConjTrnspTokStruct.Token, nonConjTrnspTokStruct.StoredValue);
        end

        function actCode = replaceTransponations(actCode, token)
            % Replaces transponation signs in the code with tokens.

            if nargin < 2
                trnspTok = MBeautifier.MFormatter.TokenStruct.TransposeToken.Token;
                nonConjTrnspTok = MBeautifier.MFormatter.TokenStruct.NonConjTransposeToken.Token;
            else
                trnspTok = token;
                nonConjTrnspTok = [token, token];
            end

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
                        tempCode = [tempCode(1:end-1), nonConjTrnspTok];
                        isLastCharTransp = true;
                    else
                        if isLastCharTransp
                            tempCode = [tempCode, trnspTok];
                        else
                            if numel(tempCode) && ~isInStr && numel(regexp(tempCode(end), charsIndicateTranspose))
                                tempCode = [tempCode, trnspTok];
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
            % Replaces strings in the code with string tokens memorizing the original text

            obj.StringMemory = MBeautifier.StringMemory.fromCodeLine(actCode);
            actCodeTemp = obj.StringMemory.MemorizedCodeLine;
        end

        function actCodeFinal = restoreStrings(obj, actCodeTemp)
            % Replaces string tokens with the original string from the memory

            for i = 1:numel(obj.StringMemory.Mementos)
                actCodeTemp = regexprep(actCodeTemp, MBeautifier.Constants.StringToken, ...
                    regexptranslate('escape', obj.StringMemory.Mementos{i}.Text), 'once');
            end

            actCodeFinal = actCodeTemp;
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

            % Replace transponation (and non-conjugate transponations) to avoid not relevant matches
            % This is just to help identify actual strings.
            possibleCode = obj.replaceTransponations(line, '#');

            exclamationInd = strfind(possibleCode, '!');
            commentSignIndexes = strfind(possibleCode, '%');
            contIndexes = strfind(possibleCode, '...');

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
                % Find the start and end of all single- or double-quoted strings
                % This treats escaped quotes as two separate quotes, which is fine
                [quoteStartInds, quoteEndInds] = regexp(possibleCode, '("|'').*?\1');
                quoteInds = sort([quoteStartInds, quoteEndInds]);

                for iCommSign = 1:commentSignCount
                    currentIndex = indexUnion{iCommSign};

                    % The line is currently "not in string"
                    if isequal(mod(sum(quoteInds < currentIndex), 2), 0)
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
                actCode = line(1:max(splittingPos-1, 1));
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

            operatorPaddingRules = obj.Configuration.operatorPaddingRuleNames();
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

            if obj.Configuration.specialRule('InlineContinousLines').ValueAsDouble
                data = regexprep(data, MBeautifier.MFormatter.TokenStruct.ContinueToken.Token, '');
            end

            % Convert all operators like + * == etc to #MBeautifier_OP_whatever# tokens
            opBuffer = {};
            operatorList = obj.AllOperators;
            operatorAppearance = regexp(data, operatorList);

            if ~isempty([operatorAppearance{:}])
                for iOpConf = 1:numel(operatorPaddingRules)
                    currField = operatorPaddingRules{iOpConf};
                    currOpStruct = obj.Configuration.operatorPaddingRule(currField);
                    dataNew = regexprep(data, ['\s*', currOpStruct.ValueFrom, '\s*'], currOpStruct.Token);
                    if ~strcmp(data, dataNew)
                        opBuffer{end+1} = currField;
                    end
                    data = dataNew;
                end
            end

            % Remove all duplicate space
            data = regexprep(data, '\s+', ' ');
            keywords = iskeyword();

            % Handle special + and - cases:
            % 	- unary plus/minus, such as in (+1): replace #MBeautifier_OP_Plus/Minus# by #MBeautifier_OP_UnaryPlus/Minus#
            %   - normalized number format, such as 7e-3: replace #MBeautifier_OP_Plus/Minus# by #MBeautifier_OP_NormNotation_Plus/Minus#
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

                    opToken = obj.Configuration.operatorPaddingRule(currField).Token;

                    splittedData = regexp(data, opToken, 'split');

                    posMatch = ['(', MBeautifier.MFormatter.joinString({'[0-9a-zA-Z_)}\]\.]', ...
                        MBeautifier.MFormatter.TokenStruct.TransposeToken.Token, ...
                        MBeautifier.MFormatter.TokenStruct.NonConjTransposeToken.Token, ...
                        MBeautifier.Constants.StringToken, ...
                        '#MBeauty_ArrayToken_\d+#'}, '|'), ')$'];
                    negMatch = [obj.Configuration.operatorPaddingRule('At').Token, ...
                        '#MBeauty_ArrayToken_\d+#$'];
                    keywordMatch = ['(?=^|\s)(', MBeautifier.MFormatter.joinString(keywords', '|'), ')$'];

                    replaceTokens = {};
                    for iSplit = 1:numel(splittedData) - 1
                        beforeItem = strtrim(splittedData{iSplit});
                        if ~isempty(beforeItem) && ...
                                numel(regexp(beforeItem, posMatch)) && ...
                                ~numel(regexp(beforeItem, negMatch)) && ...
                                (doIndexing || ~numel(regexp(beforeItem, keywordMatch)))
                            % + or - is a binary operator after:
                            %    - numbers [0-9.],
                            %    - variable names [a-zA-Z0-9_] or
                            %    - closing brackets )}]
                            %    - transpose signs ', here represented as #MBeutyTransp#
                            %    - non-conjugate transpose signs .', here represented as #MBeutyNonConjTransp#
                            %    - Strings, here represented as #MBeutyString#
                            %    - keywords
                            % but not after an anonymous function

                            % Special treatment for E: 7E-3 or 7e+4 normalized notation
                            % In this case the + and - signs are not operators so shoud be skipped
                            if numel(beforeItem) > 1 && strcmpi(beforeItem(end), 'e') && numel(regexp(beforeItem(end-1), '[0-9.]'))
                                if isPlus
                                    replaceTokens{end+1} = MBeautifier.MFormatter.TokenStruct.NormNotationPlus.Token;
                                    normPlusOperatorPresent = true;
                                else
                                    replaceTokens{end+1} = MBeautifier.MFormatter.TokenStruct.NormNotationMinus.Token;
                                    normMinusOperatorPresent = true;
                                end
                            else
                                replaceTokens{end+1} = opToken;
                            end
                        else
                            if isPlus
                                replaceTokens{end+1} = MBeautifier.MFormatter.TokenStruct.UnaryPlus.Token;
                                unaryPlusOperatorPresent = true;
                            else
                                replaceTokens{end+1} = MBeautifier.MFormatter.TokenStruct.UnaryMinus.Token;
                                unaryMinusOperatorPresent = true;
                            end
                        end
                    end

                    replacedSplittedData = cell(1, numel(replaceTokens)+numel(splittedData));
                    tokenIndex = 1;
                    for iSplit = 1:numel(splittedData)
                        replacedSplittedData{iSplit*2-1} = splittedData{iSplit};
                        if iSplit < numel(splittedData)
                            replacedSplittedData{iSplit*2} = replaceTokens{tokenIndex};
                        end
                        tokenIndex = tokenIndex + 1;
                    end
                    data = [replacedSplittedData{:}];
                end
            end

            %%
            % At this point the data is in a completely tokenized representation, e.g.'x#MBeautifier_OP_Plus#y' instead of the 'x + y'.
            % Now go backwards and replace the tokens by the real operators

            % Special tokens: Unary Plus/Minus, Normalized Number Format
            % Performance tweak: only if there were any unary or norm operators
            if unaryPlusOperatorPresent
                data = regexprep(data, ['\s*', MBeautifier.MFormatter.TokenStruct.UnaryPlus.Token, '\s*'], [' ', MBeautifier.MFormatter.TokenStruct.UnaryPlus.StoredValue]);
            end
            if unaryMinusOperatorPresent
                data = regexprep(data, ['\s*', MBeautifier.MFormatter.TokenStruct.UnaryMinus.Token, '\s*'], [' ', MBeautifier.MFormatter.TokenStruct.UnaryMinus.StoredValue]);
            end
            if normPlusOperatorPresent
                data = regexprep(data, ['\s*', MBeautifier.MFormatter.TokenStruct.NormNotationPlus.Token, '\s*'], MBeautifier.MFormatter.TokenStruct.NormNotationPlus.StoredValue);
            end
            if normMinusOperatorPresent
                data = regexprep(data, ['\s*', MBeautifier.MFormatter.TokenStruct.NormNotationMinus.Token, '\s*'], MBeautifier.MFormatter.TokenStruct.NormNotationMinus.StoredValue);
            end

            % Replace all other operators
            for iOpConf = 1:numel(operatorPaddingRules)
                currField = operatorPaddingRules{iOpConf};

                if any(strcmp(currField, opBuffer))
                    currOpStruct = obj.Configuration.operatorPaddingRule(currField);

                    valTo = currOpStruct.ValueTo;
                    if doIndexing && ~isempty(contType) && numel(regexp(currOpStruct.ValueFrom, '\+|\-|\/|\*'))
                        if strcmp(contType, 'matrix')
                            replacementPattern = currOpStruct.matrixIndexingReplacementPattern(obj.MatrixIndexingOperatorPadding);
                            if ~obj.MatrixIndexingOperatorPadding
                                valTo = strrep(valTo, ' ', '');
                            end

                        elseif strcmp(contType, 'cell')
                            replacementPattern = currOpStruct.cellArrayIndexingReplacementPattern(obj.CellArrayIndexingOperatorPadding);
                            if ~obj.CellArrayIndexingOperatorPadding
                                valTo = strrep(valTo, ' ', '');
                            end
                        end
                    else
                        replacementPattern = currOpStruct.ReplacementPattern;
                    end

                    tokenizedReplaceString = strrep(valTo, ' ', MBeautifier.Constants.WhiteSpaceToken);

                    % Replace only the amount of whitespace tokens that are actually needed by the operator rule
                    data = regexprep(data, replacementPattern, tokenizedReplaceString);
                end
            end

            if ~isContainerElement && ~obj.Configuration.specialRule('AllowMultipleStatementsPerLine').ValueAsDouble
                if numel(regexp(data, ';')) > 1
                    data = regexprep(data, ';(?!\s*$)', ';\n');
                end
            end

            data = regexprep(data, MBeautifier.Constants.WhiteSpaceToken, ' ');

            data = regexprep(data, ' \)', ')');
            data = regexprep(data, ' \]', ']');
            data = regexprep(data, '\( ', '(');
            data = regexprep(data, '\[ ', '[');

            % Keyword formatting
            keywordRules = obj.Configuration.keywordPaddingRules();
            for i = 1:numel(keywordRules)
                rule = keywordRules{i};
                data = regexprep(data, ['(?<=\b|^)', rule.Keyword, '\s*(?=#MBeauty_ArrayToken_\d+#)'], rule.ReplaceTo);
            end

            % Restore containers
            data = obj.restoreContainers(data, arrayMapCell);

            % Fix semicolon whitespace at end of line
            data = regexprep(data, '\s+;\s*$', ';');
            data = strtrim(data);
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
                if any(strcmp(data(i), MBeautifier.Constants.ContainerOpeningBrackets))
                    newDepth = depth + 1;
                    maxDepth = newDepth;
                elseif any(strcmp(data(i), MBeautifier.Constants.ContainerClosingBrackets))
                    newDepth = depth - 1;
                    depth = depth - 1;
                else
                    borderFound = false;
                end

                if borderFound
                    containerBorderIndexes{end+1, 1} = i;
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

            % TODO: Bind obj.AllOperators in in a filtered manner
            nonUnaryOperatorArray = {'&', '&&', '|', '||', '/', './', '\', '.\', '*', '.*', ':', '^', '.^', '<', '>', '==', '>=', '<=', '~='};
            nonUnaryOperatorArray1 = nonUnaryOperatorArray(cellfun(@numel, nonUnaryOperatorArray) == 1);
            nonUnaryOperatorArray2 = nonUnaryOperatorArray(cellfun(@numel, nonUnaryOperatorArray) == 2);
            operatorArray = [nonUnaryOperatorArray(:)', {'+'}, {'-'}, {'~'}];
            contTokenStructMatrix = MBeautifier.MFormatter.TokenStruct.ContinueMatrixToken;
            contTokenStructCurly = MBeautifier.MFormatter.TokenStruct.ContinueCurlyToken;
            commaToken = obj.Configuration.operatorPaddingRule('Comma').Token;

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

                %% Calculate container indexing

                % Container indexing is like:
                %   - "myArray{2}" but NOT "myArray {2}"
                %   - "myMatrix(4)" or "myMatrix (4)"
                %
                % Exceptions:
                %   - NOT after keywords: while(true)
                %   - "myMatrix (4)" is not working inside other containers, like: "[myArray (4)]" must be translated as "[myArray, (4)]"

                % Determine if whitespace can be a delimiter in this context
                isEmbeddedContainer = indexes(1) > 1;

                if isEmbeddedContainer && ...
                        (data(containerBorderIndexes{indexes(1)-1, 1}) == '[' ...
                        || data(containerBorderIndexes{indexes(1)-1, 1}) == '{')
                    isWhitespaceDelimiter = true;
                    contRegex = ['[a-zA-Z0-9_][', openingBracket, ']$'];
                else
                    isWhitespaceDelimiter = false;
                    contRegex = ['[a-zA-Z0-9_]\s*[', openingBracket, ']$'];
                end

                isContainerIndexing = numel(regexp(data(1:containerBorderIndexes{indexes(1), 1}), contRegex));
                preceedingKeyWord = false;
                if isContainerIndexing
                    keywords = iskeyword();
                    prevStr = strtrim(data(1:containerBorderIndexes{indexes(1), 1}-1));

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

                %%

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
                        strNew = [strNew(1), strtrim(obj.performFormattingSingleLine(strNew(2:end-1), doIndexing, contType, true)), strNew(end)];
                    else
                        elementsCell = regexp(str, ' ', 'split');

                        firstElem = strtrim(elementsCell{1});
                        lastElem = strtrim(elementsCell{end});

                        if numel(elementsCell) == 1
                            elementsCell{1} = firstElem(2:end-1);
                        else
                            elementsCell{1} = firstElem(2:end);
                            elementsCell{end} = lastElem(1:end-1);
                        end

                        for iElem = 1:numel(elementsCell)
                            elem = strtrim(elementsCell{iElem});
                            if numel(elem) && strcmp(elem(1), ',')
                                elem = elem(2:end);
                                if iElem > 1
                                    elementsCell{iElem-1} = [elementsCell{iElem-1}, ','];
                                end
                            end
                            elementsCell{iElem} = elem;
                        end

                        isInCurlyBracket = 0;
                        inlineMatrix = obj.Configuration.specialRule('InlineContinousLinesInMatrixes').ValueAsDouble;
                        inlineCurly = obj.Configuration.specialRule('InlineContinousLinesInCurlyBracket').ValueAsDouble;
                        for elemInd = 1:numel(elementsCell) - 1

                            currElem = strtrim(elementsCell{elemInd});
                            nextElem = strtrim(elementsCell{elemInd+1});

                            if ~numel(currElem)
                                continue;
                            end

                            isInCurlyBracket = isInCurlyBracket || numel(strfind(currElem, openingBracket));
                            isInCurlyBracket = isInCurlyBracket && ~numel(strfind(currElem, closingBracket));

                            currElemStripped = regexprep(currElem, ['[', openingBracket, closingBracket, ']'], '');
                            nextElemStripped = regexprep(nextElem, ['[', openingBracket, closingBracket, ']'], '');

                            if obj.isContinueToken(nextElemStripped) && numel(elementsCell) > elemInd + 1
                                nextElem = strtrim(elementsCell{elemInd+2});
                                nextElemStripped = regexprep(nextElem, ['[', openingBracket, closingBracket, ']'], '');
                            end

                            if strcmp(openingBracket, '[')
                                if obj.isContinueToken(currElem)
                                    if inlineMatrix
                                        elementsCell{elemInd} = '';
                                        continue;
                                    else
                                        currElem = contTokenStructMatrix.Token;
                                    end
                                else

                                end
                                addCommas = obj.Configuration.specialRule('AddCommasToMatrices').ValueAsDouble;
                            else
                                addCommas = obj.Configuration.specialRule('AddCommasToCellArrays').ValueAsDouble;
                                if obj.isContinueToken(currElem)

                                    if inlineCurly
                                        elementsCell{elemInd} = '';
                                        continue;
                                    else
                                        currElem = contTokenStructCurly.Token;
                                    end
                                end
                            end


                            % Handle space between unary operator and operand
                            % Detect if there is a potential unary operator
                            % and determine if it is the beginning of an
                            % expression
                            lastChar = currElem(end);
                            if lastChar == '-' || lastChar == '+' || lastChar == '~'
                                prevChar = [];
                                if numel(currElem) > 1
                                    prevChar = currElem(end-1);
                                elseif elemInd > 1
                                    prevElems = strtrim(elementsCell(1:elemInd-1));
                                    prevElems = prevElems(~cellfun(@isempty, prevElems));
                                    prevElem = prevElems{end};
                                    if numel(prevElem) >= numel(commaToken) && ...
                                            strcmp(prevElem(end-numel(commaToken)+1:end), commaToken)
                                        prevChar = ',';
                                    else
                                        prevChar = prevElem(end);
                                    end
                                end
                                if isempty(prevChar) || prevChar == ','
                                    currElem = [currElem, nextElem];
                                    currElemStripped = regexprep(currElem, ['[', openingBracket, closingBracket, ']'], '');
                                    elementsCell{elemInd+1} = '';
                                    if numel(elementsCell) > elemInd + 1
                                        nextElem = strtrim(elementsCell{elemInd+2});
                                        nextElemStripped = regexprep(nextElem, ['[', openingBracket, closingBracket, ']'], '');
                                    else
                                        elementsCell{elemInd} = currElem;
                                        break
                                    end
                                end
                            end

                            currElem = strtrim(obj.performFormattingSingleLine(currElem, doIndexing, contType, true));
                            numNext = numel(nextElemStripped);

                            if ~addCommas || ...
                                    isempty(currElem) || ...
                                    strcmp(currElem(end), ',') || ...
                                    strcmp(currElem(end), ';') || ...
                                    isInCurlyBracket || ...
                                    obj.isContinueToken(currElem) || ...
                                    any(strcmp(currElemStripped, operatorArray)) || ...
                                    any(strcmp(currElemStripped(end), operatorArray)) || ...
                                    (numNext >= 1 && any(strcmp(nextElemStripped(1), nonUnaryOperatorArray1))) || ...
                                    (numNext > 1 && any(strcmp(nextElemStripped(1:2), nonUnaryOperatorArray2))) || ...
                                    (numNext == 1 && any(strcmp(nextElemStripped, operatorArray))) || ...
                                    numel(regexp(currElemStripped, '^@#MBeauty_ArrayToken_\d+#$'))

                                elementsCell{elemInd} = [currElem, ' '];
                            else
                                elementsCell{elemInd} = [currElem, commaToken];
                            end
                        end
                        elementsCell(cellfun('isempty', elementsCell)) = [];

                        if ~isempty(elementsCell)
                            elementsCell{end} = strtrim(obj.performFormattingSingleLine(elementsCell{end}, doIndexing, contType, true));
                        end
                        strNew = [openingBracket, elementsCell{:}, closingBracket];
                    end
                else
                    strNew = strtrim(str);
                    strNew = [strNew(1), strtrim(obj.performFormattingSingleLine(strNew(2:end-1), doIndexing, contType, true)), strNew(end)];
                end

                datacell = cell(1, 3);
                if containerBorderIndexes{indexes(1), 1} == 1
                    datacell{1} = '';
                else

                    datacell{1} = data(1:containerBorderIndexes{indexes(1), 1}-1);
                    if isContainerIndexing
                        if isWhitespaceDelimiter && datacell{1}(end) == ' '
                            datacell{1} = [strtrim(datacell{1}), ' '];
                        else
                            datacell{1} = strtrim(datacell{1});
                        end
                    elseif preceedingKeyWord
                        datacell{1} = strtrim(datacell{1});
                        datacell{1} = [datacell{1}, ' '];
                    end
                end

                if containerBorderIndexes{indexes(2), 1} == numel(data)
                    datacell{end} = '';
                else
                    datacell{end} = data(containerBorderIndexes{indexes(2), 1}+1:end);
                end

                idAsStr = num2str(id);
                idStr = [repmat('0', 1, 5-numel(idAsStr)), idAsStr];
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
            obj.Configuration.operatorPaddingRule('Comma').Token;
            data = regexprep(data, obj.Configuration.operatorPaddingRule('Comma').Token, obj.Configuration.operatorPaddingRule('Comma').ValueTo);
        end

        function ret = isContinueToken(obj, element)
            ret = strcmp(element, obj.TokenStruct.ContinueToken.Token) || ...
                strcmp(element, obj.TokenStruct.ContinueMatrixToken.Token) || ...
                strcmp(element, obj.TokenStruct.ContinueCurlyToken.Token);
        end

        function fullComment = buildContinousLineCommentAsPrecedingLines(obj, contLineArray)
            fullComment = '';
            newLine = MBeautifier.Constants.NewLine;
            for iCont = 1:size(contLineArray, 1) - 1
                cComment = contLineArray{iCont, 2};
                if isempty(strtrim(cComment))
                    continue
                end
                if ~numel(regexp(cComment, '^\s*%'))
                    cComment = ['% ', cComment];
                end
                if isempty(fullComment)
                    fullComment = cComment;
                else
                    fullComment = [fullComment, newLine, cComment];
                end
            end
        end
    end
end