function [codeToFormat, additionalInfo] = handleSource(source)

codeToFormat = '';
additionalInfo = [];

sourceType = '';

if nargin < 1
    sourceType = 'AutoDetect';
elseif any(strcmp(source, {'EditorCurrentPage', 'EditorSelection','AutoDetect' }))
    
    sourceType = source;
    
else
    if ischar(source)
        if exist(source, 'file')
            sourceType = 'File';
        else
            sourceType = 'String';
        end
    end
end


switch sourceType
    case 'AutoDetect'
        
    case 'EditorCurrentPage'
        currentEditorPage = matlab.desktop.editor.getActive();

        if isempty(currentEditorPage)
            return;
        end
        additionalInfo = currentEditorPage;
        codeToFormat = currentEditorPage.Text;

    case 'EditorSelection'
        
        currentEditorPage = matlab.desktop.editor.getActive();

        if isempty(currentEditorPage)
            return;
        end
        additionalInfo = currentEditorPage;
        codeToFormat = currentEditorPage.SelectedText;

        
%     case 'String'
%         codeToFormat = source;
%     case 'File'
%         file = source;
%         % ToDo:
%         
    otherwise
        
        % ToDo: Unknown source
        
end




end