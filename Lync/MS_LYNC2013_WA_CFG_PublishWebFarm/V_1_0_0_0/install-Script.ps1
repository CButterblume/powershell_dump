<#
.SYNOPSIS
This script publishes the Microsoft Office Web Apps 2013 Farm.

.DESCRIPTION
This script publishes the Microsoft Office Web Apps 2013 Farm.
The script needs some informations, especially the friendly name of the previous imported certificate.

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
ATTENTION: The user that runs this script has to be a member of the group Enterprise Admin.
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
Initialize-BLFunctions -AppName "MS_LYNC2013_CFG_WA_CFG_PublishWebFarm" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information


function Test-RegValue {
#Checks if a Registry Property with a specific Value exists
#if it doesn't exist, it creates the Subkey with the property
#and sets the value for the property to  "not defined"
	Param (
		[Parameter(Mandatory=$True)]
		[string]$KeyPath,
		[Parameter(Mandatory=$True)]
		[string]$Value,
		[Parameter(Mandatory=$False)]
		[string]$Computer
	)
	Try { 
		Get-BLRegistryValueX64 -Path $KeyPath -Name $Value -Computer $Computer
		"Registry Value $Value in $KeyPath exists." | Write-BLLog -LogType Information
	} Catch {
		"Registry Value $Value in $KeyPath doesn't exist. Creating Value right now!" | Write-BLLog -LogType Information
		# First create the key then create the property and set the value
		New-BLRegistryKeyX64 -Path $KeyPath -Computer $Computer
		Set-BLRegistryValueX64 -Path $KeyPath -Name $Value -Value "not defined" -Computer $Computer
	}
}

function Add-ServerToWebAppsFarm () {
	Param (
		[Parameter(Mandatory=$True)]
		$FarmMember,
		[Parameter(Mandatory=$True)]
		$DomainFQDN,
		[Parameter(Mandatory=$True)]
		$ServerName
	)
	try {
		"Adding this server to the Microsoft Office Web Apps Farm." | Write-BLLog -LogType $LogType
		$Server2Join = $FarmMember + "." + $DomainFQDN
		"Invoking: New-OfficeWebAppsMachine -MachineToJoin $Server2Join -Force" | Write-BLLog -LogType $LogType
		$ExitCode = New-OfficeWebAppsMachine -MachineToJoin $Server2Join -Force
		if ($ExitCode.MachineName -eq $ServerName) {
			"The Server was successful added to the Office Web Apps Farm." | Write-BLLog -LogType $LogType
			"Adding the server to the registry Key of the farm members." | Write-BLLog -LogType $LogType
			try {
				"Testing the .NET-Installation. Invoking: Get-OfficeWebAppsFarm" | Write-BLLog -LogType $LogType
				$TestOWA = Get-OfficeWebAppsFarm
			} catch [System.Exception] {
				$StatusCode = [int]$Error.Exception.InnerException.Response.StatusCode
				"Exception found: WebStatusCode = $StatusCode" | Write-BLLog -LogType $LogType
				if (($StatusCode -eq 500) -OR ($StatusCode -eq 501)) {
					$LogType = "Warning"
					"Response was $StatusCode. There could be an issue with .NET 4.5.Trying to repair the .NET Installation." | Write-BLLog -LogType $LogType
					"Invoking: Invoke-BLSetupOther -FileName $FileName -Arguments $Arguments" | Write-BLLog -LogType $LogType
					$WinDir = $Env:windir
					$Dir = Join-Path $WinDir "Microsoft.NET\Framework64\v4.0.30319"
					$FileName = Join-Path $Dir "aspnet_regiis.exe"
					$Arguments = "-i"
					$InstallEC = Invoke-BLSetupOther -FileName $FileName -Arguments $Arguments
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
			}
			$FarmMember = Get-BLRegistryValueX64 -Path $KeyPath -Name $FarmMemberKeyName -Computer $DC
			if ($FarmMember -Contains $ServerName) {
				"The server was a member of the farm before and the key already contains the server name. Skipping the setting of the registry key..." | Write-BLLog -LogType $LogType
				$ExitCode = 0
			} else {
				$FarmMember = $Farmmember + "," + $ServerName
				"Setting the Key - $KeyPath\$FarmMemberKeyName - to - $FarmMember ." | Write-BLLog -LogType $LogType
				"Invoking: Set-BLRegistryValueX64 -Path $KeyPath -Name $FarmMemberKeyName -Value $ServerName -Computer $DC " | Write-BLLog -LogType $LogType
				$SetFarmMembers = Set-BLRegistryValueX64 -Path $KeyPath -Name $FarmMemberKeyName -Value $FarmMember -Computer $DC
				$ExitCode = 0
			}
		} else {
			$LogType = "Error"
			"An error occured while adding the $FarmMember to the Office Web Apps Farm." | Write-BLLog -LogType $LogType
			Return 1
		}
	} catch {
		$LogType = "Error"
		$ErrorMessage = $_.Exception.Message
		"Could not create a PSSession on $ComputerName. An error occured: $ErrorMessage" | Write-BLLog -LogType $LogType
		$Error.Clear()
		Return 1
	}
	Return $ExitCode
}

#region Installation
Function Invoke-ISInstallation() {
	$ExitCode = 1
	$LogType = "Information"
	$ServerName = hostname
	$DomainFQDN = $cfg["DOMAIN_FQDN"]
	$OfficeWebAppsPoolName = $cfg["LYNC2013_CFG_WA_POOL_NAME"]
	$LogLocation = $cfg["LYNC2013_CFG_WA_LOG_PATH"]
	$CacheLocation = $cfg["LYNC2013_CFG_WA_CACHE_PATH"]
	$RenderingLocalCacheLocation = $cfg["LYNC2013_CFG_WA_RENDERING_PATH"]
	$InternalUrl = "https://" + $OfficeWebAppsPoolName + "." + $DomainFQDN
	$CertificateName = $cfg["LYNC2013_CFG_WA_CERT_FRIENDLY_NAME"]

	$DC = Get-BLADDomainController
	$KeyPath = "HKLM:\Software\Atos\MS_LYNC2013_WA_CFG_PublishWebFarm"
	$Operation = "CreateFarm"
	$FarmMemberKeyName = "FarmMember"
	$TestRegKey = Test-RegValue -KeyPath $KeyPath -Value $Operation -Computer $DC
	$FarmValue = Get-BLRegistryValueX64 -Path $KeyPath -Name $Operation -Computer $DC
	$FarmMember = Get-BLRegistryValueX64 -Path $KeyPath -Name $FarmMemberKeyName -Computer $DC -ErrorAction SilentlyContinue

	if ($FarmMember) {
		if ($FarmMember.Split(",") -Contains $ServerName) {
			"The server was part of the farm before. Deleting the entry for this server in the registry of the DC." | Write-BLLog -LogType $LogType
			$FarmMember = $FarmMember.Split(",")
			foreach ($Member in $FarmMember) {
				if (($Member -ne $ServerName) -AND (!$NewMembers)) {
					"This server is not the current server. Adding it to the registry value variable" | Write-BLLog -LogType $LogType
					$NewMembers = $Member
				} elseif (($Member -ne $ServerName) -AND ($NewMembers)) {
					$NewMembers = $NewMembers + "," + $Member
					"Adding the server $Member to the registry value variable. New Value: $NewMembers" | Write-BLLog -LogType $LogType
				} elseif ($Member -eq $ServerName) {
					"The server was marked for deletion in the registry key. Skipping to add the servername to the registry value variable." | Write-BLLog -LogType $LogType
				} else {
					$LogType = "Error"
					"Unexpected error while creating the new registry value without this server - $ServerName `r`nValue of the variable $NewMembers" | Write-BLLog -LogType $LogType
					Return 1
				}
			}
			
			if (!$NewMembers) {
				"No other server was installed before, the farm has to be created again. Deleting the registry key on the PDC." | Write-BLLog -LogType $LogType
				"Invoking: Remove-BLRegistryKeyX64 -Path $KeyPath -Computer $DC" | Write-BLLog -LogType $LogType
				$RemoveCompleteRegKeys = Remove-BLRegistryKeyX64 -Path $KeyPath -Computer $DC
				"Creating the default registry key for a new installation." | Write-BLLog -LogType $LogType
				"Invoking: Test-RegValue -KeyPath $KeyPath -Value $Operation -Computer $DC" | Write-BLLog -LogType $LogType
				$TestRegKey = Test-RegValue -KeyPath $KeyPath -Value $Operation -Computer $DC
			} else {
				"Setting the new value of the registry key - $KeyPath\$FarmMemberKeyName ." | Write-BLLog -LogType $LogType
				$SetNewMembersRegKey = Set-BLRegistryValueX64 -Path $KeyPath -Name $FarmMemberKeyName -Value $NewMembers -Computer $DC
			}
		} else {
			"The server was not a member before. Skipping the change of the registry Key." | Write-BLLog -LogType $LogType
		}
	} else {
		"No farm member specified in the registry. This is a new installation. Skipping this step." | Write-BLLog -LogType $LogType
	}
	
	$FarmValue = Get-BLRegistryValueX64 -Path $KeyPath -Name $Operation -Computer $DC
	if ($FarmValue -eq "not defined" -or $FarmValue -eq "error") {
		if ($FarmValue -eq "not defined") {
			"This is the first time $Operation for Microsoft Office Web Apps Server 2013 is running." | Write-BLLog -LogType $LogType
		} elseif ($FarmValue -eq "error") {
			"There was an error last time the $Operation was attempted. Trying again..." | Write-BLLog -LogType Warning
			"If this operation encounters an error again, check Logfiles in C:\RIS\Logs." | Write-BLLog -LogType Warning
		}
		"Create new Office Web Apps farm." | Write-BLLog -LogType $LogType
		"Setting the registry Key to 'Started'. Invoking: Set-BLRegistryValueX64 -Path $KeyPath -Name $Operation -Value 'Started' -Computer $DC" | Write-BLLog -LogType $LogType
		$SetFarmRegToStarted = Set-BLRegistryValueX64 -Path $KeyPath -Name $Operation -Value "Started" -Computer $DC
		"Invoking: New-OfficeWebAppsFarm -InternalUrl $InternalUrl -CertificateName $CertificateName –LogLocation $LogLocation –CacheLocation $CacheLocation –RenderingLocalCacheLocation $RenderingLocalCacheLocation -verbose -Force" | Write-BLLog -LogType $LogType
		$ExitCode = New-OfficeWebAppsFarm -InternalUrl $InternalUrl -CertificateName $CertificateName –LogLocation $LogLocation –CacheLocation $CacheLocation –RenderingLocalCacheLocation $RenderingLocalCacheLocation -verbose -Force
		
		
		$EC = $ExitCode.GetType().Name
		if ($EC -eq "OfficeWebAppsFarm") {
			"ExitCode type name is 'OfficeWebAppsFarm' changeing Exitcode to 0, the farm was created." | Write-BLLog -LogType $LogType
			try {
				$TestOWA = Get-OfficeWebAppsFarm
			} catch [System.Exception] {
				$StatusCode = [int]$Error.Exception.InnerException.Response.StatusCode
				"Exception found: WebStatusCode = $StatusCode" | Write-BLLog -LogType $LogType
				if (($StatusCode -eq 500) -OR ($StatusCode -eq 501)) {
					$LogType = "Warning"
					"Response was $StatusCode. There could be an issue with .NET 4.5.Trying to repair the .NET Installation." | Write-BLLog -LogType $LogType
					"Invoking: Invoke-BLSetupOther -FileName $FileName -Arguments $Arguments" | Write-BLLog -LogType $LogType
					$WinDir = $Env:windir
					$Dir = Join-Path $WinDir "Microsoft.NET\Framework64\v4.0.30319"
					$FileName = Join-Path $Dir "aspnet_regiis.exe"
					$Arguments = "-i"
					$InstallEC = Invoke-BLSetupOther -FileName $FileName -Arguments $Arguments
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
			}
			"Setting the registry Key to 'Created'. Invoking: Set-BLRegistryValueX64 -Path $KeyPath -Name $Operation -Value 'Created' -Computer $DC" | Write-BLLog -LogType $LogType
			$SetFarmRegToCreated = Set-BLRegistryValueX64 -Path $KeyPath -Name $Operation -Value "Created" -Computer $DC
			"Setting the farm creator name now. Invoking: Set-BLRegistryValueX64 -Path $KeyPath -Name $FarmMemberKeyName -Value ServerName -Computer $DC	" | Write-BLLog -LogType $LogType
			$SetCreatorName = Set-BLRegistryValueX64 -Path $KeyPath -Name $FarmMemberKeyName -Value $ServerName -Computer $DC			
			$ExitCode = 0
		} else {
			$LogType = "Error"
			"Setting the registry Key to 'Error'. Invoking: Set-BLRegistryValueX64 -Path $KeyPath -Name $Operation -Value 'Error' -Computer $DC" | Write-BLLog -LogType $LogType
			$SetFarmRegToError = Set-BLRegistryValueX64 -Path $KeyPath -Name $Operation -Value "Error" -Computer $DC	
			"An error occured while creating the Offce Web Apps Farm. Please take a look at the log files at C:\RIS\Log" | Write-BLLog -LogType $LogType
			Return 1
		}	
	} elseif ($FarmValue -eq "Created") {
		"The farm was created before. Skipping the creation of the farm..." | Write-BLLog -LogType $LogType
		$FarmMember = Get-BLRegistryValueX64 -Path $KeyPath -Name $FarmMemberKeyName -Computer $DC
		if ($FarmMember.Split(",").Count -gt 1) {
			$FarmMember = $FarmMember.Split(",")[0]
			"Setting farm member on which the Office Web Apps farm is running: $FarmMember" | Write-BLLog -LogType $LogType
		} else {
			"Setting the farm member on which the Office Web Apps farm is running: $FarmMember" | Write-BLLog -LogType $LogType
		}
		
		try {
			"Invoking: Add-ServerToWebAppsFarm -FarmMember $FarmMember -DomainFQDN $DomainFQDN -ServerName $ServerName" | Write-BLLog -LogType $LogType
			$ExitCode = Add-ServerToWebAppsFarm -FarmMember $FarmMember -DomainFQDN $DomainFQDN -ServerName $ServerName
		} catch {
			$LogType = "Error"
			"This error was thrown while getting the status of the website: `r`nWebsite FQDN: $WebSiteFQDN `r`n$ErrorMessage" | Write-BLLog -LogType $LogType
			"$Error" | Write-BLLog -LogType $LogType
			$Error.clear()
			Return 1
		}
	} elseif ($FarmValue -eq "Started") {
		"Another server is creating the farm right now. Waiting for the server to finish." | Write-BLLog -LogType $LogType
		$i = 0
		While (($FarmValue -eq "Started") -AND ($i -lt 15)) {
			Start-Sleep -Seconds 60
			$FarmValue = Get-BLRegistryValueX64 -Path $KeyPath -Name $Operation -Computer $DC
			$i++
		}
		if ($FarmValue -eq "Started") {
			$LogType = "Error"
			"The registry Key $KeyPath\$Operation is after 15 minutes still 'Started'. Please take a look at the other Office Web Apps Server." | Write-BLLog -LogType $LogType
			"We cancel the creation and/or the joining of the farm now. Be sure the other servers are healthy and `r`nthe registry key displays the right status of the farm creation." | Write-BLLog -LogType $LogType
			Return 1
		} elseif ($FarmValue -eq "Created") {
			$FarmMember = Get-BLRegistryValueX64 -Path $KeyPath -Name $FarmMemberKeyName -Computer $DC
			"The farm was just created by $FarmMember." | Write-BLLog -LogType $LogType
			"Adding this server to the Microsoft Office Web Apps Farm." | Write-BLLog -LogType $LogType
			"Invoking: Add-ServerToWebAppsFarm -FarmMember $FarmMember -ServerName $ServerName" | Write-BLLog -LogType $LogType
			$ExitCode = Add-ServerToWebAppsFarm -FarmMember $FarmMember -ServerName $ServerName
		}
	}

	"Searching for the Office Web Apps Server master machine. Invoking: (Get-OfficeWebAppsMachine).MasterMachineName" | Write-BLLog -LogType $LogType
	$MasterServer = (Get-OfficeWebAppsMachine).MasterMachineName
	"Master machine is: $MasterServer. Setting registry key for this." | Write-BLLog -LogType $LogType
	$MasterServerValue = Get-BLRegistryValueX64 -Path $KeyPath -Name "MasterServer" -ComputerName $DC -ErrorAction SilentlyContinue
	if ($MasterServerValue) {
		if ($MasterServerValue -eq $MasterServer) {
			"The current Office Web Apps Master Server ($MasterServer) is the same as set in the registry ($MasterServerValue). Skipping the setting of the value..." | Write-BLLog -LogType $LogType
		} else {
			"The current Office Web Apps Master Server ($MasterServer) is not the same as the one that is set in the registry ($MasterServerValue)." | Write-BLLog -LogType $LogType
			"Setting the new Office Web Apps Master Server now." | Write-BLLog -LogType $LogType
			"Invoking: Set-BLRegistryValueX64 -Path $KeyPath -Name MasterServer -Value $MasterServer -Computer $Computer" | Write-BLLog -LogType $LogType
			$SetMasterServerValue = Set-BLRegistryValueX64 -Path $KeyPath -Name "MasterServer" -Value $MasterServer -Computer $DC
		}
	} else {
		"A value for the Office Web Apps Master Server was not set yet. Creating the value right now." | Write-BLLog -LogType $LogType
		"Invoking: Set-BLRegistryValueX64 -Path $KeyPath -Name MasterServer -Value $MasterServer -Computer $Computer" | Write-BLLog -LogType $LogType
		$SetCreatedMasterServerValue = Set-BLRegistryValueX64 -Path $KeyPath -Name "MasterServer" -Value $MasterServer -Computer $DC
	}

	Return $ExitCode
}
#endregion

Function Invoke-ISUninstallation() {
	"Uninstallation is unprovided for the Office Web Apps Farm creation!" | Write-BLLog -LogType Information	
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
$TaskUserDomain =	$cfg["AD_CFG_DOMAINACCOUNT"].Split("\")[0].Trim()
$TaskUsername =		$cfg["AD_CFG_DOMAINACCOUNT"].Split("\").Split(";")[1].Trim()
$TaskPassword =		$cfg["AD_CFG_DOMAINACCOUNT"].Split(";")[1].Trim()
### Start a second instance of the script; the main instance will wait here until the task instance is done:
$ExitCode = Enter-BLExecutionAsTask -UserName $TaskUsername -UserDomain $TaskUserDomain -UserPass $TaskPassword -Timeout 20 -NoTask
If ($ExitCode -eq -2) {				# Task could not be created; this is a serious error
   $ExitCode = 1
} ElseIf ($ExitCode -eq -1) {		# we're running as a scheduled task; this is a second instance of the script!
	$CurrentUserDomain, $CurrentUserName = (& whoami.exe).Split("\")
	If ($CurrentUserName -eq "SYSTEM") {
		"Installation can not be run with user account '$($CurrentUserDomain)\$($CurrentUserName)'" | Write-BLLog -LogType CriticalError
		Exit-BLFunctions -SetExitCode 1
	}
##END OPTION
#endregion RunAsTask
 
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
