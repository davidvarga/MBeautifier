function this = MBeautyConfigurationRules()
this = struct();

this.OperatorRules = struct();


this.OperatorRules.ShortCircuitAnd = struct();
this.OperatorRules.ShortCircuitAnd.ValueFrom = '&&';
this.OperatorRules.ShortCircuitAnd.ValueTo = ' && ';

this.OperatorRules.ShortCircuitOr = struct();
this.OperatorRules.ShortCircuitOr.ValueFrom = '\|\|';
this.OperatorRules.ShortCircuitOr.ValueTo = ' \|\| ';

this.OperatorRules.LogicalAnd = struct();
this.OperatorRules.LogicalAnd.ValueFrom = '&';
this.OperatorRules.LogicalAnd.ValueTo = ' & ';

this.OperatorRules.LogicalOr = struct();
this.OperatorRules.LogicalOr.ValueFrom = '\|';
this.OperatorRules.LogicalOr.ValueTo = ' \| ';

this.OperatorRules.LessEquals = struct();
this.OperatorRules.LessEquals.ValueFrom = '<=';
this.OperatorRules.LessEquals.ValueTo = ' <= ';

this.OperatorRules.Less = struct();
this.OperatorRules.Less.ValueFrom = '<';
this.OperatorRules.Less.ValueTo = ' < ';

this.OperatorRules.GreaterEquals = struct();
this.OperatorRules.GreaterEquals.ValueFrom = '>=';
this.OperatorRules.GreaterEquals.ValueTo = ' >= ';

this.OperatorRules.Greater = struct();
this.OperatorRules.Greater.ValueFrom = '>';
this.OperatorRules.Greater.ValueTo = ' > ';

this.OperatorRules.Equals = struct();
this.OperatorRules.Equals.ValueFrom = '==';
this.OperatorRules.Equals.ValueTo = ' == ';

this.OperatorRules.NotEquals = struct();
this.OperatorRules.NotEquals.ValueFrom = '~=';
this.OperatorRules.NotEquals.ValueTo = ' ~= ';

this.OperatorRules.Assignment = struct();
this.OperatorRules.Assignment.ValueFrom = '=';
this.OperatorRules.Assignment.ValueTo = ' = ';

this.OperatorRules.Plus = struct();
this.OperatorRules.Plus.ValueFrom = '\+';
this.OperatorRules.Plus.ValueTo = ' \+ ';

this.OperatorRules.Minus = struct();
this.OperatorRules.Minus.ValueFrom = '\-';
this.OperatorRules.Minus.ValueTo = ' \- ';

this.OperatorRules.ElementWiseMultiplication = struct();
this.OperatorRules.ElementWiseMultiplication.ValueFrom = '\.\*';
this.OperatorRules.ElementWiseMultiplication.ValueTo = ' \.\* ';

this.OperatorRules.Multiplication = struct();
this.OperatorRules.Multiplication.ValueFrom = '\*';
this.OperatorRules.Multiplication.ValueTo = ' \* ';

this.OperatorRules.RightArrayDivision = struct();
this.OperatorRules.RightArrayDivision.ValueFrom = '\./';
this.OperatorRules.RightArrayDivision.ValueTo = ' \./ ';

this.OperatorRules.LeftArrayDivision = struct();
this.OperatorRules.LeftArrayDivision.ValueFrom = '\.\\';
this.OperatorRules.LeftArrayDivision.ValueTo = ' \.\\ ';

this.OperatorRules.Division = struct();
this.OperatorRules.Division.ValueFrom = '/';
this.OperatorRules.Division.ValueTo = ' / ';

this.OperatorRules.LeftDivision = struct();
this.OperatorRules.LeftDivision.ValueFrom = '\\';
this.OperatorRules.LeftDivision.ValueTo = ' \\ ';

this.OperatorRules.ElementWisePower = struct();
this.OperatorRules.ElementWisePower.ValueFrom = '\.\^';
this.OperatorRules.ElementWisePower.ValueTo = '\.\^';

this.OperatorRules.Power = struct();
this.OperatorRules.Power.ValueFrom = '\^';
this.OperatorRules.Power.ValueTo = '\^';

this.OperatorRules.Not = struct();
this.OperatorRules.Not.ValueFrom = '~';
this.OperatorRules.Not.ValueTo = ' ~';

this.OperatorRules.Comma = struct();
this.OperatorRules.Comma.ValueFrom = ',';
this.OperatorRules.Comma.ValueTo = ', ';

this.OperatorRules.SemiColon = struct();
this.OperatorRules.SemiColon.ValueFrom = ';';
this.OperatorRules.SemiColon.ValueTo = '; ';

this.OperatorRules.Colon = struct();
this.OperatorRules.Colon.ValueFrom = ':';
this.OperatorRules.Colon.ValueTo = ':';
this.SpecialRules = struct();


this.SpecialRules.MaximalNewLines = struct();
this.SpecialRules.MaximalNewLinesValue = '2';

this.SpecialRules.SectionPrecedingNewlineCount = struct();
this.SpecialRules.SectionPrecedingNewlineCountValue = '1';

this.SpecialRules.SectionTrailingNewlineCount = struct();
this.SpecialRules.SectionTrailingNewlineCountValue = '-1';

this.SpecialRules.EndingNewlineCount = struct();
this.SpecialRules.EndingNewlineCountValue = '1';

this.SpecialRules.AddCommasToMatrices = struct();
this.SpecialRules.AddCommasToMatricesValue = '1';

this.SpecialRules.AddCommasToCellArrays = struct();
this.SpecialRules.AddCommasToCellArraysValue = '1';

this.SpecialRules.CellArrayIndexing_ArithmeticOperatorPadding = struct();
this.SpecialRules.CellArrayIndexing_ArithmeticOperatorPaddingValue = '0';

this.SpecialRules.MatrixIndexing_ArithmeticOperatorPadding = struct();
this.SpecialRules.MatrixIndexing_ArithmeticOperatorPaddingValue = '0';

this.SpecialRules.AllowMultipleStatementsPerLine = struct();
this.SpecialRules.AllowMultipleStatementsPerLineValue = '0';
end