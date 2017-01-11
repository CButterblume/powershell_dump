<#
.SYNOPSIS
One line of function summary.

.DESCRIPTION
Verbose description of the function; usually starts with "The function <function name> ...", followed by the synopsis.

.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 

.EXAMPLE
install-Script -Force					Installation or Join / Create Farm
install-Script -Uninstall -Force		Deinstallation

.OUTPUTS
The script writes a logifle in C:\RIS\Log\.

.NOTES
To run the script you have to be a member of the local administrator group and you have to run the powershell with elevated rights.
#>
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
Initialize-BLFunctions -AppName "MS_SHPO2010_CFG_CreateOrJoinFarm" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

#region installation
Function Invoke-ISInstallation() {
	$ExitCode = 1
	$LogType = "Information"
	"Adding the SharePoint PowerShell SnapIn to the Shell. Invoking: Add-PSSnapin Microsoft.SharePoint.PowerShell" | Write-BLLog -LogType $LogType
	Add-PSSnapin Microsoft.SharePoint.PowerShell
	$DotNETCheckModuleFile = "NetCheck.psm1"
	$DotNETCheck = Join-Path $AppSource $DotNETCheckModuleFile
	Import-Module $DotNETCheck
	$FarmAccount = $cfg["SHP_FARM_ADMIN"].Split(";")[0]
	$FarmName = $cfg["SQL_CONNECTION_01"].Split(";")[2]
	#$FarmName = $cfg["SHP_FARM_NAME"]
	$AdminContentDB = $FarmName + "_CentralAdminContent"
	$ConfigDB = $FarmName + "_ConfigDB"
	$DatabaseServer = $cfg["SHP_FARM_SQL_SERVER"]
	$SecurePass = $cfg["SHP_FARM_SAFEPASS"]
	$Passphrase = ConvertTo-SecureString $SecurePass -AsPlainText -Force
	$Port = $cfg["SHP_FARM_CA_PORT"]
	$Authentication = $cfg["SHP_FARM_CA_SETTING"]
	$Password = $cfg["SHP_FARM_ADMIN"].Split(";")[1] | ConvertTo-SecureString -AsPlainText -Force
	$Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $FarmAccount, $Password

<#
	#.NET
	$MSIExec = Join-Path $Env:WinDir "\System32\msiexec.exe"
	$Arguments = "/X $ID /qn /passive"
	$DotNetChecker = Get-InstalledNetFrameWorks
	if ($DotNetChecker -Contains "Dot_Net_Version_4_5_2") {
		$LogType = "Warning"
		$ID = "{26784146-6E05-3FF9-9335-786C7C0FB5BE}"
		"Removing .NET 4.5.2 it is not compatible with Microsoft SharePoint 2010. Invoking: Invoke-BLSetupOther -FileName $MSIExec -Arguments $Arguments" | Write-BLLog -LogType $LogType
		$ExitCode = Invoke-BLSetupOther -FileName $MSIExec -Arguments $Arguments
	}
#>	
	$LogType = "Information"
	#New Farm
	"Set powershell version to 2."
	$PS2 = Powershell.exe -version 2
	New-SPConfigurationDatabase -DatabaseName $ConfigDB -DatabaseServer $DatabaseServer -FarmCredentials $Credentials -Passphrase $Passphrase -AdministrationContentDatabaseName $AdminContentDB
<#
	Install-SPHelpCollection -All

	Initialize-SPResourceSecurity

	Install-SPService

	Install-SPFeature –AllExistingFeatures

	New-SPCentralAdministration -Port $Port  -WindowsAuthProvider $Authentication

	Install-SPApplicationContent
#>

#Adding a new server to the farm
<#	
	Connect-SPConfigurationDatabase -DatabaseServer "sql-db-alias" -DatabaseName "SharePoint15_Config" -Passphrase (ConvertTo-SecureString "yourpassphrase" -AsPlainText -Force)

	Initialize-SPResourceSecurity

	Install-SPService

	Install-SPFeature -AllExistingFeatures
	
#>
	#	$ExitCode = 
	Return $ExitCode
}
#endregion

#region uninstallation
Function Invoke-ISUninstallation() {
	$ExitCode = 0
	"Uninstallation is unprovided for the creation or the joining of the farm." | Write-BLLog -LogType Information	
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
