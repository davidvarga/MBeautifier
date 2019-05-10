classdef NoDirectiveChanged < MBeautifier.DirectiveChange
    methods
        function obj = NoDirectiveChanged()
            obj@MBeautifier.DirectiveChange(MBeautifier.DirectiveChangeType.NONE);
        end
    end
end
