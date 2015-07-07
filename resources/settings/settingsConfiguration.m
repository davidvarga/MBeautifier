function this = settingsConfiguration()
this = struct();


this.ShortCircuitAnd = struct();
this.ShortCircuitAnd.ValueFrom = '&&';
this.ShortCircuitAnd.ValueTo = ' && ';

this.ShortCircuitOr = struct();
this.ShortCircuitOr.ValueFrom = '||';
this.ShortCircuitOr.ValueTo = ' || ';

this.LogicalAnd = struct();
this.LogicalAnd.ValueFrom = '&';
this.LogicalAnd.ValueTo = ' & ';

this.LogicalOr = struct();
this.LogicalOr.ValueFrom = '|';
this.LogicalOr.ValueTo = ' | ';

this.Greater = struct();
this.Greater.ValueFrom = '>';
this.Greater.ValueTo = ' > ';

this.GreaterEquals = struct();
this.GreaterEquals.ValueFrom = '>=';
this.GreaterEquals.ValueTo = ' >= ';

this.Equals = struct();
this.Equals.ValueFrom = '==';
this.Equals.ValueTo = ' == ';

this.NotEquals = struct();
this.NotEquals.ValueFrom = '~=';
this.NotEquals.ValueTo = ' ~= ';

this.Assignment = struct();
this.Assignment.ValueFrom = '=';
this.Assignment.ValueTo = ' = ';

this.Less = struct();
this.Less.ValueFrom = '<';
this.Less.ValueTo = ' < ';

this.LessEquals = struct();
this.LessEquals.ValueFrom = '<=';
this.LessEquals.ValueTo = ' <= ';

this.Plus = struct();
this.Plus.ValueFrom = '+';
this.Plus.ValueTo = ' + ';

this.Minus = struct();
this.Minus.ValueFrom = '-';
this.Minus.ValueTo = ' - ';

this.ElementWiseMultiplication = struct();
this.ElementWiseMultiplication.ValueFrom = '.*';
this.ElementWiseMultiplication.ValueTo = ' .* ';

this.Multiplication = struct();
this.Multiplication.ValueFrom = '*';
this.Multiplication.ValueTo = ' * ';

this.RightArrayDivision = struct();
this.RightArrayDivision.ValueFrom = './';
this.RightArrayDivision.ValueTo = ' ./ ';

this.LeftArrayDivision = struct();
this.LeftArrayDivision.ValueFrom = '.\';
this.LeftArrayDivision.ValueTo = ' .\ ';

this.Division = struct();
this.Division.ValueFrom = '/';
this.Division.ValueTo = ' / ';

this.LeftDivision = struct();
this.LeftDivision.ValueFrom = '\';
this.LeftDivision.ValueTo = ' \ ';

this.ElementWisePower = struct();
this.ElementWisePower.ValueFrom = '.^';
this.ElementWisePower.ValueTo = ' .^ ';

this.Power = struct();
this.Power.ValueFrom = '^';
this.Power.ValueTo = ' ^ ';

this.Not = struct();
this.Not.ValueFrom = '~';
this.Not.ValueTo = ' ~';

this.Comma = struct();
this.Comma.ValueFrom = ',';
this.Comma.ValueTo = ', ';

this.SemiColon = struct();
this.SemiColon.ValueFrom = ';';
this.SemiColon.ValueTo = '; ';
end