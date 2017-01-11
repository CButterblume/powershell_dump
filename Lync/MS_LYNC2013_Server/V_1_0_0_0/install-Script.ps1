<#
.SYNOPSIS


.DESCRIPTION
Autor: Michael Wittmann, michael.wittmann@interface-ag.de


Used ConfigDB-variables:




.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 
In this case we have no uninstallation routine. It is advised to clear the imported certificate manually from the machine.

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
Initialize-BLFunctions -AppName "MS_LYNC2013_FE_Server" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
$AppDisplayName = "MS_LYNC2013_FE_Server"
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

#region ConfigDB/defaults.txt

#<#

$cfg = @{}
$ExitCode = Get-BLConfigDBVariables $cfg -Defaults "$AppSource\Defaults.txt"
If ($ExitCode -ne 0) {
	"Error setting variables from ConfigDB, unable to continue!" | Write-BLLog -LogType Information
	Exit-BLFunctions -SetExitCode 1
}

Write-BLConfigDBSettings -cfg $cfg -Filter "LYNC2013_CFG_FE_POOL_NAME"
$SubjectFE = $cfg["LYNC2013_CFG_FE_POOL_NAME"] #RZ1VPFLYC601.pf.t01r01.ccis.svc.intranetbw.de
Write-BLConfigDBSettings -cfg $cfg -Filter "LYNC2013_CFG_PC_POOL_NAME"
$SubjectPC = $cfg["LYNC2013_CFG_PC_POOL_NAME"] #602
Write-BLConfigDBSettings -cfg $cfg -Filter "LYNC2013_CFG_ET_POOL_NAME"
$SubjectET = $cfg["LYNC2013_CFG_ET_POOL_NAME"] #604
Write-BLConfigDBSettings -cfg $cfg -Filter "DOMAIN_FQDN"
$DomainSuffix = $cfg["DOMAIN_FQDN"]
#Write-BLConfigDBSettings -cfg $cfg -Filter "COMPUTER_DNS_FQDN"
#$CertFilePrefix = $cfg["COMPUTER_DNS_FQDN"]
Write-BLConfigDBSettings -cfg $cfg -Filter "LYNC2013_INSTALL_CERT_TRANSPORTKEY" 
$TransportKey = $cfg["LYNC2013_INSTALL_CERT_TRANSPORTKEY"]
Write-BLConfigDBSettings -cfg $cfg -Filter "LYNC2013_INSTALL_CERT_SOURCEFOLDER"
$CertFolder = $cfg["LYNC2013_INSTALL_CERT_SOURCEFOLDER"]
Write-BLConfigDBSettings -cfg $cfg -Filter "LYNC2013_INSTALL_ROLE"
$InstallRole = $cfg["LYNC2013_INSTALL_ROLE"] #FE,PC,ET

#>



#endregion ConfigDB/defaults.txt


#Variables for Bootstrapper.exe
$BSSourceFolder = Join-Path $env:ProgramFiles "Microsoft Lync Server 2013\Deployment"
$BSEXE = "bootstrapper.exe"
$BSFilePath = Join-Path $BSSourceFolder $BSEXE

#Variables for Source-Files
$SourceFolder = "\source\amd64"
$SetupPath = Join-Path $AppSource $SourceFolder
$OCSCoreInstall= "setup\ocscore.msi"
$OCSCoreFilePath = Join-Path $SetupPath $OCSCoreInstall

$CertLocation = "Cert:\LocalMachine\My"




Function Invoke-ISInstallation() {
## Make sure that $ExitCode is ONLY 0 if the install was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.

	## CUSTOMIZE: Check here if the software is installed; you can use "Get-Help Get-BLUninstallInformation -Full" for more complex options, like specific x86/x64 versions,
	## query by GUID, a specific version, or a Hotfix. Comment out if not required.
	$ExitCode = 1
	
	#Check the server role and set certificate subject, certificate types and certificate file name accordingly
	switch($InstallRole){		
			"FE" {$TypeSet = "Default", "OAuthTokenIssuer";$SubjectID = $SubjectFE;$ServerType = "Front End Server"}
			"PC" {$TypeSet = "Default";$SubjectID = $SubjectPC;$ServerType = "Persistent Chat Server"}
			"ET" {$TypeSet = "Default";$SubjectID = $SubjectET;$ServerType = "Edge Transport Server"}	
	}
	
	$CertFileName = $SubjectID + ".pfx"
		
	"Installing $ServerType..." | Write-BLLog -LogType Information
	
		
	#Install Local Mgmt Store and Enable replica	
	"Installing the Local Management Store and enabling a replica." | Write-BLLog -LogType Information
	
	$ExitCode = Set-LocalManagementStore -Bootstrapexe $BSFilePath -SourceDirectory $SetupPath
	
	if($ExitCode[$ExitCode.Count -1] -eq 0){
		$ExitCode = 0
	}
	else{
		$ExitCode = 1
		Return $ExitCode
	}
	
	#Install Roles
	
	
	"Installing roles." | Write-BLLog -LogType Information
	
	$ExitCode = Install-Roles -Bootstrapexe $BSFilePath -SourceDirectory $SourceFolder
	
	if($ExitCode[$ExitCode.Count -1] -eq 0){
		$ExitCode = 0
	}
	else{
		$ExitCode = 1
		Return $ExitCode
	}	
	
	#Assign Certificate(s)	
	"Assigning certificates." | Write-BLLog -LogType Information
	
	Foreach ($Type in $TypeSet){
	
		"--DEBUG-- Type: $Type"|Write-BLLog -LogType Warning
		
		if($Type -eq "OAuthTokenIssuer"){			
				$CertFileName = $DomainSuffix + ".pfx"
				$SubjectID = $DomainSuffix			
		}
		"--DEBUG-- CertFileName: $CertFileName"|Write-BLLog -LogType Warning
		"--DEBUG-- SubjectID: $SubjectID"|Write-BLLog -LogType Warning
		$ExitCode = Assign-Certificate -SourceFolder $CertFolder -Password $TransportKey -CertStore $CertLocation -CertFile $CertFileName -CertType $Type
		
	}
	
	if($ExitCode[$ExitCode.Count -1] -eq 0){
		$ExitCode = 0
	}
	else{
		$ExitCode = 1
		Return $ExitCode
	}
	
	#Start Services
	
	"Please start the services manually." | Write-BLLog -LogType Warning
	<#
	"Starting Services." | Write-BLLog -LogType Information
	
	$ExitCode = Start-LyncServices
	
	if($ExitCode[$ExitCode.Count -1] -eq 0){
		$ExitCode = 0
	}
	else{
		$ExitCode = 1
		Return $ExitCode
	}
	#>
	
	Return $ExitCode
}

Function Invoke-ISUninstallation() {
## Make sure that $ExitCode is ONLY 0 if the uninstall was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.
	
	## CUSTOMIZE: Check here if the software is installed; you can use "Get-Help Get-BLUninstallInformation -Full" for more complex options, like specific x86/x64 versions,
	## query by GUID, a specific version, or a Hotfix. Comment out if not required.
	$ExitCode = 0
	
	"Uninstallation not supported. Please restaore a backup or delete the certificates manually." | Write-BLLog -LogType Warning
	Return $ExitCode
}

Function Assign-Certificate{

	Param(
		[Parameter(Mandatory=$True)]
		[string]$SourceFolder,
		[Parameter(Mandatory=$True)]
		[string]$Password,
		[Parameter(Mandatory=$True)]
		[string]$CertStore,
		[Parameter(Mandatory=$True)]
		[string]$CertFile,
		[Parameter(Mandatory=$True)]
		[string]$CertType
		)

$ReturnCode = 1


#Return Value on success: Thumbprint of imported Certificate
#Return Value on Error: 1

# General assumptions:

# - Certificate is a pfx file
# - Transport key is known and available through the ConfigDB
# - We have to use certutil to import a pfx-file, Import-Certificate does not work with pfx-files

# Check the CertFolder
	$ImportFilePath = Join-Path $SourceFolder $CertFile
	$Path = Test-Path $ImportFilePath 
	$AssignCertLogFile = "C:\RIS\Log\LYNC_Assign-Certificate_" + $CertType + ".html"

		If($Path){

			"Certificate $ImportFilePath is available."|Write-BLLog -LogType Information
		}
		else{
			
			"Certificate is not available. Check the shared folder."|Write-BLLog -LogType Error
			Return $ReturnCode
		}




# Import Certificate into Certificate Store

	Try{
		$Import = Start-Process certutil.exe -ArgumentList "-p $Password -importpfx $ImportFilePath" -wait
	}

	Catch{	
		"There was an error during the import operation."|Write-BLLog -LogType CriticalError
		$ErrorMessage = $_.Exception.Message
		"The Error Message is: $ErrorMessage"|Write-BLLog -LogType CriticalError
		"Please check the System and Application Logs in the Eventlogs."|Write-BLLog -LogType CriticalError
		Return $ReturnCode
	}
	"--DEBUG-- SubjectID: $SubjectID" | Write-BLLog -LogType Warning
	"--DEBUG-- CertStore: $CertStore" | Write-BLLog -LogType Warning
	# Get the Thumbprint of the certificate
	$Thumbprint = $null
	[string]$Thumbprint = (Get-ChildItem -Path $CertStore | Where-Object {$_.Subject -contains "CN=$SubjectID"}).Thumbprint	
	
	# Checking if string (Thumbprint) is empty
	
	if([string]::IsNullOrWhiteSpace($Thumbprint)){		
		"Thumbprint is empty! This might be a wrong certificate. Check the subject of the imported certificate."|Write-BLLog -LogType Error
		Return $ReturnCode	
	}
	else{	
		Try{
		
			Set-CsCertificate -type $CertType -thumbprint $Thumbprint -Report $AssignCertLogFile
			$ReturnCode = 0
		}
		Catch{
			
			"There was an error setting the certificate for $CertType" | Write-BLLog -LogType CriticalError
			$ErrorMessage = $_.Exception.Message
			"The Error Message is: $ErrorMessage"|Write-BLLog -LogType CriticalError
			"Please check the Logfile found under $AssignCertLogFile"|Write-BLLog -LogType CriticalError
			Return $ReturnCode
		}		
	}
Return $ReturnCode
}

Function Install-OCSCore{

	Param(
		[Parameter(Mandatory=$True)]
		[string]$Installfile
	
	)
	
	
	$ReturnCode = 0
	$ArgumentList = "/quiet ADDLOCAL=Feature_LocalMgmtStore REBOOT=ReallySuppress"
	
	Try{
		Start-Process -FilePath $Installfile -ArgumentList $ArgumentList -wait -ErrorAction Stop
	}
	Catch{
		"There was an error during the installation of the ocs core components."|Write-BLLog -LogType CriticalError
		$ErrorMessage = $_.Exception.Message
		"The Error Message is: $ErrorMessage"|Write-BLLog -LogType CriticalError
		"Please check the System and Application Logs in the Eventlogs."|Write-BLLog -LogType CriticalError
		$ReturnCode = 1	
	}
	
	Return $ReturnCode
}

Function Set-LocalManagementStore{

	Param(
		[Parameter(Mandatory=$True)]
		[string]$Bootstrapexe,
		[Parameter(Mandatory=$True)]
		[string]$SourceDirectory
	
	)
	
	$ReturnCode = 0
	$StartReplicaSvcLogFile = "C:\RIS\Log\LYNC_StartReplicaSvc.html"
	$EnableReplicaLogFile = "C:\RIS\Log\LYNC_EnableReplica.html"
	$ArgumentList ="/BootStrapLocalMgmt /SourceDirectory:$SourceDirectory"
	
	$modulePath = Join-Path $env:ProgramFiles "common files\Microsoft Lync Server 2013\modules\lync"
	
	import-module -name $modulePath
	
	"Installing Local Management Store ... " | Write-BLLog -LogType Information
	Try{		
		Start-Process -FilePath $Bootstrapexe -ArgumentList $ArgumentList -wait -ErrorAction Stop
	}
	Catch{
		"There was an error installing the local management store."|Write-BLLog -LogType CriticalError
		$ErrorMessage = $_.Exception.Message
		"The Error Message is: $ErrorMessage"|Write-BLLog -LogType CriticalError
		"Please check the System and Application Logs in the Eventlogs and the Lync-Logs in C:\RIS\Log."|Write-BLLog -LogType CriticalError
		$ReturnCode = 1	
	}
	
	If(!$ReturnCode){
	
		$currentconfig = Export-CsConfiguration -asbytes
		
		"Creating a replica of the Central Management Store." | Write-BLLog -LogType Information
		
		Try{
		
			Import-CsConfiguration -byteinput $currentconfig -verbose -localstore
			Enable-CsReplica -Verbose -Report $EnableReplicaLogFile
			Start-CsWindowsService Replica -Verbose -Report $StartReplicaSvcLogFile
		
		}
		Catch{
			"There was an error during the creation of the local replica."|Write-BLLog -LogType CriticalError
			$ErrorMessage = $_.Exception.Message
			"The Error Message is: $ErrorMessage"|Write-BLLog -LogType CriticalError
			"Please check the Logfiles under C:\RIS\Log."|Write-BLLog -LogType CriticalError
			$ReturnCode = 1	
		}	
	}	
	Return $ReturnCode
}

Function Install-Roles{

	Param(
		[Parameter(Mandatory=$True)]
		[string]$Bootstrapexe,
		[Parameter(Mandatory=$True)]
		[string]$SourceDirectory	
	)
	
	$ReturnCode = 0
	$ArgumentList = "/SourceDirectory:$SourceDirectory"
	
	Try{
		Start-Process -FilePath $Bootstrapexe -ArgumentList $ArgumentList -wait -ErrorAction Stop
	}
	Catch{
		"There was an error installing the server roles."|Write-BLLog -LogType CriticalError
		$ErrorMessage = $_.Exception.Message
		"The Error Message is: $ErrorMessage"|Write-BLLog -LogType CriticalError
		"Please check the System and Application Logs in the Eventlogs."|Write-BLLog -LogType CriticalError
		$ReturnCode = 1	
	}	
	Return $ReturnCode
}

Function Start-LyncServices{

	$ReturnCode = 0
	
	Start-CsWindowsService
	$timeout = 600
	$count = 0
	
	"Waiting for Lync services to start..." | Write-BLLog -LogType Information
	
	for($count -le $timeout){
	
		$checksvcStart = get-CsWindowsService
		
		foreach ($check in $checksvcStart)
		{
			if($check.status -ne "Running")
			{
				"$check:Starting..."|Write-BLLog LogType Information			
			}		
		}	
	}
	
	
	if($count -eq $timeout){		
		"Service did not start in an appropriate time, please check services.msc and eventlogs."|Write-BLLog -LogType Error
		$checkstart	
		$ReturnCode = 1
	}
	else{	
		"Services started successfully."|Write-BLLog -LogType Information	
	}
		
	Return $ReturnCode
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

## CUSTOMIZE: set filter for config vars you want to be displayed (i.e. you will be using)
#Write-BLConfigDBSettings -cfg $cfg -Filter ""


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
