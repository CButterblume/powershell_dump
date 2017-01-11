<#
.SYNOPSIS
This script installs Microsoft SharePoint Server 2010 inclusive Service Pack 2. 
The file "config.xml" is necessary for an unattended installation.

.DESCRIPTION
Autor: stefan.schmalz@interface-ag.de
This script installs Microsoft SharePoint Server 2010 inclusive Service Pack 2.
The file "config.xml" is necessary for an unattended installation.

.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 

.EXAMPLE
install-Script -Force					Installation of Microsoft SharePoint Server 2010
install-Script -Uninstall -Force		Deinstallation of Microsoft SharePoint Server 2010

.OUTPUTS
The script writes some logifles in C:\RIS\Log\SHP2010.

.NOTES
To run the script you have to be a member of the local administrator group and you have to run the powershell with elevated rights.
ATTENTION: The Service Pack 2 files have to be unzipped in the Updates folder of the SharePoint 2010 ISO-files which also have to 
be unzipped in the source folder.
"Source" folder: Unzipped SharePoint 2010 ISO files.
"Source\Updates" folder (folder of the SharePoint 2010 ISO): Unzipped Service Pack 2 files.
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
## 31.05.2016			baumh			Initial version
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
Initialize-BLFunctions -AppName "MS_SHPO2010_ServerSP2" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
$AppDisplayName = "Microsoft SharePoint Server 2010"

"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

Function Invoke-ISInstallation() {
	$ExitCode = 1
	
#region Customized installation
	$UninstallInformation = Get-BLUninstallInformation -DisplayName $AppDisplayName
	If ($UninstallInformation.IsInstalled) {
		"Software is already installed - installation not necessary!" | Write-BLLog -LogType Information	
		$ExitCode = 0
	} else {
		$FilePath = Join-Path $AppSource "Source"
		$XmlFile = Join-Path $AppSource "config.xml"
		$SetupFile = "setup.exe"
		$FileName = Join-Path $FilePath $SetupFile
		$Arguments = "/config $XmlFile"
		$ExitCode = Invoke-BLSetupOther -FileName $FileName -Arguments $Arguments
	}
#endregion

	Return $ExitCode
}

Function Invoke-ISUninstallation() {
	"Uninstallation is unprovided for the Microsoft SharePoint Server 2010." | Write-BLLog -LogType Information
	$ExitCode = 0
	Return $ExitCode
}
#endregion

## ====================================================================================================
## MAIN
## ====================================================================================================
## CUSTOMIZE: Uncomment to get information from ConfigDB if required (use of Defaults.txt is optional).
## - The use of Defaults.txt and Write-BLConfigDBSettings is optional
## - Add a filter to Write-BLConfigDBSettings to only show required variables (will filter ConfigDB variables beginning with this value)

 
	If (-Not $Uninstall) {
		$ExitCode = Invoke-ISInstallation
	} Else {
		$ExitCode = Invoke-ISUninstallation
	}

"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
