# MBeautifier

MBeautifier is a lightweight M-Script based tool that can be usable to format Matlab M-Code directly in the Matlab editor.

# Deployment
Add container directory to Matlab path, then execute: MBeautify.setup

This command will make the standard configuration of formatting.
Configuration can be modified by editing the "MBeautifier\resources\settings\MBeautyConfigurationRules.xml" file then executing the setup command again.

# Usage
Formatting can be done by executing the "MBeautify.beautify('EditorCurrentPage');" command.

This command will perform the formatting on the currently active Matlab Editor Page (this is the only approach now supported).
