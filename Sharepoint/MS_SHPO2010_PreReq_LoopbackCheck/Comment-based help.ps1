<#
.SYNOPSIS
One line of function summary.

.DESCRIPTION
Verbose description of the function; usually starts with "The function <function name> ...", followed by the synopsis.

.PARAMETER <Argument name without '$'>
Argument description; use one .PARAMETER line per argument
Use 'Optional' or 'Mandatory' as first line; declaring a variable explicitly as mandatory has the disadvantage that PS will *always*
query for input if the argument is not passed, you can't force an error if the argument is missing. For some functions, this is not an option,
so it's best to state it in the description.

.INPUTS
Type of the input arguments (use the TypeName line of '$Variable | get-member'); examples:
System.String
System.__ComObject

.OUTPUTS
Type of the return value (if applicable)

.EXAMPLE
Example use of the function; multiple .EXAMPLE lines are allowed
The FIRST line will automatically have "C:\PS>" added at the beginning.
After the first line, 2 empty lines will automatically be added.
For a multiline example, it's best to use an underscore as first line, then the example lines, two empty lines, and the description.
Example:
$Result = My-Function -MyArgument 1
Description of what the example line does

.LINK
Add the names of related functions and/or external links (for example to source information download) here

.NOTES
Other notes
Use 'Get-Help about_Comment_Based_Help' for details about comment Based Help.
#>
