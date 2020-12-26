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

% #36
a(1, 1:2) = [3, 1]
a(3, :) = [3, 1]
b = zeros(3, 3, 3);
b(:, :, 2) = rand(2, 2);

 %if AddCommasToMatrices=1
a=[@(x) minus(x,1),]

%if AddCommasToCellArrays=1
a={@(x) minus(x,1),  @(x,y) minus(x,y)}

% #34
if -1 > -2
end
if +1 > -2
end

% #59
a = [1, 2, 3];
a = [1, a...
.* 2]

% #58
a = [1, a ... % 111
    .* 2, ... % 222
    123, 4- ...
    5] % 333

a = {'', ... % hello
    1, 4+ ... %hello2
     2} % hello3

if true || ... % aaa
        true || ... asd
        false % //
end

%80
a + sprintf("%d", b)%comment
a + sprintf("'%d'", b) %comment
a + sprintf("""%d""", b) % comment
a + sprintf('"%d"', b)
a.' + sprintf('''%d''', b)
a' + sprintf('%d', b)

% Remove extra space after @
f = @ (x) a
% Remove extra space before unary operator
f = @(x) - a
num@MySuper(obj) - a
% remove spaces around @
num @ MySuper(obj) - a

% if AddCommasToMatrices=1
% add comma after b
[a, - b c + d]
% add comma before b
[a -b]
% one comma added after b
[a *b (c -d)]

% treat whitespace as delimiter regardless of AddCommasToMatrices
[1 (2) {3}]
% same for cells
{1 (2) {3}}