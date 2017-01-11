<#
.SYNOPSIS
This script adds the necessary databases to the instance LYNC on the Database Backend Mirror

.DESCRIPTION
Autor: stefan.schmalz@interface-ag.de
The script adds these databases to the instance LYNC on the Database Backend Mirror using the Lync commandlet "Install-CsDatabase"
- lis
- xds
- rtcxds 
- rtcab
- rgsconfig
- LcsCDR
- QoEMetrics
- rtcshared
- rgsdyn
- cpsdyn

After the lync commandlets have done their work, the script tests if the databases have been created.

.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 

.EXAMPLE
install-Script -Force					Installation der Software
install-Script -Uninstall -Force		Deinstallation der Software

.OUTPUTS
The script writes a logifle in C:\RIS\Log.

.NOTES
To run the script you have to be a member of a group that has right to access the lync database and you have to run the powershell with elevated rights.
ATTENTION: The variables for the userright that are filled with users or groups have to be completely different. 
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
## 8/10/2016			A563910			Initial version
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
Initialize-BLFunctions -AppName "MS_LYNC2013_FE_CFG_CreateCMSDB" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information


Function Invoke-ISInstallation() {
	$ReturnCode = 1
	$LogFileCMDBs = "C:\RIS\Log\Lync_CFG_Databases_CentralManagementStore.html"
	$DomainFQDN = $cfg["DOMAIN_FQDN"]
	$SQLBEMirrorNode1 = $cfg["LYNC2013_SQL_BE_NODE_1"]
	$SQLServerFQDN = $SQLBEMirrorNode1 + "." + $DomainFQDN
	$SQLInstanceName = $cfg["LYNC2013_SQL_INSTANCE_NAME"]
	$LyncDBs = "lis", "xds"
	$SQLContext = "SQLServer:\\SQL\"
	$SQLDatabasesPath = "\Databases"
	$SQLConnectionString = $SQLContext + $SQLBEMirrorNode1 + "\" + $SQLInstanceName + $SQLDatabasesPath
	$DeclaredStoreLocation = $SQLBEMirrorNode1 + $DomainFQDN + "\" + $SQLInstanceName
		
	Try{
		"Opening PS Session to $SQLBEMirrorNode1" | Write-BLLog -LogType Information
		$PSS = New-BLLYPowerShellSession -ComputerName $SQLBEMirrorNode1
		"Searching for existing databases on $SQLBEMirrorNode1" | Write-BLLog -LogType Information
		$DBNames = Invoke-Command -Session $PSS -ScriptBlock {Param ($SQLConnectionString) Add-PSSnapIn *sql*;dir $SQLConnectionString | Select Name} -Args $SQLConnectionString
		if (($DBNames.Name -Contains $LyncDBs[0]) -AND ($DBNames.Name -Contains $LyncDBs[1]))  {
			"The Central Management Store databases were installed before. Skipping this step..." | Write-BLLog -LogType Information
		} else {
			"Installing the central management store databases. Invoking: `n`rInstall-CsDatabase -CentralManagementDatabase -SqlServerFqdn $SQLServerFQDN -SqlInstanceName $SQLInstanceName -UseDefaultSqlPaths -Report $LogFileCMDBs –verbose" | Write-BLLog -LogType Information
			$ReturnCode = Install-CsDatabase -CentralManagementDatabase -SqlServerFqdn $SQLServerFQDN -SqlInstanceName $SQLInstaceName -UseDefaultSqlPaths -Report $LogFileCMDBs –verbose
		}
	}
	Catch{	
		"There was an error during the installation of the central management store databases."|Write-BLLog -LogType CriticalError
		$ErrorMessage = $_.Exception.Message
		"The Error Message is: $ErrorMessage"|Write-BLLog -LogType CriticalError
		"Please check the System and Application Logs in the Eventlogs."|Write-BLLog -LogType CriticalError
		$ReturnCode = 1	
	}
	
	"Searching for databases on  $SQLBEMirrorNode1" | Write-BLLog -LogType Information
	"Invoking: Add-PSSnapIn *sql*;Dir SQLServer:\\SQL\$SQLBEMirrorNode1\$SQLInstanceName\Databases | Select Name" | Write-BLLog -LogType Information
	$DBNames = Invoke-Command -Session $PSS -ScriptBlock {
		param(
			[string]$SQLConn
		)
	
		Add-PSSnapIn *sql*
		Get-ChildItem -Path $SQLConn | Select Name
		
		} -Argumentlist $SQLConnectionString

	if (($DBNames.Name -Contains $LyncDBs[0]) -AND ($DBNames.Name -Contains $LyncDBs[1]))  {
		"The databases for Lync - 'lis' and 'xds' - were created successfully." | Write-BLLog -LogType Information
		$ReturnCode = 0
	} 
	else {
		"The databases for Lync - 'lis' and 'xds' - do not exist on $ComputerName." | Write-BLLog -LogType Error
		$ReturnCode = 1	
	}
	"Removing the PSSession. Invoking: Remove-PSSession -Session $PSS" | Write-BLLog -LogType Information
	$ClosePSS = Remove-PSSession -Session $PSS
	
	# Setting the Active Directory Service Control Point for the Central Management Store.
	
	$GetStoreLocation = Get-CsConfigurationStoreLocation
	$StoreLocation = $GetStoreLocation.BackEndServer
	if ($StoreLocation -eq $DeclaredStoreLocation) {
		if (!$ReturnCode) {

			Try{		
				"Setting the Active Directory Service Control Point for the Central Management Store." | Write-BLLog -LogType Information
				"Invoking: Set-CsConfigurationStoreLocation -SqlServerFqdn $SQLServerFQDN -SqlInstanceName $SQLInstanceName" | Write-BLLog -LogType Information
				$ReturnCode = Set-CsConfigurationStoreLocation -SqlServerFqdn $SQLServerFQDN -SqlInstanceName $SQLInstanceName		
			}
			Catch{		
				"There was an error setting the Active Directory Service Control Point for the Central Management Store."|Write-BLLog -LogType CriticalError
				$ErrorMessage = $_.Exception.Message
				"The Error Message is: $ErrorMessage"|Write-BLLog -LogType CriticalError
				"Please check the System and Application Logs in the Eventlogs."|Write-BLLog -LogType CriticalError
				$ReturnCode = 1		
			}
		
			if($ReturnCode -ne 1){
				$ReturnCode = 0
			}

		} 
	} else {
		"The Active Directory Service Control Point for the Central Management Store was set before. Skipping this step..." | Write-BLLog -LogType Information
		$ReturnCode = 0
	}
	Return $ReturnCode
}
#endregion installation


#region uninstallation
Function Invoke-ISUninstallation() {
	"A uninstallation is not provided for the lync backend db configuration." | Write-BLLog -LogType Information
	$ReturnCode = 0
	Return $ReturnCode
}
#endregion uninstallation

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

#region RunAsTask 
$TaskUserDomain =	$cfg["AD_CFG_DOMAINACCOUNT"].Split("\")[0].Trim()
$TaskUsername =		$cfg["AD_CFG_DOMAINACCOUNT"].Split("\").Split(";")[1].Trim()
$TaskPassword =		$cfg["AD_CFG_DOMAINACCOUNT"].Split(";")[1].Trim()
### Start a second instance of the script; the main instance will wait here until the task instance is done:
$ExitCode = Enter-BLExecutionAsTask -UserName $TaskUsername -UserDomain $TaskUserDomain -UserPass $TaskPassword -Timeout 60 #-NoTask
If ($ExitCode -eq -2) {				# Task could not be created; this is a serious error
   $ExitCode = 1
} ElseIf ($ExitCode -eq -1) {		# we're running as a scheduled task; this is a second instance of the script!
	$CurrentUserDomain, $CurrentUserName = (& whoami.exe).Split("\")
	If ($CurrentUserName -eq "SYSTEM") {
		"Installation can not be run with user account '$($CurrentUserDomain)\$($CurrentUserName)'" | Write-BLLog -LogType CriticalError
		Exit-BLFunctions -SetExitCode 1
	}

	If (-Not $Uninstall) {
		$ExitCode = Invoke-ISInstallation
	} Else {
		$ExitCode = Invoke-ISUninstallation
	}
}
#endregion RunAsTask

"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
