<#
.SYNOPSIS
The script installs the updates of the lync server.

.DESCRIPTION
The script configures the federation and external access of lync edge.
It enables:
Federation and external access --> External Access Policy --> Global
1. Enable communications with federated users
2. Enable communications with remote users
3. Enable communications with public users

Federation and external access --> Access Edge Configuration --> Global

1. Enable federation and public IM connectivity
2. Enable partner domain discovery
3. Enable remote user access


.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 

.EXAMPLE
install-Script -Force					Installation of the configuration
install-Script -Uninstall -Force		Deinstallationof the configuration

.OUTPUTS
The script writes a logifle in C:\RIS\Log.

.NOTES
The user that runs this script has to be at least a member of the Edge RTCUniversalServerAdmins group or is assigned to the CSAdministrator role.
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
If (-Not (Import-Module $BaseLibrary -PassThru)) {Write-Host -ForegroundColor Red "[CriticalError] File not found - '$BaseLibrary'"; Exit 1}

$ScriptItem = Get-Item -Path $MyInvocation.MyCommand.Path
$Local:ScriptFullName = $ScriptItem.FullName
$Local:ScriptName = $ScriptItem.Name
$Local:ScriptPath = $ScriptItem.DirectoryName

## CUSTOMIZE: Edit value for the AppName parameter <Appname> below; use only characters allowed in file names, no spaces:
Initialize-BLFunctions -AppName "MS_LYNC2013_ET_GlobalPolicy" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information


#region Installation
Function Invoke-ISInstallation() {
	$ExitCode = 1
	$LogType = "Information"
	try {
		"--------------------------------------------------" | Write-BLLog -LogType $LogType
		"------------ External Access Policy --------------" | Write-BLLog -LogType $LogType
		"--------------------------------------------------" | Write-BLLog -LogType $LogType
		"Reading ExternalAccessPolicy. Invoking: Get-CsExternalAccessPolicy" | Write-BLLog -LogType $LogType
		$GetEAP = Get-CsExternalAccessPolicy -ErrorAction Stop
		if ($GetEAP.EnableFederationAccess -eq $True -AND $GetEAP.EnableOutsideAccess -eq $True -AND $GetEAP.EnablePublicCloudAccess -eq $True) {		
			"The External Access Policy was set before. Skipping to set the Policy again..." | Write-BLLog -LogType $LogType
		} else {
			"Invoking: Set-CsExternalAccessPolicy -EnableFederationAccess $True -EnableOutsideAccess $True -EnablePublicCloudAccess $True" | Write-BLLog -LogType $LogType
			$SetExternalAccessPolicy = Set-CsExternalAccessPolicy -EnableFederationAccess $True -EnableOutsideAccess $True -EnablePublicCloudAccess $True -ErrorAction Stop
		}
		
		"Testing the ExternalAccessPolicy. Invoking: Get-CsExternalAccessPolicy" | Write-BLLog -LogType $LogType
		$GetEAP = Get-CsExternalAccessPolicy -ErrorAction Stop
		if ($GetEAP.EnableFederationAccess -eq $True -AND $GetEAP.EnableOutsideAccess -eq $True -AND $GetEAP.EnablePublicCloudAccess -eq $True) {
			"FederationAccess, OutsideAccess and PublicCloudAccess were enabled successful." | Write-BLLog -LogType $LogType
			$xitCode = 0
		} else {
			$LogType = "Error"
			$EnableFedAccess = $GetEAP.EnableFederationAccess
			$EnableOutsideAccess = $GetEAP.EnableOutsideAccess
			$EnablePublicCloudAccess = $GetEAP.EnablePublicCloudAccess
			"The configuration was not successful. These are the current settings:" | Write-BLLog -LogType $LogType
			"Enable Federation Access = $EnableFedAccess " | Write-BLLog -LogType $LogType
			"Enable Outside Access = $EnableOutsideAccess " | Write-BLLog -LogType $LogType
			"Enable Public Cloud Access = $EnablePublicCloudAccess " | Write-BLLog -LogType $LogType
			Return 1
		}
		
		
		
		"-------------------------------------------------" | Write-BLLog -LogType $LogType
		"---------- Access Edge Configuration ------------" | Write-BLLog -LogType $LogType
		"-------------------------------------------------" | Write-BLLog -LogType $LogType
		"Reading Access Edge Configuration. Invoking: Get-CsAccessEdgeConfiguration" | Write-BLLog -LogType $LogType
		$GetAEC = Get-CsAccessEdgeConfiguration -ErrorAction Stop
		if ($GetAEC.AllowOutsideUsers -eq $True -AND $GetAEC.AllowFederatedUsers -eq $True -AND $GetAEC.EnablePartnerDiscovery -eq $True) {
			"The Access Edge Configuration has been done before. Skipping to set the configuration again..." | Write-BLLog -LogType $LogType
		} else {
			"Invoking: Set-CsAccessEdgeConfiguration -AllowOutsideUsers $True -AllowFederatedUsers $True -EnablePartnerDiscovery $True -UseDnsSrvRouting " | Write-BLLog -LogType $LogType
			$SetAccessEdgeConfig = Set-CsAccessEdgeConfiguration -AllowOutsideUsers $True -AllowFederatedUsers $True -EnablePartnerDiscovery $True -UseDnsSrvRouting -ErrorAction Stop
		}
		
		"Testing the Access Edge Configuration. Invoking: Get-CsAccessEdgeConfiguration" | Write-BLLog -LogType $LogType
		$GetAEC = Get-CsAccessEdgeConfiguration -ErrorAction Stop
		if ($GetAEC.AllowOutsideUsers -eq $True -AND $GetAEC.AllowFederatedUsers -eq $True -AND $GetAEC.EnablePartnerDiscovery -eq $True) {
			"AllowOutsideAccess, AllowFederatedUsers and EnablePartnerDiscovery were enabled successful" | Write-BLLog -LogType $LogType
			$ExitCode = 0
		} else {
			$AllowOutsideUsers = $GetAEC.AllowOutsideUsers
			$AllowFederatedUsers = $GetAEC.AllowFederatedUsers
			$EnablePartnerDiscovery = $GetAEC.EnablePartnerDiscovery
			"The configuration was not successful. These are the current settings:" | Write-BLLog -LogType $LogType
			"Allow Outside Users = $AllowOutsideUsers " | Write-BLLog -LogType $LogType
			"Allow Federated Users = $AllowFederatedUsers " | Write-BLLog -LogType $LogType
			"Enable Partner Discovery = $EnablePartnerDiscovery " | Write-BLLog -LogType $LogType
			Return 1
		}
	} catch {
		$LogType = "Error"
		$ErrorMessage = $_.Exception.Message
		"This error was thrown while invoking Start-Service -Name $ServiceName : `r`n $ErrorMessage" | Write-BLLog -LogType $LogType
		$Error.clear()
		Return 1	
	}
	


	Return $ExitCode
}
#endregion installation

#region uninstallation
Function Invoke-ISUninstallation() {

	$ExitCode = 1

		
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
$TaskUserDomain =	$cfg["AD_CFG_DOMAINACCOUNT"].Split("\")[0].Trim()
$TaskUsername =		$cfg["AD_CFG_DOMAINACCOUNT"].Split("\").Split(";")[1].Trim()
$TaskPassword =		$cfg["AD_CFG_DOMAINACCOUNT"].Split(";")[1].Trim()
### Start a second instance of the script; the main instance will wait here until the task instance is done:
$ExitCode = Enter-BLExecutionAsTask -UserName $TaskUsername -UserDomain $TaskUserDomain -UserPass $TaskPassword -Timeout 15 # -NoTask
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
