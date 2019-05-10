classdef Constants
    properties(Constant)
        WhiteSpaceToken = '#MBeauty_WhiteSpace_Token#';
        ContainerOpeningBrackets = {'[', '{', '('};
        ContainerClosingBrackets = {']', '}', ')'};
       
    end
    
    methods(Access = private)
        function obj = Constants()
        end
    end
 
    
end

