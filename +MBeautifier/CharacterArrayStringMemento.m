classdef CharacterArrayStringMemento < MBeautifier.StringMemento

    properties (Dependent)
        Text
    end

    methods
        function obj = CharacterArrayStringMemento(storedText)
            obj@MBeautifier.StringMemento(storedText);
        end

        function value = get.Text(obj)
            value = ['''', obj.StoredText, ''''];
        end
    end

end
