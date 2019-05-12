classdef Configuration < handle

    properties (Access = private)
        OperatorPaddingRules;
        OperatorPaddingRuleNamesInOrder;
        KeywordPaddingRules;
        SpecialRules;
    end

    methods (Access = private)
        function obj = Configuration(operatorPaddingRules, operatorPaddingRuleNamesInOrder, keywordRules, specialRules)
            obj.OperatorPaddingRules = operatorPaddingRules;
            obj.SpecialRules = specialRules;
            obj.KeywordPaddingRules = keywordRules;
            obj.OperatorPaddingRuleNamesInOrder = operatorPaddingRuleNamesInOrder;
        end
    end

    methods

        function rule = specialRule(obj, name)
            rule = obj.SpecialRules(lower(name));
        end

        function rules = specialRules(obj)
            rules = obj.SpecialRules.values;
        end

        function rule = operatorPaddingRule(obj, name)
            rule = obj.OperatorPaddingRules(lower(name));
        end

        function rule = keywordPaddingRule(obj, name)
            rule = obj.KeywordPaddingRules(lower(name));
        end

        function rules = keywordPaddingRules(obj)
            rules = obj.KeywordPaddingRules.values;
        end

        function names = operatorPaddingRuleNames(obj)
            keys = obj.OperatorPaddingRuleNamesInOrder;
            names = cell(1, numel(keys));
            for i = 1:numel(keys)
                names{i} = obj.operatorPaddingRule(keys{i}).Key;
            end
        end

        function characters = operatorCharacters(obj)
            keys = obj.OperatorPaddingRules.keys();
            characters = cell(1, numel(keys));
            for i = 1:numel(keys)
                characters{i} = obj.operatorPaddingRule(keys{i}).ValueFrom;
            end
        end
    end

    methods (Static)
        function obj = fromFile(xmlFile)
            obj = MBeautifier.Configuration.Configuration.readSettingsXML(xmlFile);
        end
    end

    methods (Static, Access = private)
        function configuration = readSettingsXML(xmlFile)
            XMLDoc = xmlread(xmlFile);

            allOperatorItems = XMLDoc.getElementsByTagName('OperatorPaddingRule');
            operatorRules = containers.Map();
            operatorCount = allOperatorItems.getLength();
            operatorPaddingRuleNamesInOrder = cell(1, operatorCount);

            for iOperator = 0:operatorCount - 1
                currentOperator = allOperatorItems.item(iOperator);
                key = char(currentOperator.getElementsByTagName('Key').item(0).getTextContent().toString());
                from = removeXMLEscaping(char(currentOperator.getElementsByTagName('ValueFrom').item(0).getTextContent().toString()));
                to = removeXMLEscaping(char(currentOperator.getElementsByTagName('ValueTo').item(0).getTextContent().toString()));

                operatorPaddingRuleNamesInOrder{iOperator+1} = lower(key);
                operatorRules(lower(key)) = MBeautifier.Configuration.OperatorPaddingRule(key, from, to);
            end

            allSpecialItems = XMLDoc.getElementsByTagName('SpecialRule');
            specialRules = containers.Map();

            for iSpecRule = 0:allSpecialItems.getLength() - 1
                currentRule = allSpecialItems.item(iSpecRule);
                key = char(currentRule.getElementsByTagName('Key').item(0).getTextContent().toString());
                value = char(currentRule.getElementsByTagName('Value').item(0).getTextContent().toString());

                specialRules(lower(key)) = MBeautifier.Configuration.SpecialRule(key, value);
            end

            allKeywordItems = XMLDoc.getElementsByTagName('KeyworPaddingRule');
            keywordRules = containers.Map();

            for iKeywordRule = 0:allKeywordItems.getLength() - 1
                currentRule = allKeywordItems.item(iKeywordRule);
                keyword = char(currentRule.getElementsByTagName('Keyword').item(0).getTextContent().toString());
                rightPadding = str2double(char(currentRule.getElementsByTagName('RightPadding').item(0).getTextContent().toString()));

                keywordRules(lower(keyword)) = MBeautifier.Configuration.KeywordPaddingRule(keyword, rightPadding);
            end

            configuration = MBeautifier.Configuration.Configuration(operatorRules, operatorPaddingRuleNamesInOrder, keywordRules, specialRules);

            function escapedValue = removeXMLEscaping(value)
                escapedValue = regexprep(value, '&lt;', '<');
                escapedValue = regexprep(escapedValue, '&amp;', '&');
                escapedValue = regexprep(escapedValue, '&gt;', '>');
            end
        end
    end
end
