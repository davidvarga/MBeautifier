classdef StringArrayStringMemento < MBeautifier.StringMemento

    properties (Dependent)
        Text
    end

    methods
        function obj = StringArrayStringMemento(storedText)
            obj@MBeautifier.StringMemento(storedText);
        end

        function value = get.Text(obj)
            value = ['"', obj.StoredText, '"'];
        end
    end

end
