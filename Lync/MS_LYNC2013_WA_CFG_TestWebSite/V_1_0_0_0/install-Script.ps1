<#
.SYNOPSIS
This script tests a website that indicates that the Microsoft Office Web Apps 2013 Farm was installed successful.

.DESCRIPTION
This script tests a website that indicates that the Microsoft Office Web Apps 2013 Farm was installed successful.
If the website returns a errorcode 500 or 501 the script repairs the .NET 4.5.2 installation and tests the website again.

.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 
In this case we have no uninstallation routine. 

.EXAMPLE
install-Script.ps1 -Force
install-Script.ps1 -Uninstall

.OUTPUTS
The installation writes logs in the folder "C:\RIS\Log"

.NOTES
ATTENTION: The user that runs this script has to be a member of the local administrators.
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
Initialize-BLFunctions -AppName "MS_LYNC2013_WA_CFG_TestWebSite" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information



Function Invoke-ISInstallation() {
	$ExitCode = 1
	$LogType = "Information"
	$OfficeWebAppsPoolName = $cfg["LYNC2013_CFG_WA_POOL_NAME"]
	$DomainFQDN = $cfg["DOMAIN_FQDN"]
	$WebSiteFQDN = "https://" + $OfficeWebAppsPoolName + "." + $DomainFQDN + "/hosting/discovery"
	try {
		"Creating Request. Invoking: HTTP_Request = [System.Net.WebRequest]::Create($WebSiteFQDN)" | Write-BLLog -LogType $LogType
		$HTTP_Request = [System.Net.WebRequest]::Create($WebSiteFQDN)
		"Get response from the site. Invoking: HTTP_Response = $HTTP_Request.GetResponse() " | Write-BLLog -LogType $LogType
		$HTTP_Response = $HTTP_Request.GetResponse()
		"Start sleep for five second before getting the status of the request." | Write-BLLog -LogType $LogType
		Start-Sleep -Seconds 5
		"Get HTTP statuscode as int. Invoke: HTTP_Status = [int]$HTTP_Response.StatusCode" | Write-BLLog -LogType $LogType
		$HTTP_Status = [int]$HTTP_Response.StatusCode
		"HTTP statuscode - $HTTP_Status - was returned" | Write-BLLog -LogType $LogType
		if ($HTTP_Status -eq 200) {
			"The Website is reachable, everything went fine" | Write-BLLog -LogType Information
			$ExitCode = 0
		} 
	} catch [System.Exception] {
		"Exception found: $Error.Exception" | Write-BLLog -LogType $LogType
		$StatusCode = [int]$Error.Exception.InnerException.Response.StatusCode
		if (($StatusCode -eq 500) -OR ($StatusCode -eq 501)) {
			$LogType = "Warning"
			"Response was $StatusCode. There could be an issue with .NET 4.5.Trying to repair the .NET Installation." | Write-BLLog -LogType $LogType
			"Invoking: Invoke-BLSetupOther -FileName $FileName -Arguments $Arguments" | Write-BLLog -LogType $LogType
			$WinDir = $Env:windir
			$Dir = Join-Path $WinDir "Microsoft.NET\Framework64\v4.0.30319"
			$FileName = Join-Path $Dir "aspnet_regiis.exe"
			$Arguments = "-i"
			$ExitCode = Invoke-BLSetupOther -FileName $FileName -Arguments $Arguments	
			if ($ExitCode -eq 0) {
				
				$HTTP_Request = [System.Net.WebRequest]::Create($WebSiteFQDN)
				# We then get a response from the site.
				$HTTP_Response = $HTTP_Request.GetResponse()
				# We then get the HTTP code as an integer.
				$HTTP_Status = [int]$HTTP_Response.StatusCode
				if ($HTTP_Status -eq 200) {
					$LogType = "Information"
					"The Website is reachable after the repair of the .NET 4.5 Installation." | Write-BLLog -LogType Information
					$ExitCode = 0
				} else {
					$LogType = "Error"
					"The Website is not reachable even after the repair of the .NET 4.5 installation. Please take a further look at the installation of .NET / IIS and/or Office Web Apps Server & Farm" | Write-BLLog -LogType $LogType
					Return 1
				}
			}
		} else {
			$LogType = "Error"
			"An unexpected StatusCode - $StatusCode - was returned by the website. Please take a look at the logfiles." | Write-BLLog -LogType $LogType
			Return 1
		}
	} catch {
		$LogType = "Error"
		"This error was thrown while getting the status of the website: `r`nWebsite FQDN: $WebSiteFQDN `r`n$ErrorMessage" | Write-BLLog -LogType $LogType
		"$Error" | Write-BLLog -LogType $LogType
		$Error.clear()
		Return 1
	} finally {
		$LogType = "Information"
		# Finally, we clean up the http request by closing it.
		"Clean up the http request. Closing it. Invoking: HTTP_Response.Close()" | Write-BLLog -LogType $LogType
		$HTTP_Response.Close() 
	}

	Return $ExitCode
}

Function Invoke-ISUninstallation() {
	$LogType = "Information"
	"Uninstallation is unprovided for the testing of the web site" | Write-BLLog -LogType $LogType
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
