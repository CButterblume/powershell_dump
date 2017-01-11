<#
.SYNOPSIS
Sets MX Records for the edge server of the RZ.

.DESCRIPTION
This script sets a mx record on the dns if it does not exits yet.
If the exchange server is a server in RZ1 the script searches for an mx entry in the dns of the edge server of RZ1.
If it already exist, the script does nothing, if it does not exist the mx entry will be set.
This will be done for RZ2 like for RZ1. The script can differentiate between RZ1 and RZ2 via the hostname

.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 
In this case we have no uninstallation routine. 

.EXAMPLE
install-Script.ps1 -Force
install-Script.ps1 -Uninstall

.NOTES
The User that runs the script has to be a member of the domain administrators.
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
## Date					Version	By					Change Description
## --------------------------------------------------------------------------------------
## 31.05.2016			baumh						Initial version
## 20.06.2016			Stefan Schmalz (IF)			Initial Script, deleted some part of the standard script. 
## 04.07.2016			Stefan Schmalz (IF) 		Ready for first testing, when the test env is accessible.
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
Initialize-BLFunctions -AppName "MS_EXCH2013_CFG_MXRecords" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
$AppDisplayName = "MS_EXCH2013_CFG_MXRecords"

## CUSTOMIZE: Edit value for the AppName parameter <Appname> below; use only characters allowed in file names, no spaces:
Initialize-BLFunctions -AppName "MS_EXCH2013_CFG_MXRecords" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

#region Get MX Record
Function Get-MXRecord {
Param (
	[Parameter(Mandatory=$true)]
	$MXServer,
	[Parameter(Mandatory=$true)]
	$DomainController,
	[Parameter(Mandatory=$true)]
	$ZoneName
	)
	
try {
	$LogType = "Information"
	"Opening PSSession, invoking: $PSS = New-PSSession -ComputerName $DomainController -ErrorAction Stop" | Write-BLLog -LogType $LogType
	$PSS = New-PSSession -ComputerName $DomainController -ErrorAction Stop
} catch {
	$LogType = "Error"
	$ErrorMessage = $_.Exception.Message
	"This error was thrown while waiting the Service $ServiceName to start and get the new status: $ErrorMessage" | Write-BLLog -LogType $LogType
	$Error.clear()
	Return 1
}

try {
	$LogType = "Information"
	#Name of MX-Entry in the DNS
	$Name = $MXServer + "-MX"
	"Invoking: Get-DnsServerResourceRecord -RRType MX -ZoneName $ZoneName | Where {$_.HostName -eq $Name} - via a PSSession"| Write-BLLog -LogType $LogType
	$GetMX = Invoke-Command -Session $PSS -Scriptblock {
		Param (
			[Parameter(Mandatory=$true)]
			$ZoneName,
			[Parameter(Mandatory=$true)]
			$Name
		)
		Get-DnsServerResourceRecord -RRType MX -ZoneName $ZoneName | Where {$_.HostName -eq $Name}
	} -Args $ZoneName,$Name
} catch {
	$LogType = "Error"
	$ErrorMessage = $_.Exception.Message
	"This error was thrown while waiting the Service $ServiceName to start and get the new status: $ErrorMessage" | Write-BLLog -LogType $LogType
	$Error.clear()
	Return 1
}
"Removing PSSession: $PSS" | Write-BLLog -LogType Information
Remove-PsSession -Session $PSS
Return $GetMX
}
#endregion Get MX Record

#region Add MX Record
Function Add-MXRecord {
Param (
	[Parameter(Mandatory=$true)]
	$MXServer,
	[Parameter(Mandatory=$true)]
	$DomainController,
	[Parameter(Mandatory=$true)]
	$EdgeServer,
	[Parameter(Mandatory=$true)]	
	$ZoneName
	)
	
	try {
		$LogType = "Information"
		"Opening PSSession, invoking: $PSS = New-PSSession -ComputerName $DomainController -ErrorAction Stop" | Write-BLLog -LogType $LogType
		$PSS = New-PSSession -ComputerName $DomainController -ErrorAction Stop
	} catch {
		$LogType = "Error"
		$ErrorMessage = $_.Exception.Message
		"This error was thrown while waiting the Service $ServiceName to start and get the new status: $ErrorMessage" | Write-BLLog -LogType $LogType
		$Error.clear()
		Return 1
	}

	try {	
		$LogType = "Information"
		$Name = $MXServer + "-MX"
		"Invoking: Add-DnsServerResourceRecordMX -Name $Name -ZoneName $ZoneName -MailExchange $EdgeServer -Preference 10 -ErrorAction Stop - via a PsSession" | Write-BLLog -LogType $LogType
			$AddMX = Invoke-Command -Session $PSS -Scriptblock {
				param(
					[Parameter(Mandatory=$true)]
					$EdgeServer,
					$Name,
					$ZoneName
				)									
				Add-DnsServerResourceRecordMX -Name $EdgeServer -ZoneName $ZoneName -MailExchange $Name -Preference 10 -ErrorAction Stop 
			} -Args $Name,$EdgeServer,$ZoneName
			Return 0
	} catch {
		$LogType = "Error"
		$ErrorMessage = $_.Exception.Message
		"This error was thrown while waiting the Service $ServiceName to start and get the new status: $ErrorMessage" | Write-BLLog -LogType $LogType
		$Error.clear()
		Return 1
	}
	"Removing PSSession: $PSS" | Write-BLLog -LogType Information
	Remove-PsSession -Session $PSS
	Return $AddMX
}
#endregion Add MX Record

#region Remove MX Record
Function Remove-MXRecord {
Param (
	[Parameter(Mandatory=$true)]
	$MXServer,
	[Parameter(Mandatory=$true)]	
	$DomainController,
	[Parameter(Mandatory=$true)]
	$EdgeServer,
	[Parameter(Mandatory=$true)]
	$ZoneName
	)
	
	try {
		$LogType = "Information"
		"Opening PSSession, invoking: $PSS = New-PSSession -ComputerName $DomainController -ErrorAction Stop" | Write-BLLog -LogType $LogType
		$PSS = New-PSSession -ComputerName $DomainController -ErrorAction Stop
	} catch {
		$LogType = "Error"
		$ErrorMessage = $_.Exception.Message
		"This error was thrown while waiting the Service $ServiceName to start and get the new status: $ErrorMessage" | Write-BLLog -LogType $LogType
		$Error.clear()
		Return 1
	}

	try {	
		$LogType = "Information"
		$Name = $MXServer + "-MX"
		"Invoking: Remove-DnsServerResourceRecordMX -Name $Name -ZoneName $ZoneName -MailExchange $EdgeServer -Preference 10 -ErrorAction Stop - via a PsSession" | Write-BLLog -LogType $LogType
			$AddMX = Invoke-Command -Session $PSS -Scriptblock {
				param(
					[Parameter(Mandatory=$true)]
					$EdgeServer,
					[Parameter(Mandatory=$true)]
					$Name,
					[Parameter(Mandatory=$true)]
					$ZoneName
				)									
				Remove-DnsServerResourceRecord -Name $EdgeServer -ZoneName $ZoneName -RRType Mx -Force -ErrorAction Stop 
			} -Args $Name,$EdgeServer,$ZoneName
			Return 0
	} catch {
		$LogType = "Error"
		$ErrorMessage = $_.Exception.Message
		"This error was thrown while waiting the Service $ServiceName to start and get the new status: $ErrorMessage" | Write-BLLog -LogType $LogType
		$Error.clear()
		Return 1
	}
	"Removing PSSession: $PSS" | Write-BLLog -LogType Information
	Remove-PsSession -Session $PSS
	Return $AddMX
}
#endregion Remove MX Record

Function Invoke-ISInstallation() {
## Make sure that $ExitCode is ONLY 0 if the install was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.
	$ExitCode = 1
	$LogType = "Information"
	#Auslesen und setzen der Variablen
	$DomFQDN = $cfg["DOMAIN_FQDN"]
	$MXServer = $cfg["EX2013_CFG_EDGE_SERVERS"].split(" ")
	$ServerName = hostname
	$DomainController = Get-BLADDomainController
	$ZoneName = $cfg["DOMAIN_FQDN"]
	$Role = $cfg["EX2013_INSTALL_ROLE"]
	
	if ($Role -eq "MR") {
		foreach ($MXer in $MXServer) {
			$EdgeServer = $MXer + "." + $DomFQDN
			"Searching for existing MX Records." | Write-BLLog -LogType $LogType
			$Result = Get-MXRecord -MXServer $MXer -ZoneName $ZoneName -DomainController $DomainController
			if ($Result) {
				$LogType = "Information"
				"The MX-Record already exists. No MX Record will be set now." | Write-BLLog -LogType $LogType
				$ExitCode = 0
			} else {
				try {
					$LogType = "Information"
						"The MX Record does not exist. Setting the MX-Record for $EdgeServer now." | Write-BLLog -LogType $LogType
						$ExitCode = Add-MXRecord -MXServer $MXer -ZoneName $ZoneName -EdgeServer $EdgeServer -DomainController $DomainController
				} catch {
					$LogType = "Error"
					$ErrorMessage = $_.Exception.Message
					"This error was thrown while waiting the Service $ServiceName to start and get the new status: $ErrorMessage" | Write-BLLog -LogType $LogType
					$Error.clear()
					Return 1
				}
			}
		}
	} elseif ($Role -eq "ET") {
		"No MX Records to be set. Skipping the setting of any DNS Records..." | Write-BLLog -LogType $LogType
		$ExitCode = 0
	} else {
		$LogType = "Error"
		"The specified Role in the configdb variable 'EX2013_INSTALL_ROLE' is neither 'ET' nor 'MR'. Please correct that. We cancel the installation now." | Write-BLLog -LogType $LogType
		Return 1	
	}
	Return $ExitCode
}

Function Invoke-ISUninstallation() {
## Make sure that $ExitCode is ONLY 0 if the uninstall was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.
	$ExitCode = 1
	#Auslesen und setzen der Variablen
	$DomFQDN = $cfg["DOMAIN_FQDN"]
	$MXServer = $cfg["EX2013_CFG_EDGE_SERVERS"].split(" ")
	$ServerName = hostname
	$DomainController = Get-BLADDomainController
	$ZoneName = $cfg["DOMAIN_FQDN"]
	$Role = $cfg["EX2013_INSTALL_ROLE"]
	
	if ($Role -eq "MR") {
		foreach ($MXer in $MXServer) {	
			$EdgeServer = $MXer + "." + $DomFQDN
			$Result = Get-MXRecord -MXServer $MXer0 -ZoneName $ZoneName -DomainController $DomainController
			if ($Result) {
				$LogType = "Information"
				"The MX entry for $MXer exists. It will be removed now." | Write-BLLog -LogType $LogType
				"Invoking: Remove-MXRecord -MXServer $MXer -ZoneName $ZoneName -EdgeServer $EdgeServer -DomainController $DomainController" | Write-BLLog -LogType $LogType
				$ExitCode = Remove-MXRecord -MXServer $MXer -ZoneName $ZoneName -EdgeServer $EdgeServer -DomainController $DomainController
			} else {
				$LogType = "Information"
				"The MX entry on the dns server does not exist. Nothing to do." | Write-BLLog -LogType $LogType
			}
		}
	} elseif ($Role -eq "ET") {
		"No MX Records to be removed. Skipping the removal of any DNS Records..." | Write-BLLog -LogType $LogType
		$ExitCode = 0
	} else {
		$LogType = "Error"
		"The specified Role in the configdb variable 'EX2013_INSTALL_ROLE' is neither 'ET' nor 'MR'. Please correct that. We cancel the installation now." | Write-BLLog -LogType $LogType
		Return 1	
	}
	Return $ExitCode
}

## ====================================================================================================
## MAIN
## ====================================================================================================
## CUSTOMIZE: Uncomment to get information from ConfigDB if required (use of Defaults.txt is optional).
$cfg = @{}
$ExitCode = Get-BLConfigDBVariables $cfg -Defaults "$AppSource\Defaults.txt"
If ($ExitCode -ne 0) {
	"Error setting variables from ConfigDB, unable to continue!" | Write-BLLog -LogType Information
	Exit-BLFunctions -SetExitCode 1
}
#region RunAsTask
$TaskUserDomain =	$cfg["AD_CFG_DOMAINACCOUNT"].Split("\")[0].Trim()
$TaskUsername =		$cfg["AD_CFG_DOMAINACCOUNT"].Split("\").Split(";")[1].Trim()
$TaskPassword =		$cfg["AD_CFG_DOMAINACCOUNT"].Split(";")[1].Trim()
### Start a second instance of the script; the main instance will wait here until the task instance is done:
$ExitCode = Enter-BLExecutionAsTask -UserName $TaskUsername -UserDomain $TaskUserDomain -UserPass $TaskPassword -Timeout 15  # -NoTask
If ($ExitCode -eq -2) {				# Task could not be created; this is a serious error
   $ExitCode = 1
} ElseIf ($ExitCode -eq -1) {		# we're running as a scheduled task; this is a second instance of the script!
	$CurrentUserDomain, $CurrentUserName = (& whoami.exe).Split("\")
	If ($CurrentUserName -eq "SYSTEM") {
		"Installation can not be run with user account '$($CurrentUserDomain)\$($CurrentUserName)'" | Write-BLLog -LogType CriticalError
		Exit-BLFunctions -SetExitCode 1
	}
	#Start Installation or Uninstallation
	If (-Not $Uninstall) {
		$ExitCode = Invoke-ISInstallation
	} Else {
		$ExitCode = Invoke-ISUninstallation
	}
}
#endregion RunAsTask


"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
