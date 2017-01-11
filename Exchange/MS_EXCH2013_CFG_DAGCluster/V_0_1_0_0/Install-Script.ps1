<#
.SYNOPSIS
This script creates a new Database Availibility Group and adds the current server to that DAG.

.DESCRIPTION
This script creates a new Database Availability Group if it does not exist and adds the current server
to the DAG if it is not already a member of the DAG.

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
## Date					Version		By						Change Description
## --------------------------------------------------------------------------------------
## 31.05.2016			baumh								Initial version
## 16.11.2016			V0.1.0.0	Stefan Schmalz			Skript fertig Versionierung eingefügt.
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
Initialize-BLFunctions -AppName "MS_EXCH2013_CFG_DAGCluster" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.

"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

#Setting necessary variables
$cfg = @{}
$ExitCode = Get-BLConfigDBVariables $cfg -Defaults "$AppSource\Defaults.txt"
If ($ExitCode -ne 0) {
	"Error setting variables from ConfigDB, unable to continue!" | Write-BLLog -LogType Information
	Exit-BLFunctions -SetExitCode 1
}

Function Invoke-ISInstallation() {
## Make sure that $ExitCode is ONLY 0 if the install was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.

	## CUSTOMIZE: Check here if the software is installed; you can use "Get-Help Get-BLUninstallInformation -Full" for more complex options, like specific x86/x64 versions,
	## query by GUID, a specific version, or a Hotfix. Comment out if not required.
	$ExitCode = 1
	$LogType = "Information"
	#Adding the PSSNappIn for Exchange
	Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn

	$DAGName = $cfg["EX2013_INSTALL_DAG_NAME"]
	$DAGIP = $cfg["EX2013_INSTALL_DAG_IP"]
	$DAGWitnessServer = $cfg["EX2013_CFG_WITNESSSERVER"]
	$DAGWitnessShare = $cfg["EX2013_CFG_WITNESSSERVER_SHAREPATH"]
	$ServerName = hostname
	$ServerRole = $cfg["EX2013_INSTALL_ROLE"]
	$ComputerName = $DAGWitnessServer.Split(".")[0]
	if ($ServerRole -eq "MR") {
		try {
			$DAGs = Get-DatabaseAvailabilityGroup -ErrorAction Stop
			if ($DAGs.Name -contains $DAGName) {
				"The Database Availability Group - $DAGName - already exists. Skipping the creation of the DAG..." | Write-BLLog -LogType $LogType
			} else {
				try {
					$UserName = "Exchange Trusted Subsystem"
					$DomainName = $cfg["DOMAIN_NETBIOSNAME"]
					"The Database Availability Group - $DAGName - does not exist. Trying to create a new DAG now." | Write-BLLog -LogType $LogType
					"Adding the '$UserName' to the local admin group on the witness server." | Write-BLLog -LogType $LogType
					$AddETSS = Add-BLLocalAdminGroupMember -UserName $UserName -DomainName $DomainName -ComputerName $ComputerName
					if ($AddETSS -eq 0) {
						"Creating the new DAG. Invoking: New-DatabaseAvailabilityGroup -Name $DAGName -WitnessServer $DAGWitnessServer -WitnessDirectory $DAGWitnessShare -DatabaseAvailabilityGroupIpAddresses $DAGIP" | Write-BLLog -LogType $LogType
						$NewDAG = New-DatabaseAvailabilityGroup -Name $DAGName -WitnessServer $DAGWitnessServer -WitnessDirectory $DAGWitnessShare -DatabaseAvailabilityGroupIpAddresses $DAGIP -ErrorAction Stop
					}
				} catch {
					$ErrorMessage = $_.Exception.Message
					$LogType = "Error"
					"This error was thrown while creating the new Database Availibility Group - $DAGName : `r`n $ErrorMessage" | Write-BLLog -LogType $LogType
					$Error.clear()
					Return 1
				}
			}
		} catch {
			$ErrorMessage = $_.Exception.Message
			$LogType = "Error"
			"This error was thrown while creating of - or adding members to - the new Database Availibility Group : `r`n $ErrorMessage" | Write-BLLog -LogType $LogType
			$Error.clear()
			Return 1
		}
		
		$GetDAG = Get-DatabaseAvailabilityGroup -ErrorAction Stop
		
		$DAGMemberServer = $GetDAG.Servers.Name
		if ($DAGMemberServer -contains $ServerName) {
			"The current Exchange Server - $ServerName - is already a member of the DAG - $DAGName. Skipping the adding of the server to the DAG..." | Write-BLLog -LogType $LogType
			Return 0
		} else {
			try {
				"The current server is not a member of the DAG. Adding the server now. Invoking: Add-DatabaseAvailabilityGroupServer -MailboxServer $ServerName -Identity $DAGName" | Write-BLLog -LogType $LogType
				$NewDAGMember = Add-DatabaseAvailabilityGroupServer -MailboxServer $ServerName -Identity $DAGName -ErrorAction Stop
				Return 0
			} catch {
				$ErrorMessage = $_.Exception.Message
				$LogType = "Error"
				"This error was thrown while adding a member to the Database Availibility Group : `r`n $ErrorMessage" | Write-BLLog -LogType $LogType
				$Error.clear()
				Return 1		
			}
		}
	} elseif ($ServerRole -eq "ET") {
		"This server is a Edge Transport Server. Skipping this step." | Write-BLLog -LogType $LogType
		$ExitCode = 0
	} else {
		"No valid server role information found in ConfigDB variable EXCH_INSTALL_ROLE."|Write-BLLog -LogType Warning
		"Please check the variable in the ConfigDB."|Write-BLLog -LogType Warning
		"Configuration task cannot continue..."|Write-BLLog CriticalError
	}
	Return $ExitCode
}
#endregion Installation

#region uninstallation
Function Invoke-ISUninstallation() {

		"Uninstallation is unprovided for the creation of the DAG or the adding of a member to the DAG!" | Write-BLLog -LogType Information	
		$ExitCode = 0
	Return $ExitCode
}
#endregion uninstallation

## ====================================================================================================
## MAIN
## ====================================================================================================
## CUSTOMIZE: Uncomment to get information from ConfigDB if required (use of Defaults.txt is optional).
## - The use of Defaults.txt and Write-BLConfigDBSettings is optional
## - Add a filter to Write-BLConfigDBSettings to only show required variables (will filter ConfigDB variables beginning with this value)

 
	If (-Not $Uninstall) {
		$ExitCode = Invoke-ISInstallation
	} Else {
		$ExitCode = Invoke-ISUninstallation
	}
	



"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
