function beautify(source)
%% ToDo: done
%{
    sad
%}
% => if %{ (exact match) found, skip the lines till %} (exact match)

%% ToDo:  done
% transpose and .' => When splittig by ' character: note and check what's the previous character is.
% prev char:
% . -> it's an operator
% a-zA-Z0-9 -> it's a simple transpose operator
% ' -> if the previous character was traspose, it is also transpose
%
 
%% ToDo: 
% ! => shall work as comment

%% ToDO: done
% lines with ... end => concatenate them

%% ToDo: done
% processing brackets: shall called to whole lines to make ['a' 'a' 'a'] work



h = matlab.desktop.editor.getActive();

if isempty(h)
    
    return;
end
h.smartIndentContents();

source = h.Text;
nMaximalNewLines = 2;
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
                replacedLines = strConcat(replacedLines, tempRow);
                
            end

            replacedLines = strConcat(replacedLines, actCode);

            actCodeFinal = performReplacements(replacedLines);
            
            splitToLine = regexp(actCodeFinal, contTokenStruct.Token, 'split');
            
            line = '';
            for iSplitLine = 1:numel(splitToLine) - 1
                line = strConcat(line, strtrim(splitToLine{iSplitLine}),  [' ', contTokenStruct.StoredValue, ' '], contLineArray{iSplitLine,2}, newLine);
            end
            line = strConcat(line, strtrim(splitToLine{end}),  actComment, newLine);

            [replacedTextArray, lastIndexUsed] = arrayAppend(replacedTextArray, {line, sprintf('\n')}, lastIndexUsed);

            contLineArray = cell(0,2);
            
            continue;
            
      
        end
    end
    

    actCodeFinal = performReplacements(actCode);
    line = [strtrim(actCodeFinal), ' ', actComment];
    [replacedTextArray, lastIndexUsed] = arrayAppend(replacedTextArray, {line, sprintf('\n')}, lastIndexUsed);

end

h.Text = [replacedTextArray{:}];
h.smartIndentContents();
h.makeActive();


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

function actCodeFinal = performReplacements(actCode)

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
actCodeTemp = replaces(actCodeTemp);


splitByStrTok = regexp(actCodeTemp, strTokenStruct.Token, 'split');

if numel(strTokStructs)
    actCodeFinal = '';
    for iSplit = 1:numel(strTokStructs)
        actCodeFinal = strConcat(actCodeFinal, splitByStrTok{iSplit}, '''', strTokStructs{iSplit}.StoredValue, '''');
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
            tempCode = strConcat(tempCode, nonConjTrnspTokStruct.Token);
            % tempCode = [tempCode, nonConjTrnspTokStruct.Token];
            isLastCharTransp = true;
        else
            if isLastCharTransp
                tempCode = strConcat(tempCode, trnspTokStruct.Token);
               % tempCode = [tempCode, trnspTokStruct.Token]; 
               isLastCharTransp = true;
            else
                
                if numel(tempCode) && numel(regexp(tempCode(end),charsIndicateTranspose)) && ~isInStr
                        
                    tempCode = strConcat(tempCode, trnspTokStruct.Token);
                    % tempCode = [tempCode, trnspTokStruct.Token]; 
                    isLastCharTransp = true;
                else
                    tempCode = strConcat(tempCode, actChar);
                    % tempCode = [tempCode, actChar];
                    isInStr = ~isInStr;
                    isLastCharTransp = false;
                end 
            end
        end
        
        isLastCharDot = false;
    elseif isequal(actChar,'.') && ~isInStr
        isLastCharDot = true;
        tempCode = strConcat(tempCode, actChar);
        % tempCode = [tempCode, actChar];
        isLastCharTransp = false;
    else
        isLastCharDot = false;
        tempCode = strConcat(tempCode, actChar);
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


function res = fix(val, symb)

main_arr = regexp(val, symb, 'split');
new_arr = {};
for i = 1 : numel(main_arr)
    new_arr{end + 1} = regexprep(main_arr{i}, '\s+', ' ');
    new_arr{end + 1} = [' ', symb, ' '];
    
end
res = [new_arr{1:end - 1}];

end

function data = replaces(data)


data = regexprep(data, '\s+', ' ');
data = fix(data, '+');
data = fix(data, '-');
data = fix(data, '*');
data = fix(data, '/');
data = fix(data, '\\');
data = fix(data, '=');
data = fix(data, '<');
data = fix(data, '>');
data = fix(data, '&');
data = fix(data, '|');
data = fix(data, '^');
data = fix(data, ',');
data = fix(data, ';');

data = regexprep(data, '\. \*', '.*');
data = fix(data, '\.\*');
data = regexprep(data, '\. \^', '.^');
data = fix(data, '\.\^');

data = regexprep(data, '\. \/', './');
data = fix(data, '\.\/');

data = regexprep(data, '\. \\\\', '.\\');
data = fix(data, '\.\\\\');

data = regexprep(data, '\~ \=', '~=');
data = fix(data, '~=');
data = regexprep(data, '\s+', ' ');

data = regexprep(data, '= =', '==');
data = regexprep(data, '< =', '<=');
data = regexprep(data, '> =', '>=');
data = regexprep(data, '\+ \=', '+=');
data = regexprep(data, '\- \=', '-=');
data = regexprep(data, '\& \&', '&&');
data = regexprep(data, '\| \|', '||');
data = regexprep(data, ' \, ', ', ');
data = regexprep(data, ' \; ', '; ');

data = regexprep(data, ' \)', ')');
data = regexprep(data, ' \]', ']');
data = regexprep(data, '\( ', '(');
data = regexprep(data, '\[ ', '[');


data = regexprep(data, 'if(', 'if (');
data = regexprep(data, 'while(', 'while (');

%% Process Brackets
data = processBracket(data);


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

function data = processBracket(data)
tokStruct = MBeautify.getTokenStruct();
aithmeticOpetors = {'+','-','&','&&','|','||','/', '*'};

% [sad asd asd] => [sad, asd, asd]
% [hello, thisisfcn(a1, a2, a3) 3rd sin(12, 12)] =>[hello, thisisfcn(a1, a2, a3), 3rd, sin(12, 12)]
%% ToDo handle [sad[], gh[] []] cases
[multElBracketStrs, multElBracketBegInds, multElBracketEndInds] = regexp(data, '\[[^\]]+\]', 'match');
contTokenStruct = tokStruct('ContinueToken');
if numel(multElBracketStrs)
    
    parts = cell(1, numel(multElBracketStrs) + 3);
    
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
                
                
                if numel(currElem) && ~(strcmp(currElem(end), ',') || strcmp(currElem(end), ';')) && ~isInCurlyBracket && ...
                        ~strcmp(currElem, contTokenStruct.Token) && ...
                        ~any(strcmp(currElem, aithmeticOpetors)) && ~any(strcmp(nextElem, aithmeticOpetors))
                    elementsCell{elemInd} = [currElem, ','];
                end
                elementsCell{elemInd} = [elementsCell{elemInd}, ' '];
            end
            str = [elementsCell{:}];
            
            
            parts{brcktInd * 2} = str;
        else
            parts{brcktInd * 2} = [elementsCell{:}];
        end
        
    end
    dataNew = [parts{:}];
    data = dataNew;
end
end


