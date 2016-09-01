function formattedSource = performFormatting(source, settingConf)

nMaximalNewLines = str2double(settingConf.SpecialRules.MaximalNewLinesValue);
newLine = sprintf('\n');

tokStruct = MBeautify.getTokenStruct();

contTokenStruct = tokStruct('ContinueToken');




%%
textArray = regexp(source, newLine, 'split');

replacedTextArray = cell(1, numel(textArray) * 4);
isInContinousLine = 0;
contLineArray = cell(0,2);

isInBlockComment = false;
blockCommentDepth = 0;
lastIndexUsed = 0;
nNewLinesFound = 0;
for j = 1: numel(textArray) % in textArray)
    line = textArray{j};
    
    %% Process the maximal new-line count
    [isAcceptable, nNewLinesFound] = MBeautify.handleMaximalNewLines(line, nNewLinesFound, nMaximalNewLines);
    
    if ~isAcceptable
        continue;
    end
    
    %% Determine the position where the line shall be splitted into code and comment
    [commPos, exclamationPos, isInBlockComment, blockCommentDepth] = findComment(line, isInBlockComment, blockCommentDepth);
    splittingPos = max(commPos, exclamationPos);
    
    %% Split the line into two parts: code and comment
    [actCode, actComment] = getCodeAndComment(line, splittingPos);
    
    %% Check for line continousment (...)
    trimmedCode = strtrim(actCode);
    % Line ends with "..."
    if (numel(trimmedCode) >= 3 && strcmp(trimmedCode(end-2:end), '...')) ...
            || (isequal(splittingPos, 1) && isInContinousLine )
        isInContinousLine = true;
        contLineArray{end+1,1} = actCode;
        contLineArray{end,2} = actComment;
        % Step to next line
        continue;
    else
        % End of cont line
        if isInContinousLine
            isInContinousLine = 0;
            contLineArray{end+1,1} = actCode;
            contLineArray{end,2} = actComment;
            
            %% ToDo: Process
            replacedLines = '';
            for iLine = 1:size(contLineArray, 1) - 1
                tempRow = strtrim(contLineArray{iLine, 1});
                tempRow = [tempRow(1:end-3), [ ' ', contTokenStruct.Token, ' ' ]];
                tempRow = regexprep(tempRow, ['\s+', contTokenStruct.Token, '\s+'], [ ' ', contTokenStruct.Token, ' ' ]);
                replacedLines = MBeautify.strConcat(replacedLines, tempRow);
                
            end
            
            replacedLines = MBeautify.strConcat(replacedLines, actCode);
            
            actCodeFinal = performReplacements(replacedLines, settingConf);
            
            splitToLine = regexp(actCodeFinal, contTokenStruct.Token, 'split');
            
            line = '';
            for iSplitLine = 1:numel(splitToLine) - 1
                line = MBeautify.strConcat(line, strtrim(splitToLine{iSplitLine}),  [' ', contTokenStruct.StoredValue, ' '], contLineArray{iSplitLine,2}, newLine);
            end
            line = MBeautify.strConcat(line, strtrim(splitToLine{end}),  actComment);
            
            [replacedTextArray, lastIndexUsed] = arrayAppend(replacedTextArray, {line, sprintf('\n')}, lastIndexUsed);
            
            contLineArray = cell(0,2);
            
            continue;
            
            
        end
    end
    
    
    actCodeFinal = performReplacements(actCode, settingConf);
    line = [strtrim(actCodeFinal), ' ', actComment];
    [replacedTextArray, lastIndexUsed] = arrayAppend(replacedTextArray, {line, sprintf('\n')}, lastIndexUsed);
    
end

formattedSource = [replacedTextArray{:}];

end

function [actCode, actComment] = getCodeAndComment(line, commPos)
if isequal(commPos, 1)
    actCode = '';
    actComment = line;
elseif commPos == - 1
    actCode = line;
    actComment = '';
else
    actCode = line(1: max(commPos - 1, 1));
    actComment = strtrim(line(commPos:end));
end
end

function actCodeFinal = performReplacements(actCode, settingConf)

tokStruct = MBeautify.getTokenStruct();
%% Transpose
actCode = replaceTransponations(actCode);
trnspTokStruct = tokStruct('TransposeToken');
nonConjTrnspTokStruct = tokStruct('NonConjTransposeToken');


%% Strings
splittedCode = regexp(actCode, '''', 'split');
strTokenStruct = tokStruct('StringToken');

strTokStructs = cell(1,ceil(numel(splittedCode)/2));

strArray = cell(1, numel(splittedCode));

for iSplit = 1 : numel(splittedCode)
    % Not string
    if ~isequal(mod(iSplit, 2), 0)
        
        mstr = splittedCode{iSplit};
        
        strArray{iSplit} = mstr;
    else % String
        strTokenStruct = tokStruct('StringToken');
        
        strArray{iSplit}  = strTokenStruct.Token;
        strTokenStruct.StoredValue = splittedCode{iSplit};
        strTokStructs{iSplit} = strTokenStruct;
    end
    
end

strTokStructs = strTokStructs(cellfun(@(x) ~isempty(x), strTokStructs));

actCodeTemp = [strArray{:}];
actCodeTemp = performReplacementsSingleLine(actCodeTemp, settingConf);


splitByStrTok = regexp(actCodeTemp, strTokenStruct.Token, 'split');

if numel(strTokStructs)
    actCodeFinal = '';
    for iSplit = 1:numel(strTokStructs)
        actCodeFinal = MBeautify.strConcat(actCodeFinal, splitByStrTok{iSplit}, '''', strTokStructs{iSplit}.StoredValue, '''');
        %actCodeFinal = [actCodeFinal, splitByStrTok{iSplit}, '''', strTokStructs{iSplit}.StoredValue, '''' ];
    end
    
    if numel(splitByStrTok) > numel(strTokStructs)
        actCodeFinal = [actCodeFinal, splitByStrTok{end}];
    end
else
    actCodeFinal = actCodeTemp;
end

actCodeFinal = regexprep(actCodeFinal,trnspTokStruct.Token,trnspTokStruct.StoredValue);
actCodeFinal = regexprep(actCodeFinal,nonConjTrnspTokStruct.Token,nonConjTrnspTokStruct.StoredValue);



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
    
    if isequal(actChar,'''')
        % .' => NonConj transpose
        if isLastCharDot
            tempCode = tempCode(1:end-1);
            tempCode = MBeautify.strConcat(tempCode, nonConjTrnspTokStruct.Token);
            % tempCode = [tempCode, nonConjTrnspTokStruct.Token];
            isLastCharTransp = true;
        else
            if isLastCharTransp
                tempCode = MBeautify.strConcat(tempCode, trnspTokStruct.Token);
                % tempCode = [tempCode, trnspTokStruct.Token];
                isLastCharTransp = true;
            else
                
                if numel(tempCode) && numel(regexp(tempCode(end),charsIndicateTranspose)) && ~isInStr
                    
                    tempCode = MBeautify.strConcat(tempCode, trnspTokStruct.Token);
                    % tempCode = [tempCode, trnspTokStruct.Token];
                    isLastCharTransp = true;
                else
                    tempCode = MBeautify.strConcat(tempCode, actChar);
                    % tempCode = [tempCode, actChar];
                    isInStr = ~isInStr;
                    isLastCharTransp = false;
                end
            end
        end
        
        isLastCharDot = false;
    elseif isequal(actChar,'.') && ~isInStr
        isLastCharDot = true;
        tempCode = MBeautify.strConcat(tempCode, actChar);
        % tempCode = [tempCode, actChar];
        isLastCharTransp = false;
    else
        isLastCharDot = false;
        tempCode = MBeautify.strConcat(tempCode, actChar);
        % tempCode = [tempCode, actChar];
        isLastCharTransp = false;
    end
end
actCode = tempCode;
end

function [retComm, exclamationPos, isInBlockComment, blockCommentDepth] = findComment(line, isInBlockComment, blockCommentDepth)
%% Set the variables
retComm = - 1;
exclamationPos = -1;

trimmedLine = strtrim(line);

%% Handle some special cases

if strcmp(trimmedLine,'%{')
    retComm = 1;
    isInBlockComment = true;
    blockCommentDepth = blockCommentDepth + 1;
elseif strcmp(trimmedLine,'%}') && isInBlockComment
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
if isequal(retComm,1), return; end

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

exclamationInd =  strfind(line, '!');
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
% commUnionExclIndexes = {commentSignIndexes{:}, exclamationInd{:}};
indexUnion = {commentSignIndexes{:}, exclamationInd{:}, contIndexes{:}};
% commUnionExclIndexes = sortrows(commUnionExclIndexes(:))';
indexUnion = sortrows(indexUnion(:))';

% Iterate through the union
commentSignCount = numel(indexUnion);
if commentSignCount
    
    for iCommSign = 1: commentSignCount
        currentIndex = indexUnion{iCommSign};
        
        % Check all leading parts that can be "code"
        % Replace transponation (and noin-conjugate transponations) to
        % avoid not relevant matches
        possibleCode = line(1:currentIndex - 1);
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
                retComm = currentIndex+3;
            end
            
            break;
        end
        
    end
else
    retComm = - 1;
end

end


function data = performReplacementsSingleLine(data, settingConf)

setConfigOperatorFields = fields(settingConf.OperatorRules);
% at this point, the data contains one line of code, but all user-defined strings enclosed in ''
% were replaced by #MBeutyString#

% old-style function calls, such as
% 'subplot 211' or 'disp Hello World'
% -> return unchanged
if numel(regexp(data,'^[a-zA-Z0-9_]+\s+[^(=]'))
    % TODO: fix whitespace after function name, semicolon at end etc.
    return
end

% replace all control flow keywords (if, for, ...) by #MBeauty_KW_...#
keywords=iskeyword();
for i=1:length(keywords)
    keyword=keywords{i};
    if strcmp(keyword,'end')
        % special handling for 'end':
        % in 'A(1:end)', it can be treated as a variable.
        % in 'for ...' 'end', it is a control flow keyword, but in this
        % case only whitespace and semicolon and nothing else may be on
        % the line.W
        if ~numel(regexp(data, '^\s*end[\s;]*$'))
            continue
        end
    end
    data = regexprep(data, ['(?<![a-zA-Z0-9_])', keyword, '(?![a-zA-Z0-9_])'], ['#MBeauty_KW_',keyword,'#'] );
end
% convert all operators like + * == etc to #MBeauty_OP_whatever# tokens
for iOpConf = 1: numel(setConfigOperatorFields)
    currField = setConfigOperatorFields{iOpConf};
    currOpStruct = settingConf.OperatorRules.(currField); 
    data = regexprep(data, ['\s*', currOpStruct.ValueFrom, '\s*'], ['#MBeauty_OP_', currField, '#'] );
end

% remove all duplicate space
data = regexprep(data, '\s+', ' ');

% find unary plus/minus, such as in (+1), but not in (1+2)
% if found, replace #MBeauty_OP_Plus# by #MBeauty_OP_UnaryPlus#
% Then convert UnaryPlus tokens to '+' signs
% (same for minus)
for iOpConf = 1: numel(setConfigOperatorFields)
    currField = setConfigOperatorFields{iOpConf};
    
    opToken = ['#MBeauty_OP_', currField, '#'];
    unaryOpToken = ['#MBeauty_OP_Unary', currField, '#'];
    
    if (strcmp(opToken, '#MBeauty_OP_Plus#') || strcmp(opToken, '#MBeauty_OP_Minus#')) && numel(regexp(data, opToken))
        
        splittedData = regexp(data, opToken, 'split');
        
        replaceTokens = {};
        for iSplit = 1:numel(splittedData)-1
           beforeItem = strtrim(splittedData{iSplit});
           if ~isempty(beforeItem) && numel(regexp(beforeItem, '([0-9a-zA-Z_)}\]\.]|#MBeutyTransp#)$'))
               % + or - is a binary operator after:
               % numbers [0-9.],
               % variable names [a-zA-Z0-9_] or
               % closing brackets )}]
               % transpose signs ', here represented as #MBeutyTransp#
               replaceTokens{end+1} = opToken;
           else
               replaceTokens{end+1} = unaryOpToken;
           end
        end
        
        replacedSplittedData = cell(1, numel(replaceTokens) + numel(splittedData));
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

% At this point the data is in a completely tokenized representation, e.g.
% 'x#MBeauty_OP_Plus#y' instead of the original 'x + y'.
% Now go backwards and replace the tokens by the real operators

data = regexprep(data, ['\s*', '#MBeauty_OP_UnaryPlus#', '\s*'], '+');
data = regexprep(data, ['\s*', '#MBeauty_OP_UnaryMinus#', '\s*'], '-');     

% replace all other operators
for iOpConf = 1: numel(setConfigOperatorFields)
    currField = setConfigOperatorFields{iOpConf};
    currOpStruct = settingConf.OperatorRules.(currField);
    data = regexprep(data, ['\s*', '#MBeauty_OP_', currField, '#', '\s*'], currOpStruct.ValueTo);
end

data = regexprep(data, ' \)', ')');
data = regexprep(data, ' \]', ']');
data = regexprep(data, '\( ', '(');
data = regexprep(data, '\[ ', '[');

% restore keywords
keywords=iskeyword();
for i=1:length(keywords)
    keyword=keywords{i};
    data = regexprep(data, ['\s*', '#MBeauty_KW_',keyword,'#', '\s*'], [' ', keyword, ' '] );
end

% fix semicolon whitespace at end of line
data = regexprep(data, '\s+;\s*$', ';');

%% Process Brackets
if str2double(settingConf.SpecialRules.AddCommasToMatricesValue)
    data = processBracket(data, settingConf);
end


end

function [array, lastUsedIndex] = arrayAppend(array, toAppend, lastUsedIndex)
cellLength = numel(array);

if cellLength <= lastUsedIndex
    error();
end

if ischar(toAppend)
    array{lastUsedIndex + 1} = toAppend;
    lastUsedIndex = lastUsedIndex + 1;
elseif iscell(toAppend)
    %% ToDo: Additional check
    
    for i = 1: numel(toAppend)
        array{lastUsedIndex + 1} = toAppend{i};
        lastUsedIndex = lastUsedIndex + 1;
    end
    
else
    error();
end


end

function data = processBracket(data, settingConf)
tokStruct = MBeautify.getTokenStruct();
arithmeticOperators = {'+','-','&','&&','|','||','/', '*'};

% [sad asd asd] => [sad, asd, asd]
% [hello, thisisfcn(a1, a2, a3) 3rd sin(12, 12)] =>[hello, thisisfcn(a1, a2, a3), 3rd, sin(12, 12)]
%% ToDo handle [sad[], gh[] []] cases
[multElBracketStrs, multElBracketBegInds, multElBracketEndInds] = regexp(data, '\[[^\]]+\]', 'match');
contTokenStruct = tokStruct('ContinueToken');
if numel(multElBracketStrs)
    
    % parts contains the input string as a cell like:
    %   - {'a = ', '[1, 2, 3]', ' + ', '[4, 5 6]', ' + ', '[6    7 8]'}
    parts = cell(1, numel(multElBracketStrs)*2 + 1);
    
    if multElBracketBegInds(1) == 1
        parts{1} = '';
    else
        parts{1} = data(1:multElBracketBegInds(1) - 1);
    end
    
    
    if multElBracketEndInds(end) == numel(data)
        parts{end} = '';
    else
        parts{end} = data(multElBracketEndInds(end) + 1:end);
    end
    
    for ind = 1:numel(multElBracketStrs) - 1
        if multElBracketBegInds(ind + 1) - multElBracketEndInds(ind) > 1
            parts{ind * 2 + 1} = data(multElBracketEndInds(ind) + 1:multElBracketBegInds(ind + 1) - 1);
        else
            parts{ind * 2 + 1} = '';
        end
    end
    
    
    for brcktInd = 1: numel(multElBracketStrs)
        str = multElBracketStrs{brcktInd};
        
        
        elementsCell = regexp(str, ' ', 'split');
        if numel(elementsCell) > 1
            isInCurlyBracket = 0;
            for elemInd = 1: numel(elementsCell) - 1
                
                currElem = elementsCell{elemInd};
                nextElem = elementsCell{elemInd+1};
                
                hasOpeningBrckt = numel(strfind(currElem, '(')) || numel(strfind(currElem, '{'));
                isInCurlyBracket = isInCurlyBracket || hasOpeningBrckt;
                hasClosingBrckt = numel(strfind(currElem, ')'))|| numel(strfind(currElem, '}'));
                isInCurlyBracket = isInCurlyBracket && ~hasClosingBrckt;
                
                currElemStripped = regexprep(currElem, '[[]{}]', '');
                nextElemStripped = regexprep(nextElem, '[[]{}]', '');
                
                if numel(currElem) && ~(strcmp(currElem(end), ',') || strcmp(currElem(end), ';')) && ~isInCurlyBracket && ...
                        ~strcmp(currElem, contTokenStruct.Token) && ...
                        ~any(strcmp(currElemStripped, arithmeticOperators)) && ~any(strcmp(nextElemStripped, arithmeticOperators))
                    elementsCell{elemInd} = [currElem, '#MBeauty_OP_Comma#'];
                else
                    elementsCell{elemInd} = [elementsCell{elemInd}, ' '];
                end
                
            end
            str = [elementsCell{:}];
            
            
            parts{brcktInd * 2} = str;
        else
            parts{brcktInd * 2} = [elementsCell{:}];
        end
        
    end
    dataNew = [parts{:}];
     dataNew = regexprep(dataNew, '#MBeauty_OP_Comma#', settingConf.OperatorRules.Comma.ValueTo  );
    data = dataNew;
end
end

