function retStr = strConcat( srcStr, varargin )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

retStr = srcStr;

if nargin > 1
    retStr = [retStr, varargin{:}];
else
    return; 
end


end

