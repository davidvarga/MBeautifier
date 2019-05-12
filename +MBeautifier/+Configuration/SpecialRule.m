classdef SpecialRule

    properties (SetAccess = immutable)
        Key
        Value
    end

    properties (Dependent)
        ValueAsDouble
    end

    methods
        function obj = SpecialRule(key, value)
            obj.Key = key;
            obj.Value = value;
        end

        function value = get.ValueAsDouble(obj)
            value = str2double(obj.Value);
        end
    end

end
