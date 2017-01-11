<#
.SYNOPSIS
(Un-)Installation that are required WindowsFeatures for Exchange 2013 depending on the role that will be installed on the server.

.DESCRIPTION
Autor: stefan.schmalz@interface-ag.de

The script starts the (un-)installation that are required WindowsFeatures for Exchange 2013 depending on the role that will be installed on the server.
It will install these features for

Edge Transport Server:
01. ADLDS

Multirole Server:
01. Desktop-Experience
02. NET-Framework
03. NET-HTTP-Activation
04. RPC-over-HTTP-proxy
05. RSAT-WebServer
06. RSAT-Clustering
07. WAS-Process-Model
08. Web-Asp-Net
09. Web-Basic-Auth
10. Web-Client-Auth
11. Web-Digest-Auth
12. Web-Dir-Browsing
13. Web-Dyn-Compression
14. Web-Http-Errors
15. Web-Http-Logging
16. Web-Http-Redirect
17. Web-Http-Tracing
18. Web-ISAPI-Ext
19. Web-ISAPI-Filter
20. Web-Lgcy-Mgmt-Console
21. Web-Metabase
22. Web-Mgmt-Console
23. Web-Mgmt-Service
24. Web-Net-Ext
25. Web-Request-Monitor
26. Web-Server
27. Web-Stat-Compression
28. Web-Static-Content
29. Web-Windows-Auth
30. Web-WMI
31. BranchCache
32. BITS-IIS-EXT - For Uninstall: This feature is uninstalled first cause of dependencies to other features.
33. Failover-Clustering
34. RSAT-ADDS

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
The script created a logfile:_"C:\RIS\Log\Ex2013_PreReq_WinFeature.log"

.NOTES
To run the script you have to be a member of the local administrator group and you have to run the powershell with elevated rights.
ATTENTION: This script requires the new BaseLibraryEXCHANGE.psm1. Please copy it to C:\RIS\Lib before you run the script.
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
## 01.06.2016	V0.0.0.1 S. Schmalz (IF)	Datei angelegt, Skriptkopf eingefuegt.
## 08.06.2016	V0.0.0.2 S. Schmalz (IF)	Daten in das install-Script übernommen und Error-Handling hinzugefuegt.
## 24.06.2016	V0.0.0.3 S. Schmalz (IF)	Da der Exitcode ungleich der der MSI-Setups ist musste das umgeschrieben werden.
##
##
## endregion Version Management


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

#Logging Variables
$LoggingPath = "C:\RIS\Log"
$InstLogName = "MS_EXCH2013_Prereq_WindowsFeatures_Inst.log"
$DeInstLogName = "MS_EXCH2013_Prereq_WindowsFeatures_DeInst.log"
$LogPathInst = Join-Path $LoggingPath $InstLogName
$LogPathDeInst = Join-Path $LoggingPath $DeInstLogName
$RebootPending = Get-BLComputerPendingReboot | findstr "True"

## CUSTOMIZE: Edit value for the AppName parameter <Appname> below; use only characters allowed in file names, no spaces:
Initialize-BLFunctions -AppName "MS_EXCH2013_Prereq_WindowsFeatures" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

Function Invoke-ISInstallation() {
	$LoggingPath = "C:\RIS\Log"
	$InstLogName = "MS_EXCH2013_Prereq_WindowsFeatures_Inst.log"
	$LogPathInst = Join-Path $LoggingPath $InstLogName
	$RebootPending = Get-BLComputerPendingReboot | findstr "True"
	$Role = $cfg["EX2013_INSTALL_ROLE"]
	 if (!$RebootPending) {
		if ($Role -eq "MR") {
			$LogType = "Information"
			"There is no Reboot pending. Installation can begin now." | Write-BLLog -LogType $LogType
			"Importing ServerManager Powershell Module." | Write-BLLog -LogType $LogType
			Import-Module ServerManager
			"Installing required Windows Features for a Multirole Server (Mailbox and Client Access Server)." | Write-BLLog -LogType $LogType
			"Invoking: Add-WindowsFeature Desktop-Experience, NET-Framework, NET-HTTP-Activation, RPC-over-HTTP-proxy, RSAT-Web-Server, RSAT-Clustering, WAS-Process-Model, Web-Asp-Net, `
			 Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, `
			 Web-ISAPI-Filter, Web-Lgcy-Mgmt-Console, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, Web-Net-Ext, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, `
			 Web-Windows-Auth, Web-WMI, BranchCache, BITS-IIS-EXT, Failover-Clustering, RSAT-ADDS -LogPath $LogPathInst" | Write-BLLog -LogType $LogType
			$Success  = Add-WindowsFeature Desktop-Experience, NET-Framework, NET-HTTP-Activation, RPC-over-HTTP-proxy, RSAT-Web-Server, RSAT-Clustering, WAS-Process-Model, Web-Asp-Net, Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Lgcy-Mgmt-Console, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, Web-Net-Ext, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, Web-Windows-Auth, Web-WMI, BranchCache, BITS-IIS-EXT, Failover-Clustering, RSAT-ADDS -LogPath $LogPathInst
			If ($Success.Success -eq "True") {
				$ExitCode = $Success.ExitCode
			} elseif ($Success.Success -eq "False") {
				$ExitCode = $Success.ExitCode
				$LogType = "Error"
				"The Installation was not successful. The Installation process returned this Exitcode: $ExitCode" | Write-BLLog -LogType $LogType
			}
		} elseif ($Role -eq "ET") {
			$LogType = "Information"
			"There is no Reboot pending. Installation can begin now." | Write-BLLog -LogType $LogType
			"Importing ServerManager Powershell Module." | Write-BLLog -LogType $LogType
			Import-Module ServerManager
			"Installing required Windows Features for a Edge Transport Server." | Write-BLLog -LogType $LogType
			"Invoking: Add-WindowsFeature ADLDS -LogPath $LogPathInst" | Write-BLLog -LogType $LogType
			$Success  = Add-WindowsFeature ADLDS -LogPath $LogPathInst
			If ($Success.Success -eq "True") {
				$ExitCode = $Success.ExitCode
			} elseif ($Success.Success -eq "False") {
				$ExitCode = $Success.ExitCode
				$LogType = "Error"
				"The Installation was not successful. The Installation process returned this Exitcode: $ExitCode" | Write-BLLog -LogType $LogType
			}
		} else {
			$LogType = "Error"
			"The specified Role in the configdb variable 'EX2013_INSTALL_ROLE' is neither 'ET' nor 'MR'. Please correct that. We cancel the installation now." | Write-BLLog -LogType $LogType
			Return 1
		}
	} else {
		$LogType = "Error"
		"A Reboot is pending. Take a look at the table: $RebootPending . Reboot the system and rerun the installation again." | Write-BLEventLog -LogType $LogType
		"A Reboot is pending. Take a look at the table: $RebootPending . Reboot the system and rerun the installation again." | Write-BLLog -LogType $LogType
		Return 1        
	}
	Return $ExitCode
}

Function Invoke-ISUninstallation() {
	$LoggingPath = "C:\RIS\Log"
	$DeInstLogName = "MS_EXCH2013_Prereq_WindowsFeatures_DeInst.log"
	$LogPathDeInst = Join-Path $LoggingPath $DeInstLogName
	$RebootPending = Get-BLComputerPendingReboot | findstr "True"  
	$Role = $cfg["EX2013_INSTALL_ROLE"]
	
    if (!$RebootPending) {
		if ($Role -eq "MR") { 
			$LogType = "Information"
			"There is nor Reboot pending. Uninstallation can begin now." | Write-BLLog -LogType $LogType
			Import-Module ServerManager
			$LogType = "Information"
			"The Windows feature BITS-IIS-EXT is removed first because of dependencies to the other features." | Write-BLLog -LogType $LogType
			$Success1 = Remove-WindowsFeature BITS-IIS-EXT -LogPath $LogPathDeInst
			if ($Success1.Success -eq "True") {
				$LogType = "Information"
				"The other Windows features are removed now." | Write-BLLog -LogType $LogType
				$Success = Remove-WindowsFeature Desktop-Experience, NET-Framework, NET-HTTP-Activation, RPC-over-HTTP-proxy, RSAT-Web-Server, RSAT-Clustering, WAS-Process-Model, Web-Asp-Net, Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Lgcy-Mgmt-Console, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, Web-Net-Ext, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, Web-Windows-Auth, Web-WMI, BranchCache, Failover-Clustering, RSAT-ADDS -LogPath $LogPathDeInst
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
				"An error occured while uninstalling the feature BITS-IIS-EXT. The uninstallation of the other features will be stopped because of depenencies." | Write-BLLog -LogType $LogType
			}
		} elseif ($Role -eq "ET") {
			$Success = Remove-WindowsFeature ADLDS
			If ($Success.Success -eq "True") {
				$LogType = "Information"
				"Everything fine. The uninstallation of the WindowsFeature has run without errors." | Write-BLLog -LogType $LogType
			} else {
				$LogType = "Error"
				"An error occured while uninstalling Windows Features. Take a look at the logfiles." | Write-BLLog -LogType $LogType
			}			
		} else {
			$LogType = "Error"
			"The specified Role in the configdb variable 'EX2013_INSTALL_ROLE' is neither 'ET' nor 'MR'. Please correct that. We cancel the installation now." | Write-BLLog -LogType $LogType
			Return 1			
		}

    } else {
        $LogType = "Error"
        "A Reboot is pending. Take a look at the table: $RebootPending . Reboot the system and rerun the installation again." | Write-BLEventLog -LogType $LogType
        "A Reboot is pending. Take a look at the table: $RebootPending . Reboot the system and rerun the installation again." | Write-BLLog -LogType $LogType
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

#ExitCode(s) werden getestet.
$ExitCode = Test-BLEXExitCode -ExitCode $ExitCode

"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode