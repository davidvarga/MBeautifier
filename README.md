# MBeautifier

MBeautifier is a lightweight M-Script based Matlab source code formatter usable directly in the Matlab Editor.

![Basic working](https://cloud.githubusercontent.com/assets/12681120/20592407/904cb1d6-b22d-11e6-93dd-1637c3738e50.png)


Main features
-------------

 - Padding operators with white spaces based on the XML configuration file.
 - Correction white space padding of keywords
 - Correction of indentation using the Smart Indent functionality of the Matlab Editor
 - Removal of continuous empty lines (the number can be configured)
 - Optionally inserting missing element separators (commas) in matrix and cell array initializations
 - Different working modes: format the current page of the Matlab editor, format only a selection in the Matlab Editor or format file(s) 

Deployment and Configuration
----------------------------
Add containing directory to the Matlab path, then execute: `MBeautify.setup()`.

This command will create the standard configuration of formatting stored in `MBeautifier\resources\settings\MBeautyConfigurationRules.m`.

This file is used in run-time to gather the configuration rules, therefore when the configuration XML file has been modified, executing this function again will make the rules active.

### Configuration

The configuration can be modified by editing the `MBeautifier\resources\settings\MBeautyConfigurationRules.xml` file.

#### Configuration rules

Currently two types of configuration rules are implemented: `OperatorPaddingRule` and `SpecialRule`.

#### Operator padding rules

Each `OperatorPaddingRule` represents the formatting rules for one single operator and consists of a key, the string that should be replaced and a string that should be used for the replacement.

    <OperatorPaddingRule>
        <Key>NotEquals</Key>
        <ValueFrom>~=</ValueFrom>
        <ValueTo> ~= </ValueTo>
    </OperatorPaddingRule>
	
The example above shows the rule for the "not equals" operator. The `ValueFrom` node stores the operator `~=` and the `ValueTo` node stores the expected format: the operator should be preceded and followed by a white-space character.

All of the operator padding rules are collected dynamically, therefore adding a new node to this list then executing the `setup` command will result in that MBeautifier will replace the currently added node also.

#### Special rules

These rules are basically switches for certain functionalities of MBeautifier.

The current list of special rules:

 - **MaximalNewLines**: Integer value. MBeautifier will remove continuous empty lines. This rule can be used to specify the maximal number of maximal continuous empty lines.
 - **SectionPrecedingNewlineCount**: Integer value. Defines how many empty lines should precede the section comments (`%% `). Negative values mean no special formatting is needed (the final format is defined by the input and the MaximalNewLines rule). For any number "X" bigger or equal to zero: section comments will be preceded exactly by X empty lines.
 - **SectionTrailingNewlineCount**: Integer value. Defines how many empty lines should follow the section comments (`%% `). Negative values mean no special formatting is needed (the final format is defined by the input and the MaximalNewLines rule). For any number "X" bigger or equal to zero: section comments will be followed exactly by X empty lines.
 - **EndingNewlineCount**: Integer value. Defines how many empty lines should be placed on the end of the input. Negative values mean no special formatting is needed (the final format is defined by the input and the MaximalNewLines rule). For any number "X" bigger or equal to zero: input will trailed exactly by X empty lines.
 - **AllowMultipleStatementsPerLine**: [1|0]. If set to 1, MBeautifier will allow multiple statements per line (`a = 1; b = 2;`), otherwise it will break every statement into a new line. Defaults to "0".
 - **AddCommasToMatrices**: [1|0]. Indicates whether the missing element separator commas in matrices should be inserted. For example: `[1 2 3]` will be formatted as `[1, 2, 3]`.
 - **AddCommasToCellArrays**: [1|0]. Indicates whether the missing element separator commas in cell arrays should be inserted. For example: `{1 2 3}` will be formatted as `{1, 2, 3}`.
 - **MatrixIndexing_ArithmeticOperatorPadding**: [1|0]. Indicates whether the arithmetic operators should be padded by white spaces (using the operator padding rules), when they are used to index matrices. For example: `matrix(end+1) = 1` can be formatted as `matrix(end+1) = 1` when value is set to 0, or as `matrix(end + 1) = 1` if value is set to 1.
 - **CellArrayIndexing_ArithmeticOperatorPadding**: [1|0]. Indicates the same as `MatrixIndexing_ArithmeticOperatorPadding` but for cell arrays.


Usage
-----

### From Matlab Command Window

Currently four approaches are supported:

 - Perform formatting on the currently active page of Matlab Editor. Command: `MBeautify.formatCurrentEditorPage()`. By default the file is not saved, but it remains opened modified in the editor. Optionally the formatted file can be saved using the `MBeautify.formatCurrentEditorPage(true)` syntax.
 - Perform formatting on the currently selected text of the active page of Matlab Editor. Command: `MBeautify.formatEditorSelection()`. An optional saving mechanism as above exists also in this case. Useful in case of large files, but in any case `MBeautify.formatCurrentEditorPage()` is suggested.
 - Perform formatting on a file. Command: `MBeautify.formatFile(file)`. Can be used with (1)one argument: the input file is formatted and remains open in the Matlab editor unsaved; (2)two arguments as `MBeautify.formatFile(file, outFile)`: the formatted file is saved to the specified output file if possible. Output can be the same as input.
 - Perform formatting on several files in a directory. Command: `MBeautify.formatFiles(directory, fileFilter)`. The first argument is an absolute path to a directory, the second one is a wildcard expression (used for `dir` command) to filter files in the target directory. The files will be formatted in-place (overwritten). 
 
### Shortcuts
 
 There is a possibility to create shortcuts for the first three approaches above, which shortcut buttons will appear under the "Shortcuts" tab of Matlab's main window.
 
 To create these buttons, the following commands can be used:
 
  - `MBeautify.createShortcut('editorpage')`: Creates a shortcut for `MBeautify.formatCurrentEditorPage()`  
  - `MBeautify.createShortcut('editorselection')`: Creates a shortcut for `MBeautify.formatEditorSelection()`
  - `MBeautify.createShortcut('file')`: Creates a shortcut for `MBeautify.formatFile(sourceFile, destFile)`
  
 These shortcuts will add the MBeautifier root directory to the Matlab path too, therefore no Matlab path preparation is needed to use MBeauty next time when a new Matlab instance is opened.
 
 Supported Matlab versions
 -------------------------
 
 As MBeautifier uses the built-in Matlab Editor functionality, it supports Matlab versions from R2011a.
 
 Planned future versions
 -----------------------
 
 As Matlab does not contain any formatter even in R2017 releases, and will not contain in R2018 releases this project will be at least maintained until R2019a (if live editor will contain a formatter).
 
 As it is planned at the moment, the current release is the last one which is M-Script based, and the next release is planned to be implemented in Java with Matlab interface. This is the first step to make MBeautifier also usable in Octave.
 
