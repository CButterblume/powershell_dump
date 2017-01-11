<#
.SYNOPSIS
This script publishes a predefined topology and configures the use of simple Urls for the installation of Microsoft Lync Server 2013

.DESCRIPTION
Autor: Michael Wittmann, michael.wittmann@interface-ag.de

The script publishes and enables a predefined topology for the installation of a Microsoft Lync Server 2013 environment.
It also configures the use of simple Urls for the administration website, the Dialin and the Meeting functionality.

The predefined topology has to be delivered as a exported topology file from an reference environment and has to be in valid (utf8) xml format.
To get a valid export file use the following command in a reference environment:

	Get-CsTopology | Out-File <TargetFolder>\exportedTopology.xml -Encoding utf8
	
In the export file, every occurence of a fully qualified domain name has to be substituted for the tag [DOMAINID].

The Script itself implements two scenarios at the moment:

- One datacenter
- Two datacenters

Which scenario is used is controlled with a CFGDB-variable called LYNC2013_CFG_TOPOLOGY. This variable can have three values.

0: Do not change the topology
1: Use the topology file for one datacenter
2: Use the topology file for two datacenters

The files are delivered in the source directory of the package. 
The files are labeled 1RZ.xml (one datacenter) and 2RZ.xml (two datacenters).


The simpleURL-configuration configures the service Urls for Dialin, Meeting and Admin access as followed:

Dialin:
https://dialin<FQDN of the domain>

Meet:
https://meet<FQDN of the domain>

Admin:
https://adminlync<FQDN of the domain>



The script runs as a task which runs under the account specified in the CFGDB-variable AD_CFG_DOMAINACCOUNT.


Used CFGDB-variables:

LYNC2013_CFG_TOPOLOGY
Controls the topology configuration. 0 = no change, 1 = one DC scenario, 2 = two DCs scenario

DOMAIN_JOIN_OUPATH
Determines the install location for fresh LYNC servers in Active Drectory. Used to delegate permissions for several role groups over the freshly installed LYNC servers.

DOMAIN_FQDN
The FQDN of the current domain. Used in the simpleURL-configuration and in the preapration of the topology files.
	

.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
Due to the extensive changes in Lync configuration during the deployment of the package the uninstall parameter is not supported.

.EXAMPLE
install-Script -Force					Installation der Software
install-Script -Uninstall -Force		Deinstallation der Software

.OUTPUTS
The script writes a logifle in C:\RIS\Log.
The preparation steps write several logs in html-format. The logs are found in C:\RIS\Log.

Publishing the topology: LYNC_Publish_Topology.html
Enabling the topology: LYNC_Enable_Topology.html


.NOTES

Be advised: If you configure the file shares needed for a Lync Server installation prior to the enabling of the topology you will get warnings during the enabling.
This is not an error but expected!

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
Initialize-BLFunctions -AppName "MS_LYNC2013_FE_CFG_PublishTopology" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.

"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information






#region ConfigDB/defaults.txt

#<#

$cfg = @{}
$ExitCode = Get-BLConfigDBVariables $cfg -Defaults "$AppSource\Defaults.txt"
If ($ExitCode -ne 0) {
	"Error setting variables from ConfigDB, unable to continue!" | Write-BLLog -LogType Information
	Exit-BLFunctions -SetExitCode 1
}

$topologycfg = $cfg["LYNC2013_CFG_TOPOLOGY"] 	# Values are 0, 1 or 2 
										#0: No topology change
										#1: 1RZ
										#2: 2RZ
Write-BLConfigDBSettings -cfg $cfg -Filter "LYNC2013_CFG_TOPOLOGY"										
$LyncServersInstallOU = $cfg["DOMAIN_JOIN_OUPATH"]
Write-BLConfigDBSettings -cfg $cfg -Filter "DOMAIN_JOIN_OUPATH"
$EnvDomain = $cfg["DOMAIN_FQDN"]
Write-BLConfigDBSettings -cfg $cfg -Filter "DOMAIN_FQDN"

#>

#endregion ConfigDB/defaults.txt

#$topologycfg = 1 #Only for Testing






#region Installation
Function Invoke-ISInstallation() {

	$ExitCode = 1
	
	#$PathToTopologyFiles = "C:\Temp" #Only for testing
	$SourceFolder = "\source"
	$PathToTopologyFiles = Join-Path $AppSource $SourceFolder

	# Check if Path is available
	$PathAvail = Test-Path $PathToTopologyFiles

		If($PathAvail){
			"$PathToTopologyFiles is available."|Write-BLLog -LogType Information
		}
		else{			
			"$PathToTopologyFiles is not available. Check the shared folder."|Write-BLLog -LogType Error
			Return $ExitCode			
		}

		
	if($topologycfg -eq 1 -or $topologycfg -eq 2){	
		$topologyfile = [string]$topologycfg+"RZ.xml"
		"We are using the following configuration file: $topologyfile"|Write-BLLog -LogType Information
		$importfilepath = Join-Path $PathToTopologyFiles $topologyfile
		"Package Path: $importfilepath"|Write-BLLog -LogType Information
		$localimportpath = Join-Path "C:\temp" $topologyfile
		"Local Path: $localimportpath"|Write-BLLog -LogType Information
		
		#Prepare the topologyfile for the current environment
		"Preparing the configuration file for the current enviroment."|Write-BLLog -LogType Information
		Copy-Item -Path $importfilepath -Destination $localimportpath
		(Get-Content $localimportpath).replace('[DOMAINID]', $EnvDomain)|Set-Content $localimportpath -Encoding UTF8
		
	}
	elseif($topologycfg -eq 0){	
		$ExitCode = 0
		"No topology change needed. Quitting this task without errors."|Write-BLLog -LogType Information
		Return $ExitCode	
	}
	else{	
		"The value $topologycfg in the ConfigDB variable LYNC2013_CFG_TOPOLOGY is not valid."|Write-BLLog -LogType Error
		"Configuration task cannot continue..."|Write-BLLog -LogType Error
		Return $ExitCode
	}
	
# Execute the function Deploy-Topology
 $ExitCode = Deploy-Topology -importfile $localimportpath
 
		if($ExitCode[$ExitCode.Count -1] -eq 0){
			$ExitCode = 0
		}
		else{		
			$ExitCode = 1
			"There was an error during the operation."|Write-BLLog -LogType CriticalError
			Return $ExitCode		
		}
	Return $ExitCode
}
#endregion Installation

#region Uninstallation

Function Invoke-ISUninstallation() {
## Make sure that $ExitCode is ONLY 0 if the uninstall was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.
	
	
	$ExitCode = 0

	
	Return $ExitCode
}

#endregion Uninstallation


Function Deploy-Topology{


	Param(	
		[Parameter(Mandatory=$True)]
		[string]$importfile	
	)
	
	$ReturnCode = 0	
	
	$PermissionCheck = Test-CsSetupPermission -ComputerOU $LyncServersInstallOU
	
	if(!$PermissionCheck){
		
		"RTCUniversalServerAdmin doesn't have valid permissions to execute Enable-CsTopology against the Lync 2013 servers."|Write-BLLog -LogType Warning
		"Granting the permissions now."|Write-BLLog -LogType Information
		Try{		
			Grant-CsSetupPermission -ComputerOU $LyncServersInstallOU		
		}		
		Catch{		
			"There was an error during the operation: Grant-CsSetupPermission"|Write-BLLog -LogType CriticalError
			$ErrorMessage = $_.Exception.Message
			"The Error Message is: $ErrorMessage"|Write-BLLog -LogType CriticalError
			"Please check the System and Application Logs in the Eventlogs."|Write-BLLog -LogType CriticalError
			$ReturnCode = 1		
		}
	}
	else{	
		"RTCUniversalServerAdmin has valid permissions to execute Enable-CsTopology against the Lync 2013 servers."|Write-BLLog -LogType Information	
	}

	"ReturnCode after Checking/Setting Permissions: $ReturnCode" | Write-BLLog -LogType Warning

	#Publish the topology 
	if(!$ReturnCode){
	
			
		Try{	
			Publish-CsTopology -FileName $importfile -Report "C:\RIS\Log\LYNC_Publish_Topology.html" -Force	
		}	
		Catch{	
			"There was an error during the operation: Publish-CsTopology"|Write-BLLog -LogType CriticalError
			$ErrorMessage = $_.Exception.Message
			"The Error Message is: $ErrorMessage"|Write-BLLog -LogType CriticalError
			"Please check the System and Application Logs in the Eventlogs."|Write-BLLog -LogType CriticalError
			$ReturnCode = 1			
		}	
	}
	else{
	
		"Setting permissions against Lync Servers failed. Exiting the task."|Write-BLLog -LogType CriticalError
		Return $ReturnCode	
	}
	
	"ReturnCode nach Publish-CsTopology: $ReturnCode"|Write-BLLog -LogType Warning
		#Customize SimpleUrls

	if(!$ReturnCode){
	
		$urlDialin = "https://dialin." + $EnvDomain
		$urlMeet = "https://meet." + $EnvDomain
		$urlAdmin = "https://adminlync." + $EnvDomain
	
		$urlEntrydialin = New-CsSimpleUrlEntry -url $urlDialin # "https://dialin.pf.t01r01.ccis.svc.intranetbw.de"
		$simpleUrldialin = New-CsSimpleUrl -Component "Dialin" -Domain "*" -SimpleUrlEntry $urlEntrydialin -ActiveUrl $urlDialin
		$urlEntrymeet = New-CsSimpleUrlEntry -url $urlMeet #"https://meet.pf.t01r01.ccis.svc.intranetbw.de"    
		$simpleUrlmeet = New-CsSimpleUrl -Component "Meet" -Domain $EnvDomain -SimpleUrlEntry $urlEntrymeet -ActiveUrl $urlMeet
		$urlEntryadmin = New-CsSimpleUrlEntry -url $urlAdmin #"https://adminlync.pf.t01r01.ccis.svc.intranetbw.de"
		$simpleUrladmin = New-CsSimpleUrl -Component "Cscp" -Domain $EnvDomain -SimpleUrlEntry $urlEntryadmin -ActiveUrl $urlAdmin
		Try{
			"Creating new simple URL configuration for Dialin, Meet and Admin/CSCP..."|Write-BLLog -LogType Information
			New-CsSimpleUrlConfiguration -Identity "site:HaFIS" -SimpleUrl @{Add=$simpleUrldialin,$simpleUrlmeet,$simpleUrladmin}
			"Done."|Write-BLLog -LogType Information
		}	
		Catch{	
			"There was an error setting the simpleURL-configuration."|Write-BLLog -LogType CriticalError
			$ErrorMessage = $_.Exception.Message
			"The Error Message is: $ErrorMessage"|Write-BLLog -LogType CriticalError
			"Please check the System and Application Logs in the Eventlogs."|Write-BLLog -LogType CriticalError
			$ReturnCode = 1
		}
		
		#Dumping the SimpleUrlConfiguration in the Logfile
		
		"SimpleUrlConfiguration for this Site:" | Write-BLLog -LogType Information
		
		$testdialinurlconf = Get-CsSimpleUrlConfiguration | Select-Object -ExpandProperty SimpleUrl | Where-Object {$_.Component -eq "Dialin"}
		$testdialinurlconf | Write-BLLog -LogType Information
		$testmeeturlconf = Get-CsSimpleUrlConfiguration | Select-Object -ExpandProperty SimpleUrl | Where-Object {$_.Component -eq "Meet"}
		$testmeeturlconf | Write-BLLog -LogType Information
		$testadminurlconf = Get-CsSimpleUrlConfiguration | Select-Object -ExpandProperty SimpleUrl | Where-Object {$_.Component -eq "Cscp"}
		$testadminurlconf | Write-BLLog -LogType Information
	}
	else{
		
		"Publishing the topology failed. Exiting the task."|Write-BLLog -LogType CriticalError
		Return $ReturnCode
	}
	
	"ReturnCode nach SimpleUrlConfiguration: $ReturnCode"|Write-BLLog -LogType Warning
			
	#Enabling the topology
	if(!$ReturnCode){
			Try{	
				Enable-CsTopology -Report "C:\RIS\Log\LYNC_Enable_Topology.html" -Force
			}	
			Catch{	
				"There was an error during the operation: Enable-CsTopology"|Write-BLLog -LogType CriticalError
				$ErrorMessage = $_.Exception.Message
				"The Error Message is: $ErrorMessage"|Write-BLLog -LogType CriticalError
				"Please check the System and Application Logs in the Eventlogs."|Write-BLLog -LogType CriticalError
				$ReturnCode = 1
				#Return 1	
			}
	}
	else{	
		"Setting the SimpleUrl-Configuration failed. Exiting the task."|Write-BLLog -LogType CriticalError
		Return $ReturnCode	
	}
	
	
	if($ReturnCode){	
		"Enabling the Topology failed. Exiting the task."|Write-BLLog -LogType CriticalError	
	}	
	Return $ReturnCode
}

## ====================================================================================================
## MAIN
## ====================================================================================================


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
