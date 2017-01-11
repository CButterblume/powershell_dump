<#
.SYNOPSIS
The script installs necessary hotfixes.

.DESCRIPTION
Autor: stefan.schmalz@interface-ag.de

Actually these KBs are installaed by the script.
Multirole Server:
	- KB974405-x64
	- KB2685891-x64
	- KB2639032-x64
	- KB2619234-v2

Edge Transport Server: 
None
	
If new KBs are necessary, the script searches for .msu-files in the Source folder and installs the existing KBs.
A Reboot is required after the installation.

.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 

.EXAMPLE
install-Script -Force					Installation der Hotfixes
install-Script -Uninstall -Force		Deinstallation der Hotfixes

.OUTPUTS
The script writes some logifles with the name of the KB in the name of the logfile (for wach KB a .evt and a .dpx file). After the (un-)installation the logfiles
are transfered to the the Summarize log by the "ConvertFrom-BLEvt"-function.

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
## region Version Management
## Version Mngt
## ============
## Date			Version	By		Change Description
## -------------------------------------------------------------------------
## 01.06.2016	V0.0.1 S. Schmalz (IF)	Datei angelegt, Skriptkopf eingefuegt.
## 06.06.2016	V0.0.2 S. Schmalz (IF)	BL-Functions eingebaut, Ueberführung in das Install-Script.ps1 File
## 09.06.2016	V0.0.3 S. Schmalz (IF)	Fehler bei der Übergabe der Variable $Logpath behoben. Pfad war nicht angegeben.
## 16.06.2016	V0.0.4 S. Schmalz (IF)	Hilfe erweitert.
## 22.06.2016	V0.0.5 S. Schmalz (IF)	ExitCode-Test in eine Funktion gepackt. Kleinen Fehler beim Logging (Deinstallation) behoben.
## 24.10.2016	V0.0.6 S. Schmalz (IF)	Abfrage und Logik eingebaut abhängig von der zu installierenden Rolle.
##
## endregion Version Management
##
## CUSTOMIZE: Add supported arguments for the script here (do not remove the -Force or -Uninstall arguments):

Param(
	[switch]$Force,
	[switch]$Uninstall
)

$LibraryPath = "C:\RIS\Lib"
$BaseLibrary = Join-Path $LibraryPath "BaseLibrary.psm1"
$BaseLibraryEXCHANGE = Join-Path $LibraryPath "BaseLibraryEXCHANGE.psm1"
If (-Not (Import-Module $BaseLibrary -PassThru)) {Write-Host -ForegroundColor Red "[CriticalError] File not found - '$BaseLibrary'"; Exit 1}
If (-Not (Import-Module $BaseLibraryEXCHANGE -PassThru)) {Write-Host -ForegroundColor Red "[CriticalError] File not found - '$BaseLibraryEXCHANGE'"; Exit 1}

$ScriptItem = Get-Item -Path $MyInvocation.MyCommand.Path
$Local:ScriptFullName = $ScriptItem.FullName
$Local:ScriptName = $ScriptItem.Name
$Local:ScriptPath = $ScriptItem.DirectoryName

## CUSTOMIZE: Edit value for the AppName parameter <Appname> below; use only characters allowed in file names, no spaces:
Initialize-BLFunctions -AppName "MS_EXCH2013_Prereq_Hotfixes" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall

"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

#Setting Variables for Logging
$Logpath = "C:\RIS\Log\"
$Ex2013_PreReqPath = $Local:ScriptPath + "\Source"

#Searching for Updates - .msu-files - in the "Source" folder
$Ex2013_WinUpdates = Get-ChildItem $Ex2013_PreReqPath -ErrorAction Stop | Where {$_.Name -like "*.msu"} | Select-Object Name | findstr ".msu"

#One or more found in the "Source" folder?
if (!($Ex2013_WinUpdates.length)){
	"No Hotfixfile found. Installation will be aborted." | Write-BLLog -LogType CriticalError
	Return 1
}


#region installation.
Function Invoke-ISInstallation ($Ex2013_WinUpdates,$Ex2013_PreReqPath,$Logpath) {
## Make sure that $ExitCode is ONLY 0 if the install was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.

$ExitCode = 1
$Role = $cfg["EX2013_INSTALL_ROLE"]
$LogType = "Information"
	if ($Role -eq "MR") {
		"This server is a multirole server. Installing the needed hotfixes for the role." | Write-BLLog -LogType $LogType
		foreach ($Hotfix in $Ex2013_WinUpdates) {
			$HotFix = $HotFix.trim()
			$HF = $HotFix.split("-")
			$HFInst = $HF[1]
			$Installed = Get-HotFix $HFInst -ErrorAction SilentlyContinue
			if (!$Installed) {
				"Update $HFInst was not installed yet. Installation can be started." | Write-BLLog -LogType $LogType
				"Hotfix $HFInst will be installed now" | Write-BLLog -LogType $LogType
				$MSUFile = Join-Path $Ex2013_PreReqPath $Hotfix
				$HotFixLogName = $Hotfix + ".evt"
				$Logfile = Join-Path $Logpath $HotfixLogName
				$Exitcode = Install-BLWindowsHotfix -MSUFile $MSUFile -LogFile $LogFile
			} else {
				"Update $HFInst was installed previously. Installation will be canceled." | Write-BLLog -LogType $LogType
				$ExitCode = 0			
			} 
		}
	} elseif ($Role -eq "ET") {
		"This server is a edge transport server. No installation of hotfixes required. Skipping installation..." | Write-BLLog -LogType $LogType
		$ExitCode = 0
	} else {
		$LogType = "Error"
		"The specified Role in the configdb variable 'EX2013_INSTALL_ROLE' is neither 'ET' nor 'MR'. Please correct that. We cancel the installation now." | Write-BLLog -LogType $LogType
		Return 1	
	}
	Return $ExitCode
}
#endregion installation

#region Uninstallation
Function Invoke-ISUninstallation ($Ex2013_WinUpdates,$Ex2013_PreReqPath,$Logpath) {
$ExitCode = 1
$Role = $cfg["EX2013_INSTALL_ROLE"]
$LogType = "Information"
	if ($Role -eq "MR") {	
		foreach ($Hotfix in $Ex2013_WinUpdates) {
			$HotFix = $HotFix.trim()
			$HF = $HotFix.split("-")
			$HFInst = $HF[1]
			$Installed = Get-Hotfix $HFInst -ErrorAction Silentlycontinue		
			if (!$Installed) { 
				"Update $HFInst is not installed. Uninstallation will be canceled." | Write-BLLog -LogType $LogType
				$ExitCode = 0
			} else {
				"Update $HFInst is installed.  Uninstallation can be started." | Write-BLLog -LogType $LogType
				"Starting uninstallation of update $HFInst." | Write-BLLog -LogType $LogType
				$MSUFile = Join-Path $Ex2013_PreReqPath $Hotfix
				$HotFixLogName = $Hotfix + ".evt"
				$Logfile = Join-Path $Logpath $HotfixLogName
				$Exitcode = Uninstall-BLWindowsHotfix -MSUFile $MSUFile -LogFile $LogFile
			}
		}
	} elseif ($Role -eq "ET") {
		"No hotfixes to remove. Skipping the removal of any hotfixes." | Write-BLLog -LogType $LogType
		$ExitCode = 0
	} else {
		$LogType = "Error"
		"The specified Role in the configdb variable 'EX2013_INSTALL_ROLE' is neither 'ET' nor 'MR'. Please correct that. We cancel the installation now." | Write-BLLog -LogType $LogType
		Return 1	
	}
#	Return $ExitCode
Return $ExitCode
}
#endregion


#region MAIN
## ====================================================================================================
## MAIN
## ====================================================================================================
$cfg = @{}
$ExitCode = Get-BLConfigDBVariables $cfg -Defaults "$AppSource\Defaults.txt"
If ($ExitCode -ne 0) {
	"Error setting variables from ConfigDB, unable to continue!" | Write-BLLog -LogType Information
	Exit-BLFunctions -SetExitCode 1
}
 
	If (-Not $Uninstall) {
		$ExitCode = Invoke-ISInstallation -Ex2013_WinUpdates $Ex2013_WinUpdates -Ex2013_PreReqPath $Ex2013_PreReqPath -LogPath $Logpath
	} Else {
		$ExitCode = Invoke-ISUninstallation  -Ex2013_WinUpdates $Ex2013_WinUpdates -Ex2013_PreReqPath $Ex2013_PreReqPath -LogPath $Logpath
	}
#endregion MAIN

$ExitCode = Test-BLEXExitCode -ExitCode $ExitCode
	
"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
