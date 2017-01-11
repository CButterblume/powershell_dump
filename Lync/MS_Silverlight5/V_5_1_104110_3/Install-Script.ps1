## --------------------------------------------------------------------------------------
## File                 : Install-Script.ps1
##                        --------------------
## Purpose              : Installs or uninstalls software and logs progress and result
##
## Syntax               : powershell.exe "& '<TemplateFullPath>\Install-Script.ps1' <Script arguments>"
##
## Template Version Management
## ===========================
## Date					Version	By			Change Description
## --------------------------------------------------------------------------------------
## 05.08.2013			M. Richardt			Initial version
## --------------------------------------------------------------------------------------
## 
## When creating custom functions, use the Verb-Noun syntax and the naming rules from Microsoft.
## Use the Cmdlet "Get-Verb" in a PsSession for a list; details can be found here:
## Approved Verbs for Windows PowerShell Commands
## http://msdn.microsoft.com/en-us/library/ms714428(v=vs.85).aspx
## Use "IS" (*I*nstall *S*cript) as common Noun prefix for all custom functions in this script.
##
## Version Mgmt
## ============
## Date					Version	By			Change Description
## --------------------------------------------------------------------------------------
## 21.01.2013			M. Richardt			Initial version
## --------------------------------------------------------------------------------------
## Installs the Microsoft "Silverlight" browser plugin version 5 in 32bit and 64bit (64bit IE only)
## The 64bit installer installs both the 32bit and the 64bit versions of Silverlight!
## Installation on a terminal server is supported

## CUSTOMIZE: Add supported arguments for the script here (do not remove the -Force or -Uninstall arguments):
Param(
	[switch]$Force,
	[switch]$Uninstall
)
$LibraryPath = "C:\RIS\Lib"
$BaseLibrary = Join-Path $LibraryPath "BaseLibrary.psm1"
If (-Not (Import-Module $BaseLibrary -Force -PassThru)) {Write-Host -ForegroundColor Red "[CriticalError] File not found - '$BaseLibrary'"; Exit 1}

$Local:ScriptFullName = & {$MyInvocation.ScriptName}
$Local:ScriptName = [string]$(Split-Path $Local:ScriptFullName -Leaf)
$Local:ScriptPath = [string]$(Split-Path $Local:ScriptFullName)

## CUSTOMIZE: Edit value for the AppName parameter <Appname> below; use only characters allowed in file names, no spaces:
Initialize-BLFunctions -AppName "MS_Silverlight5" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall

"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information
$ExitCode = 0

## CUSTOMIZE: Set Value of $is32BitSoftware to $TRUE if this script contains 32Bit Software. Default is $FALSE
$Is32BitSoftware = $false

## Check environment the script is running in (if X64 or X86) - returns true if environment is a 64 Bit environment
"Checking installation evironment..." | Write-BLLog -LogType Information
$is64BitSystem = ($env:Processor_Architecture -ne "x86")
"installation environment is 64Bit: $is64BitSystem"| Write-BLLog -LogType Information

Function Invoke-ISInstallation() {
## CUSTOMIZE: Add installation code here.
## Make sure that $ExitCode is ONLY 0 if the uninstall was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.

	$SetupArguments = "/q /noupdate"
	
	"Installing $SetupFile at $((Get-Date).ToLongTimeString()) ..." | Write-BLLog -LogType Information
	Set-BLRDSInstallMode
	$ExitCode = Invoke-BLSetupOther -FileName $SetupFile -Arguments $SetupArguments
	Set-BLRDSExecuteMode
	"... install finished at $((Get-Date).ToLongTimeString()) with exit code $ExitCode." | Write-BLLog -LogType Information
	
	Return $ExitCode
}

Function Invoke-ISUninstallation() {
## CUSTOMIZE: Add uninstallation code here.
## Make sure that $ExitCode is ONLY 0 if the uninstall was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
	$IsInstalled = $true
	
	## Process uninstallation only if software is installed.
	## If not needed (used setup file has a implemented error handling for this case) comment code out until "END OF INSTALLATION CHECK" Comment
	## CUSTOMIZE: Insert software registry key name here:
	## Notice: Key for Silverlight is for 64Bit and 32Bit the same one 
	$RegKeySoftware =  "{89F4137D-6C26-4A84-BDB8-2E5A4BB71E00}"
	$IsInstalled= $False
	
	##If 32Bit Software is installed on a 64Bit System the relevant Regkey is stored at another location in HKLM
	IF (($Is64BitSystem) -and ($Is32BitSoftware)) {
		$BaseRegKey = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
	} Else {
		$BaseRegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
	}
	"64 Bit is $Is64BitSystem and Software is 32Bit $Is32BitSoftware - Using Regkey $BaseRegKey" | Write-BLLog -LogType Information
	$RegKey = $BaseRegKey + "\" + $RegKeySoftware
	
	"Checking if software is installed" | Write-BLLog -LogType Information
	$RegKeyProperties = Get-ItemProperty $RegKey -ErrorAction SilentlyContinue
	IF ($RegKeyProperties.UninstallString) {
		$IsInstalled = $true
		"Software is installed, beginning with uninstallation..." | Write-BLLog -LogType Information
	}
	## END OF INSTALLATION CHECK
	
	IF ($IsInstalled) {
	## CUSTOMIZE: Add uninstallation code here.	
		
		$SetupArguments = "/qu"
		
		Set-BLRDSInstallMode
		$ExitCode = Invoke-BLSetupOther -FileName $SetupFile -Arguments $SetupArguments
		Set-BLRDSExecuteMode	
	
		
	} Else {
		"Software is not installed - uninstallation not necessary!" | Write-BLLog -LogType Information	
	}
	Return $ExitCode

}
## ====================================================================================================
## MAIN
## ====================================================================================================
## CUSTOMIZE: Uncomment to get information from ConfigDB if required (use of Defaults.txt is optional):
# $cfg = @{}
# $ExitCode = Get-BLConfigDBVariables $cfg # -Defaults "$AppSource\Defaults.txt"
# If ($ExitCode -ne 0) {
	# "Error setting variables from ConfigDB, unable to continue!" | Write-BLLog -LogType Information
	# Exit-BLFunctions -SetExitCode 1
# }

IF ($is64BitSystem) {
		$SetupFile = Join-Path $AppSource "Source\Silverlight-v5.1.10411.0_x64.exe"
	} Else {
		$SetupFile = Join-Path $AppSource "Source\Silverlight-v5.1.10411.0.exe"
	}

If (-Not $Uninstall) {
	$ExitCode = Invoke-ISInstallation
} Else {
	$ExitCode = Invoke-ISUninstallation
}

## CUSTOMIZE: An msi installation may leave with errorlevel 3010, indicating a reboot is required;
## uncomment if this is supported, and make sure that the Task Sequence has a Reboot action after package execution.
# If ($ExitCode -eq 3010) {
	# "A reboot is required to finish the installation!" | Write-BLLog -LogType Information
	# $ExitCode = 0
# }

"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
