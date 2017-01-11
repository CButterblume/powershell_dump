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
Initialize-BLFunctions -AppName "MS_LYNC2013_FE_PreReq_ReqSW" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
$AppDisplayName = Throw "Template TODO:  Insert 'Uninstall DisplayName' as described in the line above"

"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

#region Std-Installation "FileCopyOnly" use this if you only want to copy all files from $AppSource\Source  to C:\RIS\FILES\$Appname, delete it otherwise
$DstDir = "C:\RIS\FILES\$AppName"
#endregion


Function Invoke-ISInstallation() {
## Make sure that $ExitCode is ONLY 0 if the install was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.

	## CUSTOMIZE: Check here if the software is installed; you can use "Get-Help Get-BLUninstallInformation -Full" for more complex options, like specific x86/x64 versions,
	## query by GUID, a specific version, or a Hotfix. Comment out if not required.
	$ExitCode = 0

#region Std-Installation "FileCopyOnly" use this if you only want to copy all files from $AppSource\Source  to C:\RIS\FILES\$Appname, delete it otherwise
	# remove existing folder
	if (test-Path $DstDir) {
		"Removing existing folder '$DstDir'" | Write-BLLog
		$RET = remove-item -Recurse -Force -Path $DstDir -ea 0
        $RET = $?
		"RET:$RET" | Write-BLLog
		if ( -not $RET ) {
			"Could not delete existing folder '$DstDir'" | Write-BLLog -LogType Error 
			return 1
		}
	}
	
	# create directory
	"Creating folder '$DstDir'" | Write-BLLog
	$RET = New-Item -type directory "$DstDir"
    $RET = $?
	"RET:$RET" | Write-BLLog
	if ( -not $RET ) {
		"Could not create folder '$DstDir'" | Write-BLLog -LogType Error 
		return 2
	}

	# copy Files
	"Copying items from '$AppSource\Source' to folder '$DstDir'" | Write-BLLog
	$RET = Copy-Item -Path "$AppSource\Source\*" -Destination "$DstDir" -Container -Recurse -Force
    $RET = $?
	"RET:$RET" | Write-BLLog
	if ( -not $RET ) {
		"Could not copy items from '$AppSource\Source' to folder '$DstDir'" | Write-BLLog -LogType Error 
		return 3
	}
#endregion
	
	
	
#region Customized installation. Use this part for normal installations, delete it otherwise
	$UninstallInformation = Get-BLUninstallInformation -DisplayName $AppDisplayName
	If ($UninstallInformation.IsInstalled) {
		"Software is already installed - installation not necessary!" | Write-BLLog -LogType Information	
		$ExitCode = 0
	} else {
		## CUSTOMIZE: Add installation code here.

		#Set-BLRDSInstallMode		# uncomment if RDS is enabled on machine, i.e. MGMT001 Citrix Server
		
		$ExitCode = .......
		
		#Set-BLRDSExecuteMode		# uncomment if RDS is enabled on machine, i.e. MGMT001 Citrix Server
	}
#endregion

	Return $ExitCode
}

Function Invoke-ISUninstallation() {
## Make sure that $ExitCode is ONLY 0 if the uninstall was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.
	
	## CUSTOMIZE: Check here if the software is installed; you can use "Get-Help Get-BLUninstallInformation -Full" for more complex options, like specific x86/x64 versions,
	## query by GUID, a specific version, or a Hotfix. Comment out if not required.
	$ExitCode = 0

#region Std-Installation "FileCopyOnly" use this if you only want to copy all files from $AppSource\Source  to C:\RIS\FILES\$Appname, delete it otherwise
	# remove existing folder
	if (test-Path $DstDir) {
		"Removing existing folder '$DstDir'" | Write-BLLog
		$RET = remove-item -Recurse -Force -Path $DstDir -ea 0
        $RET = $?
		"RET:$RET" | Write-BLLog
		if ( -not $RET ) {
			"Could not delete existing folder '$DstDir'" | Write-BLLog -LogType Error 
			return 1
		}
	} else {
        "Folder '$DstDir' does not exist: OK" | Write-BLLog
    }
#endregion

#region Customized installation. Use this part for normal installations, delete it otherwise
	$UninstallInformation = Get-BLUninstallInformation -DisplayName $AppDisplayName
	If (-Not $UninstallInformation.IsInstalled) {
		"Software is not installed - uninstallation not necessary!" | Write-BLLog -LogType Information	
		$ExitCode = 0
	} else {
		## CUSTOMIZE: Add uninstallation code here.
		## The .UninstallString property of the object returned by Get-BLUninstallInformation might give a starting point
		## but will usually NOT work unattended! With MSI replacing /I with /X  in that string might work

		#Set-BLRDSInstallMode		#uncomment if RDS is enabled on machine, i.e. MGMT001 Citrix Server
		
		$ExitCode = .......

		#Set-BLRDSExecuteMode		#uncomment if RDS is enabled on machine, i.e. MGMT001 Citrix Server
	}
#endregion
	
	Return $ExitCode
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
Write-BLConfigDBSettings -cfg $cfg -Filter ""


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
