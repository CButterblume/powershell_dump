<#
.SYNOPSIS
This script executes the infrastructure preparation steps prior to the installation of Microsoft Lync Server 2013

.DESCRIPTION
Autor: Michael Wittmann, michael.wittmann@interface-ag.de
This script imports a PKCS12-certificate labeled with the FQDN of the target computer found in a defined folder into the personal certificate store of the machine account.
For this step a password is needed which is deposited in the ConfigDB.

Used ConfigDB-variables:

COMPUTER_DNS_FQDN
The FQDN of the current domain. Used to determine the filename of the certificate.

LYNC2013_INSTALL_CERT_TRANSPORTKEY
The password to import the pfx-certificate.

LYNC2013_INSTALL_CERT_SOURCEFOLDER
Folder in which the certificate file is provided. Can be a local folder or a fileshare.


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
Initialize-BLFunctions -AppName "MS_LYNC2013_WA_CFG_InstallCert" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
$AppDisplayName = "MS_LYNC2013_WA_CFG_InstallCert"
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

#region ConfigDB/defaults.txt

#<#

$cfg = @{}
$ExitCode = Get-BLConfigDBVariables $cfg -Defaults "$AppSource\Defaults.txt"
If ($ExitCode -ne 0) {
	"Error setting variables from ConfigDB, unable to continue!" | Write-BLLog -LogType Information
	Exit-BLFunctions -SetExitCode 1
}

Write-BLConfigDBSettings -cfg $cfg -Filter "LYNC2013_CFG_WA_POOL_NAME"
$SubjectPrefix = $cfg["LYNC2013_CFG_WA_POOL_NAME"]
Write-BLConfigDBSettings -cfg $cfg -Filter "DOMAIN_FQDN"
$DomainSuffix = $cfg["DOMAIN_FQDN"]
#Write-BLConfigDBSettings -cfg $cfg -Filter "COMPUTER_DNS_FQDN"
#$CertFilePrefix = $cfg["COMPUTER_DNS_FQDN"]
Write-BLConfigDBSettings -cfg $cfg -Filter "LYNC2013_INSTALL_CERT_TRANSPORTKEY" 
$TransportKey = $cfg["LYNC2013_INSTALL_CERT_TRANSPORTKEY"]
Write-BLConfigDBSettings -cfg $cfg -Filter "LYNC2013_INSTALL_CERT_SOURCEFOLDER"
$CertFolder = $cfg["LYNC2013_INSTALL_CERT_SOURCEFOLDER"]

#>



#endregion ConfigDB/defaults.txt

$SubjectID = $SubjectPrefix + "." + $DomainSuffix
$CertFileName = $SubjectID + ".pfx"
$CertLocation = "Cert:\LocalMachine\My"


Function Invoke-ISInstallation() {
## Make sure that $ExitCode is ONLY 0 if the install was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.

	## CUSTOMIZE: Check here if the software is installed; you can use "Get-Help Get-BLUninstallInformation -Full" for more complex options, like specific x86/x64 versions,
	## query by GUID, a specific version, or a Hotfix. Comment out if not required.
	$ExitCode = 1
	
	
	"Importing the provided certificate."|Write-BLLog -LogType Information
	$CertImport = Import-WACertificate -SourceFolder $CertFolder -Password $TransportKey -CertStore $CertLocation -CertFile $CertFileName

	If($CertImport -ne "error"){

		"The import operation was successful."|Write-BLLog -LogType Information
		"The Thumbprint of the imported certificate is: $CertImport"|Write-BLLog -LogType Information
		$ExitCode = 0
	}
	else{
		
		"The import oroperation failed."|Write-BLLog -LogType CriticalError
		"Quitting the task with error."|Write-BLLog -LogType CriticalError
			
	}
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

Function Import-WACertificate{

	Param(
		[Parameter(Mandatory=$True)]
		[string]$SourceFolder,
		[Parameter(Mandatory=$True)]
		[string]$Password,
		[Parameter(Mandatory=$True)]
		[string]$CertStore,
		[Parameter(Mandatory=$True)]
		[string]$CertFile
		)

$ReturnCode = "error"


#Return Value on success: Thumbprint of imported Certificate
#Return Value on Error: Error

# General assumptions:

# - Certificate is a pfx file
# - Transport key is known and available through the ConfigDB
# - Subject = <OfficeWebAppsPoolName>.<DomainName>
# - SubjectAlternativeName = <OfficeWebAppsServerName>.<DomainName> & <OfficeWebAppsServerName>
# - We have to use certutil to import a pfx-file, Import-Certificate does not work with pfx-files

# Check the CertFolder
	$ImportFilePath = Join-Path $SourceFolder $CertFile
	$Path = Test-Path $ImportFilePath 

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
	
	# Get the Thumbprint of the certificate and use it as return value

	[string]$Thumbprint = (Get-ChildItem -Path $CertStore | Where-Object {$_.Subject -match "$SubjectID"}).Thumbprint	
	
	# Checking if string (Thumbprint) is empty
	
	if([string]::IsNullOrWhiteSpace($Thumbprint)){		
		"Thumbprint is empty! This might be a wrong certificate. Check the subject of the imported certificate."|Write-BLLog -LogType Error
		Return $ReturnCode	
	}
	else{	
		$ReturnCode = $Thumbprint
		Return $ReturnCode	
	}	

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
