<#
.SYNOPSIS
This script sets the right registry values for the Internet Explorer Enhanced Security Configuration.

.DESCRIPTION
This script sets the Internet Explorer Enhanced Security Configuration for 
Admins to Off
Users to On
via a registry key.

Admins 	HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}\IsInstalled DWORD 0x00000000
Users	HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}\IsInstalled DWORD 0x00000001


.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 

.OUTPUTS
The script writes a logfile in C:\RIS\Log.

.EXAMPLE
install-Script -Force					Installation der Software
install-Script -Uninstall -Force		Deinstallation der Software

.NOTES
This script has to be run by a user that is member of the local admininistrator group.
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
Initialize-BLFunctions -AppName "03 - MS_SHPO2010_PreReq_IEEsc" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

#region Std-Installation "FileCopyOnly" use this if you only want to copy all files from $AppSource\Source  to C:\RIS\FILES\$Appname, delete it otherwise
$DstDir = "C:\RIS\FILES\$AppName"
#endregion


#region installation
Function Invoke-ISInstallation() {
	$ExitCode = 1
	$LogType = "Information"
	$AdminRegKey = "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
	$UserRegKey = "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
	$Admin = (Get-BLRegistryKeyX64 -Path $AdminRegKey).IsInstalled
	$User = (Get-BLRegistryKeyX64 -Path $UserRegKey).IsInstalled
	$On = 1
	$Off = 0
	$Type = "DWord"
	
	if ($Admin -eq 0) {
		"OK - Internet Explorer Enhanced Security Configuration for admins is already disabled." | Write-BLLog -LogType $LogType		
		$ExitCode = 0
	} else {
		"IE ESC is set to 'On' for admins. Invoking: Set-BLRegistryValueX64 -Path $AdminRegKey -Name IsInstalled -Type $Type -Value $Off" | Write-BLLog -LogType $LogType
		$SetAdminKey = Set-BLRegistryValueX64 -Path $AdminRegKey -Name IsInstalled -Type "DWord" -Value $Off
	}
	
	if (($SetAdminKey) -OR ($ExitCode -eq 0)) {
		if ($User -eq 1) {
			"OK - Internet Explorer Enhanced Security Configuration for users is already enabled." | Write-BLLog -LogType $LogType
			$ExitCode = 0
		} else {
			"IE ESC is set to 'Off' for users. Invoking: Set-BLRegistryValueX64 -Path $UserRegKey -Name IsInstalled -Type $Type -Value $On" | Write-BLLog -LogType $LogType
			$SetUserKey = Set-BLRegistryValueX64 -Path $UserRegKey -Name IsInstalled -Type "DWord" -Value $On
			if ($SetUserKey) {
				$ExitCode = 0
			} else {
				$LogType = "Error"
				"An error occured while setting the registry key for IE ESC User on." | Write-BLLog -LogType $LogType
			}
		}
	} else {
		$LogType = "Error"
		"An error occured while setting the registry key for IE ESC Admin off." | Write-BLLog -LogType $LogType
		Return 1
	}
	Return $ExitCode
}
#endregion Installation

#region Uninstallation
Function Invoke-ISUninstallation() {
	$ExitCode = 1
	$LogType = "Information"
	$AdminRegKey = "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
	$UserRegKey = "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
	$Admin = (Get-BLRegistryKeyX64 -Path $AdminRegKey).IsInstalled
	$User = (Get-BLRegistryKeyX64 -Path $UserRegKey).IsInstalled
	$On = 1
	$Off = 0
	$Type = "DWord"
	if ($Admin -eq 1) {
		"OK - Internet Explorer Enhanced Security Configuration for admins is already enabled." | Write-BLLog -LogType $LogType		
		$ExitCode = 0
	} else {
		"Setting the IE ESC 'On' for Admin. Invoking: Set-BLRegistryValueX64 -Path $AdminRegKey -Name IsInstalled -Type $Type -Value $On" | Write-BLLog -LogType $LogType
		$SetAdminKey = Set-BLRegistryValueX64 -Path $AdminRegKey -Name IsInstalled -Type "DWord" -Value $On
	}
	
	if (($SetAdminKey) -OR ($ExitCode -eq 0)) {
		if ($User -eq 0) {
			"OK - Internet Explorer Enhanced Security Configuration for users is already disabled." | Write-BLLog -LogType $LogType
			$ExitCode = 0
		} else {
			"Setting the IE ESC 'Off' for User. Invoking: Set-BLRegistryValueX64 -Path $UserRegKey -Name IsInstalled -Type $Type -Value $Off" | Write-BLLog -LogType $LogType
			$SetUserKey = Set-BLRegistryValueX64 -Path $UserRegKey -Name IsInstalled -Type "DWord" -Value $Off
			if ($SetUserKey) {
				$ExitCode = 0
			} else {
				$LogType = "Error"
				"An error occured while setting the registry key for IE ESC User off." | Write-BLLog -LogType $LogType
			}
		}
	} else {
		$LogType = "Error"
		"An error occured while setting the registry key for IE ESC Admin off." | Write-BLLog -LogType $LogType
		Return 1
	}
	Return $ExitCode
}
#endregion Uninstallation

## ====================================================================================================
## MAIN
## ====================================================================================================
 
	If (-Not $Uninstall) {
		$ExitCode = Invoke-ISInstallation
	} Else {
		$ExitCode = Invoke-ISUninstallation
	}


"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
