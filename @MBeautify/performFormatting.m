function formattedSource = performFormatting(source)
settingConf = MBeautify.getConfigurationStruct();

nMaximalNewLines = str2double(settingConf.SpecialRules.MaximalNewLinesValue);
newLine = sprintf('\n');

tokStruct = MBeautify.getTokenStruct();

contTokenStruct = tokStruct('ContinueToken');


%%
textArray = regexp(source, newLine, 'split');

replacedTextArray = {};
isInContinousLine = 0;
containerDepth = 0;
contLineArray = cell(0, 2);

isInBlockComment = false;
blockCommentDepth = 0;
nNewLinesFound = 0;
for j = 1:numel(textArray)
    line = textArray{j};
    
    %% Process the maximal new-line count
    isAcceptable = true;
    
    if isempty(strtrim(line))
        if ~(nNewLinesFound < nMaximalNewLines)
            isAcceptable = false;
        end
        nNewLinesFound = nNewLinesFound + 1;
    else
        nNewLinesFound = 0;
    end
    
    if ~isAcceptable
        continue;
    end
    
    %% Determine the position where the line shall be splitted into code and comment
    [commPos, exclamationPos, isInBlockComment, blockCommentDepth] = findComment(line, isInBlockComment, blockCommentDepth);
    splittingPos = max(commPos, exclamationPos);
    
    %% Split the line into two parts: code and comment
    [actCode, actComment] = getCodeAndComment(line, splittingPos);
    
    %% Check for line continousment (...)
  % Continous lines have to be converted into one single code line to perform replacement on it
    % The continousment characters have to be replaced by tokens and the comments of the lines must be stored
    % After replacement, the continuosment has to be re-created along with the comments.
    trimmedCode = strtrim(actCode);
    if numel(trimmedCode)
        
        containerDepth = containerDepth + calculateContainerDepthDeltaOfLine(trimmedCode);
        
        if containerDepth && ~(numel(trimmedCode) >= 3 && strcmp(trimmedCode(end-2:end), '...'))
            postfix = '; ...';
            if strcmp(trimmedCode(end), ',') || strcmp(trimmedCode(end), ';')
                actCode = trimmedCode(1:end-1);
            end
            actCode = [actCode, postfix];
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
                isInContinousLine = 0;
                contLineArray{end+1, 1} = actCode;
                contLineArray{end, 2} = actComment;
                
                %% ToDo: Process
                replacedLines = '';
                for iLine = 1:size(contLineArray, 1) - 1
                    tempRow = strtrim(contLineArray{iLine, 1});
                    tempRow = [tempRow(1:end-3), [' ', contTokenStruct.Token, ' ']];
                    tempRow = regexprep(tempRow, ['\s+', contTokenStruct.Token, '\s+'], [' ', contTokenStruct.Token, ' ']);
                    replacedLines = [replacedLines, tempRow];
                end
                
                replacedLines = [replacedLines, actCode];
                
                actCodeFinal = performReplacements(replacedLines, settingConf);
                
                splitToLine = regexp(actCodeFinal, contTokenStruct.Token, 'split');
                
                line = '';
                for iSplitLine = 1:numel(splitToLine) - 1
                    line = [line, strtrim(splitToLine{iSplitLine}), [' ', contTokenStruct.StoredValue, ' '], contLineArray{iSplitLine, 2}, newLine];
                end
                line = [line, strtrim(splitToLine{end}), actComment]; %#ok<*AGROW>
                
                replacedTextArray = [replacedTextArray, {line, sprintf('\n')}];
                
                contLineArray = cell(0, 2);
                
                continue;
            end
            
        end
        
        actCodeFinal = performReplacements(actCode, settingConf);
    else
        actCodeFinal = '';
    end
    
    line = [strtrim(actCodeFinal), ' ', actComment];
    replacedTextArray = [replacedTextArray, {line, sprintf('\n')}];
end
% The last new-line must be removed: inner new-lines are removed by the split, the last one is an additional one
if numel(replacedTextArray)
   replacedTextArray(end) = []; 
end

formattedSource = [replacedTextArray{:}];

end

function ret = calculateContainerDepthDeltaOfLine(code)
ret = 0;
% Pre-check for opening and closing brackets: the final delta has to be calculated after the transponations and the
% strings are replaced, which are time consuming actions
if numel(regexp(code, '{|[')) || numel(regexp(code, '}|]'))
    actCodeTemp = replaceTransponations(code);
    actCodeTemp = replaceStrings(actCodeTemp);
    
    ret = numel(regexp(actCodeTemp, '{|[')) - numel(regexp(actCodeTemp, '}|]'));
end
end


function [actCode, actComment] = getCodeAndComment(line, commPos)
if isequal(commPos, 1)
    actCode = '';
    actComment = line;
elseif commPos == -1
    actCode = line;
    actComment = '';
else
    actCode = line(1:max(commPos-1, 1));
    actComment = strtrim(line(commPos:end));
end
end

function [actCodeTemp, strTokStructs] = replaceStrings(actCode)
tokStruct = MBeautify.getTokenStruct();

%% Strings
splittedCode = regexp(actCode, '''', 'split');

strTokStructs = cell(1, ceil(numel(splittedCode)/2));

strArray = cell(1, numel(splittedCode));

for iSplit = 1:numel(splittedCode)
    % Not string
    if ~isequal(mod(iSplit, 2), 0)
        
        mstr = splittedCode{iSplit};
        
        strArray{iSplit} = mstr;
    else % String
        strTokenStruct = tokStruct('StringToken');
        
        strArray{iSplit} = strTokenStruct.Token;
        strTokenStruct.StoredValue = splittedCode{iSplit};
        strTokStructs{iSplit} = strTokenStruct;
    end
end

strTokStructs = strTokStructs(cellfun(@(x) ~isempty(x), strTokStructs));

actCodeTemp = [strArray{:}];

end

function actCodeFinal = restoreStrings(actCodeTemp, strTokStructs)
tokStruct = MBeautify.getTokenStruct();
strTokenStruct = tokStruct('StringToken');
splitByStrTok = regexp(actCodeTemp, strTokenStruct.Token, 'split');

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

function actCode = replaceTransponations(actCode)
tokStruct = MBeautify.getTokenStruct();
trnspTokStruct = tokStruct('TransposeToken');
nonConjTrnspTokStruct = tokStruct('NonConjTransposeToken');


charsIndicateTranspose = '[a-zA-Z0-9\)\]\}\.]';

tempCode = '';
isLastCharDot = false;
isLastCharTransp = false;
isInStr = false;
for iStr = 1:numel(actCode)
    actChar = actCode(iStr);
    
    if strcmp(actChar, '''')
        % .' => NonConj transpose
        if isLastCharDot
            tempCode = tempCode(1:end-1);
            tempCode = [tempCode, nonConjTrnspTokStruct.Token];
            isLastCharTransp = true;
        else
            if isLastCharTransp
                tempCode = [tempCode, trnspTokStruct.Token];
                isLastCharTransp = true;
            else
                
                if numel(tempCode) && numel(regexp(tempCode(end), charsIndicateTranspose)) && ~isInStr
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

function actCodeFinal = restoreTransponations(actCodeFinal)
tokStruct = MBeautify.getTokenStruct();
trnspTokStruct = tokStruct('TransposeToken');
nonConjTrnspTokStruct = tokStruct('NonConjTransposeToken');

actCodeFinal = regexprep(actCodeFinal, trnspTokStruct.Token, trnspTokStruct.StoredValue);
actCodeFinal = regexprep(actCodeFinal, nonConjTrnspTokStruct.Token, nonConjTrnspTokStruct.StoredValue);
end

function actCodeFinal = performReplacements(actCode, settingConf)
actCode = replaceTransponations(actCode);
[actCode, strTokenStruct] = replaceStrings(actCode);

actCodeTemp = performReplacementsSingleLine(actCode, settingConf);

actCodeFinal = restoreStrings(actCodeTemp, strTokenStruct);
actCodeFinal = restoreTransponations(actCodeFinal);

end

function [retComm, exclamationPos, isInBlockComment, blockCommentDepth] = findComment(line, isInBlockComment, blockCommentDepth)
%% Set the variables
retComm = -1;
exclamationPos = -1;

trimmedLine = strtrim(line);

%% Handle some special cases

if strcmp(trimmedLine, '%{')
    retComm = 1;
    isInBlockComment = true;
    blockCommentDepth = blockCommentDepth + 1;
elseif strcmp(trimmedLine, '%}') && isInBlockComment
    retComm = 1;
    
    blockCommentDepth = blockCommentDepth - 1;
    isInBlockComment = blockCommentDepth > 0;
else
    if isInBlockComment
        retComm = 1;
        isInBlockComment = true;
    end
end

% In block comment, return
if isequal(retComm, 1), return; end

% Empty line, simply return
if isempty(trimmedLine)
    return;
end


if isequal(trimmedLine, '%')
    retComm = 1;
    return;
end

if isequal(trimmedLine(1), '!')
    exclamationPos = 1;
    return
end

% If line starts with "import ", it indicates a java import, that line is treated as comment
if numel(trimmedLine) > 7 && isequal(trimmedLine(1:7), 'import ')
    retComm = 1;
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
if commentSignCount
    
    for iCommSign = 1:commentSignCount
        currentIndex = indexUnion{iCommSign};
        
        % Check all leading parts that can be "code"
        % Replace transponation (and noin-conjugate transponations) to avoid not relevant matches
        possibleCode = line(1:currentIndex-1);
        possibleCode = replaceTransponations(possibleCode);
        
        copSignIndexes = strfind(possibleCode, '''');
        copSignCount = numel(copSignIndexes);
        
        % The line is currently "not in string"
        if isequal(mod(copSignCount, 2), 0)
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
else
    retComm = -1;
end

end

function token = generateOperatorToken(operatorName)
token = ['#MBeauty_OP_', operatorName, '#'];
end

function data = performReplacementsSingleLine(data, settingConf, doIndexing)

if isempty(data)
    return;
end

if nargin < 3
    doIndexing = false;
end

tokStruct = MBeautify.getTokenStruct();

setConfigOperatorFields = fields(settingConf.OperatorRules);
% At this point, the data contains one line of code, but all user-defined strings enclosed in '' are replaced by #MBeutyString#

keywords = iskeyword();

% Old-style function calls, such as 'subplot 211' or 'disp Hello World' -> return unchanged
if numel(regexp(data, '^[a-zA-Z0-9_]+\s+[^(=]'))
    
    splitData = regexp(strtrim(data), ' ', 'split');
    % The first elemen is not a keyword and does not exist (function on the path)
    if numel(splitData) && ~any(strcmp(splitData{1}, keywords)) && exist(splitData{1}) %#ok<EXIST>
        return
    end
end

% Process matrixes and cell arrays
% All containers are processed element wised. The replaced containers are placed into a map where the key is a token
% inserted to the original data
[data, arrayMapCell] = processContainer(data, settingConf);

% Convert all operators like + * == etc to #MBeauty_OP_whatever# tokens
opBuffer = {};
operatorList = MBeautify.getAllOperators();
operatorAppearance = regexp(data, operatorList);

if ~isempty([operatorAppearance{:}])
    for iOpConf = 1:numel(setConfigOperatorFields)
        currField = setConfigOperatorFields{iOpConf};
        currOpStruct = settingConf.OperatorRules.(currField);
        dataNew = regexprep(data, ['\s*', currOpStruct.ValueFrom, '\s*'], generateOperatorToken(currField));
        if ~strcmp(data, dataNew)
            opBuffer{end+1} = generateOperatorToken(currField);
        end
        data = dataNew;
    end
end

% Remove all duplicate space
data = regexprep(data, '\s+', ' ');

% Handle special + and - cases:
% 	- unary plus/minus, such as in (+1): replace #MBeauty_OP_Plus/Minus# by #MBeauty_OP_UnaryPlus/Minus#
%   - normalized number format, such as 7e-3: replace #MBeauty_OP_Plus/Minus# by #MBeauty_OP_NormNotation_Plus/Minus#
% Then convert UnaryPlus tokens to '+' signs same for minus)
for iOpConf = 1:numel(setConfigOperatorFields)
    currField = setConfigOperatorFields{iOpConf};
    
    opToken = generateOperatorToken(currField);
    
    
    isPlus = strcmp(opToken, generateOperatorToken('Plus'));
    isMinus = strcmp(opToken, generateOperatorToken('Minus'));
    
    if (isPlus || isMinus) && numel(regexp(data, opToken))
        
        splittedData = regexp(data, opToken, 'split');
        
        replaceTokens = {};
        for iSplit = 1:numel(splittedData) - 1
            beforeItem = strtrim(splittedData{iSplit});
            if ~isempty(beforeItem) && numel(regexp(beforeItem, ...
                    ['([0-9a-zA-Z_)}\]\.]|', tokStruct('TransposeToken').Token, '|#MBeauty_ArrayToken_.*#)$']))
                % + or - is a binary operator after:
                %    - numbers [0-9.],
                %    - variable names [a-zA-Z0-9_] or
                %    - closing brackets )}]
                %    - transpose signs ', here represented as #MBeutyTransp#
                
                % Special treatment for E: 7E-3 or 7e+4 normalized notation
                % In this case the + and - signs are not operators so shoud be skipped
                if numel(beforeItem) > 1 && strcmpi(beforeItem(end), 'e') && numel(regexp(beforeItem(end-1), '[0-9]'))
                    if isPlus
                        replaceTokens{end+1} = tokStruct('NormNotationPlus').Token;
                    elseif isMinus
                        replaceTokens{end+1} = tokStruct('NormNotationMinus').Token;
                    end
                    
                else
                    replaceTokens{end+1} = opToken;
                end
            else
                if isPlus
                    replaceTokens{end+1} = tokStruct('UnaryPlus').Token;
                elseif isMinus
                    replaceTokens{end+1} = tokStruct('UnaryMinus').Token;
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

% At this point the data is in a completely tokenized representation, e.g.'x#MBeauty_OP_Plus#y' instead of the 'x + y'.
% Now go backwards and replace the tokens by the real operators

% Special tokens: Unary Plus/Minus, Normalized Number Format
data = regexprep(data, ['\s*', tokStruct('UnaryPlus').Token, '\s*'], tokStruct('UnaryPlus').StoredValue);
data = regexprep(data, ['\s*', tokStruct('UnaryMinus').Token, '\s*'], tokStruct('UnaryMinus').StoredValue);
data = regexprep(data, ['\s*', tokStruct('NormNotationPlus').Token, '\s*'], tokStruct('NormNotationPlus').StoredValue);
data = regexprep(data, ['\s*', tokStruct('NormNotationMinus').Token, '\s*'], tokStruct('NormNotationMinus').StoredValue);

% Replace all other operators

for iOpConf = 1:numel(setConfigOperatorFields)
    
    currField = setConfigOperatorFields{iOpConf};
    if any(strcmp(generateOperatorToken(currField), opBuffer))
        currOpStruct = settingConf.OperatorRules.(currField);
        
        replaceTo = currOpStruct.ValueTo;
        if doIndexing && numel(regexp(currOpStruct.ValueFrom, '\+|\-|\/|\*|\:'))
            replaceTo = strtrim(replaceTo);
        end
        data = regexprep(data, ['\s*', generateOperatorToken(currField), '\s*'], replaceTo);
    end
end


data = regexprep(data, ' \)', ')');
data = regexprep(data, ' \]', ']');
data = regexprep(data, '\( ', '(');
data = regexprep(data, '\[ ', '[');

% Restore containers
data = decodeArrayTokens(data, arrayMapCell, settingConf);

% Fix semicolon whitespace at end of line
data = regexprep(data, '\s+;\s*$', ';');
end

function data = decodeArrayTokens(data, map, settingConf)
arrayTokenList = map.keys();
if isempty(arrayTokenList)
    return;
end

for iKey = numel(arrayTokenList):- 1:1
    data = regexprep(data, arrayTokenList{iKey}, regexptranslate('escape', map(arrayTokenList{iKey})));
end

data = regexprep(data, generateOperatorToken('Comma'), settingConf.OperatorRules.Comma.ValueTo);
end

function [containerBorderIndexes, maxDepth] = calculateContainerDepths(data, openingBrackets, closingBrackets)
containerBorderIndexes = {};
depth = 1;
maxDepth = 1;
for i = 1:numel(data)
    borderFound = true;
    if any(strcmp(data(i), openingBrackets))
        newDepth = depth + 1;
        maxDepth = newDepth;
    elseif any(strcmp(data(i), closingBrackets))
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

function [data, arrayMap] = processContainer(data, settingConf)

arrayMap = containers.Map();
if isempty(data)
    return
end

data = regexprep(data, '\s+;', ';');

openingBrackets = {'[', '{', '('};
closingBrackets = {']', '}', ')'};

tokStruct = MBeautify.getTokenStruct();

operatorArray = {'+', '-', '&', '&&', '|', '||', '/', './', '\', '.\', '*', '.*', ':', '^', '.^', '~'};
contTokenStruct = tokStruct('ContinueToken');

[containerBorderIndexes, maxDepth] = calculateContainerDepths(data, openingBrackets, closingBrackets);

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
    
    str = data(containerBorderIndexes{indexes(1), 1}:containerBorderIndexes{indexes(2), 1});
    
    openingBracket = data(containerBorderIndexes{indexes(1), 1});
    closingBracket = data(containerBorderIndexes{indexes(2), 1});
    
    isContainerIndexing = numel(regexp(data(1:containerBorderIndexes{indexes(1), 1}), ['[a-zA-Z0-9_]\s*[', openingBracket, ']$']));
    preceedingKeyWord = false;
    if isContainerIndexing
        keywords = iskeyword();
        prevStr = strtrim(data(1:containerBorderIndexes{indexes(1), 1}-1));
        for i = 1:numel(keywords)
            if numel(regexp(prevStr, ['(?<=\s|^)', keywords{i}, '$']))
                isContainerIndexing = false;
                preceedingKeyWord = true;
                break;
            end
        end
    end
    
    doIndexing = isContainerIndexing;
    if doIndexing
        
        
        if strcmp(openingBracket, '(')
            doIndexing = ~str2double(settingConf.SpecialRules.MatrixIndexing_ArithmeticOperatorPaddingValue);
        elseif strcmp(openingBracket, '{')
            doIndexing = ~str2double(settingConf.SpecialRules.CellArrayIndexing_ArithmeticOperatorPaddingValue);
        else
            doIndexing = false;
        end
    end
    
    str = regexprep(str, '\s+', ' ');
    str = regexprep(str, [openingBracket, '\s+'], openingBracket);
    str = regexprep(str, ['\s+', closingBracket], closingBracket);
    
    
    if ~strcmp(openingBracket, '(')
        if doIndexing
            strNew = strtrim(str);
            strNew = [strNew(1), strtrim(performReplacementsSingleLine(strNew(2:end-1), settingConf, doIndexing)), strNew(end)];
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
                end
                elementsCell{iElem} = elem;
            end
            
            isInCurlyBracket = 0;
            for elemInd = 1:numel(elementsCell) - 1
                
                currElem = strtrim(elementsCell{elemInd});
                nextElem = strtrim(elementsCell{elemInd+1});
                
                if ~numel(currElem)
                    continue;
                end
                
                hasOpeningBrckt = numel(strfind(currElem, openingBracket));
                isInCurlyBracket = isInCurlyBracket || hasOpeningBrckt;
                hasClosingBrckt = numel(strfind(currElem, closingBracket));
                isInCurlyBracket = isInCurlyBracket && ~hasClosingBrckt;
                
                currElemStripped = regexprep(currElem, ['[', openingBracket, closingBracket, ']'], '');
                nextElemStripped = regexprep(nextElem, ['[', openingBracket, closingBracket, ']'], '');
                
                currElem = strtrim(performReplacementsSingleLine(currElem, settingConf, doIndexing));
                
                if strcmp(openingBracket, '[')
                    addCommas = str2double(settingConf.SpecialRules.AddCommasToMatricesValue);
                else
                    addCommas = str2double(settingConf.SpecialRules.AddCommasToCellArraysValue);
                end
                
                if numel(currElem) && addCommas && ...
                        ~(strcmp(currElem(end), ',') || strcmp(currElem(end), ';')) && ~isInCurlyBracket && ...
                        ~strcmp(currElem, contTokenStruct.Token) && ...
                        ~any(strcmp(currElemStripped, operatorArray)) && ~any(strcmp(nextElemStripped, operatorArray))
                    
                    elementsCell{elemInd} = [currElem, '#MBeauty_OP_Comma#'];
                else
                    elementsCell{elemInd} = [currElem, ' '];
                end
            end
            
            elementsCell{end} = strtrim(performReplacementsSingleLine(elementsCell{end}, settingConf, doIndexing));
            
            strNew = [openingBracket, elementsCell{:}, closingBracket];
        end
    else
        strNew = strtrim(str);
        strNew = [strNew(1), strtrim(performReplacementsSingleLine(strNew(2:end-1), settingConf, doIndexing)), strNew(end)];
    end
    
    datacell = cell(1, 3);
    if containerBorderIndexes{indexes(1), 1} == 1
        datacell{1} = '';
    else
        
        datacell{1} = data(1:containerBorderIndexes{indexes(1), 1}-1);
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
        datacell{end} = data(containerBorderIndexes{indexes(2), 1}+1:end);
    end
    
    
    idStr = [repmat('0', 1, 5-numel(num2str(id))), num2str(id)];
    tokenOfCUrElem = ['#MBeauty_ArrayToken_', idStr, '#'];
    arrayMap(tokenOfCUrElem) = strNew;
    id = id + 1;
    datacell{2} = tokenOfCUrElem;
    data = [datacell{:}];
    
    containerBorderIndexes = calculateContainerDepths(data, openingBrackets, closingBrackets);
end
end


