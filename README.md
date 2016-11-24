# MBeautifier

MBeautifier is a lightweight M-Script based Matlab source code formatter usable directly in the Matlab Editor.

![Basic working](https://cloud.githubusercontent.com/assets/12681120/20592407/904cb1d6-b22d-11e6-93dd-1637c3738e50.png)


Main features
-------------

 - Padding operators with white spaces based on the configuration.
 - Fixing white space padding of keywords
 - Correction of indentation using the Smart Indent functionality of the Matlab Editor
 - Removal of continuous empty lines (the number can be configured)
 - Optionally inserting missing element separators (commas) in matrix and cell array declarations
 - Different working modes: format the current page of the Matlab editor, format only a selection in the Matlab Editor or format files

Deployment and Configuration
----------------------------
Add containing directory to the Matlab path, then execute: `MBeautify.setup()`.

This command will create the standard configuration of formatting stored in `MBeautifier\resources\settings\MBeautyConfigurationRules.m`.

This file is used in run-time to gather the configuration rules, therefore when the configuration has been modified, executing this function again will make the rules active.

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
	
The above example shows the rules for the "not equals" operator. The `ValueFrom` node stores the operator `~=` and the `ValueTo` node stores the expected formatting: the operator should be preceded and followed by a white-space character.

All of the operator padding rules are collected dynamically, therefore adding a new node to this list then executing the `setup` command will result in that MBeautifier will replace the currently added node also.

#### Special rules

These rules are basically switches for certain functionalities of MBeautifier.

The current list of special rules:

 - **MaximalNewLines**: Integer value. MBeautifier will remove continuous empty lines. This rule can be used to specify the maximal number of maximal continuous empty lines.
 - **AddCommasToMatrices**: [1|0]. Indicates whether the missing element separator commas in matrices should be inserted. For example: `[1 2 3]` will be formatted as `[1, 2, 3]`.
 - **AddCommasToCellArrays**: [1|0]. Indicates whether the missing element separator commas in cell arrays should be inserted. For example: `{1 2 3}` will be formatted as `{1, 2, 3}`.
 - **MatrixIndexing_ArithmeticOperatorPadding**: [1|0]. Indicates whether the arithmetic operators should be padded by white spaces (using the operator padding rules), when they are used to index matrices. For example: `matrix(end+1) = 1` can be formatted as `matrix(end+1) = 1` when value is set to 0, or as `matrix(end + 1) = 1` if value is set to 1.
 - **CellArrayIndexing_ArithmeticOperatorPadding**: [1|0]. Indicates the same as `MatrixIndexing_ArithmeticOperatorPadding` but for cell arrays.


Usage
-----

Currently there are three approaches supported:

 - Perform formatting on the currently active page of Matlab Editor. Command: `MBeautify.formatCurrentEditorPage()`. By default the file is not saved, but it remains opened modified in the editor. Optionally the formatted file can be saved using the `MBeautify.formatCurrentEditorPage(true)` syntax.
 - Perform formatting on the currently selected text of the active page of Matlab Editor. Command: `MBeautify.formatEditorSelection()`. An optional saving mechanism as above exists also in this case. Useful in case of large files, but in any case `MBeautify.formatCurrentEditorPage()` is suggested.
 - Perfrom formatting on a file. Command: `MBeautify.formatFile(file)`. Can be used with (1)one argument: the input file is formatted and remains open in the Matlab editor unsaved; (2)two arguments as `MBeautify.formatFile(file, outFile)`: the formatted file is saved to the specified output file if possible. Output can be the same as input. 
 
 Supported Matlab versions
 -------------------------
 
 As MBeautifier uses the built-in Matlab Editor functionality, it supports Matlab versions from R2011a.
 
