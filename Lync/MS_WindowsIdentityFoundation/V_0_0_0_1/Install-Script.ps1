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
## Version Management
## ==================
## Date					Version	By			Change Description
## --------------------------------------------------------------------------------------
## 28.10.2013			Matthias Benesch	Initial version
## --------------------------------------------------------------------------------------
## CUSTOMIZE: Add the change date and an overview of your changes to the table above, and add a description of what the script does here:
##

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
Initialize-BLFunctions -AppName "MS_WindowsIdentityFoundation" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall

"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information
$ExitCode = 0

Function Invoke-ISInstallation() {
## CUSTOMIZE: Add installation code here.
## Make sure that $ExitCode is ONLY 0 if the uninstall was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
	Import-Module (Join-Path $AppSource "/NetCheck.psm1")
	$InstalledFrameworks = Get-InstalledNetFrameworks
	 if (-Not ($InstalledFrameworks -contains $DotNet3_5)) {
      "Required .Net Framework Version 3.5 is not installed" | Write-BLLog -LogType Error
      $ExitCode = 1
      return $ExitCode
    }
	$sourceFile = Join-Path $AppSource "/source/Windows6.1-KB974405-x64.msu"
	if (-not (Test-Path $sourceFile)) {
		"Installer file is missing" | Write-BLLog -LogType Error
		$ExitCode = 1
		Return $ExitCode
	}
	"Installing $AppName" | Write-BLLog -LogType Information
	$ExitCode = Install-BLWindowsHotfix $sourceFile
	if ($ExitCode -ne 0) {
		if ($ExitCode -eq 3010) {
			"A reboot is required to complete the installation" | Write-BLLog -LogType Warning
			$ExitCode = 0
			Return $ExitCode
		} else {
			"Failed to install $AppName" | Write-BLLog -LogType Error
			Return $ExitCode
		}
	}
	Return $ExitCode
}

Function Invoke-ISUninstallation() {
## CUSTOMIZE: Add uninstallation code here.
## Make sure that $ExitCode is ONLY 0 if the uninstall was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.

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
