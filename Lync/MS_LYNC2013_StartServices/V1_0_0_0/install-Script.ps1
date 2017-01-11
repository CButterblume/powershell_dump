<#
.SYNOPSIS
This script will copy the two files from the source folder to C:\RIS\FILES\MS_LYNC2013_StartServices

.DESCRIPTION
This script will copy the two files from the source folder to C:\RIS\FILES\MS_LYNC2013_StartServices

.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 
In this case we have no uninstallation routine. 

.EXAMPLE
install-Script.ps1 -Force
install-Script.ps1 -Uninstall
#>

## --------------------------------------------------------------------------------------
## File                 : Install-Script.ps1
##                        --------------------
## Purpose              : Installs or uninstalls software and logs progress and result
##
## Syntax               : powershell.exe "& '<TemplateFullPath>\Install-Script.ps1' <Script arguments>"
##
## Template Version Management
## ===========================
## Date			Version	By			Change Description
## -------------------------------------------------------------------------------
## 05.08.2013	M. Richardt			Initial version
## 12.09.2013	B. Kolbe			Implement functions for 32Bit applications and installation check in uninstall section
## 16.09.2013	A. Horn				Fixed syntax-error (unexpected "}")
## 09.01.2014	H. Baum				"< Appname >"  in Aufruf von Initialize-BLFunctions
## 29.07.2014	M. Richardt			Changed uninstall handling to new function Get-BLUninstallInformation
## 25.06.2015	H. Baum				Set-BLRDSInstallMode / Set-BLRDSExecuteMode um Installationsaufrufe eingefügt
## 01.07.2015	H.Baum				RunAsTask als Option im Template aufgenommen
## 07.04.2016	H.Baum				Option CopyFiles to RIS\FILE\Appname aufgenommen
## -------------------------------------------------------------------------------
## 
## When creating custom functions, use the Verb-Noun syntax and the naming rules from Microsoft.
## Use the Cmdlet "Get-Verb" in a PsSession for a list; details can be found here:
## Approved Verbs for Windows PowerShell Commands
## http://msdn.microsoft.com/en-us/library/ms714428(v=vs.85).aspx
## Use "IS" (*I*nstall *S*cript) as common Noun prefix for all custom functions in this script.
##
## Version Management
## ==================
## Date					Version	By			Change Description
## --------------------------------------------------------------------------------------
## 01.01.1980			Author Name			Initial version
## --------------------------------------------------------------------------------------
## CUSTOMIZE: Add the change date and an overview of your changes to the table above, and add a description of what the script does here:
##

## CUSTOMIZE: delete ranges (#region ... #endregion) you do not need

## CUSTOMIZE: Add supported arguments for the script here (do not remove the -Force or -Uninstall arguments):
Param(
	[switch]$Force,
	[switch]$Uninstall
)
$LibraryPath = "C:\RIS\Lib"
$BaseLibrary = Join-Path $LibraryPath "BaseLibrary.psm1"
If (-Not (Import-Module $BaseLibrary -PassThru)) {Write-Host -ForegroundColor Red "[CriticalError] File not found - '$BaseLibrary'"; Exit 1}

$ScriptItem = Get-Item -Path $MyInvocation.MyCommand.Path
$Local:ScriptFullName = $ScriptItem.FullName
$Local:ScriptName = $ScriptItem.Name
$Local:ScriptPath = $ScriptItem.DirectoryName

## CUSTOMIZE: Edit value for the AppName parameter <Appname> below; use only characters allowed in file names, no spaces:
Initialize-BLFunctions -AppName "MS_LYNC2013_StartServices" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
$AppDisplayName = "MS_LYNC2013_StartServices"
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

#region Std-Installation "FileCopyOnly" use this if you only want to copy all files from $AppSource\Source  to C:\RIS\FILES\$Appname, delete it otherwise
$DstDir = "C:\RIS\FILES\$AppName"
#endregion


#region Std-Installation "FileCopyOnly" 
Function Invoke-ISInstallation() {
	$ExitCode = 0
	$LogType = "Information"
	try {
		$Destination = Join-Path $AppSource "Source"
		$TXT = Join-Path $AppSource "Defaults.txt"
		"Copying Defaults.txt to $Destination " | Write-BLLog -LogType $LogType
		$CopyDefault = Copy-Item -Path "$TXT" -Destination "$Destination" -Force
	} catch {
		$ErrorMessage = $_.Exception.Message
		$LogType = "Error"
		"This error was thrown while mounting the $FIMDBName Database : `r`n $ErrorMessage" | Write-BLLog -LogType $LogType
		$Error.clear()
		Return 1	
	}
	
	
	# remove existing folder
	if (test-Path $DstDir) {
		"Removing existing folder '$DstDir'" | Write-BLLog
		$RET = remove-item -Recurse -Force -Path $DstDir -ea 0
        $RET = $?
		"RET:$RET" | Write-BLLog
		if ( -not $RET ) {
			"Could not delete existing folder '$DstDir'" | Write-BLLog -LogType Error 
			return 1
		}
	}
	
	# create directory
	"Creating folder '$DstDir'" | Write-BLLog
	$RET = New-Item -type directory "$DstDir"
    $RET = $?
	"RET:$RET" | Write-BLLog
	if ( -not $RET ) {
		"Could not create folder '$DstDir'" | Write-BLLog -LogType Error 
		return 2
	}

	# copy Files
	"Copying items from '$AppSource\Source' to folder '$DstDir'" | Write-BLLog
	$RET = Copy-Item -Path "$AppSource\Source\*" -Destination "$DstDir" -Container -Recurse -Force
    $RET = $?
	"RET:$RET" | Write-BLLog
	if ( -not $RET ) {
		"Could not copy items from '$AppSource\Source' to folder '$DstDir'" | Write-BLLog -LogType Error 
		return 3
	}
	


	Return $ExitCode
}
#endregion

#region uninstallation.
Function Invoke-ISUninstallation() {
	$ExitCode = 0
	if (test-Path $DstDir) {
		"Removing existing folder '$DstDir'" | Write-BLLog
		$RET = remove-item -Recurse -Force -Path $DstDir -ea 0
        $RET = $?
		"RET:$RET" | Write-BLLog
		if ( -not $RET ) {
			"Could not delete existing folder '$DstDir'" | Write-BLLog -LogType Error 
			return 1
		}
	} else {
        "Folder '$DstDir' does not exist: OK" | Write-BLLog
    }
	Return $ExitCode
}
#endregion

## ====================================================================================================
## MAIN
## ====================================================================================================
## CUSTOMIZE: Uncomment to get information from ConfigDB if required (use of Defaults.txt is optional).
## - The use of Defaults.txt and Write-BLConfigDBSettings is optional
## - Add a filter to Write-BLConfigDBSettings to only show required variables (will filter ConfigDB variables beginning with this value)
$cfg = @{}
$ExitCode = Get-BLConfigDBVariables $cfg -Defaults "$AppSource\Defaults.txt"
If ($ExitCode -ne 0) {
	"Error setting variables from ConfigDB, unable to continue!" | Write-BLLog -LogType Information
	Exit-BLFunctions -SetExitCode 1
}

 
	If (-Not $Uninstall) {
		$ExitCode = Invoke-ISInstallation
	} Else {
		$ExitCode = Invoke-ISUninstallation
	}
	

"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
