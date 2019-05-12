classdef OperatorPaddingRule

    properties (SetAccess = immutable)
        Key
        ValueFrom
        ValueTo
        Token
        ReplacementPattern
    end

    properties (Access = private)
        MatrixIndexingReplacementPattern
        CellArrayIndexingReplacementPattern
    end

    methods
        function obj = OperatorPaddingRule(key, valueFrom, valueTo)
            obj.Key = key;
            obj.ValueFrom = regexptranslate('escape', valueFrom);
            obj.ValueTo = regexptranslate('escape', valueTo);
            obj.Token = ['#MBeautifier_OP_', key, '#'];

            whiteSpaceToken = MBeautifier.Constants.WhiteSpaceToken;
            wsTokenLength = numel(whiteSpaceToken);

            tokenizedReplaceString = strrep(obj.ValueTo, ' ', whiteSpaceToken);
            % Calculate the starting white space count
            leadingWSNum = 0;
            matchCell = regexp(tokenizedReplaceString, ['^(', whiteSpaceToken, ')+'], 'match');
            if numel(matchCell)
                leadingWSNum = numel(matchCell{1}) / wsTokenLength;
            end

            % Calculate ending whitespace count
            endingWSNum = 0;
            matchCell = regexp(tokenizedReplaceString, ['(', whiteSpaceToken, ')+$'], 'match');
            if numel(matchCell)
                endingWSNum = numel(matchCell{1}) / wsTokenLength;
            end

            obj.ReplacementPattern = ['\s*(', whiteSpaceToken, '){0,', num2str(leadingWSNum), '}', obj.Token, ...
                '(', whiteSpaceToken, '){0,', num2str(endingWSNum), '}\s*'];

            if numel(regexp(obj.ValueFrom, '\+|\-|\/|\*'))
                obj.MatrixIndexingReplacementPattern = ['\s*(', whiteSpaceToken, '){0,0}', obj.Token, '(', whiteSpaceToken, '){0,0}\s*'];
                obj.CellArrayIndexingReplacementPattern = ['\s*(', whiteSpaceToken, '){0,0}', obj.Token, '(', whiteSpaceToken, '){0,0}\s*'];
            else
                obj.MatrixIndexingReplacementPattern = obj.ReplacementPattern;
                obj.MatrixIndexingReplacementPattern = obj.ReplacementPattern;
            end
        end

        function pattern = matrixIndexingReplacementPattern(obj, isPaddingEnabled)
            if isPaddingEnabled
                pattern = obj.ReplacementPattern;
            else
                pattern = obj.MatrixIndexingReplacementPattern;
            end
        end

        function pattern = cellArrayIndexingReplacementPattern(obj, isPaddingEnabled)
            if isPaddingEnabled
                pattern = obj.ReplacementPattern;
            else
                pattern = obj.CellArrayIndexingReplacementPattern;
            end
        end
    end
end
