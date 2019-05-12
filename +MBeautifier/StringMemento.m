classdef (Abstract) StringMemento

    properties (SetAccess = immutable)
        StoredText
    end

    properties (Abstract, Dependent)
        Text
    end

    methods
        function obj = StringMemento(storedText)
            obj.StoredText = storedText;
        end
    end

end
