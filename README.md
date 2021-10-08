# MBeautifier

MBeautifier is a lightweight M-Script based MATLAB source code formatter usable directly in the MATLAB Editor.

![Basic working](https://cloud.githubusercontent.com/assets/12681120/20592407/904cb1d6-b22d-11e6-93dd-1637c3738e50.png)


Main features
-------------
 - Padding operators and keywords with white spaces
 - Configurable indentation character and level. Indentation using the Smart Indent functionality of the MATLAB Editor
 - Removal/addition of continuous empty lines
 - Inserting missing element separators (commas) in matrix and cell array initializations
 - Insert missing continuous symbol line in matrix and cell array initializations
 - In-lining continuous lines 
 - Formats the current page of the MATLAB Editor or only a selection in the MATLAB Editor or file(s) 
 - While everything above is configurable in a single XML file

Deployment and Configuration
----------------------------
Simply add the root directory to the MATLAB path.

### Configuration

The configuration can be modified by editing the `MBeautifier\resources\settings\MBeautyConfigurationRules.xml` file.

#### Configuration rules

Currently three types of configuration rules are implemented: `Operator padding rule`, `Keyword padding rule` and `Special rule`.

#### Operator padding rules

Each `OperatorPaddingRule` represents the formatting rules for one single operator and consists of a key, the string that should be replaced and a string that should be used for the replacement.

    <OperatorPaddingRule>
        <Key>NotEquals</Key>
        <ValueFrom>~=</ValueFrom>
        <ValueTo> ~= </ValueTo>
    </OperatorPaddingRule>
	
The example above shows the rule for the "not equals" operator. The `ValueFrom` node stores the operator `~=` and the `ValueTo` node stores the expected format: the operator should be preceded and followed by a white-space character.

#### Keyword padding rules

Each `KeyworPaddingRule` represents the formatting rules for one single keyword and consists the keyword itself, and a numeric value of the needed white-space padding on the right side.

	<KeyworPaddingRule>
		<Keyword>properties</Keyword>
		<RightPadding>1</RightPadding>
	</KeyworPaddingRule>
	
The example above shows the rule for the keyword "properties". The `RightPadding` node stores the expected right padding white space amount: the keyword should be preceded by one white space character.

> Note: Not all of the keywords are listed - only the ones where controlling padding makes sense.

#### Special rules

These rules are basically switches for certain functionalities of MBeautifier.

The current list of special rules:

##### Special rules regarding new lines
 - **MaximalNewLines**: Integer value. MBeautifier will remove continuous empty lines. This rule can be used to specify the maximal number of maximal continuous empty lines.
 - **SectionPrecedingNewlineCount**: Integer value. Defines how many empty lines should precede the section comments (`%% `). Negative values mean no special formatting is needed (the final format is defined by the input and the MaximalNewLines rule). For any number "X" bigger or equal to zero: section comments will be preceded exactly by X empty lines.
 - **SectionTrailingNewlineCount**: Integer value. Defines how many empty lines should follow the section comments (`%% `). Negative values mean no special formatting is needed (the final format is defined by the input and the MaximalNewLines rule). For any number "X" bigger or equal to zero: section comments will be followed exactly by X empty lines.
 - **EndingNewlineCount**: Integer value. Defines how many empty lines should be placed on the end of the input. Negative values mean no special formatting is needed (the final format is defined by the input and the MaximalNewLines rule). For any number "X" bigger or equal to zero: input will trailed exactly by X empty lines.
 - **AllowMultipleStatementsPerLine**: [1|0]. If set to 1, MBeautifier will allow multiple statements per line (`a = 1; b = 2;`), otherwise it will break every statement into a new line. Defaults to "0".
 
##### Special rules regarding matrix and cell array separators
 
 - **AddCommasToMatrices**: [1|0]. Indicates whether the missing element separator commas in matrices should be inserted. For example: `[1 2 3]` will be formatted as `[1, 2, 3]`.
 - **AddCommasToCellArrays**: [1|0]. Indicates whether the missing element separator commas in cell arrays should be inserted. For example: `{1 2 3}` will be formatted as `{1, 2, 3}`.
 
##### Special rules arithmetic operators 

 - **MatrixIndexing_ArithmeticOperatorPadding**: [1|0]. Indicates whether the arithmetic operators should be padded by white spaces (using the operator padding rules), when they are used to index matrices. For example: `matrix(end+1) = 1` can be formatted as `matrix(end+1) = 1` when value is set to 0, or as `matrix(end + 1) = 1` if value is set to 1.
 - **CellArrayIndexing_ArithmeticOperatorPadding**: [1|0]. Indicates the same as `MatrixIndexing_ArithmeticOperatorPadding` but for cell arrays.
 
##### Special rules regarding continous lines

 - **InlineContinousLines**: [1|0]. If set to 1, MBeautifier will in-line continuous line operators ("...") everywhere except in matrices (inside [] brackets) and in curly brackets ({}) - these cases are handled by the next two options. In-lining means: the "..." operator will be removed and the next line will be copied into its place.
 - **InlineContinousLinesInMatrixes**: [1|0]. Same as **InlineContinousLines**, but only has effect inside brackets ("[]").
 - **InlineContinousLinesInCurlyBracket**: [1|0]. Same as **InlineContinousLines**, but only has effect inside curly brackets ("{}").
 
##### Special rules regarding indentation

 - **IndentationCharacter**: [white-space|tab]. Specifies which character should be used for auto-indentation: white space or tabulator. Defaults to "white-space".
 - **IndentationCount**: Integer value. Specifies the level of auto-indentation (how many **IndentationCharacter** means one level of indentation). Defaults to "4".
 - **Indentation_TrimBlankLines**: [1|0]. Specifies if blank lines (lines containing only white space characters - as result of auto-indentation) should be trimmed (made empty) by MBeautifier. Defaults to "1" as it can lead to smaller file sizes.
 - **Indentation_Strategy**: ['AllFunctions'|'NestedFunctions'|'NoIndent']. Controls the "Function indenting format" preference of the MATLAB editor used by MBeautifier: changes the indentation level of the functions' body. Possible values: "AllFunctions" - indent the body of each function, "NestedFunctions" - indent the body of nested functions only, "NoIndent" - all of the functions' body will be indented the same amount as the function keyword itself.
  
#### Directives

MBeautifier directives are special constructs which can be used in the source code to control MBeautifier during the formatting process. The example below controls the directive named `Format` and sets its value to `on` and then later to `off`.

    a =  1;
    % MBeautifierDirective:Format:Off
    longVariableName = 'where the assigement is';
    aligned          = 'with the next assignment';
    % MBD:Format:On
    someMatrix  =  [1 2 3];
    
The standard format of a directive line is:
 - following the pattern: `<ws>%<ws>MBeautifierDirective<ws>:<ws>:NAME<ws>:<ws>VALUE<ws>[NEWLINE]` or : `<ws>%<ws>MBD<ws>:<ws>:NAME<ws>:<ws>VALUE<ws>[NEWLINE]`where
    -   `<ws>` means zero or more optional white space characters
    -   `NAME` means the directive name (only latin letters, case insensitive)
    -   `VALUE` means the directive value (only latin letters, case insensitive)
 - must not contain any code or any trailing comment  (only the directive comment above)
 - must not be inside a block comment
 - must not be inside any line continousment
 - the keyword `MBeautifierDirective` is freely interchangable with `MBD`

> **Note: Directive names which are not present in the list below, or directive values which are not applicable to the specified directive will be ignored together with a MATLAB warning**.

##### Directive List

###### `Format`
Directive to generally control the formatting process.
Possible values:
- `on` - Enable formatting
- `off` - Disable formatting

Example:
In the code-snippet below MBeautifier is formatting the first line using the configuration currently active, but will not format the lines 2,3,4,5. The last line will be beautified again using the current configuration.

    a =  1;
    % MBeautifierDirective:Format:Off
    longVariableName = 'where the assigement is';
    aligned          = 'with the next assignment';
    % MBeautifierDirective:Format:On
    someMatrix  =  [1 2 3];
    
The formatted code will look like (configuration dependently):

	a = 1;
	% MBeautifierDirective:Format:Off
	longVariableName = 'where the assigement is';
	aligned          = 'with the next assignment';
	% MBeautifierDirective:Format:On
	someMatrix = [1, 2, 3];

Usage
-----

### From MATLAB Command Window

Currently four approaches are supported:

 - Perform formatting on the currently active page of MATLAB Editor. Command: `MBeautify.formatCurrentEditorPage()`. By default the file is not saved, but it remains opened modified in the editor. Optionally the formatted file can be saved using the `MBeautify.formatCurrentEditorPage(true)` syntax.
 - Perform formatting on the currently selected text of the active page of MATLAB Editor. Command: `MBeautify.formatEditorSelection()`. An optional saving mechanism as above exists also in this case. Useful in case of large files, but in any case `MBeautify.formatCurrentEditorPage()` is suggested.
 - Perform formatting on a file. Command: `MBeautify.formatFile(file)`. Can be used with (1)one argument: the input file is formatted and remains open in the MATLAB editor unsaved; (2)two arguments as `MBeautify.formatFile(file, outFile)`: the formatted file is saved to the specified output file if possible. Output can be the same as input.
 - Perform formatting on several files in a directory. Command: `MBeautify.formatFiles(directory, fileFilter)`. The first argument is an absolute path to a directory, the second one is a wildcard expression (used for `dir` command) to filter files in the target directory. The files will be formatted in-place (overwritten). 
 
### Shortcuts
 
 There is a possibility to create shortcuts for the first three approaches above, which shortcut buttons will appear under the "Shortcuts" tab of MATLAB's main window below Matlab R2019, and under "Favourites" and on the "Quick Access Toolbar" above.
 
 To create these buttons, the following commands can be used:
 
  - `MBeautify.createShortcut('editorpage')`: Creates a shortcut for `MBeautify.formatCurrentEditorPage()`  
  - `MBeautify.createShortcut('editorselection')`: Creates a shortcut for `MBeautify.formatEditorSelection()`
  - `MBeautify.createShortcut('file')`: Creates a shortcut for `MBeautify.formatFile(sourceFile, destFile)`
  
 These shortcuts will add the MBeautifier root directory to the MATLAB path too, therefore no MATLAB path preparation is needed to use MBeautifier next time when a new Matlab instance is opened.
 
 Supported Matlab versions
 -------------------------
 
 The oldest version of MATLAB to be used to test MBeautifier is R2013b.
 
 Planned future versions
 -----------------------
 
It is planned that the project is maintained until MATLAB is shipped with a code formatter with a similar functionality.
 
It is planned to make MBeautifier also usable in Octave, by starting a new development branch using Java/Kotlin (versions 2.*). The MATLAB based branched will be developed in branch versions (1.*). 
 
