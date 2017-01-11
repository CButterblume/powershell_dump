<#
.SYNOPSIS
This script sets the necessary SRV Records.

.DESCRIPTION
This script sets the Service Location (SRV) Record:
_sip._tls

The script also sets a SRV Record for the Edge Transport Server Pool depending of the servers data center.

.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 

.EXAMPLE
install-Script.ps1 -Force
install-Script.ps1 -Uninstall

.OUTPUTS
The installation writes logs in the folder "C:\RIS\Log". One for the Skript and one for the task.

.NOTES
ATTENTION: The user that runs this script has to be a member of the group local Admins.
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
Initialize-BLFunctions -AppName "MS_LYNC2013_ET_PreReq_DNSSrvRecordSSADom" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.

"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

#region Installation
Function Invoke-ISInstallation() {
	$LogType = "Information"
	$ExitCode = 1
	$ETPoolName = $cfg["LYNC2013_CFG_ET_POOL_NAME"]
	$ZoneName = $cfg["DOMAIN_FQDN"]
	$EdgeServerSIPName = $cfg["LYNC2013_CFG_ET_SIPNAME"]
	$OfferingHost = $EdgeServerSIPName + "." + $ZoneName
	$ComputerName = Get-BLADDomainController
	$SRVRecord = "LYNC2013_CFG_ET_SRVRECORD"

	#ServiceName;Protocol;Priority;Weight;Portnummer
	$Name = $cfg["$SRVRecord"].Split(";")[0]
	$Protocol = $cfg["$SRVRecord"].Split(";")[1]
	$Priority = $cfg["$SRVRecord"].Split(";")[2]
	$Weight = $cfg["$SRVRecord"].Split(";")[3]
	$Port = $cfg["$SRVRecord"].Split(";")[4]

	 "Searching for existing SRV-Records." | Write-BLLog -LogType $LogType
	 "Invoking: Get-BLLYSRVRecord -Name $Name -Protocol $Protocol -ZoneName $ZoneName -ComputerName $ComputerName" | Write-BLLog -LogType $LogType
	$RecordTest = Get-BLLYSRVRecord -Name $Name -Protocol $Protocol -ZoneName $ZoneName -ComputerName $ComputerName
	if ([string]$RecordTest -eq "DnsServerResourceRecord") {
		"SRV-Record for - $Name - already exists. Skipping creation..." | Write-BLLog -LogType $LogType
		$ExitCode = 0
	} else {
		"SRV-Record for - $Name - does not exist. Setting the Record now." | Write-BLLog -LogType $LogType
		"Invoking: Add-BLLYSRVRecord -Name $Name -Protocol $Protocol -Priority $Priority -Weight $Weight -Port $Port -OfferingHost $OfferingHost -ZoneName $ZoneName -ComputerName $ComputerName" | Write-BLLog -LogType $LogType
		$ExitCode = Add-BLLYSRVRecord -Name $Name -Protocol $Protocol -Priority $Priority -Weight $Weight -Port $Port -OfferingHost $OfferingHost -ZoneName $ZoneName -ComputerName $ComputerName
	} 
	Return $ExitCode
}
#endregion Installation

#region Uninstallation
Function Invoke-ISUninstallation() {
	$LogType = "Information"
	$ExitCode = 1
	$ZoneName = $cfg["DOMAIN_FQDN"]
	$ComputerName = Get-BLADDomainController
	$SRVRecord = "LYNC2013_CFG_ET_SRVRECORD"

	#ServiceName;Protocol;Priority;Weight;Portnummer
	$Name = $cfg["$SRVRecord"].Split(";")[0]
	$Protocol = $cfg["$SRVRecord"].Split(";")[1]
	$Priority = $cfg["$SRVRecord"].Split(";")[2]
	$Weight = $cfg["$SRVRecord"].Split(";")[3]
	$Port = $cfg["$SRVRecord"].Split(";")[4]
	$ZoneName = $cfg["DOMAIN_FQDN"]
	 "Searching for existing SRV-Records." | Write-BLLog -LogType $LogType
	 "Invoking: Get-BLLYSRVRecord -Name $Name -Protocol $Protocol -ZoneName $ZoneName -ComputerName $ComputerName" | Write-BLLog -LogType $LogType
	$RecordTest = Get-BLLYSRVRecord -Name $Name -Protocol $Protocol -ZoneName $ZoneName -ComputerName $ComputerName
	Write-Debug "RecordTest: $RecordTest"
	if ([string]$RecordTest -ne "DnsServerResourceRecord") {
		"SRV-Record for - $Name - does not exists. Skipping the removal..." | Write-BLLog -LogType $LogType
		$ExitCode = 0
	} else {
		"SRV-Record for - $Name - exists. Removal starts now." | Write-BLLog -LogType $LogType
		"Invoking: Remove-BLLYSRVRecord -Name $Name -Protocol $Protocol -ZoneName $ZoneName -ComputerName $ComputerName"  | Write-BLLog -LogType $LogType
		$ExitCode = Remove-BLLYSRVRecord -Name $Name -Protocol $Protocol -ZoneName $ZoneName -ComputerName $ComputerName
	}
	Return $ExitCode
}
#endregion Uninstallation

## ====================================================================================================
## MAIN
## ====================================================================================================

#region ConfigDB
$cfg = @{}
$ExitCode = Get-BLConfigDBVariables $cfg -Defaults "$AppSource\Defaults.txt"
If ($ExitCode -ne 0) {
	"Error setting variables from ConfigDB, unable to continue!" | Write-BLLog -LogType Information
	Exit-BLFunctions -SetExitCode 1
}
#endregion ConfigDB


## CUSTOMIZE: RunAsTask
## if you want to use RunAsTask Option i.e. want to run the installation script with a special account
## - uncomment lines between "##OPTION: RunAsTask" to "## END OPTION", there are 2 blocks to uncomment
## - adjust Konfig-DB VarNames as needed 

##OPTION: RunAsTask 
$TaskUserDomain =	$cfg["AD_CFG_DOMAINACCOUNT"].Split("\")[0].Trim()
$TaskUsername =		$cfg["AD_CFG_DOMAINACCOUNT"].Split("\").Split(";")[1].Trim()
$TaskPassword =		$cfg["AD_CFG_DOMAINACCOUNT"].Split(";")[1].Trim()
### Start a second instance of the script; the main instance will wait here until the task instance is done:
$ExitCode = Enter-BLExecutionAsTask -UserName $TaskUsername -UserDomain $TaskUserDomain -UserPass $TaskPassword -Timeout 15 #-NoTask
If ($ExitCode -eq -2) {				# Task could not be created; this is a serious error
   $ExitCode = 1
} ElseIf ($ExitCode -eq -1) {		# we're running as a scheduled task; this is a second instance of the script!
	$CurrentUserDomain, $CurrentUserName = (& whoami.exe).Split("\")
	If ($CurrentUserName -eq "SYSTEM") {
		"Installation can not be run with user account '$($CurrentUserDomain)\$($CurrentUserName)'" | Write-BLLog -LogType CriticalError
		Exit-BLFunctions -SetExitCode 1
	}
##END OPTION
	If (-Not $Uninstall) {
		$ExitCode = Invoke-ISInstallation
	} Else {
		$ExitCode = Invoke-ISUninstallation
	}
##OPTION: RunAsTask
}
##END OPTION

$ExitCode = Test-BLLYExitCode -ExitCode $ExitCode

"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
