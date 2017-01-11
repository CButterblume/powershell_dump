<#
.SYNOPSIS
Installation of necessary Tools. Actually this tools are installed:

LyncDebugTools.msi 	-	Microsoft Lync Server 2013, Debugging Tools
rtcbpa.msi			-	Microsoft Lync Server 2013, Best Practices Analyzer
OCSReskit.msi		- 	Microsoft Lync Server 2013, Resource Kit Tools

.DESCRIPTION
Autor: stefan.schmalz@interface-ag.de

This script installs the Tools for the installation of Lync 2013. Actually these are the tools:
LyncDebugTools.msi 	-	Microsoft Lync Server 2013, Debugging Tools
rtcbpa.msi			-	Microsoft Lync Server 2013, Best Practices Analyzer
OCSReskit.msi		- 	Microsoft Lync Server 2013, Resource Kit Tools

For Lync Debug Tools a installation of Microsoft Lync is presupposed.
For Lync Best Practice Analyser presupposed a installation of:

- .NET 4.5
- Lync Server 2013 Core Components

Weiter kopiert das Script die Dateien "default.tmx" und "default.xml" von 
C:\Program Files\Common Files\Microsoft Lync Server 2013\Tracing 
nach 
C:\Program Files\Microsoft Lync Server 2013\Debugging Tools

.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 

.EXAMPLE
install-Script -Force					Installation der Tools
install-Script -Uninstall -Force		Deinstallation der Tools

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
## Date					Version		By							Change Description
## --------------------------------------------------------------------------------------
## 31.05.2016			baumh									Initial version
## 12.09.2016			0.0.0.12	Stefan Schmalz (IF)			Skriptgerüst fertig, Tests folgen.
## 14.09.2016			1.0.0.0		Stefan Schmalz (IF)			Skript fertig, Fehler beim Kopiervorgang gefixt.
## --------------------------------------------------------------------------------------
## CUSTOMIZE: Add the change date and an overview of your changes to the table above, and add a description of what the script does here:
##

## CUSTOMIZE: delete ranges (#region ... #endregion) you do not need

## CUSTOMIZE: Add supported arguments for the script here (do not remove the -Force or -Uninstall arguments):
[CmdletBinding()]
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
Initialize-BLFunctions -AppName "MS_LYNC2013_FE_Tools" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.

"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

Function Invoke-ISInstallation() {
## Make sure that $ExitCode is ONLY 0 if the install was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.

	## CUSTOMIZE: Check here if the software is installed; you can use "Get-Help Get-BLUninstallInformation -Full" for more complex options, like specific x86/x64 versions,
	## query by GUID, a specific version, or a Hotfix. Comment out if not required.
	$ExitCode = 1
	$LogType = "Information"
	
#region Customized installation. Use this part for normal installations, delete it otherwise
	$Source = "Source"
	$SourcePath = Join-Path $AppSource $Source
	$Files = Get-ChildItem $SourcePath
	$AppDisplayName = "Microsoft Lync Server 2013, Front End Server"
	$DisplayNameCoreComponents = "Microsoft Lync Server 2013, Core Components"
	$UninstallInformation = Get-BLUninstallInformation -DisplayName $AppDisplayName
	$InstInfoCC = Get-BLUninstallInformation -DisplayName $DisplayNameCoreComponents
	
	#Lync Best Practice Analyser
	Import-Module (Join-Path $AppSource "/NetCheck.psm1")
	$InstalledFrameworks = Get-InstalledNetFrameworks
	if (-Not ($InstalledFrameworks -match $DotNet4_5)) {
		"Required .Net Framework Version 4.5 is missing - please install it first!" | Write-BLLog -LogType Error
		$ExitCode = 1
	} else {
		"Required .NET Framework 4.5 is installed - Prerequisite for Lync Best Practice Analyser is given" | Write-BLLog -LogType Information
		if ($InstInfoCC.IsInstalled) {
			"Required 'Microsoft Lync Server 2013, Core Components' are installed - Prerequisite 1 for Lync Debug Tools is given." | Write-BLLog -LogType Information	
			If ($UninstallInformation.IsInstalled) {
				"Required $AppDisplayName is installed -  Prerequisite 2 for Lync Debug Tools is given and they can be installed now." | Write-BLLog -LogType Information	
				foreach ($File in $Files) {
				
					$Software = @{ "LyncDebugTools.msi" = "Microsoft Lync Server 2013, Debugging Tools"; `
								   "rtcbpa.msi" = "Microsoft Lync Server 2013, Best Practices Analyzer"; `
								   "OCSReskit.msi" = "Microsoft Lync Server 2013, Resource Kit Tools" }
					$DisplayName = $Software.Get_Item([string]$File)
					$InstInfoSW = Get-BLUninstallInformation -DisplayName $DisplayName
					if ($InstInfoSW.IsInstalled) {
						"Software - $DisplayName is already installed. Installation will be skipped." | Write-BLLog -LogType Warning
						$ExitCode = 0
					} else {
						$InstType = "/i"
						$MsiFile = Join-Path $SourcePath $File
						$ExitCode = Invoke-BLSetupMsi -MsiFile $MsiFile -InstType $InstType
						Test-BLLYExitCode -ExitCode $ExitCode -NoReturn
					}
				}
			} else {
				"$AppDisplayName is not installed. It is a prerequisite for the Lync Debug Tools. Please install $AppDisplayName first." | Write-BLLog -LogType Error
				Return 1
			}
		
		
		} else {
			"Microsoft Lync Server 2013, Core Components - are not installed yet. They are a prerequisite for Lync Best Practice Analyser. Please install them first." | Write-BLLog -LogType Error
			Return 1
		}
	}
	$Files = "default.tmx", "default.xml"
	$SDirPart1 = $Env:CommonProgramFiles
	$SDirPart2 = "Microsoft Lync Server 2013\Tracing"
	$DDirPart1 = $Env:ProgramFiles
	$DDirPart2 = "Microsoft Lync Server 2013\Debugging Tools"
	$SDir = Join-Path $SDirPart1 $SDirPart2
	$DDir = Join-Path $DDirPart1 $DDirPart2
	"Copying necessary files ($Files) from: '$SDIR' to '$DDir'" | Write-BLLog -LogType $LogType
	try {
		foreach ($File in $Files) {
			$Source = Join-Path $SDir $File
			$Destination = Join-Path $DDir $File
			$TestPath = Test-Path $Source
			"Copying $Source to $Destination." | Write-BLLog -LogType $LogType
			Copy-Item $Source -Destination $Destination
		}
	} catch {
		$LogType = "Error"
		$ErrorMessage = $_.Exception.Message
		"An error occured while creating the DFS folder. Error: $ErrorMessage" | Write-BLLog -LogType $LogType
		Return 1
	}
	Return $ExitCode
}
#endregion Installation


#region Uninstallation
Function Invoke-ISUninstallation() {
## Make sure that $ExitCode is ONLY 0 if the uninstall was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.
	
	## CUSTOMIZE: Check here if the software is installed; you can use "Get-Help Get-BLUninstallInformation -Full" for more complex options, like specific x86/x64 versions,
	## query by GUID, a specific version, or a Hotfix. Comment out if not required.
	$ExitCode = 0

#region Customized installation. Use this part for normal installations, delete it otherwise
		$Software = @{"Microsoft Lync Server 2013, Debugging Tools" = "{5043B30E-AD39-4251-8807-A2B8184E48B7}"; `
					  "Microsoft Lync Server 2013, Best Practices Analyzer" = "{597568A4-CECE-4179-99DA-C8D27382C2DB}"; `
					  "Microsoft Lync Server 2013, Resource Kit Tools" = "{72C84263-9F4D-4475-937E-1AEA029FE256}" }
		$Keys = $Software.Get_Keys()
		
		foreach ($Key in $Keys) {
			$UninstallInformation = Get-BLUninstallInformation -DisplayName $Key
			if (-Not $UninstallInformation.IsInstalled) {
				"Software is not installed - uninstallation not necessary!" | Write-BLLog -LogType Information	
				$ExitCode = 0
			} else {
				$InstType = "/x"
				$MsiGUID = $Software.Get_Item($Key)
				$ExitCode = Invoke-BLSetupMsi -MsiGUID $MsiGUID -InstType $InstType
				Test-BLLYExitCode -ExitCode $ExitCode -NoReturn
			}
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

$ExitCode = Test-BLLYExitCode -ExitCode $ExitCode

"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
