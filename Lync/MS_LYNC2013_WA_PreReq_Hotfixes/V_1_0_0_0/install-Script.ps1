<#
.SYNOPSIS
Installation of necessary KBs. Actually these are necessary:
	- KB2592525
and deinstallation of
	- KB2670838

.DESCRIPTION
Autor: stefan.schmalz@interface-ag.de

Actually these KBs are installed by the script.
	- KB2592525
and thsi KB will be deinstalled
	- KB2670838
	
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
## Date			Version		By					Change Description
## -------------------------------------------------------------------------
## 29.07.2016	V0.0.0.1	S. Schmalz (IF)		Datei angelegt, Skriptkopf und CBH eingefuegt.
## 29.07.2016	V0.0.0.2 	S. Schmalz (IF)		Skript fertig
## endregion Version Management
##
## CUSTOMIZE: Add supported arguments for the script here (do not remove the -Force or -Uninstall arguments):

Param(
	[switch]$Force,
	[switch]$Uninstall
)

$LibraryPath = "C:\RIS\Lib"
$BaseLibrary = Join-Path $LibraryPath "BaseLibrary.psm1"
$BaseLibraryLYNC = Join-Path $LibraryPath "BaseLibraryLYNC.psm1"
If (-Not (Import-Module $BaseLibrary -PassThru)) {Write-Host -ForegroundColor Red "[CriticalError] File not found - '$BaseLibrary'"; Exit 1}
If (-Not (Import-Module $BaseLibraryLYNC -PassThru)) {Write-Host -ForegroundColor Red "[CriticalError] File not found - '$BaseLibraryLYNC'"; Exit 1}

$ScriptItem = Get-Item -Path $MyInvocation.MyCommand.Path
$Local:ScriptFullName = $ScriptItem.FullName
$Local:ScriptName = $ScriptItem.Name
$Local:ScriptPath = $ScriptItem.DirectoryName

## CUSTOMIZE: Edit value for the AppName parameter <Appname> below; use only characters allowed in file names, no spaces:
Initialize-BLFunctions -AppName "MS_LYNC2013_WA_Prereq_Hotfixes" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall

"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information


Function Invoke-ISInstallation () {
## Make sure that $ExitCode is ONLY 0 if the install was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.

$ExitCode = 1
#Setting Variables for Logging
$Logpath = "C:\RIS\Log\"
$Ly2013_PreReqPath = $AppSource + "\Source"

#Searching for Updates - .msu-files - in the "Source" folder
$Ly2013_WinUpdates = Get-ChildItem $Ly2013_PreReqPath -ErrorAction Stop | Where {$_.Name -like "*.msu"} | Select-Object Name | findstr ".msu"

#One or more found in the "Source" folder?
if (!($Ly2013_WinUpdates.length)){
	"No Hotfixfile found. Installation will be aborted." | Write-BLLog -LogType CriticalError
	Return 1
}
	
#region installation.
	foreach ($Hotfix in $Ly2013_WinUpdates) {
		$HotFix = $HotFix.trim()
		$HF = $HotFix.split("-")
		$HFInst = $HF[1]
		$Installed = Get-HotFix $HFInst -ErrorAction SilentlyContinue
		if (!$Installed) {
			"Update $HFInst was not installed yet. Installation can be started." | Write-BLLog
			"Hotfix $HFInst will be installed now" | Write-BLLog
			$MSUFile = Join-Path $Ly2013_PreReqPath $Hotfix
			$HotFixLogName = $Hotfix + ".log"
			$Logfile = Join-Path $Logpath $HotfixLogName
			$CABFileName = "Windows6.1-KB2592525-x64.cab"
			$CABFile = Join-Path $Ly2013_PreReqPath $CABFileName
			"Expanding .msu-file to $Ly2013_PreReqPath" | Write-BLLog
			$Expand = expand $MSUFile –F:* $Ly2013_PreReqPath
			"Testing path for the CAB-File. Invoking: Test-Path $CABFile" | Write-BLLog
			$TestPath = Test-Path $CABFile
			if ($TestPath -eq $True) {
				$Arguments = "/ip /m:$CABFile /quiet /norestart /l:$Logfile"
				$FileName = "C:\Windows\System32\PkgMgr.exe"
				"CAB-File exists in the folder. Invoking: Start-BLProcess -FileName $FileName -Arguments $Arguments" | Write-BLLog
				$ExitCode = Start-BLProcess -FileName $FileName -Arguments $Arguments
			}
		} else {
			"Update $HFInst was installed previously. Installation will be canceled." | Write-BLLog
			$ExitCode = 0			
		} 
	}
	if (($ExitCode -eq 0) -OR ($ExitCode -eq 3010)) {
		if ($ExitCode -eq 3010) {
			$LogType = "Warning"
			"A reboot is necessary to complete the installation of the hotfix(es)."	 | Write-BLLog -LogType $LogType
		}
		$MSUNr = "KB2670838"
		$MSUKB = "2670838"
		"Searching for a Installation of $MSUNr on the system." | Write-BLLog 
		"Invoking: Get-HotFix $MSUNr -ErrorAction SilentlyContinue" | Write-BLLog
		$InstalledKB = Get-HotFix $MSUNr -ErrorAction SilentlyContinue
		if ($InstalledKB) {
			"Update $MSUKB is installed. Uninstallation starts now. Invoking:" | Write-BLLog
			"Uninstall-BLWindowsHotfix -MSUKB $MSUKB -LogFile $LogFile" | Write-BLLog
			$Exitcode = Uninstall-BLWindowsHotfix -MSUKB $MSUKB -LogFile $LogFile
		} else {
			"Update $MSUNr is not installed. Uninstallation not necessary." | Write-BLLog
			Return 0
		}
	}
	
#endregion installation
	Return $ExitCode
}

#region Uninstallation
Function Invoke-ISUninstallation () {
	$ExitCode = 1
	#Setting Variables for Logging
	$Logpath = "C:\RIS\Log\"
	$Ly2013_PreReqPath = $AppSource + "\Source"

	#Searching for Updates - .msu-files - in the "Source" folder
	$Ly2013_WinUpdates = Get-ChildItem $Ly2013_PreReqPath -ErrorAction Stop | Where {$_.Name -like "*.msu"} | Select-Object Name | findstr ".msu"

	#One or more found in the "Source" folder?
	if (!($Ly2013_WinUpdates.length)){
		"No Hotfixfile found. Installation will be aborted." | Write-BLLog -LogType CriticalError
		Return 1
	}	
	foreach ($Hotfix in $Ly2013_WinUpdates) {
		$HotFix = $HotFix.trim()
		$HF = $HotFix.split("-")
		$HFInst = $HF[1]
		$Installed = Get-Hotfix $HFInst -ErrorAction Silentlycontinue		
		if (!$Installed) { 
			"Update $HFInst is not installed. Uninstallation will be canceled." | Write-BLLog
			$ExitCode = 0
		} else {
			"Update $HFInst is installed.  Uninstallation can be started." | Write-BLLog
			"Starting uninstallation of update $HFInst." | Write-BLLog
			$MSUFile = Join-Path $Ly2013_PreReqPath $Hotfix
			$HotFixLogName = $Hotfix + ".evt"
			$Logfile = Join-Path $Logpath $HotfixLogName
			$Exitcode = Uninstall-BLWindowsHotfix -MSUFile $MSUFile -LogFile $LogFile
		}
	}
	"Reinstallation is unprovided for Update KB2670838. Please install it manual again if you need it."  | Write-BLLog -LogType Warning
#	Return $ExitCode
Return $ExitCode
}
#endregion


#region MAIN
## ====================================================================================================
## MAIN
## ====================================================================================================

 
	If (-Not $Uninstall) {
		$ExitCode = Invoke-ISInstallation
	} Else {
		$ExitCode = Invoke-ISUninstallation
	}
#endregion MAIN
$Type = $ExitCode.GetType()
Write-Host $Type
Write-Host $ExitCode -foregroundcolor yellow
$ExitCode = Test-BLLYExitCode -ExitCode $ExitCode
	
"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
