<#
.SYNOPSIS
This script sets the SQL Alias for all three SharePoint portals.

.DESCRIPTION
This script sets the SQL Alias for the three SharePoint portals.
It sets a registry key with "DBMSSOCN,FQDN+InstanceName,Portnumber" at HKLM:\Software\Microsoft\MSSQLServer\Client\ConnectTo

.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 

.OUTPUTS
The script writes a logfile in C:\RIS\Log.

.EXAMPLE
install-Script -Force					Installation of the Software
install-Script -Uninstall -Force		Uninstallation of the Software

.NOTES
The user that runs this script has to be member of the local administrator group.
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
## 01.01.1980			Author Name			Initial version
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
Initialize-BLFunctions -AppName "MS_SHPO2010_PreReq_SQLAlias" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.

"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information


#region installation
Function Invoke-ISInstallation() {
	$ExitCode = 1
	$LogType = "Information"
	$SQLConn1 = $cfg["SQL_CONNECTION_01"].Split(";")
	$SQLConn2 = $cfg["SQL_CONNECTION_02"].Split(";")
	$SQLConn3 = $cfg["SQL_CONNECTION_03"].Split(";")
	$SQLAlias1 = $SQLConn1[0]
	$SQLAlias2 = $SQLConn2[0]
	$SQLAlias3 = $SQLConn3[0]
	$ServerName1 = $SQLConn1[1]
	$ServerName2 = $SQLConn1[1]
	$ServerName3 = $SQLConn3[1]
	$Instance1 = $SQLConn1[2]
	$Instance2 = $SQLConn2[2]
	$Instance3 = $SQLConn3[2]
	$Instances = $Instance1, $Instance2, $Instance3
	$Port1 = $SQLConn1[3]
	$Port2 = $SQLConn2[3]
	$Port3 = $SQLConn3[3]
	
	
	$HTPort = @{$Instance1 = $Port1;$Instance2 = $Port2;$Instance3 = $Port3}
	$HTName = @{$Instance1 = $SQLAlias1;$Instance2 = $SQLAlias2;$Instance3 = $SQLAlias3}
	$HTServer = @{$Instance1 = $ServerName1;$Instance2 = $ServerName2;$Instance3 = $ServerName3}
	#These are the two Registry locations for the SQL Alias locations
#	$x64 = "HKLM:\Software\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo"
	$RegPath = "HKLM:\Software\Microsoft\MSSQLServer\Client\ConnectTo" 
	$Type = "string"
	"Testing the existance of the registry path: $RegPath" | Write-BLLog -LogType $LogType
	"Invoking: Test-Path -Path $RegPath" | Write-BLLog -LogType $LogType
	$TestRegPath = Test-Path -Path $RegPath
	if ($TestRegPath -eq $False) {
		"The registry key does not exist. Creating it now. Invoking: New-BLRegistryKeyX64 -Path $RegPath" | Write-BLLog -LogType $LogType
		$NewRegKey = New-BLRegistryKeyX64 -Path $RegPath
	} else {
		"The registry key $RegPath already exist. Skipping the creation..." | Write-BLLog -LogType $LogType
	}
		
	foreach ($Instance in $Instances) {
		$TCPPort = $HTPort.Get_Item($Instance)
		$AliasName = $HTName.Get_Item($Instance)
		$Server = $HTServer.Get_Item($Instance)
		$ServerInstance = $Server + "\" + $Instance
		$TCPAlias = "DBMSSOCN," + $ServerInstance + "," + $TCPPort
		$Result = Get-ItemProperty -Path $RegPath
		if ($Result.$AliasName -eq $TCPAlias) {
			"The alias $AliasName - was set before. Skipping the creation..." | Write-BLLog -LogType $LogType
			$ExitCode = 0
		} else {
			"The alias for $AliasName - was not set yet. Invoking: Set-BLRegistryValueX64 -Path $RegPath -Name $AliasName -Type $Type -Value $TCPAlias" | Write-BLLog -LogType $LogType
			$Result = Set-BLRegistryValueX64 -Path $RegPath -Name $AliasName -Type $Type -Value $TCPAlias
			if ($Result.$AliasName -eq $TCPAlias) {
			$Value = $Result.$AliasName
				"The alias for $AliasName was set - `r`nAlias: $AliasName `r`nValue: $Value " | Write-BLLog -LogType $LogType
				$ExitCode = 0
			} else {
				$LogType = "Error"
				"An error occured while setting the SQL Alias to the registry - $RegPath " | Write-BLLog -LogType $LogType
				Return 1
			}
		}
	}
	Return $ExitCode
}
#endregion installation

#region uninstallation
Function Invoke-ISUninstallation() {
	$ExitCode = 1
	$ExitCode = 
	Return $ExitCode
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

## CUSTOMIZE: set filter for config vars you want to be displayed (i.e. you will be using)
Write-BLConfigDBSettings -cfg $cfg -Filter "SQL_CONNECTION_"


## CUSTOMIZE: RunAsTask
## if you want to use RunAsTask Option i.e. want to run the installation script with a special account
## - uncomment lines between "##OPTION: RunAsTask" to "## END OPTION", there are 2 blocks to uncomment
## - adjust Konfig-DB VarNames as needed 

##OPTION: RunAsTask 
#$TaskUserDomain =	$cfg["XXX  _INSTALL_SETUP_USER"].Split("\")[0].Trim()
#$TaskUsername =		$cfg["XXX  _INSTALL_SETUP_USER"].Split("\")[1].Trim()
#$TaskPassword =		$cfg["XXX  _INSTALL_SETUP_PASSWORD"].Trim()
### Start a second instance of the script; the main instance will wait here until the task instance is done:
#$ExitCode = Enter-BLExecutionAsTask -UserName $TaskUsername -UserDomain $TaskUserDomain -UserPass $TaskPassword -Timeout 60 # -NoTask
#If ($ExitCode -eq -2) {				# Task could not be created; this is a serious error
#   $ExitCode = 1
#} ElseIf ($ExitCode -eq -1) {		# we're running as a scheduled task; this is a second instance of the script!
#	$CurrentUserDomain, $CurrentUserName = (& whoami.exe).Split("\")
#	If ($CurrentUserName -eq "SYSTEM") {
#		"Installation can not be run with user account '$($CurrentUserDomain)\$($CurrentUserName)'" | Write-BLLog -LogType CriticalError
#		Exit-BLFunctions -SetExitCode 1
#	}
##END OPTION
 
	If (-Not $Uninstall) {
		$ExitCode = Invoke-ISInstallation
	} Else {
		$ExitCode = Invoke-ISUninstallation
	}
	
##OPTION: RunAsTask
#}
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
