% This file should NOT change when run through MBeautify, but
% currently these examples trigger known bugs, and are therefore
% excluded from testfile.m.
% As soon as the bug is fixed, these should be moved to testfile.m.

% #34
if -1 > -2
end
if +1 > -2
end

% #35, if ArithmeticOperatorPadding=0
trace(3 + 4)
a = eye(1 + 1)

% #36
a(1, 1:2) = [3, 1]
a(3, :) = [3, 1]
b = zeros(3, 3, 3);
b(:, :, 2) = rand(2, 2);

 %if AddCommasToMatrices=1
a=[@(x) minus(x,1),]

%if AddCommasToCellArrays=1
a={@(x) minus(x,1),  @(x,y) minus(x,y)}
