<#
.SYNOPSIS
This script adds file shares for the Lync Pools on the file server.
It grants the necessary rights on the share and adds a dfs namespace
folder to the dfs. It also configures the replication on the DFS. 

.DESCRIPTION
Autor: stefan.schmalz@interface-ag.de
This script adds the necessary folder on the file server if it does not exists. The necessary rights are granted. 
The dfs namespace folders are added also. It configures the necessary steps to initialize a replication of the 
file shares.

1. It copys necessary PowerShell Modules to the folder C:\Windows\System32\WindowsPowerShell\v1\Modules
	- SmbShare
	- Dfsr
	- ScheduleTask
2. On each server with "VPFFIL" in the name it creates a file share with the name of the pool
3. It grants access to a given number of users with the necessary rights
4. It creates a DFSn Folder out of the file share
5. If necessary it creates a replication group
6. The script adds all file servers to the members of the replication group. It sets the first Fileserver of the FileServer list als Primary Server!
7. DFS replication connections are configured for each of the file servers like a mesh (each server talks to each server)
8. The folder is added to the replication group, namespacefolder and the file servers are added to the members of the folder

ATTENTION: The content of variable for the userrights ($Access) that is filled with users and/or groups does not contain duplicate 
users/groups with different permissions. 
Otherwise the script stops setting rights and throws an error.

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
To run the script you have to be a member of the domain admin group and you have to run the powershell with elevated rights.
ATTENTION: The variables for the userright that are filled with users or groups have to be completely different. 
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
$BaseLibraryLYNC = Join-Path $LibraryPath "BaseLibraryLYNC.psm1"
If (-Not (Import-Module $BaseLibrary -PassThru)) {Write-Host -ForegroundColor Red "[CriticalError] File not found - '$BaseLibrary'"; Exit 1}
If (-Not (Import-Module $BaseLibraryLYNC -PassThru)) {Write-Host -ForegroundColor Red "[CriticalError] File not found - '$BaseLibraryLYNC'"; Exit 1}

$ScriptItem = Get-Item -Path $MyInvocation.MyCommand.Path
$Local:ScriptFullName = $ScriptItem.FullName
$Local:ScriptName = $ScriptItem.Name
$Local:ScriptPath = $ScriptItem.DirectoryName

## CUSTOMIZE: Edit value for the AppName parameter <Appname> below; use only characters allowed in file names, no spaces:
Initialize-BLFunctions -AppName "MS_LYNC2013_FE_PreReq_FileShare" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.
"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information


## CUSTOMIZE: Uncomment to get information from ConfigDB if required (use of Defaults.txt is optional).
## - The use of Defaults.txt and Write-BLConfigDBSettings is optional
## - Add a filter to Write-BLConfigDBSettings to only show required variables (will filter ConfigDB variables beginning with this value)
$cfg = @{}
$ExitCode = Get-BLConfigDBVariables $cfg -Defaults "$AppSource\Defaults.txt"
If ($ExitCode -ne 0) {
	"Error setting variables from ConfigDB, unable to continue!" | Write-BLLog -LogType Information
	Exit-BLFunctions -SetExitCode 1
}

#region Installation
Function Invoke-ISInstallation() {
	$ExitCode = 1
	$LogType = "Information"
	
	#Werden für den Task in der Funktion Add-BLLYDFSnFolder benötigt
	$UserName = $cfg["AD_CFG_DOMAINACCOUNT"].Split("\").Split(";")[1].Trim()
	$Password = $cfg["AD_CFG_DOMAINACCOUNT"].Split(";")[1].Trim()
	$DFSNameSpace = $cfg["LYNC2013_CFG_DFS_NAMESPACE"]
	$NameSpace = $cfg["LYNC2013_CFG_DFS_NAMESPACE"]
	$DC = Get-BLADDomainController
	$FileServers = $cfg["LYNC2013_CFG_DFS_FILESERVERS"].Split(",")
	$PrimaryServer = $FileServers[0]
	
	#Copy DFSN and ScheduleTask Powershell modules to the module folder of the DC-PF if they do not exist.
	#Copy DFSr powershell modules top the local module folder if they do not exist.
	$ScriptPath = $AppSource
	$DDir = "C:\Windows\System32\WindowsPowerShell\v1.0\Modules"
	$FileDC = "\\" + $DC
	$DDirDC = Join-Path $FileDC $DDir

	$DDirDfsn = Join-Path $DDirDC.Replace("C:\","C$\") "DFSN"
	$DDirST =  Join-Path $DDir "ScheduledTasks"
	$DDirDfsr = Join-Path $DDir "Dfsr"
	
	$SDirDfsn = Join-Path $ScriptPath "\Source\DFSN"
	$SDirST = Join-Path $ScriptPath "\Source\ScheduledTasks"
	$SDirDfsr = Join-Path $ScriptPath "\Source\Dfsr"


	function Copy-PSModules {
		Param (
			[Parameter(Mandatory = $true)]
			$ModuleDesc,
			[Parameter(Mandatory = $true)]
			$DDirPSM,
			[Parameter(Mandatory = $true)]
			$SDirPSM
		)
		try {
			"Searching for the $ModuleDesc. Invoking: Test-Path $DDirPSM -ErrorAction SilentlyContinue" | Write-BLLog -LogType $LogType
			$TestPathPSM = Test-Path $DDirPSM -ErrorAction SilentlyContinue
			if ($TestPathPSM -eq $True) {
				"Folder already exists. Skipping the copy process..." | Write-BLLog -LogType $LogType
				$ExitCode = 0
			} else {
				"$ModuleDesc aren't available. Copying files to module folder..." | Write-BLLog -LogType $LogType
				"Invoking: Copy-Item -Source $SDirPSM -Destination $DDirPSM -Recurse -Force" | Write-BLLog -LogType $LogType
				$CopyItem = Copy-Item -Path $SDirPSM -Destination $DDirPSM -Recurse -Force	
				$ExitCode = 0
			}
		} catch {
			$LogType = "Error"
			$ErrorMessage = $_.Exception.Message
			"An error occured while creating the DFS folder. Error: $ErrorMessage" | Write-BLLog -LogType $LogType
			Return 1		
		}
		Return $ExitCode
	}
	
	"Copying necessary powershell modules to the dc (DFSN and ScheduledTasks) and to the local server (Dfsr) if they do not exist." | Write-BLLog -LogType $LogType
	$ModuleDesc = @("Dfsn PowerShell Module","ScheduleTask PowerShell Module","Dfsr PowerShell Module")
	$DDirModules = @{ "Dfsn Powershell Module" = $DDirDfsn;"ScheduleTask PowerShell Module" = $DDirST;"Dfsr PowerShell Module" = $DDirDfsr }
	$SDirModules = @{ "Dfsn PowerShell Module" = $SDirDfsn;"ScheduleTask PowerShell Module" = $SDirST;"Dfsr PowerShell Module" = $SDirDfsr }
	foreach ($Mod in $ModuleDesc) {
		$DDirPSM = $DDirModules.Get_Item($Mod)
		$SDirPSM = $SDirModules.Get_Item($Mod)
		$CopyPSM = Copy-PSModules -ModuleDesc $Mod -DDirPSM $DDirPSM -SDirPSM $SDirPSM
	}	

	if ($CopyPSM -eq 0) {
		$FEPoolName = $cfg["LYNC2013_CFG_FE_POOL_NAME"]
		$PCPoolName = $cfg["LYNC2013_CFG_PC_POOL_NAME"]
		$NameSpaceFE = Join-Path $DFSNameSpace $FEPoolName 
		$NameSpacePC = Join-Path $DFSNameSpace $PCPoolName 
		$NameSpaces = $NameSpaceFE, $NameSpacePC
		#$Access.Values --> Full, Change, Read
		#$Access.Keys --> User or GroupName
		$Access = $cfg["LYNC2013_CFG_DFS_USER_ACCESS"].Split(";")
		$AccessHT = @{}
		foreach ($Acc in $Access) {
			$Account = $Acc.Split("=")[0]
			$Right = $Acc.Split("=")[1]
			$AccessHT.Add($Account,$Right)
		}
		
		$PoolNames = @{$NameSpaceFE = $FEPoolName; $NameSpacePC = $PCPoolName}
		#Share and Namespacefolder creation
		foreach ($NameSpace in $NameSpaces) {
			#create share
			$ShareName = $PoolNames.Get_Item($NameSpace)
			$FolderPath = Join-Path "D:\" $ShareName
			$Domain = $Env:UserDomain
			foreach ($ComputerName in $FileServers) {
				$SharedFolder = "\\$ComputerName\$ShareName"
				"Adding the share $ShareName to $FolderPath on $ComputerName." | Write-BLLog -LogType $LogType
				"Invoking: Add-BLLYSMBShare -ComputerName $ComputerName -ShareName $ShareName -FolderPath $FolderPath -AccessHT $AccessHT -Domain $Domain" | Write-BLLog -LogType $LogType
				$ExitCode = Add-BLLYSMBShare -ComputerName $ComputerName -ShareName $ShareName -FolderPath $FolderPath -AccessHT $AccessHT -Domain $Domain
				
				if ($ExitCode.ReturnCode -eq 0) { 
					"The Share - $SharedFolder - was successfully created." | Write-BLLog -LogType $LogType
					#Create DFS Namespacefolder 
					"The DFS folder will be created now." | Write-BLLog -LogType $LogType
					"Invoking: Add-BLLYDFSnFolder -ComputerName $ComputerName -Path $NameSpace -TargetPath $SharedFolder" | Write-BLLog -LogType $LogType
					$ExitCode = Add-BLLYDFSnFolder -DC $DC -ComputerName $ComputerName -Path $NameSpace -TargetPath $SharedFolder -UserName $UserName -Password $Password
				} else {
					$LogType = "Error"
					$ErrorMessage = $_.Exception.Message
					"An error occured while creating the DFSN folder $NameSpace on $ComputerName.`n`r $ErrorMessage" | Write-BLLog -LogType $LogType
					Return 1
				}
			}
		}
		
		foreach ($NameSpace in $NameSpaces) {
			$DfsnPath = $NameSpace
			###ToDo: Replicationgroup Name muss noch spezifiziert werden. Momentan wird der DNS-Name des Pools genutzt.
			$Name = $PoolNames.Get_Item($NameSpace)
			#DFS Replication
			#Add DFS group skip if it exist
			$ToDo = "adding the group $Name to the dfs namespace."
			$ExitCode = Add-BLLYDFSrGroup -Name $Name
			if ($ExitCode -eq 0) {
				#Add member to the dfs group
				$ToDo = "adding member(s) to the dfs group."
				$ExitCode = Add-BLLYDFSrGroupMember -Name $Name -FileServers $FileServers
				if ($ExitCode -eq 0){
					#adding dfs connection FileServer1 --> FileServer2
					$ToDo = "adding connections (mesh) to the replication group members"
					"Adding the connections to the dfs replication group members. Invoking: Add-BLLYDFSrConnection -Name $Name -FileServers $FileServers " | Write-BLLog -LogType $LogType
					$ExitCode = Add-BLLYDFSrConnection -Name $Name -FileServers $FileServers
					if ($ExitCode -eq 0) {
						$Description = $PoolNames.Get_Item($NameSpace)
						#Add folder to replication group
						$ExitCode = Add-BLLYDFSrFolder -Name $Name -FolderName $Name -DfsnPath $DfsnPath -PrimaryServer $PrimaryServer -Description $Description
					}
				}
			} else {
				$LogType = "Error"
				"An error occured while $ToDo." | Write-BLLog -LogType $LogType
				Return 1
			}
		}
	} else {
		"An error occured while copying the PowerShell Modules." | Write-BLLog -LogType $LogType
		Return 1
	}
	Return $ExitCode
}
#endregion Installation

#region Uninstallation
Function Invoke-ISUninstallation() {
	"Uninstall is unprovided for the Lync DFS Shares." | Write-BLLog -LogType $LogType
	$ExitCode = 0	
	Return $ExitCode
}
#endregion Uninstallation

 
##OPTION: RunAsTask 
$TaskUserDomain =	$cfg["AD_CFG_DOMAINACCOUNT"].Split("\")[0].Trim()
$TaskUsername =		$cfg["AD_CFG_DOMAINACCOUNT"].Split("\").Split(";")[1].Trim()
$TaskPassword =		$cfg["AD_CFG_DOMAINACCOUNT"].Split(";")[1].Trim()
### Start a second instance of the script; the main instance will wait here until the task instance is done:
$ExitCode = Enter-BLExecutionAsTask -UserName $TaskUsername -UserDomain $TaskUserDomain -UserPass $TaskPassword -Timeout 60 # -NoTask
If ($ExitCode -eq -2) {				# Task could not be created; this is a serious error
   $ExitCode = 1
} ElseIf ($ExitCode -eq -1) {		# we're running as a scheduled task; this is a second instance of the script!
	$CurrentUserDomain, $CurrentUserName = (& whoami.exe).Split("\")
	If ($CurrentUserName -eq "SYSTEM") {
		"Installation can not be run with user account '$($CurrentUserDomain)\$($CurrentUserName)'" | Write-BLLog -LogType CriticalError
		Exit-BLFunctions -SetExitCode 1
	}
##END OPTION
#endregion RunAsTask
 
	If (-Not $Uninstall) {
		$ExitCode = Invoke-ISInstallation
	} Else {
		$ExitCode = Invoke-ISUninstallation
	}
	
##OPTION: RunAsTask
}
##END OPTION


"Leaving $AppName at $((Get-Date).ToLongTimeString()) with ExitCode $ExitCode" | Write-BLLog -LogType Information
Exit-BLFunctions -SetExitCode $ExitCode
