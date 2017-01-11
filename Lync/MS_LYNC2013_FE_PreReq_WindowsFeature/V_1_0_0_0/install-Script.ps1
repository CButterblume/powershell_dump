<#
.SYNOPSIS
(Un-)Installation that are required WindowsFeatures for Lync 2013 FrontEnd Server


.DESCRIPTION
Autor: stefan.schmalz@interface-ag.de

The script starts the (un-)installation that are required WindowsFeatures for Lync 2013 FrontEnd Server:
01. Web-Server
02. Web-Static-Content
03. Web-Default-Doc
04. Web-Scripting-Tools
05. Web-Windows-Auth
06. Web-Asp-Net
07. Web-Log-Libraries
08. Web-Http-Tracing
09. Web-Stat-Compression
10. Web-Dyn-Compression
11. Web-ISAPI-Ext
12. Web-ISAPI-Filter
13. Web-Http-Errors
14. Web-Http-Logging
15. Web-Net-Ext
16. Web-Client-Auth
17. Web-Filtering
18. Web-Mgmt-Console
19. Telnet-Client
20. RSAT-AD-Tools
21. Desktop-Experience

A Reboot is required after the installation.

.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 

.EXAMPLE
install-Script.ps1 -Force				Installation
install-Script.ps1 -Uninstall -Force	Uninstallation

.OUTPUTS
The script created a logfile: "C:\RIS\Log\MS_LYNC2013_FE_Prereq_WindowsFeatures.log"

.NOTES
To run the script you have to be a member of the local administrator group and you have to run the powershell with elevated rights.
ATTENTION: This script requires the new BaseLibraryLYNC.psm1. Please copy it to C:\RIS\Lib before you run the script.
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
## 28.07.2016	V0.0.0.1	S. Schmalz (IF)		Datei angelegt, Skriptkopf eingefuegt.
## 31.08.2016	V1.0.0.0 	S. Schmalz (IF)		Skript fertig
##
## endregion Version Management


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

#Logging Variables
$LoggingPath = "C:\RIS\Log"
$InstLogName = "MS_LYNC2013_FE_Prereq_WindowsFeatures_Inst.log"
$DeInstLogName = "MS_LYNC2013_FE_Prereq_WindowsFeatures_Deinst.log"
$LogPathInst = Join-Path $LoggingPath $InstLogName
$LogPathDeInst = Join-Path $LoggingPath $DeInstLogName
$RebootPending = Get-BLComputerPendingReboot | findstr "True"

## CUSTOMIZE: Edit value for the AppName parameter <Appname> below; use only characters allowed in file names, no spaces:
Initialize-BLFunctions -AppName "MS_LYNC2013_FE_Prereq_WindowsFeatures" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

Function Invoke-ISInstallation($LogPathInst,$RebootPending) {
     if (!$RebootPending) {
        $LogType = "Information"
        "There is no Reboot pending. Installation can begin now." | Write-BLLog -LogType $LogType
	    Import-Module ServerManager
	    $Success  = Add-WindowsFeature Web-Server, Web-Static-Content, Web-Default-Doc, Web-Scripting-Tools, Web-Windows-Auth,Web-Asp-Net, Web-Log-Libraries, Web-Http-Tracing, Web-Stat-Compression, Web-Dyn-Compression, Web-ISAPI-Ext,Web-ISAPI-Filter, Web-Http-Errors, Web-Http-Logging, Web-Net-Ext, Web-Client-Auth, Web-Filtering, Web-Mgmt-Console, Telnet-Client, RSAT-AD-Tools, Desktop-Experience -LogPath $LogPathInst
		$ExitCode = $Success.ExitCode
	    If ($Success.Success -eq "True") {
		    "The installation of the windows features was successful." | Write-BLLog -LogType $LogType
        } elseif ($Success.Success -eq "False") {
            $LogType = "Error"
            "The Installation was not successful. The Installation process returned this Exitcode: $ExitCode" | Write-BLLog -LogType $LogType
        }
    } else {
        $LogType = "Error"
        "A Reboot is pending. Take a look at the table: $RebootPending . Reboot the system and rerun the installation." | Write-BLEventLog -LogType $LogType
        "A Reboot is pending. Take a look at the table: $RebootPending . Reboot the system and rerun the installation." | Write-BLLog -LogType $LogType
		Return 1        
    }
	Return $ExitCode
}

Function Invoke-ISUninstallation($LogPathDeInst,$RebootPending) {
    
    if (!$RebootPending) {
        $LogType = "Information"
        "There is no reboot pending. Uninstallation can begin now." | Write-BLLog -LogType $LogType
	    Import-Module ServerManager
        $LogType = "Information"
            $LogType = "Information"
		    "The Windows features are removed now." | Write-BLLog -LogType $LogType
		    $Success = Remove-WindowsFeature Web-Server, Web-Static-Content, Web-Default-Doc, Web-Scripting-Tools, Web-Windows-Auth,Web-Asp-Net, Web-Log-Libraries, Web-Http-Tracing, Web-Stat-Compression, Web-Dyn-Compression, Web-ISAPI-Ext,Web-ISAPI-Filter, Web-Http-Errors, Web-Http-Logging, Web-Net-Ext, Web-Client-Auth, Web-Filtering, Web-Mgmt-Console, Telnet-Client, RSAT-AD-Tools, Desktop-Experience -LogPath $LogPathDeInst
		    #endregion
		    $ExitCode = $Success.Exitcode
		    If ($Success.Success -eq "True") {
			    $LogType = "Information"
			    "Everything fine. The uninstallation of the WindowsFeatures has run without errors." | Write-BLLog -LogType $LogType
		    } else {
			    $LogType = "Error"
			    "An error occured while uninstalling Windows Features. Take a look at the logfiles." | Write-BLLog -LogType $LogType
		    }
    } else {
        $LogType = "Error"
        "A Reboot is pending. Take a look at the table: $RebootPending . Reboot the system and rerun the uninstallation." | Write-BLEventLog -LogType $LogType
        "A Reboot is pending. Take a look at the table: $RebootPending . Reboot the system and rerun the uninstallation." | Write-BLLog -LogType $LogType
		Return 1
    }
    Return $ExitCode
}

## ====================================================================================================
## MAIN
## ====================================================================================================
## CUSTOMIZE: Uncomment to get information from ConfigDB if required (use of Defaults.txt is optional).
## - The use of Defaults.txt and Write-BLConfigDBSettings is optional
## - Add a filter to Write-BLConfigDBSettings to only show required variables (will filter ConfigDB variables beginning with this value)


	If (-Not $Uninstall) {
		$ExitCode = Invoke-ISInstallation -LogPath $LogPathInst -RebootPending $RebootPending
	} Else {
		$ExitCode = Invoke-ISUninstallation -LogPath $LogPathDeInst -RebootPending $RebootPending
	}

#ExitCode(s) werden getestet.
$ExitCode = Test-BLLYExitCode -ExitCode $ExitCode

"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode