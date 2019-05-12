classdef GeneralFormattingDirective < MBeautifier.Directive

    properties (SetAccess = immutable)
        Name = 'Format'
    end

    methods (Access = protected)
        function [success, toBeGarbadeCollected] = tryToupdateFromValue(obj, value)
            success = true;
            toBeGarbadeCollected = false;
            if strcmpi(value, 'on')
                obj.Values = {};
                toBeGarbadeCollected = true;
            elseif strcmpi(value, 'off')
                obj.Values = {'off'};
            else
                toBeGarbadeCollected = ~numel(obj.Values);
                success = false;
            end
        end
    end
end
