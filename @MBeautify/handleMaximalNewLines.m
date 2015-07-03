function [isAcceptable, nCurrentNewlines] = handleMaximalNewLines(line, nCurrentNewlines, maximalNewLines)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

 
    
        isAcceptable = true;
   
    
        if isempty(strtrim(line))
            
            
            if ~(nCurrentNewlines < maximalNewLines)
                isAcceptable = false;
            end
            nCurrentNewlines = nCurrentNewlines + 1;
        else
            nCurrentNewlines = 0;
        end
    
end

