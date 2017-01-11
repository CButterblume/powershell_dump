<#
.SYNOPSIS
This script starts the lync services on the servers that are set in the topology.

.DESCRIPTION
This script starts the lync services on the servers that are set in the topology.

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
The script writes a log file to C:\RIS\Log
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
## Date					Version		By								Change Description
## --------------------------------------------------------------------------------------
## 01.01.1980			Author 		Name							Initial version
## 12.12.2016			V1.0.0.0	Stefan Schmalz (IF)				Skript fertig.
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

Initialize-BLFunctions -AppName "MS_LYNC2013_StartServices" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall

"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

#region installation
Function Invoke-ISInstallation() {
	$LogType = "Information"
	$ExitCode = 1
	$DomainFQDN = $cfg["DOMAIN_FQDN"]
	$FEPoolName = $cfg["LYNC2013_CFG_FE_POOL_NAME"] + "." + $DomainFQDN
	$PCPoolName = $cfg["LYNC2013_CFG_PC_POOL_NAME"] + "." + $DomainFQDN
	$ETPoolName = $cfg["LYNC2013_CFG_ET_POOL_NAME"]	+ "." + $DomainFQDN
	$SvcStati = @{1 = "Stopped"; 2 = "Starting"; 3 = "Stopping"; 4 = "Running"; 5 = "Continue is pending"; 6 = "Pause is pending"; 7 = "Paused"}
	$ServiceExitCode = @()
	"Searching for FrontEnd Servers. Invoking: Get-CsPool -Identity $FEPoolName" | Write-BLLog -LogType $LogType
	$FEServer = (Get-CsPool -Identity $FEPoolName).Computers
	if ($FEServer) {
		"######################################################################" | Write-BLLog -LogType $LogType
		"########################## FrontEnd Servers ##########################" | Write-BLLog -LogType $LogType
		try {
			foreach ($Server in $FEServer) {
				"#####################################################################################" | Write-BLLog -LogType $LogType
				"###################### Start of 'starting services on $Server' ######################" | Write-BLLog -LogType $LogType				
				"Opening new PsSession to $Server. Invoking: New-PsSession -ComputerName $Server" | Write-BLLog -LogType $LogType
				$PSS = New-PsSession -ComputerName $Server -ErrorAction Stop
				"Starting the Lync services on $Server. Invoking: Invoke-Command -Session $PSS -ScriptBlock {Start-CSWindowsService}" | Write-BLLog -LogType $LogType
				$SvcStatus = Invoke-Command -Session $PSS -ScriptBlock {Start-CSWindowsService -ErrorAction SilentlyContinue;Get-CsWindowsService | Select-Object Name, Status}
				foreach ($Service in $SvcStatus) {
					$ServiceName = $Service.Name
					$ServiceStatus = $Service.Status
					$Status = $SvcStati.Get_Item($ServiceStatus)
					if ($ServiceStatus -ne 4) {
						"$ServiceName is not running. The current status is: $Status " | Write-BLLog -LogType Warning
						$Text = "$Server=$ServiceName=$Status"
						$ServiceExitCode += $Text
					} else {
						"$ServiceName is in the status $Status." | Write-BLLog -LogType Information
					}
				}
				"Removing the open PSSession to $Server" | Write-BLLog -LogType $LogType
				$RemovePSS = Remove-PsSession -Session $PSS
				"####################### End of 'starting services on $Server' #######################" | Write-BLLog -LogType $LogType
				"#####################################################################################" | Write-BLLog -LogType $LogType
			}
		} catch {
			"This error was thrown while trying to start the Lync services on $Server"  | Write-BLLog -LogType $LogType
			"$Error" | Write-BLLog -LogType Error
			$Error.clear()
			Return 1
		}
	} else {
		"There is now FrontEnd Server in the environment or an error occured while searching for FrontEnd Servers." | Write-BLLog -LogType Warning
	}
	"####################### End of FrontEnd Servers #######################" | Write-BLLog -LogType $LogType
	"#######################################################################" | Write-BLLog -LogType $LogType
	
	
	
	"Searching for Persistent Chat Servers. Invoking: Get-CsPool -Identity $PCPoolName" | Write-BLLog -LogType $LogType
	$PCServer = (Get-CsPool -Identity $PCPoolName).Computers 
	if ($PCServer) {
		"#######################################################################" | Write-BLLog -LogType $LogType
		"####################### Persistent Chat Servers #######################" | Write-BLLog -LogType $LogType
		try {
			foreach ($Server in $PCServer) {
				"#####################################################################################" | Write-BLLog -LogType $LogType
				"###################### Start of 'starting services on $Server' ######################" | Write-BLLog -LogType $LogType
				"Opening new PsSession to $Server. Invoking: New-PsSession -ComputerName $Server" | Write-BLLog -LogType $LogType
				$PSS = New-PsSession -ComputerName $Server -ErrorAction Stop
				"Starting the Lync services on $Server. Invoking: Invoke-Command -Session $PSS -ScriptBlock {Start-CSWindowsService}" | Write-BLLog -LogType $LogType
				$SvcStatus = Invoke-Command -Session $PSS -ScriptBlock {Start-CSWindowsService -ErrorAction SilentlyContinue;Get-CsWindowsService | Select-Object Name, Status}
				foreach ($Service in $SvcStatus) {
					$ServiceName = $Service.Name
					$ServiceStatus = $Service.Status
					$Status = $SvcStati.Get_Item($ServiceStatus)
					if ($ServiceStatus -ne 4) {
						"$ServiceName is not running. The current status is: $Status " | Write-BLLog -LogType Warning
						$Text = "$Server=$ServiceName=$Status"
						$ServiceExitCode += $Text
					} else {
						"$ServiceName is in the status $Status." | Write-BLLog -LogType Information
					}
				}
				"Removing the open PSSession to $Server" | Write-BLLog -LogType $LogType
				$RemovePSS = Remove-PsSession -Session $PSS
				"####################### End of 'starting services on $Server' #######################" | Write-BLLog -LogType $LogType
			}
		} catch {
			"This error was thrown while trying to start the Lync services on $Server"  | Write-BLLog -LogType $LogType
			"$Error" | Write-BLLog -LogType Error
			$Error.clear()
			Return 1
		}
	} else {
		"There is no Persistent Chat Server in the environment or an error occured while searching for Persistent Chat servers."  | Write-BLLog -LogType Warning
	}
	"####################### End of Persistent Chat Servers #######################" | Write-BLLog -LogType $LogType
	"##############################################################################" | Write-BLLog -LogType $LogType

	
	"Searching for Edge Servers. Invoking: Get-CsPool -Identity $ETPoolName" | Write-BLLog -LogType $LogType
	$ETServer = (Get-CsPool -Identity $ETPoolName).Computers 
	if ($ETServer) {
		"######################################################################" | Write-BLLog -LogType $LogType
		"############################ Edge Servers ############################" | Write-BLLog -LogType $LogType
		try {
			foreach ($Server in $ETServer) {
				"#####################################################################################" | Write-BLLog -LogType $LogType
				"###################### Start of 'starting services on $Server' ######################" | Write-BLLog -LogType $LogType
				"Opening new PsSession to $Server. Invoking: New-PsSession -ComputerName $Server" | Write-BLLog -LogType $LogType
				$PSS = New-PsSession -ComputerName $Server -ErrorAction Stop
				"Starting the Lync services on $Server. Invoking: Invoke-Command -Session $PSS -ScriptBlock {Start-CSWindowsService}" | Write-BLLog -LogType $LogType
				$SvcStatus = Invoke-Command -Session $PSS -ScriptBlock {Start-CSWindowsService -ErrorAction SilentlyContinue;Get-CsWindowsService | Select-Object Name, Status}
				foreach ($Service in $SvcStatus) {
					$ServiceName = $Service.Name
					$ServiceStatus = $Service.Status
					$Status = $SvcStati.Get_Item($ServiceStatus)
					if ($ServiceStatus -ne 4) {
						"$ServiceName is not running. The current status is: $Status " | Write-BLLog -LogType Warning
						$Text = "$Server=$ServiceName=$Status"
						$ServiceExitCode += $Text
					} else {
						"$ServiceName is in the status $Status." | Write-BLLog -LogType Information
					}
				}
				"Removing the open PSSession to $Server" | Write-BLLog -LogType $LogType
				$RemovePSS = Remove-PsSession -Session $PSS
				"####################### End of 'starting services on $Server' #######################" | Write-BLLog -LogType $LogType
			}
		} catch {
			"This error was thrown while trying to start the Lync services on $Server"  | Write-BLLog -LogType $LogType
			"$Error" | Write-BLLog -LogType Error
			$Error.clear()
			Return 1
		}
	} else {
		"There is no Edge Server in the environment or an error occured while searching for Edge servers."  | Write-BLLog -LogType Warning
	}
	"####################### End of Edge Servers #######################" | Write-BLLog -LogType $LogType
	"###################################################################" | Write-BLLog -LogType $LogType
	if ($ServiceExitCode) {	
		foreach ($Exits in $ServiceExitCode) {
		#$Server=$ServiceName=$Status"
			$Server = $Exits.Split("=")[0]
			$Service = $Exits.Split("=")[1]
			$Status = $Exits.Split("=")[2]
			"On Server '$Server' the Service '$Service' is not running and in the status $Status." | Write-BLLog -LogType Error
		}
		$ExitCode = 1
	} else {
		"No services found that are not running. Setting ExitCode to 0" | Write-BLLog -LogType $LogType
		$ExitCode = 0
	}
	Return $ExitCode
}
#endregion installation

#region uninstallation
Function Invoke-ISUninstallation() {
	$LogType = "Information"
	$ExitCode = 0
	"There is no uninstallation provided for MS_LYNC2013_StartServices" | Write-BLLog -LogType $LogType
	Return $ExitCode
}
#endregion uninstallation



## ====================================================================================================
## MAIN
## ====================================================================================================

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


"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
