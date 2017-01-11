<#
.SYNOPSIS
This script installs the prerequisites for Sharepoint via the SharePoint PrerequisitesInstaller

.DESCRIPTION
The script installs these prerequisites for SharePoint via the SharePoint PrerequisitesInstaller

1.	Sqlncli.msi 						Microsoft SQL Server Native Client
2.	MSChart.exe							Microsoft Chart Controls für Microsoft .NET Framework 3.5
3.	SQLSERVER2008_ASADOMD10.msi			Microsoft SQL Server 2008 Analysis Services ADOMD.NET
4.	rsSharePoint.msi					SQL 2008 R2 Reporting Services SharePoint 2010 Add-in
5.	SpeechPlatformRuntime.msi			Microsoft Server Speech Platform Runtime
6.	MSSpeech_SR_en-US_TELE.msi			Microsoft Server Speech Recognition Language – TELE(en-US)


The Hotfixes:
1.	Windows6.1-KB976462-v2-x64.msu		Hotfix for Microsoft Windows

!!!!!!!!!!!!!!!!!!!!!!!ATTENTION!!!!!!!!!!!!!!!!!!!!!!!
These files have to be installed before you run this script. They are substituted by existing packages:
FileName					PackageName
#1.	dotnetfx35setup.exe		WIN2008R2_AddFeature_DOTNET35
#2.	Synchronization.msi		MS_SyncFrameworkRuntime_x64
#3. FilterPack64bit.exe		MS_FilterPack2010
#4.	KB974405-x64.msu		MS_WindowsIdentityFoundation

.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests of the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests of the script. 

.OUTPUTS
The script writes logfiles one in C:\RIS\Log and one in C:\Windows\Temp

.EXAMPLE
install-Script -Force					Installation of the Software
install-Script -Uninstall -Force		Uninstallation of the Software		in this case unprovided

.LINK
?????<Prerequisite Name="IIS Management Cmdlets" Url="http://download.microsoft.com/download/B/8/6/B8617908-B777-4A86-A629-FFD1094990BD/iis7psprov_x64.msi" />

<Prerequisite Name="Microsoft Chart Controls for the Microsoft .NET Framework 3.5" Url="http://download.microsoft.com/download/c/c/4/cc4dcac6-ea60-4868-a8e0-62a8510aa747/MSChart.exe" />
<Prerequisite Name="WCF fix for Win2008 R2" Url="http://download.microsoft.com/download/E/C/7/EC785FAB-DA49-4417-ACC3-A76D26440FC2/Windows6.1-KB976462-v2-x64.msu" />
<Prerequisite Name="SQL Server 2008 Native Client" Url="http://download.microsoft.com/download/3/5/5/35522a0d-9743-4b8c-a5b3-f10529178b8a/sqlncli.msi" />
<Prerequisite Name="Microsoft SQL Server 2008 Analysis Services ADOMD.NET" Url="http://go.microsoft.com/fwlink/?linkid=160390" />
<Prerequisite Name="ADO.NET Data Services v1.5 CTP2 (Win2008 SP2)" Url="http://download.microsoft.com/download/1/7/1/171CCDD6-420D-4635-867E-6799E99AB93F/ADONETDataServices_v15_CTP2_RuntimeOnly.exe" />
<Prerequisite Name="SQL 2008 R2 Reporting Services SharePoint 2010 Add-in" Url="http://download.microsoft.com/download/1/0/F/10F1C44B-6607-41ED-9E82-DF7003BFBC40/1033/x64/rsSharePoint.msi" />
<Prerequisite Name="Microsoft Server Speech Platform Runtime" Url="http://download.microsoft.com/download/8/D/F/8DFE3CE7-6424-4801-90C3-85879DE2B3DE/Platform/x64/SpeechPlatformRuntime.msi" />
<Prerequisite Name="Microsoft Server Speech Recognition Language - TELE(en-US)" Url="http://download.microsoft.com/download/E/0/3/E033A120-73D0-4629-8AED-A1D728CB6E34/SR/MSSpeech_SR_en-US_TELE.msi" />

Diese wurden durch vorhandene Pakete ersetzt
<Prerequisite Name="Microsoft Sync Framework Runtime v1.0 (x64)" Url="http://download.microsoft.com/download/C/9/F/C9F6B386-824B-4F9E-BD5D-F95BB254EC61/Redist/amd64/Microsoft%20Sync%20Framework/Synchronization.msi" />
<Prerequisite Name="Microsoft .NET Framework 3.5 Service Pack 1" Url="http://download.microsoft.com/download/2/0/e/20e90413-712f-438c-988e-fdaa79a8ac3d/dotnetfx35.exe" />
<Prerequisite Name="Windows Identity Framework (Win2008 R2)" Url="http://download.microsoft.com/download/D/7/2/D72FD747-69B6-40B7-875B-C2B40A6B2BDD/Windows6.1-KB974405-x64.msu" />

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
Initialize-BLFunctions -AppName "MS_SHPO2010_PreReq_SW" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.

"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information


#region installation
Function Invoke-ISInstallation() {
	$ExitCode = 1
	$LogType = "Information"
	$FilterPack = "Microsoft Filter Pack 2.0"
	$WindowsIdentityFoundation = "KB974405"
	$SyncFramework = "Microsoft Sync Framework Runtime v1.0 SP1 (x64)"
	$DotNet35SP1 = "AS-NET-Framework"
	$FP = Get-BLUninstallInformation -DisplayName $FilterPack
	$SF = Get-BLUninstallInformation -DisplayName $SyncFramework
	$WIF = Get-HotFix $WindowsIdentityFoundation -ErrorAction SilentlyContinue
	$DotNet351 = Get-WindowsFeature -Name $DotNet35SP1
	$SWInstalled = @()
	
	"Checking prerequisites for the package." | Write-BLLog -LogType $LogType
	if ($SF.IsInstalled -eq "True") {
		$LogType = "Information"
		"OK - Microsoft Sync Framework Runtime is installed." | Write-BLLog -LogType $LogType
	} else {
		$LogType = "Error"
		"Not OK - Microsoft Sync Framework Runtime is not installed. Please install it first and run this script again." | Write-BLLog -LogType $LogType
		$SWInstalled += 1
	}
	if ($FP.IsInstalled -eq "True") {
		$LogType = "Information"
		"OK - Microsoft Filter Pack 2.0 is installed." | Write-BLLog -LogType $LogType
	} else {
		$LogType = "Error"
		"Not OK - Microsoft Filter Pack 2.0 is not installed. Please install it first and run this script again." | Write-BLLog -LogType $LogType
		$SWInstalled += 1
	}
	
	if ($DotNet351.Installed -eq $True) {
		$LogType = "Information"
		"OK - Windows Feature AS-NET-Framework is installed." | Write-BLLog -LogType $LogType
	} else {
		$LogType = "Error"
		"Not OK - Windows Feature AS-NET-Framework is not installed. Please install it first and run this script again." | Write-BLLog -LogType $LogType
		$SWInstalled += 1
	}	
		
	if ($WIF) {
		$LogType = "Information"
		"OK - Windows Identity Foundation is installed." | Write-BLLog -LogType $LogType
	} else {
		$LogType = "Error"
		"Not OK - Windows Identity Foundation is not installed. " | Write-BLLog -LogType $LogType
		$SWInstalled += 1
	}
	
	if ($SWInstalled -contains 1) {
		$LogType = "Error"
		"At least one required software is not installed. Take a look at the logfile in C:\RIS\Log" | Write-BLLog -LogType $LogType
		Return 1
	} else {
		$LogType = "Information"
		"Every required software was installed before. We can proceed with the installation of the other prerequisites for SharePoint 2010" | Write-BLLog -LogType $LogType
	}
	
	$LogType = "Information"
	$PRInstallerPath = Join-Path $AppSource "Source"
	$PRInstaller = Join-Path $PRInstallerPath "PrerequisiteInstaller.exe"
	#Diese vier werden durch vorhandene Pakete ersetzt.
	#Softwarename					Argument für Installer									Paketname
	#Windows Identity Foundation 	/IDFXR2:$PRInstallerPath\Windows6.1-KB974405-x64.msu	MS_WindowsIdentityFoundation
	#.NET Framework 3.5 SP1			/NETFX35SP1:$PRInstallerPath\dotnetfx35.exe				WIN2008R2_AddFeature_DOTNET35
	#Sync Framework Runtime 1.0		/Sync:$PRInstallerPath\Synchronization.msi 				MS_SyncFrameworkRuntime_x64
	#FilterPack 2.0					/FilterPack:$PRInstallerPath\FilterPack.msi 			MS_FilterPack2010
	$Arguments = "/SQLNCli:$PRInstallerPath\sqlncli.msi /ChartControl:$PRInstallerPath\MSChart.exe /KB976462:$PRInstallerPath\Windows6.1-KB976462-v2-x64.msu /ADOMD:$PRInstallerPath\SQLSERVER2008_ASADOMD10.msi /ReportingServices:$PRInstallerPath\rsSharePoint.msi /Speech:$PRInstallerPath\SpeechPlatformRuntime.msi /SpeechLPK:$PRInstallerPath\MSSpeech_SR_en-US_TELE.msi /unattended"
	"Invoking: Invoke-BLSetupOther -FileName $PRInstaller -Arguments $Arguments" | Write-BLLog -LogType $LogType
	$ExitCode = Invoke-BLSetupOther -FileName $PRInstaller -Arguments $Arguments	
	Return $ExitCode
}
#endregion installation

#region uninstallation
Function Invoke-ISUninstallation() {
	"Uninstallation is unprovided for the SharePoint 2010 PreRequisites." | Write-BLLog -LogType Information	
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

	If (-Not $Uninstall) {
		$ExitCode = Invoke-ISInstallation
	} Else {
		$ExitCode = Invoke-ISUninstallation
	}


"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode