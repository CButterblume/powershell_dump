<#
.SYNOPSIS
The script installs the german language pack for Microsoft SharePoint 2010 and the correspondingly Service Pack 1.

.DESCRIPTION
The script installs the german language pack for Microsoft SharePoint 2010 and the correspondingly Service Pack 1.
If there is any of the applications already installed the script skips the installation.

Uninstallation is unprovided for these applications.

.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 

.EXAMPLE
install-Script -Force					Installation of the german language pack for Microsoft SharePoint Server 2010
install-Script -Uninstall -Force		Deinstallation

.OUTPUTS
The script writes a logifle in C:\RIS\Log\.

.NOTES
To run the script you have to be a member of the local administrator group and you have to run the powershell with elevated rights.
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
Initialize-BLFunctions -AppName "MS_SHPO2010_LanguagePackDE" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

#region installation
Function Invoke-ISInstallation() {
	$ExitCode = 1
	$LogType = "Information"
	$InstallNameLP = "Language Pack for SharePoint, Project Server and Office Web Apps 2010 - German/Deutsch"
	$InstallNameLPSP = "Service Pack 2 for Microsoft 2010 Server Language Pack (KB2687462) 64-Bit Edition"
	$UninstallInformationLP = Get-BLUninstallInformation -DisplayName $InstallNameLP
	$UninstallInformationLPSP = Get-BLUninstallInformation -DisplayName $InstallNameLPSP
	$Arguments = "/quiet /passive /norestart"
	
	if ($UninstallInformationLP.IsInstalled) {
		"The Language Pack is already installed - skipping the installation..." | Write-BLLog -LogType $LogType	
		$ExitCode = 0
	} else {
		$SourcePath = Join-Path $AppSource "Source"
		$LP = "ServerLanguagePack.exe"
		$FileNameLP = Join-Path $SourcePath $LP
		$LPSP = "oslpksp2010-kb2687462-fullfile-x64-de-de.exe"
		$FileNameLPSP = Join-Path $SourcePath $LPSP
		"Installing the language pack 'german' now." | Write-BLLog -LogType $LogType	
		$ExitCode = Invoke-BLSetupOther -FileName $FileNameLP -Arguments $Arguments
	}	
	
	if ($ExitCode -eq 0) {
		if ($UninstallInformationLPSP.IsInstalled) {
			"The Service Pack 1 of the language pack is already installed - skipping the installation..." | Write-BLLog -LogType $LogType	
			$ExitCode = 0
		} else {
			"Installing the Service Pack 1 for the language pack now. `r`nInvoking: Invoke-BLSetupOther -FileName $FileNameLPSP -Arguments $Arguments" | Write-BLLog -LogType $LogType	
			$ExitCode = Invoke-BLSetupOther -FileName $FileNameLPSP -Arguments $Arguments
		}
	} else {
		$LogType = "Error"
		"An error occured while installing the Language Pack for SharePoint. The ExitCode $ExitCode was thrown." | Write-BLLog -LogType $LogType
		Return 1
	}
	Return $ExitCode
}
#endregion installation

#region  uninstallation
Function Invoke-ISUninstallation() {
	$LogType = "Information"
	$ExitCode = 0
	"No uninstallation provided for the language pack and its service pack 1" | Write-BLLog -LogType $LogType
	Return $ExitCode
}
#endregion uninstallation

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



## CUSTOMIZE: RunAsTask
## if you want to use RunAsTask Option i.e. want to run the installation script with a special account
## - uncomment lines between "##OPTION: RunAsTask" to "## END OPTION", there are 2 blocks to uncomment
## - adjust Konfig-DB VarNames as needed 

##OPTION: RunAsTask 
#$TaskUserDomain =	$cfg["XXX  _INSTALL_SETUP_USER"].Split("\")[0].Trim()
#$TaskUsername =		$cfg["XXX  _INSTALL_SETUP_USER"].Split("\")[1].Trim()
#$TaskPassword =		$cfg["XXX  _INSTALL_SETUP_PASSWORD"].Trim()
### Start a second instance of the script; the main instance will wait here until the task instance is done:
#$ExitCode = Enter-BLExecutionAsTask -UserName $TaskUsername -UserDomain $TaskUserDomain -UserPass $TaskPassword -Timeout 60 # -NoTask
#If ($ExitCode -eq -2) {				# Task could not be created; this is a serious error
#   $ExitCode = 1
#} ElseIf ($ExitCode -eq -1) {		# we're running as a scheduled task; this is a second instance of the script!
#	$CurrentUserDomain, $CurrentUserName = (& whoami.exe).Split("\")
#	If ($CurrentUserName -eq "SYSTEM") {
#		"Installation can not be run with user account '$($CurrentUserDomain)\$($CurrentUserName)'" | Write-BLLog -LogType CriticalError
#		Exit-BLFunctions -SetExitCode 1
#	}
##END OPTION
 
	If (-Not $Uninstall) {
		$ExitCode = Invoke-ISInstallation
	} Else {
		$ExitCode = Invoke-ISUninstallation
	}
	
##OPTION: RunAsTask
#}
##END OPTION



## CUSTOMIZE: An msi installation may leave with errorlevel 3010, indicating a reboot is required;
## uncomment if this is supported, and make sure that the Task Sequence has a Reboot action after package execution  (=> InstallationPackageList)
##OPTION: Repair MSI-Exitcode
#If ($ExitCode -eq 3010) {
#	"A reboot is required to finish the installation!" | Write-BLLog -LogType Warning
#	$ExitCode = 0
#}
##END OPTION


"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
