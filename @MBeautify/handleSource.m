function [isSourceAvailable, codeBefore, codeToFormat, codeAfter, selectedPosition, additionalInfo] = handleSource(source)

codeToFormat = '';
additionalInfo = [];
isSourceAvailable = true;
selectedPosition = '';
sourceType = '';

if nargin < 1
    sourceType = 'AutoDetect';
elseif any(strcmp(source, {'EditorCurrentPage', 'EditorSelection', 'AutoDetect' }))
    
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
        codeBefore = '';
        codeAfter = '';
        
        
        currentEditorPage = matlab.desktop.editor.getActive();
        if isempty(currentEditorPage)
            isSourceAvailable = false;
            return;
        end
        selectedPosition = currentEditorPage.Selection;
        
       
        additionalInfo = currentEditorPage;
        codeToFormat = currentEditorPage.Text;
        
    case 'EditorSelection'
        
        currentEditorPage = matlab.desktop.editor.getActive();
        
        if isempty(currentEditorPage)
            codeToFormat = '';
            additionalInfo = [];
            isSourceAvailable = false;
            return;
        end
        
        currentSelection = currentEditorPage.Selection;
        
        selectedText = currentEditorPage.SelectedText;
        
        if isempty(selectedText)
            return;
        end
        
        % Expand the selection from the beginnig of the first line to the end of the last line
        expandedSelection = [currentSelection(1), 1, currentSelection(3), Inf];
        
        
        if currentSelection(1) > 1
            lineBeforePosition = [currentSelection(1) - 1, 1, currentSelection(1) - 1, Inf];
            
            currentEditorPage.Selection = lineBeforePosition;
            lineBeforeText = currentEditorPage.SelectedText;
            
            while lineBeforePosition(1) > 1 && ~isempty(strtrim(lineBeforeText))
                lineBeforePosition = [lineBeforePosition(1) - 1, 1, lineBeforePosition(1) - 1, Inf];
                currentEditorPage.Selection = lineBeforePosition;
                lineBeforeText = currentEditorPage.SelectedText;
            end
        end
        expandedSelection = [lineBeforePosition(1), 1, expandedSelection(3), Inf];
        
        
        lineAfterSelection = [currentSelection(3) + 1, 1, currentSelection(3) + 1, Inf];
        currentEditorPage.Selection = lineAfterSelection;
        lineAfterText = currentEditorPage.SelectedText;
        beforeselect = currentSelection(1);
        while ~isequal(lineAfterSelection(1), beforeselect) && ~isempty(strtrim(lineAfterText))
            beforeselect = lineAfterSelection(1);
            lineAfterSelection = [lineAfterSelection(1) + 1, 1, lineAfterSelection(1) + 1, Inf];
            currentEditorPage.Selection = lineAfterSelection;
            lineAfterText = currentEditorPage.SelectedText;
            
        end
        
        endReached = isequal(lineAfterSelection(1), currentSelection(1));
        
        expandedSelection = [expandedSelection(1), 1, lineAfterSelection(3), Inf];
        
        if isequal(currentSelection(1), 1)
            codeBefore = '';
        else
            codeBeforeSelection = [1, 1, expandedSelection(1), Inf];
            currentEditorPage.Selection = codeBeforeSelection;
            codeBefore = currentEditorPage.SelectedText;
        end
        
        if endReached
            codeAfter = '';
        else
            codeAfterSelection = [expandedSelection(3) + 1, 1, Inf, Inf];
            currentEditorPage.Selection = codeAfterSelection;
            codeAfter = currentEditorPage.SelectedText;
            
        end
        
        currentEditorPage.Selection = expandedSelection;
        codeToFormat = currentEditorPage.SelectedText;
        additionalInfo = currentEditorPage;
        selectedPosition = currentEditorPage.Selection;
        
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
