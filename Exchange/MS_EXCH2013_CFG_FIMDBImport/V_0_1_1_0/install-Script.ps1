<#
.SYNOPSIS
This script creates a new mailbox database, restarts the MSExchangeIS service and mounts the database.

.DESCRIPTION
This script creates a new mailbox database if the current server ist the first exchange server of the first data center.
First the script tests is the server is the first exchange server of the first data center, if not it will exit with 0.
If it is the first exchange server of the first data center the script will create a new mailbox database. After that the
service MSExchangeIS will be restarted and the mailbox database will be mounted.

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
$BaseLibraryEXCHANGE = Join-Path $LibraryPath "BaseLibraryEXCHANGE.psm1"
If (-Not (Import-Module $BaseLibrary -PassThru)) {Write-Host -ForegroundColor Red "[CriticalError] File not found - '$BaseLibrary'"; Exit 1}
If (-Not (Import-Module $BaseLibraryEXCHANGE -PassThru)) {Write-Host -ForegroundColor Red "[CriticalError] File not found - '$BaseLibraryEXCHANGE'"; Exit 1}

$ScriptItem = Get-Item -Path $MyInvocation.MyCommand.Path
$Local:ScriptFullName = $ScriptItem.FullName
$Local:ScriptName = $ScriptItem.Name
$Local:ScriptPath = $ScriptItem.DirectoryName

## CUSTOMIZE: Edit value for the AppName parameter <Appname> below; use only characters allowed in file names, no spaces:
Initialize-BLFunctions -AppName "MS_EXCH2013_CFG_FIMDBImport" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
$AppDisplayName = "MS_EXCH2013_CFG_FIMDBImport"
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information


#region Installation
Function Invoke-ISInstallation() {
	$ExitCode = 1
	$LogType = "Information"
	$ExchServ = hostname
	$NewMailBoxFIMDB = $cfg["EX2013_CFG_FIM_DB_IMPORT"]
	$ServiceName = "MSExchangeIS"
	$FIMDBName = $cfg["EX2013_CFG_FIM_DB_NAME"]
	$FIMDBFile = $FIMDBName + ".edb"
	$FIMDBPath = $cfg["EX2013_CFG_FIM_DB_FILE_PATH"]
	$FIMDBLogPath = $cfg["EX2013_CFG_FIM_DB_LOG_PATH"]
	$EDBFilePath = Join-Path $FIMDBPath $FIMDBFile
	$EDBLogFolder = Join-Path $FIMDBLogPath $FIMDBName
	$Role = $cfg["EX2013_INSTALL_ROLE"]
	"Adding the PowerShell SnapIn for Exchange. Invoking: Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn" | Write-BLLog -LogType $LogType
	Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
	
	if ($Role -eq "MR") {		
		if ($NewMailBoxFIMDB -eq "Import") {
			try {
				"Searching for existing mailbox databases." | Write-BLLog -LogType $LogType
				"Invoking: Get-MailboxDatabase -Server $ExchServ -ErrorAction Stop" | Write-BLLog -LogType $LogType
				$MBoxes = Get-MailboxDatabase -Server $ExchServ -ErrorAction Stop
				if ($MBoxes.Name -Contains $FIMDBName) {
					"The database $FIMDBName does already exists. skipping the creation of the database..." | Write-BLLog -LogType $LogType
					"Testing if the Mailbox Database is mounted..." | Write-BLLog -LogType $LogType
					$TestMount = Get-MailboxDatabaseCopyStatus -Identity $FIMDBName
					if ($TestMount.Status -eq "Mounted") {
						"Database is mounted. Everything went find the last time. Maybe this script ran for the second time?" | Write-BLLog -LogType $LogType
						Return 0
					} elseif ($TestMount.Status -eq "Dismounted") {
						try {
							"The database is not mounted. Restarting the MSExchangeIS service and mounting the database now." | Write-BLLog -LogType $LogType
							"Trying to restart the Microsoft Exchange Information Store - Service." | Write-BLLog -LogType $LogType
							$ExitCode = Restart-BLEXService -ServiceName $ServiceName
							if ($ExitCode -eq 0) {
								"Mounting Database $FIMDBName . Invoking: Mount-Database $FIMDBName "  | Write-BLLog -LogType $LogType
								$MountDB = Mount-Database $FIMDBName -ErrorAction Stop
								$ExitCode = 0
							} else {
								$LogType = "Error"
								"Something went wrong while restarting the MSExchangeIS Service." | Write-BLLog -LogType $LogType
								Return 1
							}
						} catch {
							$ErrorMessage = $_.Exception.Message
							$LogType = "Error"
							"This error was thrown while mounting the $FIMDBName Database : `r`n $ErrorMessage" | Write-BLLog -LogType $LogType
							$Error.clear()
							Return 1
						}
					}
				} else {
					"Creating new mailbox database $FIMDBName ." | Write-BLLog -LogType $LogType
					"Invoking: New-MailboxDatabase –Name $FIMDBName –Server $ExchServ -EdbFilePath $EDBFilePath –LogFolderPath $EDBLogFolder" | Write-BLLog -LogType $LogType
					$NewMBDB = New-MailboxDatabase –Name $FIMDBName –Server $ExchServ -EdbFilePath $EDBFilePath –LogFolderPath $EDBLogFolder -ErrorAction Stop
					"Trying to restart the Microsoft Exchange Information Store - Service." | Write-BLLog -LogType $LogType
					$ExitCode = Restart-BLEXService -ServiceName $ServiceName

					if ($ExitCode -eq 0) {
						try {
							"Mounting Database $FIMDBName. Invoking: Mount-Database $FIMDBName"  | Write-BLLog -LogType $LogType
							$MountDB = Mount-Database $FIMDBName -ErrorAction Stop
							$ExitCode = 0
						} catch {
							$LogType = "Error"
							$ErrorMessage = $_.Exception.Message
							"This error was thrown while mounting the $FIMDBName Database : `r`n $ErrorMessage" | Write-BLLog -LogType $LogType
							$Error.clear()
							Return 1
						}
					} else {
						$LogType = "Error"
						"Something went wrong while restarting the MSExchangeIS Service." | Write-BLLog -LogType $LogType
						Return 1
					}
				}
			} catch {
				$LogType = "Error"
				$ErrorMessage = $_.Exception.Message
				"This error was thrown while creating the mailbox database '$FIMDBName' : `r`n $ErrorMessage" | Write-BLLog -LogType $LogType
				$Error.clear()
				Return 1
			} 
		} elseif ($NewMailBoxFIMDB -eq "Copy") {
			try {
				"This Exchange Server is marked to get a mailbox database copy - $FIMDBName ." | Write-BLLog -LogType $LogType
				"Adding a mailbox database copy to the server. Invoking: Add-MailboxDatabaseCopy $FIMDBName -MailboxServer $ExchServ" | Write-BLLog -LogType $LogType
				$AddDBCopy = Add-MailboxDatabaseCopy $FIMDBName -MailboxServer $ExchServ -ErrorAction Stop
				"A Restart of the MSExchangeIS service is necessary. Trying to restart the Microsoft Exchange Information Store - Service." | Write-BLLog -LogType $LogType
				$ExitCode = Restart-BLEXService -ServiceName $ServiceName
			} catch {
				$LogType = "Error"
				$ErrorMessage = $_.Exception.Message
				"This error was thrown while adding a copy of the mailbox database '$FIMDBName' to $ExchServ : `r`n $ErrorMessage" | Write-BLLog -LogType $LogType
				$Error.clear()
				Return 1		
			}		
		} else {
			$LogType = "Information"
			"This is server is neither marked to get a $FIMDBName database nor to get a mailbox database copy. The package will be skipped..." | Write-BLLog -LogType $LogType
			Return 0
		}
	} elseif ($Role -eq "ET") {
		"Nothing to do here, this is the edge transport server. Skipping the creation of the $FIMDBName database..." | Write-BLLog -LogType $LogType
		$ExitCode = 0
	} else {
		$LogType = "Error"
		"The specified Role in the configdb variable 'EX2013_INSTALL_ROLE' is neither 'ET' nor 'MR'. Please correct that. We cancel the installation now." | Write-BLLog -LogType $LogType
		Return 1	
	}		
	Return $ExitCode
}
#endregion Installation

#region Uninstallation
Function Invoke-ISUninstallation() {
		"Uninstallation is unprovided for the FIM-Database import." | Write-BLLog -LogType Information	
		$ExitCode = 0
	
	Return $ExitCode
}
#endregion Uninstallation

## ====================================================================================================
## MAIN
## ====================================================================================================
$cfg = @{}
$ExitCode = Get-BLConfigDBVariables $cfg -Defaults "$AppSource\Defaults.txt"
If ($ExitCode -ne 0) {
	"Error setting variables from ConfigDB, unable to continue!" | Write-BLLog -LogType Information
	Exit-BLFunctions -SetExitCode 1
}
	If (-Not $Uninstall) {
		$ExitCode = Invoke-ISInstallation
	} Else {
		$ExitCode = Invoke-ISUninstallation
	}



"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
