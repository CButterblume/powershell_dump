<#
.SYNOPSIS
Installation of necessary Software. Actually these are necessary:

- vcredist_x64.exe - Microsoft Visual C++ 2012 x64 Minimum Runtime -  11.0.50727 
- SQLSysClrTypes.msi 
- SharedManagementObjects.msi 
- OCSCore.msi 
- AdminTools.msi 

The MSIs have to be installed in this sequence and deinstalled in the reversed sequence.

.DESCRIPTION
Autor: stefan.schmalz@interface-ag.de

This script installs the necessary Software for the installation of Lync 2013. Actually these are necessary:

ATTENTION: The script presuppose the names of the MSI files like they are mentioned here.
- vcredist_x64.exe - Microsoft Visual C++ 2012 x64 Minimum Runtime -  11.0.50727 
- SQLSysClrTypes.msi 
- SharedManagementObjects.msi 
- OCSCore.msi 
- AdminTools.msi 

The MSIs have to be installed in this sequence and deinstalled in the reversed sequence.


A Reboot is required after the installation.

.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 

.EXAMPLE
install-Script -Force					Installation der Software
install-Script -Uninstall -Force		Deinstallation der Software

.OUTPUTS
The script writes some logifles in C:\RIS\Log.

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
## Date					Version	By						Change Description
## --------------------------------------------------------------------------------------
## 01.08.2016			Stefan Schmalz (IF)				Initial version
## 01.08.2016			0.0.1	Stefan Schmalz (IF)		Aufgeräumt, nicht genutzten Code gelöscht
## 30.11.2016			1.0.0.0 Stefan Schmalz (IF)		Paket fertig.
## --------------------------------------------------------------------------------------
## CUSTOMIZE: Add the change date and an overview of your changes to the table above, and add a description of what the script does here:
##

## CUSTOMIZE: delete ranges (#region ... #endregion) you do not need

## CUSTOMIZE: Add supported arguments for the script here (do not remove the -Force or -Uninstall arguments):
[CmdletBinding(SupportsShouldProcess=$True)]
Param(
	[switch]$Force,
	[switch]$Uninstall
)
$VerbosePreference = "Continue"


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
Initialize-BLFunctions -AppName "MS_LYNC2013_PreReq_AdminTools" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
$AppDisplayName = "MS_LYNC2013_PreReq_AdminTools"
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

#region Installation
Function Invoke-ISInstallation() {
	$LogType = "Information"
	$Sourcefolder = "Source"
	$SourcePath =  Join-Path $AppSource $Sourcefolder
	"Searching for MSI-files in the folder: $SourcePath" | Write-BLLog -LogType $LogType
	try {
		$EXEFile = Get-ChildItem $SourcePath -ErrorAction Stop | Where {$_.Name -like "*.exe"} | Select-Object Name | findstr ".exe"
		if ($EXEFile) {
			"Found these Exe-files: $EXEFile" | Write-BLLog -LogType $LogType
		}
	} catch {
		$LogType = "Error"
		"An error occured while searching for an .exe file in the source folder: `r`n $ErrorMessage"  | Write-BLLog -LogType $LogType
		"$Error" | Write-BLLog -LogType Error
		$Error.clear()
		Return 1
	}
	
	
	$Redist2012 = "Microsoft Visual C++ 2012 Redistributable (x64) - 11.0.50727"
	$UninstInfo_Redist2012 = Get-BLUninstallInformation -DisplayName $Redist2012

	If ($UninstInfo_Redist2012.IsInstalled -eq $True) {
		"Software is already installed - installation not necessary!" | Write-BLLog -LogType Information	
		$ExitCode = 0
	} else {
		## CUSTOMIZE: Add installation code here.
		$FileName = Join-Path $SourcePath $EXEFile
		$Arguments = "/install /passive /norestart"
		$ExitCode = Invoke-BLSetupOther -FileName $FileName -Arguments $Arguments
	}
	
	If (($ExitCode -eq 3010) -OR ($ExitCode -eq 0)) {
		$MSIFiles = Get-ChildItem $SourcePath -ErrorAction Stop | Where {$_.Name -like "*.msi"} | Select-Object Name | findstr ".msi"
		if ($MSIFiles) {
			"Found these MSI-files for installation: $MSIFiles" | Write-BLLog -LogType $LogType
		}		
		[array]::Reverse($MSIFiles)

		$Count = $MSIFiles.Count
		
		$Software = @{"adminTools.msi" = "Microsoft Lync Server 2013, Administrative Tools";
					  "OCScore.msi" = "Microsoft Lync Server 2013, Core Components";
					  "SharedManagementObjects.msi" = "Microsoft SQL Server 2012 Management Objects  (x64)";
					  "SQLSysClrTypes.msi" = "Microsoft System CLR Types for SQL Server 2012 (x64)"}
		$i = 0
		while ($i -lt $Count) {
			$MSIFile = Join-Path $SourcePath $MSIFiles[$i]
			$SW_MSI = $MsiFiles[$i].trim()
			$DisplayName = $Software.Get_Item($SW_MSI)
			$UninstallInformation = Get-BLUninstallInformation -DisplayName $DisplayName
			if ($UninstallInformation.IsInstalled -eq $True) {
				"Software - $DisplayName - is already installed - installation not necessary!" | Write-BLLog -LogType $LogType	
				$ExitCode = 0
			} else {			
				"The software - $DisplayName - is not installed. Trying to install it now." | Write-BLLog -LogType $LogType	
				$ExitCode = Invoke-BLSetupMsi -MsiFile  $MSIFile
				"After the installation of - $DisplayName - we are testing the ExitCode for errors."  | Write-BLLog -LogType $LogType
				Test-BLLYExitCode -ExitCode $ExitCode
			}
			$i++
		}
	} else {
		"An error occured while installing $Redist2012. Take a look at the logfiles." | Write-BLLog -LogType Error
		Return 1
	}

	Return $ExitCode
}
#endregion Installation

#region Uninstallation
Function Invoke-ISUninstallation() {

$Software = @{"Microsoft Lync Server 2013, Administrative Tools" = "{6408FD69-B5A4-48C7-9484-F3EA3C847279}";
			  "Microsoft Lync Server 2013, Core Components"	= "{8901ADFC-435C-4E37-9045-9E2E7A613285}";
			  "Microsoft SQL Server 2012 Management Objects  (x64)" = "{FA0A244E-F3C2-4589-B42A-3D522DE79A42}";
			  "Microsoft System CLR Types for SQL Server 2012 (x64)" = "{F1949145-EB64-4DE7-9D81-E6D27937146C}";
			  "Microsoft Visual C++ 2012 Redistributable (x64) - 11.0.50727" = "{AC53FC8B-EE18-3F9C-9B59-60937D0B182C}"}
			  $SoftwareName = $Software.Get_Keys() | Sort-Object
	foreach ($SW in $SoftwareName) {
		$UninstallInformation = Get-BLUninstallInformation -DisplayName $SW
		If (-Not $UninstallInformation.IsInstalled) {
			"Software - $SW - is not installed - uninstallation not necessary!" | Write-BLLog -LogType Information	
			$ExitCode = 0
		} else {
			"Software - $SW - is installed - trying to uninstall the software!" | Write-BLLog -LogType Information
			$InstType = "/x"
			$MsiGUID = $Software.Get_Item($SW)
			$ExitCode = Invoke-BLSetupMsi -InstType $InstType -MsiGUID $MsiGUID
			Test-BLLYExitCode -ExitCode $ExitCode
		}
	}
	Return $ExitCode
}
#endregion Uninstallation

#region Main
## ====================================================================================================
## MAIN
## ====================================================================================================
	If (-Not $Uninstall) {
		$ExitCode = Invoke-ISInstallation
	} Else {
		$ExitCode = Invoke-ISUninstallation
	}
#endregion Main	
Write-Host "ExitCode: $ExitCode"
if ($ExitCode) {
	$ExitCode = Test-BLLYExitCode $ExitCode
} else {

}

"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
