classdef StringMemory < handle

    properties (SetAccess = immutable)
        Mementos;
        OriginalCodeLine;
        MemorizedCodeLine;
    end

    methods (Access = private)
        function obj = StringMemory(originalCodeLine, replacedCodeLine, mementos)
            obj.Mementos = mementos;
            obj.OriginalCodeLine = originalCodeLine;
            obj.MemorizedCodeLine = replacedCodeLine;
        end
    end

    methods (Static)
        function stringMemory = fromCodeLine(actCode)
            % Possible formats:
            % 'text'
            % ' text '' " text2 '
            % " text "
            % " text "" ' text2"

            indices = regexp(actCode, '''|"');
            mementos = {};
            strArray = cell(1, numel(indices)+1);

            if numel(indices) > 1
                stringStartedWith = '';
                currentString = '';
                isInString = false;
                lastWasEscape = false;
                for iMatch = 1:numel(indices)
                    if ~isInString
                        if iMatch == 1
                            predecingPart = actCode(1:indices(iMatch)-1);
                        else
                            predecingPart = actCode(indices(iMatch-1)+1:indices(iMatch)-1);
                        end
                        strArray{iMatch} = predecingPart;
                        isInString = true;
                        stringStartedWith = actCode(indices(iMatch));
                        continue
                    end

                    if lastWasEscape
                        currentString = [currentString, actCode(indices(iMatch))];
                        lastWasEscape = false;
                        continue
                    end

                    % String started with " and the current character is ' (or vice-versa) -> it is still aprt of the
                    % string
                    if ~strcmp(stringStartedWith, actCode(indices(iMatch)))
                        currentString = [currentString, actCode(indices(iMatch-1)+1:indices(iMatch))];
                    else
                        % String started with ' and the same character comes (or " case)

                        isEndOfString = numel(indices) == iMatch || indices(iMatch) + 1 ~= indices(iMatch+1);

                        if isEndOfString
                            currentString = [currentString, actCode(indices(iMatch-1)+1:indices(iMatch)-1)];


                            if strcmp(stringStartedWith, '''')
                                memento = MBeautifier.CharacterArrayStringMemento(currentString);
                            elseif strcmp(stringStartedWith, '"')
                                memento = MBeautifier.StringArrayStringMemento(currentString);
                            else
                                error('MBeautifier:InternalError', 'Unknown problem happened while processing strings.')
                            end
                            mementos{end+1} = memento;

                            strArray{iMatch} = MBeautifier.Constants.StringToken;
                            isInString = false;
                            currentString = '';
                        else
                            currentString = [currentString, actCode(indices(iMatch-1)+1:indices(iMatch))];
                            lastWasEscape = true;
                        end
                    end
                end

                % Append the trailing part if any
                if indices(end) < numel(actCode)
                    strArray{end} = actCode(indices(end)+1:end);
                end

                actCodeTemp = [strArray{:}];
            else
                actCodeTemp = actCode;
            end

            stringMemory = MBeautifier.StringMemory(actCode, actCodeTemp, mementos);
        end
    end

end
