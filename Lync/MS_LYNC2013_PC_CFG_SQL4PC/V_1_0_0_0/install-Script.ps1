<#
.SYNOPSIS
This script prepares the SQL Server for Persistent Chat.

.DESCRIPTION
This script prepares the SQL Server for the installation of the Lync Persistent Chat Server.
The script creates a database on the correspondingly sql server with the name 'mgc'.

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
The User that runs the script has to got rights (read informations and create new databases for PC) on the database server for persistent chat.
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
## 8/10/2016			1.0.0.0							Initial version
## 25.10.2016			1.0.0.1 S. Schmalz (IF)			Added CBH and ready for testing.
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
$BaseLibraryLYNC = Join-Path $LibraryPath "BaseLibraryLYNC.psm1"
If (-Not (Import-Module $BaseLibrary -PassThru)) {Write-Host -ForegroundColor Red "[CriticalError] File not found - '$BaseLibrary'"; Exit 1}
If (-Not (Import-Module $BaseLibraryLYNC -PassThru)) {Write-Host -ForegroundColor Red "[CriticalError] File not found - '$BaseLibraryLYNC'"; Exit 1}

$ScriptItem = Get-Item -Path $MyInvocation.MyCommand.Path
$Local:ScriptFullName = $ScriptItem.FullName
$Local:ScriptName = $ScriptItem.Name
$Local:ScriptPath = $ScriptItem.DirectoryName

## CUSTOMIZE: Edit value for the AppName parameter <Appname> below; use only characters allowed in file names, no spaces:
Initialize-BLFunctions -AppName "MS_LYNC2013_PC_CFG_SQL4PC" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information


#region Installation
Function Invoke-ISInstallation() {
	$LogType = "Information"
	$ExitCode = 1
	$DomainFQDN = $cfg["DOMAIN_FQDN"]
	$SQLServer = $cfg["LYNC2013_SQL_PC_NODE_1"]
	$SQLServerFQDN = $SqlServer + "." + $DomainFQDN 
	$InstanceName = $cfg["LYNC2013_SQL_PC_INSTANCE_NAME"]
	$DBType = $cfg["LYNC2013_PC_DB_TYPE"]
	$DataPath = $cfg["LYNC2013_PC_DB_DATA_PATH"]
	$LogPath = $cfg["LYNC2013_PC_DB_LOG_PATH"]
	$LyncPCDB = $cfg["LYNC2013_PC_DB_NAME"]
	
	try {
		"Searching for databases on  $SQLServer" | Write-BLLog -LogType $LogType
		"Opening PS Session to $SQLServer" | Write-BLLog -LogType $LogType
		$PSS = New-BLLYPowerShellSession -ComputerName $SQLServer
		"Invoking: Add-PSSnapIn *sql*;Dir SQLServer:\\SQL\$SQLServer\$InstanceName\Databases | Select Name" | Write-BLLog -LogType $LogType
		$DBNames = Invoke-Command -Session $PSS -ErrorAction Stop -ScriptBlock {Param ($SQLServer, $InstanceName) Add-PSSnapIn *sql*;Dir SQLServer:\\SQL\$SQLServer\$InstanceName\Databases | Select Name} -args $SQLServer,$InstanceName
	} catch {
		$LogType = "Error"
		"This error was thrown while retrieving a database list from $SqlServer : `r`n $ErrorMessage" | Write-BLLog -LogType $LogType
		"$Error" | Write-BLLog -LogType Error
		$Error.clear()
		Return 1
	} finally {
		"Removing the open powershell session - $PSS" | Write-BLLog -LogType $LogType
		Remove-PsSession -Session $PSS
	}
	
	if ($DBNames.Name -Contains $LyncPCDB) {
		"The database - $LyncPCDB - was created successful before." | Write-BLLog -LogType $LogType
		$ExitCode = 0
	} else {
		try {
			$InstallDB = Install-CsDatabase -DatabaseType $DBType –SqlServerFqdn $SQLServerFQDN -SQLInstanceName $InstanceName -DatabasePaths $LogPath,$DataPath -ErrorAction Stop -Verbose
			$ExitCode = 0
		} catch {
			$LogType = "Error"
			"This error was thrown while creating the database for Lync Persistent Chat on $SqlServer : `r`n $ErrorMessage"  | Write-BLLog -LogType $LogType
			"$Error" | Write-BLLog -LogType Error
			$Error.clear()
			Return 1		
		}
		
	}
	Return $ExitCode
}
#endregion Installation

#region Uninstallation
Function Invoke-ISUninstallation() {
	$LogType = "Information"
	"Uninstallation is unprovided for the initial creation of the persistent chat databases." | Write-BLLog -LogType $LogType
	$ExitCode = 0		
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


"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
