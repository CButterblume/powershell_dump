<#
.SYNOPSIS
The script imports and linkes a GPO.

.DESCRIPTION
The script creates, imports and linkes GPOs in the Source folder.
For each GPO in the source folder, the script searches for the existance of the GPO in the 
Domain. If it does not exist it will create the GPO, imports the delivered GPO from the source 
folder and link it to the SharePoint OU.


.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 

.OUTPUTS
The script writes a logfile in C:\RIS\Log.

.EXAMPLE
install-Script -Force					Installation of the Software
install-Script -Uninstall -Force		Uninstallation of the Software

.NOTES
The user that runs this script has to be member of the group "domain admins".
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
## 01.01.1980			Author Name			Initial version
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
Initialize-BLFunctions -AppName "MS_SHPO2010_PreReq_GPO" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

#region function Import-GroupPolicy
function Import-GroupPolicy {
	Param(
		[Parameter(Mandatory=$True)]
		$ImportPath,
		[Parameter(Mandatory=$True)]
		$DC,
		[Parameter(Mandatory=$True)]
		$CurrentComputer,
		[Parameter(Mandatory=$True)]
		$OU,
		[Parameter(Mandatory=$True)]
		$GPOTestString,
		$Filter
	)
	$LogType = "Information"
	
	$Path = "\\" + $CurrentComputer + "\" + $ImportPath.Replace(":","$")
	try {
		"Open a new PowerShellSession to $DC . Invoking: New-PowerShellSession -ComputerName $DC" | Write-BLLog -LogType $LogType
		$PSS = New-PowerShellSession -ComputerName $DC
		"Getting folders in $ImportPath." | Write-BLLog -LogType $LogType
		if ($Filter) {
			"Invoking: Get-ChildItem -Path $Path -Directory -Filter $Filter" | Write-BLLog -LogType $LogType
			$Folders = Invoke-Command -Session $PSS -Scriptblock {
				Param (
					[Parameter(Mandatory=$True)]
					$Path,
					[Parameter(Mandatory=$True)]
					$Filter
				)
				Get-ChildItem -Path $Path -Directory -Filter $Filter
		} -Args $Path,$Filter
			
		} else {
			"Invoking: Get-ChildItem -Path $Path -Directory" | Write-BLLog -LogType $LogType
			$Folders = Invoke-Command -Session $PSS -Scriptblock {
				Param (
					[Parameter(Mandatory=$True)]
					$Path
				)
				Get-ChildItem -Path $Path -Directory
			} -Args $Path
		}
		#Import GPO "Certificate Path Validation Settings"

		if ($Folders) {
			"These GPO-folders have been found and will imported now:" | Write-BLLog -LogType $LogType
			$i = 1
			foreach ($Folder in $Folders) {
				$FN = $Folder.FullName
				"$i. $FN" | Write-BLLog -LogType $LogType
				$i++
			}
			
			foreach ($Folder in $Folders) {
			
				$SetGPO = Invoke-Command -Session $PSS -Scriptblock {
					Param (
						[Parameter(Mandatory=$True)]
						$Folder,
						[Parameter(Mandatory=$True)]
						$Path,
						[Parameter(Mandatory=$True)]
						$OU,
						[Parameter(Mandatory=$True)]
						$GPOTestString
					)
					$LibraryPath = "C:\RIS\Lib"
					$BaseLibrary = Join-Path $LibraryPath "BaseLibrary.psm1"
					Import-Module $BaseLibrary
					$TargetName = $Folder.Name
					$GPOPath = $Path + "\" + $TargetName
					$BackupID = (Get-ChildItem -Path $GPOPath | Where-Object {$_.Name -like "{*}"}).Name.Replace("{","").Replace("}","")
					$ExistingGPO = Get-GPO -Name $TargetName -ErrorAction SilentlyContinue
					$GPInheritance = Get-GPInheritance -Target $OU
					
					try {
						if ($ExistingGPO.DisplayName -Contains $TargetName) {
							"A GPO with that name already exists. Skipping the creation of the GPO."
						} else {
							"The GPO does not exist. Creating it now. Invoking: New-GPO -Name $TargetName"
							$NewGPO = New-GPO -Name $TargetName -ErrorAction Stop
						}
						
						"Getting a report of the GPO. Invoking: Get-GPOReport -Name $TargetName -ReportType XML"
						[xml]$XML = Get-GPOReport -Name $TargetName -ReportType XML
						"Testing if the GPO included a striking string. Invoking: $XML.InnerXml.Contains($GPOTestString)"
						$GPOSet = $XML.InnerXml.Contains($GPOTestString)
						if ($GPOSet -eq "True") {
							"The GPO was set correctly before. Skipping the import process."
						} else {
							"The GPO was not set correctly or was just created before. Importing the GPO now. Invoking: Import-GPO -TargetName $TargetName -Path $GPOPath -BackupId $BackupID"
							$ImportGPO = Import-GPO -TargetName $TargetName -Path $GPOPath -BackupId $BackupID  -ErrorAction Stop
						}

						if ($GPInheritance.GpoLinks.Displayname -Contains $TargetName) {
							"The Link of $TargetName on the OU '$OU' already exists. Skipping the link process..."
						} else {
							"The link of the GPO '$TargetName' is not set yet. Invoking: New-GPLink -Name $TargetName -Target $OU -LinkEnabled yes"
							$NewGPOLink = New-GPLink -Name $TargetName -Target $OU -LinkEnabled yes -ErrorAction Stop
						}
					} catch {
						$LogType = "Error"
						$ErrorMessage = $_.Exception.Message
						$Error.Clear()
						$ErrorMessage
						1
					}							
				} -Args $Folder,$Path,$OU,$GPOTestString  -ErrorAction Stop
				$SetGPO | Write-BLLog -LogType $LogType
				if ($SetGPO[$SetGPO.Count - 1] -eq 1) {
					$LogType = "Error"
					"An error occured during the GPO settings. Error: $ErrorMessage" | Write-BLLog -LogType $LogType
					Return 1
				} else {
					$ExitCode = 0
				}
			}
		} else {
			$LogType = "Warning"
			"No GPOs for import have been found in $Path." | Write-BLLog -LogType $LogType
			$ExitCode = 2
		}
	} catch {
		$LogType = "Error"
		$ErrorMessage = $_.Exception.Message
		"Could not import the GPO(s). An error occured: $ErrorMessage" | Write-BLLog -LogType $LogType
		$Error.Clear()
		Return 1		
	} finally {
		"Removing PowerShellSession. Invoking: Remove-PSSession -Session $PSS" | Write-BLLog -LogType $LogType
		$RemovePSS = Remove-PSSession -Session $PSS
	}
	Return $ExitCode
}
#endregion function Import-GroupPolicy

#region function New-PowerShellSession
function New-PowerShellSession {
<#
.SYNOPSIS
This function opens a new PSSession to another computer.

.DESCRIPTION
This function opens a new PSSession to the given computer.

.PARAMETER ComputerName
The Parameter ComputerName is mandatory and the machine to which the session will be opened

.EXAMPLE
New-BLLYPSSession -ComputerName $ComputerName

.OUTPUTS
The function returns a PowershellSession $PSS if everything is alright or a 1 if error occures.
#>
[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		$ComputerName
	)
	
	try {
		$LogType = "Information"
		"Opening PSSession, invoking: $PSS = New-PSSession -ComputerName $ComputerName -ErrorAction Stop" | Write-BLLog -LogType $LogType
		$PSS = New-PSSession -ComputerName $ComputerName -ErrorAction Stop
	} catch {
		$LogType = "Error"
		$ErrorMessage = $_.Exception.Message
		"Could not create a PSSession on $ComputerName. An error occured: $ErrorMessage" | Write-BLLog -LogType $LogType
		$Error.Clear()
		Return 1
	}
	Return $PSS
}
#endregion New-BLLYPowerShellSession


#region installation
Function Invoke-ISInstallation() {
	$ExitCode = 1
	$LogType = "Information"
	$ImportPath= Join-Path $AppSource "Source"
	$OU = $cfg["SHAREPOINT_SERVER_OU"]
	$DC = Get-BLADDomainController
	$CurrentComputer = hostname
	$GPOTestString = "xsi:type=`"q2:RegistrySettings`"><q2:Policy><q2:Name>Turn off Automatic Root Certificates Update</q2:Name><q2:State>Enabled</q2:State><q2:Explain>This policy setting specifies whether to automatically update root certificates using the Windows Update website."
	$ExitCode = Import-GroupPolicy -ImportPath $ImportPath -CurrentComputer $CurrentComputer -OU $OU -DC $DC -GPOTestString $GPOTestString
	
	if ($ExitCode -eq 2) {
		$LogType = "Warning"
		"No GPOs have been found in the import folder $ImportPath. Is that correct?" | Write-BLLog -LogType $LogType
	}
	
	
	Return $ExitCode
}
#endregion installation

#region uninstallation
Function Invoke-ISUninstallation() {
	"Uninstallation is unprovided for the import of the GPO for Certificate Path Validation Settings" | Write-BLLog -LogType Information
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
## Start a second instance of the script; the main instance will wait here until the task instance is done:
$ExitCode = Enter-BLExecutionAsTask -UserName $TaskUsername -UserDomain $TaskUserDomain -UserPass $TaskPassword -Timeout 60 #-NoTask
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
