<#
.SYNOPSIS
The script installs the updates of the lync server.

.DESCRIPTION
The script installs the updates of the lync server. It runs the LyncServerUpdateInstaller.

.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 

.EXAMPLE
install-Script -Force					Installation der Software
install-Script -Uninstall -Force		Deinstallation der Software

.OUTPUTS
The script writes a logifle in C:\RIS\Log.

.NOTES
The user that runs this script has to be at least a member of the local administator group.
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
Initialize-BLFunctions -AppName "MS_LYNC2013_FE_Update" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information
$LogType = "Information"

#region Installation
Function Invoke-ISInstallation() {
	$ExitCode = 1
	$InstallRole = $cfg["LYNC2013_INSTALL_ROLE"] #FE,PC,ET
	$ScriptPath = $AppSource
	$SourceFolder = Join-Path $ScriptPath "Source"
	$FileName = Join-Path $SourceFolder "LyncServerUpdateInstaller.exe"
	$Arguments = "/silentmode"
	$LogFolder = "C:\RIS\Log\LyncUpdate"
	$TestLF = Test-Path -Path $LogFolder -PathType Container
	if ($TestLF -eq $False) {
		"Logfolder does not exists. creating it now." | Write-BLLog -LogType $LogType
		$LogFolder2 = "C:\RIS\Log"
		$DirName = "LyncUpdate"
		$NF = New-Item -Path $LogFolder2 -Name $DirName -ItemType Directory -Force
	} else {
		"Logfolder already exists. Skipping the creation of the folder." | Write-BLLog -LogType $LogType
	}
	
	
	if ($InstallRole -eq "PC") {
		try {
			$KBs = "Lync Server 2013, Core Components (KB3140581)","Unified Communications Managed API 4.0, Core Runtime 64-bit (KB3081744)", `
			"Lync Server 2013, Administrative Tools (KB3070381)","Lync Server 2013, Persistent Chat (KB3070404)"
			$HT =  @{"Unified Communications Managed API 4.0, Core Runtime 64-bit (KB3081744)" = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\5FBA89DEFB6BDE7429BAC1CDBA694474\Patches\A5F326166EB86E045983B1E833CEE2F4"; `
					"Lync Server 2013, Administrative Tools (KB3070381)" = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\96DF80464A5B7C8449483FAEC3482797\Patches\E297735BF7D19EC41ABDC53D95271E22"; `
					"Lync Server 2013, Persistent Chat (KB3070404)" = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\B8C1606F597C7C642B8934E423CBD674\Patches\D1273EBC5D85E4F4CBEA7FA8A298521E"; `
					"Lync Server 2013, Core Components (KB3140581)" = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\CFDA1098C53473E40954E9E2A7162358\Patches\AE85705B1429DFB4CBCCE1D72CD14758"}
			$Info = @()
			foreach ($KB in $KBs) {
				$RegKey = $HT.Get_Item($KB)
				$GetInfo = Get-BLRegistryKeyX64 -Path $RegKey -ErrorAction SilentlyContinue

			if ($GetInfo) {
					$InstallDate = $GetInfo.Installed
					"$KB was installed before on $InstallDate." | Write-BLLog -LogType $LogType
					$IsInstalled = 1
					$Info += $IsInstalled
					"------------------------------------------------------------" | Write-BLLog -LogType $LogType
				} else {
					"$KB was not installed yet." | Write-BLLog -LogType $LogType
					$IsInstalled = 0
					$Info += $IsInstalled
					"------------------------------------------------------------" | Write-BLLog -LogType $LogType
				}
				$GetInfo = ""
			}
			
			if ($Info -Contains 0) {
				$PCSvc = "RTCCHAT"
				"This is a Persistent Chat Server. Stopping the $PCSvc before updating lync persistent chat. This can take a while (5 minutes+)..." | Write-BLLog -LogType $LogType
				"Invoking: Stop-Service -Name $PCSvc" | Write-BLLog -LogType $LogType
				$StopPCSvc = Stop-Service -Name $PCSvc	
			} else {
				"The Updates for Lync Persistent Chat Server were installed before." | Write-BLLog -LogType $LogType
				$InstallCode = 0
			}
		} catch {
			$LogType = "Error"
			$ErrorMessage = $_.Exception.Message
			"This error was thrown while invoking Start-Service -Name $ServiceName : `r`n $ErrorMessage" | Write-BLLog -LogType $LogType
			$Error.clear()
			Return 1		
		}
	}
	
	$TestPath = Test-Path -Path $FileName
	if ($TestPath) {
		try {
			if (($InstallRole -eq "PC") -AND ($InstallCode -eq 0)) {
				"Skipping the invocation of the update installer." | Write-BLLog -LogType $LogType
				$ExitCode = 0
			} else {
				"LyncServerUpdateInstaller is present." | Write-BLLog -LogType $LogType
				"Starting the installation of the Lync FrontEnd Server Updates via LyncServerUpdateInstaller" | Write-BLLog -LogType $LogType
				$ExitCode = Invoke-BLSetupOther -FileName $FileName -Arguments $Arguments
			}
		} catch {
			$LogType = "Error"
			$ErrorMessage = $_.Exception.Message
			"This error was thrown while invoking Start-Service -Name $ServiceName : `r`n $ErrorMessage" | Write-BLLog -LogType $LogType
			$Error.clear()
			Return 1	
		} finally {
			try {
				"Moving logfiles to C:\RIS\Log\LyncUpdate" | Write-BLLog -LogType $LogType
				"Invoking: Get-ChildItem -Path $SourceFolder -Exclude 'LyncServerUpdateInstaller.exe' | Move-Item -Destination $LogFolder" | Write-BLLog -LogType $LogType
				$Files = Get-ChildItem -Path $SourceFolder -Exclude "LyncServerUpdateInstaller.exe" | Move-Item -Destination $LogFolder
				if ($InstallRole -eq "PC") { 
					$Status = Get-Service -Name RTCCHAT
					if ($Status.Status -eq "Running") {
						"The Service 'RTCCHAT' is still running. Skipping start of the service." | Write-BLLog -LogType $LogType
					} else {
						"Starting the RTCCHAT Service. Invoking: Start-CsWindowsService -Name 'RTCCHAT'" | Write-BLLog -LogType $LogType
						$StartRTCCHAT = Start-CsWindowsService -Name "RTCCHAT"
					}
				}
			} catch {
				$LogType = "Error"
				$ErrorMessage = $_.Exception.Message
				"This error was thrown while invoking Start-Service -Name $ServiceName : `r`n $ErrorMessage" | Write-BLLog -LogType $LogType
				$Error.clear()
				$ExitCode = 1		
			}
		}
	} else {
		$LogType = "Error"
		"The LyncServerUpdateInstaller is not present in the Source folder."  | Write-BLLog -LogType $LogType
		Return 1
	}
	Return $ExitCode
}
#endregion Installation

Function Invoke-ISUninstallation() {
	"A uninstall routine is unprovided for the Lync FrontEnd Updates!" | Write-BLLog -LogType Information	
	$ExitCode = 0
	Return $ExitCode
}

## ====================================================================================================
## MAIN
## ====================================================================================================
$cfg = @{}
$ExitCode = Get-BLConfigDBVariables $cfg -Defaults "$AppSource\Defaults.txt"
If ($ExitCode -ne 0) {
	"Error setting variables from ConfigDB, unable to continue!" | Write-BLLog -LogType Information
	Exit-BLFunctions -SetExitCode 1
}
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
If ($ExitCode -eq 2) {
	"A reboot is required to finish the installation!" | Write-BLLog -LogType Warning
	$ExitCode = 0
}
##END OPTION


"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
