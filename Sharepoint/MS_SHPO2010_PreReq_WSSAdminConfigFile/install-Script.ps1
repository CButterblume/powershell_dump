<#
.SYNOPSIS
The script copies a file drom the source folder to another folder.

.DESCRIPTION
This script copies the file WSSAdmin.exe.config from the source folder to 
"C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\14\BIN"
if necessary it will rename the existing file and copy the new file.

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
The user that runs this script has to be member of the local administrator group.
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
Initialize-BLFunctions -AppName "MS_SHPO2010_PreReq_WSSAdminConfigFile" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information


#region Installation
Function Invoke-ISInstallation() {
## Make sure that $ExitCode is ONLY 0 if the install was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.

	## CUSTOMIZE: Check here if the software is installed; you can use "Get-Help Get-BLUninstallInformation -Full" for more complex options, like specific x86/x64 versions,
	## query by GUID, a specific version, or a Hotfix. Comment out if not required.
	$ExitCode = 1
	$LogType = "Information"
	#region Std-Installation "FileCopyOnly" use this if you only want to copy all files from $AppSource\Source  to C:\RIS\FILES\$Appname, delete it otherwise
	$DstDir = "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\14\BIN"
	$DstFileName = "WSSAdmin.exe.config"
	$DstFile = Join-Path $DstDir $DstFileName
	$RenameFileName = $DstFile + "_old"
	$PathTest = Test-Path -Path $DstDir
	$NewFolderDir = $DstDir.Split("BIN")[0]
	if ($PathTest -eq $False) {
		try {
			"The Folder was not created yet. Creating the folder now." | Write-BLLog -LogType $LogType
			"Invoking: New-Item -ItemType Directory -Path $NewFolderDir -Name 'BIN' -Force -ErrorAction Stop" | Write-BLLog -LogType $LogType
			$CreateFolder = New-Item -ItemType Directory -Path $NewFolderDir -Name "BIN" -Force -ErrorAction Stop
			"Missing folder was created successful. Copying the file(s) now." | Write-BLLog -LogType $LogType
		} catch {
			$LogType = "Error"
			"This error was thrown while creating the new folder '$DstDir' : `r`n $ErrorMessage" | Write-BLLog -LogType $LogType
			"$Error" | Write-BLLog -LogType Error
			$Error.clear()
			Return 1			
		}
	} else {
		"The folder '$DstDir' already exists. Skipping the creation of the folder..." | Write-BLLog -LogType $LogType
	}
	
	#checking for existance and if necessary renaming the existing file
	if ((Test-Path -Path $DstFile) -eq "True") {
		try {
			"The file '$DstFileName' already exist in '$DstDir' . Renaming it." | Write-BLLog -LogType $LogType
			"Invoking: Rename-Item -Path $DstFile -NewName $RenameFileName -Force"| Write-BLLog -LogType $LogType
			$Renaming = Rename-Item -Path $DstFile -NewName $RenameFileName -ErrorAction Stop -Force
			"The file was successful renamed to '$RenameFileName'." | Write-BLLog -LogType $LogType
		} catch [System.IO.IOException] {
			$Date = Get-Date
			[string]$Second = $Date.Second
			[string]$Minute = $Date.Minute
			[string]$Hour = $Date.Hour
			[string]$Year = $Date.Year
			[string]$Month = $Date.Month
			[string]$Day = $Date.Day
			$TimeStamp = $Year + "-" + $Month + "-" + $Day + "--" + $Hour + "-" + $Minute + "-" + $Second
			$NewFileName = $RenameFileName + "_" + $TimeStamp
			if ($Error.Exception.Message.Trim() -Contains "Cannot create a file when that file already exists.") {
				$Error.Clear()
				"Renamed file already exists. Renaming it now." | Write-BLLog -LogType $LogType
				"Invoking: Rename-Item -Path $RenameFileName -NewName $NewFileName -Force" | Write-BLLog -LogType $LogType
				$RemoveItem = Rename-Item -Path $RenameFileName -NewName $NewFileName -Force -ErrorAction Stop
				try {
					"The file '$DstFileName' already exist in '$DstDir' . Renaming it." | Write-BLLog -LogType $LogType
					"Invoking: Rename-Item -Path $DstFile -NewName $RenameFileName -Force"| Write-BLLog -LogType $LogType
					$Renaming = Rename-Item -Path $DstFile -NewName $RenameFileName -ErrorAction Stop -Force
					"The file was successful renamed to '$RenameFileName'." | Write-BLLog -LogType $LogType
				} catch {
					$LogType = "Error"
					"This error was thrown while renaming a file: `r`n $ErrorMessage" | Write-BLLog -LogType $LogType
					"$Error" | Write-BLLog -LogType Error
					$Error.clear()
					Return 1					
				}
			} else {
				$LogType = "Error"
				"This error was thrown while renaming a file: `r`n $ErrorMessage" | Write-BLLog -LogType $LogType
				"$Error" | Write-BLLog -LogType Error
				$Error.clear()
				Return 1				
			}
		} catch {
			$LogType = "Error"
			"This error was thrown while renaming a file: `r`n $ErrorMessage" | Write-BLLog -LogType $LogType
			"$Error" | Write-BLLog -LogType Error
			$Error.clear()
			Return 1	
		}
	} else {
		"The file does not exist yet. Skipping the renaming process..." | Write-BLLog -LogType $LogType
	}
	
	# copy Files
	"Copying items from '$AppSource\Source' to folder '$DstDir'" | Write-BLLog -LogType $LogType
	$RET = Copy-Item -Path "$AppSource\Source\*" -Destination "$DstDir" -Container -Recurse -Force
    $RET = $?
	"RET:$RET" | Write-BLLog
	if ( -not $RET ) {
		"Could not copy items from '$AppSource\Source' to folder '$DstDir'" | Write-BLLog -LogType Error 
		Return 1
	} else {
		"The file(s) were copied successful." | Write-BLLog -LogType $LogType
		$ExitCode = 0
	}	
	
	Return $ExitCode
}
#endregion

Function Invoke-ISUninstallation() {
	$LogType = "Information"
	"There is no uninstallation provided for this package." | Write-BLLog -LogType $LogType
	$Exitcode = 0
	Return $ExitCode
}

## ====================================================================================================
## MAIN
## ====================================================================================================

 
	If (-Not $Uninstall) {
		$ExitCode = Invoke-ISInstallation
	} Else {
		$ExitCode = Invoke-ISUninstallation
	}
	


"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
