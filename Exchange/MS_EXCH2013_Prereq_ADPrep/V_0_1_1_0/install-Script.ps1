<#
.SYNOPSIS
This script executes the Topology Preparation Steps prior to installation of MS Exchange Server 2013

.DESCRIPTION
This script executes the Topology Preparation steps for Exchange.

1st step is Prepare Schema, which extends the Active Directory Schema with several Classes and Attributes
2nd step is Prepare Active Directory, which defines the name of the Exchange Organization and adds 
Forest-wide Security Groups and privileges
3rd step is Prepare All Domains, which adds Security groups and privileges in the domains.


.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 
In this case we have no uninstallation routine. It is advised to restore the Active directory.

.EXAMPLE
install-Script.ps1 -Force
install-Script.ps1 -Uninstall

.OUTPUTS
The installation writes logs in the folders C:\RIS\Logs and C:\ExchangeSetupLogs

.NOTES
The script runs as a task under a user account with priviledges of a schema and enterprise administrator.
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
If (-Not (Import-Module $BaseLibrary -PassThru)) {Write-Host -ForegroundColor Red "[CriticalError] File not found - '$BaseLibrary'"; Exit 1}

$ScriptItem = Get-Item -Path $MyInvocation.MyCommand.Path
$Local:ScriptFullName = $ScriptItem.FullName
$Local:ScriptName = $ScriptItem.Name
$Local:ScriptPath = $ScriptItem.DirectoryName

## CUSTOMIZE: Edit value for the AppName parameter <Appname> below; use only characters allowed in file names, no spaces:
Initialize-BLFunctions -AppName "MS_EXCH2013_Prereq_ADPrep" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
## $AppDisplayName = Throw "Template TODO:  Insert 'Uninstall DisplayName' as described in the line above"

"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

##NOTUSED
#region Std-Installation "FileCopyOnly" use this if you only want to copy all files from $AppSource\Source  to C:\RIS\FILES\$Appname, delete it otherwise
#$DstDir = "C:\RIS\FILES\$AppName"
#endregion

#region CFGDB/defaults.txt

$cfg = @{}
$ExitCode = Get-BLConfigDBVariables $cfg -Defaults "$AppSource\Defaults.txt"
If ($ExitCode -ne 0) {
	"Error setting variables from ConfigDB, unable to continue!" | Write-BLLog -LogType Information
	Exit-BLFunctions -SetExitCode 1
}
Write-BLConfigDBSettings -cfg $cfg -Filter "COMPUTER_RegisteredOrganization"
$Script:ExchangeOrga = $cfg["COMPUTER_RegisteredOrganization"] # Here is the ExchangeOrganization defined
Write-BLConfigDBSettings -cfg $cfg -Filter "AD_CFG_DOMAINACCOUNT"


#endregion

#Variables für ADPrep-Operations
#$Script:ExchangeOrga = "ExchangeOrga"  #Only for Testing

$ADDC = Get-BLADDomainController
$RegKey = "HKLM:\Software\Atos\MS_EXCH2013_Prereq_ADPREP"
$SecondsToWait = 300








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



function Invoke-PrepareSchema{

	Param(
		[Parameter(Mandatory=$True)]
		[string]$SetupFile,
		[Parameter(Mandatory=$True)]
		[string]$DomainController,
		[Parameter(Mandatory=$True)]
		[string]$KeyPath	
	)

	Test-RegValue -KeyPath $RegKey -Value "PS" -Computer $DomainController
	
	$PrepValue = Get-BLRegistryValueX64 -Path $KeyPath -Name "PS" -Computer $DomainController

	if($PrepValue -eq "not defined" -or $PrepValue -eq "error"){
		if($PrepValue -eq "not defined"){
			
			"This is the first time Prepare Schema is running"|Write-BLLog -LogType Information
			}
			elseif($PrepValue -eq "error"){
				"There was an error last time Prepare Schema was attempted. Trying again..."|Write-BLLog -LogType Warning
				"If this operation encounters an error again, check Logfiles in C:\ExchangeSetupLogs and C:\RIS\Logs."|Write-BLLog -LogType Warning
			}
			
			"Starting Step Prepare Schema..."|Write-BLLog -LogType Information
			"-------------------------------"|Write-BLLog -LogType Information
			
			"Setting PS-Property in $KeyPath to 'started'"|Write-BLLog -LogType Information
			
			Set-BLRegistryValueX64 -Path $KeyPath -Name "PS" -Value "started" -Computer $DomainController

			$ps = Invoke-BLSetupOther -FileName $SetupFile -Arguments "/PS /IAcceptExchangeServerLicenseTerms"
			
			
			
			
			if($ps){
			
				"Step Prepare Schema encountered an error. Check logfiles in C:\ExchangeSetupLogs and C:\RIS\Log"|Write-BLLog -LogType CriticalError
				"This is a severe error. Setup will not continue..."|Write-BLLog -LogType CriticalError
				"Setting PS-Property in $KeyPath to 'error'"|Write-BLLog -LogType Information
				Set-BLRegistryValueX64 -Path $KeyPath -Name "PS" -Value "error" -Computer $DomainController
				Return 1
		
			}else{
				
				"Step Prepare Schema successfully concluded"|Write-BLLog -LogType Information
				"------------------------------------------"|Write-BLLog -LogType Information
				"Setting PS-Property in $KeyPath to 'concluded'"|Write-BLLog -LogType Information
				Set-BLRegistryValueX64 -Path $KeyPath -Name "PS" -Value "concluded" -Computer $DomainController
				Return 0
			}
		}
		elseif($PrepValue -eq "started"){
			$RegKeyValue = $PrepValue
			$i=0
				while(($RegKeyValue -eq "started") -and ($i -le 3)){
					
					if($i -eq 0){
					
					"The registry key value of $KeyPath - PS is set to 'started'. Another AD-Prep may be running. Waiting for 5 minutes to let the other setup conclude."|Write-BLLog -LogType Warning
					$TimeElapsed = ($i+1)*5	
					}
					
					elseif($i -gt 0){
					
					"No change after $TimeElapsed minutes. The registry key value of $KeyPath - PS was not set to 'concluded' or 'error'." | Write-BLLog -LogType Information
					$TimeElapsed = ($i+1)*5
					
					}
					
					Start-Sleep -Seconds $SecondsToWait
					$RegKeyValue = Get-BLRegistryValueX64 -Path $KeyPath -Name "PS" -Computer $DomainController
					$i++
					
				}
				if (($RegKeyValue -eq "started") -AND ($i -gt 3)) {
						
					"After $TimeElapsed minutes the registry key value of $KeyPath - PS was not set to 'concluded' or 'error'." | Write-BLLog -LogType CriticalError
					"Please take a look at the other servers and your Domain Controllers, maybe there is/was a problem with another Exchange 2013 installation." | Write-BLLog -LogType CriticalError
					"Setup will not continue. Rerun after the problem is solved. Check logfiles in C:\ExchangeSetupLogs and C:\RIS\Log" | Write-BLLog -LogType CriticalError
					Return 1
				}
				elseif ($RegKeyValue -eq "concluded") {
					
					"After $TimeElapsed minutes the registry key value of $KeyPath - PS was set to 'concluded'. Prepare Schema was concluded from another server."|Write-BLLog -LogType Information
					"This server skips the Step Prepare Schema. Setup will continue with the next step."|Write-BLLog -LogType Information
					Return 0					
				}
				elseif ($RegKeyValue -eq "error") {
				
					"After $TimeElapsed minutes the registry key value of $KeyPath - PS was set to 'error'. Prepare Schema was started on another machine and encountered an error."|Write-BLLog -LogType Warning
					"This server will start the step Prepare Schema again."|Write-BLLog -LogType Warning
					"If this operation encounters an error again, check Logfiles in C:\ExchangeSetupLogs and C:\RIS\Logs."|Write-BLLog -LogType Warning
					"Starting Step Prepare Schema..."|Write-BLLog -LogType Information
					"-------------------------------"|Write-BLLog -LogType Information
			
					"Setting PS-Property in $KeyPath to 'started'"|Write-BLLog -LogType Information
					
					Set-BLRegistryValueX64 -Path $KeyPath -Name "PS" -Value "started" -Computer $DomainController

					$ps = Invoke-BLSetupOther -FileName $SetupFile -Arguments "/PS /IAcceptExchangeServerLicenseTerms"
					
					
					
					
						if($ps){
						
							"Step Prepare Schema encountered an error. Check logfiles in C:\ExchangeSetupLogs and C:\RIS\Log"|Write-BLLog -LogType CriticalError
							"This is a severe error. Setup will not continue..."|Write-BLLog -LogType CriticalError
							"Setting PS-Property in $KeyPath to 'error'"|Write-BLLog -LogType Information
							Set-BLRegistryValueX64 -Path $KeyPath -Name "PS" -Value "error" -Computer $DomainController
							Return 1
					
						}
						else{
							
							"Step Prepare Schema successfully concluded"|Write-BLLog -LogType Information
							"------------------------------------------"|Write-BLLog -LogType Information
							"Setting PS-Property in $KeyPath to 'concluded'"|Write-BLLog -LogType Information
							Set-BLRegistryValueX64 -Path $KeyPath -Name "PS" -Value "concluded" -Computer $DomainController
							Return 0
						}
					
					
					
					}
		
				
				
				
		}
		else{
				"Step Prepare Schema is already concluded."|Write-BLLog -LogType Information
				"This server skips the Step Prepare Schema. Setup will continue with the next step."|Write-BLLog -LogType Information
				Return 0	
		}		
}



function Invoke-PrepareActiveDirectory{

	Param(
		[Parameter(Mandatory=$True)]
		[string]$SetupFile,
		[Parameter(Mandatory=$True)]
		[string]$DomainController,
		[Parameter(Mandatory=$True)]
		[string]$KeyPath	
	)

	Test-RegValue -KeyPath $RegKey -Value "P" -Computer $DomainController

	$PrepValue = Get-BLRegistryValueX64 -Path $KeyPath -Name "P" -Computer $DomainController

	if($PrepValue -eq "not defined" -or $PrepValue -eq "error"){
		if($PrepValue -eq "not defined"){
			
			"This is the first time Prepare AD is running"|Write-BLLog -LogType Information
			}
			elseif($PrepValue -eq "error"){
				"There was an error last time Prepare AD was attempted. Trying again..."|Write-BLLog -LogType Warning
				"If this operation encounters an error again, check Logfiles in C:\ExchangeSetupLogs and C:\RIS\Logs."|Write-BLLog -LogType Warning
			}
			
			"Starting Step Prepare AD..."|Write-BLLog -LogType Information
			"----------------------"|Write-BLLog -LogType Information
			"Setting P-Property in $KeyPath to 'started'"|Write-BLLog -LogType Information
			Set-BLRegistryValueX64 -Path $KeyPath -Name "P" -Value "started" -Computer $DomainController

			$p = Invoke-BLSetupOther -FileName $setupFile -Arguments "/P /OrganizationName:$Script:ExchangeOrga /IAcceptExchangeServerLicenseTerms"
			
			
			
			if($p){
			
				"Step Prepare AD encountered an error. Check logfiles in C:\ExchangeSetupLogs and C:\RIS\Log"|Write-BLLog -LogType CriticalError
				"This is a severe error. Setup will not continue..."|Write-BLLog -LogType CriticalError
				"Setting P-Property in $KeyPath to 'error'"|Write-BLLog -LogType Information
				Set-BLRegistryValueX64 -Path $KeyPath -Name "P" -Value "error" -Computer $DomainController
				Return 1
		
			}else{
				
				"Prepare AD successfully concluded"|Write-BLLog -LogType Information
				"---------------------------------"|Write-BLLog -LogType Information
				"Setting P-Property in $KeyPath to 'concluded'"|Write-BLLog -LogType Information
				Set-BLRegistryValueX64 -Path $KeyPath -Name "P" -Value "concluded" -Computer $DomainController
				Return 0
			}
		}
		elseif($PrepValue -eq "started"){
			$RegKeyValue = $PrepValue
			$i=0
				while(($RegKeyValue -eq "started") -and ($i -le 3)){
					
					if($i -eq 0){
					
					"The registry key value of $KeyPath - P is set to 'started'. Another AD-Prep may be running. Waiting for 5 minutes to let the other setup conclude."|Write-BLLog -LogType Warning
					$TimeElapsed = ($i+1)*5	
					}
					
					elseif($i -gt 0){
					
					"No change after $TimeElapsed minutes. The registry key value of $KeyPath - P was not set to 'concluded' or 'error'." | Write-BLLog -LogType Information
					$TimeElapsed = ($i+1)*5
					}
					
					Start-Sleep -Seconds $SecondsToWait
					$RegKeyValue = Get-BLRegistryValueX64 -Path $KeyPath -Name "P" -Computer $DomainController
					$i++
					
				}
				if (($RegKeyValue -eq "started") -AND ($i -gt 3)) {
						
					"After $TimeElapsed minutes the registry key value of $KeyPath - P was not set to concluded or error." | Write-BLLog -LogType CriticalError
					"Please take a look at the other servers, maybe there is/was a problem with another Exchange 2013 installation." | Write-BLLog -LogType CriticalError
					"Setup will not continue. Rerun after the problem is solved. Check logfiles in C:\ExchangeSetupLogs and C:\RIS\Log" | Write-BLLog -LogType CriticalError
					Return 1
				}
				elseif ($RegKeyValue -eq "concluded") {
					
					"After $TimeElapsed minutes the registry key value of $KeyPath - P was set to concluded. Prepare AD was concluded from another server."|Write-BLLog -LogType Information
					"This server skips the Step Prepare AD. Setup will continue."|Write-BLLog -LogType Information
					Return 0					
				}
				elseif ($RegKeyValue -eq "error") {
				
					"After $TimeElapsed minutes the registry key value of $KeyPath - P was set to 'error'. Prepare AD was started on another machine and encountered an error."|Write-BLLog -LogType Warning
					"This server will start the step Prepare AD again."|Write-BLLog -LogType Warning
					"If this operation encounters an error again, check Logfiles in C:\ExchangeSetupLogs and C:\RIS\Logs."|Write-BLLog -LogType Warning
					
					"Starting Step Prepare AD..."|Write-BLLog -LogType Information
					"---------------------------"|Write-BLLog -LogType Information
					"Setting P-Property in $KeyPath to 'started'"|Write-BLLog -LogType Information
					
					Set-BLRegistryValueX64 -Path $KeyPath -Name "P" -Value "started" -Computer $DomainController

					$p = Invoke-BLSetupOther -FileName $setupFile -Arguments "/P /OrganizationName:$Script:ExchangeOrga /IAcceptExchangeServerLicenseTerms"
					
					
					
						if($p){
						
							"Step Prepare AD encountered an error. Check logfiles in C:\ExchangeSetupLogs and C:\RIS\Log"|Write-BLLog -LogType CriticalError
							"This is a severe error. Setup will not continue..."|Write-BLLog -LogType CriticalError
							"Setting P-Property in $KeyPath to 'error'"|Write-BLLog -LogType Information
							Set-BLRegistryValueX64 -Path $KeyPath -Name "P" -Value "error" -Computer $DomainController
							Return 1
					
						}else{
							
							"Prepare AD successfully concluded"|Write-BLLog -LogType Information
							"---------------------------------"|Write-BLLog -LogType Information
							"Setting P-Property in $KeyPath to 'concluded'"|Write-BLLog -LogType Information
							Set-BLRegistryValueX64 -Path $KeyPath -Name "P" -Value "concluded" -Computer $DomainController
							Return 0
						}
				
				}
		
				
				
				
		}
		else{
				"Step Prepare AD is already concluded."|Write-BLLog -LogType Information
				"This server skips the Step Prepare AD. Setup will continue."|Write-BLLog -LogType Information
				Return 0	
		}		
}




function Invoke-PrepareDomains{

	Param(
		[Parameter(Mandatory=$True)]
		[string]$SetupFile,
		[Parameter(Mandatory=$True)]
		[string]$DomainController,
		[Parameter(Mandatory=$True)]
		[string]$KeyPath	
	)

	Test-RegValue -KeyPath $RegKey -Value "PAD" -Computer $DomainController

	$PrepValue = Get-BLRegistryValueX64 -Path $KeyPath -Name "PAD" -Computer $DomainController

	if($PrepValue -eq "not defined" -or $PrepValue -eq "error"){
		if($PrepValue -eq "not defined"){
			
			"This is the first time Prepare All Domains is running"|Write-BLLog -LogType Information
			}
			elseif($PrepValue -eq "error"){
				"There was an error last time Prepare All Domains was attempted. Trying again..."|Write-BLLog -LogType Warning
				"If this operation encounters an error again, check Logfiles in C:\ExchangeSetupLogs and C:\RIS\Logs."|Write-BLLog -LogType Warning
			}
			
			"Starting Step Prepare All Domains..."|Write-BLLog -LogType Information
			"------------------------------------"|Write-BLLog -LogType Information
			
			"Setting PAD-Property in $KeyPath to 'started'"|Write-BLLog -LogType Information
			
			Set-BLRegistryValueX64 -Path $KeyPath -Name "PAD" -Value "started" -Computer $DomainController

			$pad = Invoke-BLSetupOther -FileName $SetupFile -Arguments "/PAD /IAcceptExchangeServerLicenseTerms"
			
			
			
			if($pad){
			
				"Step Prepare All Domains encountered an error. Check logfiles in C:\ExchangeSetupLogs and C:\RIS\Log"|Write-BLLog -LogType CriticalError
				"This is a severe error. Setup will not continue..."|Write-BLLog -LogType CriticalError
				"Setting PAD-Property in $KeyPath to 'error'"|Write-BLLog -LogType Information
				Set-BLRegistryValueX64 -Path $KeyPath -Name "PAD" -Value "error" -Computer $DomainController
				Return 1
		
			}else{
				
				"Prepare Schema successfully concluded"|Write-BLLog -LogType Information
				"-------------------------------------"|Write-BLLog -LogType Information
				"Setting PAD-Property in $KeyPath to 'concluded'"|Write-BLLog -LogType Information
				Set-BLRegistryValueX64 -Path $KeyPath -Name "PAD" -Value "concluded" -Computer $DomainController
				Return 0
			}
		}
		elseif($PrepValue -eq "started"){
			$RegKeyValue = $PrepValue
			$i=0
				while(($RegKeyValue -eq "started") -and ($i -le 3)){
					
					if($i -eq 0){
					
					"The registry key value of $KeyPath - PAD is set to 'started'. Another AD-Prep may be running. Waiting for 5 minutes to let the other setup conclude."|Write-BLLog -LogType Warning
					$TimeElapsed = ($i+1)*5	
					}
					
					elseif($i -gt 0){
					
					"No change after $TimeElapsed minutes. The registry key value of $KeyPath - PAD was not set to 'concluded' or 'error'." | Write-BLLog -LogType Information
					$TimeElapsed = ($i+1)*5
					
					}
					
					Start-Sleep -Seconds $SecondsToWait
					$RegKeyValue = Get-BLRegistryValueX64 -Path $KeyPath -Name "PAD" -Computer $DomainController
					$i++
					
				}
				if (($RegKeyValue -eq "started") -AND ($i -gt 3)) {
						
					"After $TimeElapsed minutes the registry key value of $KeyPath - PAD was not set to 'concluded' or 'error'." | Write-BLLog -LogType CriticalError
					"Please take a look at the other servers and your Domain Controllers, maybe there is/was a problem with another Exchange 2013 installation." | Write-BLLog -LogType CriticalError
					"Setup will not continue. Rerun after the problem is solved. Check logfiles in C:\ExchangeSetupLogs and C:\RIS\Log" | Write-BLLog -LogType CriticalError
					Return 1
				}
				elseif ($RegKeyValue -eq "concluded") {
					
					"After $TimeElapsed minutes the registry key value of $KeyPath - PAD was set to 'concluded'. Prepare All Domains was concluded from another server."|Write-BLLog -LogType Information
					"This server skips the Step Prepare All Domains. Setup will continue with the next step."|Write-BLLog -LogType Information
					Return 0					
				}
				elseif ($RegKeyValue -eq "error") {
				
					"After $TimeElapsed minutes the registry key value of $KeyPath - PAD was set to 'error'. Prepare All Domains was started on another machine and encountered an error."|Write-BLLog -LogType Warning
					"This server will start the step Prepare All Domains again."|Write-BLLog -LogType Warning
					"If this operation encounters an error again, check Logfiles in C:\ExchangeSetupLogs and C:\RIS\Logs."|Write-BLLog -LogType Warning
					
					"Starting Step Prepare All Domains..."|Write-BLLog -LogType Information
					"------------------------------------"|Write-BLLog -LogType Information
					"Setting PAD-Property in $KeyPath to 'started'"|Write-BLLog -LogType Information
					
					Set-BLRegistryValueX64 -Path $KeyPath -Name "PAD" -Value "started" -Computer $DomainController

					$pad = Invoke-BLSetupOther -FileName $setupFile -Arguments "/PAD /IAcceptExchangeServerLicenseTerms"
					
					
					
						if($pad){
						
							"Step Prepare All Domains encountered an error. Check logfiles in C:\ExchangeSetupLogs and C:\RIS\Log"|Write-BLLog -LogType CriticalError
							"This is a severe error. Setup will not continue..."|Write-BLLog -LogType CriticalError
							"Setting P-Property in $KeyPath to 'error'"|Write-BLLog -LogType Information
							Set-BLRegistryValueX64 -Path $KeyPath -Name "PAD" -Value "error" -Computer $DomainController
							Return 1
					
						}else{
							
							"Prepare All Domains successfully concluded"|Write-BLLog -LogType Information
							"---------------------------------"|Write-BLLog -LogType Information
							"Setting P-Property in $KeyPath to 'concluded'"|Write-BLLog -LogType Information
							Set-BLRegistryValueX64 -Path $KeyPath -Name "PAD" -Value "concluded" -Computer $DomainController
							Return 0
						}
				
				}
		
				
				
				
		}
		else{
				"Step Prepare All Domains is already concluded."|Write-BLLog -LogType Information
				"This server skips the Step Prepare All Domains. Setup will continue with the next step."|Write-BLLog -LogType Information
				Return 0	
		}		
}



###



Function Invoke-ISInstallation() {
## Make sure that $ExitCode is ONLY 0 if the install was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.

	## CUSTOMIZE: Check here if the software is installed; you can use "Get-Help Get-BLUninstallInformation -Full" for more complex options, like specific x86/x64 versions,
	## query by GUID, a specific version, or a Hotfix. Comment out if not required.
	
	
	

	$Temp = $Env:Temp
	$Destination = Join-Path $Temp $AppName
	Write-Host "Destination: $Destination"
	if ((Test-Path -Path $Destination) -eq $False) {
		"Destination folder does not exist. Creating it now. Invoking: New-Item -Path $Env:Temp -ItemType Directory -Name $AppName" | Write-BLLog -LogType Information
		$DestFolder = New-Item -Path $Env:Temp -ItemType Directory -Name $AppName
	} else {
		"Destination folder exists. Skipping the creation of the folder." | Write-BLLog -LogType Information
	}
	$SourceItem = Get-Item (Join-Path $AppSource "Source\Exchange2013-x64-cu14.exe")
	$DestinationItem = Get-Item $Destination
	
	if ((Test-Path -Path $SourceItem) -eq $True) {
		"Expanding '$($SourceItem.FullName)' to '$($DestinationItem.FullName)' ..." | Write-BLLog
		$Options = @(
			 'x'       ## eXtract files with full paths
			 '-bd' ## Disable percentage indicator
			 '-y' ## assume Yes on all queries
			 "`"-o$($DestinationItem.FullName)`"" ## set Output directory
			 "`"$($SourceItem.FullName)`""             ## <archive_name>
		)
		If ($Verbose) {
			 & 'C:\RIS\Tools\7z.exe' $Options 2>&1 | Write-BLLog -NoTrim -NoColCaller -NoColTime -CustomCol '7z.exe'
		} Else {
			 & 'C:\RIS\Tools\7z.exe' $Options 2>&1 | Select-String -NotMatch -SimpleMatch 'Extracting' | Write-BLLog -NoTrim -NoColCaller -NoColTime -CustomCol '7z.exe'
		}
		If ($LASTEXITCODE -ne 0) {
			 "Could not expand '$($SourceItem.FullName)' to '$($DestinationItem.FullName)', SevenZip exit code was $($LASTEXITCODE)!" | Write-BLLog -LogType CriticalError
			 Return 9
		}
		"... successfully expanded '$($SourceItem.FullName)' to '$($DestinationItem.FullName)'." | Write-BLLog
		"Duration was $([uint64]((Get-Date) - $StartTime).TotalSeconds) seconds." | Write-BLLog
	
	#Variables for Setup.exe
	#$SourceFolder = "\source"
	#$SetupPath = Join-Path $AppSource $SourceFolder
	$SetupEXE = "setup.exe"
	$FileName = Join-Path $Destination $SetupEXE
	


	"+++ MS_EXCH2013_Prereq_ADPREP started. +++"|Write-BLLog -LogType Information
	$ExitCode = 1
	
	$ExitCodePS = Invoke-PrepareSchema -SetupFile $FileName -DomainController $ADDC -KeyPath $RegKey

		if($ExitCodePS[$ExitCodePS.Count -1] -eq 0){
			$ExitCode = 0
		}else{
			$ExitCode = 1
			"-------------------------------------------------"|Write-BLLog -LogType CriticalError
			"There was an error during the Step Prepare Schema"|Write-BLLog -LogType CriticalError
			"-------------------------------------------------"|Write-BLLog -LogType CriticalError
		}

		if($ExitCode -eq 0){

			$ExitCodeP = Invoke-PrepareActiveDirectory -SetupFile $FileName -DomainController $ADDC -KeyPath $RegKey
			
			if($ExitCodeP[$ExitCodeP.Count -1] -eq 0){
				$ExitCode = 0
			}else{
				$ExitCode = 1
				"-----------------------------------------------------------"|Write-BLLog -LogType CriticalError
				"There was an error during the Step Prepare Active Directory"|Write-BLLog -LogType CriticalError
				"-----------------------------------------------------------"|Write-BLLog -LogType CriticalError
			}
			
			
		}

		if($ExitCode -eq 0){

			$ExitCodePAD = Invoke-PrepareDomains -SetupFile $FileName -DomainController $ADDC -KeyPath $RegKey
			if($ExitCodePAD[$ExitCodePAD.Count -1] -eq 0){
				$ExitCode = 0
			}else{
				$ExitCode = 1
				"------------------------------------------------------"|Write-BLLog -LogType CriticalError
				"There was an error during the Step Prepare All Domains"|Write-BLLog -LogType CriticalError
				"------------------------------------------------------"|Write-BLLog -LogType CriticalError
			}	
			
			
		}

		if($ExitCode -eq 0){
			
			"---------------------------------------------------------------------------"|Write-BLLog -LogType Information
			"All AD-Preparation steps successfully concluded. Triggering AD-Replication."|Write-BLLog -LogType Information
			"---------------------------------------------------------------------------"|Write-BLLog -LogType Information
			
			$ExitCode = Initialize-Replication -DomainController $ADDC
			
			"ExitCode = $ExitCode"|Write-BLLog
			
		}

		if($ExitCode -eq 0){

			"-------------------------"|Write-BLLog -LogType Information
			"AD-Replication triggered."|Write-BLLog -LogType Information
			"Waiting for 20 Minutes."|Write-BLLog -LogType Information
			"-------------------------"|Write-BLLog -LogType Information
			Start-Sleep -s 1200 # This is for Prod
			#Start-Sleep -s 10 # Only for Testing
			
			"+++ MS_EXCH2013_Prereq_ADPREP sucessfully concluded.+++"|Write-BLLog -LogType Information
			Return $ExitCode

		}


	Return $ExitCode
	}
}

Function Invoke-ISUninstallation() {
## Make sure that $ExitCode is ONLY 0 if the uninstall was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.
	$IsInstalled = $true
	$ExitCode = 0
	
	## CUSTOMIZE: Check here if the software is installed; you can use "Get-Help Get-BLUninstallInformation -Full" for more complex options, like specific x86/x64 versions,
	## query by GUID, a specific version, or a Hotfix. Comment out if not required.
	

#region Std-Installation "FileCopyOnly" use this if you only want to copy all files from $AppSource\Source  to C:\RIS\FILES\$Appname, delete it otherwise
	# remove existing folder
#	if (test-Path $DstDir) {
#		"Removing existing folder '$DstDir'" | Write-BLLog
#		$RET = remove-item -Recurse -Force -Path $DstDir -ea 0
#       $RET = $?
#		"RET:$RET" | Write-BLLog
#		if ( -not $RET ) {
#			"Could not delete existing folder '$DstDir'" | Write-BLLog -LogType Error 
#			return 1
#		}
#	} else {
#        "Folder '$DstDir' does not exist: OK" | Write-BLLog
#    }
#endregion


	IF ($IsInstalled) {
	## CUSTOMIZE: Add uninstallation code here.	
	## HINT Use only absolute filepathes to access files in package. Use variable $AppSource which points to the folder of this installation skript
		"No uninstallation supported. Please restore a Backup!" | Write-BLLog -LogType Warning
	} Else {
		"Software is not installed - uninstallation not necessary!" | Write-BLLog -LogType Information	
	}
		
	Return $ExitCode
}

## ====================================================================================================
## MAIN
## ====================================================================================================
## CUSTOMIZE: Uncomment to get information from ConfigDB if required (use of Defaults.txt is optional).
## - The use of Defaults.txt and Write-BLConfigDBSettings is optional
## - Add a filter to Write-BLConfigDBSettings to only show required variables (will filter ConfigDB variables beginning with this value)
<#
$cfg = @{}
$ExitCode = Get-BLConfigDBVariables $cfg -Defaults "$AppSource\Defaults.txt"
If ($ExitCode -ne 0) {
	"Error setting variables from ConfigDB, unable to continue!" | Write-BLLog -LogType Information
	Exit-BLFunctions -SetExitCode 1
}

## CUSTOMIZE: set filter for config vars you want to be displayed (i.e. you will be using)
Write-BLConfigDBSettings -cfg $cfg -Filter "COMPUTER_RegisteredOrganization"
Write-BLConfigDBSettings -cfg $cfg -Filter "AD_CFG_DOMAINACCOUNT"
#>

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
