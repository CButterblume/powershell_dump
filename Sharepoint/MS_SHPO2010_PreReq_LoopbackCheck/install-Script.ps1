<#
.SYNOPSIS
The script deactivates the loopback check.

.DESCRIPTION
The script deactivates the loopback check via these registry keys:

1.	HKLM\System\CurrentControlSet\Control\LSA
New DWORD Key with the name DisableLoopbackCheck and hexadecimal value 1

2.	HKLM\System\CurrentControlSet\Control
New DWORD Key wit the name ServicesPipeTimout and the decimal value of 60000

.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 

.OUTPUTS
The script writes a logfile in C:\RIS\Log.

.EXAMPLE
install-Script -Force					Installation of the Software
install-Script -Uninstall -Force		Uninstallation of the Software

.NOTES
The user that runs this script has to be member of the local administrator group.
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
Initialize-BLFunctions -AppName "MS_SHPO2010_PreReq_LoopbackCheck" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall

"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information


#region Customized installation. Use this part for normal installations, delete it otherwise
Function Invoke-ISInstallation() {
	$ExitCode = 1
	$LogType = "Information"

	$LBCPath = "HKLM\System\CurrentControlSet\Control\LSA"
	$LBCName = "DisableLoopbackCheck"
	$LBCValue = 1

	$SPTPath = "HKLM\System\CurrentControlSet\Control"
	$SPTName = "ServicesPipeTimout"
	$SPTValue = 60000

	$Type = "DWord"
	
	"Searching for an existing DWORD. Invoking: Get-BLRegistryValueX64 -Path $LBCPath -Name $LBCName" | Write-BLLog -LogType $LogType
	$CheckLBC = Get-BLRegistryValueX64 -Path $LBCPath -Name $LBCName -ErrorAction SilentlyContinue
	if ($CheckLBC) {
		"DWORD - $LBCPath\$LBCName - exists. Skipping the setting of the DWORD..." | Write-BLLog -LogType $LogType
		$ExitCode = 0
	} else {
		"DWORD does not exist. Setting the DWORD now." | Write-BLLog -LogType $LogType
		"Invoking: Set-BLRegistryValueX64 -Path $LBCPath -Name $LBCName -Type $Type -Value $LBCValue" | Write-BLLog -LogType $LogType
		$SetLBC = Set-BLRegistryValueX64 -Path $LBCPath -Name $LBCName -Type $Type -Value $LBCValue
		$CheckLBC = Get-BLRegistryValueX64 -Path $LBCPath -Name $LBCName -ErrorAction SilentlyContinue
		if ($CheckLBC -eq 1) {
			"DWORD - $LBCPath\$LBCName was successfully set to 1." | Write-BLLog -LogType $LogType
			$ExitCode = 0
		} else {
			$LogType = "Error"
			"An error occured while setting the DWORD for disabling the Loopback check. Please take a look at the logfile." | Write-BLLog -LogType $LogType
			Return 1
		}
	}
	if ($ExitCode -eq 0) {
		"Searching for an existing DWORD. Invoking: Get-BLRegistryValueX64 -Path $SPTPath -Name $SPTName" | Write-BLLog -LogType $LogType
		$CheckSPT = Get-BLRegistryValueX64 -Path $SPTPath -Name $SPTName -ErrorAction SilentlyContinue
		if ($CheckSPT) {
			"DWORD - $SPTPath\$SPTName - exists. Skipping the setting of the DWORD..." | Write-BLLog -LogType $LogType
			$ExitCode = 0
		} else {
			"DWORD does not exist. Setting the DWORD now." | Write-BLLog -LogType $LogType	
			"Invoking: Set-BLRegistryValueX64 -Path $SPTPath -Name $SPTName -Type $Type -Value $SPTValue" | Write-BLLog -LogType $LogType
			$SetSPT = Set-BLRegistryValueX64 -Path $SPTPath -Name $SPTName -Type $Type -Value $SPTValue
			$CheckSPT = Get-BLRegistryValueX64 -Path $SPTPath -Name $SPTName -ErrorAction SilentlyContinue
			if ($CheckSPT -eq 60000) {
				"DWORD - $SPTPath\$SPTName was successfully set to 60000." | Write-BLLog -LogType $LogType
				$ExitCode = 0
			} else {
				$LogType = "Error"
				"An error occured while setting the DWORD for setting the ServicesPipeTimout to 60000. Please take a look at the logfile." | Write-BLLog -LogType $LogType
				Return 1
			}
		}
	}
	Return $ExitCode
}
#endregion

#region uninstallation
Function Invoke-ISUninstallation() {
	$ExitCode = 1
	$LogType = "Information"
	
	$LBCPath = "HKLM\System\CurrentControlSet\Control\LSA"
	$LBCName = "DisableLoopbackCheck"

	$SPTPath = "HKLM\System\CurrentControlSet\Control"
	$SPTName = "ServicesPipeTimout"
	
	"Searching for existing registry values - $LBCPath\$LBCName " | Write-BLLog -LogType $LogType
	$CheckLBC = Get-BLRegistryValueX64 -Path $LBCPath -Name $LBCName -ErrorAction SilentlyContinue
	if ($CheckLBC) {
		"Registry value exists, removing it now. Invoking: Remove-BLRegistryValueX64 -Path $LBCPath -Name $LBCName" | Write-BLLog -LogType $LogType
		$RemValueLBC = Remove-BLRegistryValueX64 -Path $LBCPath -Name $LBCName -ErrorAction SilentlyContinue
		if ($RemValueLBC) {
			"DWORD was successfully removed." | Write-BLLog -LogType $LogType
			$ExitCode = 0
		} else {
			$LogType = "Error"
			"An error occured while removing the DWORD for - $LBCPath\$LBCName" | Write-BLLog -LogType $LogType
			Return 1
		}
	} else {
		"The registry DWORD does not exist. Nothing to do, skipping the removal..." | Write-BLLog -LogType $LogType
		$ExitCode = 0
	}

	$CheckSPT = Get-BLRegistryValueX64 -Path $SPTPath -Name $SPTName -ErrorAction SilentlyContinue
	if ($CheckSPT) {
		"Registry value exists, removing it now. Invoking: Remove-BLRegistryValueX64 -Path $SPTPath -Name $SPTName" | Write-BLLog -LogType $LogType
		$RemValueSPT = Remove-BLRegistryValueX64 -Path $SPTPath -Name $SPTName -ErrorAction SilentlyContinue
	} else {
		"The registry DWORD does not exist. Nothing to do, skipping the removal..." | Write-BLLog -LogType $LogType
		$ExitCode = 0
	}

	Return $ExitCode
}
#endregion

 
	If (-Not $Uninstall) {
		$ExitCode = Invoke-ISInstallation
	} Else {
		$ExitCode = Invoke-ISUninstallation
	}
	

"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
