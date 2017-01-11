<#
.SYNOPSIS
This script executes the infrastructure preparation steps prior to the installation of Microsoft Lync Server 2013

.DESCRIPTION
Autor: Michael Wittmann, michael.wittmann@interface-ag.de
This script executes the infrastructure preparation steps for Lync.

1st step is the Schema Extension, which extends the Active Directory Schema with several Classes and Attributes
2nd step is the Forest Preparation, which sets forest wide privileges. 
Please note that for a successfull conclusion of this step we need several security groups in place before we execute the AD-Preparation:
- RTCHSUniversalServices
- RTCComponentUniversalServices
- RTCUniversalServerAdmins
- RTCUniversalConfigReplicator
3rd step is the Domain Preparation, which sets domain wide privileges.


The scripts runs as a task which runs under the account specified in the CFGDB-variable AD_CFG_DOMAINACCOUNT.
	

.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
Due to the extensive changes in Active Directory during the the preparation steps the uninstall parameter is not supported.

.EXAMPLE
install-Script -Force					Installation der Software
install-Script -Uninstall -Force		Deinstallation der Software

.OUTPUTS
The script writes a logifle in C:\RIS\Log.
The preparation steps write several log in xml-format. The log are found in C:\RIS\Log.

.NOTES
To run the script you have to be a member of the local administrator group and you have to run the powershell with elevated rights.
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
## 31.05.2016			baumh			Initial version
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
Initialize-BLFunctions -AppName "MS_LYNC2013_FE_PreReq_ADPrep" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

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
Write-BLConfigDBSettings -cfg $cfg -Filter "Domain_FQDN"
$Script:DomainFQDN =$cfg["Domain_FQDN"]


#Variables for ADPrep-Function

$ADDC = Get-BLADDomainController
$RegKey = "HKLM:\Software\Atos\MS_LYNC2013_FE_PreReq_ADPrep"
$SecondsToWait = 300

$SourceFolder ="\Source"
$SetupPath = Join-Path $AppSource $SourceFolder

$arrOp = @("SchemaExtension","ForestPrep","DomainPrep")




#region Installation
Function Invoke-ISInstallation() {
	$ExitCode = 1
	
<#	$UninstallInformation = Get-BLUninstallInformation -DisplayName $AppDisplayName
	If ($UninstallInformation.IsInstalled) {
		"Software is already installed - installation not necessary!" | Write-BLLog -LogType Information	
		$ExitCode = 0
	} else {
		$ExitCode = 1
	}
#>
	
	"+++ MS_LYNC2013_FE_PreReq_ADPrep started. +++"|Write-BLLog -LogType Information
	
	Foreach ($op in $arrOp){
	
		$ExitCode = Invoke-PrepOperation -SourcePath $SetupPath -DomainController $ADDC -KeyPath $RegKey -Operation $op
		
		if($ExitCode[$ExitCode.Count -1] -eq 0){
			$ExitCode = 0
		}
		else{
		
			$ExitCode = 1
			"There was an error during the step $op."|Write-BLLog -LogType CriticalError
			Return $ExitCode
		
		}
	}
	
	if($ExitCode -eq 0){
	
		"All AD-Preparation steps successfully concluded. Triggering AD-Replication."|Write-BLLog -LogType Information
		
		$ExitCode = Initialize-Replication -DomainController $ADDC
		
		if($ExitCode -eq 0){
		
			"AD-Replication successfully triggered. Waiting for 20 minutes."|Write-BLLog -LogType Information
			Start-Sleep -s 1200 
			
			
			"+++ MS_LYNC2013_FE_PreReq_ADPrep successfully concluded. +++"|Write-BLLog -LogType Information
		}
		else{
		
			"There was an error during the triggering the AD-Replication."|Write-BLLog -LogType CriticalError
			$ExitCode = 1
		}
		
	}

	Return $ExitCode
}
#endregion Installation

#region Uninstallation
Function Invoke-ISUninstallation() {
	$ExitCode = 0

	"Uninstall not supported."|Write-BLLog -LogType Warning
	"Please restore a backup of your Domain Controllers."|Write-BLLog -LogType Information
	Return $ExitCode
}
#endregion Uninstallation

## Funktion für ADReplikation

function Initialize-Replication{

#Triggers a full AD replication sync from the defined Domain Controller via PSRemoting and repadmin.exe

	Param(
		[Parameter(Mandatory=$True)]
		[string]$DomainController
	)

	# Create PSSession on the DC
	
	
	$PSS = New-PSSession -ComputerName $DomainController
	if(!$PSS){
		"Could not create a Powershell session on $DomainController."|Write-BLLog -LogType CriticalError
		"Check if $DomainController is reachable."|Write-BLLog -LogType CriticalError
		Return 1
	
	}
	
	# Execute repadmin in the PSSession
	$TR = Invoke-Command -Session $PSS -Scriptblock {
	
		$Repl = Start-Process repadmin -Argumentlist "/syncall" -wait
		
		if($Repl){
		
		"Triggering AD-Replication failed."|Write-BLLog -LogType CriticalError
		"Check System Log on $DomainController."|Write-BLLog -LogType CriticalError
		Return 1
		}
	
	}
	Return 0
}


function Test-RegValue{

#Checks if a Registry Property with a specific Value exists
#if it doesn't exist, it creates the Subkey with the property
#and sets the value for the property to  "not defined"

	Param(
		[Parameter(Mandatory=$True)]
		[string]$KeyPath,
		[Parameter(Mandatory=$True)]
		[string]$Value,
		[Parameter(Mandatory=$False)]
		[string]$Computer
	)

	
	
	Try{ 

		Get-BLRegistryValueX64 -Path $KeyPath -Name $Value -Computer $Computer
		"Registry Value $Value in $KeyPath exists." | Write-BLLog -LogType Information

	}

	Catch{
		"Registry Value $Value in $KeyPath doesn't exist. Creating Value right now!" | Write-BLLog -LogType Information
		# First create the key then create the property and set the value
		New-BLRegistryKeyX64 -Path $KeyPath -Computer $Computer
		Set-BLRegistryValueX64 -Path $KeyPath -Name $Value -Value "not defined" -Computer $Computer

	}





}



function Invoke-PrepOperation{

# Executes the ADPreparation-Commands for Lync Server 2013 and writes status markers in the registry of the domain controller

	Param(
		[Parameter(Mandatory=$True)]
		[string]$SourcePath,
		[Parameter(Mandatory=$True)]
		[string]$DomainController,
		[Parameter(Mandatory=$True)]
		[string]$KeyPath,
		[Parameter(Mandatory=$True)]
		[string]$Operation
	)
	# $Operation <= sets the operation = "SchemaExtension", "ForestPrep", "DomainPrep"
	# $SourcePath <= sets the path for the installation files (only needed for SchemaExtension)
	# $DomainController <= specifies the DomainController
	# $KeyPath <= sets the Path in the registry where the status for the operation is tracked
	
	$LDFPath = Join-Path $SourcePath "Binaries\Support\Schema"
	
	Test-RegValue -KeyPath $RegKey -Value $Operation -Computer $DomainController
	
	$PrepValue = Get-BLRegistryValueX64 -Path $KeyPath -Name $Operation -Computer $DomainController
	
	
		if($PrepValue -eq "not defined" -or $PrepValue -eq "error"){
			if($PrepValue -eq "not defined"){
			
			"This is the first time $Operation for Microsoft Lync Server 2013 is running."|Write-BLLog -LogType Information
			}
			elseif($PrepValue -eq "error"){
				"There was an error last time the $Operation was attempted. Trying again..."|Write-BLLog -LogType Warning
				"If this operation encounters an error again, check Logfiles in C:\RIS\Logs."|Write-BLLog -LogType Warning
			}
			
			"--- Starting Step $Operation ---"|Write-BLLog -LogType Information
						
			"Setting Property $Operation in $KeyPath to 'started'"|Write-BLLog -LogType Information
			
			Set-BLRegistryValueX64 -Path $KeyPath -Name $Operation -Value "started" -Computer $DomainController
			
			if($Operation -eq "SchemaExtension"){
			
				Install-CsADServerSchema -LDF $LDFPath -verbose
				$OperationOutput = Get-CsADServerSchema
				$OperationOutput|Write-BLLog -LogType Warning
				"Triggering AD-Replication after $Operation"|Write-BLLog -Information
				Initialize-Replication -DomainController $ADDC
				
			}
			elseif($Operation -eq "ForestPrep"){
			
				Enable-CsADForest -Groupdomain $Script:DomainFQDN -verbose
				$OperationOutput = Get-CsADForest
				$OperationOutput|Write-BLLog -LogType Warning
			}
			elseif($Operation -eq "DomainPrep"){
			
				Enable-CsADDomain -Domain $Script:DomainFQDN -verbose
				$OperationOutput = Get-CsADDomain
				$OperationOutput|Write-BLLog -LogType Warning
			}
			else{
			
				"The specified operation ($Operation) is not supported."|Write-BLLog -LogType Error
			}
			
			
						
			if($OperationOutput -eq "SCHEMA_VERSION_STATE_CURRENT" -or $OperationOutput -eq "LC_FORESTSETTINGS_STATE_READY" -or $OperationOutput -eq "LC_DOMAINSETTINGS_STATE_READY"){
			
				"Step $Operation successfully concluded."|Write-BLLog -LogType Information
				"Setting Property $Operation in $KeyPath to 'concluded'"|Write-BLLog -LogType Information
				Set-BLRegistryValueX64 -Path $KeyPath -Name $Operation -Value "concluded" -Computer $DomainController
				Return 0	
			}
			else{
			
				"Step $Operation encountered an error. Check logfiles in C:\RIS\Log"|Write-BLLog -LogType CriticalError
				"This is a severe error. Setup will not continue..."|Write-BLLog -LogType CriticalError
				"Setting Property $Operation in $KeyPath to 'error'"|Write-BLLog -LogType Information
				Set-BLRegistryValueX64 -Path $KeyPath -Name $Operation -Value "error" -Computer $DomainController
				Return 1				
			}
		}
		elseif($PrepValue -eq "started"){
			$RegKeyValue = $PrepValue
			$i=0
				while(($RegKeyValue -eq "started") -and ($i -le 3)){
					
					if($i -eq 0){
					
					"The registry key value of $KeyPath - $Operation is set to 'started'. Another AD-Prep may be running. Waiting for 5 minutes to let the other setup conclude."|Write-BLLog -LogType Warning
					$TimeElapsed = ($i+1)*5	
					}
					
					elseif($i -gt 0){
					
					"No change after $TimeElapsed minutes. The registry key value of $KeyPath - $Operation was not set to 'concluded' or 'error'." | Write-BLLog -LogType Information
					$TimeElapsed = ($i+1)*5					
					}
					
					Start-Sleep -Seconds $SecondsToWait
					$RegKeyValue = Get-BLRegistryValueX64 -Path $KeyPath -Name $Operation -Computer $DomainController
					$i++
					
				}
				if (($RegKeyValue -eq "started") -AND ($i -gt 3)) {
						
					"After $TimeElapsed minutes the registry key value of $KeyPath - $Operation was not set to 'concluded' or 'error'." | Write-BLLog -LogType CriticalError
					"Please take a look at the other servers and your Domain Controllers, maybe there is/was a problem with another Lync Server 2013 installation." | Write-BLLog -LogType CriticalError
					"Setup will not continue. Rerun after the problem is solved. Check logfiles in C:\RIS\Log" | Write-BLLog -LogType CriticalError
					Return 1
				}
				elseif ($RegKeyValue -eq "concluded") {
					
					"After $TimeElapsed minutes the registry key value of $KeyPath - $Operation was set to 'concluded'. Prepare Schema was concluded from another server."|Write-BLLog -LogType Information
					"This server skips the Step $Operation. Setup will continue with the next step."|Write-BLLog -LogType Information
					Return 0					
				}
				elseif ($RegKeyValue -eq "error") {
				
					"After $TimeElapsed minutes the registry key value of $KeyPath - $Operation was set to 'error'. Prepare Schema was started on another machine and encountered an error."|Write-BLLog -LogType Warning
					"This server will start the step $Operation again."|Write-BLLog -LogType Warning
					"If this operation encounters an error again, check Logfiles in C:\RIS\Logs."|Write-BLLog -LogType Warning
					"--- Starting Step $Operation ---"|Write-BLLog -LogType Information
								
					"Setting Property $Operation in $KeyPath to 'started'"|Write-BLLog -LogType Information
					
					Set-BLRegistryValueX64 -Path $KeyPath -Name $Operation -Value "started" -Computer $DomainController

					if($Operation -eq "SchemaExtension"){
			
						Install-CsADServerSchema -LDF $LDFPath -verbose
						$OperationOutput = Get-CsADServerSchema
						$OperationOutput|Write-BLLog -LogType Warning
						"Triggering AD-Replication after $Operation"|Write-BLLog -Information
						Initialize-Replication -DomainController $ADDC						
					}
					elseif($Operation -eq "ForestPrep"){
					
						Enable-CsADForest -Groupdomain $Script:DomainFQDN -verbose
						$OperationOutput = Get-CsADForest
						$OperationOutput|Write-BLLog -LogType Warning
					}
					elseif($Operation -eq "DomainPrep"){
					
						Enable-CsADDomain -Domain $Script:DomainFQDN -verbose
						$OperationOutput = Get-CsADDomain
						$OperationOutput|Write-BLLog -LogType Warning
					}
					else{
					
						"The specified operation ($Operation) is not supported."|Write-BLLog -LogType Error
					}
			
			
						
					if($OperationOutput -eq "SCHEMA_VERSION_STATE_CURRENT" -or $OperationOutput -eq "LC_FORESTSETTINGS_STATE_READY" -or $OperationOutput -eq "LC_DOMAINSETTINGS_STATE_READY"){
					
						"--- Step $Operation successfully concluded. ---"|Write-BLLog -LogType Information
						"Setting Property $Operation in $KeyPath to 'concluded'"|Write-BLLog -LogType Information
						Set-BLRegistryValueX64 -Path $KeyPath -Name $Operation -Value "concluded" -Computer $DomainController
						Return 0				
					}
					else{
					
						"Step $Operation encountered an error. Check logfiles in C:\RIS\Log"|Write-BLLog -LogType CriticalError
						"This is a severe error. Setup will not continue..."|Write-BLLog -LogType CriticalError
						"Setting Property $Operation in $KeyPath to 'error'"|Write-BLLog -LogType Information
						Set-BLRegistryValueX64 -Path $KeyPath -Name $Operation -Value "error" -Computer $DomainController
						Return 1						
					}
				
		
				}
				else{
				
					"--- Step $Operation is already concluded. ---"|Write-BLLog -LogType Information
					"This server skips the Step $Operation. Setup will continue with the next step."|Write-BLLog -LogType Information
					Return 0	
				}
		}
		else{				
			"--- Step $Operation is already concluded. ---"|Write-BLLog -LogType Information
			"This server skips the Step $Operation. Setup will continue with the next step."|Write-BLLog -LogType Information
			Return 0	
		}
}
	






## ====================================================================================================
## MAIN
## ====================================================================================================


#region RunAsTask
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
