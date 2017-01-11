<#
.SYNOPSIS
The function created OUs, User and groups for the Exchange Server 2013 in the Central Management Domain.

.DESCRIPTION
This script creates the necessary OUs, user and groups for managing the Exchange Server 2013 in the Central Management Domain.
It searches for the OUs, user and groups before it creates them. So unnessesary creations will be skipped.

.PARAMETER Force
The Parameter "Force" is needed to start the installation without any further requests by the script.

.PARAMETER Uninstall
The Parameter "Uninstall" together with the parameter "Force" is needed to start the uninstallation without any 
further requests by the script. 

.EXAMPLE
install-Script.ps1 -Force				Installation
install-Script.ps1 -Uninstall -Force	Uninstallation

.OUTPUTS
Logfiles in C:\RIS\Log\
MS_EXCH2013_CFG_AdministrationCM.log 
MS_EXCH2013_CFG_AdministrationCM-TASK.log

.NOTES
The script runs in a Task that is run by a ad cfg account that has rights in the cm domain and the pf domain (to create the a task).
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
If (-Not (Import-Module $BaseLibrary -PassThru)) {Write-Host -ForegroundColor Red "[CriticalError] File not found - '$BaseLibrary'"; Exit 1}

$ScriptItem = Get-Item -Path $MyInvocation.MyCommand.Path
$Local:ScriptFullName = $ScriptItem.FullName
$Local:ScriptName = $ScriptItem.Name
$Local:ScriptPath = $ScriptItem.DirectoryName

## CUSTOMIZE: Edit value for the AppName parameter <Appname> below; use only characters allowed in file names, no spaces:
Initialize-BLFunctions -AppName "MS_EXCH2013_CFG_AdministrationCM" -AppSource $Local:ScriptPath -Force:$Force -Uninstall:$Uninstall
## CUSTOMIZE: Edit value for AppDisplayName (as seen in "Control Panel\Programs and Features") to determine the current installation state; see Invoke-ISInstallation.

"Starting '$AppName' at $((Get-Date).ToLongTimeString())" | Write-BLLog -LogType Information

$cfg = @{}
$ExitCode = Get-BLConfigDBVariables $cfg -Defaults "$AppSource\Defaults.txt"
If ($ExitCode -ne 0) {
	"Error setting variables from ConfigDB, unable to continue!" | Write-BLLog -LogType Information
	Exit-BLFunctions -SetExitCode 1
}


#region Customized installation
Function Invoke-ISInstallation() {
## Make sure that $ExitCode is ONLY 0 if the install was successful! Note that not all installers return an errorlevel <> 0 if an error occurred.
## Use only absolute filepaths to access files in package; the variable $AppSource points to the folder of this installation skript.
$ExitCode = 1
	## CUSTOMIZE: Check here if the software is installed; you can use "Get-Help Get-BLUninstallInformation -Full" for more complex options, like specific x86/x64 versions,
	## query by GUID, a specific version, or a Hotfix. Comment out if not required.
	$LogType = "Information"
	#Domain Controller of the CM Domain
	$DomainControllerCM = $cfg["CM_DC1_FQDN"]

	$TestDCCon = Test-Connection -ComputerName $DomainControllerCM
	If (!$TestDCCon) {
		"The 1st Domain Controller of the Central Management Domain is not pingable. Please check the Connection to the Domain Controller." | Write-BLLog -LogType Information	
		$ExitCode = 1
	} else {
#region Variables	

		#Change Server Domain to distingushed name of the domain CM
		$SD = Get-ADDomain
		$SDDistName = $SD.DistinguishedName
		$PF_NetbiosName = $Env:UserDomain.ToLower()
		$CM_NetbiosName = $cfg["CM_DOMAIN_NETBIOSNAME"]
		$CM_DistinguishedName = $SDDistName.Replace($PF_NetbiosName,$CM_NetbiosName)
		"Importing Module for the AD. Invoking: Import-Module ActiveDirectory" | Write-BLLog -LogType $LogType
		Import-Module ActiveDirectory
		$LogType = "Information"
		"The Connection to the Domain Controller of the Central Management Domain is ok." | Write-BLLog -LogType $LogType
		#Setting Vars from ConfigDB
		#Accessgroup Exchange Admin 				ACC_EXC_Administrate
		$ExchAdminAccGroup = $cfg["EX2013_CFG_ACCESS_GROUP"].Split(";").Split("=")[1]
		$ExchAdminAccGroupScope = $cfg["EX2013_CFG_ACCESS_GROUP"].Split(";").Split("=")[3]
		$ExchAdminAccGroupCategory = $cfg["EX2013_CFG_ACCESS_GROUP"].Split(";").Split("=")[5]
		$ExchAdminAccGroupDesc = $cfg["EX2013_CFG_ACCESS_GROUP"].Split(";").Split("=")[7]
		
		#Role group Exchange Administrators 		AR_EXC_Admins
		$ExchAdminRoleGroup = $cfg["EX2013_CFG_ADMIN_ROLE_GROUP"].Split(";").Split("=")[1]
		$ExchAdminRoleGroupScope = $cfg["EX2013_CFG_ADMIN_ROLE_GROUP"].Split(";").Split("=")[3]
		$ExchAdminRoleGroupCategory = $cfg["EX2013_CFG_ADMIN_ROLE_GROUP"].Split(";").Split("=")[5]
		$ExchAdminRoleGroupDesc = $cfg["EX2013_CFG_ADMIN_ROLE_GROUP"].Split(";").Split("=")[7]
		
		#Ou Names
		$OUNameGroups = $cfg["EX2013_CFG_OU_GROUPS_PATH"].Split("\")
		$OUNameGroups0 = $OUNameGroups[0]
		$OUNameGroups1 = $OUNameGroups[1]
		$OUNameGroups2 = $OUNameGroups[2]
		$OUNameGroups3 = $OUNameGroups[3]
								
		$OU4ExchGroups = "OU=$OUNameGroups3,OU=$OUNameGroups2,OU=$OUNameGroups1,OU=$OUNameGroups0,$CM_DistinguishedName"
		
		
		#Service User Exchange Plattform Linked SVC_EXC_PF_LINKED			
		$LinkedExchSvcUser = $cfg["EX2013_CFG_LINKED_USER_PROPERTIES"].Split(";").Split("=")[1]
		$LinkedExchSvcUserPW = $cfg["EX2013_CFG_LINKED_USER_PROPERTIES"].Split(";").Split("=")[3] | ConvertTo-SecureString -AsPlainText -Force
		$LinkedExchSvcUserDesc = $cfg["EX2013_CFG_LINKED_USER_PROPERTIES"].Split(";").Split("=")[7]
		#OU Path for SVC_EXC_PF_LINKED
		$OUNameUser = $cfg["EX2013_CFG_OU_USERS_PATH"].Split("\")
		$OUNameUser0 = $OUNameUser[0]
		$OUNameUser1 = $OUNameUser[1]
		$OUNameUser2 = $OUNameUser[2]
		$OU4ExchSvcUser = "OU=$OUNameUser2,OU=$OUNameUser1,OU=$OUNameUser0,$CM_DistinguishedName"
		
#endregion Variables	
#region Groups		
		$OUGroups = Get-ADOrganizationalUnit -Server $DomainControllerCM -Filter {DistinguishedName -like $OU4ExchGroups}
		if ([string]::IsNullOrWhiteSpace($OUGroups)) {    
			try {
				$LogType = "Information"
				"Creating OU for the new groups: $OU4ExchGroups" | Write-BLLog -LogType $LogType
				$OUName = "OU=$OUNameGroups0,$CM_DistinguishedName"
				$Result = Get-ADOrganizationalUnit -Server $DomainControllerCM -Filter {DistinguishedName -like  $OUName} -ErrorAction SilentlyContinue
				if ([string]::IsNullOrWhiteSpace($Result)) {
					"The OU '$OUNameGroups0' does not exist." | Write-BLLog -LogType $LogType
					"Invoking: New-ADOrganizationalUnit -Server $DomainControllerCM –Name $OUNameGroups0 –Path $CM_DistinguishedName" | Write-BLLog -LogType $LogType
					New-ADOrganizationalUnit -Server $DomainControllerCM –Name $OUNameGroups0 –Path "$CM_DistinguishedName" -ErrorAction Stop
				} else {
					"The OU '$OUNameGroups0' already exists. Skipping the creation." | Write-BLLog -LogType $LogType
				}
				
				$OUName = "OU=$OUNameGroups1,OU=$OUNameGroups0,$CM_DistinguishedName"
				$Result = Get-ADOrganizationalUnit -Server $DomainControllerCM -Filter {DistinguishedName -like $OUName} -ErrorAction SilentlyContinue
				if ([string]::IsNullOrWhiteSpace($Result)) {
					"The OU '$OUNameGroups0\$OUNameGroups1' does not exist." | Write-BLLog -LogType $LogType
					"Invoking: New-ADOrganizationalUnit -Server $DomainControllerCM –Name $OUNameGroups1 –Path 'OU=$OUNameGroups0,$CM_DistinguishedName'" | Write-BLLog -LogType $LogType
					New-ADOrganizationalUnit -Server $DomainControllerCM –Name $OUNameGroups1 –Path "OU=$OUNameGroups0,$CM_DistinguishedName" -ErrorAction Stop
				} else {
					"The OU '$OUNameGroups0\$OUNameGroups1' already exists. Skipping the creation." | Write-BLLog -LogType $LogType
				}
				
				$OUName = "OU=$OUNameGroups2,OU=$OUNameGroups1,OU=$OUNameGroups0,$CM_DistinguishedName"
				$Result = Get-ADOrganizationalUnit -Server $DomainControllerCM -Filter {DistinguishedName -like $OUName} -ErrorAction SilentlyContinue
				if ([string]::IsNullOrWhiteSpace($Result)) {
					"The OU '$OUNameGroups0\$OUNameGroups1\$OUNameGroup2' does not exist." | Write-BLLog -LogType $LogType
					"Invoking: New-ADOrganizationalUnit -Server $DomainControllerCM –Name $OUNameGroups2 –Path 'OU=$OUNameGroups1,OU=$OUNameGroups0,$CM_DistinguishedName'" | Write-BLLog -LogType $LogType
					New-ADOrganizationalUnit -Server $DomainControllerCM –Name $OUNameGroups2 –Path "OU=$OUNameGroups1,OU=$OUNameGroups0,$CM_DistinguishedName" -ErrorAction Stop
				} else {
					"The OU '$OUNameGroups0\$OUNameGroups1\$OUNameGroup2' already exists. Skipping the creation." | Write-BLLog -LogType $LogType
				}
				
				$OUName = "OU=$OUNameGroups3,OU=$OUNameGroups2,OU=$OUNameGroups1,OU=$OUNameGroups0,$CM_DistinguishedName"				
				$Result = Get-ADOrganizationalUnit -Server $DomainControllerCM -Filter {DistinguishedName -like $OUName} -ErrorAction SilentlyContinue
				if ([string]::IsNullOrWhiteSpace($Result)) {
					"The OU '$OUNameGroups0\$OUNameGroups1\$OUNameGroup2\$OUNameGroups3' does not exist." | Write-BLLog -LogType $LogType
					"Invoking: New-ADOrganizationalUnit -Server $DomainControllerCM –Name $OUNameGroups3 –Path 'OU=$OUNameGroups2,OU=$OUNameGroups1,OU=$OUNameGroups0,$CM_DistinguishedName'" | Write-BLLog -LogType $LogType
					New-ADOrganizationalUnit -Server $DomainControllerCM –Name $OUNameGroups3 –Path "OU=$OUNameGroups2,OU=$OUNameGroups1,OU=$OUNameGroups0,$CM_DistinguishedName" -ErrorAction Stop
				} else {
					"The OU '$OUNameGroups0\$OUNameGroups1\$OUNameGroup2\$OUNameGroup3' already exists. Skipping the creation." | Write-BLLog -LogType $LogType
				}					
				
				
				"Creating new groups: '$ExchAdminAccGroup' and '$ExchAdminRoleGroup'" | Write-BLLog -LogType $LogType
				#Accessgroup = ACC_EXC_Administrate		RoleGroup = AR_EXC_Admins
				$Result = Get-ADGroup -Server $DomainControllerCM -Filter {Name -eq $ExchAdminAccGroup}
				if (!$Result) {
					"The group $ExchAdminAccGroup does not exist. Creating group now." | Write-BLLog -LogType $LogType
					"Invoking: New-ADGroup -Server $DomainControllerCM -Name $ExchAdminRoleGroup -GroupCategory $ExchAdminRoleGroupCategory -GroupScope $ExchAdminRoleGroupScope -Path $OU4ExchGroups -Description $ExchAdminRoleGroupDesc" | Write-BLLog -LogType $LogType
					New-ADGroup -Server $DomainControllerCM -Name $ExchAdminAccGroup -GroupCategory $ExchAdminAccGroupCategory -GroupScope $ExchAdminAccGroupScope -Path $OU4ExchGroups -Description $ExchAdminAccGroupDesc -ErrorAction Stop
				} else {
					"The Group $ExchAdminAccGroup already exists. Skipping creation of the group." | Write-BLLog -LogType $LogType
				}
				$Result = Get-ADGroup -Server $DomainControllerCM -Filter {Name -eq $ExchAdminRoleGroup}
				if (!$Result) {
					"The group $ExchAdminRoleGroup does not exist. Creating group now." | Write-BLLog -LogType $LogType
					"Invoking: New-ADGroup -Server $DomainControllerCM -Name $ExchAdminRoleGroup -GroupCategory $ExchAdminAccGroupCategory -GroupScope $ExchAdminAccGroupScope -Path $OU4ExchGroups -Description $ExchAdminAccGroupDesc" | Write-BLLog -LogType $LogType
					New-ADGroup -Server $DomainControllerCM -Name $ExchAdminRoleGroup -GroupCategory $ExchAdminRoleGroupCategory -GroupScope $ExchAdminRoleGroupScope -Path $OU4ExchGroups -Description $ExchAdminRoleGroupDesc -ErrorAction Stop
				} else {
					"The Group $ExchAdminRoleGroup already exists. Skipping creation of the group." | Write-BLLog -LogType $LogType
				}
				
				#ExchangeAdminRoleGroup als Mitglied der Gruppe ExchangeAdmin setzen
				"Setting $ExchAdminRoleGroup as member of $ExchAdminAccGroup." | Write-BLLog -LogType $LogType
				$Result = Get-ADGroupMember -Server $DomainControllerCM -Identity $ExchAdminAccGroup | Where {$_.Name -eq $ExchAdminRoleGroup} -ErrorAction SilentlyContinue
				if (!$Result) {
					"$ExchAdminRoleGroup is not a member of $ExchAdminAccGroup. Will adding $ExchAdminRoleGroup to the group $ExchAdminAccGroup now." | Write-BLLog -LogType $LogType
					"Invoking: Add-ADGroupMember -Server $DomainControllerCM -Identity $ExchAdminAccGroup -Members $ExchAdminRoleGroup" | Write-BLLog -LogType $LogType
					Add-ADGroupMember -Server $DomainControllerCM -Identity $ExchAdminAccGroup -Members $ExchAdminRoleGroup -ErrorAction Stop
				} else {
					"The group $ExchAdminRoleGroup is already a member of $ExchAdminAccGroup. Skipping the process." | Write-BLLog -LogType $LogType
				}
				$ExitCode = 0
			} catch {
				$LogType = "Error"
				$ErrorMessage = $_.Exception.Message
				"This error was thrown while waiting the Service $ServiceName to start and get the new status: $ErrorMessage" | Write-BLLog -LogType $LogType
				$Error.clear()
				Return 1
			}
		} else {
			try {
				#OU for groups already exists, the groups will be created now.  
				$LogType = "Information"
				"The OU '$OU4ExchGroups' already exist. Skipping the creation of the OUs." | Write-BLLog -LogType $LogType
				"Creating new groups: '$ExchAdminAccGroup' and '$ExchAdminRoleGroup'" | Write-BLLog -LogType $LogType
				#Accessgroup = ACC_EXC_Administrate		RoleGroup = AR_EXC_Admins
				# Get-ADGroup in Zusammenhang mit -Identity wirft einen Fehler bei nicht vorhandenem Account - Dieser ist durch -erroraction silentlycontinue nicht zu unterdrücken.
				$Result = Get-ADGroup -Server $DomainControllerCM -Filter { Name -eq $ExchAdminAccGroup }
				if (!$Result) {
					"The group $ExchAdminAccGroup does not exist. The group will be created now." | Write-BLLog -LogType $LogType
					"Invoking: New-ADGroup -Server $DomainControllerCM -Name $ExchAdminRoleGroup -GroupCategory $ExchAdminRoleGroupCategory -GroupScope $ExchAdminRoleGroupScope -Path $OU4ExchGroups -Description $ExchAdminRoleGroupDesc" | Write-BLLog -LogType $LogType
					New-ADGroup -Server $DomainControllerCM -Name $ExchAdminAccGroup -GroupCategory $ExchAdminAccGroupCategory -GroupScope $ExchAdminAccGroupScope -Path $OU4ExchGroups -Description $ExchAdminAccGroupDesc -ErrorAction Stop
				} else {
					"The group $ExchAdminAccGroup already exists. Skipping creation of the group." | Write-BLLog -LogType $LogType
				}
				$Result = Get-ADGroup -Server $DomainControllerCM -Filter { Name -eq $ExchAdminRoleGroup}
				if (!$Result) {
					"The group $ExchAdminRoleGroup does not exist. The group will be created now." | Write-BLLog -LogType $LogType
					"Invoking: New-ADGroup -Server $DomainControllerCM -Name $ExchAdminAccGroup -GroupCategory $ExchAdminAccGroupCategory -GroupScope $ExchAdminAccGroupScope -Path $OU4ExchGroups -Description $ExchAdminAccGroupDesc" | Write-BLLog -LogType $LogType
					New-ADGroup -Server $DomainControllerCM -Name $ExchAdminRoleGroup -GroupCategory $ExchAdminRoleGroupCategory -GroupScope $ExchAdminRoleGroupScope -Path $OU4ExchGroups -Description $ExchAdminRoleGroupDesc -ErrorAction Stop
				} else {
					"The group $ExchAdminRoleGroup already exists. Skipping creation of the group." | Write-BLLog -LogType $LogType
				}
				#ExchangeAdminRoleGroup als Mitglied der Gruppe ExchangeAdmin setzen
				"Setting $ExchAdminRoleGroup as member of $ExchAdminAccGroup." | Write-BLLog -LogType $LogType
				$Result = Get-ADGroupMember -Server $DomainControllerCM -Identity $ExchAdminAccGroup | Where {$_.Name -eq $ExchAdminRoleGroup} -ErrorAction SilentlyContinue 
				if (!$Result) {
					"$ExchAdminRoleGroup is not a member of $ExchAdminAccGroup. Will adding $ExchAdminRoleGroup to the group $ExchAdminAccGroup now." | Write-BLLog -LogType $LogType
					"Invoking: Add-ADGroupMember -Server $DomainControllerCM -Identity $ExchAdminAccGroup -Members $ExchAdminRoleGroup" | Write-BLLog -LogType $LogType
					Add-ADGroupMember -Server $DomainControllerCM -Identity $ExchAdminAccGroup -Members $ExchAdminRoleGroup -ErrorAction Stop
				} else {
					"The group $ExchAdminRoleGroup is already a member of $ExchAdminAccGroup. Skipping the process." | Write-BLLog -LogType $LogType
				}
				$ExitCode = 0
			} catch {
				$LogType = "Error"
				$ErrorMessage = $_.Exception.Message
				"This error was thrown while waiting the Service $ServiceName to start and get the new status: $ErrorMessage" | Write-BLLog -LogType $LogType
				$Error.clear()
				Return 1
			}
		}
#endregion Groups		
#region User
		#Service Account und OU für den Svc-Account anlegen 
		$OUUser = Get-ADOrganizationalUnit -Server $DomainControllerCM -Filter {DistinguishedName -like $OU4ExchSvcUser}
		if([string]::IsNullOrWhiteSpace($OUUser)) {
			try {
				$LogType = "Information"
				"The OU for the Service User does not exist. The OU will added to the AD now." | Write-BLLog -LogType $LogType
				$OUName = "OU=$OUNameUser0,$CM_DistinguishedName"
				$Result = Get-ADOrganizationalUnit -Server $DomainControllerCM -Filter {DistinguishedName -like $OUName} -ErrorAction SilentlyContinue
				if (!$Result) {
					"The OU '$OUNameUser0' does not exists. Will create it now." | Write-BLLog -LogType $LogType
					"Invoking: New-ADOrganizationalUnit -Server $DomainControllerCM –Name $OUNameUser0 –Path $CM_DistinguishedName" | Write-BLLog -LogType $LogType
					New-ADOrganizationalUnit -Server $DomainControllerCM –Name Admin –Path "$CM_DistinguishedName"
				} else {
					"The OU $OUNameUser0 already exists. Skipping the creation." | Write-BLLog -LogType $LogType
				}
				
				$OUName = "OU=$OUNameUser1,OU=$OUNameUser0,$CM_DistinguishedName"
				$Result = Get-ADOrganizationalUnit -Server $DomainControllerCM -Filter {DistinguishedName -like $OUName} -ErrorAction SilentlyContinue
				if (!$Result) {
					"The OU '$OUNameUser0\$OUNameUser1' does not exists. Will create it now." | Write-BLLog -LogType $LogType
					"Invoking: New-ADOrganizationalUnit -Server $DomainControllerCM –Name $OUNameUser1 –Path 'OU=$OUNameUser0,$CM_DistinguishedName'" | Write-BLLog -LogType $LogType
					New-ADOrganizationalUnit -Server $DomainControllerCM –Name $OUNameUser1 –Path "OU=$OUNameUser0,$CM_DistinguishedName"
				} else {
					"The OU $OUNameUser0\$OUNameUser1 already exists. Skipping the creation." | Write-BLLog -LogType $LogType
				}
				
				$OUName = "OU=$OUNameUser2,OU=$OUNameUser1,OU=$OUNameUser0,$CM_DistinguishedName"
				$Result = Get-ADOrganizationalUnit -Server $DomainControllerCM -Filter {DistinguishedName -like $OUName} -ErrorAction SilentlyContinue
				if (!$Result) {
					"The OU '$OUNameUser0\$OUNameUser1\$OUNameUser2' does not exists. Will create it now." | Write-BLLog -LogType $LogType
					"Invoking: New-ADOrganizationalUnit -Server $DomainControllerCM –Name $OUNameUser2 –Path 'OU=$OUNameUser1,OU=$OUNameUser0,$CM_DistinguishedName'" | Write-BLLog -LogType $LogType
					New-ADOrganizationalUnit -Server $DomainControllerCM –Name $OUNameUser2 –Path "OU=$OUNameUser1,OU=$OUNameUser0,$CM_DistinguishedName"
				} else {
					"The OU $OUNameUser0\$OUNameUser1\$OUNameUser2 already exists. Skipping the creation." | Write-BLLog -LogType $LogType
				}
				
				#User anlegen:
				$Result = Get-ADUser -Server $DomainControllerCM -Filter {Name -eq $LinkedExchSvcUser}
				if (!$Result) { 
					"The User '$LinkedExchSvcUser' does not exist. Will add the new user now." | Write-BLLog -LogType $LogType
					"Invoking: New-ADUser -Server $DomainControllerCM -Name $LinkedExchSvcUser -Path '$OU4ExchSvcUser' -AccountPassword 'xxxxx' -Enabled $true -PasswordNeverExpires $true" | Write-BLLog -LogType $LogType
					New-ADUser -Server $DomainControllerCM -Name $LinkedExchSvcUser -Path $OU4ExchSvcUser -AccountPassword $LinkedExchSvcUserPW -Description $LinkedExchSvcUserDesc -Enabled $true -PasswordNeverExpires $true
				} else {
					"The User $LinkedExchSvcUser already exists. Skipping the creation." | Write-BLLog -LogType $LogType
				}
				$ExitCode = 0
			} catch {
				$LogType = "Error"
				$ErrorMessage = $_.Exception.Message
				"This error was thrown while waiting the Service $ServiceName to start and get the new status: $ErrorMessage" | Write-BLLog -LogType $LogType
				$Error.clear()
				Return 1
			}
		} else {
			try {
			#User anlegen, OU existiert bereits
				$LogType = "Information"
				"The OU '$OU4ExchSvcUser' already exist. OU-Information: `r`n $OUGroups"  | Write-BLLog -LogType $LogType
				"Skipping the creation of the OUs. Only the user '$LinkedExchSvcUser' will be created." | Write-BLLog -LogType $LogType
				$Result = Get-ADUser -Server $DomainControllerCM -Filter {Name -eq $LinkedExchSvcUser}
				if (!$Result) {
					"The User '$LinkedExchSvcUser' dows not exist. Will add the new user now." | Write-BLLog -LogType $LogType
					"Invoking: New-ADUser -Server $DomainControllerCM -Name $LinkedExchSvcUser -Path $OU4ExchSvcUser -AccountPassword 'xxxxx' -Enabled $true -PasswordNeverExpires $true" | Write-BLLog -LogType $LogType
					New-ADUser -Server $DomainControllerCM -Name $LinkedExchSvcUser -Path $OU4ExchSvcUser -AccountPassword $LinkedExchSvcUserPW -Description $LinkedExchSvcUserDesc -Enabled $true -PasswordNeverExpires $true
				} else {
					"The User $LinkedExchSvcUser already exists. Skipping the creation." | Write-BLLog -LogType $LogType
				}
				$ExitCode = 0
			} catch {
				$LogType = "Error"
				$ErrorMessage = $_.Exception.Message
				"This error was thrown while waiting the Service $ServiceName to start and get the new status: $ErrorMessage" | Write-BLLog -LogType $LogType
				$Error.clear()
				Return 1			
			}	
		}          
	}
	Return $ExitCode
}
#endregion User
#endregion

#region uninstallation
Function Invoke-ISUninstallation() {

	$UninstallInformation = Get-BLUninstallInformation -DisplayName $AppDisplayName
		$LogType = "Information"
		"Actually there is no uninstallation provided for the Exchange Domain Accounts in the CM Domain." | Write-BLLog -LogType $LogType
		$ExitCode = 0
	Return $ExitCode
}
#endregion

## ====================================================================================================
## MAIN
## ====================================================================================================
## CUSTOMIZE: RunAsTask
## User aus CM Domain
#	CM Administrator - Geht nicht, da Add-BLLocalAdminGroupMember mit der lokalen Domaine $DomainName = $Env:DomainName arbeitet
$TaskUserDomain = $cfg["CM_AD_CFG_DOMAINACCOUNT"].Split("\")[0].Trim()
$TaskUserName= $cfg["CM_AD_CFG_DOMAINACCOUNT"].Split("\").Split(";")[1].Trim()
$TaskPassword = $cfg["CM_AD_CFG_DOMAINACCOUNT"].Split(";")[1].Trim()

##OPTION: RunAsTask
#$TaskUserDomain =	$cfg["AD_CFG_DOMAINACCOUNT"].Split("\")[0].Trim()
#$TaskUsername =		$cfg["AD_CFG_DOMAINACCOUNT"].Split("\").Split(";")[1].Trim()
#$TaskPassword =		$cfg["AD_CFG_DOMAINACCOUNT"].Split(";")[1].Trim()
### Start a second instance of the script; the main instance will wait here until the task instance is done:				# -NoTask
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
