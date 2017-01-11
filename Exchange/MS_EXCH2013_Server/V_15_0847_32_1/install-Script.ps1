<#
.SYNOPSIS
This script installs Microsoft Exchange Server 2013 SP1

.DESCRIPTION
This script installs Microsoft Exchange Server 2013 SP1 and checks specified schema elements 
before installing the Exchange binaries. If there are some og these elements missing they will 
be set by the script.

These values are the required settings

ClassSchema 								possSuperiors
ms-Exch-Information-Store					msExchExchangeServer
ms-Exch-Exchange-Transport-Cfg-Container	msExchExchangeServer
ms-Exch-Exchange-Admin-Service				computer,container,msExchExchangeServer
ms-Exch-MTA									computer,container,msExchExchangeServer
ms-Exch-Protocol-Cfg-Shared-Server			computer,container,msExchExchangeServer

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
The installation writes logs in the folder "C:\ExchangeSetupLogs"

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
## Date					Version		By					Change Description
## -----------------------------------------------------------------------------------------------------------
## 06.06.2016			0.0.1 		S.Schmalz (IF)		Initial version
## 09.06.2016			0.0.2		S.Schmalz (IF)		Skript läuft soweit. Es gibt aber noch einen Fehler, der vor 
##														dem Setup abgefangen werden muss (PrepareSchema macht nicht alles was es sollte)
## 15.06.2016			0.0.3		S.Schmalz (IF)		Skript fertig, Variablen aus Defaults.txt eingebunden, RunAs fehlt noch
## 16.06.2016			0.0.4		S.Schmalz (IF)		RunAs eingebaut, die Variable für das PW fehlt noch.
## 24.10.2016			0.0.5		S.Schmalz (IF)		Abfrage und Logik eingebaut abhängig von der zu installierenden Rolle.
## -----------------------------------------------------------------------------------------------------------
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
$BaseLibraryEXCHANGE = Join-Path $LibraryPath "BaseLibraryEXCHANGE.psm1"
If (-Not (Import-Module $BaseLibrary -PassThru)) {Write-Host -ForegroundColor Red "[CriticalError] File not found - '$BaseLibrary'"; Exit 1}
If (-Not (Import-Module $BaseLibraryEXCHANGE -PassThru)) {Write-Host -ForegroundColor Red "[CriticalError] File not found - '$BaseLibraryEXCHANGE'"; Exit 1}

$ScriptItem = Get-Item -Path $MyInvocation.MyCommand.Path
$Local:ScriptFullName = $ScriptItem.FullName
$Local:ScriptName = $ScriptItem.Name
$Local:ScriptPath = $ScriptItem.DirectoryName

## CUSTOMIZE: Edit value for the AppName parameter <Appname> below; use only characters allowed in file names, no spaces:
Initialize-BLFunctions -AppName "MS_EXCH2013_Server" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
# Timeout of the "RunAsTask" in minutes
$TimeoutRunAsTask = 120

## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
## TODO after first Testinstallation
$AppDisplayName = "Microsoft Exchange Server 2013 Service Pack 1"
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information



## CUSTOMIZE: Uncomment to get information from ConfigDB if required (use of Defaults.txt is optional).
## - The use of Defaults.txt and Write-BLConfigDBSettings is optional
## - Add a filter to Write-BLConfigDBSettings to only show required variables (will filter ConfigDB variables beginning with this value)
#Get these Vars from Defaults.txt
#<EX2013_INSTALL_DIR> 
#<EX2013_INSTALL_MDB_PATH> 
#<EX2013_INSTALL_MDB_LOG_PATH> 
$cfg = @{}
$ExitCode = Get-BLConfigDBVariables $cfg -Defaults "$AppSource\Defaults.txt"
If ($ExitCode -ne 0) {
	"Error setting variables from ConfigDB, unable to continue!" | Write-BLLog -LogType Information
	Exit-BLFunctions -SetExitCode 1
}
Write-BLConfigDBSettings -cfg $cfg -Filter "EXCH"





Function Invoke-ISInstallation() {
## Make sure that $ExitCode is ONLY 0 if the install was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.

	## CUSTOMIZE: Check here if the software is installed; you can use "Get-Help Get-BLUninstallInformation -Full" for more complex options, like specific x86/x64 versions,
	## query by GUID, a specific version, or a Hotfix. Comment out if not required.
	$ExitCode = 0
	$LogType = "Information"
	
		
#region Customized installation. Use this part for normal installations, delete it otherwise
	$UninstallInformation = Get-BLUninstallInformation -DisplayName $AppDisplayName
	If ($UninstallInformation.IsInstalled) {
		"Software is already installed - installation not necessary!" | Write-BLLog -LogType Information	
		$ExitCode = 0
	} else {
<#	

		#region Check possSuperior
		$DOM = Get-ADDomain
		$DisName = $Dom.DistinguishedName.trim()

		$ClassSchema = @{"ms-Exch-Information-Store" = 1;
						 "ms-Exch-Exchange-Transport-Cfg-Container" = 1;
						 "ms-Exch-Exchange-Admin-Service" = 2;
						 "ms-Exch-MTA" = 2;
						 "ms-Exch-Protocol-Cfg-Shared-Server" = 2}
					 
		$One = "msExchExchangeServer"				 
		$Two = "computer","container","msExchExchangeServer"

		ForEach($Item in $ClassSchema.GetEnumerator()) {
			$Container = $Item.Key.trim()
			try {
				"Retrieve information about the currently set possSuperiors in AD for $Container" | Write-BLLog
				$PossibleSuperiors = Get-ADObject -Identity "cn=$Container,cn=schema,cn=configuration,$DisName" -Properties * -ErrorAction Stop
			} catch {
				"We got problems to retrieve informations from the active directory. Please check the connectivity." | Write-BLLog -LogType "Error"
				Return 1
			}
			
			$PoSu = $PossibleSuperiors.possSuperiors
			$ConValue = $Item.Value
			if (!$ConValue) {
				"Error: No Values given by the Hashtable. Please take a look at the script and/or contact the author!" | Write-BLLog
		   } else {
				if ($ConValue -eq 1){
					if ($PoSu -eq $One) {
					   "The entry for possSuperior of the ClassSchema $Container is set correctly to: $PoSu. We can proceed with the installation." | Write-BLLog
					} else {
						"The entry of the ClassSchema possSuperior of $Container is not set correctly. The possSuperior $One is missing" | Write-BLLog -LogType "Warning"
						"Setting the missing Property now: Invoking: Set-ADObject -Identity `"cn=$Container,cn=schema,cn=configuration,$DisName`" -Add @`{possSuperiors=$One`}" | Write-BLLog -LogType "Warning"
						try {
							Set-ADObject -Identity "cn=$Container,cn=schema,cn=configuration,$DisName" -Add @{possSuperiors=$One} -ErrorAction Stop
						} catch {
							"We got Problems with setting the correct possSuperior $One for $Container. Please set the correct value using this command on a domain controller and rerun the Package."  | Write-BLLog -LogType "Error"
							"Set-ADObject -Identity `"cn=$Container,cn=schema,cn=configuration,$DisName`" -Add @`{possSuperiors=$One`}"  | Write-BLLog -LogType "Error"
							Return 1
						}
					}
				} elseif ($ConValue -eq 2) {
					$Compare = (Compare-Object $PoSu $Two).InputObject
					if (!$Compare) {
						"The entries for possSuperior of the ClassSchema $Container are ok, these are the right entries: $PoSu. We can proceed with the installation." | Write-BLLog 
						$ExitCode = 0
					} else {
						"These values are missing in the property possSuperior of the ClassSchema $Container : $Compare " | Write-BLLog -LogType "Warning"
						"The entries for possSuperior of the ClassSchema $Container are not ok and will be set now." | Write-BLLog -LogType "Warning"
						"The missing value(s) will be set by this command now. Invoking:" | Write-BLLog  -LogType "Warning"
						if ($Compare.length -gt 1) { 
							foreach ($Item in $Compare) {
								try {
									"Set-ADObject -Identity `"cn=$Container,cn=schema,cn=configuration,$DisName`" -Add @`{possSuperiors=`"$Item`"`}" | Write-BLLog -LogType "Warning"
									Set-ADObject -Identity "cn=$Container,cn=schema,cn=configuration,$DisName" -Add @{possSuperiors="$Item"} -ErrorAction Stop
								}
								catch {
									"We got Problems with setting the correct possSuperior $Item for $Container. Please set the correct value using this command on a domain controller and rerun the Package." | Write-BLLog -LogType "Error"
									"Set-ADObject -Identity `"cn=$Container,cn=schema,cn=configuration,$DisName`" -Add @`{possSuperiors=$Item`}" | Write-BLLog -LogType "Error"
									Return 1
								}
							}
						}
						else {
							try {
								"Set-ADObject -Identity `"cn=$Container,cn=schema,cn=configuration,$DisName`" -Add @`{possSuperiors=`"$Compare`"`}" | Write-BLLog -LogType "Warning"
								Set-ADObject -Identity "cn=$Container,cn=schema,cn=configuration,$DisName" -Add @{possSuperiors=$Compare} -ErrorAction Stop
							} catch {
								"We got Problems with setting the correct possSuperior $Item for $Container. Please set the correct value using this command on a domain controller and rerun the Package." | Write-BLLog -LogType "Error"
								"Set-ADObject -Identity `"cn=$Container,cn=schema,cn=configuration,$DisName`" -Add @`{possSuperiors=$Item`}" | Write-BLLog -LogType "Error"
								Return 1
							}
						 }
					}
				}
			}
		}
		#endregion Check possSuperior
		
#>	
		#Variables for Setup.exe
		$SourceFolder = "\Source"
		$SetupPath = Join-Path $Appsource $SourceFolder
		$SetupEXE = "setup.exe"
		$FileName = Join-Path $SetupPath $SetupEXE
		$TestSetup = Test-Path -Path $FileName

		#Variables for Setup Arguments
		$CN = $Env:ComputerName
		$MDBNr = "_001.edb"
		$MDBName = $CN + $MDBNr
		$InstallDir = $cfg["EX2013_INSTALL_DIR"]
		$DBPath = $cfg["EX2013_INSTALL_MDB_PATH"]
		$MDBPath =  Join-Path $DBPath $MDBName
		$MDBLogPath = $cfg["EX2013_INSTALL_MDB_LOG_PATH"]

		#Setting Arguments for Installation
		$Role = $cfg["EX2013_INSTALL_ROLE"]
		if ($Role -eq "MR") {
			"Setting Arguments for a multi role server installation. Roles: Client Access and MailBox Server" | Write-BLLog -LogType $LogType
			$Arguments = "/m:Install /Roles:ca,mb /DisableAMFiltering /TargetDir:$InstallDir /MdbName:$MDBName /DbFilePath:$MDBPath /LogFolderPath:$MDBLogPath /IAcceptExchangeServerLicenseTerms"
		} elseif ($Role -eq "ET") {
			"Setting Arguments for a edge transport server installation." | Write-BLLog -LogType $LogType
			$Arguments = "/m:Install /Roles:et /IAcceptExchangeServerLicenseTerms"
		} else {
			$LogType = "Error"
			"The specified Role in the configdb variable 'EX2013_INSTALL_ROLE' is neither 'ET' nor 'MR'. Please correct that. We cancel the installation now." | Write-BLLog -LogType $LogType
			Return 1
		}
		#Starting Installation
		if ($TestSetup) {
			"Invoking: Invoke-BLSetupOther -FileName $FileName -Arguments $Arguments" | Write-BLLog -LogType $LogType
			$Exitcode = Invoke-BLSetupOther -FileName $FileName -Arguments $Arguments
		} else {
			"The setupfile 'setup.exe' was not found. Please take a look at the source folder: $SetupPath" | Write-BLLog -LogType CriticalError
			Return 1
		}
	}
#endregion

	Return $ExitCode
}

Function Invoke-ISUninstallation() {
## Make sure that $ExitCode is ONLY 0 if the uninstall was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.
	
	## CUSTOMIZE: Check here if the software is installed; you can use "Get-Help Get-BLUninstallInformation -Full" for more complex options, like specific x86/x64 versions,
	## query by GUID, a specific version, or a Hotfix. Comment out if not required.
	$ExitCode = 1


#region Customized installation. Use this part for normal installations, delete it otherwise
	$UninstallInformation = Get-BLUninstallInformation -DisplayName $AppDisplayName
	If (-Not $UninstallInformation.IsInstalled) {
		"Software is not installed - uninstallation not necessary!" | Write-BLLog -LogType Information	
		$ExitCode = 0
	} else {
		"There is no uninstallation-routine unprovided for Exchange 2013 Server" | Write-BLLog -LogType "Warning"
		$ExitCode = 0
	}
#endregion
	
	Return $ExitCode
}

## ====================================================================================================
## MAIN
## ====================================================================================================

#region RUNASTASK
#ConfigDB and Defaults.txt connection was created at the start of the script.

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!	Use for RunAsTaskUser	!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

## CUSTOMIZE: RunAsTask
## if you want to use RunAsTask Option i.e. want to run the installation script with a special account
## - uncomment lines between "##OPTION: RunAsTask" to "## END OPTION", there are 2 blocks to uncomment
## - adjust Konfig-DB VarNames as needed 

##OPTION: RunAsTask 
$TaskUserDomain =	$cfg["AD_CFG_DOMAINACCOUNT"].Split("\")[0].Trim()
$TaskUsername =		$cfg["AD_CFG_DOMAINACCOUNT"].Split("\").Split(";")[1].Trim()
$TaskPassword =		$cfg["AD_CFG_DOMAINACCOUNT"].Split(";")[1].Trim()
### Start a second instance of the script; the main instance will wait here until the task instance is done:
$ExitCode = Enter-BLExecutionAsTask -UserName $TaskUsername -UserDomain $TaskUserDomain -UserPass $TaskPassword -Timeout $TimeoutRunAsTask #-NoTask
If ($ExitCode -eq -2) {				# Task could not be created; this is a serious error
   $ExitCode = 1
} ElseIf ($ExitCode -eq -1) {		# we're running as a scheduled task; this is a second instance of the script!
	$CurrentUserDomain, $CurrentUserName = (& whoami.exe).Split("\")
	If ($CurrentUserName -eq "SYSTEM") {
		"Installation can not be run with user account '$($CurrentUserDomain)\$($CurrentUserName)'" | Write-BLLog -LogType CriticalError
		Exit-BLFunctions -SetExitCode 1
	}
#Region (Un-)Installaufruf
#Auswertung der Aufrufparameter
	If (-Not $Uninstall) {
		$ExitCode = Invoke-ISInstallation
	} Else {
		$ExitCode = Invoke-ISUninstallation
	}
#engregion
}
##OPTION: RunAsTask
##END OPTION
#endregion
if (($ExitCode -ne 0) -AND ($ExitCode -ne 3010)) {
	}

##OPTION: Repair MSI-Exitcode
$ExitCode = Test-BLEXExitCode -ExitCode $ExitCode

##END OPTION
"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
