<#
.SYNOPSIS
The script does an update on the Lync Persistent Chat Server database.

.DESCRIPTION
The script does an update on the Lync Persistent Chat Server database.
1. It stops the w3svc service
2. Runs a Install-CsDatabase -Update command
3. Starts the lync services again "Start-CsWindowsService"

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
The user who starts the script has to be a user of the domain, a member of the group "RTCUniversalReadOnlyAdmins"
a SQL Server-Administrator and local administrator on the SQL Server where the database is hosted.
The Script uses the BaseLibraryLYNC.psm1.
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
Initialize-BLFunctions -AppName "MS_LYNC2013_PC_DB_Update" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information


Function Invoke-ISInstallation() {
	$ExitCode = 1
	$LogType = "Information"
	$LogFile = "C:\RIS\Log\Update_PC_Database.html"
	$WebServiceName = "w3svc"
	$DomainFQDN = $cfg["DOMAIN_FQDN"]
	$SQLPersistentChat = $cfg["LYNC2013_SQL_PC_NODE_1"]
	$SqlServerfqdn = $SQLPersistentChat + "." + $DomainFQDN
#	$ADDC = Get-BLADDomainController´
#	$Server = hostname
#	$RegKey = "HKLM:\Software\Atos\MS_LYNC2013_PC_DB_Update"
	"Stopping the service $WebServiceName . Invoking: Stop-BLLYService -ServiceName $WebServiceName" | Write-BLLog -LogType $LogType
	$ExitCode = Stop-BLLYService -ServiceName $WebServiceName
	if ($ExitCode -eq 0) {
		try {
			"$WebServiceName was stopped successful. Updating the database." | Write-BLLog -LogType $LogType
			 "Invoking: Install-CsDatabase -Update -ConfiguredDatabases -SqlServerfqdn $SqlServerfqdn -Report $LogFile" | Write-BLLog -LogType $LogType
			$ExitCode = Install-CsDatabase -Update -ConfiguredDatabases -SqlServerfqdn $SqlServerfqdn -Report $LogFile
		} catch {
			$LogType = "Error"
			$ErrorMessage = $_.Exception.Message
			"This error was thrown while updating the 'configured databases' of Lync Persistent Chat Servers. This Error was thrown: `r`n $ErrorMessage"  | Write-BLLog -LogType $LogType
			"$Error" | Write-BLLog -LogType Error
			$Error.clear()
			Return 1		
		}
		
		try {
			"Update ran successful, starting the Lync services. Invoking: Start-CsWindowsService -ErrorAction Stop" | Write-BLLog -LogType $LogType
			$StartSvcs = Start-CsWindowsService -ErrorAction Stop
			$NotStartedSvcs = Get-CsWindowsService | Where-Object {$_.Status -ne "Running"}
			if ($NotStartedSvcs) {
				$LogType = "Error"
				"Some Services could not be started. $NotStartedSvcs Please take a look at the logfiles and start them manually." | Write-BLLog -LogType $LogType
				Return 1
			} else {
				"All Lync Persistent Chat Server services have been started successful." | Write-BLLog -LogType $LogType
				$ExitCode = 0
			}
		} catch {
			$LogType = "Error"
			$ErrorMessage = $_.Exception.Message
			"This error was thrown while starting the Lync Persistent Chat Server services. This Error was thrown: `r`n $ErrorMessage"  | Write-BLLog -LogType $LogType
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
	"Uninstallation is unprovided for the DB Update of the Lync database!" | Write-BLLog -LogType Information	
	$ExitCode = 0
	Return $ExitCode
}
#endregion Uninstallation

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

## CUSTOMIZE: RunAsTask
## if you want to use RunAsTask Option i.e. want to run the installation script with a special account
## - uncomment lines between "##OPTION: RunAsTask" to "## END OPTION", there are 2 blocks to uncomment
## - adjust Konfig-DB VarNames as needed 

##OPTION: RunAsTask 
$TaskUserDomain =	$cfg["AD_CFG_DOMAINACCOUNT"].Split("\")[0].Trim()
$TaskUsername =		$cfg["AD_CFG_DOMAINACCOUNT"].Split("\").Split(";")[1].Trim()
$TaskPassword =		$cfg["AD_CFG_DOMAINACCOUNT"].Split(";")[1].Trim()
### Start a second instance of the script; the main instance will wait here until the task instance is done:
$ExitCode = Enter-BLExecutionAsTask -UserName $TaskUsername -UserDomain $TaskUserDomain -UserPass $TaskPassword -Timeout 60 # -NoTask
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



## CUSTOMIZE: An msi installation may leave with errorlevel 3010, indicating a reboot is required;
## uncomment if this is supported, and make sure that the Task Sequence has a Reboot action after package execution  (=> InstallationPackageList)
##OPTION: Repair MSI-Exitcode
#If ($ExitCode -eq 3010) {
#	"A reboot is required to finish the installation!" | Write-BLLog -LogType Warning
#	$ExitCode = 0
#}
##END OPTION


"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
