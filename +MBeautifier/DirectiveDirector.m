classdef DirectiveDirector < handle

    properties (SetAccess = private)
        Directives;
    end

    methods
        function obj = DirectiveDirector()
            obj.Directives = containers.Map();
        end

        function changed = updateFromLine(obj, line)
            changed = MBeautifier.NoDirectiveChanged();

            lineTrimmed = strtrim(line);
            directiveTokens = regexp(lineTrimmed, '%\s*(?:MBeautifierDirective|MBD)\s*:\s*([a-zA-Z]+)\s*:\s*(\w+)$', 'tokens');
            if ~isempty(directiveTokens)
                directiveName = lower(strtrim(directiveTokens{1}{1}));
                directiveValue = lower(strtrim(directiveTokens{1}{2}));

                isNewDirective = false;
                if obj.Directives.isKey(directiveName)
                    directive = obj.Directives(directiveName);
                else
                    isNewDirective = true;
                    switch (directiveName)
                        case 'format'
                            directive = MBeautifier.GeneralFormattingDirective();
                        otherwise
                            warning('MBeautifier:Directive:InvalidDirective', ['The directive name "', char(directiveName), '" is not a valid directive name!']);
                            return
                    end
                end

                [success, toBeGarbadeCollected] = directive.updateFromValue(directiveValue);
                if toBeGarbadeCollected && isNewDirective
                    changed = MBeautifier.NoDirectiveChanged();
                    return
                end

                if toBeGarbadeCollected
                    obj.Directives.remove(directiveName);
                    changed = MBeautifier.DirectiveChange(MBeautifier.DirectiveChangeType.REMOVED, directiveName);
                    return;
                end

                if success
                    obj.Directives(directiveName) = directive;
                    if ~isNewDirective
                        changed = MBeautifier.DirectiveChange(MBeautifier.DirectiveChangeType.CHANGED, directive);
                    else
                        changed = MBeautifier.DirectiveChange(MBeautifier.DirectiveChangeType.ADDED, directive);
                    end
                else
                    changed = MBeautifier.NoDirectiveChanged();
                end
            end
        end
    end
end
