classdef MBeautyShortcuts
    % Creates and executes MBeautifier related Matlab shortcuts.
    
    properties(Access = private, Constant)
        ShorcutModes = {'editorpage', 'editorselection', 'file'};
    end
    
    methods(Static)
        
        function createShortcut(mode)
            % Creates a shortcut with the selected mode: 'editorpage', 'editorselection', 'file'
            %   'editorpage' - Execute MBeauty.formatCurrentEditorPage
            %   'editorselection' - Execute MBeauty.formatEditorSelection
            %   'file' - Execute MBeauty.formatFile
            
            mode = MBeautyShortcuts.checkMode(mode);
            
            if ~verLessThan('matlab', '8.0')
                category = 'MBeautifier';
            else
                category = 'Toolbar Shortcuts';
            end
            
            shortCutStruct = MBeautyShortcuts.getShortcutCategoryStructure(mode);
            
            shortcutUtils = com.mathworks.mlwidgets.shortcuts.ShortcutUtils();
            
            try
                shortcutUtils.removeShortcut(category, shortCutStruct.Name);
            catch %#ok<CTCH>
                % This command only fails on R2012b
            end
            shortcutUtils.addShortcutToBottom(shortCutStruct.Name, shortCutStruct.Callback, '', category, 'true');
            
        end
        
        function executeCallback(mode)
            mode = MBeautyShortcuts.checkMode(mode);
            if strcmp(mode, 'editorpage')
                MBeautyShortcuts.editorPageShortcutCallback();
            elseif strcmp(mode, 'editorselection')
                MBeautyShortcuts.editorSelectionShortcutCallback();
            elseif strcmp(mode, 'file')
                MBeautyShortcuts.fileShortcutCallback();
            end
        end
    end
    
    methods(Static, Access = private)
        
        function structure = getShortcutCategoryStructure(mode)
            mode = MBeautyShortcuts.checkMode(mode);
            
            if strcmp(mode, 'editorpage')
                structure = MBeautyShortcuts.getEditorPageShortcut();
            elseif strcmp(mode, 'editorselection')
                structure = MBeautyShortcuts.getEditorSelectionShortcut();
            elseif strcmp(mode, 'file')
                structure = MBeautyShortcuts.getFileShortcut();
            end
            
            pathToAdd = eval('fileparts(mfilename(''fullpath''))');
            addPathCommand = ['addpath(''', pathToAdd, ''');'];
            structure.Callback = [addPathCommand, structure.Callback];
            
        end
        
        function mode = checkMode(mode)
            
            mode = lower(strtrim(mode));
            if ~any(strcmp(mode, MBeautyShortcuts.ShorcutModes))
                error('MBeautifier:InvalidShortcutMode', 'Unavailable shortcut mode defined!');
            end
        end
        
        function structure = getEditorPageShortcut()
            structure = struct();
            structure.Name = 'MBeauty: Format Editor Page';
            structure.Callback = MBeautyShortcuts.editorPageShortcutCallback();
        end
        
        function command = editorPageShortcutCallback()
            command = 'MBeautify.formatCurrentEditorPage();';
        end
        
        
        function structure = getEditorSelectionShortcut()
            structure = struct();
            structure.Name = 'MBeauty: Format Editor Selection';
            structure.Callback = MBeautyShortcuts.editorSelectionShortcutCallback();
        end
        
        function command = editorSelectionShortcutCallback()
            
            command = 'MBeautify.formatEditorSelection();';
        end
        
        function structure = getFileShortcut()
            structure = struct();
            structure.Name = 'MBeauty: Format File';
            structure.Callback = MBeautyShortcuts.fileShortcutCallback();
        end
        
        function command = fileShortcutCallback()
            command = ['[sourceFile, sourcePath] = uigetfile(); drawnow(); sourceFile = fullfile(sourcePath, sourceFile);', ...
                'if isempty(sourceFile), return; end', sprintf('\n'), ...
                '[destFile, destPath] = uiputfile(); drawnow(); destFile = fullfile(destPath, destFile);', ...
                'if isempty(destFile), return; end', sprintf('\n'), ...
                'MBeautify.formatFile(sourceFile, destFile);'];
        end
    end
    
end

