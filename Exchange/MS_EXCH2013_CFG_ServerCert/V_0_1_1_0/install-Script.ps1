<#
.SYNOPSIS
This script imports a certificate, activates it in Exchange for the protocolls IIS, SMTP, POP and IMAP and configures IIS to use the certificate for the secure Exchange Back End site.

.DESCRIPTION
This script configures a certificate for the use on the Exchange server.

Step 1: Imports a PKCS12-certificate found in a defined folder into the personal certificate store of the machine account.
For this step a password is needed which is deposited in the ConfigDB.
Step 2: Initialize the certificate in Exchange. This step initializes the imported certificate in Exchange for the following protocols/services: IIS, SMTP, POP, IMAP
Step 3: Activate the certificate in IIS for the secure Exchange Back End site. Activates the certificate for the ssl-Binding of the Exchange Back End site in IIS. 
Due to a certain error-proneness of IIS the singular substeps are repeated a second time when an error occurs. Should the error persist please consult the installation handbook.


Used ConfigDB-variables:

EX2013_INSTALL_DAG_NAME
FQDN of the DAG-Cluster, used in the subject of the certificate.

EX2013_INSTALL_CERT_TRANSPORTKEY
Transportkey(password) for the certificate in pfx format. Used in the import process.

EX2013_INSTALL_CERT_SOURCEFOLDER
Path in the filesystem where the certificate file is stored. Can be a local folder or a network share.

EX2013_INSTALL_ROLE
Determines the role of the server. MR = Multirole-Server, ET = EdgeTransport-Server

COMPUTER_DNS_FQDN
FQDN of the local Machine, used to determine the prefix of the file name for the certificate file

DOMAIN_FQDN
FQDN of the current domain, used to determine the 2nd part of the file name for the certificate file



.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 
In this case we have no uninstallation routine. It is advised to clear the imported certificate manually from the machine

.EXAMPLE
install-Script.ps1 -Force
install-Script.ps1 -Uninstall

.OUTPUTS
The installation writes a log in the folder C:\RIS\Logs

.NOTES

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
## -----------------------------------------------------------------------------------------------------------------
## 05.09.2016			Michael Wittmann/IF Initial Version [V1.0.0]
## 03.11.2016			Michael Wittmann/IF Serverrole (Multirole, EdgeTransport-Server), Workaround for IIS problem [V1.1.1]			
##
## -----------------------------------------------------------------------------------------------------------------
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
Initialize-BLFunctions -AppName "MS_EXCH2013_CFG_ServerCert" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
#$AppDisplayName = Throw "Template TODO:  Insert 'Uninstall DisplayName' as described in the line above"

"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information


#region ConfigDB/defaults.txt

#<#

$cfg = @{}
$ExitCode = Get-BLConfigDBVariables $cfg -Defaults "$AppSource\Defaults.txt"
If ($ExitCode -ne 0) {
	"Error setting variables from ConfigDB, unable to continue!" | Write-BLLog -LogType Information
	Exit-BLFunctions -SetExitCode 1
}

Write-BLConfigDBSettings -cfg $cfg -Filter "EX2013_INSTALL_DAG_NAME"
$SubjectPrefix = $cfg["EX2013_INSTALL_DAG_NAME"]
Write-BLConfigDBSettings -cfg $cfg -Filter "DOMAIN_FQDN"
$DomainSuffix = $cfg["DOMAIN_FQDN"]
Write-BLConfigDBSettings -cfg $cfg -Filter "COMPUTER_DNS_FQDN"
$CertFilePrefix = $cfg["COMPUTER_DNS_FQDN"]
Write-BLConfigDBSettings -cfg $cfg -Filter "EX2013_INSTALL_CERT_TRANSPORTKEY" 
$TransportKey = $cfg["EX2013_INSTALL_CERT_TRANSPORTKEY"]
Write-BLConfigDBSettings -cfg $cfg -Filter "EX2013_INSTALL_CERT_SOURCEFOLDER"
$CertFolder = $cfg["EX2013_INSTALL_CERT_SOURCEFOLDER"]
Write-BLConfigDBSettings -cfg $cfg -Filter "EX2013_INSTALL_ROLE"
$ServerRole = $cfg["EX2013_INSTALL_ROLE"] # mr, et

#>

#endregion ConfigDB/defaults.txt

$CertFileName = $CertFilePrefix + ".pfx"
$CertLocation = "Cert:\LocalMachine\My"
$ExchangeWebsite = "Exchange Back End"
$SubjectID = $SubjectPrefix + "." + $DomainSuffix




Function Import-ExchCertificate{

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
	# - Subject = ComputerFQDN => COMPUTER_DNS_FQDN from ConfigDB
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

function Install-SSLCertificate{

	Param(
		[Parameter(Mandatory=$True)]
		[string]$CertStore,
		[Parameter(Mandatory=$True)]
		[string]$Thumbprint,
		[Parameter(Mandatory=$True)]
		[string]$WebSite	
	)
	
	$ReturnCode = 0	
	$CertPath = Join-Path $CertStore $Thumbprint
	
	$retries = 2
	$retrycount = 0
	$delay = 5
	$completed = $false
	
	while (!$completed){
		Try{
			"Trying to import the WebAdministration module." | Write-BLLog -LogType Information
			import-module WebAdministration
			"Importing WebAdministration module successfull." | Write-BLLog -LogType Information
			$completed = $true			
			
		}	
		Catch{
			if($retrycount -ge $retries){
				"There was a persistent error during the import of the WebAdministration module."|Write-BLLog -LogType CriticalError
				$ErrorMessage = $_.Exception.Message
				"The Error Message is: $ErrorMessage"|Write-BLLog -LogType CriticalError
				"Importing WebAdministration module failed the maximum number of $retries count." | Write-BLLog -LogType CriticalError
				$ReturnCode = 1
				throw			
			}
			else{			
				"Importing WebAdministration module failed. Retrying in $delay seconds." | Write-BLLog -LogType Warning
				Start-Sleep $delay
				$retrycount ++			
			}		
		}
	}
	
	if ($ReturnCode -eq 1){	
		Return $ReturnCode	
	}
	
	#Set-Variable -Name $retrycount -Value "0"
	#Set-Variable -Name $completed -Value $false
	
	$retrycount = 0
	$completed = $false
	
	while (!$completed){

		# Get the ip address and the port of the ssl-Website via the sslbindings
		Try{
			"Trying to query the SSL-Bindings." | Write-BLLog -LogType Information
			$arrsslbinding=((((Get-Childitem -path IIS:\Sites|where {$_.name -match "$WebSite"}).bindings).Collection|where {$_.protocol -match "https"}).bindingInformation).Split(":")
			## Error testing
			#Throw [System.IO.FileNotFoundException] $UnexplainableError
			"Querying the SSL-Bindings was successfull." | Write-BLLog -LogType Information
			$completed = $true
			
		}
		Catch{
			if($retrycount -ge $retries){
				"There was a persistent error querying the SSL-Bindings."|Write-BLLog -LogType CriticalError
				$ErrorMessage = $_.Exception.Message
				"The Error Message is: $ErrorMessage"|Write-BLLog -LogType CriticalError
				"Querying the SSL-Bindings failed the maximum number of $retries count." | Write-BLLog -LogType CriticalError
				$ReturnCode = 1
				throw			
			}
			else{			
				"Querying the SSL-Bindings failed. Retrying in $delay seconds." | Write-BLLog -LogType Warning
				Start-Sleep $delay
				$retrycount ++			
			}		
		}
		
	}
	
	if ($ReturnCode -eq 1){	
		Return $ReturnCode	
	}
		
	
	
	if ($arrsslbinding[0] -eq "*"){
		$sslbindingip = "0.0.0.0" # * equals 0.0.0.0 => all ips
	}
	else{
		$sslbindingip = $arrsslbinding[0] # here a specific ip is set
	}

	$sslbindingport = $arrsslbinding[1]

	Try{		
		$appguid =[guid]::NewGuid().ToString("B")
		
		# Using netsh.exe because powershell doesn't work very well for this task
		# First delete the existing certificate then add the new one
		netsh http delete sslcert ipport="${sslbindingip}:$sslbindingport"
		netsh http add sslcert ipport="${sslbindingip}:$sslbindingport" certhash=$Thumbprint certstorename=MY appid = $appguid
	}	
	Catch{		
		"There was an error during the activation of the ssl-certificate on $WebSite."|Write-BLLog -LogType CriticalError
		$ErrorMessage = $_.Exception.Message
		"The Error Message is: $ErrorMessage"|Write-BLLog -LogType CriticalError
		"Please check the System and Application Logs in the Eventlogs."|Write-BLLog -LogType CriticalError
		$ReturnCode = 1		
	}
	
	Return $ReturnCode
}

Function Initialize-ExchangeCertificate{

		Param(
		[Parameter(Mandatory=$True)]
		[string]$Thumbprint
		)
		
		$Services = "IMAP, POP, IIS, SMTP"
		
		# Adding the PSSNappIn for Exchange
		Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn		
						
		Try{
			Enable-ExchangeCertificate -Thumbprint $Thumbprint -Services $Services -Force
			$ReturnCode = 0
		}
		Catch{					
			"There was an error during the activation of the certificate."|Write-BLLog -LogType CriticalError
			$ErrorMessage = $_.Exception.Message
			"The Error Message is: $ErrorMessage"|Write-BLLog -LogType CriticalError
			"Please check the System and Application Logs in the Eventlogs."|Write-BLLog -LogType CriticalError
			$ReturnCode = 1				
		}
			
		if(!$ReturnCode){
			$excert = Get-ExchangeCertificate -Thumbprint $Thumbprint
				
			if($excert.services -eq $Services){
				"Enabling the certificate in Exchange (Services: $Services) is successfull."|Write-BLLog -LogType Information
				Return $ReturnCode
			}
		}
}

Function Invoke-ISInstallation() {
## Make sure that $ExitCode is ONLY 0 if the install was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.

	## CUSTOMIZE: Check here if the software is installed; you can use "Get-Help Get-BLUninstallInformation -Full" for more complex options, like specific x86/x64 versions,
	## query by GUID, a specific version, or a Hotfix. Comment out if not required.
	$ExitCode = 1
	
	If($ServerRole = "MR"){
	
		"This Server is a Multirole-Server." | Write-BLLog -LogType Information	
	
		"+++ MS_EXCH2013_CFG_ServerCert started. +++"|Write-BLLog -LogType Information		
		
		"Executing Step 1: Import the provided certificate."|Write-BLLog -LogType Information
		$CertImport = Import-ExchCertificate -SourceFolder $CertFolder -Password $TransportKey -CertStore $CertLocation -CertFile $CertFileName

		If($CertImport -ne "error"){
			"The import operation was successful."|Write-BLLog -LogType Information
			"The Thumbprint of the imported certificate is: $CertImport"|Write-BLLog -LogType Information
			
			"Executing Step 2: Initialize the certificate in Exchange."|Write-BLLog -LogType Information
			$ExitCodeIEC = Initialize-ExchangeCertificate -Thumbprint $CertImport			
			
			If($ExitCodeIEC[$ExitCodeIEC.Count -1] -eq 1){  # we get an array of values, only the last value is useful
				"Initilization of the certificate in Exchange was not successful."|Write-BLLog -LogType CriticalError
				"Configuration task cannot continue..."|Write-BLLog -LogType CriticalError
				Return $ExitCode					
			}
			else{				
				"Initilization of the certificate in Exchange was successful."|Write-BLLog -LogType Information
				
				"Executing Step 3: Activate the certificate in IIS for the secure Exchange Back End site."|Write-BLLog -LogType Information
				$ExitCodeISC = Install-SSLCertificate -CertStore $CertLocation -Thumbprint $CertImport -WebSite $ExchangeWebsite #Array mit Werten (3), Nur letzter Wert wichtig
				
				if($ExitCodeISC[$ExitCodeISC.Count -1] -eq 1){  # we get an array of values, only the last value is useful
					"Activation of the certificate in IIS was not successful."|Write-BLLog -LogType CriticalError
					"Configuration task cannot continue..."|Write-BLLog -LogType CriticalError
					Return $ExitCode
				}
				else{				
					"Activation of the certificate in IIS was successful."|Write-BLLog -LogType Information
					$ExitCode = 0	
					Return $ExitCode
				}
			}
		}
		else{
			"The import operation was not successful."|Write-BLLog -LogType CriticalError
			"Configuration task cannot continue..."|Write-BLLog -LogType CriticalError
			Return $ExitCode
		}
	}
	elseif($ServerRole = "ET"){	
		"This server is a EdgeTransport-Server."|Write-BLLog -LogType Information
		"No certificate configuration needed."|Write-BLLog -LogType Information
		"Exiting the task without errors."
		$ExitCode = 0
		Return $ExitCode	
	}
	else{	
		"No valid server role information found in ConfigDB variable EXCH_INSTALL_ROLE."|Write-BLLog -LogType Warning
		"Please check the variable in the ConfigDB."|Write-BLLog -LogType Warning
		"Configuration task cannot continue..."|Write-BLLog CriticalError
		Return $ExitCode	
	}
}

Function Invoke-ISUninstallation() {
## Make sure that $ExitCode is ONLY 0 if the uninstall was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.
	
	## CUSTOMIZE: Check here if the software is installed; you can use "Get-Help Get-BLUninstallInformation -Full" for more complex options, like specific x86/x64 versions,
	## query by GUID, a specific version, or a Hotfix. Comment out if not required.
	$ExitCode = 0

	"Uninstallation not supported. Please restore a backup."|Write-BLLog -LogType Warning

	Return $ExitCode
}

## ====================================================================================================
## MAIN
## ====================================================================================================
## CUSTOMIZE: Uncomment to get information from ConfigDB if required (use of Defaults.txt is optional).
## - The use of Defaults.txt and Write-BLConfigDBSettings is optional
## - Add a filter to Write-BLConfigDBSettings to only show required variables (will filter ConfigDB variables beginning with this value)

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
