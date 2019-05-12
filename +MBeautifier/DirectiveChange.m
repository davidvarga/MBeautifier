classdef DirectiveChange < handle
    properties (SetAccess = immutable)
        DirectiveName;
        Directive;
        Type;
    end

    methods
        function obj = DirectiveChange(type, varargin)
            obj.Type = type;
            if nargin < 2 && ~isequal(type, MBeautifier.DirectiveChangeType.NONE)
                error('MBeaturifier:Directive:InvalidChange', 'Any changes must include the directive name or the directive itself!');
            end

            if nargin == 1
                directiveNameOrDirective = '';
            else
                directiveNameOrDirective = varargin{1};
            end

            if isa(directiveNameOrDirective, 'MBeautifier.Directive')
                obj.DirectiveName = directiveNameOrDirective.Name;
                obj.Directive = directiveNameOrDirective;
            else
                obj.DirectiveName = directiveNameOrDirective;
                obj.Directive = [];
            end
        end
    end

end
