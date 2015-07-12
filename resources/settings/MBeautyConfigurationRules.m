function this = settingsConfiguration()
this = struct();

this.OperatorRules = struct();


this.OperatorRules.ShortCircuitAnd = struct();
this.OperatorRules.ShortCircuitAnd.ValueFrom = '&amp;&amp;';
this.OperatorRules.ShortCircuitAnd.ValueTo = ' &amp;&amp; ';

this.OperatorRules.ShortCircuitOr = struct();
this.OperatorRules.ShortCircuitOr.ValueFrom = '\|\|';
this.OperatorRules.ShortCircuitOr.ValueTo = ' || ';

this.OperatorRules.LogicalAnd = struct();
this.OperatorRules.LogicalAnd.ValueFrom = '&amp;';
this.OperatorRules.LogicalAnd.ValueTo = ' &amp; ';

this.OperatorRules.LogicalOr = struct();
this.OperatorRules.LogicalOr.ValueFrom = '\|';
this.OperatorRules.LogicalOr.ValueTo = ' | ';

this.OperatorRules.LessEquals = struct();
this.OperatorRules.LessEquals.ValueFrom = '&lt;=';
this.OperatorRules.LessEquals.ValueTo = ' &lt;= ';

this.OperatorRules.Less = struct();
this.OperatorRules.Less.ValueFrom = '&lt;';
this.OperatorRules.Less.ValueTo = ' &lt; ';

this.OperatorRules.GreaterEquals = struct();
this.OperatorRules.GreaterEquals.ValueFrom = '&gt;=';
this.OperatorRules.GreaterEquals.ValueTo = ' &gt;= ';

this.OperatorRules.Greater = struct();
this.OperatorRules.Greater.ValueFrom = '&gt;';
this.OperatorRules.Greater.ValueTo = ' &gt; ';

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
this.OperatorRules.Plus.ValueTo = ' + ';

this.OperatorRules.Minus = struct();
this.OperatorRules.Minus.ValueFrom = '\-';
this.OperatorRules.Minus.ValueTo = ' - ';

this.OperatorRules.ElementWiseMultiplication = struct();
this.OperatorRules.ElementWiseMultiplication.ValueFrom = '\.\*';
this.OperatorRules.ElementWiseMultiplication.ValueTo = ' .* ';

this.OperatorRules.Multiplication = struct();
this.OperatorRules.Multiplication.ValueFrom = '\*';
this.OperatorRules.Multiplication.ValueTo = ' * ';

this.OperatorRules.RightArrayDivision = struct();
this.OperatorRules.RightArrayDivision.ValueFrom = '\./';
this.OperatorRules.RightArrayDivision.ValueTo = ' ./ ';

this.OperatorRules.LeftArrayDivision = struct();
this.OperatorRules.LeftArrayDivision.ValueFrom = '\.\\';
this.OperatorRules.LeftArrayDivision.ValueTo = ' .\ ';

this.OperatorRules.Division = struct();
this.OperatorRules.Division.ValueFrom = '/';
this.OperatorRules.Division.ValueTo = ' / ';

this.OperatorRules.LeftDivision = struct();
this.OperatorRules.LeftDivision.ValueFrom = '\\';
this.OperatorRules.LeftDivision.ValueTo = ' \ ';

this.OperatorRules.ElementWisePower = struct();
this.OperatorRules.ElementWisePower.ValueFrom = '\.\^';
this.OperatorRules.ElementWisePower.ValueTo = ' .^ ';

this.OperatorRules.Power = struct();
this.OperatorRules.Power.ValueFrom = '\^';
this.OperatorRules.Power.ValueTo = ' ^ ';

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

this.SpecialRules.AddCommasToMatrices = struct();
this.SpecialRules.AddCommasToMatricesValue = '1';
end