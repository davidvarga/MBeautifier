% This file should NOT change when run through MBeautify
% If you find anything that is difficult or failed in some MBeautify
% version, please add it here.

% unary operator testcases

+2
+2.
+.2
'   string  with  lots  of  spaces   '
1 + 2
f(+1) + 1

x = y
x + 1. + 2
x + 1. + +.1
x + 1 + 2
x = 1
x = -1
x = +1
x = +.1
+(-[-.1])
z = [1, 2, 3, 4]

if 1 > +2
    return
end; % comment +-+-+- +++ 123 ***
if 1 > -2
end
% different meanings of 'end'
if any(z == -[-1, -2, -3, -4])
    ifmyvariablenamecontainsif = z(1:end);
end

% old-style function calls
disp +end+ this is not any keyword if else endif while +1
% bracket handling
while (1)
    a = [0, 1];
    a(1) = 2 * [a(0)];
    break
end;

% transpose
-x' + +1 + x'' + 2 * x''' * 1
a = eye(27)
a(3, 4:5) = [3, 1]

% norm notation
1.e-6
