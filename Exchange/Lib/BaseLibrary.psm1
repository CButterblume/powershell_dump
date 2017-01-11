## ---------------------------------------------------------------------------
## File                 : BaseLibrary.psm1
##                        -------------
## Purpose              : Core functions library for the install script
##
## Syntax               : Import-Module "C:\RIS\Lib\SCCM_CoreFunctions.ps1"
##
## region Version Management
## Version Mngt
## ============
## Date			Version	By		Change Description
## -------------------------------------------------------------------------
## 17.03.2011	C. Wallner		Added INVOKE-Powershell
## 11.2011		H. Baum			Added CONFIG-Functions, added -insttype to SCCM:Invoke-MSI
## 25.11.2011	M. Richardt		Added SCCM:Query-RDS-Installation
## 								Added SCCM:Invoke-RDS-InstallMode
## 								Added SCCM:Invoke-RDS-ExecuteMode
## 16.05.2012	M. Richardt		Added revised config functions, with http download of cfg files.
##								Mainly *internal* use:
##									SCCM:Get-Config-File
##									SCCM:Read-Config-File
##									SCCM:Verify-Config-Variables
##                              Package Developer use:
##									SCCM:Set-Config-Variables
##								Declared 2011 Config functions "Legacy", do not use in new packages anymore!
## 27.06.2012	M. Richardt		Added SCCM:Split-Config-Account
## 								Added SCCM:Check-HyperVGuest
## 								Added SCCM:Get-PrimaryDNSSuffix
## 28.06.2012	M. Richardt		Added SCCM:Log-Config-Settings
## 02.07.2012	M. Richardt		Added call stack information to SCCM:WriteLog to log the calling function
## 02.07.2012	M. Richardt		Added SCCM:Split-Config-ElementList
## 10.07.2012	T. Menke		Added SCCM:applyTemplate
## 11.07.2012	M. Richardt		Changed SCCM:Write-EventLog: $ID passed to WriteEntry limited to 0..65535
## 23.07.2012	H. Baum			Loggfiles for MSIs not TEMP but $RIS_LOGIFILE
## 31.07.2012	H. Baum			Import-INI: Trim auf Key und Value  1. Zeichen = matchen
## 16.08.2012	M. Richardt		Added SCCM:Test-InstallationAsTask
## 								Added SCCM:Fork-InstallationAsTask
## 								Changed SCCM:Initialize-Installation to accommodate SCCM:Fork-InstallationAsTask
## 								Changed SCCM:FollowUp-Installation to accommodate SCCM:Fork-InstallationAsTask
## 								Changed SCCM:Start-Process to catch stderr output as well.
## 23.08.2012	M. Richardt		Minor changes to SCCM:Fork-InstallationAsTask
## 05.09.2012	T. Menke		Minor changes to SCCM:Initialize-Installation
## 31.07.2012	M. Richardt		Renamed script from SCCM_Corefunctions.ps1 to BaseLibrary.psm1
##								Changed naming conventions to only use "approved" verbs for the functions.
##								Added a common prefix "BL" to all function nouns.
##								Removed the need for 'SCCM_InitializeLibrary.ps1'
##								Changed Initialize-BLFunctions to confirm script execution if not forced and support more logging options.
##								Changed Write-BLLog to allow Debug output, custom log types and suppression of the default columns; LogType 'Information' is now set as default.
##								Added 'Set-BLLogDebugMode'
##								Changed 'Set-BLServiceStartup' to support delayed start
##								Integrated SCCM:Invoke-MsiUninstall into Invoke-BLSetupMsi
##								Corrected potential issue with 'Set-BLScheduledTask' and 'Remove-BLScheduledTask' on remote computers
##								Added 'Update-BLLibraryScript' to migrate existing scripts to the new function syntax
##								Added 'Format-BLXML'
##								Added 'Test-BLElevation'
##								Added 'Get-BLShortcut'
##								Added 'New-BLShortcut'
## 12.08.2013	T. Menke		Added
##								Import-BLConfigDB,
##								Get-BLMultiValue,
##								Enable-BLRemoteDesktopConfig,
##								Disable-BLIPv6,
##								Disable-BLFirewall,
##								Set-BLDriveLetters,
##								Set-BLPageFileSize,
##								Dismount-BLISOFiles,
##								Get-BLNetmask,
##								Set-BLAdapterIP,
##								Set-BLIPConfig,
##								Set-BLDNSServers,
##								Set-BLNICNames,
##								Get-BLGeneratedMAC,
##								Rename-BLCSV
## 19.08.2013	M. Richardt		Added 'ConvertTo-BLStringBitmask'
## 27.08.2013	M. Richardt		Added 'Get-BLDVDDrives'
## 11.09.2013	M. Richardt		Changed 'Invoke-BLSetupNSIS': folder for option "/D" may NOT be enclosed in double quotes, even if the path contains spaces
##								Changed 'Export-BLConfigDBConvertedTemplateFile': Now returns 1 if template file not found.
## 16.09.2013	A. Horn			Added 'Get-BLLogFileName'
## 17.09.2013	A. Horn			Fixed Bug #0012215: HAFIS 3: Set-BLRDSInstallMode; Set-BLRDSExecuteMode liefern ErrorCode
## 18.09.2013	B. Kolbe		Changed 'Get-BLLogFileName': added a switch to create a path instead of a logfile
##								Changed 'Enter-BLExecutionAsTask','Remove-BLScheduledTask', 'Set-BLScheduledTask': Added additional logging information, deleted not needed checkings "Does task still exist?"
##								Changed 'Set-BLScheduledTask': Revised first part (Get WMI object and perform connection test to remote computer)
## 26.09.2013	H. Baum         Get-BLLogFileName: bei Option -CreatePath Verzeichnis auch anlegen, falls noch nicht existent
## 08.10.2013	J. Martinewski	Changed: (Eingangsparameter hinzugefügt)
##								Set-BLPageFileSize
##								Set-BLIPConfig
##								Set-BLDNSServers
##								Set-BLNICNames
##								Set-BLNICName
##								Get-BLGeneratedMAC
## 09.10.2013	M. Richardt		Fixed Copy-BLConfigDBFile (Changed "$Global:CFG_ConfigVirtualFolder" to "$CFG_ConfigVirtualFolder")
## 08.10.2013	J. Martinewski	Changed: Dismount-BLISOFiles (Modified for Windows 2012)
## 14.10.2013	H. Baum         Changed: $Global:RIS_Summarizelog -> $Script:RIS_Summarizelog
## 17.10.2013	H. Baum         Added: Copy-BLArchiveContent
## 22.10.2013	M. Richardt		Added 'Get-BLADcontroller'
##				M. Richardt		Added Format-BLHashTable
##				M. Richardt		Changed Write-BLLog: added argument "-CustomCol"
##				M. Richardt		Changed Initialize-BLFunctions, Exit-BLFunctions: Fixed issue with installation end not showing up in RIS_Summarize.log, added dedicated uninstallation logging.
## 23.10.2013   A. Horn			Changed Import-BLConfigDBFile: added support for comments in Defaults.txt (starting with #) and detection of @EOF@
## 22.10.2013	M. Richardt		Fixed function name 'Get-BLADcontroller' to 'Get-BLADDomainController'
## 12.11.2013	M. Richardt		Changed: Test-BLElevation returns true if running in System context as well.
## 13.11.2013	M. Richardt		Changed: Add-LocalAdminGroupMember and Get-BLLocalGroupMembers to support remote computers
##								Added: Get-BLComputerDomain
## 14.11.2013	M. Richardt		Added functions to work with ini file format in a hash table:
##									Get-BLIniHTContent
##									Get-BLIniHTSection
##									Get-BLIniHTSectionNames
##									Get-BLIniHTValue
##									Out-BLIniHT
##									Remove-BLIniHTKey
##									Remove-BLIniHTSection
##									Set-BLIniHTSection
##									Set-BLIniHTValue
## 26.11.2013	M. Richardt		Added functions:
##									Invoke-BLCommand32Bit
##									Invoke-BLCommandTimeout
## 27.11.2013	M. Richardt		Changed function Enter-BLExecutionAsTask:
##								- Added argument -RunAs32 to restart the script in a 32bit PS shell (requires new install.cmd)
##								- Added warning for -NoTask when the user running the script differs from the specified task user
##								Added function Get-BLRegistryKeyX64
## 06.12.2013	H.Baum			Get-BLConfigDBVariables  -Path Argument: Optionl , gibt Pfad der Konfig-CFG an
## 16.12.2013	M. Richardt		Added function: Get-BLScriptLineNumber (mainly for use in script blocks, where the line count begins with the script block)
##								Enter-BLExecutionAsTask: Removed "-RunOnce" from Set-BLScheduledTask (could remove the task before Exit-BLFunctions had a chance to check whether it was running as task)
## 16.12.2013   H.Baum          LogCmd [switch]argument in Start-BLProcess 
## 19.12.2013	M. Richardt		Added function: ConvertFrom-BLSecureString
## 23.01.2014	M. Richardt		Exported variable: $CFG_ConfigVirtualFolder
## 28.01.2014	M. Richardt		Added functions:
##									Get-BLRegistryHiveX64
##									Get-BLRegistryValueKind
##									Get-BLRegistryValueX64
##									New-BLRegistryKeyX64
##									Remove-BLRegistryValueX64
##									Set-BLRegistryValueX64
##								Changed Enter-BLExecutionAsTask to use the new X64 registry functions; -RunAs32 now works even if the original script is started in a 64bit environment.
## 11.02.2014  	H. Baum			Set-BLServiceStartup: Optionen -Start und -Stop eingefügt							
## 28.01.2014	M. Richardt		Added functions:
##									Get-BLSID
##									Get-BLADUser
##									Get-BLOSArchitecture
##									Get-BLSpecialFolder
##									Get-BLUninstallInformation
##								Exported new variable (for use in Get-BLSpecialFolder): $BL_SpecialFolder
##								Changed function: Get-BLRegistryKeyX64 to support returning subkeys
##								Changed function: Enter-BLExecutionAsTask to support uninstall
## 20.02.2014	M. Richardt		Added function: Get-BLMsiProperties
## 24.02.2014	M. Richardt		Changed function: Get-BLMsiProperties
##									Fixed an issue where the COM object kept a handle to the msi file open
## 26.02.2014	M. Richardt		Changed functions: Format-BLXML, Format-BLHashTable
##									Now accept pipeline input of the elements to format
## 07.03.2014	J. Martinewski	Changed functions: New-BLShortcut
##								Added function: Remove-BLShortcut
## 11.03.2014	M. Richardt		Added function: Get-BLAccountFromSID
##								Renamed function: Get-BLSID to Get-BLSIDFromAccount, added Get-BLSID as alias for backward compatibility
##								Changed functions New-BLShortcut, Remove-BLShortcut: Aligned arguments, used Get-BLSpecialFolder instead of registry
## 12.03.2014	M. Richardt		Changed functions: *-BLExecutionAsTask, major overhaul
##									- The task will be removed even if the scheduled script instance is not started or crashed before initialization.
##									- Added Stop-BLExecutionAsTask to 'gracefully' end a hung installation from the command line before the timeout.
##									- Fixed issue where Timeout could not be longer than an hour
##									- On 2012 or later, the scheduled tasks are now managed with the PS 3.0 *-TaskSchedule Cmdlets instead of schtasks.exe;
##									  on 2008R2 or earlier schtasks.exe will still be used.
## 31.03.2014	M. Richardt		Changed function:  Get-BLADDomainController
##									Fixed an issue if PDCe was not responding (Mantis 0012925)
## 02.04.2014	H. Baum		    Added function:  Add-BLLocalGroupMember
## 07.04.2014	M. Richardt		Added functions:
##									Get-BLHashFromFile
##									Get-BLHashFromString
## 30.04.2014	M. Richardt		Changed function: Initialize-BLFunctions
##									- Added exception list when importing environment variables from the registry (to prevent the USERNAME variable from being set to SYSTEM)
## 								Changed function: Get-BLUninstallInformation
##									- Added switches -x64Only and -x86Only to restrict the software architecture.
##									- Enhanced GUID detection (e.g. "Citrix Single Sign-On Console" doesn't have an uninstall string)
##									- Fixed issue when registry value "UninstallString" was missing
##									- Fixed minor isse where the display name was not printed in warning when more than one install with the name was found.
## 13.05.2014	M. Richardt		Added function: Disable-BLGeneratePublisherEvidence
##								Removed function (to avoid confusion with XA6.5): Initialize-BLXACommands (XenApp 6, not supported anymore!)
## 22.05.2014	M. Richardt		Changed function: Get-BLHashFromFile
##									- Can now handle files with Read-Only flag
## 26.05.2014	M. Richardt		Changed function: Get-BLMsiProperties
##									- Support for msp files
## 26.05.2014	M. Richardt		Changed functions: BLRegistry*X64
##									- Support for remote registry
## 17.06.2014	M. Richardt		Changed functions:
##									- Get-BLIniHTContent: corrected function name from Get-BLIIniHTContent
##									- Out-BLIniHT:
##										- now accepts pipeline input of the ini hashtable
##										- fixed issue where the internal section ____ROOT____ could be included in the output
## 02.07.2014	M. Richardt		Changed function: Get-BLUninstallInformation
##									- Added support to search for installed QFE hotfixes
##									- Added Comment Based Help
## 04.07.2014   H.Baum			Added function: Set-BLLogLevel -LowestLevelToLog  LevName
##									Unterdrückt Logging von Leveln kleiner <Param>
## 04.07.2014   J. Martinewski	Changed function: Initialisation of Set-BLLogLevel
## 21.07.2014	M. Richardt		Added functions:
##									- Get-BLNetFrameworkVersions
##									- Get-BLOSVersion
##									- Initialize-BLWUAErrorCodes
## 								Changed function: Install-BLWindowsHotfix now properly checks the error code.
## 22.07.2014	M. Richardt		Added functions:
##									- Uninstall-BLWindowsHotfix
##									- ConvertFrom-BLEvt
## 								Changed function: Exit-BLFunctions now warns and explicitly lists the contents of SetExitCode if it's not a single integer.
## 23.07.2014	M. Richardt		Added function: ConvertFrom-BLEvt
## 								Changed function: Install-BLWindowsHotfix now supports writing to a log file (evt, csv, log).
## 30.07.2014	M. Richardt		Changed function: Exit-BLFunctions fixed issue with Powershell 2.0 when testing SetExitCode
## 07.08.2014	M. Richardt		Added functions:
##									- Initialize-BLCustomTypes (not exported)
##									- Get-BLSymbolicLinkTarget
## 11.08.2014	M. Richardt		Changed functions:
##									- BLRegistry*X64: ErrorAction now typed
##									- Get-BLNetFrameworkVersions: Renamed to Get-BLDotNetFrameworkVersions
## 								Added functions:
##									- Remove-BLRegistryKeyX64
##									- New-BLUninstallEntry
##									- Remove-BLUninstallEntry
## 12.08.2014	M. Richardt		Added functions:
##									- Get-BLNetInterfaceIndex
##									- Get-BLNetRoute
##									- Get-BLSubnetInformation
## 12.08.2014	M. Richardt		Changed functions:
##									- Write-BLLog: new switch "-NoTrim" to keep formatted output (route print, robocopy, ...)
## 20.08.2014	M. Richardt		Added functions:
##									- Get-BLInternetZoneFromUrl
##									- Get-BLInternetZoneMappings
##									- Remove-BLInternetZoneMapping
##									- Set-BLInternetZoneMapping
##								Changed function:
##									- Initialize-BLCustomTypes: Added C# for the *-BLInternetZone... functions
## 04.09.2014	M. Richardt		Changed functions:
##									- Get-BLRegistryKeyX64, Get-BLRegistryValueX64, Set-BLRegistryValueX64: Fixed issue with the "default" value of a registry key
##									- *-BLInternetZone*: enhanced pipeline and error handling
## 24.10.2014	H. Baum 		Changed functions:
##                                  - Import-BLConfigDBFile:   Parameter -CreateFiles  ergänzt
##                                  - Get-BLConfigDBVariables: Parmaeter [switch]$CreateFiles  ergänzt
##                                  - *.CFG-Dateien können Abschnitte @FILE@:<relPathOfFile> enhalten, die bei gesetztem Schalter nach C:\RIS\FILES\<relPathOfFile> kopiert werden 
##                                    die Abschnittet enthalten die Inhalte der Datei b64 encoded
## 03.11.2014	M. Richardt		Removed function: Copy-BLConfigDBFile (not exported)
##								Replaced function Import-BLConfigDBFile with ConvertTo-BLConfigDBObject
##								Changed functions:
##									- Get-BLConfigDBVariables: Doesn't create a local copy of the .cfg file anymore.
##									  .cfg files will by default be read from the SCCM Management Point or the location specified in ATOS_CFGDB_LOCATION
##									  Local copies (for test/development ONLY) can be used by pointing the environment variable ATOS_CFGDB_LOCATION to the .cfg file folder.
##									- Write-BLConfigDBSettings:
##										- Hides passwords 
##										- Now supports switch RegEx to filter by RegEx instead of the beginning of the key
##								New functions:
##									- Get-BLConfigDBLocation
##									- Set-BLConfigDBLocation
##									- Test-BLRegularExpression
## 10.11.2014	M. Richardt		Removed function: Test-BLConfigDBVariables (not exported; now integrated into Get-BLConfigDBVariables)
##								Changed functions:
##									- Get-BLConfigDBVariables: cfg file import encoding changed to Windows-1252
##									- Split-BLConfigDBElementList: Now supports passing a hash table with default values.
##									- Write-BLConfigDBSettings, ConvertTo-BLConfigDBObject: Changed to new Details format with named key/value pairs.
## 12.11.2014	M. Richardt		Added function: Get-BLConfigDBCfgList
##								New ConfigDB location format (http path now without the trailing ConfigDB/Unattend virtual folder)
## 13.11.2014	M. Richardt		Added function: Get-BLConfigDBUAFile
## 13.11.2014	M. Richardt		Changed virtual folder for unattend.xml from "Unattended" to "Unattend"
## 20.11.2014	M. Richardt		Changed function: ConvertTo-BLConfigDBObject; changed cfg line parsing and Regular Expression handling
## 11.12.2014	M. Richardt		Added functions:
##									- Test-BLPSHostTranscription
##									- Test-BLPSHostWriteHost
##									- Update-BLExceptionInvocationInfo
##								Added exported variable:
##									- $BL_PSHost with properties SupportsTranscription, SupportsWindowTitle, SupportsWriteHost
##								Changed functions:
##									- Initialize-BLFunctions: now verifies transcript capabilities
##									- Get-BLConfigDBLocation: now uses a DNS SRV entry (defined in $BL_CFGDB_ServiceName) as default location (instead of SCCM MP)
##								Enhanced compatibility with hosts not supporting transcription (ISE) and/or Write-Host (SCO)
## 17.12.2014	M. Richardt		Added functions:
##									- New-BLConfigDBLocationObject (not exported)
##									- Test-BLConfigDBLocation
##								Changed functions:
##									- Update-BLExceptionInvocationInfo: now accepts pipeline input
##									- Get-BLConfigDBLocation: now supports failover for ConfigDB locations (";" as path delimiter); .Active is now only True if the location was found.
## 09.01.2015	M. Richardt		Added function:
##									- Get-BLRDSGracePeriodDaysLeft
##								Changed functions:
##									- Get-BLConfigDBCfgList: fixed potential issues when testing the ConfigDB location
##									- Get-BLConfigDBUAFile: fixed potential issues when testing the ConfigDB location
##								Added/updated comment based help:
##									- Get-BLConfigDBCfgList
##									- Get-BLConfigDBLocation
##									- Get-BLConfigDBUAFile
##									- Get-BLConfigDBVariables
##									- Set-BLConfigDBLocation
##									- Write-BLConfigDBSettings
## 14.01.2015	M. Richardt		Added function:
##									- Get-BLDfsrReplicatedFolderInfo
##								Removed group "SCCM" and moved Get-BLSCCMManagementPoint to group "Miscellaneous"
## 19.01.2015	M. Richardt		Changed functions:
##									- Initialize-BLFunctions: now tries to find the calling script's version by checking the parent folder's name.
##									- Split-BLConfigDBElementList: columns containing the delim can now be enclosed in double quotes
##									- Get-BLComputerDomain: now uses a C# based custom class [BLNetApi] (defined in Initialize-BLCustomTypes).
##									  The WMI query formerly used didn't work in child domains.
##								Removed function:
##									- Get-BLRDSGracePeriodDaysLeft: now in BaselibrarySH.psm1 as Get-BLSHGracePeriodDaysLeft (now with support for remote queries)
## 12.03.2015	M. Richardt		Changed functions:
##									- Get-BLDnsSrvRecord:
##										- added automatic domain suffix support for the API call
##										- added failover support for nslookup method (slow)
##										- API is the new default; nslookup can be forced using the switch -nslookup
## 01.04.2015	A. Horn			Added function:
##									- Remove-BLLocalGroupMember
## 08.04.2015	M. Richardt		Added functions:
##									- New type CSHARP_BLAccountRights
##									- New type CSHARP_BLLookupAccount
##									- Get-BLAccountsWithUserRight
##									- Get-BLHyperVHostingServer
##									- Get-BLUserRightsForAccount
##									- Grant-BLUserRights
##									- Resolve-BLSid
##									- Revoke-BLUserRights
##									- Set-BLServiceCredentials
##									- Show-BLUserRightsInformation
##									- Show-BLWellKnownSidsInformation
##									- Test-BLSid
##								Changed functions:
##									- Get-BLAccountFromSID, Get-BLSIDFromAccount: declared deprecated; use Resolve-BLSid instead
##									- Get-BLConfigDBVariables: now writes the contents of _@INFO@ to the log file
##								Changed CSharp:
##									- $CSHARP_BLAccountRights: fixed issues when imported under PS 2.0
## 28.05.2015	M. Richardt		Added functions:
##									- Get-BLCredentialManagerPolicy
##									- Get-BLLogonSession
##									- Get-BLScheduledTask
##									- Set-BLCredentialManagerPolicy
##									- Split-BLDistinguishedName
##								Changed functions:
##									- Enter-BLExecutionAsTask
##										- Now tries to work around the group policy that disables the Credential Manager
##									- Set-BLExecutionAsTaskStatus
##										- Changes to support the Credential Manager policy handling
##									- Get-BLOSArchitecture
##										- Now supports remote computers
##									- Get-BLUninstallInformation
##										- Now can return a list of all installed programs; this part works remotely as well.
##										- Returns a new boolean property 'SystemComponent'.
##										- Fixed issue with GUID detection when a registry key name was followed by additional characters (as in '{<GUID>} - 1033')
##									- Invoke-BLSetupMsi
##										- Now accepts argument -MspFile (alias for MsiFile)
##										- Now accepts instType /i for msp (determined by extension).
##									- Remove-BLScheduledTask
##										- Now uses Get-BLScheduledTask to check if the task exists (eliminates confusing warning messages)
##										- Now supports switch -Quiet to suppress the 'Task did not exist' message.
##									- Test-BLExecutionAsTask
##										- Now uses Get-BLScheduledTask instead of the MUI dependent schtasks.exe
## 04.08.2015	M. Richardt		Added function:
##									- Get-BLComputerBootTime
## 								Changed functions:
##									- New-BLShortcut with additional path specifications, icon location, window style.
##									- Remove-BLShortcut with additional path specifications, changed conditions to delete empty parent folder.
## 13.08.2015	M. Richardt		Added function:
##									- Get-BLInternetExplorerVersion
## 								Changed functions:
##									- Get-BLShortcut now supports advertised shortcuts.
##									- Get-BLMsiProperties now supports advertised .lnk files as input path.
## 19.08.2015	M. Richardt		Added function:
##									- Read-BLUIMessageBox
## 								Changed functions:
##									- Get-BLInternetExplorerVersion: fixed issue with IE8 detection.
##								Updates to comment based help.
## 23.09.2015	M. Richardt		Added function:
##									- Read-BLHost
## 								Changed function:
##									- Get-BLIniHTContent: fixed issue with comments
## 29.09.2015	M. Richardt		Added function:
##									- Compare-BLWmiNamespace
## 05.10.2015	M. Richardt		Changed function:
##									- New-BLUninstallEntry: new arguments -NoModify, ModifyPath
## 08.10.2015	M. Richardt		Added function:
##									- Copy-BLWindowsCertToJava
## 16.10.2015	H. Baum			Added function:
##									- New-BLConfigDBWebClient:	creates WebClient Object and sets header to authorize access to ConfigDB service
##														checks elevation OR user name starts with SVC_
## 19.11.2015	M. Richardt		Added functions:
##									- Get-BLADPreferredBridgehead
##									- Get-BLComputerPendingReboot
## 03.12.2015	M. Richardt		Changed function:
##									- ConvertTo-BLConfigDBObject: now supports ConfigDB values with Well Known Sids '${WKS:...}'; see the function's comment section for details.
## 17.12.2015	M. Richardt		Changed function:
##									- ConvertTo-BLConfigDBObject: fixed minor issue when setting the #WKS key.
##									- New-BLConfigDBWebClient: sends new header with more information.
##									- Test-BLElevation: now queries the user's security token
##									- Get-BLConfigDBVariables: updated Help to include the new WKS support.
## 								Added functions:
##									- Compress-BLString
##									- Expand-BLString
## 26.01.2016	M. Richardt		Changed functions:
##									- Write-BLLog: now only writes to RIS_Summarizelog and EventLog if a TranscriptFile is configured (interactive use)
##									- Get-BLRegistryKeyX64: now returns new property "PSLastWriteTime" with the last write access.
##									- Get-BLUninstallInformation: parameterset Software_All now returns InstallDates as DateTime, and uses PSLastWriteTime if InstallDate is empty.
##								Added CSharp:
##									- $CSHARP_BLRegQueryInfoKey: Adds the class BLRegQueryInfoKey (used to retrieve the LastWriteTime of a registry key)
## 								Added functions:
##									- Compare-BLDirectory: compares two directories
## 18.02.2016	M. Richardt		Added functions:
##									- Get-BLShortPath: Gets the short file name ("8.3") for a file or directory.
##									- Get-BLFullPath: Gets the full path for a relative path, and optionally resolves network drives to UNC notation.
## 								Changed functions:
##									- Enter-BLExecutionAsTask: now creates a local copy of the installation source for the task if the source is on a network share.
##									- Get-BLShortcut, Get-BLSCCMManagementPoint, Get-BLADUser, New-BLShortcut: added FinalReleaseComObject() of the Com object used.
## 17.03.2016	M. Richardt		Added functions:
##									- Get-BLAdsiObject
##									- Get-BLLocalUser
##									- Get-BLRandomString
##									- New-BLLocalUser
##									- Remove-BLLocalUser
##									- Remove-BLUserProfile
##									- Set-BLLocalUser
## 								Changed functions:
##									- Enter-BLExecutionAsTask: now supports new switch AutoCreateTemporaryUser to install with a temporary account instead of an specified account.
## 05.04.2016   H.Baum          Set-BLEnvironmentVariable Set-BLEnvironmentPATH  geändert und in Export aufgenommen (für EVSPR)
## 25.04.2016   H.Baum          Powershell 2.0 Kompatibilitaet
##
## endregion Version Management
##
## region Comment Based Help
## The following list shows which functions already have a comment based help, and which still require CBH to be added.
## Comment based help						Date		Author
## ------------------------------------------------------------------
##	Add-BLLocalAdminGroupMember
##  Add-BLLocalGroupMember					
##	ConvertTo-BLBool
##  Copy-BLArchiveContent					
##	Enter-BLExecutionAsTask					07.08.2013	M. Richardt
##	Exit-BLFunctions
##	Export-BLConfigDBConvertedTemplateFile		
##	Export-BLIniFile
##	Format-BLHashTable
##	Format-BLXML
##	Get-BLADDomainController
##	Get-BLConfigDBCfgList					09.01.2015	M. Richardt
##	Get-BLConfigDBConvertedTemplate
##	Get-BLConfigDBLocation					09.01.2015	M. Richardt
##	Get-BLConfigDBUAFile					09.01.2015	M. Richardt
##	Get-BLConfigDBVariables					07.08.2013	M. Richardt
##	Get-BLCredentials
##	Get-BLEnvironmentVariable
##	Get-BLIniHTContent
##	Get-BLIniHTSection
##	Get-BLIniHTSectionNames
##	Get-BLIniHTValue
##	Get-BLIniKey
##	Get-BLLocalGroupMembers
##	Get-BLLogFileName						
##	Get-BLPrimaryDNSSuffix
##	Get-BLRDSApplicationMode
##	Get-BLRegistryKeyX64
##	Get-BLSCCMManagementPoint
##	Get-BLUninstallInformation				02.07.2014	M. Richardt
##	Import-BLIniFile
##	Import-BLRegistryFile
##	Initialize-BLFunctions					07.08.2013	M. Richardt
##	Initialize-BLXACommands
##	Install-BLWindowsHotfix
##	Install-BLWindowsLanguagePack
##	Install-BLWindowsRoleOrFeature
##	Invoke-BLBatchFile
##	Invoke-BLCommand32Bit
##	Invoke-BLCommandTimeout
##	Invoke-BLPowershell
##	Invoke-BLSetupInno
##	Invoke-BLSetupInstallShield
##	Invoke-BLSetupInstallShieldPFTW
##	Invoke-BLSetupMsi
##	Invoke-BLSetupNSIS
##	Invoke-BLSetupOther
##	Invoke-BLSetupWise
##	New-BLRegistryKey
##	New-BLShortcut							05.08.2015	M. Richardt
##	Out-BLIniHT
##	Remove-BLIniCategory
##	Remove-BLIniHTKey
##	Remove-BLIniHTSection
##	Remove-BLIniKey
##	Remove-BLLocalGroupMember				01.04.2015	A. Horn				
##	Remove-BLScheduledTask
##	Remove-BLShortcut						05.08.2015	M. Richardt
##	Set-BLConfigDBLocation					09.01.2015	M. Richardt
##	Set-BLEnvironmentPATH					??.??.2013	?
##	Set-BLEnvironmentVariable				??.??.2013	?
##	Set-BLIniHTSection
##	Set-BLIniHTValue
##	Set-BLIniKey
##	Set-BLLogDebugMode
##	Set-BLLogLevel
##	Set-BLRDSExecuteMode
##	Set-BLRDSInstallMode
##	Set-BLScheduledTask
##	Set-BLServiceStartup
##	Split-BLConfigDBAccountVariable
##	Split-BLConfigDBElementList
##	Start-BLProcess
##	Test-BLElevation
##	Test-BLHyperVGuest
##	Update-BLLibraryScript
##	Write-BLConfigDBSettings				09.01.2015	M. Richardt
##	Write-BLEventLog
##	Write-BLLog
## endregion Comment Based Help
##									
## ---------------------------------------------------------------------------

## Log folder root
$RIS_Logfolder = Join-Path $Env:SystemDrive "RIS\Log"
## Log file to which a summary of all installations is added
$RIS_Summarizelog = Join-Path $RIS_Logfolder "RIS_Summarize.log"
## Local folder path in which the <ComputerName>.cfg file(s) will be stored with the CFG functions in SCCM_CoreFunctions
## $CFG_ConfigFolderLocal = Join-Path $Env:SYSTEMDRIVE "RIS\ConfigDB\"
$BL_CFGDB_VirtualFolderCfg = "ConfigDB/"		## Virtual folder from which the .cfg files will be retrieved over http 
$BL_CFGDB_VirtualFolderUA = "Unattend/"			## Virtual folder from which the Unattend.xml files will be retrieved over http
$BL_CFGDB_EmbeddedFilesFolder = Join-Path $Env:SYSTEMDRIVE "RIS\Files"	## Path in which to expand files embedded in the .cfg file.
$BL_CFGDB_ServiceName = "_cfgdb"				## Name of the SRV entry in DNS, including the leading underscore. In case of a DNS entry with port 445, this will be used as the share name as well.
$BL_CFGDB_ENV_Location = "ATOS_CFGDB_LOCATION"	## Machine environment variable to override the default SCCM ManagementPoint
$BL_CFGDB_ENV_Setup = "ATOS_CFGDB_SETUP"		## RESERVED FOR TSINSTALLER: Machine environment variable to override the default SCCM ManagementPoint
$BL_CFGDB_LocationCache = "" | Select-Object Location, Expires
## Virtual folder from where to retrieve the <ComputerName>.cfg, including leading and trailing slashes; this variable will be exported (mainly for use in the SCCM installation)
$CFG_ConfigVirtualFolder = "/ConfigDB/"		## DO NOT USE ANYMORE - Legacy!

$BL_CFGDB_TYPE_Password = "Password"					## Name of the password type in the new .cfg format.

$SevenZip = "C:\RIS\Tools\7z.exe"

## Definition of all allowed log types; this is to prevent typos like "eror" to show up in white (default) instead of red.
$BL_LOG_AllowedLogTypes = @(
	"Debug",
	"Information",
	"Warning",
	"MinorError",
	"Error",
	"MajorError",
	"CriticalError",
	"UnexpectedError"
)
$BL_LOG_NoLogList = @(
	"Debug"
)
$BL_LOG_DebugMode = $False

## Execution As Task
$BL_EAT_Name = "BaseLibrary-ExecutionAsTask"
$BL_EAT_RegKey = "HKLM:\SOFTWARE\Atos\$BL_EAT_Name"
$BL_EAT_LogPostfix = "-TASK"
$BL_EAT_TempInstallAccount = "ASA_EAT_TmpInstall"

## Exported; additional properties of the PS host; will be set during import right before Export-ModuleMember, because it uses BL functions.
$BL_PSHost = "" | Select SupportsTranscription, SupportsWindowTitle, SupportsWriteHost

$Local:BLScriptFullName = & {$MyInvocation.ScriptName}
$Local:BLScriptName = [string]$(Split-Path $Local:BLScriptFullName -Leaf)
$Local:BLScriptPath = [string]$(Split-Path $Local:BLScriptFullName)

## Reference: Win32_LogicalDisk class, http://msdn.microsoft.com/en-us/library/windows/desktop/aa394173(v=vs.85).aspx
$CIM_LD_Access = @{
	"Unknown" =		[uint16]0
	"Readable" =	[uint16]1
	"Writable" =	[uint16]2
	"Read_Write" =	[uint16]3
	"Write_Once" =	[uint16]4
}
$CIM_LD_DriveType = @{
	"Unknown" =				[uint32]0
	"No_Root_Directory" =	[uint32]1
	"Removable_Disk" =		[uint32]2
	"Local_Disk" =			[uint32]3
	"Network_Drive" =		[uint32]4
	"Compact_Disc" =		[uint32]5
	"RAM_Disk" =			[uint32]6
}

$BL_INTERNET_URLZONE = @{
	"Invalid" =			-1
	"LocalMachine" =	0
	"Intranet" =		1
	"Trusted" =			2
	"Internet" =		3
	"Restricted" =		4
}

## ====================================================================================================
## Exported Variables for general use
## ====================================================================================================
## Environment.SpecialFolder Enumeration
## http://msdn.microsoft.com/en-us/library/system.environment.specialfolder(v=vs.110).aspx
## Use in Get-BLSpecialFolder; you can use tab autocompletion with $BL_SpecialFolder:: to find the folder you're interested in.
$BL_SpecialFolder = [Environment+SpecialFolder]

$BL_OSVersion = (Get-WmiObject Win32_OperatingSystem).Version

## ====================================================================================================
## ====================================================================================================
## Functions are grouped by purpose, then sorted by name
## ====================================================================================================
## ====================================================================================================

Function Initialize-BLCustomTypes() {
## Initializes all custom types required for the BaseLibrary.
## If you add new types, please assign a here-string with the code to a variable starting with "CSHARP_BL",
## and define a "## region ..." and "## endregion ..." around it (Notepad++ can't collapse Here-Strings (yet)).
## All types defined like this will be added automatically.
## If your type references additional assemblies, add a comment with the required arguments; example:
## // -ReferencedAssemblies System.Windows.Forms, "Foo.Bar"

## region CSHARP_BLAccountRights
$CSHARP_BLAccountRights = @'
// C# based on "UserRights PowerShell Module", https://gallery.technet.microsoft.com/scriptcenter/UserRights-PowerShell-1ff45589
// Changes by Manuel Richardt, March 2015:
// 		- Usage without additional DLLs
//		- Combination into a single class "BLAccountRights"
//		- Added missing privileges
//		- Fixed potential memory leak where the buffer allocated by ConvertSidToStringSid/ConvertStringSidToSid wasn't released.
// See
//		"Security Management Functions", https://msdn.microsoft.com/en-us/library/windows/desktop/ms721849(v=vs.85).aspx
//		"Authorization Constants", https://msdn.microsoft.com/en-us/library/windows/desktop/aa375728(v=vs.85).aspx
	using System;
	using System.Collections.Generic;
	using System.ComponentModel;
	using System.Runtime.InteropServices;
	using System.Security.Principal;
	using System.Text;

	public class BLAccountRights
	{
		[StructLayout(LayoutKind.Sequential)]
		private struct LSA_UNICODE_STRING
		{
			public UInt16 Length;
			public UInt16 MaximumLength;
			[MarshalAs(UnmanagedType.LPWStr)]
			public string Buffer;
		}

		private struct LSA_ENUMERATION_INFORMATION
		{
			public IntPtr Sid;
		}

		[StructLayout(LayoutKind.Sequential)]
		private struct LSA_OBJECT_ATTRIBUTES
		{
			public UInt32 Length;
			public IntPtr RootDirectory;
			public UInt32 Attributes;
			public LSA_UNICODE_STRING ObjectName;
			public IntPtr SecurityDescriptor;
			public IntPtr SecurityQualityOfService;
		}

		[Flags]
		private enum LsaAccessPolicy : uint
		{
			POLICY_VIEW_LOCAL_INFORMATION =		0x00000001,
			POLICY_VIEW_AUDIT_INFORMATION =		0x00000002,
			POLICY_GET_PRIVATE_INFORMATION =	0x00000004,
			POLICY_TRUST_ADMIN =				0x00000008,
			POLICY_CREATE_ACCOUNT =				0x00000010,
			POLICY_CREATE_SECRET =				0x00000020,
			POLICY_CREATE_PRIVILEGE =			0x00000040,
			POLICY_SET_DEFAULT_QUOTA_LIMITS =	0x00000080,
			POLICY_SET_AUDIT_REQUIREMENTS =		0x00000100,
			POLICY_AUDIT_LOG_ADMIN =			0x00000200,
			POLICY_SERVER_ADMIN =				0x00000400,
			POLICY_LOOKUP_NAMES =				0x00000800,
			POLICY_NOTIFICATION =				0x00001000
		}

		private const UInt32 STATUS_SUCCESS = 0;

		[DllImport("advapi32.dll", EntryPoint = "ConvertSidToStringSid", SetLastError = true, CharSet = CharSet.Auto, CallingConvention = CallingConvention.Winapi)]
		private static extern bool ConvertSidToStringSid(
			IntPtr lpSid,
			out IntPtr lpStringSid);

		[DllImport("advapi32.dll", EntryPoint = "ConvertStringSidToSid", SetLastError = true, CharSet = CharSet.Auto, CallingConvention = CallingConvention.Winapi)]
		private static extern bool ConvertStringSidToSid(
			string lpStringSid,
			ref IntPtr lpSid);

		[DllImport("kernel32.dll", EntryPoint = "LocalFree")]
		private static extern int LocalFree(IntPtr pMem);

		[DllImport("advapi32.dll", EntryPoint = "LsaAddAccountRights", SetLastError = true, CharSet = CharSet.Auto)]
		private static extern UInt32 LsaAddAccountRights(IntPtr PolicyHandle, IntPtr AccountSid, LSA_UNICODE_STRING[] UserRights, int CountOfRights);

		[DllImport("advapi32.dll", EntryPoint = "LsaClose", SetLastError = true, CharSet = CharSet.Auto, CallingConvention = CallingConvention.StdCall)]
		private extern static UInt32 LsaClose(IntPtr PolicyHandle);

		[DllImport("advapi32.dll", EntryPoint = "LsaEnumerateAccountRights", SetLastError = true, CharSet = CharSet.Auto)]
		private static extern UInt32 LsaEnumerateAccountRights(IntPtr PolicyHandle, IntPtr AccountSid, out IntPtr UserRights, out int CountOfRights);

		[DllImport("advapi32.dll", EntryPoint = "LsaEnumerateAccountsWithUserRight", SetLastError = true, CharSet = CharSet.Auto, CallingConvention = CallingConvention.StdCall)]
		private extern static UInt32 LsaEnumerateAccountsWithUserRight(
			IntPtr PolicyHandle, ref LSA_UNICODE_STRING UserRights,
			out IntPtr EnumerationBuffer,
			out UInt32 CountReturned);

		[DllImport("advapi32.dll", EntryPoint = "LsaFreeMemory", SetLastError = true, CharSet = CharSet.Auto, CallingConvention = CallingConvention.StdCall)]
		private extern static UInt32 LsaFreeMemory(IntPtr Buffer);

		[DllImport("advapi32.dll", EntryPoint = "LsaNtStatusToWinError", SetLastError = true, CharSet = CharSet.Auto, CallingConvention = CallingConvention.StdCall)]
		private extern static UInt32 LsaNtStatusToWinError(UInt32 Status);
		
		[DllImport("advapi32.dll", EntryPoint = "LsaOpenPolicy", SetLastError = true, CharSet = CharSet.Auto, CallingConvention = CallingConvention.StdCall)]
		private extern static UInt32 LsaOpenPolicy(ref LSA_UNICODE_STRING SystemName, ref LSA_OBJECT_ATTRIBUTES ObjectAttributes,
		UInt32 DesiredAcces, out IntPtr PolicyHandle);

		[DllImport("advapi32.dll", EntryPoint = "LsaRemoveAccountRights", SetLastError = true, CharSet = CharSet.Auto)]
		private static extern UInt32 LsaRemoveAccountRights(IntPtr PolicyHandle, IntPtr AccountSid, bool AllRights,LSA_UNICODE_STRING[] UserRights, int CountOfRights);

		public enum Privileges
		{
			SeAssignPrimaryTokenPrivilege,
			SeAuditPrivilege,
			SeBackupPrivilege,
			SeBatchLogonRight,
			SeChangeNotifyPrivilege,
			SeCreateGlobalPrivilege,
			SeCreatePagefilePrivilege,
			SeCreatePermanentPrivilege,
			SeCreateSymbolicLinkPrivilege,
			SeCreateTokenPrivilege,
			SeDebugPrivilege,
			SeDenyBatchLogonRight,
			SeDenyInteractiveLogonRight,
			SeDenyNetworkLogonRight,
			SeDenyRemoteInteractiveLogonRight,	
			SeDenyServiceLogonRight,
			SeEnableDelegationPrivilege,
			SeImpersonatePrivilege,
			SeIncreaseBasePriorityPrivilege,
			SeIncreaseQuotaPrivilege,
			SeIncreaseWorkingSetPrivilege,
			SeInteractiveLogonRight,
			SeLoadDriverPrivilege,
			SeLockMemoryPrivilege,
			SeMachineAccountPrivilege,
			SeManageVolumePrivilege,
			SeNetworkLogonRight,
			SeProfileSingleProcessPrivilege,
			SeRelabelPrivilege,
			SeRemoteInteractiveLogonRight,
			SeRemoteShutdownPrivilege,
			SeRestorePrivilege,
			SeSecurityPrivilege,
			SeServiceLogonRight,
			SeShutdownPrivilege,
			SeSyncAgentPrivilege,
			SeSystemEnvironmentPrivilege,
			SeSystemProfilePrivilege,
			SeSystemtimePrivilege,
			SeTakeOwnershipPrivilege,
			SeTcbPrivilege,
			SeTimeZonePrivilege,
			SeTrustedCredManAccessPrivilege,
			//SeUnsolicitedInputPrivilege		// OBSOLETE!
			SeUndockPrivilege
		}

		public static void AddAccountRights(SecurityIdentifier si, Privileges privilege, string computerName)
		{
			UInt32 ntStatus;

			LSA_UNICODE_STRING computer = new LSA_UNICODE_STRING();
			computer.Buffer = computerName;
			computer.Length = (UInt16)(computer.Buffer.Length * UnicodeEncoding.CharSize);
			computer.MaximumLength = (UInt16)((computer.Buffer.Length + 1) * UnicodeEncoding.CharSize);

			LSA_OBJECT_ATTRIBUTES ObjectAttributes = new LSA_OBJECT_ATTRIBUTES();
			IntPtr policyHandle;
			ntStatus = LsaOpenPolicy(ref computer, ref ObjectAttributes, (uint)(LsaAccessPolicy.POLICY_LOOKUP_NAMES | LsaAccessPolicy.POLICY_CREATE_ACCOUNT), out policyHandle);
			if (ntStatus != STATUS_SUCCESS)
			{
				ntStatus = LsaNtStatusToWinError(ntStatus);
				throw new Win32Exception((int)ntStatus);
			}

			LSA_UNICODE_STRING[] userRights = new LSA_UNICODE_STRING[1];
			userRights[0] = new LSA_UNICODE_STRING();
			userRights[0].Buffer = privilege.ToString();
			userRights[0].Length = (UInt16)(userRights[0].Buffer.Length * UnicodeEncoding.CharSize);
			userRights[0].MaximumLength = (UInt16)((userRights[0].Buffer.Length + 1) * UnicodeEncoding.CharSize);

			IntPtr unsafeBinarySid = IntPtr.Zero;
			ConvertStringSidToSid(si.Value, ref unsafeBinarySid);		// The out buffer allocated MUST be released with LocalFree()!
			ntStatus = LsaAddAccountRights(policyHandle, unsafeBinarySid, userRights, 1);
			LocalFree(unsafeBinarySid);
			if (ntStatus != STATUS_SUCCESS)
			{
				LsaClose(policyHandle);
				throw new Win32Exception((int)ntStatus);
			}

			ntStatus = LsaClose(policyHandle);
			if (ntStatus != STATUS_SUCCESS)
			{
				ntStatus = LsaNtStatusToWinError(ntStatus);
				throw new Win32Exception((int)ntStatus);
			}
		}

		public static string[] GetAccountRights(SecurityIdentifier si, string computerName)
		{
			UInt32 ntStatus;

			LSA_UNICODE_STRING computer = new LSA_UNICODE_STRING();
			computer.Buffer = computerName;
			computer.Length = (UInt16)(computer.Buffer.Length * UnicodeEncoding.CharSize);
			computer.MaximumLength = (UInt16)((computer.Buffer.Length + 1) * UnicodeEncoding.CharSize);

			LSA_OBJECT_ATTRIBUTES ObjectAttributes = new LSA_OBJECT_ATTRIBUTES();
			IntPtr policyHandle;
			ntStatus = LsaOpenPolicy(ref computer, ref ObjectAttributes, (uint)(LsaAccessPolicy.POLICY_LOOKUP_NAMES | LsaAccessPolicy.POLICY_VIEW_LOCAL_INFORMATION), out policyHandle);
			if (ntStatus != STATUS_SUCCESS)
			{
				ntStatus = LsaNtStatusToWinError(ntStatus);
				throw new Win32Exception((int)ntStatus);
			}

			IntPtr unsafeBinarySid = IntPtr.Zero;
			ConvertStringSidToSid(si.Value, ref unsafeBinarySid);		// The out buffer allocated MUST be released with LocalFree()!
			int countOfRights = 0;
			IntPtr userRightsPtr = IntPtr.Zero;
			ntStatus = LsaEnumerateAccountRights(policyHandle, unsafeBinarySid, out userRightsPtr, out countOfRights);
			LocalFree(unsafeBinarySid);
			
			if (ntStatus != STATUS_SUCCESS)
			{
				LsaClose(policyHandle);
				ntStatus = LsaNtStatusToWinError(ntStatus);
				if (ntStatus == 2)
				{
					return new string[0];
				}

				throw new Win32Exception((int)ntStatus);
			}

			LSA_UNICODE_STRING userRight;
			string[] userRights = new string[countOfRights];

			for (int i = 0; i < countOfRights; i++)
			{
				userRight = (LSA_UNICODE_STRING)Marshal.PtrToStructure(userRightsPtr, typeof(LSA_UNICODE_STRING));
				userRights[i] = userRight.Buffer;

				userRightsPtr = (IntPtr)(userRightsPtr.ToInt64() + Marshal.SizeOf(userRight));
			}

			ntStatus = LsaClose(policyHandle);
			if (ntStatus != STATUS_SUCCESS)
			{
				ntStatus = LsaNtStatusToWinError(ntStatus);
				throw new Win32Exception((int)ntStatus);
			}

			return userRights;
		}

		public static string[] GetAccountsWithRight(Privileges privilege, string computerName)
		{
			UInt32 ntStatus;

			LSA_UNICODE_STRING computer = new LSA_UNICODE_STRING();
			computer.Buffer = computerName;
			computer.Length = (UInt16)(computer.Buffer.Length * UnicodeEncoding.CharSize);
			computer.MaximumLength = (UInt16)((computer.Buffer.Length + 1) * UnicodeEncoding.CharSize);

			LSA_OBJECT_ATTRIBUTES ObjectAttributes = new LSA_OBJECT_ATTRIBUTES();
			IntPtr policyHandle;
			ntStatus = LsaOpenPolicy(ref computer, ref ObjectAttributes, (uint)(LsaAccessPolicy.POLICY_LOOKUP_NAMES | LsaAccessPolicy.POLICY_VIEW_LOCAL_INFORMATION), out policyHandle);
			if (ntStatus != STATUS_SUCCESS)
			{
				ntStatus = LsaNtStatusToWinError(ntStatus);
				throw new Win32Exception((int)ntStatus);
			}

			LSA_UNICODE_STRING Privilege = new LSA_UNICODE_STRING();
			Privilege.Buffer = privilege.ToString();
			Privilege.Length = (UInt16)(Privilege.Buffer.Length * UnicodeEncoding.CharSize);
			Privilege.MaximumLength = (UInt16)((Privilege.Buffer.Length + 1) * UnicodeEncoding.CharSize);

			IntPtr enumerationBuffer;
			UInt32 countReturned;
			ntStatus = LsaEnumerateAccountsWithUserRight(policyHandle, ref Privilege, out enumerationBuffer, out countReturned);
			if (ntStatus != STATUS_SUCCESS)
			{
				LsaClose(policyHandle);
				ntStatus = LsaNtStatusToWinError(ntStatus);
				if (ntStatus == 259)
				{
					return new string[0];
				}

				throw new Win32Exception((int)ntStatus);
			}
			LSA_ENUMERATION_INFORMATION sid = new LSA_ENUMERATION_INFORMATION();
			sid.Sid = IntPtr.Zero;

			UInt32 StructSize = (UInt32)Marshal.SizeOf(typeof(LSA_ENUMERATION_INFORMATION));
			IntPtr enumerationItem;

			List<string> stringSids = new List<string>();
			for (int i = 0; i < countReturned; i++)
			{
				enumerationItem = (IntPtr)(enumerationBuffer.ToInt64() + (StructSize * i));
				sid = (LSA_ENUMERATION_INFORMATION)(Marshal.PtrToStructure(enumerationItem, typeof(LSA_ENUMERATION_INFORMATION)));

				IntPtr unsafeStringSid = IntPtr.Zero;
				ConvertSidToStringSid(sid.Sid, out unsafeStringSid);		// The out buffer allocated MUST be released with LocalFree()!

				string stringSid = Marshal.PtrToStringAuto(unsafeStringSid);
				LocalFree(unsafeStringSid);
				
				stringSids.Add(stringSid);
			}

			ntStatus = LsaClose(policyHandle);
			if (ntStatus != STATUS_SUCCESS)
			{
				ntStatus = LsaNtStatusToWinError(ntStatus);
				throw new Win32Exception((int)ntStatus);
			}

			//LsaFreeMemory(enumerationBuffer);
			return stringSids.ToArray();
		}

		public static void RemoveAccountRights(SecurityIdentifier si, Privileges privilege, string computerName)
		{
			UInt32 ntStatus;

			LSA_UNICODE_STRING computer = new LSA_UNICODE_STRING();
			computer.Buffer = computerName;
			computer.Length = (UInt16)(computer.Buffer.Length * UnicodeEncoding.CharSize);
			computer.MaximumLength = (UInt16)((computer.Buffer.Length + 1) * UnicodeEncoding.CharSize);

			LSA_OBJECT_ATTRIBUTES ObjectAttributes = new LSA_OBJECT_ATTRIBUTES();
			IntPtr policyHandle;
			ntStatus = LsaOpenPolicy(ref computer, ref ObjectAttributes, (uint)(LsaAccessPolicy.POLICY_LOOKUP_NAMES | LsaAccessPolicy.POLICY_CREATE_ACCOUNT), out policyHandle);
			if (ntStatus != STATUS_SUCCESS)
			{
				ntStatus = LsaNtStatusToWinError(ntStatus);
				throw new Win32Exception((int)ntStatus);
			}

			LSA_UNICODE_STRING[] userRights = new LSA_UNICODE_STRING[1];
			userRights[0] = new LSA_UNICODE_STRING();
			userRights[0].Buffer = privilege.ToString();
			userRights[0].Length = (UInt16)(userRights[0].Buffer.Length * UnicodeEncoding.CharSize);
			userRights[0].MaximumLength = (UInt16)((userRights[0].Buffer.Length + 1) * UnicodeEncoding.CharSize);

			IntPtr unsafeBinarySid = IntPtr.Zero;
			ConvertStringSidToSid(si.Value, ref unsafeBinarySid);		// The out buffer allocated MUST be released with LocalFree()!
			ntStatus = LsaRemoveAccountRights(policyHandle, unsafeBinarySid, false, userRights, 1);
			LocalFree(unsafeBinarySid);
			
			if (ntStatus != STATUS_SUCCESS)
			{
				LsaClose(policyHandle);
				throw new Win32Exception((int)ntStatus);
			}

			ntStatus = LsaClose(policyHandle);
			if (ntStatus != STATUS_SUCCESS)
			{
				ntStatus = LsaNtStatusToWinError(ntStatus);
				throw new Win32Exception((int)ntStatus);
			}
		}
	}

'@
## endregion CSHARP_BLAccountRights

## region CSHARP_BLDnsSrvQuery
$CSHARP_BLDnsSrvQuery = @'
// C# based on "Lookup SRV record in C#", http://randronov.blogspot.de/2013/03/lookup-srv-record-in-c.html
// Extended by Manuel Richardt, November 2014
	using System;
	using System.Collections.Generic;
	using System.Runtime.InteropServices;
	using System.ComponentModel;

	public class BLDnsSrvRecord
	{
		public string	Name = "";
		public int		Ttl = 0;
		public ushort	Priority = 0;
		public ushort	Weight = 0;
		public ushort	Port = 0;
		public string	Exception = "";
	}
	
	public class BLDnsSrvQuery
	{

		[DllImport("dnsapi", EntryPoint = "DnsQuery_W", CharSet = CharSet.Unicode, SetLastError = true, ExactSpelling = true)]
		private static extern int DnsQuery([MarshalAs(UnmanagedType.VBByRefStr)]ref string pszName, QueryTypes wType, QueryOptions options, int aipServers, ref IntPtr ppQueryResults, int pReserved);

		[DllImport("dnsapi", CharSet = CharSet.Auto, SetLastError = true)]
		private static extern void DnsRecordListFree(IntPtr pRecordList, int FreeType);
  
		private enum QueryOptions
		{
			DNS_QUERY_ACCEPT_TRUNCATED_RESPONSE = 1,
			DNS_QUERY_BYPASS_CACHE = 8,
			DNS_QUERY_DONT_RESET_TTL_VALUES = 0x100000,
			DNS_QUERY_NO_HOSTS_FILE = 0x40,
			DNS_QUERY_NO_LOCAL_NAME = 0x20,
			DNS_QUERY_NO_NETBT = 0x80,
			DNS_QUERY_NO_RECURSION = 4,
			DNS_QUERY_NO_WIRE_QUERY = 0x10,
			DNS_QUERY_RESERVED = -16777216,
			DNS_QUERY_RETURN_MESSAGE = 0x200,
			DNS_QUERY_STANDARD = 0,
			DNS_QUERY_TREAT_AS_FQDN = 0x1000,
			DNS_QUERY_USE_TCP_ONLY = 2,
			DNS_QUERY_WIRE_ONLY = 0x100
		}

		private enum QueryTypes
		{
			DNS_TYPE_A = 0x0001,
			DNS_TYPE_MX = 0x000f,
			DNS_TYPE_SRV = 0x0021
		}

		[StructLayout(LayoutKind.Sequential)]
		private struct SRVRecord
		{
			public IntPtr pNext;
			public string pName;
			public short wType;
			public ushort wDataLength;
			public int flags;
			public int dwTtl;
			public int dwReserved;
			public IntPtr pNameTarget;
			public ushort wPriority;
			public ushort wWeight;
			public ushort wPort;
			public short Pad;
		}
		
		public static List<BLDnsSrvRecord> GetSRVRecords(string needle)
		{
			List<BLDnsSrvRecord> resultList = new List<BLDnsSrvRecord>();
			IntPtr ptr1 = IntPtr.Zero;
			IntPtr ptr2 = IntPtr.Zero;
			SRVRecord recSRV;
			try
			{

				int num1 = DnsQuery(ref needle, QueryTypes.DNS_TYPE_SRV, QueryOptions.DNS_QUERY_BYPASS_CACHE, 0, ref ptr1, 0);
				if (num1 != 0)
				{
					throw new Win32Exception(num1);
				}
				for (ptr2 = ptr1; !ptr2.Equals(IntPtr.Zero); ptr2 = recSRV.pNext)
				{
					BLDnsSrvRecord Record = new BLDnsSrvRecord();
					recSRV = (SRVRecord)Marshal.PtrToStructure(ptr2, typeof(SRVRecord));
					if (recSRV.wType == (short)QueryTypes.DNS_TYPE_SRV)
					{
						Record.Name = Marshal.PtrToStringAuto(recSRV.pNameTarget);
						Record.Port = recSRV.wPort;
						Record.Priority = recSRV.wPriority;
						Record.Ttl = recSRV.dwTtl;
						Record.Weight = recSRV.wWeight;
						resultList.Add(Record);
					}
				}
			}
			catch(Exception ex)
			{
				BLDnsSrvRecord Record = new BLDnsSrvRecord();
				Record.Exception = ex.Message;
				resultList = new List<BLDnsSrvRecord>();
				resultList.Add(Record);
			}
			finally
			{
				BLDnsSrvQuery.DnsRecordListFree(ptr1, 0);
			}
			return resultList;
		}
		
	}
'@
## endregion CSHARP_BLDnsSrvQuery

## region CSHARP_BLInternetSecurityManager
$CSHARP_BLInternetSecurityManager = @'
// C# based on ´IE Security Zones´, http://blogs.msdn.com/b/ie/archive/2005/01/26/ie-security-zones.aspx
// ´Adding Sites to the Enhanced Security Configuration Zones´, http://msdn.microsoft.com/en-us/library/ms537181(VS.85).aspx
// ´Adding and removing websites to/from security zones programmatically (C#)´, http://blogs.msdn.com/b/ddietric/archive/2009/06/24/adding-and-removing-websites-from-security-zones-programmatically-c.aspx
	using System;
	using System.Runtime.InteropServices;
	using System.Runtime.InteropServices.ComTypes;

	[ComImport, GuidAttribute("79EAC9EE-BAF9-11CE-8C82-00AA004BA90B"),
	InterfaceTypeAttribute(ComInterfaceType.InterfaceIsIUnknown)]
	public interface IInternetSecurityManager
	{
		[return: MarshalAs(UnmanagedType.I4)][PreserveSig]
		int SetSecuritySite([In] IntPtr pSite);

		[return: MarshalAs(UnmanagedType.I4)][PreserveSig]
		int GetSecuritySite([Out] IntPtr pSite);

		[return: MarshalAs(UnmanagedType.I4)][PreserveSig]
		int MapUrlToZone([In,MarshalAs(UnmanagedType.LPWStr)] string pwszUrl, out UInt32 pdwZone, UInt32 dwFlags);

		[return: MarshalAs(UnmanagedType.I4)][PreserveSig]
		int GetSecurityId([MarshalAs(UnmanagedType.LPWStr)] string pwszUrl, [MarshalAs(UnmanagedType.LPArray)] byte[] pbSecurityId, ref UInt32  pcbSecurityId, uint dwReserved);

		[return: MarshalAs(UnmanagedType.I4)][PreserveSig]
		int ProcessUrlAction([In,MarshalAs(UnmanagedType.LPWStr)] string pwszUrl, UInt32 dwAction, out byte pPolicy, UInt32 cbPolicy, byte pContext, UInt32 cbContext, UInt32 dwFlags, UInt32 dwReserved);

		[return: MarshalAs(UnmanagedType.I4)][PreserveSig]
		int QueryCustomPolicy([In,MarshalAs(UnmanagedType.LPWStr)] string pwszUrl, ref Guid guidKey, ref byte ppPolicy, ref UInt32 pcbPolicy, ref byte pContext, UInt32 cbContext, UInt32 dwReserved);

		[return: MarshalAs(UnmanagedType.I4)][PreserveSig]
		int SetZoneMapping(UInt32 dwZone, [In,MarshalAs(UnmanagedType.LPWStr)] string lpszPattern, UInt32 dwFlags);

		[return: MarshalAs(UnmanagedType.I4)][PreserveSig]
		int GetZoneMappings(UInt32 dwZone, out IEnumString ppenumString, UInt32 dwFlags);
	}

	public class BLInternetSecurityManager
	{
		// constants from urlmon.h; see http://msdn.microsoft.com/en-us/library/ie/ms537175(v=vs.85).aspx
		public const UInt32 URLZONE_LOCAL_MACHINE =		0;
		public const UInt32 URLZONE_INTRANET =			URLZONE_LOCAL_MACHINE + 1;
		public const UInt32 URLZONE_TRUSTED =			URLZONE_INTRANET + 1;
		public const UInt32 URLZONE_INTERNET =			URLZONE_TRUSTED + 1;
		public const UInt32 URLZONE_UNTRUSTED =			URLZONE_INTERNET + 1;
		public const UInt32 URLZONE_ESC_FLAG =			0x100;
		public const UInt32 URLZONE_PREDEFINED_MAX =	999;
		public const UInt32 URLZONE_USER_MIN =			1000;
		public const UInt32 URLZONE_USER_MAX =			10000;
		
		public const UInt32 SZM_CREATE =				0x0;
		public const UInt32 SZM_DELETE =				0x1;

		// MapUrlToZone Flags, http://msdn.microsoft.com/en-us/library/ie/dd759042(v=vs.85).aspx
		public const UInt32 MUTZ_NOSAVEDFILECHECK =			0x00000001;	// Indicates that the file should not be checked for the Mark Of The Web (see http://msdn.microsoft.com/en-us/library/ie/ms537628(v=vs.85).aspx).
		public const UInt32 MUTZ_ISFILE =					0x00000002;  // Internet Explorer 6 for Windows XP SP2 and later. Indicates that the URL is a file and "file:" does not need to be prepended.
		public const UInt32 MUTZ_ACCEPT_WILDCARD_SCHEME =	0x00000080;  // Internet Explorer 6 for Windows XP SP2 and later. Indicates that wildcard characters can be used.
		public const UInt32 MUTZ_ENFORCERESTRICTED =		0x00000100;  // Indicates that the URL should be treated as if it were in the Restricted sites zone.
		public const UInt32 MUTZ_RESERVED =					0x00000200;  // Internet Explorer 7. Reserved. Do not use.
		public const UInt32 MUTZ_REQUIRESAVEDFILECHECK =	0x00000400;  // Internet Explorer 6 for Windows XP SP2 and later. Always evaluate the "saved from url" (MOTW) information in the file. By setting this flag, you override the FEATURE_UNC_SAVEDFILECHECK feature control setting.
		public const UInt32 MUTZ_DONT_UNESCAPE =			0x00000800;  // Internet Explorer 6 for Windows XP SP2 and later. Do not unescape the URL.
		public const UInt32 MUTZ_DONT_USE_CACHE =			0x00001000;  // Internet Explorer 7. Do not check the local Internet cache.
		public const UInt32 MUTZ_FORCE_INTRANET_FLAGS =		0x00002000;  // Internet Explorer 7. Force the intranet flags to be active. Implies MUTZ_DONT_USE_CACHE.
		public const UInt32 MUTZ_IGNORE_ZONE_MAPPINGS =		0x00004000;  // Internet Explorer 7. Ignore all zone mappings that the user or administrator has set in the registry, including those set by ESC. For example, a site in the Trusted Sites zone would appear to be in the Internet zone (or whatever zone it was in originally). Implies MUTZ_DONT_USE_CACHE.
	
		public static Guid CLSID_InternetSecurityManager = new Guid("7b8a2d94-0ac9-11d1-896c-00c04fb6bfc4");
		public static Guid IID_IInternetSecurityManager = new Guid("79eac9ee-baf9-11ce-8c82-00aa004ba90b");

		public static string[] GetZoneMappings(UInt32 dwZone)
		{
			IEnumString ppenumString;
			IInternetSecurityManager _ism;   // IInternetSecurityManager interface of SecurityManager COM object
			object _securityManager;
 			Type t = Type.GetTypeFromCLSID(CLSID_InternetSecurityManager);
			_securityManager = Activator.CreateInstance(t);
			_ism = (IInternetSecurityManager) _securityManager;
			int result = _ism.GetZoneMappings(dwZone, out ppenumString, 0);
			Marshal.ReleaseComObject( _securityManager );
			
			System.Collections.Generic.List<string> output = new System.Collections.Generic.List<string>();
			string[] temp = new string[1];
			IntPtr fetched = IntPtr.Zero;
			while (ppenumString.Next(1, temp, fetched) == 0)
			{
				output.Add(temp[0]);
			}
				
			return output.ToArray();
		}

		public static Int32 MapUrlToZone([In,MarshalAs(UnmanagedType.LPWStr)] string pwszUrl, UInt32 dwFlags)
		{
			IInternetSecurityManager _ism;   // IInternetSecurityManager interface of SecurityManager COM object
			object _securityManager;
 			Type t = Type.GetTypeFromCLSID(CLSID_InternetSecurityManager);
			_securityManager = Activator.CreateInstance(t);
			_ism = (IInternetSecurityManager) _securityManager;
			UInt32 pdwZone;
			int result = _ism.MapUrlToZone(pwszUrl, out pdwZone, dwFlags);
			Marshal.ReleaseComObject( _securityManager );
			if (result == 0)
			{
				return (Int32)pdwZone;
			}
			else
			{
				Console.WriteLine("Error: {0}", result);
				return -1;
			}
		}
		
		public static Int32 SetZoneMapping(UInt32 dwZone, [In,MarshalAs(UnmanagedType.LPWStr)] string lpszPattern, UInt32 dwFlags, bool bForce)
		{
			IInternetSecurityManager _ism;   // IInternetSecurityManager interface of SecurityManager COM object
			object _securityManager;
			int result;
 			Type t = Type.GetTypeFromCLSID(CLSID_InternetSecurityManager);
			_securityManager = Activator.CreateInstance(t);
			_ism = (IInternetSecurityManager) _securityManager;
			result = _ism.SetZoneMapping(dwZone, lpszPattern, dwFlags);
			if (result == -2147024816)	// Entry exists already, but maybe in another zone
			{
				string[] arrZoneMappings = GetZoneMappings(dwZone);
				int pos = Array.IndexOf(arrZoneMappings, lpszPattern);
				if (pos > -1)	// Entry found in the same zone; adjusting result
				{
					result = 0;
				}
				else
				{
					if (bForce == true)		// Entry found in another zone; remove the old entry and set the new one.
											// SetZoneMapping doesn´t seem to care about the zone when it deletes an existing site, so passing the "new" zone works.
					{
						result = _ism.SetZoneMapping(dwZone, lpszPattern, SZM_DELETE);
						result = _ism.SetZoneMapping(dwZone, lpszPattern, dwFlags);
					}
				}
			}
			Marshal.ReleaseComObject( _securityManager );
			return result;
		}
		
	}
'@
## endregion CSHARP_BLInternetSecurityManager

## region CSHARP_BLLookupAccount
$CSHARP_BLLookupAccount = @'
// Author: Manuel Richardt, March 2015
// Defines a class BLLookupAccount for account/SID lookup.
// See "Authorization Functions", https://msdn.microsoft.com/en-us/library/windows/desktop/aa375742(v=vs.85).aspx

	using System;
	using System.Collections.Generic;
	using System.ComponentModel;
	using System.Runtime.InteropServices;
	using System.Security.Principal;
	using System.Text;

	public class BLLookupAccount
	{
		
		[DllImport("advapi32.dll", EntryPoint = "LookupAccountName", CharSet = CharSet.Auto, SetLastError = true)]
		private static extern bool LookupAccountName(
			string lpSystemName, string lpAccountName,
			IntPtr lpSid,
			ref int cbsid,
			StringBuilder ReferencedDomainName, ref int cbReferencedDomainNameLength, ref int peUse);
		
		[DllImport("advapi32.dll", EntryPoint = "LookupAccountSid", CharSet = CharSet.Auto, SetLastError = true)]
		private static extern bool LookupAccountSid(
			string lpSystemName, IntPtr lpSid,
			StringBuilder name, ref int cbName,
			StringBuilder ReferencedDomainName, ref int cbReferencedDomainNameLength, ref int peUse);

		[DllImport("advapi32.dll", EntryPoint = "ConvertSidToStringSid", CharSet = CharSet.Auto, SetLastError = true)]
		private static extern bool ConvertSidToStringSid(
			IntPtr lpSid,
			out IntPtr lpStringSid);

		[DllImport("advapi32.dll", EntryPoint = "ConvertStringSidToSid", CharSet = CharSet.Auto, SetLastError = true)]
		private static extern bool ConvertStringSidToSid(
			string lpStringSid,
			out IntPtr lpSid);

		[DllImport("advapi32.dll", EntryPoint = "GetLengthSid", CharSet = CharSet.Auto, SetLastError = true)]
		private static extern int GetLengthSid(IntPtr lpSid);
	 
		[DllImport("kernel32.dll", EntryPoint = "GetLastError")]
		private static extern int GetLastError();
		
		[DllImport("advapi32.dll", EntryPoint = "IsValidSid")]
		private static extern bool IsValidSid(IntPtr lpSid);
		
		[DllImport("kernel32.dll", EntryPoint = "LocalFree")]
		private static extern int LocalFree(IntPtr pMem);
		
		public enum SID_NAME_USE		// SID_NAME_USE enumeration, https://msdn.microsoft.com/en-us/library/windows/desktop/aa379601(v=vs.85).aspx
		{
			User = 1,
			Group,
			Domain,
			Alias,
			WellKnownGroup,
			DeletedAccount,
			Invalid,
			Unknown,
			Computer
		}

		public class AccountInfo		// Used to return the information retrieved
		{
			public string	Name = "";
			public string	ComputerName = "";
			public string	Authority = "";
			public string	Sid = "";
			public string	SidType = "";
			public Int32	SidTypeNumeric = 0;
		}
		
		public static AccountInfo GetNameFromSid(string stringSid, string computerName)
		{
			int winError = 0;
			bool result = false;
			IntPtr unsafeBinarySid = IntPtr.Zero;
			
			result = ConvertStringSidToSid(stringSid, out unsafeBinarySid);		// The out buffer allocated MUST be released with LocalFree()!
			if (!result)
			{
				if (unsafeBinarySid != IntPtr.Zero)
				{
					LocalFree(unsafeBinarySid);
				}
				winError = GetLastError();
				throw(new Exception(winError.ToString() + ": " + new Win32Exception(winError).Message));
			}
			
			StringBuilder accountName = new StringBuilder();
			int accountNameSize = 0;
			StringBuilder domainName = new StringBuilder();
			int domainNameSize = 0;
			int accountType = 0;
			// First call with buffer sizes of 0; this returns the buffer sizes required for the SID and the domain name
			LookupAccountSid(computerName, unsafeBinarySid, accountName, ref accountNameSize, domainName, ref domainNameSize, ref accountType);
			winError = GetLastError();
			if (winError != 122)		// 122 is the expected error for this call: "The data area passed to a system call is too small"
			{
				LocalFree(unsafeBinarySid);
				throw(new Exception(winError.ToString() + ": " + new Win32Exception(winError).Message));
			}

			accountName = new StringBuilder(accountNameSize);
			domainName = new StringBuilder(domainNameSize);
			result = LookupAccountSid(computerName, unsafeBinarySid, accountName, ref accountNameSize, domainName, ref domainNameSize, ref accountType);
			LocalFree(unsafeBinarySid);
			if (!result)
			{
				winError = GetLastError();
				throw(new Exception(winError.ToString() + ": " + new Win32Exception(winError).Message));
			}
			
			AccountInfo info = new AccountInfo();
			string delim = (!String.IsNullOrEmpty(domainName.ToString()) && !String.IsNullOrEmpty(accountName.ToString())) ? "\\" : "";
			info.Name = domainName.ToString() + delim + accountName.ToString();
			info.ComputerName = (String.IsNullOrEmpty(computerName) || (computerName == ".")) ? System.Environment.MachineName : computerName;
			info.Authority = domainName.ToString();
			info.Sid = stringSid;
			info.SidType = ((SID_NAME_USE)accountType).ToString();
			info.SidTypeNumeric = accountType;
			
			return info;
		}
		
		public static AccountInfo GetSidFromName(string accountName, string computerName)
		{
			int winError = 0;
			bool result = false;
			IntPtr binarySid = IntPtr.Zero;
			int binarySidSize = 0;
			StringBuilder domainName = new StringBuilder();
			int domainNameSize = 0;
			int accountType = 0;
			// First call with buffer sizes of 0; this returns the buffer sizes required for the SID and the domain name
			LookupAccountName(computerName, accountName, binarySid, ref binarySidSize, domainName, ref domainNameSize, ref accountType);
			winError = GetLastError();
			if (winError != 122)		// 122 is the expected error for this call: "The data area passed to a system call is too small"
			{
				throw(new Exception(winError.ToString() + ": " + new Win32Exception(winError).Message));
			}
			
			binarySid = Marshal.AllocHGlobal(binarySidSize);
			domainName = new StringBuilder(domainNameSize);
			result = LookupAccountName(computerName, accountName, binarySid, ref binarySidSize, domainName, ref domainNameSize, ref accountType);
			if (!result)
			{
				winError = GetLastError();
				throw(new Exception(winError.ToString() + ": " + new Win32Exception(winError).Message));
			}
			
			IntPtr unsafeStringSid = IntPtr.Zero;
			result = ConvertSidToStringSid(binarySid, out unsafeStringSid);		// The out buffer allocated MUST be released with LocalFree()!
			if (!result)
			{
				if (unsafeStringSid != IntPtr.Zero)
				{
					LocalFree(unsafeStringSid);
				}
				winError = GetLastError();
				throw(new Exception(winError.ToString() + ": " + new Win32Exception(winError).Message));
			}

			string stringSid = Marshal.PtrToStringAuto(unsafeStringSid);
			LocalFree(unsafeStringSid);
			
			AccountInfo info = new AccountInfo();
			info.Name = accountName;
			info.ComputerName = (String.IsNullOrEmpty(computerName) || (computerName == ".")) ? System.Environment.MachineName : computerName;
			info.Authority = domainName.ToString();
			info.Sid = stringSid;
			info.SidType = ((SID_NAME_USE)accountType).ToString();
			info.SidTypeNumeric = accountType;
			
			return info;
		}
		
		public static bool TestSid(string stringSid)
		{
			bool result = false;
			IntPtr unsafeBinarySid = IntPtr.Zero;
			
			if (ConvertStringSidToSid(stringSid, out unsafeBinarySid))	// The out buffer allocated MUST be released with LocalFree()!
			{
				result = IsValidSid(unsafeBinarySid);
			}
			if (unsafeBinarySid != IntPtr.Zero)
			{
				LocalFree(unsafeBinarySid);
			}
			return result;
		}
	}
'@
## endregion CSHARP_BLLookupAccount

## region CSHARP_BLNetApi
$CSHARP_BLNetApi = @'
// C# based on http://blog.dotsmart.net/2009/03/11/getting-a-machine’s-netbios-domain-name-in-csharp/
using System;
using System.Runtime.InteropServices;
using System.ComponentModel;

public class BLNetApi
// 'Network Management Functions', https://msdn.microsoft.com/en-us/library/windows/desktop/aa370675(v=vs.85).aspx
{
	[DllImport("netapi32.dll", CharSet = CharSet.Auto)]
	// 'NetWkstaGetInfo function', https://msdn.microsoft.com/en-us/library/windows/desktop/aa370663(v=vs.85).aspx
	static extern int NetWkstaGetInfo(string server, int level, out IntPtr info);

	[DllImport("netapi32.dll")]
	// 'NetApiBufferFree function', https://msdn.microsoft.com/en-us/library/windows/desktop/aa370304(v=vs.85).aspx
	static extern int NetApiBufferFree(IntPtr pBuf);
 
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
	// 'WKSTA_INFO_100 structure', https://msdn.microsoft.com/en-us/library/windows/desktop/aa371402(v=vs.85).aspx
	class WKSTA_INFO_100
	{
		public int wki100_platform_id;
		[MarshalAs(UnmanagedType.LPWStr)]
		public string wki100_computername;
		[MarshalAs(UnmanagedType.LPWStr)]
		public string wki100_langroup;
		public int wki100_ver_major;
		public int wki100_ver_minor;
	}

	public static string GetComputerNetBiosDomain()
	{
		IntPtr pBuffer = IntPtr.Zero;
 
		WKSTA_INFO_100 info;
		int retval = NetWkstaGetInfo(null, 100, out pBuffer);
		if (retval != 0)
			throw new Win32Exception(retval);
 
		info = (WKSTA_INFO_100)Marshal.PtrToStructure(pBuffer, typeof(WKSTA_INFO_100));
		string domainName = info.wki100_langroup;
		NetApiBufferFree(pBuffer);
		return domainName;
	}
}
'@
## endregion CSHARP_BLNetAPI

## region CSHARP_BLRegQueryInfoKey
If (($PSVersionTable.PSVersion -ge [version]"3.0") -and ($PSVersionTable.CLRVersion -ge [version]"4.0")) {
	## Microsoft.Win32.SafeHandles.SafeRegistryHandle is only available since .NET 4.0; 
	## Add-Type will throw an error ''Microsoft.Win32.SafeHandles.SafeRegistryHandle' is inaccessible due to its protection level' when used in PS 2.0/CLR 2.0.
	## The class is only used in Get-BLRegistryKeyX64 which only works in PS 3.0/CLR 4.0 or later anyway.
$CSHARP_BLRegQueryInfoKey = @'
	using System;
	using System.Text;
	using System.Runtime.InteropServices; 
	public class BLRegQueryInfoKey {
		// 'RegQueryInfoKey function', https://msdn.microsoft.com/en-us/library/windows/desktop/ms724902(v=vs.85).aspx
		[DllImport("advapi32.dll", EntryPoint = "RegQueryInfoKey")]
		private static extern int RegQueryInfoKey(
			Microsoft.Win32.SafeHandles.SafeRegistryHandle hKey,
			StringBuilder lpClass,
			IntPtr lpcbClass,
			IntPtr lpReserved,
			IntPtr lpcSubKeys,
			IntPtr lpcbMaxSubKeyLen,
			IntPtr lpcbMaxClassLen,
			IntPtr lpcValues,
			IntPtr lpcbMaxValueNameLen,
			IntPtr lpcbMaxValueLen,
			IntPtr lpcbSecurityDescriptor,
			out System.Runtime.InteropServices.ComTypes.FILETIME lpftLastWriteTime
		);

		public static DateTime GetLastWriteTime(Microsoft.Win32.SafeHandles.SafeRegistryHandle hKey) {
			System.Runtime.InteropServices.ComTypes.FILETIME lpftLastWriteTime;
			int Result = RegQueryInfoKey(hKey, null, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, out lpftLastWriteTime);
			long highBits = lpftLastWriteTime.dwHighDateTime;     
			highBits = highBits << 32;
			DateTime dt = DateTime.FromFileTime(highBits | (long)(uint)lpftLastWriteTime.dwLowDateTime);
			return DateTime.SpecifyKind(dt, DateTimeKind.Local);
		}
	}
'@
}
## endregion CSHARP_BLRegQueryInfoKey

## region CSHARP_BLSymbolicLink
$CSHARP_BLSymbolicLink = @'
// C# based on http://stackoverflow.com/questions/16926127/powershell-to-resolve-junction-target-path
	using Microsoft.Win32.SafeHandles;
	using System;
	using System.Text;
	using System.ComponentModel;
	using System.Runtime.InteropServices;

	public class BLSymbolicLink
	{
		private const int FILE_SHARE_WRITE = 2;
		private const int FILE_FLAG_BACKUP_SEMANTICS = 0x02000000;
		private const int CREATION_DISPOSITION_OPEN_EXISTING = 3;

		[DllImport("kernel32.dll", EntryPoint = "GetFinalPathNameByHandleW", CharSet = CharSet.Unicode, SetLastError = true)]
		private static extern int GetFinalPathNameByHandle(IntPtr handle, [In, Out] StringBuilder path, int bufLen, int flags);

		[DllImport("kernel32.dll", EntryPoint = "CreateFileW", CharSet = CharSet.Unicode, SetLastError = true)]
		private static extern SafeFileHandle CreateFile(string lpFileName, int dwDesiredAccess, int dwShareMode, IntPtr SecurityAttributes, int dwCreationDisposition, int dwFlagsAndAttributes, IntPtr hTemplateFile);

		public static string GetTarget(System.IO.DirectoryInfo symlink)
		{
			SafeFileHandle directoryHandle = CreateFile(symlink.FullName, 0, 2, System.IntPtr.Zero, CREATION_DISPOSITION_OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, System.IntPtr.Zero);
			if (directoryHandle.IsInvalid)
				throw new Win32Exception(Marshal.GetLastWin32Error());

			StringBuilder path = new StringBuilder(32768);
			int size = GetFinalPathNameByHandle(directoryHandle.DangerousGetHandle(), path, path.Capacity, 0);
			if (size < 0)
				throw new Win32Exception(Marshal.GetLastWin32Error());
			// The remarks section of GetFinalPathNameByHandle mentions the return being prefixed with "\\?\"
			// More information about "\\?\" here -> http://msdn.microsoft.com/en-us/library/aa365247(v=VS.85).aspx
			if (path[0] == '\\' && path[1] == '\\' && path[2] == '?' && path[3] == '\\')
				return path.ToString().Substring(4);
			else
				return path.ToString();
		}
	}
'@
## endregion CSHARP_BLSymbolicLink

## region CSHARP_BLWin32Window
$CSHARP_BLWin32Window = @'
// Based on 'Messagebox pops up behind PowerGUI', http://en.community.dell.com/techcenter/powergui/f/4833/t/19573683
// -ReferencedAssemblies System.Windows.Forms
	using System;

	public class BLWin32Window : System.Windows.Forms.IWin32Window {
		public static BLWin32Window CurrentWindow {
			get {
				return new BLWin32Window(System.Diagnostics.Process.GetCurrentProcess().MainWindowHandle);
			}
		}

		public BLWin32Window(IntPtr handle) {
			_hwnd = handle;
		}

		public IntPtr Handle {
			get {
				return _hwnd;
			}
		}

		private IntPtr _hwnd;
	}
'@
## endregion

	ForEach ($Variable In (Get-Variable -Name "CSHARP_BL*" -Scope Local)) {
		$AddTypeArgs = @{}
		If ($Variable.Value -match "// *-ReferencedAssemblies +(?<Assemblies>.*)`r") {
			$AddTypeArgs["ReferencedAssemblies"] = $Matches["Assemblies"].Split(',') | % {$_.Trim(' "')}
		}
		Add-Type -TypeDefinition $Variable.Value -Language CSharp @AddTypeArgs
	}
	Add-Type -AssemblyName System.Web
}

## ====================================================================================================
## Group "Base Library"
## ====================================================================================================

Function Initialize-BLFunctions {
<#
.SYNOPSIS
Initializes the library variables and logging functions.

.DESCRIPTION
The function Initialize-BLFunctions initializes global library variables and logging functions.
It sets the following global variables:
	- $AppName
	- $AppSource
	- $AppVersion
	- $TranscriptFile
	- $StartTime
$AppVersion is determined from the name of the script's parent folder; might be "n/a" if the parent folder doesn't match the naming convention "V_a_b_c_d"
By default, this function will query for confirmation to prevent unintended installations by an accidental double click in Explorer.
To run the function without the confirmation, use the -Force switch.
Will create the log folder if it doesn't exist already.

.PARAMETER AppName
Mandatory
The application name that will be installed by the script; will be used as log file name as well.

.PARAMETER AppSource
Mandatory
The script's folder; this argument will be set to the global variable "AppSource".

.PARAMETER Force
Optional
Do not ask for confirmation.

.PARAMETER Uninstall
Optional
Initialize for an uninstall instead of an installation.

.PARAMETER Trace
Optional
Sets the PsDebug trace level
 0 - Turn script tracing off
 1 - Trace script lines as they are executed
 2 - Trace script lines, variable assignments, function calls, and scripts.

.PARAMETER LogFile
Optional
The path and name of the log file to use (default: C:\RIS\Log\<AppName>.log)

.PARAMETER OverwriteLog
Optional
Overwrite an existing log file instead of appending.

.PARAMETER LogByDate
Optional
Log into <AppName> folder with separate log files (date added automatically) instead of a log file directly in the log folder root

.INPUTS
System.String
System.String
System.Management.Automation.SwitchParameter
System.Int32
System.String
System.Management.Automation.SwitchParameter
System.Management.Automation.SwitchParameter

.OUTPUTS
None

.EXAMPLE
Initialize-BLFunctions -AppName "SQL_2012" -AppSource $ScriptPath -Force:$Force -Uninstall:$Uninstall

.LINK
Exit-BLFunctions

.NOTES
None
#>
[CmdletBinding(DefaultParameterSetName="Log_By_Name")]
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$true, Position=0)][ValidateNotNull()]
	[string]$AppName = "",
	[Parameter(Mandatory=$False)]
	[string]$AppSource = "",
	[Parameter(Mandatory=$False)]
	[switch]$Force,
	[Parameter(Mandatory=$False)]
	[switch]$Uninstall,
	[Parameter(Mandatory=$False)]
	[int32]$Trace = 0,
	[Parameter(Mandatory=$False, ParameterSetName="Log_By_Name")]
	[string]$LogFile = "",
	[Parameter(Mandatory=$False, ParameterSetName="Log_By_Name")]
	[switch]$OverwriteLog,
	[Parameter(Mandatory=$False, ParameterSetName="Log_By_Date")]
	[switch]$LogByDate
)
## Old name: SCCM:Initialize-Installation
	$Global:StartTime = [DateTime]::Now
	If ((Test-BLOSVersion -Version "6.2") -And ($Host.Version.Major -ge 3)){	## We're running on Server 2012/Win8 or later and can use the new TaskScheduler module
		Import-Module ScheduledTasks -Scope Global
	}
	$ExecutionAsTask = Test-BLExecutionAsTask
	If ($ExecutionAsTask) {
		$AppName = $AppName + $Script:BL_EAT_LogPostfix
	}
	$Global:Uninstall = $Uninstall
	If (-Not $Force) {
		Try {
			If ($Global:Uninstall) {$Action = "UNinstall"} Else {$Action = "install"}
			$bc = $host.UI.RawUI.BackgroundColor
			$fc = $host.UI.RawUI.ForegroundColor
			$host.UI.RawUI.BackgroundColor = "DarkRed"
			$host.UI.RawUI.ForegroundColor = "White"
			cls
			Write-Host ""
			Write-Host "`tWARNING!"
			Write-Host "`t~~~~~~~~"
			Write-Host "`tYou are about to $Action the application '$AppName'!"
			Write-Host "`tPlease enter 'yes' if you want to proceed,"
			Write-Host "`tany other input will cancel the process."
			Write-Host ""
			$Confirm = Read-Host "`tConfirm the $Action of '$AppName'"
			$host.UI.RawUI.BackgroundColor = $bc
			$host.UI.RawUI.ForegroundColor = $fc
			cls
			If ($Confirm -ne "yes") {
				Write-Host "Operation cancelled."
				Exit 1
			}
		} Catch {
			Throw "Argument '-Force' not passed, but unable to query for confirmation; cannot continue with the script!"
		}
	}
	If ($Global:Uninstall) {
		$LogEntry = "$($Global:StartTime): UNinstallation started for package '$AppName' from '$AppSource'"
		$WindowTitle = "UNinstallation: $AppName"
	} Else {
		$LogEntry = "$($Global:StartTime): Installation started for package '$AppName' from '$AppSource'"
		$WindowTitle = "Installation: $AppName"
	}
	If ($BL_PSHost.SupportsWindowTitle) {
		$Script:InitialWindowTitle = $host.UI.RawUI.WindowTitle
		$host.UI.RawUI.WindowTitle = $WindowTitle
	}
	$LogEntry | Write-BLEventLog -LogType "Information"
	If ((-not [String]::IsNullOrEmpty($Script:RIS_Logfolder)) -and (Test-Path $Script:RIS_Logfolder)) {
		If (-not [String]::IsNullOrEmpty($Script:RIS_Summarizelog)) {
			Add-Content -LiteralPath $Script:RIS_Summarizelog -Value $LogEntry -Force | Out-Null
		}
	}
	If ([string]::IsNullOrEmpty($AppName))		{"No AppName specified." | Write-BLLog -LogType CriticalError; exit 1}
	If ([string]::IsNullOrEmpty($AppSource))	{"No AppSource specified." | Write-BLLog -LogType CriticalError; exit 1}
	$Global:AppName = $AppName
	$Global:AppSource = $AppSource
	# Configure script debugging
	#Set-PSDebug -Trace $Trace -Strict
	Set-PSDebug -Trace $Trace
	If ([string]::IsNullOrEmpty($LogFile)) {
		If ($LogByDate) {
			$LogFolder = Join-Path $Script:RIS_Logfolder $AppName.Replace(" ", "_")
			$LogName = $($AppName.Replace(" ", "_") + "_" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
		} Else {
			$LogFolder = $Script:RIS_Logfolder
			$LogName = $($AppName.Replace(" ", "_") + ".log")
		}
	} Else {
		$LogFolder = Split-Path -Path $LogFile -Parent
		$LogName = Split-Path -Path $LogFile -Leaf
		If ($LogName.IndexOf(".") -lt 0) {
			$LogName = $LogName + ".log"
		}
		If ($ExecutionAsTask) {
			$LogName = $LogName.Insert($LogName.LastIndexOf("."), $Script:BL_EAT_LogPostfix)
		}
	}
	If (-Not (Test-Path -Path $LogFolder)) {
		New-Item -Type Directory -Path $LogFolder | Out-Null
	}
	$Global:TranscriptFile = Join-Path $Logfolder $LogName
	# Start script recording to $TranscriptFile
	If ($OverwriteLog) {
		Remove-Item -Path $Global:TranscriptFile -ErrorAction SilentlyContinue
	}
	If ($BL_PSHost.SupportsTranscription) {
		Start-Transcript -Append -Force -Path $Global:TranscriptFile
		If ($BL_PSHost.SupportsWriteHost) {
			$TranscriptTestLine = "Testing transcription ... "
			Write-Host "$($TranscriptTestLine)`r"
			If ($TranscriptTestLine -eq (Get-Content -Path $Global:TranscriptFile | Select-Object -Last 1)) {
				Write-Host "... OK.`r" -ForegroundColor Green
			} Else {
				Stop-Transcript
				"Transcription is not working as it should, Powershell's external stdout is probably redirected!" | Out-File -FilePath $Global:TranscriptFile -Append -Force
				$Script:BL_PSHost.SupportsTranscription = $False
			}
		}
	}
	If (-Not $BL_PSHost.SupportsTranscription) {
		$WarnTranscription = "This PS host ($($Host.Name)) does not support transcription; output which is not explicitly redirected to Write-BLLog may not be captured in the log file!"
		$Header = @"
**********************
Baselibrary Write-BLLog transcript start
Start time: $(Get-Date -Format 'yyyyMMddHHmmss')
Username  : $(& whoami.exe)
Machine   : $($ENV:Computername) ($([System.Environment]::OSVersion.VersionString))
**********************
"@
		If ($BL_PSHost.SupportsWriteHost) {
			$Header | Write-Host
		}
		$WarnTranscription | Write-Warning
		$Header.Split("`r`n") | Out-File -FilePath $Global:TranscriptFile -Append -Force
		$WarnTranscription | Out-File -FilePath $Global:TranscriptFile -Append -Force
	}
	If ($BL_PSHost.SupportsWriteHost) {
		Write-Host
	}
	## Read environment variables from Registry
	$Key = Get-Item "HKLM:SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
	$IgnoreValues = @("USERNAME")	## List any variable names here that should not be imported into the current session
	ForEach ($Value in $Key.GetValueNames()) {
		$Data = $Key.GetValue($Value)
		If ($IgnoreValues -NotContains $Value) {
			[Environment]::SetEnvironmentVariable($Value, $Data, "Process")
		}
	}
	$Global:AppVersion = Split-Path -Path $AppSource -Leaf -ErrorAction SilentlyContinue
	If (-Not ($Global:AppVersion -match '\AV_\d+_\d+_\d+_\d+\Z')) {
		$Global:AppVersion = 'n/a'
	}
	"Base library is initialized; script is '$($AppName)', version $($Global:AppVersion)." | Write-BLLog -LogType Information
}

Function Exit-BLFunctions($SetExitCode = $Null) {
## Old name: SCCM:FollowUp-Installation
## Post-installation tasks
	$MyName = [string]$($MyInvocation.MyCommand.Name)
	If ([String]::IsNullOrEmpty($SetExitCode)) {
		"'-SetExitCode' is empty; please pass an integer value (ideally uint16, but int32 supported)!" | Write-BLLog -LogType CriticalError
		$SetExitCode = 9999
	}
	If ($SetExitCode -is [array]) {
		"'-SetExitCode' contains more than one element; make sure your functions don't spill pipeline output when assigning ExitCode to a return value:" | Write-BLLog -LogType CriticalError
		$Index = 0
		ForEach ($Element In $setExitCode) {
			$Index += 1
			"##### Element $($Index), $($Element.GetType().FullName) ################################################################################" | Write-BLLog -LogType CriticalError
			$Element | Out-String | Write-BLLog -LogType CriticalError
		}
		$SetExitCode = 9999
	}
	$intExitCode = 0
	If ([int32]::TryParse($SetExitCode, [ref]$intExitCode)) {
		$SetExitCode = $intExitCode
	} Else {
		"The '-SetExitCode' of '$($SetExitCode)' is not an int32!" | Write-BLLog -LogType CriticalError
		$SetExitCode = 9999
	}
	If ((Test-BLExecutionAsTask) -eq $True) {
		Exit-BLExecutionAsTask $SetExitCode
	}
	$Global:EndTime = [DateTime]::Now
	$Footer = @"

Returned error level '$SetExitCode'

Script execution time was $([DateTime]$Global:EndTime - [DateTime]$Global:StartTime)
"@
	If ($BL_PSHost.SupportsWriteHost) {
		$Footer.Split("`r`n") | % {$_ + "`r" | Write-Host}
	}
	If ((-Not $BL_PSHost.SupportsTranscription) -And (-Not [string]::IsNullOrEmpty($Global:TranscriptFile))) {
		$Footer.Split("`r`n") | Out-File -FilePath $Global:TranscriptFile -Append -Force
	}
	If ($BL_PSHost.SupportsTranscription) {
		Stop-Transcript
	}
	If ($Global:Uninstall) {
		$LogEntry = "$($Global:EndTime): UNinstallation finished for package '$AppName' with Exitcode '$SetExitCode'."
	} Else {
		$LogEntry = "$($Global:EndTime): Installation finished for package '$AppName' with Exitcode '$SetExitCode'."
	}
	Switch ($setExitCode) {
		0		{$LogType = "Information"}
		3010	{$LogType = "Warning"}
		Default	{$LogType = "CriticalError"}
	}
	$LogEntry | Write-BLEventLog -LogType $LogType -ID $setExitCode
	If (-not [String]::IsNullOrEmpty($Script:RIS_Summarizelog)) {
		Add-Content -LiteralPath $Script:RIS_Summarizelog -Value $LogEntry -Force | Out-Null
	}
	# Copy the transcript to Central_Log
	$targetDir = $Env:RIS_Central_Log
	If ($targetDir) {
		$Logsubfolder = ("SCCM\$($Env:Computername)").Split("\")
		ForEach ($Subfolder in $Logsubfolder) {
			If ($Subfolder.Trim() -ne "") {
				$targetDir = "$($targetDir)\$($Subfolder.Trim())"
				If (!(Test-Path $targetDir)) {MD $targetDir | Out-Null}
			}
		}
		Copy-Item -Path $Global:TranscriptFile -Destination $targetDir -Force
	}
	If ($BL_PSHost.SupportsWindowTitle) {
		$host.UI.RawUI.WindowTitle = $Script:InitialWindowTitle
	}
	# Set errorlevel
	If ($SetExitCode -eq 3010) {
		Exit 0
	} Else {
		Exit $SetExitCode
	}
}

Function Update-BLLibraryScript([string]$Path = $Null) {
## Updates legacy installation scripts to the new function names and the new library usage.
## This function is meant to be run manually, not inside an install script:
## Import-Module C:\RIS\Lib\BaseLibrary.psm1 -Path "C:\Pakete\Some_Package\Install-Script.ps1"

## Will be commented out when running Update-BLLibraryScript
$BL_ISUPD_CommentLines = @'
param([string]$Init = "")
if (!($Init.Length)) {Write-Host -ForegroundColor Red "[CriticalError] $Local:ScriptName : no initialization script specified."; break}
if (!(Test-Path -Path $Init)) {Write-Host -ForegroundColor Red "[CriticalError] $Local:ScriptName : File not found - $Init"; break}
. $Init
'@

## Will be inserted BEFORE the first line in $BL_ISMIG_Comment
$BL_ISUPD_NewHeader = @'
## CUSTOMIZE: Add supported arguments for the script here (do not remove the -Force or -Uninstall arguments):
Param(
	[switch]$Force,
	[switch]$Uninstall
)
$LibraryPath = "C:\RIS\Lib"
$BaseLibrary = Join-Path $LibraryPath "BaseLibrary.psm1"
If (-Not (Import-Module "$BaseLibrary" -Force -PassThru)) {Write-Host -ForegroundColor Red "[CriticalError] $($Local:ScriptName): File not found - '$BaseLibrary'"; Exit 1}

'@

## Variable with lines of tab separated columns containing function names to be replaced with new ones.
## Lines where the third column (description) is not empty will remain unchanged, instead the description will be logged as warning;
## this is used for functions that have been replaced or a changed functionality where changing the function name is not sufficient.
$BL_ISUPD_FunctionNameReplacements = @'
SCCM:Add-LocalAdminGroupMember	Add-BLLocalAdminGroupMember
SCCM:applyTemplate	Export-BLConfigDBConvertedTemplateFile
SCCM:Check-HyperVGuest	Test-BLHyperVGuest
SCCM:chkCfg	n/a	LEGACY: Replace with Get-BLConfigDBVariables -Defaults <File>
SCCM:Create-Regkey	New-BLRegistryKey
SCCM:Create-ScheduledTask	Set-BLScheduledTask
SCCM:Dump-Log	Move-BLFileToLog
SCCM:Export-Ini	Export-BLIniFile
SCCM:Fork-InstallationAsTask	Enter-BLExecutionAsTask
SCCM:FollowUp-Installation	Exit-BLFunctions
SCCM:Get-Config-File	Copy-BLConfigDBFile
SCCM:Get-EnvVar	Get-BLEnvironmentVariable
SCCM:Get-IniKey	Get-BLIniKey
SCCM:Get-LocalGroupMembers	Get-BLLocalGroupMembers
SCCM:Get-ManagementPoint	Get-BLSCCMManagementPoint
SCCM:Get-PrimaryDNSSuffix	Get-BLPrimaryDNSSuffix
SCCM:Import-Ini	Import-BLIniFile
SCCM:Import-Regfile	Import-BLRegistryFile
SCCM:Initialize-Installation	Initialize-BLFunctions
SCCM:Initialize-XACommands	Initialize-BLXACommands
SCCM:Invoke-BatchFile	Invoke-BLBatchFile
SCCM:Invoke-Command	Invoke-BLSetupOther
SCCM:Invoke-InnoSetup	Invoke-BLSetupInno
SCCM:Invoke-InstallShieldSetup	Invoke-BLSetupInstallShield
SCCM:Invoke-ISPFTWSetup	Invoke-BLSetupInstallShieldPFTW
SCCM:Invoke-MsiSetup	Invoke-BLSetupMsi
SCCM:Invoke-NSISSetup	Invoke-BLSetupNSIS
SCCM:Invoke-Powershell	Invoke-BLPowershell
SCCM:Invoke-RDS-InstallMode	Set-BLRDSInstallMode
SCCM:Invoke-RDS-ExecuteMode	Set-BLRDSExecuteMode
SCCM:Invoke-WiseSetup	Invoke-BLSetupWise
SCCM:Install-RoleOrFeature	Install-BLWindowsRoleOrFeature
SCCM:Install-Ws2k8Hotfix	Install-BLWindowsHotfix
SCCM:Install-Ws2k8LangPack	Install-BLWindowsLanguagePack
SCCM:Log-Config-Settings	Write-BLConfigDBSettings
SCCM:Set-ServiceStartup	Set-BLServiceStartup
SCCM:Invoke-MsiUninstall	n/a	Replace with Invoke-BLSetupMsi {-msiGUID <GUID> | -msiFile <File>} -instType "/x"
SCCM:Query-RDS-Installation	Get-BLRDSApplicationMode
SCCM:rdFile Get-Content
SCCM:Read-Config-File	Import-BLConfigDBFile	Library use only, not exported; replace use 'Get-BLConfigDBVariables'
SCCM:ReadCfg	n/a	LEGACY: Replace with Get-BLConfigDBVariables
SCCM:Remove-IniCategory	Remove-BLIniCategory
SCCM:Remove-IniKey	Remove-BLIniKey
SCCM:Remove-ScheduledTask	Remove-BLScheduledTask
SCCM:Set-Config-Variables	Get-BLConfigDBVariables
SCCM:Set-IniKey	Set-BLIniKey
SCCM:Split-Config-Account	Split-BLConfigDBAccountVariable
SCCM:Split-Config-ElementList	Split-BLConfigDBElementList
SCCM:Start-Process	Start-BLProcess
SCCM:substInTemplate	Get-BLConfigDBConvertedTemplate
SCCM:Test-InstallationAsTask	Test-BLExecutionAsTask	Library use only, not exported
SCCM:Verify-Config-Variables	Test-BLConfigDBVariables	Library use only, not exported; replace use 'Get-BLConfigDBVariables' with the '/defaults' argument
SCCM:Write-EventLog	Write-BLEventLog
SCCM:Write-Log	Write-BLLog
'@

	"Starting " + $MyInvocation.MyCommand + " at " + (Get-Date).ToLongTimeString() | Write-BLLog -LogType Information
	$ExitCode = 1	## Assume failure unless proven otherwise
	$FileItem = Get-Item -Path $Path
	If ($FileItem) {
		Initialize-BLFunctions -AppSource $FileItem.DirectoryName -AppName $FileItem.BaseName -Force -LogFile (Join-Path $FileItem.DirectoryName "$($FileItem.BaseName).log") -OverwriteLog
		Set-ItemProperty -Path $Path -Name IsReadOnly -Value $False
		$WarningCount = 0
		$OldContent = Get-Content -Path $Path
		$NewContent = @()
		$FunctionNameReplacements = $BL_ISUPD_FunctionNameReplacements.Replace("`r", "").Split("`n", ([StringSplitOptions]"RemoveEmptyEntries"))
		$CommentLines = $BL_ISUPD_CommentLines.Replace("`r", "").Split("`n", ([StringSplitOptions]"RemoveEmptyEntries"))
		$NewHeader = $BL_ISUPD_NewHeader.Replace("`r", "").Split("`n")
		$LineOffset = 0
		ForEach ($OldLine In $OldContent) {
			$NewLine = $OldLine
			$IgnoreLine = $False
			ForEach ($CommentLine In $CommentLines) {
				If ($NewLine -eq $CommentLine) {
					$NewLine = "# LEGACY: $NewLine"
					$IgnoreLine = $True
					Break
				}
			}
			If (-Not $IgnoreLine) {
				ForEach ($ReplaceLine In $FunctionNameReplacements) {
					$OldFunction = $ReplaceLine.ToString().Split("`t")[0]
					$NewFunction = $ReplaceLine.ToString().Split("`t")[1]
					$Description = $ReplaceLine.ToString().Split("`t")[2]
					If ($NewLine -Match $OldFunction) {
						If ([String]::IsNullOrEmpty($Description)) {
							$NewLine = $NewLine -Replace $OldFunction, $NewFunction
						} Else {
							$NewLine = "# MANUAL CHANGE REQUIRED for function '$($Oldfunction)': " + $Description + "`n" + $NewLine
							$LineOffset += 1
							$WarningCount += 1
							"Line $($OldLine.ReadCount + $LineOffset), function '$($Oldfunction)': $Description" | Write-BLLog -LogType Warning
						}
					}
				}
			}
			If ($OldLine -eq $CommentLines[0]) {
				$NewLine = $BL_ISUPD_NewHeader + "`n" + $NewLine
				$LineOffset += $NewHeader.Count
			}
#			Write-Host -Fore Green "[$($OldLine.ReadCount + $LineOffset)]`t$NewLine"
			$NewContent += $NewLine
		}
		If (-Not (Test-Path -Path "$Path.bak")) {
			Copy-Item -Path $Path -Destination "$Path.bak"
			If ($?) {
				Set-Content -Path $Path -Value $NewContent
				If ($?) {
					$ExitCode = 0
				} Else {
					"Could not overwrite the script file." | Write-BLLog -LogType CriticalError
				}
			} Else {
				"Could not create a backup of the original file. Try running the script again in an elevated prompt." | Write-BLLog -LogType CriticalError
			}
		} Else {
			"Backup of the original file exists already." | Write-BLLog -LogType CriticalError
		}
		If ($WarningCount -gt 0) {
			"Could not automatically update all function calls; check the log file for warnings, and/or search the script file for 'MANUAL CHANGE REQUIRED'." | Write-BLLog -LogType Warning
		}
	} Else {
		"Could not find the script file '$Path'." | Write-BLLog -LogType CriticalError
	}
	"Leaving " + $MyInvocation.MyCommand + " with return value $ExitCode at " + (Get-Date).ToLongTimeString() | Write-BLLog -LogType Information
	Stop-Transcript
	If ($ExitCode -ne 0) {
		Throw "Unable to update the script '$Path'!"
	}
}

## ====================================================================================================
## Group "Logging"
## ====================================================================================================

Function Get-BLLogFileName([string]$CustomNameExtension = "", [switch]$CreatePath) {
## Creates a filename or path for custom logfiles.
# immer "_" anfügen, damit Konflikt mit Std Logfile für Transscript vermieden wird
#	IF ($CustomNameExtension -ne "") {
#		$CustomNameExtension = "_" + $CustomNameExtension
#	}

	IF ($CreatePath) {
		$LogDir = $RIS_Logfolder + "\" + $AppName + "_" + $CustomNameExtension + "\"
		If (-Not (Test-Path $LogDir)) {
			New-Item -Path $LogDir -ItemType Directory | Out-Null
		}
		return $LogDir
	} Else {
		return $RIS_Logfolder + "\" + $AppName + "_" + $CustomNameExtension + ".log"
	}
}

Function Get-BLLogFolder() {
	Return $Script:RIS_Logfolder
}

Function Get-BLScriptLineNumber() {
	Return $MyInvocation.ScriptLineNumber
}

Function Move-BLFileToLog([string]$logFile = "") {
## Old name: SCCM:Dump-Log
## Moves an installer logfile to the default log file (deletes the original file!)
	$MyName = [string]$($MyInvocation.MyCommand.Name)
	If ($logFile.Length) {
		If (Test-Path $logFile) {
			"$MyName : === Begin of installation logfile dump ===`r" | Write-BLLog -LogType Information
			$unformattedcontent = [System.IO.File]::ReadAllText($logFile)
			[string[]]$filecontent = $unformattedcontent.Split("`n")
			[int32]$x=0
			foreach ($line in $filecontent) {
				$x += 1
				$linenumber = "{0:D6}" -f $x
				Write-Host "`[$linenumber`] $line`r" -ForegroundColor $([System.ConsoleColor]::Gray)
			}
			"$MyName : === End of installation logfile dump ===`r" | Write-BLLog -LogType Information
			Remove-Item -Path $logFile -Force
		} Else {
			"$MyName : logfile not found - $logFile`r" | Write-BLLog -LogType MajorError
		}
	}
}

Function Set-BLLogDebugMode([Bool]$Mode) {
## Sets the debug mode for Write-BLLog; if $True, debug information will be written to the log.
## Function is exported.
	$Script:BL_LOG_DebugMode = $Mode
	if ($Mode) {
		Set-BLLogLevel -LowestLevelToLog "Debug" | Out-Null
	} else {
		Set-BLLogLevel | Out-Null
	}
}

Function Set-BLLogLevel($LowestLevelToLog = "Information") {
## Function is exported.
	$Script:BL_LOG_NoLogList = @()
	if ( $BL_LOG_AllowedLogTypes -inotcontains $LowestLevelToLog) {
		$LowestLevelToLog = "Information"
	}
	foreach ($lev in $BL_LOG_AllowedLogTypes) {
		if ($lev -eq $LowestLevelToLog) {
			break
		}
		$Script:BL_LOG_NoLogList += $lev
	}
}

Function Update-BLExceptionInvocationInfo {
[CmdletBinding()]
Param(
	[Parameter(ValueFromPipeline=$True, Position=0)]
	$Exception,
	[Parameter(Position=1)]
	[int]$Offset = 0
)
## Returns a (deserialized) Exception object with offset added to ScriptLineNumber and PositionMessage.
## Useful when executing scriptblocks with a try/catch where the exception is passed back to the caller.
## You can determine the offset by running Get-BLScriptLineNumber in the line immediately before Invoke-Command.
	Process {
		If (-Not $Exception) {
			Throw "$($MyInvocation.MyCommand): Mandatory argument Exception missing."
		}
		If ($Exception -is [Management.Automation.ErrorRecord]) {
			$Exception = [Management.Automation.PSSerializer]::Deserialize([Management.Automation.PSSerializer]::Serialize($Exception))
		}
		$Exception.InvocationInfo.ScriptLineNumber += $Offset
		$Exception.InvocationInfo.PositionMessage = $Exception.InvocationInfo.PositionMessage -replace "([\w\s]+:)\d+( [\w\s]+:\d+)", "`${1}$($Exception.InvocationInfo.ScriptLineNumber)`${2}"
		$Exception | Write-Output
	}
}

Function Write-BLEventLog([string]$LogType = "Information", [int32]$ID=0) {
## Old name: SCCM:Write-EventLog
	Process {
		If (-Not $_) {Return}
		$Description = $_.ToString().Trim()
		# Function throws an error if $ID -gt 65535 or -lt 0; make sure it's in the range of 0 .. 65535
		# and inform about the change.
		If (($ID -ge 65535) -Or ($ID -lt 0)) {
			$Description = "(Original ID '$ID' outside allowed range; changed to 65535) " + $Description
			$ID = 65535
		}
		#Set EventlogEntryType
		[System.Diagnostics.EventLogEntryType] $EventLogEntryType = [System.Diagnostics.EventLogEntryType]::Information
		If (($LogType).EndsWith("Error")) {
			[System.Diagnostics.EventLogEntryType] $EventLogEntryType = [System.Diagnostics.EventLogEntryType]::Error
			If ($ID -eq 0) {$ID = 1}
		} ElseIf ($LogType -eq "Warning") {
			[System.Diagnostics.EventLogEntryType] $EventLogEntryType = [System.Diagnostics.EventLogEntryType]::Warning
			If ($ID -eq 0) {$ID = 3010}
		}
		$source = "BaseLibrary"
		If (-Not ([system.Diagnostics.EventLog]::SourceExists($source))) {
			[system.diagnostics.Eventlog]::CreateEventSource($source, "BaseLibrary")
		}
		# Add the eventlog entry
		[System.Diagnostics.EventLog]::WriteEntry($Source, $Description, $EventLogEntryType, $ID)
	}
}

Function Write-BLLog([string]$LogType = "Information", [string]$CustomLogType = "", $CustomCol = "", [switch]$NoTrim, [switch]$NoColType, [switch]$NoColTime, [switch]$NoColCaller) {
## Old name: SCCM:Write-Log
## Displays a log message
	Process {
		If (-Not $_) {Return}
		If ($CustomLogType -eq "") {
			If ($BL_LOG_AllowedLogTypes -NotContains $LogType) {
				Throw "The log type '$($LogType)' is unknown; allowed types: $($BL_LOG_AllowedLogTypes -join ', ')"
			}
			$LogType = $BL_LOG_AllowedLogTypes | Where {$_ -eq $LogType}	# Force the log type case as specified in the array.
		} Else {
			$LogType = $CustomLogType
		}
		If ($NoTrim) {
			$Description = $_.ToString()
		} Else {
			$Description = $_.ToString().Trim()
		}
		If ($CustomLogType -ne "") {
			$Color = [ConsoleColor]::Cyan
		} ElseIf ($LogType.EndsWith("Error") -or ($LogType -eq "Warning")) {
			If ($LogType.EndsWith("Error")) {
				$LogEntry = "An error occurred."
				$Color = [ConsoleColor]::Red
			} Else {
				$LogEntry = "A warning level entry was written."
				$Color = [ConsoleColor]::Yellow
			}
			If ((-not [String]::IsNullOrEmpty($Script:RIS_Summarizelog)) -And (-Not [string]::IsNullOrEmpty($Global:TranscriptFile))) {
				"$($LogEntry) Please analyze detail log '$($Global:TranscriptFile)'." | Write-BLEventLog -LogType $LogType
				Add-Content -LiteralPath $Script:RIS_Summarizelog -Value $LogEntry -Force | Out-Null
			}
		} ElseIf ($LogType -eq "Debug") {
			$Color = [ConsoleColor]::Magenta
		} Else {
			$Color = [ConsoleColor]::White
		}
		$CallingFunction = (Get-PSCallStack)[1].Command
		$CallingTime = Get-Date -Format "yyyyMMdd-HHmmss"
		ForEach ($Line In $Description.Split("`r`n", ([StringSplitOptions]"RemoveEmptyEntries"))) {
			$LogLine = ""
			If (-Not $NoColType)	{$LogLine += "`[$LogType`]`t"}
			If (-Not $NoColTime)	{$LogLine += "`[$CallingTime`]`t"}
			If (-Not $NoColCaller)	{$LogLine += "`[$CallingFunction`]`t"}
			If ($CustomCol -ne "")	{$LogLine += "`[$CustomCol`]`t"}
			$LogLine += $Line
			If	(($Script:BL_LOG_NoLogList -inotcontains $LogType) -Or (($LogType -eq "Debug") -And $Script:BL_LOG_DebugMode)) {
				If ($BL_PSHost.SupportsWriteHost) {
					Write-Host "$LogLine`r" -ForegroundColor $Color
				}
				If ((-Not $BL_PSHost.SupportsTranscription) -And (-Not [string]::IsNullOrEmpty($Global:TranscriptFile))) {
					$LogLine | Out-File -FilePath $Global:TranscriptFile -Append
				}
			}
		}
	}
}

## ====================================================================================================
## Group "Execution as Task"
## ====================================================================================================

Function Enter-BLExecutionAsTask {
<#
.SYNOPSIS
Restarts the current script as a scheduled task.

.DESCRIPTION
The function Enter-BLExecutionAsTask restarts the current installation script as a scheduled task.
The 'main' script will wait for the 'task' instance to finish, monitor the 'task' instance, and retrieve and return its exit code.
AppName and log file name for the 'task' instance will be the same as the 'main' script's, with "-TASK" added.
Returns >= 0: exit code of the 'task' instance; a negative exit code from the 'task' instance will be reset to 1 and a warning with the original exit code logged in the 'main' script's log.
Returns -1: Already running as a scheduled task, returns control to the main script immediately
Returns -2: Internal error, could not create the task

.PARAMETER UserName
Mandatory
The user name under which the task will be running.
The account will be added to the local Administrators group; it will NOT be removed from this group after the execution.

.PARAMETER UserDomain
Mandatory
The user's NetBIOS domain name.

.PARAMETER UserPass
Mandatory
The user's password

.PARAMETER AutoCreateTemporaryUser
Mandatory
The function will create a temporary administrator account and remove it after the installation.

.PARAMETER TimeOut
Optional
The time in minutes that the task may run before it will be forcefully deleted.
Must be >= 5.
Default: 60 minutes.

.PARAMETER NoTask
Optional
Disables running the script as a task.
This can be used during script development and testing, so that the script can be run directly under the currently logged on user account.
You should be logged on with the user account defined for task execution.

.PARAMETER RunAs32
Optional
When starting the script as task, use the 32bit environment.

.INPUTS
System.String
System.String
System.String
System.Int32
System.Management.Automation.SwitchParameter
System.Management.Automation.SwitchParameter

.OUTPUTS
System.Int32

.EXAMPLE
_
## ... <Default variable initialization> ...
Initialize-BLFunctions -AppName "MyApplication" -AppSource $Local:ScriptPath
## Get the ConfigDB variables:
$cfg = @{}
$ExitCode = Get-BLConfigDBVariables $cfg
If ($ExitCode -ne 0) {
	"Error setting variables from ConfigDB, unable to continue!" | Write-BLLog -LogType Information
	Exit-BLFunctions -SetExitCode 1
}
## Start a second instance of the script; the main instance will wait here until the task instance is done:
$TaskUserDomain =	$cfg["XXX_INSTALL_SETUP_USER"].Split("\")[0].Trim()
$TaskUsername =		$cfg["XXX_INSTALL_SETUP_USER"].Split("\")[1].Trim()
$TaskPassword =		$cfg["XXX_INSTALL_SETUP_PASSWORD"].Trim()
$ExitCode = Enter-BLExecutionAsTask -UserName $TaskUsername -UserDomain $TaskUserDomain -UserPass $TaskPassword  # -NoTask
If ($ExitCode -eq -2) {			# Task could not be created; this is a serious error
	$ExitCode = 1
} ElseIf ($ExitCode -eq -1) {	# we're running as a scheduled task; this is a second instance of the script!
	## ... <Do whatever needs to be done to install the application> ...
}
Exit-BLFunctions -SetExitCode $ExitCode
#>
[CmdletBinding(DefaultParameterSetName="Explicit_Account")]
Param(
	[Parameter(Position=0, ParameterSetName="Explicit_Account")][ValidateNotNull()]
	[string]$UserName, 
	[Parameter(Position=1, ParameterSetName="Explicit_Account")][ValidateNotNull()]
	[string]$UserDomain, 
	[Parameter(Position=2, ParameterSetName="Explicit_Account")][ValidateNotNull()]
	[string]$UserPass,
	[Parameter(Position=0, ParameterSetName="Autocreate_Account")]
	[switch]$AutoCreateTemporaryUser,
	[Parameter(Position=3)]
	[int32]$Timeout = 60, 
	[Parameter(Position=4)]
	[Switch]$NoTask,
	[Parameter(Position=5)]
	[Switch]$RunAs32
)
## Old name: SCCM:Fork-InstallationAsTask
	"Entering " + $MyInvocation.MyCommand + " at " + (Get-Date).ToLongTimeString() | Write-BLLog -LogType Information
	If (Test-BLExecutionAsTask) {
		"This script instance is running as a scheduled task; continuing with the script ..." | Write-BLLog -LogType Information
		Set-BLExecutionAsTaskStatus -Status "Running"
		$ret = -1
	} ElseIf ($NoTask) {
		"Debug mode is enabled using switch argument -NoTask; will NOT run the installation as a task, but continue with the logged on user!" | Write-BLLog -LogType Warning
		If ((Get-BLCredentialManagerPolicy) -eq "Enabled") {
			"." | Write-BLLog
			"Note that the policy 'Network access: Do not allow storage of passwords and credentials for network authentication' in" | Write-BLLog -LogType Warning
			"'Windows Settings\Security Settings\Local Policies\Security Options' is enabled for this computer!" | Write-BLLog -LogType Warning
			"This does not prevent the current execution in debug mode, but it will prevent tasks set to run under user accounts from starting." | Write-BLLog -LogType Warning
			"The script will try to work around this issue, but the task may fail anyway if the policy update timing is unlucky." | Write-BLLog -LogType Warning
			"." | Write-BLLog
		}
		$RunningUserDomain, $RunningUserName = (&whoami.exe).Split("\")
		If ($PsCmdlet.ParameterSetName -eq "Explicit_Account") {
			If (($UserName -ne $RunningUserName) -Or ($UserDomain -ne $RunningUserDomain)) {
				"This script is currently running under '$RunningUserDomain\$RunningUserName', while the task is supposed to be running as '$UserDomain\$UserName'!" | Write-BLLog -LogType Warning
			}
		} Else {
			"This script is currently running under '$RunningUserDomain\$RunningUserName', while the task is supposed to be running under a temporary account with only local administrative permissions!" | Write-BLLog -LogType Warning
		}
		If ($RunAs32 -And ([IntPtr]::size -eq 8)) {
			"This script is supposed to be started in a 32bit environment, but is currently running in 64bit; unable to continue!" | Write-BLLog -LogType CriticalError
			$ret = -2
		} Else {
			$ret = -1
		}
	} Else {
		Try {
			$ret = 0
			If ($PsCmdlet.ParameterSetName -eq "Autocreate_Account") {
				$UserName = $BL_EAT_TempInstallAccount
				$UserDomain = $ENV:ComputerName
				$UserPass = Get-BLRandomString -Length 32 -Upper -Lower -Digit -MandatoryClasses '!:;,.-_#+=/\[]{}'
				"Creating temporary installation account '$($UserName)' ..." | Write-BLLog -LogType Information
				$EATInstallAccount = New-BLLocalUser -Name $UserName -Password $UserPass -FullName "Temporary Install" -Description "Atos Execeution As Task temporary installation account. If found while no packages are installed, this account can safely be deleted!" -AccountDisabled $false -PasswordCantChange $true -PasswordNeverExpires $true -PassThru -ProcessExistingUser
				If (-not $EATInstallAccount) {
					Throw "Could not create the temporary installation account '$($UserName)'!"
				}
			}
			$AccountName = "$($UserDomain)\$($UserName)"
			"Adding installation account '$AccountName' to local Administrators group ..." | Write-BLLog -LogType Information
			If ((Add-BLLocalAdminGroupMember -UserName $UserName -DomainName $UserDomain) -ne 0) {
				Throw "Could not add '$($AccountName)' to the local Administrators group!"
			}
			$AppSourceResolved = Get-BLFullPath -Path $AppSource -AsUnc
			If ($AppSourceResolved.StartsWith("\\")) {
				$TaskDir = Join-Path -Path $ENV:WinDir -ChildPath "Temp\EAT_$($AppName)"
				"The installation source is on a network drive ($($AppSourceResolved)); the required network access for the user running the task can not be verified." | Write-BLLog -LogType Warning
				"The source will be copied locally to '$($TaskDir)' and the task started from there." | Write-BLLog -LogType Warning
				& robocopy.exe $AppSource.TrimEnd("\") $TaskDir.TrimEnd("\") /e /r:0 /np /nfl /ndl | Write-BLLog -NoColCaller -NoColTime -CustomCol "robocopy.exe" -NoTrim
				$RCErrorLevel = $LASTEXITCODE
				If ($RCErrorLevel -lt 4) {
					"robocopy ended with errorlevel $($RCErrorLevel); the copy was successful." | Write-BLLog
				} Else {
					"robocopy ended with errorlevel $($RCErrorLevel); the copy failed!" | Write-BLLog -LogType CriticalError
					Throw "Unable to create a local copy of the network installation source!"
				}
			} Else {
				$TaskDir = $AppSource
			}
			$TaskCmd = Join-Path -Path $TaskDir -ChildPath "Install.cmd"
			If (-not (Test-Path -Path $TaskCmd)) {	## Can happen during script development
				Throw "Required file 'install.cmd' not found!"
			}
			"Creating scheduled task '$($Script:BL_EAT_Name)' to install the application." | Write-BLLog -LogType Information
			"The log file for the scheduled installation will be $($AppName + $Script:BL_EAT_LogPostfix).log" | Write-BLLog -LogType Information
			If ($RunAs32) {
				$TaskArg = "-RunAs32 -Force"
			} Else {
				$TaskArg = "-Force"
			}
			If ($Global:Uninstall) {
				$TaskArg += " -Uninstall"
			}
			# Remove possible leftovers from previous installation attempts
			Remove-BLRegistryValueX64 -Path $Script:BL_EAT_RegKey -Name "ExitCode" -ErrorAction SilentlyContinue| Out-Null
			Remove-BLRegistryValueX64 -Path $Script:BL_EAT_RegKey -Name "Status" -ErrorAction SilentlyContinue | Out-Null
			Remove-BLRegistryValueX64 -Path $Script:BL_EAT_RegKey -Name "CredentialManager" -ErrorAction SilentlyContinue | Out-Null
			# Prepare the task:
			If (-Not (New-BLRegistryKeyX64 -Path $Script:BL_EAT_RegKey)) {Throw "Could not create the required registry key '$($Script:BL_EAT_RegKey)'"}
			If ((Get-BLCredentialManagerPolicy) -eq "Enabled") {
				"The policy 'Network access: Do not allow storage of passwords and credentials for network authentication' in" | Write-BLLog -LogType Warning
				"'Windows Settings\Security Settings\Local Policies\Security Options' is enabled for this computer!" | Write-BLLog -LogType Warning
				"The script will try to work around this issue, but the task may fail anyway if the timing is unlucky." | Write-BLLog -LogType Warning
				"." | Write-BLLog
				If ((Set-BLCredentialManagerPolicy -State "Disabled") -eq 0) {
					"Policy temporarily disabled; installation should work." | Write-BLLog
					Set-BLExecutionAsTaskStatus -CredentialManager "Disable"
				} Else {
					"Unable to disable the policy; the GPO disabling the Credential Manager will need to be changed for this script to work!" | Write-BLLog -LogType CriticalError
				}
			} Else {
				Set-BLExecutionAsTaskStatus -CredentialManager "Ignore"
			}
			$CurrentTime = Get-Date
			If (Test-BLOSVersion -Version "6.2") {
				$StartTime = $CurrentTime.AddMinutes(1)	## On 2012, the start time accepts seconds, so we can reduce the wait time.
				Unregister-ScheduledTask -TaskName $Script:BL_EAT_Name -Confirm:$False -ErrorAction SilentlyContinue
				$ST_Action = New-ScheduledTaskAction -Execute $TaskCmd -Argument $TaskArg -WorkingDirectory $TaskDir -ErrorAction Stop
				$ST_Trigger = New-ScheduledTaskTrigger -Once -At $StartTime -ErrorAction Stop
				$ST_Settings = New-ScheduledTaskSettingsSet -Compatibility Win7 -MultipleInstances IgnoreNew -RestartCount 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ErrorAction Stop
				$ST_Task = Register-ScheduledTask -TaskName $Script:BL_EAT_Name -Action $ST_Action -Trigger $ST_Trigger -Settings $ST_Settings -User $AccountName -Password $UserPass -RunLevel Highest -Description "Installs '$AppName' as scheduled task. DO NOT CHANGE MANUALLY!" -Force -ErrorAction Stop
			} Else {	## Running on Server 2008 R2 or earlier, using schtasks.exe
				$StartTime = $CurrentTime.AddMinutes(2)
				$StartTimeFormatted = "{0:HH:mm}" -f $StartTime
				Remove-BLScheduledTask -Name $Script:BL_EAT_Name -Quiet | Out-Null
				$ret += Set-BLScheduledTask -Name $Script:BL_EAT_Name -Command "$TaskCmd $TaskArg" -Username $AccountName -UserPassword $UserPass -Schedule "ONCE" -StartTime $StartTimeFormatted
			}
		} Catch {
			$_ | Out-String | Write-BLLog -LogType CriticalError
			$ret += 1
		}
		If ($ret -ne 0) {
			"Error during preparing/creating the installation task, unable to continue!" | Write-BLLog -LogType CriticalError
			$ret = -2
		} Else {
			"Task successfully created to start at {0:HH:mm:ss}." -f $StartTime | Write-BLLog -LogType Information
			$Status = "Scheduled at {0:HH:mm:ss}" -f $StartTime
			Set-BLExecutionAsTaskStatus -Status $Status
			$TimeoutScriptStart = 4	## Minutes
			$Job_CancelEatIfTaskNotStarted = Start-Job -ScriptBlock {		## This job makes sure that the initial instance of the script will finish even if the scheduled one did never start.
				Param(
					[string]$BaseLibrary,
					[string]$InitialStatus,
					[int]$TimeoutScriptStart
				)
				Start-Sleep -Seconds ($TimeoutScriptStart * 60)
				Import-Module -Name $BaseLibrary -Force 2>&1
				$CurrentStatus = Get-BLExecutionAsTaskStatus
				If ($CurrentStatus -eq $InitialStatus) {	## Scheduled script hasn't updated its status to "Running" yet, so we abort.
					Set-BLExecutionAsTaskStatus -Status "Install-Script.ps1 was not started or did not initialize properly!"
					If ((Get-BLCredentialManagerPolicy) -eq "Enabled") {
						## No need to re-apply the GPO anymore; this just happened ...
						Set-BLExecutionAsTaskStatus -CredentialManager "Ignore"
						Set-BLExecutionAsTaskExitCode -ExitCode 9992999
					} Else {
						Set-BLExecutionAsTaskExitCode -ExitCode 9990999
					}
				}
			} -ArgumentList $BLScriptFullName, $Status, $TimeoutScriptStart
			$Wait = $True
			$TimeoutSeconds = $Timeout * 60
			$PollTime = 10
			$Counter = 0
			# We're assuming the worst (a timeout condition) until the installation proves us wrong:
			$ret = 1
			"[" + (Get-Date).ToLongTimeString() + "] Waiting a maximum of $Timeout minutes for the task to finish ..." | Write-BLLog
			Do {
				Receive-Job $Job_CancelEatIfTaskNotStarted | Write-BLLog -CustomCol "ScriptStartMonitor"
				Start-Sleep -Seconds $PollTime
				$Counter += $PollTime
				$NewStatus = Get-BLExecutionAsTaskStatus
				If ($Status -ne $NewStatus) {
					"[" + (Get-Date).ToLongTimeString() + "] Task status changed to '$NewStatus'" | Write-BLLog -LogType Information
					$Status = $NewStatus
					If ((Get-BLExecutionAsTaskStatus -CredentialManager) -eq "Disable") {
						## Task is now running or done; either way, we can stop disabling the Credential Manager policy.
						Set-BLExecutionAsTaskStatus -CredentialManager "Enable"
					}
				}
				If ((Get-BLExecutionAsTaskStatus -CredentialManager) -eq "Disable") {
					## While the policy is enabled, Credential Manager only prevents access to the stored credentials, it does not seem to delete them.
					## So in order to reduce the risk of the policy getting updated in the time between creating the task and task start, we keep disabling the policy until the task is started.
					If ((Get-BLCredentialManagerPolicy) -eq "Enabled") {
						"[" + (Get-Date).ToLongTimeString() + "] Credential Manager policy was updated; disabling it again." | Write-BLLog
						Set-BLCredentialManagerPolicy -State "Disabled" | Out-Null
					}
				}
				$ret = Get-BLExecutionAsTaskExitCode
				If ($ret -ne $Null) {
					$Wait = $False
				}
			} While (($Counter -lt $TimeOutSeconds) -And ($Wait -eq $True))
			Remove-Job -Job $Job_CancelEatIfTaskNotStarted -Force -ErrorAction SilentlyContinue
			If ($Wait -eq $True) {
				"[" + (Get-Date).ToLongTimeString() + "] Timeout of $Timeout minutes was reached, stopping/removing task and returning!" | Write-BLLog -LogType CriticalError
			} ElseIf ($ret -eq 9990999) {
				"[" + (Get-Date).ToLongTimeString() + "] Install-Script.ps1 was either not started by the Task Scheduler, or did not initialize properly!" | Write-BLLog -LogType CriticalError
			} ElseIf ($ret -eq 9991999) {
				"[" + (Get-Date).ToLongTimeString() + "] Install-Script.ps1 was cancelled manually by 'Stop-BLExecutionAsTask'!" | Write-BLLog -LogType CriticalError
			} ElseIf ($ret -eq 9992999) {
				"[" + (Get-Date).ToLongTimeString() + "] Install-Script.ps1 was not started because its credentials were deleted by a policy update that fell inbetween the creation of the task and its start!" | Write-BLLog -LogType CriticalError
				"[" + (Get-Date).ToLongTimeString() + "] This is NOT an error caused by the installation script; try to run the installation again." | Write-BLLog -LogType CriticalError
			} Else {
				If ($ret -eq 0) {$LogType = "Information"} Else {$LogType = "CriticalError"}
				"[" + (Get-Date).ToLongTimeString() + "] Installation signaled exit code $ret." | Write-BLLog -LogType $LogType
			}
			If (($Wait -eq $True) -Or ($ret -eq 9990999) -Or ($ret -eq 9991999) -Or ($ret -eq 9992999)) {
				$ret = 1
				If (Test-BLOSVersion -Version "6.2") {
					Stop-ScheduledTask -TaskName $Script:BL_EAT_Name -ErrorAction SilentlyContinue
				} Else {
					Start-BLProcess -Filename (Join-Path $Env:SystemRoot "system32\schtasks.exe") -Arguments "/end /tn $($Script:BL_EAT_Name)" | Out-Null
				}
			} Else {
				If ($ret -lt 0) {
					"Changed the original negative exit code of $ret to 1!" | Write-BLLog -LogType Warning
					$ret = 1
				}
				Do {	## The script has signaled that it's done; the task scheduler still needs a bit of time to clean up.
					Start-Sleep -Seconds 2
				} While (Test-BLExecutionAsTask)
				"[" + (Get-Date).ToLongTimeString() + "] Installation script finished, removing task and returning." | Write-BLLog
			}
			If (Test-BLOSVersion -Version "6.2") {
				Unregister-ScheduledTask -TaskName $Script:BL_EAT_Name -Confirm:$False -ErrorAction SilentlyContinue
			} Else {
				Remove-BLScheduledTask -Name $Script:BL_EAT_Name -Quiet | Out-Null
			}
			If ($AppSourceResolved.StartsWith("\\")) {
				"The initial script was on a network drive, so a local copy of the installation source has been created." | Write-BLLog
				If ($ret -eq 0) {
					"The installation was successful, so the local copy will be deleted." | Write-BLLog
					Remove-Item -Path $TaskDir -Recurse -Force
				} Else {
					"The installation failed, so the local copy will NOT be deleted to save time if the installation is repeated." | Write-BLLog -LogType Warning
					"If the local copy is not required anymore, you can safely delete the following folder: '$($TaskDir)'." | Write-BLLog
				}
			}
		}
	}
	If ($EATInstallAccount) {
		"Removing temporary installation account '$($UserName)' ..." | Write-BLLog
		Remove-BLUserProfile -Name $EATInstallAccount -Confirm:$False -ErrorAction SilentlyContinue
		Remove-BLLocalUser -Name $EATInstallAccount
	}
	$CMAction = Get-BLExecutionAsTaskStatus -CredentialManager
	If ((-Not $NoTask) -And (($CMAction -eq "Enable") -Or ($CMAction -eq "Disable"))) {
		"Re-applying the policy 'Network access: Do not allow storage of passwords and credentials for network authentication' ..." | Write-BLLog -LogType Warning
		Set-BLExecutionAsTaskStatus -CredentialManager "Ignore" | Out-Null
		Set-BLCredentialManagerPolicy -State "Enabled" | Out-Null
	}
	"Leaving " + $MyInvocation.MyCommand + " with return value '$ret' at " + (Get-Date).ToLongTimeString() | Write-BLLog
	Return $ret
}

Function Exit-BLExecutionAsTask($SetExitCode) {
	If (($SetExitCode -eq 3010) -or ($SetExitCode -eq 0)) {	# 3010: Installation OK, but reboot required
		$regExitCode = 0
	} Else {
		$regExitCode = $SetExitCode
	}
	# We're in an installation running as a scheduled task; set exit code in registry, so that the calling script can continue.
	"Installation as scheduled task ended; passing exit code $regExitCode back to original script ..." | Write-BLLog -LogType Information
	If (New-BLRegistryKeyX64 -Path $Script:BL_EAT_RegKey) {
		Set-BLExecutionAsTaskStatus -Status "Done"
		Set-BLExecutionAsTaskExitCode -ExitCode $regExitCode | Out-Null
	} Else {
		"Could not access '$($Script:BL_EAT_RegKey)'; unable to pass control back to the original script!" | Write-BLLog -LogType CriticalError
	}
}

Function Get-BLExecutionAsTaskExitCode() {
	Return Get-BLRegistryValueX64 -Path $Script:BL_EAT_RegKey -Name "ExitCode" -ErrorAction SilentlyContinue
}

Function Get-BLExecutionAsTaskStatus([switch]$CredentialManager) {
	If ($CredentialManager) {
		Return Get-BLRegistryValueX64 -Path $Script:BL_EAT_RegKey -Name "CredentialManager" -ErrorAction SilentlyContinue
	} Else {
		Return Get-BLRegistryValueX64 -Path $Script:BL_EAT_RegKey -Name "Status" -ErrorAction SilentlyContinue
	}
}

Function Set-BLExecutionAsTaskExitCode([int]$ExitCode) {
## Old name: Set-BLInstallationAsTaskStatus
## Updates the current task status to inform that the initial script about the task's status.
	Set-BLRegistryValueX64 -Path $Script:BL_EAT_RegKey -Name "ExitCode" -Type "REG_DWORD" -Value $ExitCode | Out-Null
}

Function Set-BLExecutionAsTaskStatus([string]$Status, [ValidateSet("Disable", "Enable", "Ignore")][string]$CredentialManager) {
## Old name: Set-BLInstallationAsTaskStatus
## Updates the current task status to inform that the initial script about the task's status.
	If ($Status) {
		Set-BLRegistryValueX64 -Path $Script:BL_EAT_RegKey -Name "Status" -Type "REG_SZ" -Value $Status | Out-Null
	}
	If ($CredentialManager) {
		Set-BLRegistryValueX64 -Path $Script:BL_EAT_RegKey -Name "CredentialManager" -Type "REG_SZ" -Value $CredentialManager | Out-Null
	}
}

Function Stop-BLExecutionAsTask([switch]$Force) {
## For use in a console session only, not in a script!
	If (-Not $Force) {
		"You are about to cancel a running installation." | Write-Warning
		$Confirm = Read-Host "Enter 'yes' to stop the scheduled task"
		If ($Confirm.ToLower() -eq "yes") {
			$Force = $True
		}
	}
	If ($Force) {
		"Sending Stop signal to ExecutionAsTask ..." | Write-Warning
		Set-BLExecutionAsTaskStatus -Status "Install-Script.ps1 was stopped manually!"
		Set-BLExecutionAsTaskExitCode -ExitCode 9991999
	}
}

Function Test-BLExecutionAsTask() {
## Old name: SCCM:Test-InstallationAsTask
## Tests whether the current script installation is running as a task that was started using Enter-BLExecutionAsTask
## Returns $False if the script is not running as a task, $True otherwise.
## The ExecutionAsTaskName task should either not exist at all, or be in state "Running".
	$ret = $False		# That's the expected default return value
	If ((Test-BLOSVersion -Version "6.2") -And ($Host.Version.Major -ge 3)) {
		$Task = Get-ScheduledTask -TaskName $Script:BL_EAT_Name -ErrorAction SilentlyContinue
		If ($Task -And ($Task.State.ToString() -eq "Running")) {
			$ret = $True
		}
	} Else {
		$Task = Get-BLScheduledTask -TaskName $Script:BL_EAT_Name
		If ($Task -And ($Task.State -eq "Running")) {
			$ret = $True
		}
	}
	Return $ret
}

## ====================================================================================================
## Group "Installation management"
## ====================================================================================================

Function Get-BLMsiProperties {
[CmdletBinding()]
Param (
	[Alias("Filename")][String]$Path,
	[String[]]$PropertyList = @()
)
## Returns a custom object with the properties retrieved from the msi file
## The property "MsiFilename" will be set to the file's full path.
## The rest of the properties depends on the PropertyList argument.
	If (-Not (Test-Path -Path $Path)) {
		"Could not find '$($Path)'!" | Write-Error
		Return $Null
	}
	If (-Not ($FileItem = Get-Item -Path $Path)) {
		"Could not access '$($Path)'!" | Write-Error
		Return $Null
	}
	If ($PropertyList.Count -eq 0) {$All = $True} Else {$All = $False}
	$MsiProperties = New-Object Object
	Add-Member -InputObject $MsiProperties -MemberType "NoteProperty" -Name "MsiFilename" -Value $FileItem.FullName
	$Installer = New-Object -ComObject "WindowsInstaller.Installer"
	Switch ($FileItem.Extension) {
		".lnk" {
			Try {
				$ShortcutTarget = $Installer.GetType().InvokeMember("ShortcutTarget", "GetProperty", $Null, $Installer, $FileItem.FullName)
				$StringData = 1..3 | % {$ShortcutTarget.GetType().InvokeMember("StringData", "GetProperty", $Null, $ShortcutTarget, $_)}
				Add-Member -InputObject $MsiProperties -MemberType "NoteProperty" -Name "ProductCode" -Value $StringData[0]
				Add-Member -InputObject $MsiProperties -MemberType "NoteProperty" -Name "FeatureID" -Value $StringData[1]
				Add-Member -InputObject $MsiProperties -MemberType "NoteProperty" -Name "ComponentCode" -Value $StringData[2]
				$Value = $Installer.GetType().InvokeMember("ProductInfo", "GetProperty", $Null, $Installer, @($StringData[0], "ProductName"))
				Add-Member -InputObject $MsiProperties -MemberType "NoteProperty" -Name "ProductName" -Value $Value
				$Value = $Installer.GetType().InvokeMember("ComponentPath", "GetProperty", $Null, $Installer, ($StringData[0, 2]))
				Add-Member -InputObject $MsiProperties -MemberType "NoteProperty" -Name "ShortcutTarget" -Value $Value
			} Catch {
				"'$($FileItem.FullName)' is not an advertised shortcut (HResult $($_.Exception.HResult))!" | Write-Error
				Return $Null
			}
		}
		".msi" {
			$InstallerDatabase = $Installer.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null, $Installer, @($FileItem.FullName, 0))
			$View = $InstallerDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $Null, $InstallerDatabase, "SELECT * FROM Property")
			$View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null)
			$Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $Null, $View, $Null)
			While ($Record) {
				$Property = $Record.GetType().InvokeMember("StringData", "GetProperty", $Null, $Record, 1)
				$Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $Null, $Record, 2)
				If (($PropertyList -Contains $Property) -Or $All) {
					Add-Member -InputObject $MsiProperties -MemberType "NoteProperty" -Name $Property -Value $Value
				}
				$Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $Null, $View, $Null)
			}
			$View.GetType().InvokeMember("Close", "InvokeMethod", $Null, $View, $Null)
			[Runtime.InteropServices.Marshal]::FinalReleaseComObject($View) | Out-Null
			[Runtime.InteropServices.Marshal]::FinalReleaseComObject($InstallerDatabase) | Out-Null
		}
		".msp" {	## See "Extracting Patch Information as XML", http://msdn.microsoft.com/en-us/library/aa368573(v=vs.85).aspx
			Try {
				[xml]$xml = $Installer.GetType().InvokeMember("ExtractPatchXMLData", "InvokeMethod", $Null, $Installer, $FileItem.FullName)
			} Catch {
				"Unable to extract XML information from '$($Path)'; is this a valid msp file?" | Write-Error
				Return $Null
			}
			[System.Xml.XmlNamespaceManager]$NsMgr = $xml.NameTable
			$xmlns = $xml.MsiPatch.GetAttribute("xmlns")
			$NsMgr.AddNamespace("msi", $xmlns)
			Add-Member -InputObject $MsiProperties -MemberType "NoteProperty" -Name "xml" -Value $xml
			Add-Member -InputObject $MsiProperties -MemberType "NoteProperty" -Name "TargetProducts" -Value @()
			ForEach ($Node In $xml.SelectNodes("/msi:MsiPatch/msi:TargetProduct", $NsMgr)) {
				$TargetProduct = New-Object Object
				ForEach ($Child In ($Node.ChildNodes)) {
					Add-Member -InputObject $TargetProduct -MemberType "NoteProperty" -Name $Child.Name -Value $Child.InnerText
				}
				$MsiProperties.TargetProducts += $TargetProduct
			}
			Add-Member -InputObject $MsiProperties -MemberType "NoteProperty" -Name "TargetProductCodes" -Value @()
			ForEach ($Node In $xml.SelectNodes("/msi:MsiPatch/msi:TargetProductCode", $NsMgr)) {
				$MsiProperties.TargetProductCodes += $Node.InnerText
			}
		}
	}
	Return $MsiProperties
}

Function Get-BLUninstallInformation {
<#
.SYNOPSIS
Returns uninstall information about installed software.

.DESCRIPTION
The function Get-BLUninstallInformation returns uninstall information about installed software.
By default, it returns a list of all installed software (PS 3.0 or later required).
The function can as well search by the software's display name, its GUID, or a hotfix's KB name.
When queried for a specific software (and unless there is an error), the function always(!) returns at least one custom object with a boolean property "IsInstalled"; use this property to check whether the software is instelled or not.
-DisplayVersion can (and will only) be used in conjunction with DisplayName if DisplayName might not be unique (for example "Microsoft Visual C++ 2005 Redistributable").
The function searches by default both in x64 and x86 HKLM\Software; the returned object will have a property "SoftwareArchitecture" set to "x86" or "x64".
If -KBName is specified (format "KB<ID>"), WMI's Win32_QuickFixEngineering will be searched to find installed hotfixes.
The WMI query results will be cached (since the WMI call can take quite some time) and can be answered from cache for subsequent queries if -Cached is used.
Returns $Null if an error occurred.

.PARAMETER DisplayName
Mandatory
Search for the software by Display Name (as displayed in Control Panel).

.PARAMETER DisplayVersion
Optional
The software's Display Version (as displayed in Control Panel).
Only required if the Display Name is not unique.

.PARAMETER x64Only
Optional
Only results for 64bit software will be returned.

.PARAMETER x86Only
Optional
Only results for 32bit software will be returned.

.PARAMETER Quiet
Optional
By default, the function warns if more than one result is returned. Use this switch to suppress this warning.

.PARAMETER GUID
Mandatory
Search for the software by GUID.

.PARAMETER KBName
Mandatory
Search for a hotfix by Knowledge Base Name (Format KB<6..7 digits>).

.PARAMETER Cached
Optional
Use this to allow the function to answer the query from the internal cache.
The cache will be (re-)built when it doesn't exist, and upon each KB search without "-Cached".

.PARAMETER Hotfix
Optional
Returns an array with all installed hotfixes.

.PARAMETER IncludeSystemComponents
Optional
When retrieving a list of all installed software, software flagged as system component will by default be skipped.
If this switch is True, system components will be returned as well.
When the query is for a specific name or GUID, system components will be returned without this switch.

.PARAMETER ComputerName
Optional
The computer from which to retrieve the software list.

.INPUTS
System.String
System.Switch

.OUTPUTS
System.Object[]

.EXAMPLE
Get-BLUninstallInformation
Returns a list of all locally installed software; software flagged as system components will be hidden.

.EXAMPLE
Get-BLUninstallInformation -ComputerName rz1vpfsql001 -IncludeSystemComponents
Returns a list of all software installed on rz1vpfsql001; system components will be returned as well.

.EXAMPLE
Get-BLUninstallInformation -Hotfix
Returns a list of all locally installed hotfixes.

.EXAMPLE
Get-BLUninstallInformation -DisplayName "Notepad++"
Checks if the software "Notepad++" is installed.

.EXAMPLE
Get-BLUninstallInformation "Microsoft Visual C++ 2005 Redistributable" -DisplayVersion "8.0.61001"
Checks if Visual C++ 2005 in the version "8.0.61001" is installed (there may be more than one version with this name!).

.EXAMPLE
Get-BLUninstallInformation -GUID "{710f4c1c-cc18-4c49-8cbf-51240c89a1a2}"
Checks if Visual C++ 2005 in the version "8.0.61001" is installed by using the GUID.

.EXAMPLE
Get-BLUninstallInformation -KBName KB2345316 -Cached
Checks if the hotfix KB2345316 is installed; use the cache from a previous (if available).

.LINK

.NOTES
#>
[CmdletBinding(DefaultParameterSetName="Software_All")]
Param(
	[Parameter(Position=0, ParameterSetName="Software_By_Name")]
	[string]$DisplayName = "",
	[Parameter(Position=1, ParameterSetName="Software_By_Name")]
	[string]$DisplayVersion = "",
	[Parameter(Position=0, ParameterSetName="Software_By_GUID")]
	[string]$GUID = "",
	[Parameter(ParameterSetName="Software_By_Name")]
	[Parameter(ParameterSetName="Software_By_GUID")]
	[switch]$x64Only,
	[Parameter(ParameterSetName="Software_By_Name")]
	[Parameter(ParameterSetName="Software_By_GUID")]
	[switch]$x86Only,
	[Parameter(ParameterSetName="Software_By_Name")]
	[Parameter(ParameterSetName="Software_By_GUID")]
	[switch]$Quiet,
	[Parameter(Position=0, ParameterSetName="Hotfix_By_KB")]
	[string]$KBName = "",
	[Parameter(ParameterSetName="Hotfix_By_KB")]
	[switch]$Cached,
	[Parameter(ParameterSetName="Software_All")]
	[switch]$IncludeSystemComponents,
	[Parameter(ParameterSetName="Hotfix_All")]
	[switch]$Hotfix,
	[Parameter(ParameterSetName="Software_All")]
	[Parameter(ParameterSetName="Hotfix_All")]
	[string]$ComputerName = $ENV:ComputerName	## '.' works for 'OpenRemoteBaseKey' on Server OS, but not on Client OS!
)
	$OSArchitecture = Get-BLOSArchitecture -ComputerName $ComputerName
	If ([string]::IsNullOrEmpty($OSArchitecture)) {
		Return $Null
	}
	$RE_Guid = '"?(?<GUID>\{[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}\})"?'
	$RE_MsiExecGuid = 'msiexec.exe .*/(x|i|uninstall|package)[ ]*' + $RE_Guid
	If ($ComputerName -eq ".") {
		$HostName = $ENV:ComputerName
	} Else {
		$HostName = $ComputerName
	}
	Switch ($PsCmdlet.ParameterSetName) {
		"Software_All" {	## PS 2.0 not supported anymore
			If ($Host.Version -lt [version]"3.0") {
				Throw "This parameter set requires PS v3.0 or later; found PS v$($Host.Version)."
			}
			$Wow6432NodeMap = [ordered]@{
				"x64" = ""
				"x86" = "\Wow6432Node"
			}
			ForEach ($SoftwareArchitecture In $Wow6432NodeMap.Keys) {
				$BaseKey = "HKLM:\Software$($Wow6432NodeMap[$SoftwareArchitecture])\Microsoft\Windows\CurrentVersion\Uninstall"
				ForEach ($SoftwareKey In Get-BLRegistryKeyX64 -Path "$($BaseKey)\*" -ComputerName $ComputerName | Select-Object -ExpandProperty PSChildName) {
					$UninstallRegistry = Get-BLRegistryKeyX64 -Path "$($BaseKey)\$($SoftwareKey)" -ComputerName $ComputerName
					If ((!$UninstallRegistry.SystemComponent -Or $IncludeSystemComponents) -And ![string]::IsNullOrEmpty($UninstallRegistry.DisplayName) -And ![string]::IsNullOrEmpty($UninstallRegistry.UninstallString)) {
						If ($UninstallRegistry.UninstallString -match $RE_MsiExecGuid) {
							$GUID = $Matches["GUID"]
						} Else {
							If ($SoftwareKey -match $RE_Guid) {
								$GUID = $Matches["GUID"]
							} Else {
								$GUID = ""
							}
						}
						$UninstallRegistry |
							Select-Object -Property `
								@{Name="ComputerName";			Expression={$HostName}},
								Comments,
								DisplayName,
								DisplayVersion,
								@{Name="GUID";					Expression={$GUID}},
								## This is the way Control Panel handles it: if InstallDate is set, it will be used; otherwise LastWriteTime of the uninstall registry key is used.
								@{Name="InstallDate";			Expression={If ([string]::IsNullOrEmpty($_.InstallDate)) {$_.PSLastWriteTime} Else {Try {[datetime]::ParseExact($_.InstallDate, "yyyyMMdd", $Null)} Catch {$_.InstallDate}}}},
								Publisher,
								@{Name="SoftwareArchitecture";	Expression={$SoftwareArchitecture}},
								@{Name="SystemComponent";		Expression={$_.SystemComponent -eq 1}},
								UninstallString |
							Write-Output
					}
				}
			}
		}
		
		{@("Software_By_Name", "Software_By_GUID") -Contains $_} {
			$PropertyList = @(
				"Comments",
				"DisplayName",
				"DisplayVersion",
				"GUID",
				"InstallDate",
				"IsInstalled",
				"Publisher",
				"SoftwareArchitecture",
				"SystemComponent",
				"UninstallString"
			)
			If ([string]::IsNullOrEmpty($DisplayName) -And [string]::IsNullOrEmpty($GUID)) {
				"Either DisplayName or GUID need to be specified!" | Write-BLLog -LogType CriticalError
				Return $Null
			}
			If ($x64Only -And $x86Only) {
				"You will have to decide between restricting to x86 OR x64!" | Write-BLLog -LogType CriticalError
				Return $Null
			}
			If ($DisplayName -ne "") {
				If ($DisplayVersion -eq "") {
					$Condition = {$_.DisplayName -eq $DisplayName}
				} Else {
					$Condition = {($_.DisplayName -eq $DisplayName) -And ($_.DisplayVersion -eq $DisplayVersion)}
				}
			}
			If ([intptr]::Size -eq 8) {	## 64bit PS on x64 OS
				If ($PsCmdlet.ParameterSetName -eq "Software_By_GUID") {
					If (-Not $x86Only) {$UninstallRegistry_x64 = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$GUID" -ErrorAction SilentlyContinue}
					If (-Not $x64Only) {$UninstallRegistry_x86 = Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$GUID" -ErrorAction SilentlyContinue}
				} Else {	## Software_By_Name
					If (-Not $x86Only) {$UninstallRegistry_x64 = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Where $Condition}
					If (-Not $x64Only) {$UninstallRegistry_x86 = Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Where $Condition}
				}
			} Else {	## 32bit PS on either x64 OS or x86 OS
				If ($PsCmdlet.ParameterSetName -eq "Software_By_GUID") {
					If ($OSArchitecture -eq "x64") {	## x64 OS
						If (-Not $x86Only) {$UninstallRegistry_x64 = Get-BLRegistryKeyX64 "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$GUID" -ErrorAction SilentlyContinue}
					}
					If (-Not $x64Only) {$UninstallRegistry_x86 = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$GUID" -ErrorAction SilentlyContinue}
				} Else {	## Software_By_Name
					If ($OSArchitecture -eq "x64") {	## 32bit PS on x64 OS
						If (-Not $x86Only) {$UninstallRegistry_x64 = Get-BLRegistryKeyX64 "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Where $Condition}
					}
					If (-Not $x64Only) {$UninstallRegistry_x86 = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Where $Condition}
				}
			}
			If (($UninstallRegistry_x86 -eq $Null) -And ($UninstallRegistry_x64 -eq $Null)) {
				$Uninstall = New-Object Object
				ForEach ($Property In $PropertyList) {
					Add-Member -InputObject $Uninstall -MemberType "NoteProperty" -Name $Property -Value ""
				}
				$Uninstall.IsInstalled = $False
				$Uninstall.SystemComponent = $False
				If ($GUID -ne "") {
					$Uninstall.GUID = $GUID
				} Else {
					$Uninstall.DisplayName = $DisplayName
				}
				Return $Uninstall
			}
			$ReturnValue = @()
			If ($UninstallRegistry_x64) {
				ForEach ($UninstallRegistry In $UninstallRegistry_x64) {
					$Uninstall = New-Object Object
					ForEach ($Property In $PropertyList) {
						Add-Member -InputObject $Uninstall -MemberType "NoteProperty" -Name $Property -Value $UninstallRegistry.$Property
					}
					If ($UninstallRegistry.PSChildName -match $RE_Guid) {
						$Uninstall.GUID = $Matches["GUID"]		# Can't use $UninstallRegistry.PSChildName - Keys like '{92FB6C44-E685-45AD-9B20-CADF4CABA132} - 1033' exist.
					} Else {
						If ((-Not [string]::IsNullOrEmpty($Uninstall.UninstallString)) -And ($Uninstall.UninstallString -match $RE_MsiExecGuid)) {
							$Uninstall.GUID = $Matches["GUID"]
						} Else {
							$Uninstall.GUID = ""
						}
					}
					$Uninstall.IsInstalled = $True
					$Uninstall.SoftwareArchitecture = "x64"
					$Uninstall.SystemComponent = $UninstallRegistry.SystemComponent -eq 1
					$ReturnValue +=	$Uninstall
				}
			}
			If ($UninstallRegistry_x86) {
				ForEach ($UninstallRegistry In $UninstallRegistry_x86) {
					$Uninstall = New-Object Object
					ForEach ($Property In $PropertyList) {
						Add-Member -InputObject $Uninstall -MemberType "NoteProperty" -Name $Property -Value $UninstallRegistry.$Property
					}
					If ($UninstallRegistry.PSChildName -match $RE_Guid) {
						$Uninstall.GUID = $Matches["GUID"]
					} Else {
						If ((-Not [string]::IsNullOrEmpty($Uninstall.UninstallString)) -And ($Uninstall.UninstallString.ToUpper() -match $RE_MsiExecGuid)) {
							$Uninstall.GUID = $Matches["GUID"]
						} Else {
							$Uninstall.GUID = ""
						}
					}
					$Uninstall.IsInstalled = $True
					$Uninstall.SoftwareArchitecture = "x86"
					$Uninstall.SystemComponent = $UninstallRegistry.SystemComponent -eq 1
					$ReturnValue +=	$Uninstall
				}
			}
			If ($ReturnValue.Count -gt 1) {
				If (-Not $Quiet) {"Found more than one installation for '{0}'!" -f $(If ($GUID -eq "") {$DisplayName} Else {$GUID}) | Write-BLLog -LogType Warning}
				Return $ReturnValue
			} Else {
				Return $ReturnValue[0]
			}
		}
		
		"Hotfix_All" {
			$PropertyList = @(
				"Caption",
				"Description",
				"FixComments",
				"HotFixID",
				"InstallDate",
				"InstalledBy",
				"InstalledOn",
				"Name",
				"ServicePackInEffect",
				"Status"
			)
			## Select * doesn't return all properties
			Get-WmiObject -Namespace "root\CIMv2" -Query "SELECT $($PropertyList -join ",") FROM Win32_QuickFixEngineering" -ComputerName $ComputerName	|
				Select-Object -Property $PropertyList | 
				Select-Object -Property @{Name="ComputerName"; Expression={$HostName}}, *, @{Name="SoftwareArchitecture"; Expression={$OSArchitecture}}
		}
	
		"Hotfix_By_KB" {
			If ([string]::IsNullOrEmpty($KBName) -Or (-Not ($KBName -match '^KB\d{6,7}$'))) {
				"KBName needs to be specified and match KB<Hotfix ID>!" | Write-BLLog -LogType CriticalError
				Return $Null
			}
			$Uninstall = New-Object Object
			$PropertyList = @(
				"Caption",
				"CSName",
				"Description",
				"FixComments",
				"HotFixID",
				"InstallDate",
				"InstalledBy",
				"InstalledOn",
				"Name",
				"ServicePackInEffect",
				"Status"
			)
			ForEach ($Property In $PropertyList) {
				Add-Member -InputObject $Uninstall -MemberType "NoteProperty" -Name $Property -Value ""
			}
			Add-Member -InputObject $Uninstall -MemberType "NoteProperty" -Name "IsInstalled" -Value $False
			Add-Member -InputObject $Uninstall -MemberType "NoteProperty" -Name "SoftwareArchitecture" -Value $OSArchitecture
			If ((-Not $Cached) -Or (-Not $Script:Win32_QuickFixEngineering)) {
				$Script:Win32_QuickFixEngineering = Get-WmiObject -Namespace "root\CIMv2" -Query "SELECT $($PropertyList -join ",") FROM Win32_QuickFixEngineering"	## Select * doesn't return all properties
			}
			$HotfixWMI = $Script:Win32_QuickFixEngineering | Where {$_.HotFixID -eq $KBName}
			If ($HotfixWMI) {
				ForEach ($Property In $PropertyList) {
					$Uninstall.$Property = $HotfixWMI.$Property
				}
				$Uninstall.IsInstalled = $True
			} Else {
				$Uninstall.HotFixID = $KBName
			}
			Return $Uninstall
		}
	}
}

Function Initialize-BLWUAErrorCodes() {
## Function is not exported, internal use only; only the variable $BL_WUA_RESULT_CODES is exported.
## Reference: Windows Update Agent Result Codes, http://technet.microsoft.com/library/dd939837.aspx
$WuaCsv = @'
	"Type","ResultCode","ResultString","Description"
	"Success","0x240001","WU_S_SERVICE_STOP","Windows Update Agent was stopped successfully."
	"Success","0x240002","WU_S_SELFUPDATE","Windows Update Agent updated itself."
	"Success","0x240003","WU_S_UPDATE_ERROR","Operation completed successfully but there were errors applying the updates."
	"Success","0x240004","WU_S_MARKED_FOR_DISCONNECT","A callback was marked to be disconnected later because the request to disconnect the operation came while a callback was running."
	"Success","0x240005","WU_S_REBOOT_REQUIRED","The system must be restarted to complete update installation."
	"Success","0x240006","WU_S_ALREADY_INSTALLED","The update to be installed is already installed on the system."
	"Success","0x240007","WU_S_ALREADY_UNINSTALLED","The update to be removed is not installed on the system."
	"Error","0x80240001","WU_E_NO_SERVICE","Windows Update Agent was unable to provide the service."
	"Error","0x80240002","WU_E_MAX_CAPACITY_REACHED","The maximum capacity of the service was exceeded."
	"Error","0x80240003","WU_E_UNKNOWN_ID","An ID cannot be found."
	"Error","0x80240004","WU_E_NOT_INITIALIZED","The object could not be initialized."
	"Error","0x80240005","WU_E_RANGEOVERLAP","The update handler requested a byte range that overlaps a previously requested range."
	"Error","0x80240006","WU_E_TOOMANYRANGES","The requested number of byte ranges exceeds the maximum number (2^31 - 1)."
	"Error","0x80240007","WU_E_INVALIDINDEX","The index to a collection was invalid."
	"Error","0x80240008","WU_E_ITEMNOTFOUND","The key for the item queried could not be found."
	"Error","0x80240009","WU_E_OPERATIONINPROGRESS","A conflicting operation was in progress. Some operations (such as installation) cannot be performed simultaneously."
	"Error","0x8024000A","WU_E_COULDNOTCANCEL","Cancellation of the operation was not allowed."
	"Error","0x8024000B","WU_E_CALL_CANCELLED","Operation was cancelled."
	"Error","0x8024000C","WU_E_NOOP","No operation was required."
	"Error","0x8024000D","WU_E_XML_MISSINGDATA","Windows Update Agent could not find the required information in the updateÂ´s XML data."
	"Error","0x8024000E","WU_E_XML_INVALID","Windows Update Agent found invalid information in the updateÂ´s XML data."
	"Error","0x8024000F","WU_E_CYCLE_DETECTED","Circular update relationships were detected in the metadata."
	"Error","0x80240010","WU_E_TOO_DEEP_RELATION","Update relationships that are too deep were evaluated."
	"Error","0x80240011","WU_E_INVALID_RELATIONSHIP","An invalid update relationship was detected."
	"Error","0x80240012","WU_E_REG_VALUE_INVALID","An invalid registry value was read."
	"Error","0x80240013","WU_E_DUPLICATE_ITEM","Operation tried to add a duplicate item to a list."
	"Error","0x80240016","WU_E_INSTALL_NOT_ALLOWED","Operation tried to install while another installation was in progress or the system was pending a mandatory restart."
	"Error","0x80240017","WU_E_NOT_APPLICABLE","Operation was not performed because there are no applicable updates."
	"Error","0x80240018","WU_E_NO_USERTOKEN","Operation failed because a required user token is missing."
	"Error","0x80240019","WU_E_EXCLUSIVE_INSTALL_CONFLICT","An exclusive update cannot be installed with other updates at the same time."
	"Error","0x8024001A","WU_E_POLICY_NOT_SET","A policy value was not set."
	"Error","0x8024001B","WU_E_SELFUPDATE_IN_PROGRESS","The operation could not be performed because the Windows Update Agent is self-updating."
	"Error","0x8024001D","WU_E_INVALID_UPDATE","An update contains invalid metadata."
	"Error","0x8024001E","WU_E_SERVICE_STOP","Operation did not complete because the service or system was being shut down."
	"Error","0x8024001F","WU_E_NO_CONNECTION","Operation did not complete because the network connection was unavailable."
	"Error","0x80240020","WU_E_NO_INTERACTIVE_USER","Operation did not complete because there is no logged-on interactive user."
	"Error","0x80240021","WU_E_TIME_OUT","Operation did not complete because it timed out."
	"Error","0x80240022","WU_E_ALL_UPDATES_FAILED","Operation failed for all the updates."
	"Error","0x80240023","WU_E_EULAS_DECLINED","The license terms for all updates were declined."
	"Error","0x80240024","WU_E_NO_UPDATE","There are no updates."
	"Error","0x80240025","WU_E_USER_ACCESS_DISABLED","Group Policy settings prevented access to Windows Update."
	"Error","0x80240026","WU_E_INVALID_UPDATE_TYPE","The type of update is invalid."
	"Error","0x80240027","WU_E_URL_TOO_LONG","The URL exceeded the maximum length."
	"Error","0x80240028","WU_E_UNINSTALL_NOT_ALLOWED","The update could not be uninstalled because the request did not originate from a WSUS server."
	"Error","0x80240029","WU_E_INVALID_PRODUCT_LICENSE","Search may have missed some updates before there is an unlicensed application on the system."
	"Error","0x8024002A","WU_E_MISSING_HANDLER","A component that is required to detect applicable updates was missing."
	"Error","0x8024002B","WU_E_LEGACYSERVER","An operation did not complete because it requires a newer version of server software."
	"Error","0x8024002C","WU_E_BIN_SOURCE_ABSENT","A delta-compressed update could not be installed because it required the source."
	"Error","0x8024002D","WU_E_SOURCE_ABSENT","A full-file update could not be installed because it required the source."
	"Error","0x8024002E","WU_E_WU_DISABLED","Access to an unmanaged server is not allowed."
	"Error","0x8024002F","WU_E_CALL_CANCELLED_BY_POLICY","Operation did not complete because the DisableWindowsUpdateAccess policy was set."
	"Error","0x80240030","WU_E_INVALID_PROXY_SERVER","The format of the proxy list was invalid."
	"Error","0x80240031","WU_E_INVALID_FILE","The file is in the wrong format."
	"Error","0x80240032","WU_E_INVALID_CRITERIA","The search criteria string was invalid."
	"Error","0x80240033","WU_E_EULA_UNAVAILABLE","License terms could not be downloaded."
	"Error","0x80240034","WU_E_DOWNLOAD_FAILED","Update failed to download."
	"Error","0x80240035","WU_E_UPDATE_NOT_PROCESSED","The update was not processed."
	"Error","0x80240036","WU_E_INVALID_OPERATION","The objectÂ´s current state did not allow the operation."
	"Error","0x80240037","WU_E_NOT_SUPPORTED","The functionality for the operation is not supported."
	"Error","0x80240038","WU_E_WINHTTP_INVALID_FILE","The downloaded file has an unexpected content type."
	"Error","0x80240039","WU_E_TOO_MANY_RESYNC","The agent was asked by server to synchronize too many times."
	"Error","0x80240040","WU_E_NO_SERVER_CORE_SUPPORT","WUA API method does not run on a Server Core installation option of the Windows 2008 R2 operating system."
	"Error","0x80240041","WU_E_SYSPREP_IN_PROGRESS","Service is not available when sysprep is running."
	"Error","0x80240042","WU_E_UNKNOWN_SERVICE","The update service is no longer registered with Automatic Updates."
	"Error","0x80240FFF","WU_E_UNEXPECTED","An operation failed due to reasons not covered by another error code."
	"Error","0x80241001","WU_E_MSI_WRONG_VERSION","Search may have missed some updates because Windows Installer is less than version 3.1."
	"Error","0x80241002","WU_E_MSI_NOT_CONFIGURED","Search may have missed some updates because Windows Installer is not configured."
	"Error","0x80241003","WU_E_MSP_DISABLED","Search may have missed some updates because a policy setting disabled Windows Installer patching."
	"Error","0x80241004","WU_E_MSI_WRONG_APP_CONTEXT","An update could not be applied because the application is installed per-user."
	"Error","0x80241FFF","WU_E_MSP_UNEXPECTED","Search may have missed some updates because there was a failure of Windows Installer."
	"Error","0x80242000","WU_E_UH_REMOTEUNAVAILABLE","A request for a remote update handler could not be completed because no remote process is available."
	"Error","0x80242001","WU_E_UH_LOCALONLY","A request for a remote update handler could not be completed because the handler is local only."
	"Error","0x80242002","WU_E_UH_UNKNOWNHANDLER","A request for an update handler could not be completed because the handler could not be recognized."
	"Error","0x80242003","WU_E_UH_REMOTEALREADYACTIVE","A remote update handler could not be created because one already exists."
	"Error","0x80242004","WU_E_UH_DOESNOTSUPPORTACTION","A request for the handler to install (uninstall) an update could not be completed because the update does not support install (uninstall)."
	"Error","0x80242005","WU_E_UH_WRONGHANDLER","An operation did not complete because the wrong handler was specified."
	"Error","0x80242006","WU_E_UH_INVALIDMETADATA","A handler operation could not be completed because the update contains invalid metadata."
	"Error","0x80242007","WU_E_UH_INSTALLERHUNG","An operation could not be completed because the installer exceeded the time limit."
	"Error","0x80242008","WU_E_UH_OPERATIONCANCELLED","An operation being done by the update handler was cancelled."
	"Error","0x80242009","WU_E_UH_BADHANDLERXML","An operation could not be completed because the handler-specific metadata is invalid."
	"Error","0x8024200A","WU_E_UH_CANREQUIREINPUT","A request to the handler to install an update could not be completed because the update requires user input."
	"Error","0x8024200B","WU_E_UH_INSTALLERFAILURE","The installer failed to install (uninstall) one or more updates."
	"Error","0x8024200C","WU_E_UH_FALLBACKTOSELFCONTAINED","The update handler should download self-contained content rather than delta-compressed content for the update."
	"Error","0x8024200D","WU_E_UH_NEEDANOTHERDOWNLOAD","The update handler did not install the update because the update needs to be downloaded again."
	"Error","0x8024200E","WU_E_UH_NOTIFYFAILURE","The update handler failed to send notification of the status of the install (uninstall) operation."
	"Error","0x8024200F","WU_E_UH_INCONSISTENT_FILE_NAMES","The file names in the update metadata are inconsistent with the file names in the update package."
	"Error","0x80242010","WU_E_UH_FALLBACKERROR","The update handler failed to fall back to the self-contained content."
	"Error","0x80242011","WU_E_UH_TOOMANYDOWNLOADREQUESTS","The update handler has exceeded the maximum number of download requests."
	"Error","0x80242012","WU_E_UH_UNEXPECTEDCBSRESPONSE","The update handler has received an unexpected response from CBS."
	"Error","0x80242013","WU_E_UH_BADCBSPACKAGEID","The update metadata contains an invalid CBS package identifier."
	"Error","0x80242014","WU_E_UH_POSTREBOOTSTILLPENDING","The post-reboot operation for the update is still in progress."
	"Error","0x80242015","WU_E_UH_POSTREBOOTRESULTUNKNOWN","The result of the post-reboot operation for the update could not be determined."
	"Error","0x80242016","WU_E_UH_POSTREBOOTUNEXPECTEDSTATE","The state of the update after its post-reboot operation has completed is unexpectedly."
	"Error","0x80242017","WU_E_UH_NEW_SERVICING_STACK_REQUIRED","The operating system servicing stack must be updated before this update is downloaded or installed."
	"Error","0x80242FFF","WU_E_UH_UNEXPECTED","This update handler error is not covered by another WU_E_UH_* code."
	"Error","0x80243001","WU_E_INSTALLATION_RESULTS_UNKNOWN_VERSION","The results of the download and installation could not be read in the registry due to an unrecognized data format version."
	"Error","0x80243002","WU_E_INSTALLATION_RESULTS_INVALID_DATA","The results of download and installation could not be read in the registry due to an invalid data format."
	"Error","0x80243003","WU_E_INSTALLATION_RESULTS_NOT_FOUND","The results of download and installation are not available; the operation may have failed to start."
	"Error","0x80243004","WU_E_TRAYICON_FAILURE","A failure occurred when trying to create an icon in the notification area."
	"Error","0x80243FFD","WU_E_NON_UI_MODE","Unable to show the user interface (UI) when in a non-UI mode; Windows Update (WU) client UI modules may not be installed."
	"Error","0x80243FFE","WU_E_WUCLTUI_UNSUPPORTED_VERSION","Unsupported version of WU client UI exported functions."
	"Error","0x80243FFF","WU_E_AUCLIENT_UNEXPECTED","There was a user interface error not covered by another WU_E_AUCLIENT_* error code."
	"Error","0x80244000","WU_E_PT_SOAPCLIENT_BASE","WU_E_PT_SOAPCLIENT_* error codes map to the SOAPCLIENT_ERROR enum of the ATL Server Library."
	"Error","0x80244001","WU_E_PT_SOAPCLIENT_INITIALIZE","Initialization of the SOAP client failed, possibly because of an MSXML installation failure."
	"Error","0x80244002","WU_E_PT_SOAPCLIENT_OUTOFMEMORY","SOAP client failed because it ran out of memory."
	"Error","0x80244003","WU_E_PT_SOAPCLIENT_GENERATE","SOAP client failed to generate the request."
	"Error","0x80244004","WU_E_PT_SOAPCLIENT_CONNECT","SOAP client failed to connect to the server."
	"Error","0x80244005","WU_E_PT_SOAPCLIENT_SEND","SOAP client failed to send a message due to WU_E_WINHTTP_* error codes."
	"Error","0x80244006","WU_E_PT_SOAPCLIENT_SERVER","SOAP client failed because there was a server error."
	"Error","0x80244007","WU_E_PT_SOAPCLIENT_SOAPFAULT","SOAP client failed because there was a SOAP fault due to WU_E_PT_SOAP_* error codes."
	"Error","0x80244008","WU_E_PT_SOAPCLIENT_PARSEFAULT","SOAP client failed to parse a SOAP fault."
	"Error","0x80244009","WU_E_PT_SOAPCLIENT_READ","SOAP client failed while reading the response from the server."
	"Error","0x8024400A","WU_E_PT_SOAPCLIENT_PARSE","SOAP client failed to parse the response from the server."
	"Error","0x8024400B","WU_E_PT_SOAP_VERSION","SOAP client found an unrecognizable namespace for the SOAP envelope."
	"Error","0x8024400C","WU_E_PT_SOAP_MUST_UNDERSTAND","SOAP client was unable to understand a header."
	"Error","0x8024400D","WU_E_PT_SOAP_CLIENT","SOAP client found the message was malformed (fix before resending)."
	"Error","0x8024400E","WU_E_PT_SOAP_SERVER","The SOAP message could not be processed due to a server error (resend later)."
	"Error","0x8024400F","WU_E_PT_WMI_ERROR","There was an unspecified Windows Management Instrumentation (WMI) error."
	"Error","0x80244010","WU_E_PT_EXCEEDED_MAX_SERVER_TRIPS","The number of round trips to the server exceeded the maximum limit."
	"Error","0x80244011","WU_E_PT_SUS_SERVER_NOT_SET","WUServer policy value is missing in the registry."
	"Error","0x80244012","WU_E_PT_DOUBLE_INITIALIZATION","Initialization failed because the object was already initialized."
	"Error","0x80244013","WU_E_PT_INVALID_COMPUTER_NAME","The computer name could not be determined."
	"Error","0x80244015","WU_E_PT_REFRESH_CACHE_REQUIRED","The reply from the server indicates that the server was changed or the cookie was invalid; refresh the state of the internal cache and retry."
	"Error","0x80244016","WU_E_PT_HTTP_STATUS_BAD_REQUEST","HTTP 400 - the server could not process the request due to invalid syntax."
	"Error","0x80244017","WU_E_PT_HTTP_STATUS_DENIED","HTTP 401 - the requested resource requires user authentication."
	"Error","0x80244018","WU_E_PT_HTTP_STATUS_FORBIDDEN","HTTP 403 - server understood the request, but declined to fulfill it."
	"Error","0x80244019","WU_E_PT_HTTP_STATUS_NOT_FOUND","HTTP 404 - the server cannot find the requested Uniform Resource Identifier (URI)."
	"Error","0x8024401A","WU_E_PT_HTTP_STATUS_BAD_METHOD","HTTP 405 - the HTTP method is not allowed."
	"Error","0x8024401B","WU_E_PT_HTTP_STATUS_PROXY_AUTH_REQ","HTTP 407 - proxy authentication is required."
	"Error","0x8024401C","WU_E_PT_HTTP_STATUS_REQUEST_TIMEOUT","HTTP 408 - the server timed out waiting for the request."
	"Error","0x8024401D","WU_E_PT_HTTP_STATUS_CONFLICT","HTTP 409 - the request was not completed due to a conflict with the current state of the resource."
	"Error","0x8024401E","WU_E_PT_HTTP_STATUS_GONE","HTTP 410 - the requested resource is no longer available at the server."
	"Error","0x8024401F","WU_E_PT_HTTP_STATUS_SERVER_ERROR","HTTP 500 - an error internal to the server prevented fulfilling the request."
	"Error","0x80244020","WU_E_PT_HTTP_STATUS_NOT_SUPPORTED","HTTP 501 - server does not support the functionality that is required to fulfill the request."
	"Error","0x80244021","WU_E_PT_HTTP_STATUS_BAD_GATEWAY","HTTP 502 - the server, while acting as a gateway or proxy, received an invalid response from the upstream server it accessed when attempting to fulfill the request."
	"Error","0x80244022","WU_E_PT_HTTP_STATUS_SERVICE_UNAVAIL","HTTP 503 - the service is temporarily overloaded."
	"Error","0x80244023","WU_E_PT_HTTP_STATUS_GATEWAY_TIMEOUT","HTTP 504 - the request was timed out waiting for a gateway."
	"Error","0x80244024","WU_E_PT_HTTP_STATUS_VERSION_NOT_SUP","HTTP 505 - the server does not support the HTTP protocol version used for the request."
	"Error","0x80244025","WU_E_PT_FILE_LOCATIONS_CHANGED","Operation failed due to a changed file location; refresh internal state and resend."
	"Error","0x80244026","WU_E_PT_REGISTRATION_NOT_SUPPORTED","Operation failed because Windows Update Agent does not support registration with a non-WSUS server."
	"Error","0x80244027","WU_E_PT_NO_AUTH_PLUGINS_REQUESTED","The server returned an empty authentication information list."
	"Error","0x80244028","WU_E_PT_NO_AUTH_COOKIES_CREATED","Windows Update Agent was unable to create any valid authentication cookies."
	"Error","0x80244029","WU_E_PT_INVALID_CONFIG_PROP","A configuration property value was wrong."
	"Error","0x8024402A","WU_E_PT_CONFIG_PROP_MISSING","A configuration property value was missing."
	"Error","0x8024402B","WU_E_PT_HTTP_STATUS_NOT_MAPPED","The HTTP request could not be completed and the reason did not correspond to any of the WU_E_PT_HTTP_* error codes."
	"Error","0x8024402C","WU_E_PT_WINHTTP_NAME_NOT_RESOLVED","The proxy server or target server name cannot be resolved."
	"Error","0x8024402F","WU_E_PT_ECP_SUCCEEDED_WITH_ERRORS","External .cab file processing completed with some errors."
	"Error","0x80244030","WU_E_PT_ECP_INIT_FAILED","The external .cab file processor initialization did not complete."
	"Error","0x80244031","WU_E_PT_ECP_INVALID_FILE_FORMAT","The format of a metadata file was invalid."
	"Error","0x80244032","WU_E_PT_ECP_INVALID_METADATA","External .cab file processor found invalid metadata."
	"Error","0x80244033","WU_E_PT_ECP_FAILURE_TO_EXTRACT_DIGEST","The file digest could not be extracted from an external .cab file."
	"Error","0x80244034","WU_E_PT_ECP_FAILURE_TO_DECOMPRESS_CAB_FILE","An external .cab file could not be decompressed."
	"Error","0x80244035","WU_E_PT_ECP_FILE_LOCATION_ERROR","External .cab processor was unable to get file locations."
	"Error","0x80244FFF","WU_E_PT_UNEXPECTED","There was a communication error not covered by another WU_E_PT_* error code"
	"Error","0x80245001","WU_E_REDIRECTOR_LOAD_XML","The redirector XML document could not be loaded into the Document Object Model (DOM) class."
	"Error","0x80245002","WU_E_REDIRECTOR_S_FALSE","The redirector XML document is missing some required information."
	"Error","0x80245003","WU_E_REDIRECTOR_ID_SMALLER","The redirector ID in the downloaded redirector .cab file is less than in the cached .cab file."
	"Error","0x8024502D","WU_E_PT_SAME_REDIR_ID","Windows Update Agent failed to download a redirector .cab file with a new redirector ID value from the server during the recovery."
	"Error","0x8024502E","WU_E_PT_NO_MANAGED_RECOVER","A redirector recovery action did not complete because the server is managed."
	"Error","0x80245FFF","WU_E_REDIRECTOR_UNEXPECTED","The redirector failed for reasons not covered by another WU_E_REDIRECTOR_* error code."
	"Error","0x80246001","WU_E_DM_URLNOTAVAILABLE","A download manager operation could not be completed because the requested file does not have a URL."
	"Error","0x80246002","WU_E_DM_INCORRECTFILEHASH","A download manager operation could not be completed because the file digest was not recognized."
	"Error","0x80246003","WU_E_DM_UNKNOWNALGORITHM","A download manager operation could not be completed because the file metadata requested an unrecognized hash algorithm."
	"Error","0x80246004","WU_E_DM_NEEDDOWNLOADREQUEST","An operation could not be completed because a download request is required from the download handler."
	"Error","0x80246005","WU_E_DM_NONETWORK","A download manager operation could not be completed because the network connection was unavailable."
	"Error","0x80246006","WU_E_DM_WRONGBITSVERSION","A download manager operation could not be completed because the version of Background Intelligent Transfer Service (BITS) is incompatible."
	"Error","0x80246007","WU_E_DM_NOTDOWNLOADED","The update has not been downloaded."
	"Error","0x80246008","WU_E_DM_FAILTOCONNECTTOBITS","A download manager operation failed because the download manager was unable to connect the Background Intelligent Transfer Service (BITS)."
	"Error","0x80246009","WU_E_DM_BITSTRANSFERERROR","A download manager operation failed because there was an unspecified Background Intelligent Transfer Service (BITS) transfer error."
	"Error","0x8024600a","WU_E_DM_DOWNLOADLOCATIONCHANGED","A download must be restarted because the location of the source of the download has changed."
	"Error","0x8024600B","WU_E_DM_CONTENTCHANGED","A download must be restarted because the update content changed in a new revision."
	"Error","0x80246FFF","WU_E_DM_UNEXPECTED","There was a download manager error not covered by another WU_E_DM_* error code."
	"Error","0x80247001","WU_E_OL_INVALID_SCANFILE","An operation could not be completed because the scan package was invalid."
	"Error","0x80247002","WU_E_OL_NEWCLIENT_REQUIRED","An operation could not be completed because the scan package requires a greater version of the Windows Update Agent."
	"Error","0x80247FFF","WU_E_OL_UNEXPECTED","Search using the scan package failed."
	"Error","0x80248000","WU_E_DS_SHUTDOWN","An operation failed because Windows Update Agent is shutting down."
	"Error","0x80248001","WU_E_DS_INUSE","An operation failed because the data store was in use."
	"Error","0x80248002","WU_E_DS_INVALID","The current and expected states of the data store do not match."
	"Error","0x80248003","WU_E_DS_TABLEMISSING","The data store is missing a table."
	"Error","0x80248004","WU_E_DS_TABLEINCORRECT","The data store contains a table with unexpected columns."
	"Error","0x80248005","WU_E_DS_INVALIDTABLENAME","A table could not be opened because the table is not in the data store."
	"Error","0x80248006","WU_E_DS_BADVERSION","The current and expected versions of the data store do not match."
	"Error","0x80248007","WU_E_DS_NODATA","The information requested is not in the data store."
	"Error","0x80248008","WU_E_DS_MISSINGDATA","The data store is missing required information or has a null value in a table column that requires a non-null value."
	"Error","0x80248009","WU_E_DS_MISSINGREF","The data store is missing required information or has a reference to missing license terms, a file, a localized property, or a linked row."
	"Error","0x8024800A","WU_E_DS_UNKNOWNHANDLER","The update was not processed because its update handler could not be recognized."
	"Error","0x8024800B","WU_E_DS_CANTDELETE","The update was not deleted because it is still referenced by one or more services."
	"Error","0x8024800C","WU_E_DS_LOCKTIMEOUTEXPIRED","The data store section could not be locked within the allotted time."
	"Error","0x8024800D","WU_E_DS_NOCATEGORIES","The category was not added because it contains no parent categories, and it is not a top-level category."
	"Error","0x8024800E","WU_E_DS_ROWEXISTS","The row was not added because an existing row has the same primary key."
	"Error","0x8024800F","WU_E_DS_STOREFILELOCKED","The data store could not be initialized because it was locked by another process."
	"Error","0x80248010","WU_E_DS_CANNOTREGISTER","The data store is not allowed to be registered with COM in the current process."
	"Error","0x80248011","WU_E_DS_UNABLETOSTART","Could not create a data store object in another process."
	"Error","0x80248013","WU_E_DS_DUPLICATEUPDATEID","The server sent the same update to the client computer, with two different revision IDs."
	"Error","0x80248014","WU_E_DS_UNKNOWNSERVICE","An operation did not complete because the service is not in the data store."
	"Error","0x80248015","WU_E_DS_SERVICEEXPIRED","An operation did not complete because the registration of the service has expired."
	"Error","0x80248016","WU_E_DS_DECLINENOTALLOWED","A request to hide an update was declined because it is a mandatory update or because it was deployed with a deadline."
	"Error","0x80248017","WU_E_DS_TABLESESSIONMISMATCH","A table was not closed because it is not associated with the session."
	"Error","0x80248018","WU_E_DS_SESSIONLOCKMISMATCH","A table was not closed because it is not associated with the session."
	"Error","0x80248019","WU_E_DS_NEEDWINDOWSSERVICE","A request to remove the Windows Update service or to unregister it with Automatic Updates was declined because it is a built-in service and Automatic Updates cannot fall back to another service."
	"Error","0x8024801A","WU_E_DS_INVALIDOPERATION","A request was declined because the operation is not allowed."
	"Error","0x8024801B","WU_E_DS_SCHEMAMISMATCH","The schema of the current data store and the schema of a table in a backup XML document do not match."
	"Error","0x8024801C","WU_E_DS_RESETREQUIRED","The data store requires a session reset; release the session and retry with a new session."
	"Error","0x8024801D","WU_E_DS_IMPERSONATED","A data store operation did not complete because it was requested with an impersonated identity."
	"Error","0x80248FFF","WU_E_DS_UNEXPECTED","There was a data store error not covered by another WU_E_DS_* code."
	"Error","0x80249001","WU_E_INVENTORY_PARSEFAILED","Parsing of the rule file failed."
	"Error","0x80249002","WU_E_INVENTORY_GET_INVENTORY_TYPE_FAILED","Failed to get the requested inventory type from the server."
	"Error","0x80249003","WU_E_INVENTORY_RESULT_UPLOAD_FAILED","Failed to upload inventory result to the server."
	"Error","0x80249004","WU_E_INVENTORY_UNEXPECTED","There was an inventory error not covered by another error code."
	"Error","0x80249005","WU_E_INVENTORY_WMI_ERROR","A WMI error occurred when enumerating the instances for a particular class."
	"Error","0x8024A000","WU_E_AU_NOSERVICE","Automatic Updates was unable to service incoming requests."
	"Error","0x8024A002","WU_E_AU_NONLEGACYSERVER","The old version of Automatic Updates has stopped because the WSUS server has been upgraded."
	"Error","0x8024A003","WU_E_AU_LEGACYCLIENTDISABLED","The old version of Automatic Updates was disabled."
	"Error","0x8024A004","WU_E_AU_PAUSED","Automatic Updates was unable to process incoming requests because it was paused."
	"Error","0x8024A005","WU_E_AU_NO_REGISTERED_SERVICE","No unmanaged service is registered with AU."
	"Error","0x8024AFFF","WU_E_AU_UNEXPECTED","There was an Automatic Updates error not covered by another WU_E_AU * code."
	"Error","0x8024C001","WU_E_DRV_PRUNED","A driver was skipped."
	"Error","0x8024C002","WU_E_DRV_NOPROP_OR_LEGACY","A property for the driver could not be found. It may not conform with required specifications."
	"Error","0x8024C003","WU_E_DRV_REG_MISMATCH","The registry type read for the driver does not match the expected type."
	"Error","0x8024C004","WU_E_DRV_NO_METADATA","The driver update is missing metadata."
	"Error","0x8024C005","WU_E_DRV_MISSING_ATTRIBUTE","The driver update is missing a required attribute."
	"Error","0x8024C006","WU_E_DRV_SYNC_FAILED","Driver synchronization failed."
	"Error","0x8024C007","WU_E_DRV_NO_PRINTER_CONTENT","Information required for the synchronization of applicable printers is missing."
	"Error","0x8024CFFF","WU_E_DRV_UNEXPECTED","There was a driver error not covered by another WU_E_DRV_* code."
	"Error","0x8024D001","WU_E_SETUP_INVALID_INFDATA","Windows Update Agent could not be updated because an .inf file contains invalid information."
	"Error","0x8024D002","WU_E_SETUP_INVALID_IDENTDATA","Windows Update Agent could not be updated because the wuident.cab file contains invalid information."
	"Error","0x8024D003","WU_E_SETUP_ALREADY_INITIALIZED","Windows Update Agent could not be updated because of an internal error that caused setup initialization to be performed twice."
	"Error","0x8024D004","WU_E_SETUP_NOT_INITIALIZED","Windows Update Agent could not be updated because setup initialization never completed successfully."
	"Error","0x8024D005","WU_E_SETUP_SOURCE_VERSION_MISMATCH","Windows Update Agent could not be updated because the versions specified in the .inf file do not match the actual source file versions."
	"Error","0x8024D006","WU_E_SETUP_TARGET_VERSION_GREATER","Windows Update Agent could not be updated because a Windows Update Agent file on the target system is newer than the corresponding source file."
	"Error","0x8024D007","WU_E_SETUP_REGISTRATION_FAILED","Windows Update Agent could not be updated because regsvr32.exe returned an error."
	"Error","0x8024D008","WU_E_SELFUPDATE_SKIP_ON_FAILURE","An update to the Windows Update Agent was skipped because previous attempts to update failed."
	"Error","0x8024D009","WU_E_SETUP_SKIP_UPDATE","An update to the Windows Update Agent was skipped due to a directive in the wuident.cab file."
	"Error","0x8024D00A","WU_E_SETUP_UNSUPPORTED_CONFIGURATION","Windows Update Agent could not be updated because the current system configuration is not supported."
	"Error","0x8024D00B","WU_E_SETUP_BLOCKED_CONFIGURATION","Windows Update Agent could not be updated because the system is configured to block the update."
	"Error","0x8024D00C","WU_E_SETUP_REBOOT_TO_FIX","Windows Update Agent could not be updated because a restart of the system is required."
	"Error","0x8024D00D","WU_E_SETUP_ALREADYRUNNING","Windows Update Agent setup is already running."
	"Error","0x8024D00E","WU_E_SETUP_REBOOTREQUIRED","Windows Update Agent setup package requires a reboot to complete installation."
	"Error","0x8024D00F","WU_E_SETUP_HANDLER_EXEC_FAILURE","Windows Update Agent could not be updated because the setup handler failed when it was run."
	"Error","0x8024D010","WU_E_SETUP_INVALID_REGISTRY_DATA","Windows Update Agent could not be updated because the registry contains invalid information."
	"Error","0x8024D011","WU_E_SELFUPDATE_REQUIRED","Windows Update Agent must be updated before search can continue."
	"Error","0x8024D012","WU_E_SELFUPDATE_REQUIRED_ADMIN","Windows Update Agent must be updated before search can continue. An administrator is required to perform the operation."
	"Error","0x8024D013","WU_E_SETUP_WRONG_SERVER_VERSION","Windows Update Agent could not be updated because the server does not contain update information for this version."
	"Error","0x8024DFFF","WU_E_SETUP_UNEXPECTED","Windows Update Agent could not be updated because of an error not covered by another WU_E_SETUP_* error code."
	"Error","0x8024E001","WU_E_EE_UNKNOWN_EXPRESSION","An expression evaluator operation could not be completed because an expression was unrecognized."
	"Error","0x8024E002","WU_E_EE_INVALID_EXPRESSION","An expression evaluator operation could not be completed because an expression was invalid."
	"Error","0x8024E003","WU_E_EE_MISSING_METADATA","An expression evaluator operation could not be completed because an expression contains an incorrect number of metadata nodes."
	"Error","0x8024E004","WU_E_EE_INVALID_VERSION","An expression evaluator operation could not be completed because the version of the serialized expression data is invalid."
	"Error","0x8024E005","WU_E_EE_NOT_INITIALIZED","The expression evaluator could not be initialized."
	"Error","0x8024E006","WU_E_EE_INVALID_ATTRIBUTEDATA","An expression evaluator operation could not be completed because there was an invalid attribute."
	"Error","0x8024E007","WU_E_EE_CLUSTER_ERROR","An expression evaluator operation could not be completed because the cluster state of the computer could not be determined."
	"Error","0x8024EFFF","WU_E_EE_UNEXPECTED","There was an expression evaluator error not covered by another WU_E_EE_* error code."
	"Error","0x8024F001","WU_E_REPORTER_EVENTCACHECORRUPT","The event cache file was defective."
	"Error","0x8024F002","WU_E_REPORTER_EVENTNAMESPACEPARSEFAILED","The XML in the event namespace descriptor could not be parsed."
	"Error","0x8024F003","WU_E_INVALID_EVENT","The XML in the event namespace descriptor could not be parsed."
	"Error","0x8024F004","WU_E_SERVER_BUSY","The server rejected an event because the server was too busy."
'@
	$Script:BL_WUA_RESULT_CODES = $WuaCsv | ConvertFrom-Csv | Select Type, @{Name="ResultCode"; Expression={[int]$_.ResultCode.Trim('"')}}, ResultString, Description
}

Function Install-BLWindowsHotfix {
## Old name: SCCM:Install-Ws2k8Hotfix
## Notes:
## - wusa.exe uses the (legacy) Windows Event Log binary format, not text.
## - "-LogFile" supports the extensions .evt, .csv, .log; for the two latter, an automatic conversion of evt to text will be done and the .evt and .evt.dpx files will be deleted.
## - To convert the .evt format into evtx (or a text format), you can use the function "ConvertFrom-BLEvt"
## - For uninstallation, the wrapper function Uninstall-BLWindowsHotfix (instead of "Install-BLWindowsHotfix -Uninstall") is available.
[CmdletBinding(DefaultParameterSetName="Install")]
Param(
	[Parameter(Position=0, ParameterSetName="Install")]
	[Parameter(Position=0, ParameterSetName="Uninstall_By_File")]
	[string]$MsuFile = "",
	[Parameter(Position=0, ParameterSetName="Uninstall_By_KB")]
	[string]$MsuKB = "",
	[Parameter(Position=1)]
	[string]$LogFile = "",
	[Parameter(ParameterSetName="Uninstall_By_File")]
	[Parameter(ParameterSetName="Uninstall_By_KB")]
	[switch]$Uninstall
)
	$wusaCmd = "wusa.exe"
	If ($PsCmdlet.ParameterSetName -eq "Install") {
		If ([string]::IsNullOrEmpty($MsuFile)) {
			"No msu file specified." | Write-BLLog -LogType CriticalError
			Return 1
		}
		If (Test-Path $MsuFile) {
			$wusaArguments = "`"$($MsuFile)`" "
		} Else {
			"File not found: '$($MsuFile)!" | Write-BLLog -LogType CriticalError
			Return 1
		}
		$wusaArguments = "`"$($MsuFile)`" "
	} Else {
		$wusaArguments = "/uninstall "
		If ((-Not [string]::IsNullOrEmpty($MsuFile)) -And (-Not [string]::IsNullOrEmpty($MsuKB))) {
			"Only one of '-MsuFile' or '-MsuKB' may be specified!" | Write-BLLog -LogType CriticalError
			Return 1
		}
		If ([string]::IsNullOrEmpty($MsuFile) -And [string]::IsNullOrEmpty($MsuKB)) {
			"Either '-MsuFile' or '-MsuKB' must be specified!" | Write-BLLog -LogType CriticalError
			Return 1
		}
		If (-Not [string]::IsNullOrEmpty($MsuKB)) {
			If ($MsuKB -Match '^\d{6,7}$') {
				$wusaArguments = $wusaArguments + "/kb:$($MsuKB) "
			} Else {
				"Argument -MsuKB has an incorrect format: '$($MsuKB)', expected are 6 or 7 digits!" | Write-BLLog -LogType CriticalError
				Return 1
			}
		} Else {
			If (Test-Path -Path $MsuFile) {
				$wusaArguments = $wusaArguments + "`"$($MsuFile)`" "
			} Else {
				"File not found: '$($MsuFile)!" | Write-BLLog -LogType CriticalError
				Return 1
			}
		}
	}
	$wusaArguments = $wusaArguments + "/quiet /norestart"
	If (-Not [string]::IsNullOrEmpty($LogFile)) {
		$LogFolder = Split-Path -Path $LogFile -Parent
		If (-Not (Get-Item -Path $LogFolder)) {
			"Log folder not found: '$($LogFolder)!" | Write-BLLog -LogType CriticalError
			Return 1
		}
		If ((-Not $LogFile.ToLower().EndsWith(".evt")) -And (-Not $LogFile.ToLower().EndsWith(".log")) -And (-Not $LogFile.ToLower().EndsWith(".csv"))) {
			"Log file format not supported: '$(Split-Path -Path $LogFile -Leaf)'; allowed: .evt, .csv, .log!" | Write-BLLog -LogType CriticalError
			Return 1
		}
		If (-Not $LogFile.ToLower().EndsWith(".evt")) {
			$LogFile += ".tmp"
			If (Test-Path $LogFile) {
				Remove-Item -Path $LogFile -Force
			}
		}
		$wusaArguments = $wusaArguments + " /log:`"$($LogFile)`""
	}
	
	"Invoking: $wusaCmd $wusaArguments" | Write-BLLog
	$StartTime = Get-Date
	$exitCode = Start-BLProcess -FileName $wusaCmd -Arguments $wusaArguments

	If (-Not [string]::IsNullOrEmpty($LogFile)) {
		$LogFileItem = Get-Item -Path $LogFile -ErrorAction SilentlyContinue
		If (-Not $LogFileItem) {
			"Log file was not written!" | Write-BLLog -LogType CriticalError
		} Else {
			If ($LogFileItem.Extension -eq ".tmp") {
				## Restore the LogFile name to the original name; $LogFileItem still refers to the .tmp file.
				$LogFile = Join-Path -Path $LogFileItem.DirectoryName $LogFileItem.BaseName
				$Log = ConvertFrom-BLEvt -Path $LogFileItem.FullName -NoProgress
				Switch ($LogFileItem.BaseName.ToLower().SubString($LogFileItem.BaseName.Length - 4, 4)) {
					".log" {
						$Content = @("{0,-11}`t{1}`t{2}" -f "Information", (Get-Date -Date $StartTime -Format "yyyyMMdd-HHmmss"), "===== Appended content follows ======================================================================")
						$Content += $Log | 
							Select-Object `
								@{Name="Level"; Expression={$_.RI_Level}},
								@{Name="Time"; Expression={Get-Date $_.TimeCreated -Format "yyyyMMdd-HHmmss"}},
								@{Name="Message"; Expression={$_.RI_Message}} |
							% {"{0,-11}`t{1}`t{2}" -f $_.Level, $_.Time, $_.Message}
						$Content | Out-File -FilePath $LogFile -Encoding UTF8 -Append -Force
					}
					".csv" {
						$AppendDate = Get-Date -Date $StartTime -Format "dd.MM.yyyy"
						$AppendTime = Get-Date -Date $StartTime -Format "HH:mm:ss"
						$Content = $Log |
							Select-Object `
								@{Name="AppendDate"; Expression={$AppendDate}},
								@{Name="AppendTime"; Expression={$AppendTime}},
								@{Name="Level"; Expression={$_.RI_Level}},
								@{Name="Date"; Expression={Get-Date -Date $_.TimeCreated -Format "dd.MM.yyyy"}},
								@{Name="Time"; Expression={Get-Date -Date $_.TimeCreated -Format "HH:mm:ss"}},
								@{Name="Message"; Expression={$_.RI_Message}}
						$Content | Export-Csv -Path $LogFile -Encoding UTF8 -Append -Force -NoTypeInformation
					}
				}
				Remove-Item -Path $LogFileItem.Fullname -Force
				If (Test-Path "$($LogFileItem.Fullname).dpx") {
					Remove-Item -Path "$($LogFileItem.Fullname).dpx" -Force
				}
			}
		}
	}
#	## wusa.exe will return its own error codes in addition to some default error codes that can be obtained using "net helpmsg"
	If ($exitCode -ne 0) {
		If ($WuaResult = ($BL_WUA_RESULT_CODES | Where {$_.ResultCode -eq $exitCode})) {
			If ($WuaResult.Type -eq "Success") {
					"wusa.exe returned a specific 'success' exit code of '$($ExitCode)' ($($WuaResult.ResultString), '$($WuaResult.Description)')." | Write-BLLog -LogType Warning
				If ($WuaResult.ResultString -eq "WU_S_REBOOT_REQUIRED") {
					$exitCode = 3010
				} Else {
					$exitCode = 0
				}
			} Else {
				"wusa.exe returned a specific 'error' exit code of '$($ExitCode)' ($($WuaResult.ResultString), '$($WuaResult.Description)')." | Write-BLLog -LogType CriticalError
				$exitCode = 0
			}
		} Else {
			If ($ExitCode -eq 3010) {
				$LogType = "Warning"
			} Else {
				$LogType = "CriticalError"
			}
			"wusa.exe returned a default exit code of '$($ExitCode)', '$(([ComponentModel.Win32Exception]$exitCode).Message)'." | Write-BLLog -LogType $LogType
		}
	}
	Return $exitCode
}

Function Install-BLWindowsLanguagePack($LpkID = "", $LpkPath = "") {
## Old name: SCCM:Install-Ws2k8LangPack
## Invoke lpksetup
	$exitCode = 1 # assume failure until proven otherwise
	$lpkSetupCmd = "lpksetup.exe"
	# Check parameters
	If (!($lpkID.Length)) {"No language pack ID specified." | Write-BLLog -LogType CriticalError; return $exitCode}
	If (!($lpkPath.Length)) {"No language pack path specified." | Write-BLLog -LogType CriticalError; return $exitCode}
	# Preparation done. Invoke ServerManagerCmd now
	"Invoking: $lpkSetupCmd /i $lpkID /r /p `"$lpkPath`" /s" | Write-BLLog -LogType Information
	$exitCode = Start-BLProcess -FileName $lpkSetupCmd -Arguments "/i $lpkID /r /p `"$lpkPath`" /s"
	Return $exitCode
}

Function Install-BLWindowsRoleOrFeature($Name = "", $LogName = "", [switch]$Restart) {
## Old name: SCCM:Install-RoleOrFeature
## Invoke ServerManagerCmd
	$exitCode = 1 # assume failure until proven otherwise
	# Check role or feature name
	If (!($name.Length)) {"No role or feature specified." | Write-BLLog -LogType CriticalError; return $exitCode}
	If ($logname -eq "") {$logname = $name.replace(" ","")}
	$logPath = Join-Path $RIS_Logfolder "$logname.log"
	# Preparation done. Invoke ServerManagerCmd now
	Import-Module ServerManager
	"Invoking: Add-Windowsfeature -name $name -logPath $logPath" | Write-BLLog -LogType Information
	If ($restart) {
		$success = Add-Windowsfeature -name $name -logPath $logPath -restart
	} Else {
		$success = Add-Windowsfeature -name $name -logPath $logPath
	}
	If ($success.success -eq "True") {$exitcode = 0}
	Move-BLFileToLog $logPath
	return $exitCode
}

Function Invoke-BLBatchFile($BatFile = "", $BatArgs = "") {
## Old name: SCCM:Invoke-BatchFile
## Execute a Batch File
	$MyName = [string]$($MyInvocation.MyCommand.Name)
	$exitCode = 1 # assume failure until proven otherwise
	# Check batch file.
	If (!($batFile.Length)) {"No batch file specified." | Write-BLLog -LogType CriticalError; return $exitCode}
	If (!(Test-Path $batFile)) {"File not found - $batFile" | Write-BLLog -LogType CriticalError; return $exitCode}
	$cmdShell = $Env:ComSpec
	$cmdLogfile = [IO.Path]::GetTempFileName( )
	# Preparation done. Invoke batch file now
	"Invoking: cmd.exe /C `"$batFile`" $batArgs" | Write-BLLog -LogType Information
	cmd.exe /C " `"$batFile`" $batArgs > `"$cmdLogfile`" 2>&1 "
	$exitCode = $LASTEXITCODE
	"EXIT CODE = $exitCode" | Write-BLLog -LogType Information
	Move-BLFileToLog $cmdLogfile
	return $exitCode
}

Function Invoke-BLPowershell($PsFile = "", $PsArgs = "") {
## Old name: SCCM:Invoke-Powershell
## Execute a Powershell script file
	$exitCode = 1 # assume failure until proven otherwise
	# Check PS file.
	If (!($PsFile.Length)) {"No PS file specified." | Write-BLLog -LogType CriticalError; return $exitCode}
	If (!(Test-Path $PsFile)) {"File not found - $PsFile" | Write-BLLog -LogType CriticalError; return $exitCode}
	$PSLogfile = [IO.Path]::GetTempFileName( )
	# Preparation done. Invoke Powershell file now
	"Invoking: Powershell.exe -file `"$PSFile`" $PsArgs" | Write-BLLog -LogType Information
	Powershell.exe -file $psFile $PSArgs >$PSLogfile 2>&1
	$exitCode = $LASTEXITCODE
	"EXIT CODE = $exitCode" | Write-BLLog -LogType Information
	Move-BLFileToLog $PsLogfile
	return $exitCode
}

Function Invoke-BLSetupInno($ExeFile = "", $InfFile = "") {
## Old name: SCCM:Invoke-InnoSetup
## Executes an Inno Setup
	$exitCode = 1 # assume failure until proven otherwise
	$innoLogfile = ""
	$innoArguments = ""
	# Check installer file.
	If (!($exeFile.Length)) {"No installer file specified." | Write-BLLog -LogType CriticalError; return $exitCode}
	If (!(Test-Path $exeFile)) {"File not found - $exeFile" | Write-BLLog -LogType CriticalError; return $exitCode}
	# Check answer file.
	If (!($infFile.Length)) {"No answer file specified." | Write-BLLog -LogType CriticalError; return $exitCode}
	If (!(Test-Path $infFile)) {"File not found - $infFile" | Write-BLLog -LogType CriticalError; return $exitCode}
	$innoLogFile = Join-Path $RIS_Logfolder ((Get-ChildItem $infFile).Name + ".log")
	$innoArguments = "/LOADINF=`"$infFile`" /LOG=`"$innoLogFile`" /SILENT"
	# Preparation done. Invoke installer now
	"Invoking: $exeFile $innoArguments" | Write-BLLog -LogType Information
	$exitCode = Start-BLProcess -FileName $exeFile -Arguments $innoArguments
	Move-BLFileToLog $innoLogfile
	return $exitCode
}

Function Invoke-BLSetupInstallShield($ExeFile = "", $IssFile = "") {
## Old name: SCCM:Invoke-InstallShieldSetup
## Executes an InstallShield Setup
	$exitCode = 1 # assume failure until proven otherwise
	$tmpIssFile = ""
	$issLogfile = ""
	$issArguments = ""
	# Check installer file.
	If (!($exeFile.Length)) {"No installer file specified." | Write-BLLog -LogType CriticalError; return $exitCode}
	If (!(Test-Path $exeFile)) {"File not found - $exeFile" | Write-BLLog -LogType CriticalError; return $exitCode}
	# Check answer file.
	If (!($issFile.Length)) {"No answer file specified." | Write-BLLog -LogType CriticalError; return $exitCode}
	If (!(Test-Path $issFile)) {"File not found - $issFile" | Write-BLLog -LogType CriticalError; return $exitCode}
	$tmpIssFile = "$env:SystemRoot\" + (Get-ChildItem $issFile).Name
	$issLogfile = Join-Path $env:TEMP ((Get-ChildItem $issFile).Name + ".log")
	$issArguments = "-s -f1`"$tmpIssFile`" -f2`"$logFile`""
	Copy-Item -Path $issFile -Destination $tmpIssFile
	# Preparation done. Invoke installer now
	"Invoking: $exeFile $issArguments" | Write-BLLog -LogType Information
	$exitCode = Start-BLProcess -FileName $exeFile -Arguments $issArguments
	Move-BLFileToLog $issLogfile
	return $exitCode
}

Function Invoke-BLSetupInstallShieldPFTW($ExeFile = "", $IssFile = "") {
## Old name: SCCM:Invoke-ISPFTWSetup
## Executes an InstallShield Package For The Web Setup
	$exitCode = 1 # assume failure until proven otherwise
	$tmpIssFile = ""
	$issLogfile = ""
	$issArguments = ""
	# Check installer file.
	If (!($exeFile.Length)) {"No installer file specified." | Write-BLLog -LogType CriticalError; return $exitCode}
	If (!(Test-Path $exeFile)) {"File not found - $exeFile" | Write-BLLog -LogType CriticalError; return $exitCode}
	# Check answer file.
	If (!($issFile.Length)) {"No answer file specified." | Write-BLLog -LogType CriticalError; return $exitCode}
	If (!(Test-Path $issFile)) {"File not found - $issFile" | Write-BLLog -LogType CriticalError; return $exitCode}
	$tmpIssFile = "$env:SystemRoot\" + (Get-ChildItem $issFile).Name
	$issLogfile = Join-Path $RIS_Logfolder ((Get-ChildItem $issFile).Name + ".log")
	$issArguments = "/s /a /s /sms /f1`"$tmpIssFile`" /f2`"$logFile`""
	Copy-Item -Path $issFile -Destination $tmpIssFile
	# Preparation done. Invoke installer now
	"Invoking: $exeFile $issArguments" | Write-BLLog -LogType Information
	$exitCode = Start-BLProcess -FileName $exeFile -Arguments $issArguments
	Move-BLFileToLog $issLogfile
	return $exitCode
}

Function Invoke-BLSetupMsi([Alias("MspFile")]$MsiFile = "", $MsiGUID = "", $MstFile = "", $TargetDir = "", $MsiOptions = "", $LogOptions = "iewa", $InstType = "/i") {
## Old name: SCCM:Invoke-MsiSetup
## Installs an MSI file
## $insttype = "/i", "/update" or "/x"; use $MsiGUID only for uninstall.
	$exitCode = 1 # assume failure until proven otherwise
	[string]$msiProduct = ""
	[string]$msiexecLogfile = ""
	[string]$msiexecArguments = ""
	If (@("/i", "/update", "/x", "/p") -NotContains $instType) {"Unknown option '$instType' specified!" | Write-BLLog -LogType CriticalError; return $exitCode}
	# Check MSI file or GUID.
	If ($instType -eq "/x") {	## Uninstall
		If ((-Not $msiFile.Length) -And (-Not $MsiGUID.Length)) {"Neither MSI file nor GUID specified." | Write-BLLog -LogType CriticalError; return $exitCode}
	} Else {					## install or update
		If (-Not $msiFile.Length) {"No MSI file specified." | Write-BLLog -LogType CriticalError; return $exitCode}
	}
	$LogFolder = Split-Path -Path $Global:TranscriptFile -Parent
	If ($msiFile.Length) {
		If (!(Test-Path $msiFile)) {"File not found - '$msiFile'" | Write-BLLog -LogType CriticalError; return $exitCode}
		If ([IO.Path]::GetExtension($msiFile) -eq ".msp") {
			If ($instType -eq "/i") {	## A patch would need to be installed using /p, but we're accepting /i as well.
				"Source file is a patch (.msp); corrected -instType argument from '/i' to '/p'." | Write-BLLog -LogType Information
				$instType = "/p"
			}
		}
		$msiexecLogfile = Join-Path $Logfolder ((Get-ChildItem $msiFile).Name + ".msi.log")
		$msiProduct = $msiFile
	} Else {
		$msiexecLogfile = Join-Path $Logfolder ($MsiGUID + ".msi.log")
		$msiProduct = $MsiGUID
	}
	$msiexecArguments = "$insttype `"$msiProduct`" /qn /l$logOptions `"$msiexecLogfile`" REBOOT=`"ReallySuppress`""
	# Check MST file. Add statement to msiexec command line if an existing file was specified
	If (!($mstFile.Length)) {
		"No MST file specified. Software will be installed w/o MST file" | Write-BLLog -LogType Information
	} Else {
		If (!(Test-Path $mstFile)) {"File not found - $mstFile" | Write-BLLog -LogType CriticalError; return $exitCode}
		$msiexecArguments = $msiexecArguments + " TRANSFORMS=`"$mstFile`""
	}
	# Check target dir. Add statement to msiexec command line if it was specified
	If (!($targetDir.Length)) {
		"No target directory specified - thus program will be installed to its default location." | Write-BLLog -LogType Information
	} Else {
		$msiexecArguments = $msiexecArguments + " INSTALLDIR=`"$targetDir`""
	}
	# Add additional options to msiexec command line, if specified
	If (!($msiOptions.Length)) {
		"No additional MSI options specified." | Write-BLLog -LogType Information
	} Else {
		$msiexecArguments = $msiexecArguments + " " + $msiOptions
	}
	# Preparation done. Invoke msiexec now
	"Invoking: msiexec.exe $msiexecArguments" | Write-BLLog -LogType Information
	$exitCode = Start-BLProcess -FileName "msiexec.exe" -Arguments $msiexecArguments
	# $match = Select-String -SimpleMatch ": INSTALL. Return value [0-9]{1,}." $msiexecLogfile
	Move-BLFileToLog $msiexecLogfile
	return $exitCode
}

Function Invoke-BLSetupNSIS($ExeFile = "", $TargetDir = "") {
## Old name: SCCM:Invoke-NSISSetup
## Execute Nullsoft Scriptable Install System (NSIS) Setup
	$exitCode = 1 # assume failure until proven otherwise
	$nsisArguments = ""
	# Check installer file.
	If (!($exeFile.Length)) {"No installer file specified." | Write-BLLog -LogType CriticalError; return $exitCode}
	If (!(Test-Path $exeFile)) {"File not found - $exeFile" | Write-BLLog -LogType CriticalError; return $exitCode}
	# Check target dir. Add statement to command line if it was specified
	If ($targetDir.Length) {
		$nsisArguments = "/S /D=$targetDir"		# /D MUST be the last option, and the path may NOT be enclosed in double quotes!
	} Else {
		"No target directory specified." | Write-BLLog -LogType Warning
		$nsisArguments = "/S"
	}
	# Preparation done. Invoke installer now
	"Invoking: $exeFile $nsisArguments" | Write-BLLog -LogType Information
	$exitCode = Start-BLProcess -FileName $exeFile -Arguments $nsisArguments
	return $exitCode
}

Function Invoke-BLSetupOther($FileName = "", $Arguments = "") {
## Old name: SCCM:Invoke-Command
## Execute a command line (like a 3rd party installer)
	$exitCode = 1 # assume failure until proven otherwise
	# Check parameters
	If (!($FileName.Length)) {"No file name specified." | Write-BLLog -LogType CriticalError; return $exitCode}
	If (!(Test-Path $FileName)) {"File not found - $FileName" | Write-BLLog -LogType CriticalError; return $exitCode}
	# Preparation done. Invoke command now
	"Invoking: $FileName $Arguments" | Write-BLLog -LogType Information
	If (!($Arguments.Length)) {
		$exitCode = Start-BLProcess -FileName $FileName
	} Else {
		$exitCode = Start-BLProcess -FileName $FileName -Arguments $Arguments
	}
	return $exitCode
}

Function Invoke-BLSetupWise($ExeFile = "") {
## Old name: SCCM:Invoke-WiseSetup
## Execute Wise InstallMaster Setup
	$exitCode = 1 # assume failure until proven otherwise
	$wiseArguments = "/s"
	# Check installer file.
	If (!($exeFile.Length)) {"No installer file specified." | Write-BLLog -LogType CriticalError; return $exitCode}
	If (!(Test-Path $exeFile)) {"File not found - $exeFile" | Write-BLLog -LogType CriticalError; return $exitCode}
	# Preparation done. Invoke installer now
	"Invoking: $exeFile $wiseArguments" | Write-BLLog -LogType Information
	$exitCode = Start-BLProcess -FileName $exeFile -Arguments $wiseArguments
	return $exitCode
}

Function New-BLUninstallEntry([string]$RegistryKeyName = "", [string]$DisplayName, [string]$UninstallString, [string]$DisplayVersion = "1.0.0.0", [string]$Publisher = "Atos", [string]$DisplayIcon = "", [switch]$NoModify, [string]$ModifyPath) {
	If ([string]::IsNullOrEmpty($DisplayName)) {
		"Mandatory argument 'DisplayName' not specified!" | Write-BLLog -LogType CriticalError
		Return $Null
	}
	If ([string]::IsNullOrEmpty($UninstallString)) {
		"Mandatory argument 'UninstallString' not specified!" | Write-BLLog -LogType CriticalError
		Return $Null
	}
	If ([string]::IsNullOrEmpty($RegistryKeyName)) {
		$RegistryKeyName = $DisplayName
	}
	$UninstallKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$($RegistryKeyName)"
	$Result = New-BLRegistryKeyX64 -Path $UninstallKey
	If (-Not ($Result)) {
		"Could not create uninstall registry key '$($UninstallKey)'!" | Write-BLLog -LogType CriticalError
		Return $Null
	}
	$Result = Set-BLRegistryValueX64 -Path $UninstallKey -Name "DisplayName" -Type "REG_SZ" -Value $DisplayName
	If (-Not ($Result)) {
		"Could not set uninstall registry value 'DisplayName' in '$($UninstallKey)' to '$($DisplayName)'!" | Write-BLLog -LogType CriticalError
		Return $Null
	}
	$Result = Set-BLRegistryValueX64 -Path $UninstallKey -Name "UninstallString" -Type "REG_SZ" -Value $UninstallString
	If (-Not ($Result)) {
		"Could not set uninstall registry value 'UninstallString' in '$($UninstallKey)' to '$($UninstallString)'!" | Write-BLLog -LogType CriticalError
		Return $Null
	}
	If (-Not [string]::IsNullOrEmpty($DisplayVersion)) {
		$Result = Set-BLRegistryValueX64 -Path $UninstallKey -Name "DisplayVersion" -Type "REG_SZ" -Value $DisplayVersion
		If (-Not ($Result)) {
			"Could not set uninstall registry value 'DisplayVersion' in '$($UninstallKey)' to '$($DisplayVersion)'!" | Write-BLLog -LogType CriticalError
			Return $Null
		}
	}
	If (-Not [string]::IsNullOrEmpty($Publisher)) {
		$Result = Set-BLRegistryValueX64 -Path $UninstallKey -Name "Publisher" -Type "REG_SZ" -Value $Publisher
		If (-Not ($Result)) {
			"Could not set uninstall registry value 'Publisher' in '$($UninstallKey)' to '$($Publisher)'!" | Write-BLLog -LogType CriticalError
			Return $Null
		}
	}
	If (-Not [string]::IsNullOrEmpty($DisplayIcon)) {
		$Result = Set-BLRegistryValueX64 -Path $UninstallKey -Name "DisplayIcon" -Type "REG_SZ" -Value $DisplayIcon
		If (-Not ($Result)) {
			"Could not set uninstall registry value 'DisplayIcon' in '$($UninstallKey)' to '$($DisplayIcon)'!" | Write-BLLog -LogType CriticalError
			Return $Null
		}
	}
	If (-Not [string]::IsNullOrEmpty($ModifyPath)) {
		$Result = Set-BLRegistryValueX64 -Path $UninstallKey -Name "ModifyPath" -Type "REG_SZ" -Value $ModifyPath
		If (-Not ($Result)) {
			"Could not set uninstall registry value 'ModifyPath' in '$($UninstallKey)' to '$($ModifyPath)'!" | Write-BLLog -LogType CriticalError
			Return $Null
		}
	}
	If ($NoModify -And [string]::IsNullOrEmpty($ModifyPath)) {$intNoModify = 1} Else {$intNoModify = 0}
	$Result = Set-BLRegistryValueX64 -Path $UninstallKey -Name "NoModify" -Type "REG_DWORD" -Value $intNoModify
	If (-Not ($Result)) {
		"Could not set uninstall registry value 'NoModify' in '$($UninstallKey)' to '$($intNoModify)'!" | Write-BLLog -LogType CriticalError
		Return $Null
	}
	Return (Get-BLRegistryKeyX64 -Path $UninstallKey)
}

Function Remove-BLUninstallEntry([string]$RegistryKeyName) {
	If ([string]::IsNullOrEmpty($RegistryKeyName)) {
		"Mandatory argument 'RegistryKeyName' not specified!" | Write-BLLog -LogType CriticalError
		Return 1
	}
	$UninstallKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$($RegistryKeyName)"
	If (Get-BLRegistryKeyX64 -Path $UninstallKey -ErrorAction SilentlyContinue) {
		Remove-BLRegistryKeyX64 -Path $UninstallKey
	}
	Return 0
}

Function Uninstall-BLWindowsHotfix {
[CmdletBinding(DefaultParameterSetName="Uninstall_By_KB")]
Param(
	[Parameter(Position=0, ParameterSetName="Uninstall_By_KB")]
	[string]$MsuKB = "",
	[Parameter(Position=0, ParameterSetName="Uninstall_By_File")]
	[string]$MsuFile = "",
	[Parameter(Position=1)]
	[string]$LogFile = ""
)
	$CommandLine = $PSBoundParameters
	$exitCode = Install-BLWindowsHotfix @CommandLine -Uninstall
	Return $exitCode
}

## ====================================================================================================
## Group "OS Management"
## ====================================================================================================

Function Add-BLLocalAdminGroupMember {
## Old name: SCCM:Add-LocalAdminGroupMember
## Adds a domain acount / domain group to the local administrators group
Param (
	[string] $UserName = $(throw "user name not specified"),
	[string] $DomainName = $ENV:UserDomain,
	[string] $ComputerName = $ENV:ComputerName
)
	# könnte auch sein return Add-BLLocalGroupMember -AdminGroup -DomainName $DomainName -UserName $UserName -ComputerName $ComputerName
	Try {
		$AdministratorsGroupName = (Get-WmiObject -Query "SELECT * FROM Win32_Group WHERE LocalAccount='TRUE' AND SID='S-1-5-32-544'" -ComputerName $ComputerName).Name
		[Array] $AdministratorsGroupMembers = Get-BLLocalGroupMembers $AdministratorsGroupName -ComputerName $ComputerName
		If ($AdministratorsGroupMembers -NotContains "$DomainName\$UserName") {
			([ADSI]"WinNT://$computerName/$AdministratorsGroupName,group").Add("WinNT://$domainName/$userName") | Out-Null
			"User '$domainName\$userName' is now member of local group '$AdministratorsGroupName'." | Write-BLLog -LogType Information
		} Else {
			"User '$domainName\$userName' is already member of local group '$AdministratorsGroupName'." | Write-BLLog -LogType Information 
		}
		Return 0
	} Catch {
		$_ | Out-String | Write-BLLog -LogType CriticalError
		Return 1
	}
}

Function Add-BLLocalGroupMember {
## Adds a domain acount / domain group to the local administrators group
Param (
	[string] $GroupName = "",  # if ""  -AdminGroup or -RDUGroup are intepreted
	[string] $UserName = $(throw "user name not specified"),
	[string] $DomainName = $ENV:UserDomain,
	[string] $ComputerName = $ENV:ComputerName,
    [switch] $AdminGroup = $false,
    [switch] $RDGroup = $false
)
	Try {
		$SID = ""
        if ($GroupName -eq "") {
            if ($RDGroup) {
                $SID = "S-1-5-32-555"    # "Remote Desktop Users"
            }
            if ($AdminGroup) {
                $SID = "S-1-5-32-544"    # "Administrators"
            }
            if ($SID -eq "") 
            {
                "Add-BLLocalGroupMember: must specify -GroupName or -AdminGroup or -RDGroup" | Write-BLLog -LogType CriticalError
                return 1
            }
        }
        if ($GroupName -eq "") {
            $GroupName = (Get-WmiObject -Query "SELECT * FROM Win32_Group WHERE LocalAccount='TRUE' AND SID='$SID'" -ComputerName $ComputerName).Name
        }

		[Array] $GroupMembers = Get-BLLocalGroupMembers $GroupName -ComputerName $ComputerName
		If ($GroupMembers -NotContains "$DomainName\$UserName") {
			([ADSI]"WinNT://$computerName/$GroupName,group").Add("WinNT://$domainName/$userName") | Out-Null
			"User '$domainName\$userName' is now member of local group '$GroupName'." | Write-BLLog -LogType Information
		} Else {
			"User '$domainName\$userName' is already member of local group '$GroupName'." | Write-BLLog -LogType Information 
		}
		Return 0
	} Catch {
		$_ | Out-String | Write-BLLog -LogType CriticalError
		Return 1
	}
}

Function ConvertFrom-BLEvt {
## Converts an .evt or evtx file into other formats.
## As of 07.2014, tests are based solely on the WUSA .evt files; use XML and/or adjust the function if you're not happy with the result.
## Removes the old file if -ToEvtx and -Purge is specified.
[CmdletBinding(DefaultParameterSetName="Convert_To_Objects")]
Param(
	[Parameter(Position=0)]
	[string]$Path = "",
	[Parameter(Position=1, ParameterSetName="Convert_To_Objects")]
	[switch]$NoProgress,
	[Parameter(Position=1, ParameterSetName="Convert_To_Evtx")]
	[switch]$ToEvtx,
	[Parameter(Position=1, ParameterSetName="Convert_To_Xml")]
	[switch]$ToXml,
	[Parameter(Position=1, ParameterSetName="Convert_To_Text")]
	[switch]$ToText,
	[Parameter(Position=1, ParameterSetName="Convert_To_RenderedXml")]
	[switch]$ToRenderedXml,
	[Parameter(Position=2, ParameterSetName="Convert_To_Evtx")]
	[switch]$Purge,
	[Parameter(Position=2, ParameterSetName="Convert_To_Xml")]
	[Parameter(Position=2, ParameterSetName="Convert_To_RenderedXml")]
	[string]$XmlRootElement = "EventLog"
)
<# "Rendered XML" sample; the "RenderingInfo" node is missing in the default XML export.
<EventLog>
	<Event xmlns="http://schemas.microsoft.com/win/2004/08/events/event">
		<System>
			<Provider Name="Microsoft-Windows-WUSA" Guid="{09608c12-c1da-4104-a6fe-b959cf57560a}" />
			<EventID>1</EventID>
			<Version>0</Version>
			<Level>0</Level>
			<Task>0</Task>
			<Opcode>0</Opcode>
			<Keywords>0x4000000000000000</Keywords>
			<TimeCreated SystemTime="2014-07-21T12:46:13.209632300Z" />
			<EventRecordID>0</EventRecordID>
			<Correlation />
			<Execution ProcessID="6720" ThreadID="6288" ProcessorID="1" KernelTime="0" UserTime="0" />
			<Channel></Channel>
			<Computer>MR1ITSPB001.MR1.infra3.svc</Computer>
			<Security />
		</System>
		<EventData>
			<Data Name="DebugMessage">UninstallWorker.00664: Start of search</Data>
		</EventData>
		<RenderingInfo Culture="de-DE">
			<Message>UninstallWorker.00664: Start of search</Message>
			<Level>Information</Level>
			<Task></Task>
			<Opcode>Info</Opcode>
			<Channel></Channel>
			<Provider>Microsoft-Windows-WUSA</Provider>
			<Keywords></Keywords>
		</RenderingInfo>
	</Event>
</EventLog>
#>
	If ([string]::IsNullOrEmpty($Path)) {
		"No event log file specified!" | Write-BLLog -LogType CriticalError
		Return $Null
	}
	If (-Not ($EventFileItem = Get-Item -Path $Path)) {
		"Event log file '$Path' not found!" | Write-BLLog -LogType CriticalError
		Return $Null
	}
	Switch ($PsCmdlet.ParameterSetName) {
		"Convert_To_Objects" {
			If (-Not $NoProgress) {Write-Progress -Status "Converting event file '$($Path)' " -Activity "Reading file" -PercentComplete 0 -SecondsRemaining -1}
			[xml]$xml = & wevtutil.exe query-events $EventFileItem.FullName /logfile:true /format:RenderedXML /element:$XmlRootElement
			If ($LASTEXITCODE -ne 0) {
				"wevtutil.exe returned with errorlevel $($LASTEXITCODE)!" | Write-BLLog -LogType CriticalError
				Return $Null
			} Else {
				[System.Xml.XmlNamespaceManager]$NsMgr = $xml.NameTable
				$Events = $xml.$XmlRootElement.Event
				$xmlns = $Events[0].GetAttribute("xmlns")
				$NsMgr.AddNamespace("evt", $xmlns)
				$PropertyList = @(
					"ProviderName",
					"ProviderGuid",
					"EventID",
					"Version",
					"Level",
					"Task",
					"Opcode",
					"Keywords",
					"TimeCreated",
					"EventRecordID",
					"Correlation",
					"Channel",
					"Computer",
					"EventData",
					"RI_Culture",
					"RI_Message",
					"RI_Level",
					"RI_Task",
					"RI_Opcode",
					"RI_Channel",
					"RI_ProviderName",
					"RI_Keywords"
				)
				$Index = 0
				ForEach ($NodeEvent In $Events) {
					$Index += 1
					If (-Not $NoProgress) {Write-Progress -Status "Converting event file '$($Path)' " -Activity "Processing events" -CurrentOperation "Event $Index of $($Events.Count)" -PercentComplete ((100 * $Index) / $Events.Count) -SecondsRemaining -1}
					$Event = "" | Select $PropertyList
					$Event.ProviderName =	[string]$NodeEvent.SelectSingleNode("evt:System/evt:Provider", $NsMgr).GetAttribute("Name")
					$Event.ProviderGuid =	[string]$NodeEvent.SelectSingleNode("evt:System/evt:Provider", $NsMgr).GetAttribute("Guid")
					$Event.EventID =		[uint32]$NodeEvent.SelectSingleNode("evt:System/evt:EventID", $NsMgr).InnerText
					$Event.Version =		[uint32]$NodeEvent.SelectSingleNode("evt:System/evt:Version", $NsMgr).InnerText
					$Event.Level =			[uint32]$NodeEvent.SelectSingleNode("evt:System/evt:Level", $NsMgr).InnerText
					$Event.Task =			[uint32]$NodeEvent.SelectSingleNode("evt:System/evt:Task", $NsMgr).InnerText
					$Event.Opcode =			[uint32]$NodeEvent.SelectSingleNode("evt:System/evt:Opcode", $NsMgr).InnerText
					$Event.Keywords =		[string]$NodeEvent.SelectSingleNode("evt:System/evt:Keywords", $NsMgr).InnerText
					$Event.TimeCreated =	[datetime]$NodeEvent.SelectSingleNode("evt:System/evt:TimeCreated", $NsMgr).GetAttribute("SystemTime")
					$Event.EventRecordID =	[uint32]$NodeEvent.SelectSingleNode("evt:System/evt:EventRecordID", $NsMgr).InnerText
					$Event.Correlation =	[string]$NodeEvent.SelectSingleNode("evt:System/evt:Correlation", $NsMgr).InnerText
					$Event.Channel =		[string]$NodeEvent.SelectSingleNode("evt:System/evt:Channel", $NsMgr).InnerText
					$Event.Computer =		[string]$NodeEvent.SelectSingleNode("evt:System/evt:Computer", $NsMgr).InnerText
					$Event.EventData = @{}	
					ForEach ($NodeData In $NodeEvent.SelectNodes("evt:EventData/evt:Data", $NsMgr)) {
						$Event.EventData[$NodeData.GetAttribute("Name")] = $NodeData.InnerText.Trim("`r`n")
					}
					$Event.RI_Culture =		[string]$NodeEvent.SelectSingleNode("evt:RenderingInfo", $NsMgr).GetAttribute("Culture")
					$Event.RI_Message =		[string]$NodeEvent.SelectSingleNode("evt:RenderingInfo/evt:Message", $NsMgr).InnerText.Trim("`r`n")
					$Event.RI_Level =		[string]$NodeEvent.SelectSingleNode("evt:RenderingInfo/evt:Level", $NsMgr).InnerText
					$Event.RI_Task =		[string]$NodeEvent.SelectSingleNode("evt:RenderingInfo/evt:Task", $NsMgr).InnerText
					$Event.RI_Opcode =		[string]$NodeEvent.SelectSingleNode("evt:RenderingInfo/evt:Opcode", $NsMgr).InnerText
					$Event.RI_Channel =		[string]$NodeEvent.SelectSingleNode("evt:RenderingInfo/evt:Channel", $NsMgr).InnerText
					$Event.RI_ProviderName =[string]$NodeEvent.SelectSingleNode("evt:RenderingInfo/evt:Provider", $NsMgr).InnerText
					$Event.RI_Keywords =	[string]$NodeEvent.SelectSingleNode("evt:RenderingInfo/evt:Keywords", $NsMgr).InnerText
					$Event | Write-Output
				}
				If (-Not $NoProgress) {Write-Progress -Status "Converting event file '$($Path)' " -Activity "Processing events" -Completed}
				Return
			}
		}
		"Convert_To_Evtx" {
			$EvtxPath = $EventFileItem.DirectoryName + "\" + $EventFileItem.BaseName + ".evtx"
			& wevtutil.exe export-log $EventFileItem.FullName $EvtxPath /logfile:true /overwrite:true | Out-Null
			If ($LASTEXITCODE -eq 0) {
				If ($Purge) {
					$EventFileItem | Remove-Item
				}
				Return (Get-Item -Path $EvtxPath)
			} Else {
				"wevtutil.exe returned with errorlevel $($LASTEXITCODE)!" | Write-BLLog -LogType CriticalError
				Return $Null
			}
		}
		"Convert_To_Text" {
			$Text = & wevtutil.exe query-events $EventFileItem.FullName /logfile:true /format:Text
			If ($LASTEXITCODE -eq 0) {
				Return $Text
			} Else {
				"wevtutil.exe returned with errorlevel $($LASTEXITCODE)!" | Write-BLLog -LogType CriticalError
				Return $Null
			}
		}
		Default {	## Convert_To_Xml, Convert_To_RenderedXml
			If ($PsCmdlet.ParameterSetName -eq "Convert_To_Xml") {
				$Format = "XML"
			} Else {
				$Format = "RenderedXML"
			}
			[xml]$xml = & wevtutil.exe query-events $EventFileItem.FullName /logfile:true /format:$Format /element:$XmlRootElement
			If ($LASTEXITCODE -eq 0) {
				Return $xml
			} Else {
				"wevtutil.exe returned with errorlevel $($LASTEXITCODE)!" | Write-BLLog -LogType CriticalError
				Return $Null
			}
		}
	}
}

Function ConvertFrom-BLSecureString([Security.SecureString]$String) {
## Returns the plain text password from a secure string
	$ret = $Null
	$ret = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "Dummy", $String -ErrorAction SilentlyContinue -ErrorVariable ErrorVar
	If ($ret -eq $Null) {
		"Could not generate a credential object; error information:" | Write-BLLog -LogType CriticalError
		$ErrorVar | Write-BLLog -LogType CriticalError
		Return $Null
	}
	Return $ret.GetNetworkCredential().Password
}

Function Get-BLAccountFromSID {
## Returns the Account of a given SID (domain or local).
## LEGACY - use the more versatile Resolve-BLSid
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)]
	[string]$SID
)
	Process {
		Try {
			$PrincipalSID = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $SID
			$Principal = $PrincipalSID.Translate([System.Security.Principal.NTAccount])
			Return $Principal.Value
		} Catch {
			$_ | Out-String | Write-BLLog -LogType CriticalError
			Return $Null
		}
	}
	End {
		"Get-BLAccountFromSID is still fully working, but deprecated since 04.2015; please use Resolve-BLSid instead." | Write-Warning
	}
}

Function Get-BLAdsiObject {
## Helper function for local user management, not exported!
[CmdletBinding()]
Param(
	[string]$Path
)
	## If something goes wrong with [ADSI], there will be something returned that is almost, but not quite, entirely unlike the System.DirectoryServices.DirectoryEntry expected on success.
	## "-is [System.DirectoryServices.DirectoryEntry]" will return $True, but trying to access the object (for example .GetType()) will result in the error that ADSI ran into.
	$AdsiObject = [ADSI]$Path
	If (Get-Member -InputObject $AdsiObject -MemberType Property) {
		Return $AdsiObject
	} Else {
		## Couldn't find any exposed property, so the ADSI call failed.
		## Provoke an exception that can be trapped, and return the message.
		Try {
			$AdsiObject.GetType() | Out-Null
		} Catch {
			"Error retrieving '$($Path)': $($_.Exception.Message.Split(':')[1].Trim().Replace("`r`n", ''))" | Write-Error
		}
	}
}

Function Get-BLComputerBootTime {
[CmdletBinding()]
Param(
	[string]$ComputerName = $ENV:ComputerName
)
	Try {
		Return [Management.ManagementDateTimeConverter]::ToDateTime((Get-WmiObject Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction Stop).LastBootUpTime)
	} Catch {
		$_.Exception.Message | Write-Error
	}
}

Function Get-BLComputerDomain([switch]$NetBIOS) {
## Returns the domain name of the machine (not the logged on user).
## String returned will be empty if no domain membership.
	$ComputerDomain = Get-WmiObject -Query "SELECT Domain, PartOfDomain FROM Win32_ComputerSystem"
	If (-Not $ComputerDomain.PartOfDomain) {
		Return ""
	}
	If ($NetBIOS) {
		Return [BLNetApi]::GetComputerNetBiosDomain()
	} Else {
		Return $ComputerDomain.Domain
	}
}

Function Get-BLComputerPendingReboot {
<#
.SYNOPSIS
Gets the pending reboot status on a local or remote computer.

.DESCRIPTION
This function will query the registry on a local or remote computer and determine if the
system is pending a reboot, from Microsoft updates, Configuration Manager Client SDK, Pending Computer 
Rename, Domain Join or Pending File Rename Operations. For Windows 2008+ the function will query the 
CBS registry key as another factor in determining pending reboot state.  "PendingFileRenameOperations" 
and "Auto Update\RebootRequired" are observed as being consistant across Windows Server 2003 & 2008.

CBServicing = Component Based Servicing (Windows 2008+)
WindowsUpdate = Windows Update / Auto Update (Windows 2003+)
CCMClientSDK = SCCM 2012 Clients only (DetermineIfRebootPending method) otherwise $null value
PendComputerRename = Detects either a computer rename or domain join operation (Windows 2003+)
PendFileRename = PendingFileRenameOperations (Windows 2003+)
PendFileRenVal = PendingFilerenameOperations registry value; used to filter if need be, some Anti-
				 Virus leverage this key for def/dat removal, giving a false positive PendingReboot

.PARAMETER ComputerName
A single Computer or an array of computer names.  The default is localhost ($env:COMPUTERNAME).

.PARAMETER ErrorLog
A single path to send error data to a log file.

.EXAMPLE
PS C:\> Get-BLComputerPendingReboot -ComputerName (Get-Content C:\ServerList.txt) | Format-Table -AutoSize

Computer CBServicing WindowsUpdate CCMClientSDK PendFileRename PendFileRenVal RebootPending
-------- ----------- ------------- ------------ -------------- -------------- -------------
DC01           False         False                       False                        False
DC02           False         False                       False                        False
FS01           False         False                       False                        False

This example will capture the contents of C:\ServerList.txt and query the pending reboot
information from the systems contained in the file and display the output in a table. The
null values are by design, since these systems do not have the SCCM 2012 client installed,
nor was the PendingFileRenameOperations value populated.

.EXAMPLE
PS C:\> Get-BLComputerPendingReboot

Computer           : WKS01
CBServicing        : False
WindowsUpdate      : True
CCMClient          : False
PendComputerRename : False
PendFileRename     : False
PendFileRenVal     : 
RebootPending      : True

This example will query the local machine for pending reboot information.

.EXAMPLE
PS C:\> $Servers = Get-Content C:\Servers.txt
PS C:\> Get-BLComputerPendingReboot -Computer $Servers | Export-Csv C:\PendingRebootReport.csv -NoTypeInformation

This example will create a report that contains pending reboot information.

.LINK
Component-Based Servicing:
http://technet.microsoft.com/en-us/library/cc756291(v=WS.10).aspx

PendingFileRename/Auto Update:
http://support.microsoft.com/kb/2723674
http://technet.microsoft.com/en-us/library/cc960241.aspx
http://blogs.msdn.com/b/hansr/archive/2006/02/17/patchreboot.aspx

SCCM 2012/CCM_ClientSDK:
http://msdn.microsoft.com/en-us/library/jj902723.aspx

.NOTES
Author:  Brian Wilhite
Email:   bcwilhite (at) live.com
Date:    29AUG2012
PSVer:   2.0/3.0/4.0/5.0
Updated: 27JUL2015
UpdNote: Added Domain Join detection to PendComputerRename, does not detect Workgroup Join/Change
         Fixed Bug where a computer rename was not detected in 2008 R2 and above if a domain join occurred at the same time.
         Fixed Bug where the CBServicing wasn't detected on Windows 10 and/or Windows Server Technical Preview (2016)
         Added CCMClient property - Used with SCCM 2012 Clients only
         Added ValueFromPipelineByPropertyName=$true to the ComputerName Parameter
         Removed $Data variable from the PSObject - it is not needed
         Bug with the way CCMClientSDK returned null value if it was false
         Removed unneeded variables
         Added PendFileRenVal - Contents of the PendingFileRenameOperations Reg Entry
         Removed .Net Registry connection, replaced with WMI StdRegProv
         Added ComputerPendingRename
Source:  https://gallery.technet.microsoft.com:443/scriptcenter/Get-PendingReboot-Query-bdb79542
#>
[CmdletBinding()]
Param(
	[Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
	[Alias("CN","Computer")]
	[String[]]$ComputerName="$env:COMPUTERNAME",
	[String]$ErrorLog
)

Begin {
}## End Begin Script Block
Process {
	Foreach ($Computer in $ComputerName) {
		Try {
			## Setting pending values to false to cut down on the number of else statements
			$CompPendRen,$PendFileRename,$Pending,$SCCM = $false,$false,$false,$false
							
			## Setting CBSRebootPend to null since not all versions of Windows has this value
			$CBSRebootPend = $null
							
			## Querying WMI for build version
			$WMI_OS = Get-WmiObject -Class Win32_OperatingSystem -Property BuildNumber, CSName -ComputerName $Computer -ErrorAction Stop

			## Making registry connection to the local/remote computer
			$HKLM = [UInt32] "0x80000002"
			$WMI_Reg = [WMIClass] "\\$Computer\root\default:StdRegProv"
							
			## If Vista/2008 & Above query the CBS Reg Key
			If ([Int32]$WMI_OS.BuildNumber -ge 6001) {
				$RegSubKeysCBS = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\")
				$CBSRebootPend = $RegSubKeysCBS.sNames -contains "RebootPending"		
			}
								
			## Query WUAU from the registry
			$RegWUAURebootReq = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")
			$WUAURebootReq = $RegWUAURebootReq.sNames -contains "RebootRequired"
							
			## Query PendingFileRenameOperations from the registry
			$RegSubKeySM = $WMI_Reg.GetMultiStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\Session Manager\","PendingFileRenameOperations")
			$RegValuePFRO = $RegSubKeySM.sValue

			## Query JoinDomain key from the registry - These keys are present if pending a reboot from a domain join operation
			$Netlogon = $WMI_Reg.EnumKey($HKLM,"SYSTEM\CurrentControlSet\Services\Netlogon").sNames
			$PendDomJoin = ($Netlogon -contains 'JoinDomain') -or ($Netlogon -contains 'AvoidSpnSet')

			## Query ComputerName and ActiveComputerName from the registry
			$ActCompNm = $WMI_Reg.GetStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName\","ComputerName")            
			$CompNm = $WMI_Reg.GetStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\","ComputerName")

			If (($ActCompNm -ne $CompNm) -or $PendDomJoin) {
				$CompPendRen = $true
			}
							
			## If PendingFileRenameOperations has a value set $RegValuePFRO variable to $true
			If ($RegValuePFRO) {
				$PendFileRename = $true
			}

			## Determine SCCM 2012 Client Reboot Pending Status
			## To avoid nested 'if' statements and unneeded WMI calls to determine if the CCM_ClientUtilities class exist, setting EA = 0
			$CCMClientSDK = $null
			$CCMSplat = @{
				NameSpace='ROOT\ccm\ClientSDK'
				Class='CCM_ClientUtilities'
				Name='DetermineIfRebootPending'
				ComputerName=$Computer
				ErrorAction='Stop'
			}
			## Try CCMClientSDK
			Try {
				$CCMClientSDK = Invoke-WmiMethod @CCMSplat
			} Catch [System.UnauthorizedAccessException] {
				$CcmStatus = Get-Service -Name CcmExec -ComputerName $Computer -ErrorAction SilentlyContinue
				If ($CcmStatus.Status -ne 'Running') {
					Write-Warning "$Computer`: Error - CcmExec service is not running."
					$CCMClientSDK = $null
				}
			} Catch {
				$CCMClientSDK = $null
			}

			If ($CCMClientSDK) {
				If ($CCMClientSDK.ReturnValue -ne 0) {
					Write-Warning "Error: DetermineIfRebootPending returned error code $($CCMClientSDK.ReturnValue)"          
				}
				If ($CCMClientSDK.IsHardRebootPending -or $CCMClientSDK.RebootPending) {
					$SCCM = $true
				}
			}
				
			Else {
				$SCCM = $null
			}

			## Creating Custom PSObject and Select-Object Splat
			$SelectSplat = @{
				Property=(
					'Computer',
					'CBServicing',
					'WindowsUpdate',
					'CCMClientSDK',
					'PendComputerRename',
					'PendFileRename',
					'PendFileRenVal',
					'RebootPending'
				)}
			New-Object -TypeName PSObject -Property @{
				Computer=$WMI_OS.CSName
				CBServicing=$CBSRebootPend
				WindowsUpdate=$WUAURebootReq
				CCMClientSDK=$SCCM
				PendComputerRename=$CompPendRen
				PendFileRename=$PendFileRename
				PendFileRenVal=$RegValuePFRO
				RebootPending=($CompPendRen -or $CBSRebootPend -or $WUAURebootReq -or $SCCM -or $PendFileRename)
			} | Select-Object @SelectSplat
		} Catch {
			Write-Warning "$Computer`: $_"
			## If $ErrorLog, log the file to a user specified location/path
			If ($ErrorLog) {
				Out-File -InputObject "$Computer`,$_" -FilePath $ErrorLog -Append
			}				
		}			
	}## End Foreach ($Computer in $ComputerName)			
}## End Process
End {
}## End End
}## End Function Get-BLComputerPendingReboot

Function Get-BLCredentialManagerPolicy() {
	$Setting = Get-BLRegistryValueX64 -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "disabledomaincreds" -ErrorAction SilentlyContinue
	If ($Setting) {
		If ($Setting -eq 0) {
			Return "Disabled"
		} Else {
			Return "Enabled"
		}
	} Else {
		Return "NotConfigured"
	}
}

Function Get-BLCredentials([string]$UserName, [string]$Password) {
## Returns a PSCredentials object
	$ret = $Null
	$SecurePassword = ConvertTo-SecureString $Password -asPlaintext -Force
	$ret = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword -ErrorAction SilentlyContinue -ErrorVariable ErrorVar
	If ($ret -eq $Null) {
		"Could not generate a credential object; error information:" | Write-BLLog -LogType CriticalError
		$ErrorVar | Write-BLLog -LogType CriticalError
	}
	Return $ret
}

Function Get-BLDotNetFrameworkVersions() {
## Returns the installed versions of the .NET Framework
## See "How to: Determine Which .NET Framework Versions Are Installed", http://msdn.microsoft.com/en-us/library/hh925568(v=vs.110).aspx
	$NDP = Get-Childitem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' | Where {$_.PSIsContainer -And $_.PSChildName -match '^v\d'}
	$Versions = @()
	ForEach ($NetVersion In $NDP) {
		If ($NetVersion.PSChildName -Match '^v(2\.0|3\.0|3\.5)') {
			$Versions += (Get-ItemProperty -Path $NetVersion.PSPath).Version
		}
		If ($NetVersion.PSChildName -Match '^v4\.0') {
			ForEach ($NetType In "Client", "Full") {
				If ($Type = Get-ItemProperty -Path "$($NetVersion.PSPath)\$($NetType)" -ErrorAction SilentlyContinue) {
					$Versions += $Type.Version + $NetType.SubString(0, 1).ToLower()
				}
			}
		}
		If ($NetVersion.PSChildName -Match '^v4$') {
			ForEach ($NetType In "Client", "Full") {
				If ($Type = Get-ItemProperty -Path "$($NetVersion.PSPath)\$($NetType)" -ErrorAction SilentlyContinue) {
					Switch ($Type.Release) {
						378389	{$Version = "4.5"}
						378675	{$Version = "4.5.1"}	## installed with Windows 8.1
						378758	{$Version = "4.5.1"}	## installed on Windows 8, Windows 7 SP1, or Windows Vista SP2
						379893	{$Version = "4.5.2"}
						Default	{Version = $Type.Version}
					}
				}
				$Versions += $Version + $NetType.SubString(0, 1).ToLower()
			}
		}
	}
	Return $Versions
}

Function Get-BLDVDDrives([switch]$MediaAccess) {
## Returns an array of DVD drive letters.
## If $MediaAccess -eq $True, only drive letters with an inserted media will be returned.
	$Filter = "DriveType=$($CIM_LD_DriveType.Compact_Disc)"
	If ($MediaAccess) {
		$Filter += " and Access>$($CIM_LD_Access.Unknown)"
	}
	$DVDDrives = Get-WmiObject Win32_LogicalDisk -Filter $Filter
	Return ,@($DVDDrives | % {$_.DeviceID})
}

Function Get-BLEnvironmentVariable([string]$Name = "") {
## Old name: SCCM:Get-EnvVar
## --------
## Determine environment variable and try to resolve it from registry if it not (yet) exists
	Trap {
		"An error occurred while trying to resolve an environment variable.´nLast Error was:`n$($Error[0])" | Write-BLLog -LogType CriticalError
		Return ""
		Continue
	}
	If ([String]::IsNullOrEmpty($Name)) {
		"Environment variable name must be set!" | Write-BLLog -LogType CriticalError
	} Else {
		If (Test-Path "env:$Name") {
			Return $(Get-Item "env:$Name").Value
		} Else {
			"Environment variable '$Name' does not yet exist for the current process." | Write-BLLog -LogType Warning
			$EnvironmentRegPath = "HKLM:SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
			If (Test-Path $EnvironmentRegPath) {
				If ($(Get-Item $EnvironmentRegPath).Property -Contains $Name) {
					Return $(Get-ItemProperty -Path $EnvironmentRegPath -Name $Name)
				} Else {
					"Did not find environment variable '$name'" | Write-BLLog -LogType Warning
				}
			} Else {
				"Can not access registry path '$EnvironmentRegPath'" | Write-BLLog -LogType CriticalError
			}
		}
	}
	Return ""
}

Function Get-BLFullPath {
<#
.SYNOPSIS
Resolves a relative path to an absolute path.

.DESCRIPTION
The function Get-BLFullPath resolves a relative path to an absolute path.
If a relative path is given, it will use the currect PS location to determine the resolved path.
Unlike Resolve-Path, the path does not need to exist.

.PARAMETER Path
The path to resolve.
Wildcards are not allowed.

.PARAMETER PSProvider
The provider to be used. Everything other than FileSystem is largely untested and deemed experimental.

.PARAMETER AsUnc
If AsUnc is $True, and the path is on a mapped network drive, will return the path in UNC format instead of the mapped drive.
Will return just the resolved path if AsUnc is $True, and the path is not on a mapped network drive.
This works with traditional drives mapped from Explorer/"net use", as well as "New-PSDrive".

.INPUTS
System.String[]

.OUTPUTS
System.String[]

.EXAMPLE
Get-BLFullPath -Path .\Temp

.EXAMPLE
Get-BLFullPath -Path X:\Temp -AsUnc
Tries to resolve X:\Temp and will return it as \\Server\Share\Folder\Temp if X: is a drive mapped to \\Server\Share\Folder

.LINK
Join-Path
Resolve-Path
Split-Path
#>
[CmdletBinding()]
Param(
	[Parameter(Position=0, ValueFromPipeline=$True)]
	[string[]]$Path = (Get-Location -PSProvider FileSystem).Path,
	[string]$PSProvider = "FileSystem",
	[switch]$AsUnc
)
	Begin {
		$PSLocation = (Get-Location -PSProvider $PSProvider).Path
		$PSDrive = Split-Path -Path $PSLocation -Qualifier
	}
	## Possibilities:
	## * UNC path: \\server\C$\Windows
	## * Rooted path with a default drive letter: C:\Windows
	## * Rooted path with a PS drive letter: WIN:\system32, HKLM:\Software
	## * Rooted path relative to a drive location: D:folder, WIN:Folder
	## * Non-rooted path relative to current drive: \folder
	## * Non-rooted path relative to current folder: folder, .\folder, ..\folder
	## Can't use Join-Path, as it insists that the drive for the Path exists.
	Process {
		ForEach ($LiteralPath In $Path) {
			$PathQualifier = Split-Path -Path $LiteralPath -Qualifier -ErrorAction SilentlyContinue
			$PathNoQualifier = Split-Path -Path $LiteralPath -NoQualifier -ErrorAction SilentlyContinue
			If ($LiteralPath.StartsWith("\\")) {	## UNC
				$QueryPath = $LiteralPath
				"UNC path detected." | Write-Verbose
			} ElseIf ($PathQualifier) {		## Rooted path; might still be relative to a drive location
				If ($PathNoQualifier.StartsWith("\")) {
					$QueryPath = $LiteralPath
					"Rooted path detected." | Write-Verbose
				} Else {
					If (Get-PSDrive -Name $PathQualifier.Trim(":") -ErrorAction SilentlyContinue) {
						$PSDriveLocation = (Get-Location -PSDrive $PathQualifier.Trim(":")).Path
						$QueryPath = If ([string]::IsNullOrEmpty($PathNoQualifier)) {$PSDriveLocation} Else {$PSDriveLocation.TrimEnd("\") + "\" + $PathNoQualifier.TrimStart("\")}
						"Rooted path relative to existing drive location detected; drive location is '$($PSDriveLocation)'." | Write-Verbose
					} Else {
						$QueryPath = $LiteralPath
						"Rooted path relative to non-existing drive location detected; taking the path as it is." | Write-Verbose
					}
				}
			} ElseIf ($LiteralPath.StartsWith("\")) {
				$QueryPath = $PSDrive + $LiteralPath
				"Non-rooted path relative to the current drive detected; current drive is '$($PSDrive)'." | Write-Verbose
			} Else {
				$QueryPath = $PSLocation.TrimEnd("\") + "\" + $LiteralPath
				"Non-rooted path relative to the current folder detected; current folder is '$($PSLocation)'." | Write-Verbose
			}
			$QueryPathQualifier = Split-Path -Path $QueryPath -Qualifier -ErrorAction SilentlyContinue
			If ($QueryPathQualifier.Length -gt 2) {	## PSDrive with more than one letter found; [System.IO.Path]::GetFullPath() can't handle this
				"Native PS drive '$($QueryPathQualifier)' detected; will temporarily work with drive A:." | Write-Verbose
				$RestoreQueryPathQualifier = $True
				$QueryPath = "A:\" + (Split-Path -Path $QueryPath -NoQualifier).TrimStart("\")
			} Else {
				$RestoreQueryPathQualifier = $False
			}
			"Will try to resolve '$($QueryPath)'." | Write-Verbose
			
			Try {
				## A qualifier based on the current PS location has been added to the path, so GetFullPath() will not require [System.Environment]::CurrentDirectory to be set correctly.
				$FullPath = [System.IO.Path]::GetFullPath($QueryPath)
				
				If ($RestoreQueryPathQualifier) {	## The original path had a qualifier longer than 1 character
					$FullPath = $QueryPathQualifier + "\" + (Split-Path -Path $FullPath -NoQualifier).TrimStart("\")
				}
				If ($AsUnc -and (-not $FullPath.StartsWith("\\"))) {
					$Share = $Null
					If ($MappedDisk = Get-WmiObject -Class "Win32_NetworkConnection" | ? {$_.LocalName -eq $QueryPathQualifier}) {
						$Share = $MappedDisk.RemotePath
						"Drive $($QueryPathQualifier) is a plain network drive and resolves to '$($Share)'." | Write-Verbose
					} ElseIf ($MappedDisk = Get-PSDrive -PSProvider FileSystem | ? {($_.Name -eq $QueryPathQualifier.Trim(":")) -and $_.Root.StartsWith("\\")}) {
						$Share = $MappedDisk.Root
						"Drive $($QueryPathQualifier) is a PS network drive and resolves to '$($Share)'." | Write-Verbose
					} ElseIf (Get-WmiObject -Class "Win32_MappedLogicalDisk" | ? {($_.Name -eq $QueryPathQualifier) -and [string]::IsNullOrEmpty($_.ProviderName)}) {
						## If it's considered a network drive, but has no provider, it's probably a substituted drive.
						## Output sample of subst.exe:
						## W:\: => C:\Windows
						## U:\: => UNC\<Server>\<Share>
						& subst.exe | ? {$_ -match ([regex]::Escape("$($QueryPathQualifier)\: => UNC\") + '(?<ProviderName>.+\\.+\Z)')} | % {$Share = "\\" + $Matches.ProviderName}
						If ($Share) {
							"Drive '$($QueryPathQualifier)' is a 'subst'ituted network drive and resolves to '$($Share)'." | Write-Verbose
						} Else {
							"Drive '$($QueryPathQualifier)' seems to be a network drive, but the provider can't be determined." | Write-Warning
						}
					} Else {
						"Drive $($QueryPathQualifier) is not a network drive." | Write-Verbose
					}
					If ($Share) {
						$FullPath = $Share.TrimEnd("\") + "\" + (Split-Path -Path $FullPath -NoQualifier).TrimStart("\")
					}
				}
				$FullPath | Write-Output
			} Catch {
				$_.Exception.Message | Write-Error
			}
		}
	}
	End {
	}
}

Function Get-BLHyperVHostingServer {
## Returns the host name running the guest computer.
## If -Full is specified, returns an object with additional information about the host.
## Requires a host running Server 2008 R2 or later, and a guest running the Integration Services.
[CmdletBinding()]
Param(
	[switch]$Full,
	[string]$ComputerName
)
	If ([string]::IsNullOrEmpty($ComputerName)) {
		$ComputerName = $ENV:ComputerName
	}
	If (Get-BLRegistryKeyX64 -Path "HKLM:\SOFTWARE" -ComputerName $ComputerName) {
		If ($GuestParameters = Get-BLRegistryKeyX64 -Path "HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters" -ComputerName $ComputerName -ErrorAction SilentlyContinue) {
			"The guest '$(If ($ComputerName -eq '.') {$ENV:ComputerName} Else {$ComputerName})' is running on host '$($GuestParameters.HostName)'." | Write-Verbose
			If ($Full) {
				Return $GuestParameters | Select-Object -Property * -ExcludeProperty "PS*"
			} Else {
				Return $GuestParameters.HostName
			}
		} Else {
			"No information about the host found; is it really a VM guest, and are the Integration Services running?" | Write-Warning
			Return
		}
	} Else {
		## Access to the registry on the remote machine not possible; Get-BLRegistryKeyX64 will have written an error message.
		Return
	}
}

Function Get-BLLocalGroupMembers {
## Old name: SCCM:Get-LocalGroupMembers
## Determines a local group's members
Param (
	[string] $GroupName = $(throw "Group name not specified"),
	[string] $ComputerName = $ENV:ComputerName
)
	Try {
		If ([ADSI]::Exists("WinNT://$ComputerName/$GroupName,group")) {
			$Group = [ADSI]("WinNT://$ComputerName/$GroupName,group")
			$Members = @()
			$Group.Members() | % {
				$AdsPath = $_.GetType().InvokeMember("Adspath", 'GetProperty', $null, $_, $null)
				# Domain members will have an ADSPath like WinNT://DomainName/UserName.
				# Local accounts will have a value like WinNT://DomainName/ComputerName/UserName.
				$a = $AdsPath.split('/',[StringSplitOptions]::RemoveEmptyEntries)
				$name = $a[-1]
				$domain = $a[-2]
				$members += "$domain\$name"
			}
			return $members
		} Else {
			return @()
		}
	} Catch {
		$_ | Out-String | Write-BLLog -LogType CriticalError
		Return 1
	}
}

Function Get-BLLocalUser {
[CmdletBinding()]
Param(
	[Parameter(ValueFromPipeline=$True, Position=0)]
	[Object[]]$Name,
	[string]$ComputerName = $ENV:ComputerName
)
	Begin {
	}
	Process {
		If ($Name) {
			ForEach ($User In $Name) {
				$User = $User.ToString()
				Get-BLAdsiObject -Path "WinNT://$($ComputerName)/$($User),User"
			}
		} Else {
			If ($AdsiComputer = Get-BLAdsiObject -Path "WinNT://$($ComputerName),Computer") {
				$AdsiComputer.psbase.Children | Where-Object {$_.psbase.schemaClassName -eq "User"}
			}
		}
	}
	End {
	}
}

Function Get-BLLogonSession {
<#
.SYNOPSIS
Returns a list of users currently logged on.

.DESCRIPTION
The function Get-BLLogonSession returns a list of users currently logged on to a computer.

.PARAMETER ComputerName
The name of the computer on which to query the logged unsers.
Default is the local computer.
An array of names can be passed as well, and pipeline input is accepted.

.PARAMETER WithActiveProcessOnly
Only returns sessions that have at least one process running.

.OUTPUTS
A PSCustomObject with the following properties:
	UserName
	Sid
	StartTime
	LogonType
	LogonTypeName
	ComputerName

.EXAMPLE
$Result = Get-BLLogonSession -WithActiveProcessOnly
#>
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)][ValidateNotNull()]
	[string[]]$ComputerName = @("."),
	[Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$False)]
	[switch]$WithActiveProcessOnly
)
	## 'Win32_LogonSession class', https://msdn.microsoft.com/en-us/library/aa394189(v=vs.85).aspx
	## 'Win32_LoggedOnUser class', https://msdn.microsoft.com/en-us/library/aa394172(v=vs.85).aspx
	Begin {
		$LS_LogonType = @{
			 "0" = "System"						## Used only by the System account.
			 "2" = "Interactive"				## Intended for users who are interactively using the machine, such as a user being logged on by a terminal server, remote shell, or similar process.
			 "3" = "Network"					## Intended for high-performance servers to authenticate clear text passwords. LogonUser does not cache credentials for this logon type.
			 "4" = "Batch"						## Intended for batch servers, where processes can be executed on behalf of a user without their direct intervention; or for higher performance servers that process many clear-text authentication attempts at a time, such as mail or web servers. LogonUser does not cache credentials for this logon type.
			 "5" = "Service"					## Indicates a service-type logon. The account provided must have the service privilege enabled.
			 "6" = "Proxy"						## Indicates a proxy-type logon.
			 "7" = "Unlock"						## This logon type is intended for GINA DLLs logging on users who are interactively using the machine. This logon type allows a unique audit record to be generated that shows when the workstation was unlocked.
			 "8" = "NetworkCleartext"			## Windows Server 2003:  Preserves the name and password in the authentication packages, allowing the server to make connections to other network servers while impersonating the client. This allows a server to accept clear text credentials from a client, call LogonUser, verify that the user can access the system across the network, and still communicate with other servers.
			 "9" = "NewCredentials"				## Windows Server 2003:  Allows the caller to clone its current token and specify new credentials for outbound connections. The new logon session has the same local identify, but uses different credentials for other network connections.
			"10" = "RemoteInteractive"			## Terminal Services session that is both remote and interactive.
			"11" = "CachedInteractive"			## Attempt cached credentials without accessing the network.
			"12" = "CachedRemoteInteractive"	## Same as RemoteInteractive. This is used for internal auditing.
			"13" = "CachedUnlock"				## Workstation logon.
		}
	}
	
	Process {
		ForEach ($Computer In $ComputerName) {
			If ($Computer -eq ".") {
				$HostName = $ENV:ComputerName
			} Else {
				$HostName = $Computer
			}
			Try {
				If ($WithActiveProcessOnly) {
					"[$(Get-Date -Format 'yyyyMMdd-HHmmss')] Enumerating processes on '$($Computer)' ..." | Write-Verbose
					## Required because Win32_LogonSession tends to return stale data, that is, logons that have already logged off and appear nowhere else.
					$ActiveSessions = Get-WmiObject -Namespace "Root\CIMv2" -Class "Win32_Process" -ComputerName $Computer |
						? {Try {$_.GetOwner().ReturnValue -eq 0} Catch {}} |
						Select-Object -Unique -Property `
							SessionId,
							@{Name="UserName"; Expression={$_.GetOwner().Domain + "\" + $_.GetOwner().User}},
							@{Name="Sid"; Expression={$_.GetOwnerSid().Sid}},
							@{Name="LogonId"; Expression={$Sid = $_.GetOwnerSid().Sid; ($LoggedOnUsers | ? {$_.Sid -eq $Sid}).LogonId}}
					$ActiveSids = $ActiveSessions | Select-Object -ExpandProperty Sid
				} Else {
					"[$(Get-Date -Format 'yyyyMMdd-HHmmss')] Doing a quick list on '$($Computer)', may contain stale logon data ..." | Write-Verbose
				}
				
				"[$(Get-Date -Format 'yyyyMMdd-HHmmss')] Enumerating logon sessions on '$($Computer)' ..." | Write-Verbose
				ForEach ($LogonSession In (Get-WmiObject -Namespace "Root\CIMv2" -Class "Win32_LogonSession" -ComputerName $Computer)) {
					$LoggedOnUser = Get-WmiObject -Namespace "Root\CIMv2" -Query "Associators of {Win32_LogonSession.LogonId=$($LogonSession.LogonId)} Where AssocClass=Win32_LoggedOnUser Role=Dependent" -ComputerName $ComputerName -ErrorAction SilentlyContinue | 
						Select-Object -Property `
							@{Name="UserName"; Expression={"$($_.Domain)\$($_.Name)"}},
							Sid,
							@{Name="StartTime"; Expression={[Management.ManagementDateTimeConverter]::ToDateTime($LogonSession.StartTime)}},
							@{Name="LogonType"; Expression={$LogonSession.LogonType}},
							@{Name="LogonTypeName"; Expression={$LS_LogonType[$LogonSession.LogonType.ToString()]}},
							@{Name="ComputerName"; Expression={$HostName}}
						
					If (($ActiveSids -contains $LoggedOnUser.Sid) -Or !$WithActiveProcessOnly) {
						$LoggedOnUser | Write-Output
					}
				}
			} Catch {
				$_ | Out-String | Write-Error
			}
		}
	}
}

Function Get-BLNetInterfaceIndex {
[CmdletBinding(DefaultParameterSetName="Index_By_Name")]
Param(
	[Parameter(Position=0, ParameterSetName="Index_By_Name")]
	[string]$InterfaceName,
	[Parameter(Position=0, ParameterSetName="Index_By_IP")]
	[string]$InterfaceIP,
	[Parameter(Position=0, ParameterSetName="Index_By_MAC")]
	[string]$InterfaceMAC
)
	Switch ($PsCmdlet.ParameterSetName) {
		"Index_By_Name" {
			If ($InterfaceName -eq "Software Loopback Interface 1") {
				[uint32]1
			} Else {
				(Get-WmiObject -Namespace "Root\cimv2" -Class "Win32_NetworkAdapter" | Where {$_.NetConnectionID -eq $InterfaceName}).InterfaceIndex
			}
		}
		"Index_By_IP" {
			If ($InterfaceIP -eq "127.0.0.1") {
				[uint32]1
			} Else {
				(Get-WmiObject -Namespace "Root\cimv2" -Class "Win32_NetworkAdapterConfiguration" | Where {$_.IPAddress -contains $InterfaceIP}).InterfaceIndex
			}
		}
		"Index_By_MAC" {
			If (($InterfaceMAC -eq "") -or ($InterfaceMAC -eq "00:00:00:00:00:00")) {
				[uint32]1
			} Else {
				(Get-WmiObject -Namespace "Root\cimv2" -Class "Win32_NetworkAdapterConfiguration" | Where {$_.MACAddress -eq $InterfaceMAC}).InterfaceIndex
			}
		}
	}
}

Function Get-BLNetRoute([string[]]$Destination, [string[]]$InterfaceIP, [string[]]$InterfaceName, [string[]]$InterfaceIndex, [string[]]$InterfaceMAC) {
## Returns the IPv4 routing table; works on Server 2008 and later.
## Note that the 'Interface' property returned may be an array if more than 1 IP address is assigned to an interface!
## NOT compatible with the Get-NetRoute Cmdlet available since Server 2012.
## Get-NetRoute displays different Metric values than 'Win32_IP4RouteTable' or 'route print' do, and even 'Get-WmiObject -NameSpace "Root\StandardCimv2" -Class "MSFT_NetRoute"'
## differs from its definition at 'MSFT_NetRoute class', http://msdn.microsoft.com/en-us/library/hh872448(v=vs.85).aspx; bug or by design?
## 'Win32_IP4RouteTable class', http://msdn.microsoft.com/en-us/library/aa394162(v=vs.85).aspx
	$NetworkAdapterConfigurations = Get-WmiObject -Namespace "Root\cimv2" -Class "Win32_NetworkAdapterConfiguration" | Where {$_.IPAddress}
	$NetworkAdapters = Get-WmiObject -Namespace "Root\cimv2" -Class "Win32_NetworkAdapter" | Where {$_.NetEnabled}
	$PersistedRoutingTable = Get-WmiObject -Namespace "Root\cimv2" -Class "Win32_IP4PersistedRouteTable"
	$RoutingTable = Get-WmiObject -Namespace "Root\cimv2" -Class "Win32_IP4RouteTable" | Select-Object -Property `
		Destination,
		Mask,
		@{Name="Gateway"; Expression={$_.NextHop}},
		@{Name="Interface"; Expression={
			If ($_.InterfaceIndex -eq 1) {
				"127.0.0.1"
			} Else {
				$ifRoute = $_.InterfaceIndex
				($NetworkAdapterConfigurations | Where {$_.InterfaceIndex -eq $ifRoute}).IPAddress
			}
		}},
		@{Name="Metric"; Expression={	## For persistent routes, this value is higher than the value actually set when adding the route (+5 in W2k8R2, W2k12); use MetricP for the "real" metric
			$_.Metric1
		}},
		@{Name="InterfaceName"; Expression={
			If ($_.InterfaceIndex -eq 1) {
				"Software Loopback Interface 1"
			} Else {
				$ifRoute = $_.InterfaceIndex
				($NetworkAdapters | Where {$_.InterfaceIndex -eq $ifRoute}).NetConnectionID
			}
		}},
		InterfaceIndex,
		@{Name="InterfaceMAC"; Expression={
			If ($_.InterfaceIndex -eq 1) {
				""
			} Else {
				$ifRoute = $_.InterfaceIndex
				($NetworkAdapters | Where {$_.InterfaceIndex -eq $ifRoute}).MACAddress
			}
		}},
		@{Name="Persistent"; Expression={
			$rtName = $_.Name
			$rtMask = $_.Mask
			$rtNextHop = $_.NextHop
			If ($PersistedRoutingTable | Where {($_.Name -eq $rtName) -And ($_.rtMask -eq $Mask) -And ($_.rtNextHop -eq $NextHop)}) {
				$True
			} Else {
				$False
			}
		}},
		@{Name="MetricP"; Expression={
			$rtName = $_.Name
			$rtMask = $_.Mask
			$rtNextHop = $_.NextHop
			If ($prt = $PersistedRoutingTable | Where {($_.Name -eq $rtName) -And ($_.rtMask -eq $Mask) -And ($_.rtNextHop -eq $NextHop)}) {
				$prt.Metric1
			} Else {
				$Null
			}
		}}
		
	Return ($RoutingTable | Where {
		(-Not $Destination -Or ($Destination -contains $_.Destination)) -And
		(-Not $InterfaceIP -Or (Compare-Object -ReferenceObject $InterfaceIP -DifferenceObject $_.Interface -IncludeEqual -ExcludeDifferent)) -And
		(-Not $InterfaceName -Or ($InterfaceName -contains $_.InterfaceAlias)) -And
		(-Not $InterfaceIndex -Or ($InterfaceIndex -contains $_.InterfaceIndex)) -And
		(-Not $InterfaceMAC -Or ($InterfaceMAC -contains $_.InterfaceMAC))
	})
}

Function Get-BLOSArchitecture([string]$ComputerName = ".") {
## Gets the real OS architecture, whether called from x86 or x64 Powershell.
## Returns either "x64" or "x86"
	If ([string]::IsNullOrEmpty($ComputerName)) {
		$ComputerName = "."
	}
	Switch ((Get-WmiObject Win32_OperatingSystem -ComputerName $ComputerName).OSArchitecture) {
		"64-bit"	{Return "x64"}
		"32-bit"	{Return "x64"}
		default		{Return}
	}
}

Function Get-BLOSVersion {
[CmdletBinding(DefaultParameterSetName="VersionDetails")]
Param(
	[Parameter(ParameterSetName="VersionDetails")][ValidateSet("Major", "Minor", "Build", "Revision")]
	[string]$VersionDetails = "Build",
	[Parameter(ParameterSetName="Single")][ValidateSet("Major", "Minor", "Build", "Revision")]
	[string]$Single = "Major",
	[Parameter(ParameterSetName="ServicePack")]
	[switch]$ServicePack,
	[Parameter(ParameterSetName="ServicePack")][ValidateSet("Major", "Minor")]
	[string]$SPDetails = "Major",
	[Parameter(ParameterSetName="Caption")]
	[switch]$Name
)
## Returns the OS version.
	Switch ($PsCmdlet.ParameterSetName) {
		"VersionDetails"		{
			$OSVersion = [System.Environment]::OSVersion.Version
			[string]$Result = $OSVersion.Major
			If (($VersionDetails -eq "Minor") -Or ($VersionDetails -eq "Build") -Or ($VersionDetails -eq "Revision")) {$Result = $Result + "." + $OSVersion.Minor}
			If (($VersionDetails -eq "Build") -Or ($VersionDetails -eq "Revision")) {$Result = $Result + "." + $OSVersion.Build}
			If ($VersionDetails -eq "Revision") {$Result = $Result + "." + $OSVersion.Revision}
		}
		"Single"		{
			$OSVersion = [System.Environment]::OSVersion.Version
			$Result = $OSVersion.$Single
		}
		"ServicePack"	{
			$Win32OS = Get-WmiObject -Query "SELECT ServicePackMajorVersion, ServicePackMinorVersion FROM Win32_OperatingSystem"
			[string]$Result = $Win32OS.ServicePackMajorVersion
			If ($SPDetails -eq "Minor") {$Result = $Result + "." + $Win32OS.ServicePackMinorVersion}
		}
		"Caption"		{
			$Result = (Get-WmiObject -Class Win32_OperatingSystem).Caption
		}
	}
	Return $Result
}

Function Get-BLPrimaryDNSSuffix() {
## Old name: SCCM:Get-PrimaryDNSSuffix
## Returns the the machine's current Primary DNS Suffix
#	"Entering " + $MyInvocation.MyCommand + " at " + (Get-Date).ToLongTimeString() | Write-BLLog -LogType Information
	$PDS = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters" -ErrorAction SilentlyContinue)."NV Domain"
	If ($PDS -eq $null) {
		$PDS = ""
	}
	Return $PDS
#	"Leaving " + $MyInvocation.MyCommand + " with return value $ret " + (Get-Date).ToLongTimeString() | Write-BLLog -LogType Information
}

Function Get-BLScheduledTask {
<#
.SYNOPSIS
Returns the properties of a Scheduled Task.

.DESCRIPTION
The function Get-BLScheduledTask returns the properties of a Scheduled Task.
It uses the 'Schedule.Service' COM object to retrieve the task properties; unlike schtasks.exe, the results are NOT language dependent.
Works on W2k8 and later, including client OS.
Only the properties TaskPath, TaskName, State are compatible with the W2k12 cmdlet 'Get-ScheduledTask', the rest is not.

.PARAMETER ComputerName
The name of the computer on which to query the task.
Default is the local computer.
An array of names can be passed as well, and pipeline input is accepted.

.PARAMETER TaskName
Specifies an array of one or more names of a scheduled task.

.PARAMETER TaskPath
Specifies an array of one or more paths for scheduled tasks in Task Scheduler namespace. You can use \ for the root folder. If you do not specify a path, the cmdlet uses the root folder.

.PARAMETER Force
Allows the function to get hidden tasks as well.

.OUTPUTS
A PSCustomObject with the following properties:
	TaskPath <String>
	TaskName <String>
	State <String>:
		Unknown, Disabled, Queued, Ready, Running
	Definition <System.__ComObject>
	LastRunTime <DateTime>
	LastTaskResult <Int32>
	NextRunTime <DateTime>
	Xml <Xml.XmlDocument>
	ComputerName <String>

.EXAMPLE
$Tasks = Get-BLScheduledTask

.LINK
Task Scheduler 2.0 Enumerated Types: https://msdn.microsoft.com/en-us/library/windows/desktop/aa383590(v=vs.85).aspx
ITaskService::Connect method: https://msdn.microsoft.com/en-us/library/windows/desktop/aa381833(v=vs.85).aspx
ITaskFolder::GetFolder method: https://msdn.microsoft.com/en-us/library/windows/desktop/aa381348(v=vs.85).aspx
ITaskFolder::GetTasks method: https://msdn.microsoft.com/en-us/library/windows/desktop/aa381357(v=vs.85).aspx
#>
[CmdletBinding()]
Param(
	[string[]]$TaskName,
	[string[]]$TaskPath = @("\"),
	[string]$ComputerName = $ENV:ComputerName,
	[switch]$Force
)
	$TASK_STATE = @{
		0 = 'Unknown';
		1 = 'Disabled';
		2 = 'Queued';
		3 = 'Ready';
		4 =	'Running'
	}
	Try {
		If ($Force) {$TaskFlags = 1} Else {$TaskFlags = 0}
		$TaskService = New-Object -ComObject "Schedule.Service"
		$TaskService.Connect($ComputerName)
		ForEach ($Path In $TaskPath) {
			If ($Path -ne "\") {
				$Path = $Path.TrimEnd("\")
			}
			$TaskFolder = $TaskService.GetFolder($Path)
			$TasksAll = $TaskFolder.GetTasks($TaskFlags)
			If ($TaskName) {
				ForEach ($Name In $TaskName) {
					If ($Tasks = ($TasksAll | ? {$_.Name -like $Name})) {
					$Tasks |
						Select-Object -Property `
							@{Name="TaskPath"; Expression={$Parent = Split-Path -Path $_.Path -Parent; If ($Parent -eq "\") {$Parent} Else {"$($Parent)\"}}},	## The COM object returns the path including the task! The W2k12 cmdlet only returns the path, so we do the same.
							@{Name="TaskName"; Expression={$_.Name}},
							@{Name="State"; Expression={$TASK_STATE[$_.State]}},
							@{Name="Definition"; Expression={$_.Definition}},
							LastRunTime,
							LastTaskResult,
							NextRunTime,
							@{Name="Xml"; Expression={[xml]$_.Xml}},
							@{Name="ComputerName"; Expression={$ComputerName}} |
						Write-Output
					}
				}
			} Else {
				$TasksAll |
					Select-Object -Property `
						@{Name="TaskPath"; Expression={$Parent = Split-Path -Path $_.Path -Parent; If ($Parent -eq "\") {$Parent} Else {"$($Parent)\"}}},	## The COM object returns the path including the task! The W2k12 cmdlet only returns the path, so we do the same.
						@{Name="TaskName"; Expression={$_.Name}},
						@{Name="State"; Expression={$TASK_STATE[$_.State]}},
						@{Name="Definition"; Expression={$_.Definition}},
						LastRunTime,
						LastTaskResult,
						NextRunTime,
						@{Name="Xml"; Expression={[xml]$_.Xml}},
						@{Name="ComputerName"; Expression={$ComputerName}} |
					Write-Output
			}
		}
	} Catch {
		$_.Exception.Message | Write-Error
	} Finally {
		If ($TaskService) {
			[Runtime.InteropServices.Marshal]::FinalReleaseComObject($TaskService) | Out-Null
		}
	}
}

Function Get-BLShortcut() {
<#
.SYNOPSIS
Returns the properties of a shortcut.

.DESCRIPTION
The function New-BLShortcut returns the properties of a shortcut.
Note that the shortcut's name and folder are specified in different arguments to allow easier access to the usual locations like start menu and desktop.

.PARAMETER Name
Mandatory
The name (WITHOUT PATH) of the shortcut to get.
The extension '.lnk' can be omitted.

.PARAMETER CommonProgramsPath
Optional
Gets the shortcut from the specified path under the 'All Programs' start menu folder (default).
Omit this argument or set it to "" to get the shortcut from the root of 'All Programs'.

.PARAMETER CommonStartup
Optional
Gets the shortcut from the "Common Startup" folder.

.PARAMETER CommonDesktop
Optional
Gets the shortcut from the "Common Desktop" folder.

.PARAMETER Path
Optional
The full path (WITHOUT SHORTCUT NAME) to the shortcut folder.

.OUTPUTS
System.Object

.EXAMPLE
Get-BLShortcut -Name "BGInfo" -CommonStartup

.EXAMPLE
Get-BLShortcut -Name "BGInfo" -Path "C:\RIS\Tools\BgInfo"

.LINK
Remove-BLShortcut
New-BLShortcut
Reference (Windows Script Host) > CreateShortcut Method: https://msdn.microsoft.com/en-us/library/xsy6k3ys(v=vs.84).aspx
#>
[CmdletBinding(DefaultParameterSetName="CommonPrograms")]
Param (
	[Parameter(Mandatory=$False, Position=0)][ValidateNotNull()]
	[string]$Name = $(Throw {"Required argument '-Name' not passed!"}),
	[Parameter(Mandatory=$False, Position=1, ParameterSetName="CommonPrograms")]
	[string]$CommonProgramsPath = "",
	[Parameter(Mandatory=$False, Position=1, ParameterSetName="CommonStartup")]
	[switch]$CommonStartup,
	[Parameter(Mandatory=$False, Position=1, ParameterSetName="CommonDesktop")]
	[switch]$CommonDesktop,
	[Parameter(Mandatory=$False, Position=1, ParameterSetName="FullPath")]
	[string]$Path
)
	Switch ($PsCmdlet.ParameterSetName) {
		"CommonPrograms" {
			$FullFolder = Join-Path -Path (Get-BLSpecialFolder -Folder "CommonPrograms") -ChildPath $CommonProgramsPath
		}
		"CommonStartup" {
			$FullFolder = Get-BLSpecialFolder -Folder "CommonStartup"
		}
		"CommonDesktop" {
			$FullFolder = Get-BLSpecialFolder -Folder "CommonDesktopDirectory"
		}
		"FullPath" {
			$FullFolder = $Path
		}
	}
	If ([IO.Path]::GetExtension($Name) -eq ".lnk") {
		$scName = Join-Path $FullFolder $Name
	} Else {
		$scName = Join-Path $FullFolder "$($Name).lnk"
	}
	If (Test-Path -Path $scName -PathType Leaf) {
		$Shell = New-Object -ComObject WScript.Shell
		$Shortcut = $Shell.CreateShortcut($scName) | Select-Object -Property *, @{Name="IsAdvertised"; Expression={$False}}
		If ($Shortcut.TargetPath.ToUpper().StartsWith("${ENV:Systemroot}\Installer\".ToUpper())) {
			$MsiProperties = Get-BLMsiProperties -Path $scName -ErrorAction SilentlyContinue
			If ($MsiProperties -And ![string]::IsNullOrEmpty($MsiProperties.ShortcutTarget)) {
				$Shortcut.TargetPath = $MsiProperties.ShortcutTarget
				$Shortcut.IsAdvertised = $True
			}
		}
		$Shortcut | Write-Output
		[Runtime.InteropServices.Marshal]::FinalReleaseComObject($Shell) | Out-Null
		Remove-Variable -Name Shell
	} Else {
		"Shortcut file '$($scName)' not found!" | Write-Error
	}
}

Function Get-BLShortPath {
[CmdletBinding(DefaultParameterSetName="FullPath")]
Param (
	[Parameter(ValueFromPipeline=$True, Position=0)]
	[object[]]$Path,
	[Parameter(ParameterSetName="Parent", Position=1)]
	[switch]$Parent,
	[Parameter(ParameterSetName="Leaf", Position=1)]
	[switch]$Leaf
)
	Begin {
		$fso = New-Object -ComObject Scripting.FileSystemObject
	}
	Process {
		Try {
			$Path | ForEach-Object {
				If ($_ -is [System.IO.FileInfo]) {
					$Item = $_
				} Else {
					$Item = Get-Item -Path ([string]$_) -ErrorAction Stop
				}
				If ($Item.PSIsContainer) {
					$ShortPath = $fso.GetFolder($Item.FullName).ShortPath
				} Else {
					$ShortPath = $fso.GetFile($Item.FullName).ShortPath
				}
				Switch ($PsCmdlet.ParameterSetName) {
					"FullPath"	{$ShortPath | Write-Output}
					"Parent"	{Split-Path -Path $ShortPath -Parent | Write-Output}
					"Leaf"		{Split-Path -Path $ShortPath -Leaf | Write-Output}
				}
			}
		} Catch {
			$_.Exception.Message | Write-Error
		}
	}
	End {
		[Runtime.InteropServices.Marshal]::FinalReleaseComObject($fso) | Out-Null
	}
}

Function Get-BLSIDFromAccount {
## Returns the SID of a given account (domain or local).
## LEGACY - use the more versatile Resolve-BLSid
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)]
	[string]$Account
)
	Process {
		Try {
			If ($Account.Contains("\")) {
				$Principal = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList $Account.Split("\")[0], $Account.Split("\")[1]
			} Else {
				$Principal = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList $Account
			}
			$PrincipalSID = $Principal.Translate([System.Security.Principal.SecurityIdentifier])
			Return $PrincipalSID.Value
		} Catch {
			$_ | Out-String | Write-BLLog -LogType CriticalError
			Return $Null
		}
	}
	End {
		"Get-BLAccountFromSID is still fully working, but deprecated since 04.2015; please use Resolve-BLSid instead." | Write-Warning
	}
}

Function Get-BLSpecialFolder([Environment+SpecialFolder]$Folder) {
	Try {
		Return [environment]::GetFolderpath([Environment+SpecialFolder]$Folder)
	} Catch {
		"Could not retrieve special folder '$($Folder.ToString())'" | Write-BLLog -LogType CriticalError
		Return $Null
	}
}

Function Get-BLSymbolicLinkTarget() {
[CmdletBinding()]
Param(
	[object]$Path
)
	If ($Path -is [System.IO.DirectoryInfo]) {
		$PathItem = $Path 
	} Else {
		$PathItem = Get-Item -Path $Path 
	}
	If ($PathItem) {
		Return [BLSymbolicLink]::GetTarget($PathItem)
	} Else {
		Return $Null
	}
}

Function Import-BLRegistryFile($regFile) {
## Old name: SCCM:Import-Regfile
## Invoke regedit /S
	$exitCode = 1 # assume failure until proven otherwise
	$regEditCmd = "reg.exe"
	# Check parameters
	If (!($regFile.Length)) {"No reg file specified." | Write-BLLog -LogType CriticalError; return $exitCode}
	If (!(Test-Path $regFile)) {"File not found - $regFile" | Write-BLLog -LogType CriticalError; return $exitCode}
	# Preparation done. Invoke regedit now
	"Invoking: $regEditCmd import `"$regFile`"" | Write-BLLog -LogType Information
	$exitCode = Start-BLProcess -FileName $regEditCmd -Arguments "import `"$regFile`""
	return $exitCode
}

Function New-BLLocalUser {
[CmdletBinding()]
Param(
	[string]$Name,
	[string]$Password,
	[string]$FullName,
	[string]$Description,
	[bool]$AccountDisabled,
	[bool]$PasswordMustChange,
	[bool]$PasswordCantChange,
	[bool]$PasswordNeverExpires,
	[switch]$ProcessExistingUser,
	[switch]$PassThru,
	[string]$ComputerName = $ENV:ComputerName
)
	If ([string]::IsNullOrEmpty($Name)) {
		Throw "Mandatory argument 'UserName' missing!"
	}
	If ([string]::IsNullOrEmpty($Password)) {
		Throw "Mandatory argument 'Password' missing!"
	}
	$AdsiUser = Get-BLAdsiObject -Path "WinNT://$($ComputerName)/$($Name),User" -ErrorAction SilentlyContinue
	If ($AdsiUser) {
		If (-not $ProcessExistingUser) {
			"User '$($Name)' already exists." | Write-Error
		}
	} Else {
		If (-not ($AdsiComputer = Get-BLAdsiObject -Path "WinNT://$($ComputerName),Computer")) {
			Return
		}
		Try {
			$AdsiUser = $AdsiComputer.Create('User', $Name)
			[void]$AdsiUser.SetPassword($Password)
			[void]$AdsiUser.SetInfo()
		} Catch {
			$_.Exception.Message | Write-Error
			Return
		}
		$AdsiLocalUserGroup = $AdsiComputer.psbase.Children | ? {($_.psbase.schemaClassName -eq "Group") -and ((New-Object System.Security.Principal.SecurityIdentifier($_.ObjectSid.Value, 0)).Value -eq "S-1-5-32-545")}
		If (-not ($AdsiLocalUserGroup)) {
			Return
		}
		[void]$AdsiLocalUserGroup.Add($AdsiUser.Path)
	}
	$SetLocalUserArgs = $PSBoundParameters
	$SetLocalUserArgs.Remove("Password") | Out-Null
	$SetLocalUserArgs["Name"] = $AdsiUser
	$SetLocalUserArgs["PassThru"] = $True
	$AdsiUser = Set-BLLocalUser @SetLocalUserArgs
	If ($PassThru) {
		Return $AdsiUser
	}
}

Function New-BLRegistryKey {
## Old name: SCCM:Create-Regkey
## Checks if registry key exists and if not automatically creates it
Param (
	[string]$RegistryKey = $(Throw "A registry key must be specified" | Write-BLLog -LogType CriticalError; Return $false)
)
	[bool]$ExitValue=$False # assume failure unless proven otherwise
	If (($RegistryKey -notlike "HKLM:\*") -and ($RegistryKey -notlike "HKCU:\*")) {
		"Invalid input format, only HKLM:\... or HKCU:\... allowed!" | Write-BLLog -LogType CriticalError
	} Else {
		If (!(Test-Path $RegistryKey)) {
			[string]$RegPartKey = ""
			$RegistrykeyNames = $RegistryKey.Split("\")
			foreach ($RegistrykeyName in $RegistrykeyNames) {
				If ($RegistrykeyName -ne "") {
					If ($RegPartKey -ne "") {
						$RegPartKey = "$RegPartKey\$RegistrykeyName"
						If (!(Test-Path $RegPartKey)) {MKDIR $RegPartKey | Out-Null}
					} Else {
						$RegPartKey = $RegistrykeyName
					}
				}
			}
			If (Test-Path $RegistryKey) {
				$ExitValue = $True
				"Registry key `"$RegistryKey`" created successfully" | Write-BLLog -LogType Information
			} Else {
				"Registry key `"$RegistryKey`" could not be created" | Write-BLLog -LogType CriticalError
			}
		} Else {
			$ExitValue = $True
		}
	}
	Return $ExitValue
}

Function New-BLShortcut {
<#
.SYNOPSIS
Creates a new shortcut or edits an existing one.

.DESCRIPTION
The function New-BLShortcut creates a new shortcut or edits an existing one.
By default, the function will return 0 on success, 1 on error.
If -PassThru is specified, the function will return a file item of the shortcut created on success, $Null on error.

.PARAMETER Name
Mandatory
The name of the shortcut to create.
The extension '.lnk' can be omitted.

.PARAMETER Target
Mandatory
The file to open/start with the shortcut.

.PARAMETER CommonProgramsPath
Optional
Creates the shortcut in a folder under the 'All Programs' start menu folder (default).
A folder path specified here will be created under the 'All Programs' folder if it doesn't exist yet.
Omit this argument or set it to "" to create the shortcut in the root of 'All Programs'.

.PARAMETER CommonStartup
Optional
Creates the shortcut in the "Common Startup" folder.

.PARAMETER CommonDesktop
Optional
Creates the shortcut in the "Common Desktop" folder.

.PARAMETER Path
Optional
The full path to the folder where the shortcut should be created.
The folder must exist before calling the function, it will NOT be created automatically.

.PARAMETER Arguments
Optional
The arguments for the file specifed in Target.

.PARAMETER Description
Optional
A description of what the shortcut does.

.PARAMETER WorkingDir
Optional
The folder from which to run the program.

.PARAMETER WindowStyle
Optional
The window style of the window opened by the shortcut: Normal, Maximized, Minimized

.PARAMETER IconLocation
Optional
The resource file from which to retrieve the icon for the shortcut. Default is the target, index 0.

.PARAMETER IconIndex
Optional
The icon's index in the resource file.

.PARAMETER PassThru
Optional
Returns a file item of the shortcut created on success, $Null on error (instead of the default of 0 on success and 1 on error).

.OUTPUTS
System.Int32 or System.IO.FileInfo (with -PassThru)

.EXAMPLE
New-BLShortcut -Name BGInfo -Target "C:\Program Files\Bginfo\Bginfo.exe" -CommonStartup -Arguments "`"C:\Program Files\Bginfo\bginfo.bgi`" /timer:0 /nolicprompt" -WindowStyle Minimized -Description "Creates a background image with system information" -PassThru

.LINK
Remove-BLShortcut
Get-BLShortcut
Reference (Windows Script Host) > CreateShortcut Method: https://msdn.microsoft.com/en-us/library/xsy6k3ys(v=vs.84).aspx
#>
[CmdletBinding(DefaultParameterSetName="CommonPrograms")]
Param (
	[Parameter(Mandatory=$False, Position=0)][ValidateNotNull()]
	[string]$Name = $(Throw {"Required argument '-Name' not passed!"}),
	[Parameter(Mandatory=$False, Position=1)][ValidateNotNull()]
	[string]$Target = $(Throw {"Required argument '-Target' not passed!"}),
	[Parameter(Mandatory=$False, Position=2, ParameterSetName="CommonPrograms")]
	[string]$CommonProgramsPath = "",
	[Parameter(Mandatory=$False, Position=2, ParameterSetName="CommonStartup")]
	[switch]$CommonStartup,
	[Parameter(Mandatory=$False, Position=2, ParameterSetName="CommonDesktop")]
	[switch]$CommonDesktop,
	[Parameter(Mandatory=$False, Position=2, ParameterSetName="FullPath")]
	[string]$Path,
	[Parameter(Mandatory=$False, Position=3)]
	[string]$Arguments = "",
	[Parameter(Mandatory=$False, Position=4)]
	[string]$Description = "",
	[Parameter(Mandatory=$False, Position=5)]
	[string]$WorkingDir = "",
	[Parameter(Mandatory=$False, Position=6)][ValidateSet("Normal", "Maximized", "Minimized")]
	[string]$WindowStyle = "Normal",
	[Parameter(Mandatory=$False, Position=7)]
	[string]$IconLocation = "",
	[Parameter(Mandatory=$False, Position=8)]
	[int]$IconIndex = 0,
	[Parameter(Mandatory=$False, Position=9)]
	[switch]$PassThru
)
	$ret = 0
	Switch ($PsCmdlet.ParameterSetName) {
		"CommonPrograms" {
			$FullFolder = Join-Path -Path (Get-BLSpecialFolder -Folder CommonPrograms) -ChildPath $CommonProgramsPath
			If (-Not (Test-Path -Path $FullFolder)) {
				New-Item -Path $FullFolder -ItemType Directory | Out-Null
				If (-Not $?) {
					"Could not create the folder '$($FullFolder)'!" | Write-Error
					$ret = 1
				}
			}
		}
		"CommonStartup" {
			$FullFolder = Get-BLSpecialFolder -Folder "CommonStartup"
			If (-Not (Test-Path -Path $FullFolder)) {
				"Shortcut folder '$($FullFolder)' not found!" | Write-Error
				$ret = 1
			}
		}
		"CommonDesktop" {
			$FullFolder = Get-BLSpecialFolder -Folder "CommonDesktopDirectory"
			If (-Not (Test-Path -Path $FullFolder)) {
				"Shortcut folder '$($FullFolder)' not found!" | Write-Error
				$ret = 1
			}
		}
		"FullPath" {
			If ([string]::IsNullOrEmpty($Path) -Or (-Not (Test-Path -Path $Path))) {
				"Shortcut folder '$($Path)' not found!" | Write-Error
				$ret = 1
			} Else {
				$FullFolder = $Path
			}
		}
	}
	If ($ret -eq 0) {
		Switch ($WindowStyle) {
			"Normal"	{$intWindowStyle = 1}
			"Maximized"	{$intWindowStyle = 3}
			"Minimized"	{$intWindowStyle = 7}
		}
		$TargetDir = Split-Path $Target -Parent
		If ($TargetDir -eq "") {
			$NewTarget = (Get-Command $Target -ErrorAction SilentlyContinue).Path
			If ($NewTarget -eq $Null) {
				"Could not find shortcut target '$($Target)'!" | Write-Error
				$ret = 1
			} Else {
				$Target = $NewTarget
				$TargetDir = Split-Path $Target -Parent
			}
		}
		If ($WorkingDir -eq "") {
			$WorkingDir = $TargetDir
		}
		If ($ret -eq 0) {
			$wsh = New-Object -ComObject Wscript.Shell
			If ([IO.Path]::GetExtension($Name) -eq ".lnk") {
				$scName = Join-Path $FullFolder $Name
			} Else {
				$scName = Join-Path $FullFolder "$($Name).lnk"
			}
			$sc = $wsh.CreateShortcut($scName)
			$sc.TargetPath = $Target
			$sc.WorkingDirectory = $WorkingDir 
			$sc.Arguments = $Arguments
			$sc.Description = $Description
			$sc.WindowStyle = $intWindowStyle
			If (-Not [string]::IsNullOrEmpty($IconLocation)) {
				$sc.IconLocation = "$($IconLocation), $($IconIndex)"
			}
			$sc.Save()
			[Runtime.InteropServices.Marshal]::FinalReleaseComObject($wsh) | Out-Null
		}
	}
	If ($ret -eq 0) {
		If ($PassThru) {
			Return (Get-Item -Path $scName)
		} Else {
			Return 0
		}
	} Else {
		If ($PassThru) {
			Return
		} Else {
			Return 1
		}
	}
}

Function Remove-BLLocalGroupMember {
## Removes a domain account / domain group from local groups
Param (
	[string] $GroupName = "",  # if ""  -AdminGroup or -RDUGroup are intepreted
	[string] $UserName = $(throw "user name not specified"),
	[string] $DomainName = $ENV:UserDomain,
	[string] $ComputerName = $ENV:ComputerName,
    [switch] $AdminGroup = $false,
    [switch] $RDGroup = $false
)
	Try {
		$SID = ""
        if ($GroupName -eq "") {
            if ($RDGroup) {
                $SID = "S-1-5-32-555"    # "Remote Desktop Users"
            }
            if ($AdminGroup) {
                $SID = "S-1-5-32-544"    # "Administrators"
            }
            if ($SID -eq "") 
            {
                "Remove-BLLocalGroupMember: must specify -GroupName or -AdminGroup or -RDGroup" | Write-BLLog -LogType CriticalError
                return 1
            }
        }
        if ($GroupName -eq "") {
            $GroupName = (Get-WmiObject -Query "SELECT * FROM Win32_Group WHERE LocalAccount='TRUE' AND SID='$SID'" -ComputerName $ComputerName).Name
        }

		[Array] $GroupMembers = Get-BLLocalGroupMembers $GroupName -ComputerName $ComputerName
		If ($GroupMembers -contains "$DomainName\$UserName") {
			([ADSI]"WinNT://$computerName/$GroupName,group").Remove("WinNT://$domainName/$userName") | Out-Null
			"User '$domainName\$userName' is now removed of local group '$GroupName'." | Write-BLLog -LogType Information
		} Else {
			"User '$domainName\$userName' was already removed of local group '$GroupName' or never a member." | Write-BLLog -LogType Information 
		}
		Return 0
	} Catch {
		$_ | Out-String | Write-BLLog -LogType CriticalError
		Return 1
	}
}

Function Remove-BLLocalUser {
[CmdletBinding()]
Param(
	[Parameter(ValueFromPipeline=$True, Position=0)]
	[object[]]$Name,
	[string]$ComputerName = $ENV:ComputerName
)	
	Begin {
		$AdsiComputer = $Null
	}
	Process {
		ForEach ($User In $Name) {
			Try {
				If ($User -is [System.DirectoryServices.DirectoryEntry]) {
					$AdsiUser = $User
					If ($AdsiUser.schemaClassName -ne 'User') {
						"Object '$($AdsiUser.Path)' is of type '$($AdsiUser.schemaClassName)', not 'User'." | Write-Error
						Continue
					}
					$AdsiUser.Path -match "\AWinNT://(?<ComputerName>.+)/$($AdsiUser.Name.ToString())\Z" | Out-Null
					If (-not ($AdsiUserComputer = Get-BLAdsiObject -Path "WinNT://$($Matches['ComputerName']),Computer" -ErrorAction Continue)) {
						Continue
					}
					[void]$AdsiUserComputer.Delete('User', $AdsiUser.Name.Value)
				} Else {
					If (-not $AdsiComputer) {
						$AdsiComputer = Get-BLAdsiObject -Path "WinNT://$($ComputerName),Computer" -ErrorAction Stop
					}
					$User = $User.ToString()
					If (-not ($AdsiUser = Get-BLAdsiObject -Path "WinNT://$($ComputerName)/$($User),User")) {
						Continue
					}
					[void]$AdsiComputer.Delete('User', $AdsiUser.Name.Value)
				}
			} Catch {
				$_.Exception.Message | Write-Error
			}
		}
	}
	End {
	}
}

Function Remove-BLScheduledTask {
## Old name: SCCM:Remove-ScheduledTask
## Removes an existing task by calling schtasks.exe
Param ( 
	[string]$name=$(throw "Taskname not specified"),
	[string]$computername = $env:computername,
	[switch]$Quiet
)
	Process {
		trap {"An error occurred while trying to remove a scheduled task.´nLast Error was:`n$($Error[0])" | Write-BLLog -LogType CriticalError; return 1; continue}
		$schtasks = Join-Path $Env:SystemRoot "system32\schtasks.exe"
		If ($computername -eq "$env:computername") {
			$Task = Get-BLScheduledTask -TaskName $name
#			$Result = Start-BLProcess -Filename $schtasks -Arguments "/Query /TN `"$name`""
		} Else {
			$Task = Get-BLScheduledTask -TaskName $name -ComputerName $computername
#			$Result = Start-BLProcess -Filename $schtasks -Arguments "/Query /S `"$computername`" /TN `"$name`""
		}
		If ($Task) {
			If ($computername -eq "$env:computername") {
				$Result = Start-BLProcess -Filename $schtasks -Arguments "/Delete /TN `"$name`" /F"
			} Else {
				$Result = Start-BLProcess -Filename $schtasks -Arguments "/Delete /S `"$computername`" /TN `"$name`" /F"
			}
			If ($Result -ne 0) {
				"Could not delete existing task. Errorlevel was $Result." | Write-BLLog -LogType CriticalError
				return 1
			} Else {
				"Scheduled task '$name' removed successfully." | Write-BLLog -LogType Information
			}
		} Else {
#			"Notice: This is NOT an error. It's expected when the queried task doesn't exist."| write-BLLog -LogType Warning
			If (-Not $Quiet) {
				"Nothing to remove, scheduled task did not exist. Everything is fine." | Write-BLLog -LogType Information
			}
		}
		return 0
	}
}

Function Remove-BLShortcut {
<#
.SYNOPSIS
Removes a shortcut.

.DESCRIPTION
The function New-BLShortcut deletes a shortcut (useful when removing shortcuts from the start menu or other common locations).
The function will return 0 on success, 1 on error.

.PARAMETER Name
Mandatory
The name (NO FOLDER) of the shortcut to remove.
The extension '.lnk' can be omitted.

.PARAMETER CommonProgramsPath
Optional
Removes the shortcut in a folder under the 'All Programs' start menu folder (default).
Omit this argument or set it to "" to remove the shortcut from the root of 'All Programs'.
If the direct parent folder of the shortcut is empty after the shortcut deletion, the parent will be deleted as well.

.PARAMETER CommonStartup
Optional
Removes the shortcut from the "Common Startup" folder.

.PARAMETER CommonDesktop
Optional
Removes the shortcut from the "Common Desktop" folder.

.PARAMETER Path
Optional
The full path (WITHOUT SHORTCUT NAME) to the folder from where the shortcut should be removed.
The folder will NOT be removed, even if it is empty after removal of the shortcut.
This is basically the same as Remove-Item.

.OUTPUTS
System.Int32

.EXAMPLE
Remove-BLShortcut -Name BGInfo -CommonStartup

.LINK
New-BLShortcut
Get-BLShortcut
#>
[CmdletBinding(DefaultParameterSetName="CommonPrograms")]
Param (
	[Parameter(Mandatory=$False, Position=0)][ValidateNotNull()]
	[string]$Name = $(Throw {"Required argument '-Name' not passed!"}),
	[Parameter(Mandatory=$False, Position=1, ParameterSetName="CommonPrograms")]
	[string]$CommonProgramsPath = "",
	[Parameter(Mandatory=$False, Position=1, ParameterSetName="CommonStartup")]
	[switch]$CommonStartup,
	[Parameter(Mandatory=$False, Position=1, ParameterSetName="CommonDesktop")]
	[switch]$CommonDesktop,
	[Parameter(Mandatory=$False, Position=1, ParameterSetName="FullPath")]
	[string]$Path
)
	$ret = 0
	$RemoveEmptyParent = $False
	Switch ($PsCmdlet.ParameterSetName) {
		"CommonPrograms" {
			$FullFolder = Join-Path -Path (Get-BLSpecialFolder -Folder "CommonPrograms") -ChildPath $CommonProgramsPath
			$RemoveEmptyParent = $True
		}
		"CommonStartup" {
			$FullFolder = Get-BLSpecialFolder -Folder "CommonStartup"
		}
		"CommonDesktop" {
			$FullFolder = Get-BLSpecialFolder -Folder "CommonDesktopDirectory"
		}
		"FullPath" {
			$FullFolder = $Path
		}
	}
	If ([IO.Path]::GetExtension($Name) -eq ".lnk") {
		$scName = Join-Path $FullFolder $Name
	} Else {
		$scName = Join-Path $FullFolder "$($Name).lnk"
	}
	If (Test-Path -Path $scName -PathType Leaf) {
		"Removing shortcut '$($scName)' ..." | Write-Verbose
		Remove-Item -Path $scName -Force
		If ($?) {
			"... OK." | Write-Verbose
			If ($RemoveEmptyParent -And ("Programs", "Startup" -NotContains [IO.Path]::GetFileName($FullFolder)) -And (-Not (Get-ChildItem -Path $FullFolder -Force))) {
				"Removing empty parent folder '$($FullFolder)' ..." | Write-Verbose
				Remove-Item -Path $FullFolder -Force
				If ($?) {
					"... OK." | Write-Verbose
				} Else {
					## Remove-Item will already have written an error
					"... ERROR." | Write-Verbose
					$ret = 1
				}
			}
		} Else {
			## Remove-Item will already have written an error
			"... ERROR." | Write-Verbose
			$ret = 1
		}
	} Else {
		"Could not delete shortcut; file '$($scName)' not found." | Write-Warning
	}
	Return $ret
}

Function Remove-BLUserProfile {
[CmdletBinding(SupportsShouldProcess=$True, ConfirmImpact="High")]
Param(
	[Parameter(ValueFromPipeline=$True, Position=0)]
	[object[]]$Name,
	[string]$ComputerName = $ENV:ComputerName
)
	Begin {
	}
	Process {
		ForEach ($User In $Name) {
			Try {
				If ($User -is [System.DirectoryServices.DirectoryEntry]) {
					$AdsiUser = $User
					If ($AdsiUser.schemaClassName -ne 'User') {
						"Object '$($AdsiUser.Path)' is of type '$($AdsiUser.schemaClassName)', not 'User'." | Write-Error
						Continue
					}
					$UserSid = (New-Object System.Security.Principal.SecurityIdentifier($AdsiUser.ObjectSid.Value, 0)).Value
					$AdsiUser.Path -match "\AWinNT://(?<ComputerName>.+)/$($AdsiUser.Name.ToString())\Z" | Out-Null
					## Can be ComputerName or DOMAIN/ComputerName
					$ProfileComputer = If ($Matches['ComputerName'].Contains('/')) {$Matches['ComputerName'].Split('/')[1]} Else {$Matches['ComputerName']}
					$User = $ProfileComputer + "\" + $AdsiUser.Name.Value
				} Else {
					$User = $User.ToString()
					$ProfileComputer = $ComputerName
					If (-not ($UserSid = (Resolve-BLSid -Name $User -ComputerName $ProfileComputer -ErrorAction SilentlyContinue).Sid)) {
						"Could not resolve SID for '$($User)':$($Error[0].Exception.Message.Split(':', 2)[1])!" | Write-Error
						Continue
					}
				}
				"Deleting profile '$($User)' (SID $($UserSid)) on computer '$($ProfileComputer)' ..." | Write-Verbose
				If ($WmiUserProfile = (Get-WmiObject -Query "Select * from Win32_UserProfile Where Sid='$($UserSid)'" -ComputerName $ProfileComputer -ErrorAction Stop)) {
					If ($PSCmdlet.ShouldProcess("$($User) ($($UserSid))", "Delete profile on computer '$($ProfileComputer)'")) {
						[void]$WmiUserProfile.Delete()
					}
					"... OK." | Write-Verbose
				} Else {
					"... no profile found." | Write-Verbose
				}
			} Catch {
				$_.Exception.Message | Write-Error
			}
		}
	}
	End {
	}
}

Function Set-BLCredentialManagerPolicy([ValidateSet("Disabled", "Enabled")][string]$State) {
	Switch ($State) {
		"Disabled" {
			$Value = 0
		}
		"Enabled" {
			$Value = 1
		}
	}
	If (Set-BLRegistryValueX64 -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "disabledomaincreds" -Type REG_DWORD -Value $Value -ErrorAction SilentlyContinue) {
		Return 0
	} Else {
		Return 1
	}
}

Function Set-BLEnvironmentPATH {
<#
.SYNOPSIS
Extend or reduce PATH-Variable of system.

.DESCRIPTION
The function Set-BLEnvironmentPATH manages System Environment PATH-Variable.
PATH be:
	- extended
	- reduced
In case of Extension plausi-checks are performed
    - is the new parameter already part of PATH-Variable 
	- does the new PATH exist
In case of PATH-Reduction a check verifies wether the given parameter does exist.
Any Changes are permanent changes and will be actived immediatly.

.PARAMETER VarPath
Mandatory
Directoryname for reduction or extension


.PARAMETER action
Mandatory
("add"|"remove") 

.INPUTS
System.String
System.String

.OUTPUTS
None

.EXAMPLE
set-BLEnvironmentPATH -path "$env:JAVA_HOME" -action "add" 

.LINK
Set-BLEnvironmentVariable

.NOTES
None
#>
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true, Position=0)][ValidateNotNull()]
	[string]$Varpath = "",
	[Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true, Position=1)][ValidateNotNull()]
	[string]$action = ""
)

  $exitCode=1
  If (!($VarPath.Length)) {"No Path Variable specified." | Write-BLLog -LogType CriticalError; return $exitCode}
  if (!($action -like "add" -or $action -like "remove")) {"No Action specified (add|remove)" | write-bllog -LogType CriticalError; return $exitCode }
 
 $arrpath=@($Env:path.split(";"))

  if ($action -like "add") {
    # Check, if $Varpath is already in $PATH
    if ($arrpath -contains $VarPath) { $ExitCode=0; "Path-Variable already contains $VarPath, nothing to do" | Write-BLLog -LogType Information; return $exitCode  }
    if (!(test-path $varpath)) { "Path $varpath does not exist, abort" | Write-BLLog -LogType CriticalError; return $exitCode }
    
    $newpath=$varpath + ";" + $Env:path

    $exitcode = Set-BLEnvironmentVariable "PATH" $newpath
    if (!($exitcode)) { "Environment:Path-Variable extended by $varPath" | Write-BLLog -LogType Information  }
    else { "Error extending Environment:Path-Variable to $varpath" | Write-BLLog -LogType CriticalError }
    return $exitCode
  }
  else { # Remove
    if (!($arrpath -contains $varpath)) { "$varpath not in PATH-Variable, can't remove, abort!" | Write-BLLog -LogType CriticalError; return $exitCode }
	$newpath=""
    foreach ($item in $arrpath) {
      if ($item -eq $varpath) {
        continue
      }
      if ($newpath.Length) { 
        $newpath += ";" + $item 
      }
      else {
        $newpath +=  $item      
      }        
    }
    $exitcode = Set-BLEnvironmentVariable "PATH" $newpath
    if (!($exitcode)) { "Environment:Path-Variable shortened by $varPath" | Write-BLLog -LogType Information  }
    else { "Error shortening Environment:Path-Variable to $varpath" | Write-BLLog -LogType CriticalError }
    return $exitCode

  }   
}

Function Set-BLEnvironmentVariable {
<#
.SYNOPSIS
Set, modify and delete System Variables.

.DESCRIPTION
The function Set-BLEnvironmentVariable manages System Environment Variables.
System Variables may be:
	- created
	- modified
	- deleted
This functions is restricted to Variables of type 'machine', User Variables are out of scope.
Any Changes are permanent changes and will be actived immediatly.
Change of "PATH"-Variable is suppressed, use SET-BLEnvironmentPATH instead.

.PARAMETER EnvVariable
Mandatory
The name of System-Variable.

.PARAMETER EnvValue
Optional
The (new) Value of EnvVariable.If omitted the System-Variable will be removed from System

.INPUTS
System.String
System.String

.OUTPUTS
None

.EXAMPLE
set-BLEnvironmentVariable -EnvVariable "JAVA_HOME" -EnvValue "C:\JAVA" 

.LINK
Set-BLEnvironmentPATH

.NOTES
None
#>
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true, Position=0)][ValidateNotNull()]
	[string]$EnvVariable = "",
	[Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true, Position=1)]
	[string]$EnvValue = ""
)
  $exitCode=1
  If (!($EnvVariable.Length)) {"No Environment Variable specified." | Write-BLLog -LogType CriticalError; return $exitCode}
  if ($envvariable -eq "path" -and ((Get-PSCallStack)[1].Command -ne "Set-BLEnvironmentPATH")) { 
    "Path must be managed by Set-BLEnvironmentPATH, abort ! " | Write-BLLog -LogType CriticalError; return $exitCode   
  }
  # Check old Value for $EnvVariable
  [string]$oldValue=[Environment]::GetEnvironmentVariable($EnvVariable, 'Machine')

  $ExitCode=0 ;  
  if ($oldValue -eq $EnvValue) {
    if (!$oldValue) {  "Environment Variable $EnvVariable not set, nothing to remove." | Write-BLLog -LogType Information}
    else {"Environment Variable $EnvVariable already set to Value $EnvValue." | Write-BLLog -LogType Information}
    return $exitCode 
  }

  # Following Action sets Vars for new Sessions (not for the actual one!)
  try {
	[void] [Environment]::SetEnvironmentVariable($EnvVariable, $EnvValue, 'Machine')
  } catch  {
	"$MyName - Error whilst setting Environment Variable $EnvVariable to Value ""$EnvValue""." | Write-BLLog -LogType CriticalError; return $exitCode
  }

  # Set new Value in Memory
  if ($EnvValue) {
	set-item -path Env:$EnvVariable -value $EnvValue
  }
  else {
    remove-item env:$EnvVariable
  }
  
  if ($oldValue.Length -and $EnvValue.Length)          { "Change Environment Variable ""$EnvVariable"" from old Value ""$oldValue"" to new Value ""$EnvValue""." | Write-BLLog -LogType Information }
  elseif ($oldValue.Length -and (!($EnvValue.Length))) { "Remove Environment Variable ""$EnvVariable"" (Previous Value: ""$oldvalue"")." | Write-BLLog -LogType Information }
  else                                                 { "Set Environment Variable ""$EnvVariable"" to Value ""$EnvValue""." | Write-BLLog -LogType Information }

  # Set Variable for actual Environment
  return $exitCode
}

Function Set-BLLocalUser {
[CmdletBinding()]
Param(
	[Parameter(ValueFromPipeline=$True, Position=0)]
	[object[]]$Name,
	[string]$Password,
	[string]$FullName,
	[string]$Description,
	[bool]$AccountDisabled,
	[bool]$PasswordMustChange,
	[bool]$PasswordCantChange,
	[bool]$PasswordNeverExpires,
	[switch]$ProcessExistingUser,
	[switch]$PassThru,
	[string]$ComputerName = $ENV:ComputerName
)	
	Begin {
		$ADS_USER_FLAG = @{		## https://msdn.microsoft.com/en-us/library/windows/desktop/aa772300(v=vs.85).aspx
			"ADS_UF_SCRIPT"                                  = [int32]0x1			## The logon script is executed. This flag does not work for the ADSI LDAP provider on either read or write operations. For the ADSI WinNT provider, this flag is read-only data, and it cannot be set for user objects.
			"ADS_UF_ACCOUNTDISABLE"                          = [int32]0x2			## The user account is disabled.
			"ADS_UF_HOMEDIR_REQUIRED"                        = [int32]0x8			## The home directory is required.
			"ADS_UF_LOCKOUT"                                 = [int32]0x10			## The account is currently locked out.
			"ADS_UF_PASSWD_NOTREQD"                          = [int32]0x20			## No password is required.
			"ADS_UF_PASSWD_CANT_CHANGE"                      = [int32]0x40			## The user cannot change the password. This flag can be read, but not set directly. For more information and a code example that shows how to prevent a user from changing the password, see User Cannot Change Password.
			"ADS_UF_ENCRYPTED_TEXT_PASSWORD_ALLOWED"         = [int32]0x80			## The user can send an encrypted password.
			"ADS_UF_TEMP_DUPLICATE_ACCOUNT"                  = [int32]0x100		## This is an account for users whose primary account is in another domain. This account provides user access to this domain, but not to any domain that trusts this domain. Also known as a local user account.
			"ADS_UF_NORMAL_ACCOUNT"                          = [int32]0x200		## This is a default account type that represents a typical user.
			"ADS_UF_INTERDOMAIN_TRUST_ACCOUNT"               = [int32]0x800		## This is a permit to trust account for a system domain that trusts other domains.
			"ADS_UF_WORKSTATION_TRUST_ACCOUNT"               = [int32]0x1000		## This is a computer account for a Windows or Windows Server that is a member of this domain.
			"ADS_UF_SERVER_TRUST_ACCOUNT"                    = [int32]0x2000		## This is a computer account for a system backup domain controller that is a member of this domain.
			"ADS_UF_DONT_EXPIRE_PASSWD"                      = [int32]0x10000		## When set, the password will not expire on this account.
			"ADS_UF_MNS_LOGON_ACCOUNT"                       = [int32]0x20000		## This is an Majority Node Set (MNS) logon account. With MNS, you can configure a multi-node Windows cluster without using a common shared disk.
			"ADS_UF_SMARTCARD_REQUIRED"                      = [int32]0x40000		## When set, this flag will force the user to log on using a smart card.
			"ADS_UF_TRUSTED_FOR_DELEGATION"                  = [int32]0x80000		## When set, the service account (user or computer account), under which a service runs, is trusted for Kerberos delegation. Any such service can impersonate a client requesting the service. To enable a service for Kerberos delegation, set this flag on the userAccountControl property of the service account.
			"ADS_UF_NOT_DELEGATED"                           = [int32]0x100000		## When set, the security context of the user will not be delegated to a service even if the service account is set as trusted for Kerberos delegation.
			"ADS_UF_USE_DES_KEY_ONLY"                        = [int32]0x200000		## Restrict this principal to use only Data Encryption Standard (DES) encryption types for keys.
			"ADS_UF_DONT_REQUIRE_PREAUTH"                    = [int32]0x400000		## This account does not require Kerberos preauthentication for logon.
			"ADS_UF_PASSWORD_EXPIRED"                        = [int32]0x800000		## The user password has expired. This flag is created by the system using data from the password last set attribute and the domain policy. It is read-only and cannot be set. To manually set a user password as expired, use the NetUserSetInfo function with the USER_INFO_3 (usri3_password_expired member) or USER_INFO_4 (usri4_password_expired member) structure.
			"ADS_UF_TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION"  = [int32]0x1000000	## The account is enabled for delegation. This is a security-sensitive setting; accounts with this option enabled should be strictly controlled. This setting enables a service running under the account to assume a client identity and authenticate as that user to other remote servers on the network.
		}
	}
	Process {
		ForEach ($User In $Name) {
			If ($User -is [System.DirectoryServices.DirectoryEntry]) {
				$AdsiUser = $User
			} Else {
				$User = $User.ToString()
				If (-not ($AdsiUser = Get-BLAdsiObject -Path "WinNT://$($ComputerName)/$($User),User")) {
					Continue
				}
			}
			Try {
				If (-not [string]::IsNullOrEmpty($Password)) {
					[void]$AdsiUser.SetPassword($Password)
					[void]$AdsiUser.SetInfo()
				}
				
				If (-not [string]::IsNullOrEmpty($FullName)) {
					If ($AdsiUser.FullName.Value -ne $FullName) {
						$AdsiUser.FullName = $FullName
						[void]$AdsiUser.SetInfo()
					}
				}
				
				If (-not [string]::IsNullOrEmpty($Description)) {
					If ($AdsiUser.Description.Value -ne $Description) {
						$AdsiUser.Description = $Description
						[void]$AdsiUser.SetInfo()
					}
				}
				
				$UserFlags = $UserFlagsOriginal = [uint32]$AdsiUser.UserFlags.Value
				If ($PSBoundParameters.ContainsKey("AccountDisabled")) {
					$UserFlags = If ($AccountDisabled) {$UserFlags -bor $ADS_USER_FLAG.ADS_UF_ACCOUNTDISABLE} Else {$UserFlags -band (-bnot $ADS_USER_FLAG.ADS_UF_ACCOUNTDISABLE)}
				}
				If ($PSBoundParameters.ContainsKey("PasswordMustChange")) {
					$SetUserFlags = $True
					$UserFlags = If ($PasswordMustChange) {$UserFlags -bor $ADS_USER_FLAG.ADS_UF_PASSWORD_EXPIRED} Else {$UserFlags -band (-bnot $ADS_USER_FLAG.ADS_UF_PASSWORD_EXPIRED)}
				}
				If ($PSBoundParameters.ContainsKey("PasswordNeverExpires")) {
					$SetUserFlags = $True
					$UserFlags = If ($PasswordNeverExpires) {$UserFlags -bor $ADS_USER_FLAG.ADS_UF_DONT_EXPIRE_PASSWD} Else {$UserFlags -band (-bnot $ADS_USER_FLAG.ADS_UF_DONT_EXPIRE_PASSWD)}
				}
				If ($PSBoundParameters.ContainsKey("PasswordCantChange")) {
					$SetUserFlags = $True
					$UserFlags = If ($PasswordCantChange) {$UserFlags -bor $ADS_USER_FLAG.ADS_UF_PASSWD_CANT_CHANGE} Else {$UserFlags -band (-bnot $ADS_USER_FLAG.ADS_UF_PASSWD_CANT_CHANGE)}
				}
				If ($UserFlags -ne $UserFlagsOriginal) {
					$AdsiUser.UserFlags = [int32]$UserFlags
					[void]$AdsiUser.SetInfo()
				}
				
				If ($PassThru) {
					$AdsiUser
				}
			} Catch {
				$_ | Write-Error
			}
		}
	}
	End {
	}
}

Function Set-BLScheduledTask {
## Old name: SCCM:Create-ScheduledTask
## Creates or updates an existing task by calling schtasks.exe
Param ( 
	[string] $name=$(throw "Taskname not specified"),
	[string] $command=$(throw "Command not specified"),
	[string] $username="SYSTEM",
	[string] $userpassword,
	[string] $schedule = "ONSTART",
	[string] $modifier,
	[string] $days,
	[string] $months,
	[string] $idletime,
	[string] $starttime,
	[string] $interval,
	[string] $endtime,
	[string] $duration,
	[switch] $kill,
	[string] $startdate,
	[string] $enddate,
	[string] $computername = $env:computername,
	[switch] $runonce
)
	Process {  
		trap {"An error occurred while trying to create a scheduled task.´nLast Error was:`n$($Error[0])" | Write-BLLog -LogType CriticalError; return 1; continue}
		$schtasks = Join-Path $Env:SystemRoot "system32\schtasks.exe"
		If ($computername -eq "$env:computername") {
			[string]$arg = "/Create /TN `"$name`" /TR `"$command`" /SC `"$schedule`""
			$wmiWin32OS = Get-WmiObject Win32_OperatingSystem
		} Else {
			If (-Not (Test-Connection $ComputerName -Quiet)) {
				"Could not access remote computer $ComputerName. Unable to continue." | Write-BLLog -LogType CriticalError
				Return 1
			}
			[string]$arg = "/Create /S `"$computername`" /TN `"$name`" /TR `"$command`" /SC `"$schedule`""
			$wmiWin32OS = Get-WmiObject -Computer $computername Win32_OperatingSystem
		}
		$Result = Remove-BLScheduledTask -Name $name -ComputerName $ComputerName -Quiet
		If ($Result -ne 0) {
			"Could not delete existing task. Unable to continue." | Write-BLLog -LogType CriticalError
			return 1
		}
		
		If ($username -eq "system") {
			$arg += " /RU `"system`""
		} Else {
			$arg += " /RU `"$username`" /RP `"$userpassword`""
		}
		If (-not ([String]::IsNullOrEmpty($modifier))) 	{ $arg += " /MO `"$modifier`"" 	}
		If (-not ([String]::IsNullOrEmpty($days))) 		{ $arg += " /D `"$days`"" 		}
		If (-not ([String]::IsNullOrEmpty($months))) 	{ $arg += " /M `"$months`"" 	}
		If (-not ([String]::IsNullOrEmpty($idletime))) 	{ $arg += " /I `"$idletime`"" 	}
		If (-not ([String]::IsNullOrEmpty($starttime))) { $arg += " /ST `"$starttime`"" }
		If (-not ([String]::IsNullOrEmpty($interval))) 	{ $arg += " /RI `"$interval`"" 	}
		If (-not ([String]::IsNullOrEmpty($endtime))) 	{ $arg += " /ET `"$endtime`"" 	}
		If (-not ([String]::IsNullOrEmpty($duration))) 	{ $arg += " /DU `"$duration`"" 	}
		If ($kill)										{ $arg += " /K" 				}
		If (-not ([String]::IsNullOrEmpty($startdate))) { $arg += " /SD `"$startdate`"" }
		If (-not ([String]::IsNullOrEmpty($enddate))) 	{ $arg += " /ED `"$enddate`"" 	}
		If ($runonce)									{ $arg += " /Z" 				}
		If ($wmiWin32OS.Version -like "6.*")			{ $arg += " /RL HIGHEST" }
		"Invoking: $schtasks $($arg.Replace($userpassword, "*****"))" | Write-BLLog -LogType Information
		$result = Start-BLProcess -FileName $schtasks -Arguments $arg
		return $result
	}
}

Function Set-BLServiceCredentials {
<#
.SYNOPSIS
Sets the logon credentials for a service.

.DESCRIPTION
The function Set-BLServiceCredentials sets the logon credentials for a service.
The service will automatically be restarted, unless -NoRestart is specified. If the service was already stopped before this function was called, the service will remain stopped and NOT be started.
The function can optionally grant the startup user the "Logon as a service" user right.
If the user is LocalSystem, Desktop Interaction can be enabled with the -DesktopInteraction switch.
If the account is changed from LocalSystem with Desktop Interaction to another account, Desktop Interaction will automatically be disabled.
If the account specified is the same as the one the service is already running under, the password will updated and the service restarted (unless -NoRestart is specified).
Returns 0 if successful, >0 otherwise:
	 1: No service name specified.
	 2: No startup account specified.
	 3: No account password specified.
	 4: Startup account not found.
	 5: Attempt to enable Desktop interaction for accounts other than SYSTEM.
	 6: No service with the name specified found.
	 7: Error when trying to access the service through WMI.
	 8: Service is in an unsupported state (neither "Running" nor "Stopped").
	 9: Error when trying to grant the user the "Logon as a service" user right.
	10: Error when trying to update the service properties.
	11: Service did not fully stop in the Timeout period.
	12: Service did not fully start in the Timeout period.

.PARAMETER Name
Mandatory
The service name.

.PARAMETER DisplayName
Mandatory
The display name of the service.

.PARAMETER StartUserName
Mandatory
The account to start the service with.

.PARAMETER StartPassword
Mandatory if a user account is specified.
The password for the service account.
Omit if the account is SYSTEM, Local Service, or Network Service.

.PARAMETER GrantLogonAsService
Optional
Grants the startup account the "Logon as a Service" user right.
If you omit this, the user must have this right granted throgh other means before running this function.

.PARAMETER DesktopInteraction
Optional
Enables desktop interaction for the service.
Only allowed if the startup account is SYSTEM, and will only be set when the account is actually changed.
The parameter can not be used to change the desktop interaction if the service is already running as SYSTEM.

.PARAMETER NoRestart
Optional
Prevents the automatic restart of the service after the account change.
If the service was already stopped before this function was called, the service will remain stopped and NOT be started.

.PARAMETER Timeout
Optional
The timeout for the service to stop completely and start completely.
If the service does not stop or start in the time given, the function will return with an error.

.PARAMETER ComputerName
Optional
The computer on which to change the account.

.INPUTS
System.String
System.Management.Automation.SwitchParameter
System.Int32

.OUTPUTS
System.Int32

.EXAMPLE
Set-BLServiceCredentials -Name "IBM Domino Server (CDominodata)" -StartUserName DOMAIN\SVC_DOMINO_USER -StartPassword TopSecret -GrantLogonAsService -Verbose
Change the startup account to the domain account "SVC_DOMINO_USER"

.EXAMPLE
Set-BLServiceCredentials -Name "IBM Domino Server (CDominodata)" -StartUserName SYSTEM -DesktopInteraction -Verbose
Change the startup account to SYSTEM and enable Desktop Interaction

.LINK

.NOTES
#>
[CmdletBinding(DefaultParameterSetName="Search_By_Name")]
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0, ParameterSetName="Search_By_Name")]
	[string]$Name,
	[Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True, Position=0, ParameterSetName="Search_By_DisplayName")]
	[string]$DisplayName,
	[Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True, Position=1)]
	[string]$StartUserName,
	[Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True, Position=2)]
	[string]$StartPassword = "",
	[Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
	[switch]$GrantLogonAsService,
	[Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
	[switch]$DesktopInteraction,
	[Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
	[switch]$NoRestart,
	[Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
	[uint32]$Timeout = 300, ## Seconds to wait for the service to stop/start
	[Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
	[string]$ComputerName = "."
)
	If ([string]::IsNullOrEmpty($Name) -And [string]::IsNullOrEmpty($DisplayName)) {
		"No service name specified!" | Write-Error
		Return 1
	}
	If ([string]::IsNullOrEmpty($StartUserName)) {
		"No service startup account specified!" | Write-Error
		Return 2
	}
	
	## The local service names as expected by the Change() method of the Win32_Service class:
	$LocalServiceAccounts = @(
		"LocalSystem",
		"NT AUTHORITY\LocalService",
		"NT AUTHORITY\NetworkService"
	)
	## Provide some tolerance when it comes to those names:
	If ("LocalSystem", "SYSTEM", ".\SYSTEM", "NT AUTHORITY\SYSTEM" -Contains $StartUserName) {
		$StartUserName = "LocalSystem"
	} ElseIf ("NT AUTHORITY\LocalService", "LocalService", ".\LocalService", "Local Service", ".\Local Service", "NT AUTHORITY\Local Service" -Contains $StartUserName) {
		$StartUserName = "NT AUTHORITY\LocalService"
	} ElseIf ("NT AUTHORITY\NetworkService", "NetworkService", ".\NetworkService", "Network Service", ".\Network Service", "NT AUTHORITY\Network Service" -Contains $StartUserName) {
		$StartUserName = "NT AUTHORITY\NetworkService"
	}
	If ($LocalServiceAccounts -NotContains $StartUserName) {
		If ([string]::IsNullOrEmpty($StartPassword)) {
			"No service startup password specified!" | Write-Error
			Return 3
		}
		If (-Not (Resolve-BLSid -Name $StartUserName -ComputerName $ComputerName -ErrorAction SilentlyContinue)) {
			"Startup account '$($StartUserName)' not found!" | Write-Error
			Return 4
		}
	}
	
	If ($DesktopInteraction -And ($StartUserName -ne "LocalSystem")) {
		"Desktop interaction can only be used if the startup account is 'LocalSystem'!" | Write-Error
		Return 5
	}
	If ($PSCmdlet.ParameterSetName -eq "Search_By_Name") {
		$Filter = "Name='$($Name)'"
	} Else {
		$Filter = "DisplayName='$($DisplayName)'"
	}
	Try {
		## See "Win32_Service class", https://msdn.microsoft.com/en-us/library/aa394418(v=vs.85).aspx
		$Service = Get-WmiObject -Namespace "Root\CIMv2" -Class "Win32_Service" -Filter $Filter -ComputerName $ComputerName -ErrorAction Stop
		If (-Not $Service) {
			"No service matching the filter $($Filter) found!" | Write-Error
			Return 6
		}
	} Catch {
		$_.Exception.Message | Out-String | Write-Error
		Return 7
	}
	If ("Stopped", "Running" -NotContains $Service.State) {
		"Service is in an unsupported state: '$(Service.State)'" | Write-Error
		Return 8
	}
	
	If (($StartUserName -eq $Service.StartName) -And ($LocalServiceAccounts -Contains $Service.StartName)) {	## Local service accounts have no passwords
		"Service already uses '$($StartUserName)' as startup account; no further action required." | Write-Verbose
		Return 0
	}
	
	<# "Change" method definition:
		uint32 Change(
			[in]  string DisplayName,
			[in]  string PathName,
			[in]  uint32 ServiceType,
			[in]  uint32 ErrorControl,
			[in]  string StartMode,
			[in]  boolean DesktopInteract,
			[in]  string StartName,
			[in]  string StartPassword,
			[in]  string LoadOrderGroup,
			[in]  string LoadOrderGroupDependencies,
			[in]  string ServiceDependencies
		);
	#>
	## region ReturnValue
	$ReturnValues = @'
		"ReturnCode","Description"
		"0", "The request was accepted."
		"1","The request is not supported."
		"2","The user did not have the necessary access."
		"3","The service cannot be stopped because other services that are running are dependent on it."
		"4","The requested control code is not valid, or it is unacceptable to the service."
		"5","The requested control code cannot be sent to the service because the state of the service (Win32_BaseService State property) is equal to 0, 1, or 2."
		"6","The service has not been started."
		"7","The service did not respond to the start request in a timely fashion."
		"8","Unknown failure when starting the service."
		"9","The directory path to the service executable file was not found."
		"10","The service is already running."
		"11","The database to add a new service is locked."
		"12","A dependency this service relies on has been removed from the system."
		"13","The service failed to find the service needed from a dependent service."
		"14","The service has been disabled from the system."
		"15","The service does not have the correct authentication to run on the system."
		"16","This service is being removed from the system."
		"17","The service has no execution thread."
		"18","The service has circular dependencies when it starts."
		"19","A service is running under the same name."
		"20","The service name has invalid characters."
		"21","Invalid parameters have been passed to the service."
		"22","The account under which this service runs is either invalid or lacks the permissions to run the service."
		"23","The service exists in the database of services available from the system."
		"24","The service is currently paused in the system."
'@ | ConvertFrom-Csv | Select-Object -Property @{Name="ReturnCode"; Expression={[uint32]$_.ReturnCode}}, Description
	## endregion ReturnValue

	If ($GrantLogonAsService) {
		"Granting user right 'Logon as a service' to account '$($StartUserName)' ..." | Write-Verbose
		If ((Grant-BLUserRights -Name $StartUserName -Right "SeServiceLogonRight" -ComputerName $ComputerName) -eq 0) {
			"... OK." | Write-Verbose
		} Else {
			## Error output will have been generated by Grant-BLUserRights
			Return 9
		}
	} Else {
		$AccountsWithServiceLogonRight = Get-BLAccountsWithUserRight -Right "SeServiceLogonRight" -ComputerName $ComputerName | Select-Object -ExpandProperty Accounts | Select-Object -ExpandProperty Name
		If (($LocalServiceAccounts -NotContains $StartUserName) -And ($AccountsWithServiceLogonRight -NotContains $StartUserName)) {
			"'$($StartUserName)' has no explicit user right 'Logon as a service'; will continue anyway." | Write-Warning
		}
	}
	
	If ($Service.DesktopInteract -And ($StartUserName -ne "LocalSystem")) {
		"Service '$($Service.DisplayName)' currently has Desktop Interaction enabled; this will be disabled!" | Write-Warning
	}
	
	$InParams = $Service.GetMethodParameters("Change")
	If ($Service.StartName -eq $StartUserName) {
		"Startup account for service '$($Service.DisplayName)' is already '$($StartUserName)', only setting password ..." | Write-Verbose
		$InParams["StartPassword"] = $StartPassword
	} Else {
		"Changing startup account for service '$($Service.DisplayName)' from '$($Service.StartName)' to '$($StartUserName)' ..." | Write-Verbose
		$InParams["StartName"] = $StartUserName
		$InParams["StartPassword"] = $StartPassword
		$InParams["DesktopInteract"] = [bool]$DesktopInteraction
	}
	$Result = $Service.InvokeMethod("Change", $InParams, $Null)
	If ($Result.ReturnValue -ne 0) {
		"Error $($Result.ReturnValue) when setting the service logon account '$($StartUserName)': $($ReturnValues | ? {$_.ReturnCode -eq $Result.ReturnValue} | Select-Object -ExpandProperty Description)" | Write-Error
		Return 10
	}
	"... OK." | Write-Verbose
	"Service restart ..." | Write-Verbose
	If ($NoRestart) {
		"... disabled by option -NoRestart." | Write-Verbose
	} ElseIf ($Service.State -eq "Stopped") {
		"... service is already stopped; no further action required." | Write-Verbose
	} Else {
		"[$(Get-Date -Format 'HH:mm:ss')] Stopping service; timeout is $($Timeout) seconds ..." | Write-Verbose
		$BreakTime = (Get-Date).AddSeconds($Timeout)
		$Service.StopService() | Out-Null
		While ($Service.State -ne "Stopped") {
			If ((Get-Date) -gt $BreakTime) {
				"Timeout reached; service did not stop after $($Timeout) seconds!" | Write-Error
				Return 11
			}
			Start-Sleep -Milliseconds 500
			$Service = Get-WmiObject -Namespace "Root\CIMv2" -Class "Win32_Service" -Filter $Filter -ComputerName $ComputerName
		}
		"[$(Get-Date -Format 'HH:mm:ss')] ... service stopped. Starting service again; timeout is $($Timeout) seconds ..." | Write-Verbose
		$BreakTime = (Get-Date).AddSeconds($Timeout)
		$Service.StartService() | Out-Null
		While ($Service.State -ne "Running") {
			If ((Get-Date) -gt $BreakTime) {
				"Timeout reached; service did not start after $($Timeout) seconds!" | Write-Error
				Return 12
			}
			Start-Sleep -Milliseconds 500
			$Service = Get-WmiObject -Namespace "Root\CIMv2" -Class "Win32_Service" -Filter $Filter -ComputerName $ComputerName
		}
		"[$(Get-Date -Format 'HH:mm:ss')] ... service is running." | Write-Verbose
	}
	Return 0
}

Function Set-BLServiceStartup($Name = "", $StartupType = "", [switch]$Delayed, [switch]$Stop, [switch]$Start) {
## Old name: SCCM:Set-ServiceStartup
## Configure Service-Startup
	trap {"$MyName : service '$name' could not be configured to '$StartupType'.`nLast Error was:`n$($Error[0])" | Write-BLLog -LogType CriticalError; return $exitCode; continue}
	$exitCode = 1 # assume failure until proven otherwise
	$StartupTypeValid = @("Automatic", "Manual", "Disabled")
	# Check parameters
	If ([String]::IsNullOrEmpty($name)) {"No service name specified" | Write-BLLog -LogType CriticalError; return $exitCode}
	If ([String]::IsNullOrEmpty($StartupType) -or ($StartupTypeValid -NotContains $StartupType)) {
		"Service startup type does not contain a valid value (Automatic, Manual, Disabled)" | Write-BLLog -LogType CriticalError
		Return $exitCode
	}
	$Service = Get-Service -Name $Name
	If (-Not $Service) {
		"'$Name' is not an installed service." | Write-BLLog -LogType CriticalError
		Return $exitCode
	}
	# basic checks done. Invoke set-service now
	Set-Service -Name $Name -StartupType $StartupType
	If ($?) {
		$ExitCode = 0
	}
	If ($Delayed) {
		Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\$($Service.Name)" -Name "DelayedAutoStart" -Value 1 -Type DWORD -Force
	} Else {
		Remove-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\$($Service.Name)" -Name "DelayedAutoStart" -Force -ErrorAction SilentlyContinue
	}
	"Service '$name' has been configured to '$StartupType'" | Write-BLLog -LogType Information
	
	if ($Start) {
		"Start Service '$name'" | Write-BLLog -LogType Information
		Start-Service -Name $Name
		if (-not $?) {
			"Service '$name' could not be started" | Write-BLLog -LogType CriticalError
			$Exit = 1
		}
	}
	
	if ($Stop) {
		"Stop Service '$name'" | Write-BLLog -LogType Information
		Stop-Service -Name $Name
		if (-not $?) {
			"Service '$name' could not be stopped" | Write-BLLog -LogType CriticalError
			$Exit = 1
		}
	}
	
	Return $ExitCode
}

Function Start-BLProcess($FileName = "", $Arguments = "", [switch]$LogCmd = $False) {
## Old name: SCCM:Start-BLProcess
## -------------
## Executes a command line and waits as long as it is running.
## Returns the exit code of the command line.
    if ($LogCmd) {
       "CALL: $FileName $Arguments" | Write-BLLog -LogType Information
    }
	$exitCode = 1 # assume failure until proven otherwise
	If ($FileName.Length) {
		$process = New-Object system.Diagnostics.Process
		$si = New-Object System.Diagnostics.ProcessStartInfo
		$si.FileName = $FileName
		If ($Arguments.Length) {$si.Arguments = $Arguments}
		$si.UseShellExecute = $false
		$si.RedirectStandardOutput = $true
		$si.RedirectStandardError = $true
		$process.StartInfo = $si
		$process.Start() | Out-Null
		$process.standardoutput.ReadToEnd() | Write-BLLog -LogType Information | Out-Null
		$process.StandardError.ReadToEnd() | Write-BLLog -LogType Warning | Out-Null
		$process.WaitForExit()
		$exitCode = $process.Get_ExitCode()
	}
	"EXIT CODE = $exitCode" | Write-BLLog -LogType Information
	return $exitCode
}

Function Test-BLOSVersion([string]$Version) {
	If (($BL_OSVersion.Split(".")[0] -gt $Version.Split(".")[0]) -Or (($BL_OSVersion.Split(".")[0] -eq $Version.Split(".")[0]) -And ($BL_OSVersion.Split(".")[1] -ge $Version.Split(".")[1]))) {
		Return $True
	} Else {
		Return $False
	}
}

Function Test-BLElevation() {
## Checks if the current session is running elevated
## Returns $True if elevated or running in System context, $False otherwise
	$Principal = New-Object -TypeName System.Security.Principal.WindowsPrincipal -ArgumentList ([System.Security.Principal.WindowsIdentity]::GetCurrent())
	$Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

Function Test-BLHyperVGuest() {
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)]
	[string]$ComputerName = "."
)
## Old name: SCCM:Check-HyperVGuest
## Checks if the machine is running as a Hyper-V guest.
## The current environment consists only of Hyper-V and physical machines, so there's no complete check for other virtualization technologies.
## Returns "$True" if Baseboard manufacturer contains "Microsoft", $False otherwise.
##	"Entering " + $MyInvocation.MyCommand + " at " + (Get-Date).ToLongTimeString() | Write-BLLog -LogType Information
	"Checking for virtualization $(If ($ComputerName -ne '.') {"on $($ComputerName)"}) ..." | Write-Verbose
	$Baseboard = Get-WmiObject -Namespace "Root\CIMv2" -Class "Win32_Baseboard" -ComputerName $ComputerName
	If (-Not $?) {
		Return
	}
	If (-Not $Baseboard) {
		"... no baseboard information available, assuming this is not a HyperV-Guest" | Write-Verbose
		Return $False
	} Else {
		If ($ret = ($Baseboard.Manufacturer -match 'Microsoft')) {
			"Baseboard Manufacturer is '$($Baseboard.Manufacturer)', this is a Hyper-V guest." | Write-Verbose
		} Else {
			"Baseboard Manufacturer is '$($Baseboard.Manufacturer)', this is not a Hyper-V guest." | Write-Verbose
		}
	}
#	"Leaving " + $MyInvocation.MyCommand + " with return value $ret at " + (Get-Date).ToLongTimeString() | Write-BLLog -LogType Information
	Return $ret
}

## ====================================================================================================
## Group "OS Local Security Authority"
## ====================================================================================================

Function Get-BLAccountsWithUserRight() {
## Enumerates all accounts that have the specified right(s).
## If no right is specified, all rights will be returned.
## Returns an array of custom objects; the array can be empty.
## If an error occurred, $Null will be returned.
## Requires the custom classes "BLLookupAccount" and "BLAccountRights"
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)]
	[Alias("Rights", "RightList")]
	[BLAccountRights+Privileges[]]$Right,
	[Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True, Position=1)]
	[string]$ComputerName = "."
)
	Begin {
		$Result = @()
		$Error = $False
		If (($ComputerName -eq ".") -Or ([string]::IsNullOrEmpty($ComputerName))) {$RealComputerName = $ENV:ComputerName} Else {$RealComputerName = $ComputerName}
		If (-Not $Right) {
 			$Right = [enum]::GetNames([BLAccountRights+Privileges])
		}
		$UserRightDisplayName = @{}
		Show-BLUserRightsInformation | % {$UserRightDisplayName[$_.Privilege] = $_.DisplayName}
	}
	Process {
		Try {
			ForEach ($Privilege In $Right) {
				$SIDs = [BLAccountRights]::GetAccountsWithRight($Privilege, $ComputerName)
				$AccountList = @()
				ForEach ($SID In $SIDs) {
					Try {
						$Name = ([BLLookupAccount]::GetNameFromSid($SID, $ComputerName)).Name
						$LastError = ""
					} Catch {
						$Name = ""
						$LastError = $_.Exception.InnerException.Message
					}
					$AccountList += "" | Select-Object -Property `
						@{Name = "Sid"; Expression = {$SID}},
						@{Name = "Name"; Expression = {$Name}},
						@{Name = "LastError"; Expression = {$LastError}}
				}
				$Result += "" | Select-Object -Property `
					@{Name = "Right"; Expression = {$Privilege.ToString()}},
					@{Name = "DisplayName"; Expression = {$UserRightDisplayName[$Privilege.ToString()]}},
					@{Name = "Accounts"; Expression = {$AccountList}},
					@{Name = "ComputerName"; Expression = {$RealComputerName}}
			}
		} Catch {
			Write-Error -ErrorRecord $_
			$Error = $True
		}
	}
	End {
		If (-Not $Error) {
			,$Result | Write-Output
		}
	}
}

Function Get-BLUserRightsForAccount() {
## Gets all rights for a specific account.
## Returns an array of custom objects; the array can be empty.
## If an error occurred, $Null will be returned.
## Requires the custom classes "BLLookupAccount" and "BLAccountRights"
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)]
	[Alias("Names", "NameList")]
	[string[]]$Name = @(),
	[Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True, Position=1)]
	[string]$ComputerName = "."
)
	Begin {
		$Result = @()
		$Error = $False
		If (($ComputerName -eq ".") -Or ([string]::IsNullOrEmpty($ComputerName))) {$RealComputerName = $ENV:ComputerName} Else {$RealComputerName = $ComputerName}
		$UserRightDisplayName = @{}
		Show-BLUserRightsInformation | % {$UserRightDisplayName[$_.Privilege] = $_.DisplayName}
	}
	Process {
		Try {
			ForEach ($Principal In $Name) {
				$LastError = ""
				If ($Principal -match '^S-\d-(\d+-){1,14}\d+$') {
					Try {
						$Account = [BLLookupAccount]::GetNameFromSid($Principal, $ComputerName)
					} Catch {
						$Account = "" | Select-Object -Property `
							@{Name = "Sid"; Expression = {$Principal}},
							@{Name = "Name"; Expression = {""}}
						$LastError = $_.Exception.InnerException.Message
					}
				} Else {
					$Account = [BLLookupAccount]::GetSidFromName($Principal, $ComputerName)
				}
				ForEach ($Privilege In [BLAccountRights]::GetAccountRights($Account.Sid, $ComputerName)) {
					$Result += "" | Select-Object -Property `
						@{Name = "Right"; Expression = {$Privilege.ToString()}},
						@{Name = "DisplayName"; Expression = {$UserRightDisplayName[$Privilege.ToString()]}},
						@{Name = "Accounts"; Expression = {
							"" | Select-Object -Property `
								@{Name = "Sid"; Expression = {$Account.Sid}},
								@{Name = "Name"; Expression = {$Account.Name}},
								@{Name = "LastError"; Expression = {$LastError}}
						}},
						@{Name = "ComputerName"; Expression = {$RealComputerName}}
				}
			}
		} Catch {
			Write-Error -ErrorRecord $_
			$Error = $True
		}
	}
	End {
		If (-Not $Error) {
			,$Result | Write-Output
		}
	}
}

Function Grant-BLUserRights {
## Sets a user right.
## Account can be a SID (use at your own risk - non-existing SIDs can be added with this as well!).
## Returns 0 on success, 1 on error.
## If -PassThru is $True, returns the account name passed on success, $Null otherwise.
## Requires the custom classes "BLLookupAccount" and "BLAccountRights"
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)]
	[string]$Name = "",
	[Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True, Position=1)]
	[Alias("Rights", "RightList")]
	[BLAccountRights+Privileges[]]$Right,
	[Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True, Position=2)]
	[string]$ComputerName = ".",
	[Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True, Position=3)]
	[switch]$PassThru
)
	Process {
		If ($PassThru) {$Result = $Name} Else {$Result = 0}
		Try {
			If ([BLLookupAccount]::TestSid($Name)) {		## Alternative: RegEx would be '\AS-\d-(\d+-){1,14}\d+\Z'
				$SID = $Name
			} Else {
				$SID = ([BLLookupAccount]::GetSidFromName($Name, $ComputerName)).Sid
			}
			ForEach ($Privilege In $Right) {
				Try {
					[BLAccountRights]::AddAccountRights($SID, $Privilege, $ComputerName)
				} Catch {
					$_.Exception.Message | Write-Error
					If ($PassThru) {$Result = $Null} Else {$Result = 1}
				}
			}
		} Catch {
			Write-Error -ErrorRecord $_
			If ($PassThru) {$Result = $Null} Else {$Result = 1}
		}
		$Result | Write-Output
	}
}

Function Resolve-BLSid {
<#
.SYNOPSIS
Resolves a name to a SID or vice versa.

.DESCRIPTION
The function Resolve-BLSid resolves a name to a SID or vice versa.
The function resolves user names, group names, computer names, domain names.
Note that when trying to resolve a domain computer name, the trailing "$" must be added to the computer name.

The function attempts to find a SID for the specified name by first checking a list of well-known SIDs. If the name does not correspond to a well-known SID, the function checks built-in and administratively defined local accounts.
Next, the function checks the primary domain. If the name is not found there, trusted domains are checked.
Use fully qualified account names (for example, domain_name\user_name) instead of isolated names (for example, user_name). Fully qualified names are unambiguous and provide better performance when the lookup is performed.
This function also supports fully qualified DNS names (for example, example.example.com\user_name) and user principal names (UPN) (for example, someone@example.com).
In addition to looking up local accounts, local domain accounts, and explicitly trusted domain accounts, LookupAccountName can look up the name for any account in any domain in the forest.

.PARAMETER Name
Mandatory
The name or SID to resolve.
If this argument is $Null or empty, the local computer SID will be returned.

.PARAMETER ComputerName
Optional
The computer on which to resolve the name or SID.
Note that you do NOT need to specify a DC to resolve domain accounts.

.INPUTS
System.String
System.String

.OUTPUTS
BLLookupAccount+AccountInfo

.EXAMPLE
Resolve-BLSid
Resolves the local computer's SID.

.EXAMPLE
Resolve-BLSid -ComputerName RZ1VPFEMW001
Resolves the local computer SID of RZ1VPFEMW001.

.EXAMPLE
Resolve-BLSid -Name RZ1VPFEMW001$
Resolves the domain computer SID of RZ1VPFEMW001.

.EXAMPLE
Resolve-BLSid -Name $ENV:UserDomain
Resolves the domain SID of the logged on user.

.EXAMPLE
Resolve-BLSid -Name ((Resolve-BLSid).Sid + "-500")
Resolves the current name of the local Administrator account.

.EXAMPLE
Resolve-BLSid -Name "S-1-5-32-544"
Resolves the name of the local Administrators group.

.EXAMPLE
Resolve-BLSid -Name ((Resolve-BLSid -Name $ENV:UserDomain).Sid + "-500")
Resolves the current name of the logged on user's Domain Administrator account.

.LINK
Show-BLWellKnownSidsInformation
Test-BLSid
#>
[CmdletBinding()]
## Returns the SID for an account/group/domain or vice versa (domain or local).
## Can be run against remote machines.
## Requires the custom class "BLLookupAccount"
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)]
	[string]$Name,
	[Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True, Position=1)]
	[string]$ComputerName = "."
)
	Process {
		If ([string]::IsNullOrEmpty($Name)) {
			$Name = If ($ComputerName -eq ".") {$ENV:ComputerName} Else {$ComputerName}
		}
		Try {
			If ([BLLookupAccount]::TestSid($Name)) {		## Alternative: RegEx would be '\AS-\d-(\d+-){1,14}\d+\Z'
				[BLLookupAccount]::GetNameFromSid($Name, $ComputerName) | Write-Output
			} Else {
				[BLLookupAccount]::GetSidFromName($Name, $ComputerName) | Write-Output
			}
		} Catch {
			$_.Exception.Message | Write-Error
		}
	}
}

Function Revoke-BLUserRights() {
## Revokes a user right for an account. If no right is specified, all rights will be removed.
## Account can be a SID.
## Ignores passed rights that the user doesn't have.
## Returns 0 on success, 1 on error.
## If -PassThru is $True, returns the account name passed on success, $Null otherwise.
## Requires the custom classes "BLLookupAccount" and "BLAccountRights"
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)]
	[string]$Name = "",
	[Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True, Position=1)]
	[Alias("Rights", "RightList")]
	[BLAccountRights+Privileges[]]$Right,
	[Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True, Position=2)]
	[string]$ComputerName = ".",
	[Parameter(Mandatory=$False, ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True, Position=3)]
	[switch]$PassThru
)
	Process {
		If ($PassThru) {$Result = $Name} Else {$Result = 0}
		Try {
			If ([BLLookupAccount]::TestSid($Name)) {		## Alternative: RegEx would be '\AS-\d-(\d+-){1,14}\d+\Z'
				$SID = $Name
			} Else {
				$SID = ([BLLookupAccount]::GetSidFromName($Name, $ComputerName)).Sid
			}
			If ($Right) {
				$RevokeList = [BLAccountRights]::GetAccountRights($SID, $ComputerName) | ? {$Right -Contains $_}
			} Else {
				$RevokeList = [BLAccountRights]::GetAccountRights($SID, $ComputerName)
			}
			ForEach ($Privilege In $RevokeList) {
				Try {
					[BLAccountRights]::RemoveAccountRights($SID, $Privilege, $ComputerName)
				} Catch {
					$_.Exception.Message | Write-Error
					If ($PassThru) {$Result = $Null} Else {$Result = 1}
				}
			}
		} Catch {
			Write-Error -ErrorRecord $_
			If ($PassThru) {$Result = $Null} Else {$Result = 1}
		}
		$Result | Write-Output
	}
}

Function Show-BLUserRightsInformation() {
## Returns a list of user rights that can be used for the *UserRight* functions.
## Based on "Authorization Constants", https://msdn.microsoft.com/en-us/library/windows/desktop/aa375728(v=vs.85).aspx
##		- "Account Rights Constants", https://msdn.microsoft.com/en-us/library/windows/desktop/bb545671(v=vs.85).aspx
##		- "Privilege Constants", https://msdn.microsoft.com/en-us/library/windows/desktop/bb530716(v=vs.85).aspx
## region AccountPrivileges
@'
	"Privilege","DisplayName","Description"
	"SeAssignPrimaryTokenPrivilege","Replace a process-level token.","Required to assign the primary token of a process."
	"SeAuditPrivilege","Generate security audits.","Required to generate audit-log entries. Give this privilege to secure servers."
	"SeBackupPrivilege","Back up files and directories.","Required to perform backup operations. This privilege causes the system to grant all read access control to any file, regardless of the access control list (ACL) specified for the file. Any access request other than read is still evaluated with the ACL. This privilege is required by the RegSaveKey and RegSaveKeyExfunctions. The following access rights are granted if this privilege is held: READ_CONTROL, ACCESS_SYSTEM_SECURITY, FILE_GENERIC_READ, FILE_TRAVERSE."
	"SeBatchLogonRight","Log on as a batch job.","Required for an account to log on using the batch logon type."
	"SeChangeNotifyPrivilege","Bypass traverse checking.","Required to receive notifications of changes to files or directories. This privilege also causes the system to skip all traversal access checks. It is enabled by default for all users."
	"SeCreateGlobalPrivilege","Create global objects.","Required to create named file mapping objects in the global namespace during Terminal Services sessions. This privilege is enabled by default for administrators, services, and the local system account."
	"SeCreatePagefilePrivilege","Create a pagefile.","Required to create a paging file."
	"SeCreatePermanentPrivilege","Create permanent shared objects.","Required to create a permanent object."
	"SeCreateSymbolicLinkPrivilege","Create symbolic links.","Required to create a symbolic link."
	"SeCreateTokenPrivilege","Create a token object.","Required to create a primary token. You cannot add this privilege to a user account with the 'Create a token object' policy. Additionally, you cannot add this privilege to an owned process using Windows APIs. Windows Server 2003 and Windows XP with SP1 and earlier: Windows APIs can add this privilege to an owned process."
	"SeDebugPrivilege","Debug programs.","Required to debug and adjust the memory of a process owned by another account."
	"SeDenyBatchLogonRight","Deny log on as a batch job.","Explicitly denies an account the right to log on using the batch logon type."
	"SeDenyInteractiveLogonRight","Deny log on locally.","Explicitly denies an account the right to log on using the interactive logon type."
	"SeDenyNetworkLogonRight","Deny access to this computer from the network.","Explicitly denies an account the right to log on using the network logon type."
	"SeDenyRemoteInteractiveLogonRight","Deny log on through Remote Desktop Services.","Explicitly denies an account the right to log on remotely using the interactive logon type."
	"SeDenyServiceLogonRight","Deny log on as a service.","Explicitly denies an account the right to log on using the service logon type."
	"SeEnableDelegationPrivilege","Enable computer and user accounts to be trusted for delegation.","Required to mark user and computer accounts as trusted for delegation."
	"SeImpersonatePrivilege","Impersonate a client after authentication.","Required to impersonate."
	"SeIncreaseBasePriorityPrivilege","Increase scheduling priority.","Required to increase the base priority of a process."
	"SeIncreaseQuotaPrivilege","Adjust memory quotas for a process.","Required to increase the quota assigned to a process."
	"SeIncreaseWorkingSetPrivilege","Increase a process working set.","Required to allocate more memory for applications that run in the context of users."
	"SeInteractiveLogonRight","Allow log on locally.","Required for an account to log on using the interactive logon type."
	"SeLoadDriverPrivilege","Load and unload device drivers.","Required to load or unload a device driver."
	"SeLockMemoryPrivilege","Lock pages in memory.","Required to lock physical pages in memory."
	"SeMachineAccountPrivilege","Add workstations to domain.","Required to create a computer account."
	"SeManageVolumePrivilege","Perform volume maintenance tasks.","Required to enable volume management privileges."
	"SeNetworkLogonRight","Access this computer from the network.","Required for an account to log on using the network logon type."
	"SeProfileSingleProcessPrivilege","Profile single process.","Required to gather profiling information for a single process."
	"SeRelabelPrivilege","Modify an object label.","Required to modify the mandatory integrity level of an object."
	"SeRemoteInteractiveLogonRight","Allow log on through Remote Desktop Services.","Required for an account to log on remotely using the interactive logon type."
	"SeRemoteShutdownPrivilege","Force shutdown from a remote system.","Required to shut down a system using a network request."
	"SeRestorePrivilege","Restore files and directories.","Required to perform restore operations. This privilege causes the system to grant all write access control to any file, regardless of the ACL specified for the file. Any access request other than write is still evaluated with the ACL. Additionally, this privilege enables you to set any valid user or group SID as the owner of a file. This privilege is required by the RegLoadKey function. The following access rights are granted if this privilege is held: WRITE_DAC, WRITE_OWNER, ACCESS_SYSTEM_SECURITY, FILE_GENERIC_WRITE, FILE_ADD_FILE, FILE_ADD_SUBDIRECTORY, DELETE."
	"SeSecurityPrivilege","Manage auditing and security log.","Required to perform a number of security-related functions, such as controlling and viewing audit messages. This privilege identifies its holder as a security operator."
	"SeServiceLogonRight","Log on as a service.","Required for an account to log on using the service logon type."
	"SeShutdownPrivilege","Shut down the system.","Required to shut down a local system."
	"SeSyncAgentPrivilege","Synchronize directory service data.","Required for a domain controller to use the Lightweight Directory Access Protocol directory synchronization services. This privilege enables the holder to read all objects and properties in the directory, regardless of the protection on the objects and properties. By default, it is assigned to the Administrator and LocalSystem accounts on domain controllers."
	"SeSystemEnvironmentPrivilege","Modify firmware environment values.","Required to modify the nonvolatile RAM of systems that use this type of memory to store configuration information."
	"SeSystemProfilePrivilege","Profile system performance.","Required to gather profiling information for the entire system."
	"SeSystemtimePrivilege","Change the system time.","Required to modify the system time."
	"SeTakeOwnershipPrivilege","Take ownership of files or other objects.","Required to take ownership of an object without being granted discretionary access. This privilege allows the owner value to be set only to those values that the holder may legitimately assign as the owner of an object."
	"SeTcbPrivilege","Act as part of the operating system.","This privilege identifies its holder as part of the trusted computer base. Some trusted protected subsystems are granted this privilege."
	"SeTimeZonePrivilege","Change the time zone.","Required to adjust the time zone associated with the computer's internal clock."
	"SeTrustedCredManAccessPrivilege","Access Credential Manager as a trusted caller.","Required to access Credential Manager as a trusted caller."
	"SeUndockPrivilege","Remove computer from docking station.","Required to undock a laptop."
	"SeUnsolicitedInputPrivilege","n/a","OBSOLETE: Required to read unsolicited input from a terminal device."
'@ | ConvertFrom-Csv
## endregion AccountPrivileges
}

Function Show-BLWellKnownSidsInformation() {
## Returns a list of well-known SIDs.
## Based on "Well-known security identifiers in Windows operating systems", http://support.microsoft.com/en-us/kb/243330
## Errors in the article as of April 2015:
##   * The name for "S-1-5-17" is not "This Organization", but "IUSR".
##   * The name for "S-1-5-19" is not "NT Authority", but "Local Service", and the description is missing.
##   * The name for "S-1-5-20" is not "NT Authority", but "Network Service", and the description is missing.
##   * "S-1-5-80-0" is listed twice, once as "Added in Windows Vista and Windows Server 2008", once as "Added in Windows Server 2008 R2"
##   * Vista, Windows 7, and Server 2012 R2 are missing from the "Applies to" section.
## The following are not errors, but relevant when you're trying to process this site into a properly formatted table:
##   * The entry for "S-1-3-4" is not formatted properly, the line break between "SID: S-1-3-4" and "Name" is missing.
##   * "SID: S-1-5- 21domain -498": additional spaces before "21" and after "domain".
##   * "SID: S-1-5- 21domain -521": additional spaces before "21" and after "domain".
##   * "SID: S-1-5-21 domain -571": additional spaces after "21" and after "domain".
##   * "SID: S-1-5- 21 domain -572": additional spaces before "21", after "21" and after "domain".
##   * "SID: S-1-5-21-domain-522": additional hyphen after "21" (unlike the other domain entries).
@'
	"SID","Name","Description","Note"
	"S-1-0","Null Authority","An identifier authority.",""
	"S-1-0-0","Nobody","No security principal.",""
	"S-1-1","World Authority","An identifier authority.",""
	"S-1-1-0","Everyone","A group that includes all users, even anonymous users and guests. Membership is controlled by the operating system.","By default, the Everyone group no longer includes anonymous users on a computer that is running Windows XP Service Pack 2 (SP2)."
	"S-1-2","Local Authority","An identifier authority.",""
	"S-1-2-0","Local","A group that includes all users who have logged on locally.",""
	"S-1-2-1","Console Logon","A group that includes users who are logged on to the physical console.","Added in Windows 7 and Windows Server 2008 R2"
	"S-1-3","Creator Authority","An identifier authority.",""
	"S-1-3-0","Creator Owner","A placeholder in an inheritable access control entry (ACE). When the ACE is inherited, the system replaces this SID with the SID for the object's creator.",""
	"S-1-3-1","Creator Group","A placeholder in an inheritable ACE. When the ACE is inherited, the system replaces this SID with the SID for the primary group of the object's creator. The primary group is used only by the POSIX subsystem.",""
	"S-1-3-2","Creator Owner Server","This SID is not used in Windows 2000.",""
	"S-1-3-3","Creator Group Server","This SID is not used in Windows 2000.",""
	"S-1-3-4","Owner Rights","A group that represents the current owner of the object. When an ACE that carries this SID is applied to an object, the system ignores the implicit READ_CONTROL and WRITE_DAC permissions for the object owner.",""
	"S-1-5-80-0","All Services","A group that includes all service processes configured on the system. Membership is controlled by the operating system.","Added in Windows Vista and Windows Server 2008"
	"S-1-4","Non-unique Authority","An identifier authority.",""
	"S-1-5","NT Authority","An identifier authority.",""
	"S-1-5-1","Dialup","A group that includes all users who have logged on through a dial-up connection. Membership is controlled by the operating system.",""
	"S-1-5-2","Network","A group that includes all users that have logged on through a network connection. Membership is controlled by the operating system.",""
	"S-1-5-3","Batch","A group that includes all users that have logged on through a batch queue facility. Membership is controlled by the operating system.",""
	"S-1-5-4","Interactive","A group that includes all users that have logged on interactively. Membership is controlled by the operating system.",""
	"S-1-5-5-X-Y","Logon Session","A logon session. The X and Y values for these SIDs are different for each session.",""
	"S-1-5-6","Service","A group that includes all security principals that have logged on as a service. Membership is controlled by the operating system.",""
	"S-1-5-7","Anonymous","A group that includes all users that have logged on anonymously. Membership is controlled by the operating system.",""
	"S-1-5-8","Proxy","This SID is not used in Windows 2000.",""
	"S-1-5-9","Enterprise Domain Controllers","A group that includes all domain controllers in a forest that uses an Active Directory directory service. Membership is controlled by the operating system.",""
	"S-1-5-10","Principal Self","A placeholder in an inheritable ACE on an account object or group object in Active Directory. When the ACE is inherited, the system replaces this SID with the SID for the security principal who holds the account.",""
	"S-1-5-11","Authenticated Users","A group that includes all users whose identities were authenticated when they logged on. Membership is controlled by the operating system.",""
	"S-1-5-12","Restricted Code","This SID is reserved for future use.",""
	"S-1-5-13","Terminal Server Users","A group that includes all users that have logged on to a Terminal Services server. Membership is controlled by the operating system.",""
	"S-1-5-14","Remote Interactive Logon","A group that includes all users who have logged on through a terminal services logon.",""
	"S-1-5-15","This Organization","A group that includes all users from the same organization. Only included with AD accounts and only added by a Windows Server 2003 or later domain controller.",""
	"S-1-5-17","IUSR","An account that is used by the default Internet Information Services (IIS) user.",""
	"S-1-5-18","Local System","A service account that is used by the operating system.",""
	"S-1-5-19","Local Service","A service account that is used by the operating system.",""
	"S-1-5-20","Network Service","A service account that is used by the operating system.",""
	"S-1-5-21-<domain>-500","Administrator","A user account for the system administrator. By default, it is the only user account that is given full control over the system.",""
	"S-1-5-21-<domain>-501","Guest","A user account for people who do not have individual accounts. This user account does not require a password. By default, the Guest account is disabled.",""
	"S-1-5-21-<domain>-502","KRBTGT","A service account that is used by the Key Distribution Center (KDC) service.",""
	"S-1-5-21-<domain>-512","Domain Admins","A global group whose members are authorized to administer the domain. By default, the Domain Admins group is a member of the Administrators group on all computers that have joined a domain, including the domain controllers. Domain Admins is the default owner of any object that is created by any member of the group.",""
	"S-1-5-21-<domain>-513","Domain Users","A global group that, by default, includes all user accounts in a domain. When you create a user account in a domain, it is added to this group by default.",""
	"S-1-5-21-<domain>-514","Domain Guests","A global group that, by default, has only one member, the domain's built-in Guest account.",""
	"S-1-5-21-<domain>-515","Domain Computers","A global group that includes all clients and servers that have joined the domain.",""
	"S-1-5-21-<domain>-516","Domain Controllers","A global group that includes all domain controllers in the domain. New domain controllers are added to this group by default.",""
	"S-1-5-21-<domain>-517","Cert Publishers","A global group that includes all computers that are running an enterprise certification authority. Cert Publishers are authorized to publish certificates for User objects in Active Directory.",""
	"S-1-5-21-<rootdomain>-518","Schema Admins","A universal group in a native-mode domain; a global group in a mixed-mode domain. The group is authorized to make schema changes in Active Directory. By default, the only member of the group is the Administrator account for the forest root domain.",""
	"S-1-5-21-<rootdomain>-519","Enterprise Admins","A universal group in a native-mode domain; a global group in a mixed-mode domain. The group is authorized to make forest-wide changes in Active Directory, such as adding child domains. By default, the only member of the group is the Administrator account for the forest root domain.",""
	"S-1-5-21-<domain>-520","Group Policy Creator Owners","A global group that is authorized to create new Group Policy objects in Active Directory. By default, the only member of the group is Administrator.",""
	"S-1-5-21-<domain>-553","RAS and IAS Servers","A domain local group. By default, this group has no members. Servers in this group have Read Account Restrictions and Read Logon Information access to User objects in the Active Directory domain local group.",""
	"S-1-5-32-544","Administrators","A built-in group. After the initial installation of the operating system, the only member of the group is the Administrator account. When a computer joins a domain, the Domain Admins group is added to the Administrators group. When a server becomes a domain controller, the Enterprise Admins group also is added to the Administrators group.",""
	"S-1-5-32-545","Users","A built-in group. After the initial installation of the operating system, the only member is the Authenticated Users group. When a computer joins a domain, the Domain Users group is added to the Users group on the computer.",""
	"S-1-5-32-546","Guests","A built-in group. By default, the only member is the Guest account. The Guests group allows occasional or one-time users to log on with limited privileges to a computer's built-in Guest account.",""
	"S-1-5-32-547","Power Users","A built-in group. By default, the group has no members. Power users can create local users and groups; modify and delete accounts that they have created; and remove users from the Power Users, Users, and Guests groups. Power users also can install programs; create, manage, and delete local printers; and create and delete file shares.",""
	"S-1-5-32-548","Account Operators","A built-in group that exists only on domain controllers. By default, the group has no members. By default, Account Operators have permission to create, modify, and delete accounts for users, groups, and computers in all containers and organizational units of Active Directory except the Builtin container and the Domain Controllers OU. Account Operators do not have permission to modify the Administrators and Domain Admins groups, nor do they have permission to modify the accounts for members of those groups.",""
	"S-1-5-32-549","Server Operators","A built-in group that exists only on domain controllers. By default, the group has no members. Server Operators can log on to a server interactively; create and delete network shares; start and stop services; back up and restore files; format the hard disk of the computer; and shut down the computer.",""
	"S-1-5-32-550","Print Operators","A built-in group that exists only on domain controllers. By default, the only member is the Domain Users group. Print Operators can manage printers and document queues.",""
	"S-1-5-32-551","Backup Operators","A built-in group. By default, the group has no members. Backup Operators can back up and restore all files on a computer, regardless of the permissions that protect those files. Backup Operators also can log on to the computer and shut it down.",""
	"S-1-5-32-552","Replicators","A built-in group that is used by the File Replication service on domain controllers. By default, the group has no members. Do not add users to this group.",""
	"S-1-5-64-10","NTLM Authentication","A SID that is used when the NTLM authentication package authenticated the client",""
	"S-1-5-64-14","SChannel Authentication","A SID that is used when the SChannel authentication package authenticated the client.",""
	"S-1-5-64-21","Digest Authentication","A SID that is used when the Digest authentication package authenticated the client.",""
	"S-1-5-80","NT Service","An NT Service account prefix",""
	"S-1-5-83-0","NT VIRTUAL MACHINE\Virtual Machines","A built-in group. The group is created when the Hyper-V role is installed. Membership in the group is maintained by the Hyper-V Management Service (VMMS). This group requires the ""Create Symbolic Links"" right (SeCreateSymbolicLinkPrivilege), and also the ""Log on as a Service"" right (SeServiceLogonRight).","Added in Windows 8 and Windows Server 2012"
	"S-1-16-0","Untrusted Mandatory Level","An untrusted integrity level."Added in Windows Vista and Windows Server 2008"
	"S-1-16-4096","Low Mandatory Level","A low integrity level.","Added in Windows Vista and Windows Server 2008"
	"S-1-16-8192","Medium Mandatory Level","A medium integrity level.","Added in Windows Vista and Windows Server 2008"
	"S-1-16-8448","Medium Plus Mandatory Level","A medium plus integrity level.","Added in Windows Vista and Windows Server 2008"
	"S-1-16-12288","High Mandatory Level","A high integrity level.","Added in Windows Vista and Windows Server 2008"
	"S-1-16-16384","System Mandatory Level","A system integrity level.","Added in Windows Vista and Windows Server 2008"
	"S-1-16-20480","Protected Process Mandatory Level","A protected-process integrity level.","Added in Windows Vista and Windows Server 2008"
	"S-1-16-28672","Secure Process Mandatory Level","A secure process integrity level.","This group appears as SID until a Windows Server 2003 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2003 domain controller is added to the domain:"
	"S-1-5-32-554","BUILTIN\Pre-Windows 2000 Compatible Access","An alias added by Windows 2000. A backward compatibility group which allows read access on all users and groups in the domain.","This group appears as SID until a Windows Server 2003 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2003 domain controller is added to the domain:"
	"S-1-5-32-555","BUILTIN\Remote Desktop Users","An alias. Members in this group are granted the right to logon remotely.","This group appears as SID until a Windows Server 2003 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2003 domain controller is added to the domain:"
	"S-1-5-32-556","BUILTIN\Network Configuration Operators","An alias. Members in this group can have some administrative privileges to manage configuration of networking features.","This group appears as SID until a Windows Server 2003 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2003 domain controller is added to the domain:"
	"S-1-5-32-557","BUILTIN\Incoming Forest Trust Builders","An alias. Members of this group can create incoming, one-way trusts to this forest.","This group appears as SID until a Windows Server 2003 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2003 domain controller is added to the domain:"
	"S-1-5-32-558","BUILTIN\Performance Monitor Users","An alias. Members of this group have remote access to monitor this computer.","This group appears as SID until a Windows Server 2003 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2003 domain controller is added to the domain:"
	"S-1-5-32-559","BUILTIN\Performance Log Users","An alias. Members of this group have remote access to schedule logging of performance counters on this computer.","This group appears as SID until a Windows Server 2003 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2003 domain controller is added to the domain:"
	"S-1-5-32-560","BUILTIN\Windows Authorization Access Group","An alias. Members of this group have access to the computed tokenGroupsGlobalAndUniversal attribute on User objects.","This group appears as SID until a Windows Server 2003 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2003 domain controller is added to the domain:"
	"S-1-5-32-561","BUILTIN\Terminal Server License Servers","An alias. A group for Terminal Server License Servers. When Windows Server 2003 Service Pack 1 is installed, a new local group is created.","This group appears as SID until a Windows Server 2003 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2003 domain controller is added to the domain:"
	"S-1-5-32-562","BUILTIN\Distributed COM Users","An alias. A group for COM to provide computerwide access controls that govern access to all call, activation, or launch requests on the computer.","This group appears as SID until a Windows Server 2008 or Windows Server 2008 R2 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2008 or Windows Server 2008 R2 domain controller is added to the domain:"
	"S-1-5-21-<domain>-498","Enterprise Read-only Domain Controllers","A Universal group. Members of this group are Read-Only Domain Controllers in the enterprise","This group appears as SID until a Windows Server 2008 or Windows Server 2008 R2 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2008 or Windows Server 2008 R2 domain controller is added to the domain:"
	"S-1-5-21-<domain>-521","Read-only Domain Controllers","A Global group. Members of this group are Read-Only Domain Controllers in the domain","This group appears as SID until a Windows Server 2008 or Windows Server 2008 R2 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2008 or Windows Server 2008 R2 domain controller is added to the domain:"
	"S-1-5-32-569","BUILTIN\Cryptographic Operators","A Builtin Local group. Members are authorized to perform cryptographic operations.","This group appears as SID until a Windows Server 2008 or Windows Server 2008 R2 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2008 or Windows Server 2008 R2 domain controller is added to the domain:"
	"S-1-5-21-<domain>-571","Allowed RODC Password Replication Group","A Domain Local group. Members in this group can have their passwords replicated to all read-only domain controllers in the domain.","This group appears as SID until a Windows Server 2008 or Windows Server 2008 R2 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2008 or Windows Server 2008 R2 domain controller is added to the domain:"
	"S-1-5-21-<domain>-572","Denied RODC Password Replication Group","A Domain Local group. Members in this group cannot have their passwords replicated to any read-only domain controllers in the domain","This group appears as SID until a Windows Server 2008 or Windows Server 2008 R2 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2008 or Windows Server 2008 R2 domain controller is added to the domain:"
	"S-1-5-32-573","BUILTIN\Event Log Readers","A Builtin Local group. Members of this group can read event logs from local machine.","This group appears as SID until a Windows Server 2008 or Windows Server 2008 R2 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2008 or Windows Server 2008 R2 domain controller is added to the domain:"
	"S-1-5-32-574","BUILTIN\Certificate Service DCOM Access","A Builtin Local group. Members of this group are allowed to connect to Certification Authorities in the enterprise.","This group appears as SID until a Windows Server 2012 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2012 domain controller is added to the domain:"
	"S-1-5-21-<domain>-522","Cloneable Domain Controllers","A Global group. Members of this group that are domain controllers may be cloned.","This group appears as SID until a Windows Server 2012 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2012 domain controller is added to the domain:"
	"S-1-5-32-575","BUILTIN\RDS Remote Access Servers","A Builtin Local group. Servers in this group enable users of RemoteApp programs and personal virtual desktops access to these resources. In Internet-facing deployments, these servers are typically deployed in an edge network. This group needs to be populated on servers running RD Connection Broker. RD Gateway servers and RD Web Access servers used in the deployment need to be in this group.","This group appears as SID until a Windows Server 2012 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2012 domain controller is added to the domain:"
	"S-1-5-32-576","BUILTIN\RDS Endpoint Servers","A Builtin Local group. Servers in this group run virtual machines and host sessions where users RemoteApp programs and personal virtual desktops run. This group needs to be populated on servers running RD Connection Broker. RD Session Host servers and RD Virtualization Host servers used in the deployment need to be in this group.","This group appears as SID until a Windows Server 2012 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2012 domain controller is added to the domain:"
	"S-1-5-32-577","BUILTIN\RDS Management Servers","A Builtin Local group. Servers in this group can perform routine administrative actions on servers running Remote Desktop Services. This group needs to be populated on all servers in a Remote Desktop Services deployment. The servers running the RDS Central Management service must be included in this group.","This group appears as SID until a Windows Server 2012 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2012 domain controller is added to the domain:"
	"S-1-5-32-578","BUILTIN\Hyper-V Administrators","A Builtin Local group. Members of this group have complete and unrestricted access to all features of Hyper-V.","This group appears as SID until a Windows Server 2012 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2012 domain controller is added to the domain:"
	"S-1-5-32-579","BUILTIN\Access Control Assistance Operators","A Builtin Local group. Members of this group can remotely query authorization attributes and permissions for resources on this computer.","This group appears as SID until a Windows Server 2012 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2012 domain controller is added to the domain:"
	"S-1-5-32-580","BUILTIN\Remote Management Users","A Builtin Local group. Members of this group can access WMI resources over management protocols (such as WS-Management via the Windows Remote Management service). This applies only to WMI namespaces that grant access to the user.","This group appears as SID until a Windows Server 2012 domain controller is made the primary domain controller (PDC) operations master role holder. The ""operations master"" is also known as flexible single master operations (FSMO). This additional built-in group is created when a Windows Server 2012 domain controller is added to the domain:"
'@ | ConvertFrom-Csv
## Duplicate:	"S-1-5-80-0","All Services","A group that includes all service processes that are configured on the system. Membership is controlled by the operating system.","Added in Windows Server 2008 R2"
}

Function Test-BLSid {
[CmdletBinding()]
## Tests if the SID passed is a valid SID.
## Requires the custom class "BLLookupAccount"
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)]
	[string]$Sid
)
	Process {
		If ([string]::IsNullOrEmpty($Sid)) {
			Throw "Mandatory argument 'Sid' is missing or empty!"
		}
		Return ([BLLookupAccount]::TestSid($Sid))
	}
}

## ====================================================================================================
## Group "Registry Management" x64
## Registry functions that always refer to the 64bit registry, even when called from a 32bit environment
## Functions can be called from a 64bit environment as well.
## Requires .Net 4.0 or later!
## ====================================================================================================

Function Get-BLRegistryPSPathX64([string]$Path) {
## Returns a string with the (simulated) PsPath for compatibility with Get-ItemProperty.
## Not exported!
	$Hive, $Subkey = $Path.Split("\:", 2, [StringSplitOptions]"RemoveEmptyEntries")
	$Subkey = $Subkey.Trim("\*")
	Switch ($Hive) {
		{@("HKLM", "HKEY_LOCAL_MACHINE") -Contains $_}	{
			$PSHive = "HKEY_LOCAL_MACHINE"
		}
		{@("HKCU", "HKEY_CURRENT_USER") -Contains $_}	{
			$PSHive = "HKEY_CURRENT_USER"
		}
		{@("HKU", "HKEY_USERS") -Contains $_}	{
			$PSHive = "HKEY_USERS"
		}
		Default {
			Throw "Unknown registry hive '$($Hive)'!"
		}
	}
	Return "Microsoft.PowerShell.Core\Registry::$($PSHive)\$($Subkey)"
}

Function Get-BLRegistryHiveX64([string]$Path, [string]$ComputerName = $ENV:ComputerName) {
## Returns a Microsoft.Win32.RegistryHive object based on the $Path passed.
## Not exported!
	Switch ($Path.Split("\:")[0]) {
		{@("HKLM", "HKEY_LOCAL_MACHINE") -Contains $_}	{
			$Hive = [Microsoft.Win32.RegistryHive]"LocalMachine"
		}
		{@("HKCU", "HKEY_CURRENT_USER") -Contains $_}	{
			$Hive = [Microsoft.Win32.RegistryHive]"CurrentUser"
		}
		{@("HKU", "HKEY_USERS") -Contains $_}	{
			$Hive = [Microsoft.Win32.RegistryHive]"Users"
		}
		Default {
			Throw "Unknown registry hive '$($Path.Split("\:")[0])'!"
		}
	}
	Return ([Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $ComputerName, [Microsoft.Win32.RegistryView]::Registry64))
}

Function Get-BLRegistryKeyX64([string]$Path, [string]$ComputerName = $ENV:ComputerName, [System.Management.Automation.ActionPreference]$ErrorAction = $ErrorActionPreference) {
## Returns a PS object with all values as properties from the x64 registry view when called from a 32bit environment.
## Format is basically the same as what Get-ItemProperty requires and returns.
## Accepts a trailing \* to return all subkeys under the given key.
## See 
## http://msdn.microsoft.com/en-us/library/dd411615(v=vs.110).aspx
	Try {
		$PSPath = Get-BLRegistryPSPathX64 -Path $Path
		$SubKey = $Path.Split("\:", 2, [StringSplitOptions]"RemoveEmptyEntries")[1]
		$SubKey = $SubKey.Trim("\")
		If ($SubKey.EndsWith("\*")) {
			$SubKey = $SubKey.Trim("\*")
			$ReturnChildren = $True
		} Else {
			$ReturnChildren = $False
		}
		$RegistryHive = Get-BLRegistryHiveX64 -Path $Path -ComputerName $ComputerName
		$RegistryKey = $RegistryHive.OpenSubKey($SubKey)
		If (-Not $RegistryKey) {
			Throw "Registry path '$Path' not found!"
		}
		If ($ReturnChildren) {
			$Result = @()
			ForEach ($Child In $RegistryKey.GetSubKeyNames()) {
				$RegistryChildKey = $RegistryHive.OpenSubKey($SubKey + "\" + $Child)
				$SubResult = New-Object Object
				ForEach ($Value In $RegistryChildKey.GetValueNames()) {
					If ($Value -eq "") {
						Add-Member -InputObject $SubResult -MemberType "NoteProperty" -Name "(default)" -Value $RegistryChildKey.GetValue($Value)
					} Else {
						Add-Member -InputObject $SubResult -MemberType "NoteProperty" -Name $Value -Value $RegistryChildKey.GetValue($Value)
					}
				}
				Add-Member -InputObject $SubResult -MemberType "NoteProperty" -Name "PSPath"		-Value ($PSPath + "\" + $Child)
				Add-Member -InputObject $SubResult -MemberType "NoteProperty" -Name "PSParentPath"	-Value $PSPath
				Add-Member -InputObject $SubResult -MemberType "NoteProperty" -Name "PSChildName"	-Value $Child
				Add-Member -InputObject $SubResult -MemberType "NoteProperty" -Name "PSLastWriteTime"	-Value ([BLRegQueryInfoKey]::GetLastWriteTime($RegistryChildKey.Handle))
				$RegistryChildKey.Close()
				$Result += $SubResult
			}
		} Else {
			$Result = New-Object Object
			ForEach ($Value In $RegistryKey.GetValueNames()) {
				If ($Value -eq "") {
					Add-Member -InputObject $Result -MemberType "NoteProperty" -Name "(default)" -Value $RegistryKey.GetValue($Value)
				} Else {
					Add-Member -InputObject $Result -MemberType "NoteProperty" -Name $Value -Value $RegistryKey.GetValue($Value)
				}
			}
			Add-Member -InputObject $Result -MemberType "NoteProperty" -Name "PSPath"		-Value $PSPath
			Add-Member -InputObject $Result -MemberType "NoteProperty" -Name "PSParentPath"	-Value (Split-Path -Parent $PSPath)
			Add-Member -InputObject $Result -MemberType "NoteProperty" -Name "PSChildName"	-Value (Split-Path -Leaf $PSPath)
			Add-Member -InputObject $Result -MemberType "NoteProperty" -Name "PSLastWriteTime"	-Value ([BLRegQueryInfoKey]::GetLastWriteTime($RegistryKey.Handle))
		}
		$RegistryKey.Close()
		$RegistryHive.Close()
		Return $Result
	} Catch {
		If ($RegistryHive) {$RegistryHive.Close()}
		If ($ErrorAction -eq [System.Management.Automation.ActionPreference]::SilentlyContinue) {
			Return $Null
		} Else {
			Throw $_
		}
	}
}

Function Get-BLRegistryValueKind([string]$Type) {
## Returns a Microsoft.Win32.RegistryValueKind based on the $Type passed.
## $Type expects either the well-known strings (REG_SZ, ...) as listed in the registry,
## or the enumeration types as listed in http://msdn.microsoft.com/en-us/library/microsoft.win32.registryvaluekind(v=vs.110).aspx
## Not exported!
	Switch ($Type) {
		{@("Binary", "DWord", "QWord", "MultiString", "String", "None", "Unknown") -Contains $_} {
			$RegistryValueKind = $_
		}
		"REG_BINARY" {
			$RegistryValueKind = "Binary"
		}
		"REG_DWORD" {
			$RegistryValueKind = "DWord"
		}
		"REG_QWORD" {
			$RegistryValueKind = "QWord"
		}
		"REG_MULTI_SZ" {
			$RegistryValueKind = "MultiString"
		}
		"REG_SZ" {
			$RegistryValueKind = "String"
		}
		Default {
			Throw "Unknown registry value kind '$($Type)'!"
		}
	}
	Return ([Microsoft.Win32.RegistryValueKind]::$RegistryValueKind)
}

Function Get-BLRegistryValueX64([string]$Path, [string]$Name = "", [string]$ComputerName = $ENV:ComputerName, [System.Management.Automation.ActionPreference]$ErrorAction = $ErrorActionPreference) {
	Try {
		$SubKey = $Path.Split("\:", 2, [StringSplitOptions]"RemoveEmptyEntries")[1]
		$RegistryHive = Get-BLRegistryHiveX64 -Path $Path -ComputerName $ComputerName
		$RegistryKeyRead = $RegistryHive.OpenSubKey($SubKey)
		If (-Not $RegistryKeyRead) {
			Throw "Registry path '$Path' not found!"
		}
		If ($RegistryKeyRead.GetValueNames() -Contains $Name) {
			$Result = $RegistryKeyRead.GetValue($Name)
		} Else {
			If ([string]::IsNullOrEmpty($Name)) {
				Throw "Default value not set in '$Path'!"
			} Else {
				Throw "Registry Value '$Name' not found in '$Path'!"
			}
		}
		$RegistryKeyRead.Close()
		$RegistryHive.Close()
		Return $Result
	} Catch {
		If ($RegistryHive) {$RegistryHive.Close()}
		If ($ErrorAction -eq [System.Management.Automation.ActionPreference]::SilentlyContinue) {
			Return $Null
		} Else {
			Throw $_
		}
	}
}

Function New-BLRegistryKeyX64([string]$Path, [string]$ComputerName = $ENV:ComputerName, [System.Management.Automation.ActionPreference]$ErrorAction = $ErrorActionPreference) {
	Try {
		$SubKey = $Path.Split("\:", 2, [StringSplitOptions]"RemoveEmptyEntries")[1]
		$RegistryHive = Get-BLRegistryHiveX64 -Path $Path -ComputerName $ComputerName
		$RegistryKeyRead = $RegistryHive.OpenSubKey($SubKey)
		If ($RegistryKeyRead) {
			$RegistryKeyRead.Close()
		} Else {
			$RegistryKeyWrite = $RegistryHive.OpenSubKey("", $True)	## $True - Write Access
			$Result = $RegistryKeyWrite.CreateSubKey($SubKey)
			$RegistryKeyWrite.Close()
			If (-Not $Result) {
				Throw "Registry path '$Path' could not be created!"
			}
		}
		$RegistryHive.Close()
		Return (Get-BLRegistryKeyX64 -Path $Path -ComputerName $ComputerName -ErrorAction $ErrorAction)
	} Catch {
		If ($RegistryHive) {$RegistryHive.Close()}
		If ($ErrorAction -eq [System.Management.Automation.ActionPreference]::SilentlyContinue) {
			Return $Null
		} Else {
			Throw $_
		}
	}
}

Function Remove-BLRegistryKeyX64([string]$Path, [string]$ComputerName = $ENV:ComputerName, [System.Management.Automation.ActionPreference]$ErrorAction = $ErrorActionPreference) {
	Try {
		$SubKey = $Path.Split("\:", 2, [StringSplitOptions]"RemoveEmptyEntries")[1]
		$RegistryHive = Get-BLRegistryHiveX64 -Path $Path -ComputerName $ComputerName
		$RegistryKeyWrite = $RegistryHive.OpenSubKey("", $True)	## $True - Write Access
		$RegistryKeyWrite.DeleteSubKey($SubKey, $True)	## $True - Raise an exception if key is not found
		$RegistryKeyWrite.Close()
		$RegistryHive.Close()
	} Catch {
		If ($RegistryHive) {$RegistryHive.Close()}
		If ($ErrorAction -eq [System.Management.Automation.ActionPreference]::SilentlyContinue) {
			Return $Null
		} Else {
			Throw $_
		}
	}
}

Function Remove-BLRegistryValueX64([string]$Path, [string]$Name = "", [string]$ComputerName = $ENV:ComputerName, [System.Management.Automation.ActionPreference]$ErrorAction = $ErrorActionPreference) {
	Try {
		$SubKey = $Path.Split("\:", 2, [StringSplitOptions]"RemoveEmptyEntries")[1]
		$RegistryHive = Get-BLRegistryHiveX64 -Path $Path -ComputerName $ComputerName
		$RegistryKeyWrite = $RegistryHive.OpenSubKey($SubKey, $True)	## $True - Write Access
		If (-Not $RegistryKeyWrite) {
			Throw "Registry path '$Path' not found!"
		}
		$RegistryKeyWrite.DeleteValue($Name)
		$RegistryKeyWrite.Close()
		$RegistryHive.Close()
		Return (Get-BLRegistryKeyX64 -Path $Path -ComputerName $ComputerName -ErrorAction $ErrorAction)
	} Catch {
		If ($RegistryHive) {$RegistryHive.Close()}
		If ($ErrorAction -eq [System.Management.Automation.ActionPreference]::SilentlyContinue) {
			Return $Null
		} Else {
			Throw $_
		}
	}
}

Function Set-BLRegistryValueX64([string]$Path, [string]$Name = "", [string]$Type = "REG_SZ", $Value = $Null, [string]$ComputerName = $ENV:ComputerName, [System.Management.Automation.ActionPreference]$ErrorAction = $ErrorActionPreference) {
	Try {
		$SubKey = $Path.Split("\:", 2, [StringSplitOptions]"RemoveEmptyEntries")[1]
		$RegistryHive = Get-BLRegistryHiveX64 -Path $Path -ComputerName $ComputerName
		$RegistryKeyWrite = $RegistryHive.OpenSubKey($SubKey, $True)	## $True - Write Access
		If (-Not $RegistryKeyWrite) {
			Throw "Registry path '$Path' not found!"
		}
		If ($Value -eq $Null) {
			Throw "No value passed!"
		}
		$RegistryKeyWrite.SetValue($Name, $Value, (Get-BLRegistryValueKind -Type $Type))
		$RegistryKeyWrite.Close()
		$RegistryHive.Close()
		Return (Get-BLRegistryKeyX64 -Path $Path -ComputerName $ComputerName -ErrorAction $ErrorAction)
	} Catch {
		If ($RegistryHive) {$RegistryHive.Close()}
		If ($ErrorAction -eq [System.Management.Automation.ActionPreference]::SilentlyContinue) {
			Return $Null
		} Else {
			Throw $_
		}
	}
}

## ====================================================================================================
## Group "Internet Management"
## Functions that handle Internet Options.
## ====================================================================================================

Function Get-BLInternetZoneFromUrl {
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)]
	[string]$URL,
	[Parameter(Mandatory=$False, ValueFromPipeline=$False)]
	[switch]$NoSavedFileCheck,
	[Parameter(Mandatory=$False, ValueFromPipeline=$False)]
	[switch]$IsFile,
	[Parameter(Mandatory=$False, ValueFromPipeline=$False)]
	[switch]$AcceptWildcardScheme,
	[Parameter(Mandatory=$False, ValueFromPipeline=$False)]
	[switch]$EnforceRestricted,
	[Parameter(Mandatory=$False, ValueFromPipeline=$False)]
	[switch]$RequireSavedFilecheck,
	[Parameter(Mandatory=$False, ValueFromPipeline=$False)]
	[switch]$DontUnescape,
	[Parameter(Mandatory=$False, ValueFromPipeline=$False)]
	[switch]$DontUseCache,
	[Parameter(Mandatory=$False, ValueFromPipeline=$False)]
	[switch]$ForceIntranetFlags,
	[Parameter(Mandatory=$False, ValueFromPipeline=$False)]
	[switch]$IgnoreZoneMappings
)
	Begin {
		If ([string]::IsNullOrEmpty($URL)) {Throw "$($MyInvocation.MyCommand): No URL specified!"}
		$MUTZFlags = 0
		If ($NoSavedFileCheck)		{$MutzFlags = $MutzFlags -bor [BLInternetSecurityManager]::MUTZ_NOSAVEDFILECHECK}
		If ($IsFile)				{$MutzFlags = $MutzFlags -bor [BLInternetSecurityManager]::MUTZ_ISFILE}
		If ($AcceptWildcardScheme)	{$MutzFlags = $MutzFlags -bor [BLInternetSecurityManager]::MUTZ_ACCEPT_WILDCARD_SCHEME}
		If ($EnforceRestricted)		{$MutzFlags = $MutzFlags -bor [BLInternetSecurityManager]::MUTZ_ENFORCERESTRICTED}
		If ($RequireSavedFilecheck)	{$MutzFlags = $MutzFlags -bor [BLInternetSecurityManager]::MUTZ_REQUIRESAVEDFILECHECK}
		If ($DontUnescape)			{$MutzFlags = $MutzFlags -bor [BLInternetSecurityManager]::MUTZ_DONT_UNESCAPE}
		If ($DontUseCache)			{$MutzFlags = $MutzFlags -bor [BLInternetSecurityManager]::MUTZ_DONT_USE_CACHE}
		If ($ForceIntranetFlags)	{$MutzFlags = $MutzFlags -bor [BLInternetSecurityManager]::MUTZ_FORCE_INTRANET_FLAGS}
		If ($IgnoreZoneMappings)	{$MutzFlags = $MutzFlags -bor [BLInternetSecurityManager]::MUTZ_IGNORE_ZONE_MAPPINGS}
	}
	Process {
		[BLInternetSecurityManager]::MapUrlToZone($URL, $MUTZFlags) |
			Select-Object @{Name = "URL"; Expression = {$URL}}, @{Name = "MUTZFlags"; Expression = {$MUTZFlags}}, @{Name = "Zone"; Expression = {$Zone = $_; ($BL_INTERNET_URLZONE.GetEnumerator() | ? {$_.Value -eq $Zone}).Key}} |
			Write-Output
	}
}

Function Get-BLInternetZoneMappings {
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)]
	[ValidateSet("", "LocalMachine", "Intranet", "Trusted", "Internet", "Restricted")]
	[string]$Zone = "",
	[switch]$IncludeDefaultZoneMappings
)
	Begin {
		$DefaultZoneMappings = @(
			"hcp://system",
			"http://localhost",
			"https://localhost"
		)
		If ($IncludeDefaultZoneMappings) {
			$WhereClause = {$True}
		} Else {
			$WhereClause = {($DefaultZoneMappings -notcontains $_)}
		}
	}
	Process {
		If ([string]::IsNullOrEmpty($Zone)) {
			ForEach ($Zone In "LocalMachine", "Intranet", "Trusted", "Internet", "Restricted") {
				$NumericZone = $BL_INTERNET_URLZONE[$Zone]
				[BLInternetSecurityManager]::GetZoneMappings($NumericZone) |
					Where-Object $WhereClause |
					Select-Object @{Name = "URL"; Expression = {$_}}, @{Name = "Zone"; Expression = {$Zone}} |
					Write-Output
			}
		} Else {
			$NumericZone = $BL_INTERNET_URLZONE[$Zone]
			[BLInternetSecurityManager]::GetZoneMappings($NumericZone) |
				Where-Object $WhereClause |
				Select-Object @{Name = "URL"; Expression = {$_}}, @{Name = "Zone"; Expression = {$Zone}} |
				Write-Output
		}
	}
}

Function Remove-BLInternetZoneMapping {
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)]
	[string]$URL,
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=1)]
	[ValidateSet("LocalMachine", "Intranet", "Trusted", "Internet", "Restricted")]
	[string]$Zone = "LocalMachine",
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=2)]
	[switch]$ESCDomain
)
	Begin {
		$Return = 0
	}
	Process {
		If ([string]::IsNullOrEmpty($URL)) {Throw "$($MyInvocation.MyCommand): No URL specified!"}
		$NumericZone = $BL_INTERNET_URLZONE[$Zone]
		If ($ESCDomain) {$NumericZone = $NumericZone -bor [BLInternetSecurityManager]::URLZONE_ESC_FLAG}
		$ExitCode = [BLInternetSecurityManager]::SetZoneMapping($NumericZone, $URL, [BLInternetSecurityManager]::SZM_DELETE, 1)
		Switch ($ExitCode) {
			0 {}
			Default {
				"$($MyInvocation.MyCommand): Trying to remove URL '$($URL)' from zone '$($Zone)' returned error $($ExitCode)!" | Write-Error
				$Return += 1
			}
		}
	}
	End {
		If ($Return -eq 0) {
			0 | Write-Output
		} Else {
			1 | Write-Output
		}
	}
}

Function Set-BLInternetZoneMapping {
## Sets a zone mapping like in the Internet Security Options.
## If the function returns -2147024816, the entry already exists in another zone; delete it before setting it, or use -Force.
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)]
	[string]$URL,
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=1)]
	[ValidateSet("LocalMachine", "Intranet", "Trusted", "Internet", "Restricted")][ValidateNotNull()]
	[string]$Zone,
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=2)]
	[switch]$ESCDomain,
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=3)]
	[switch]$Force
)
	Begin {
		$Return = 0
	}
	Process {
		If ([string]::IsNullOrEmpty($URL)) {Throw "$($MyInvocation.MyCommand): No URL specified!"}
		If ([string]::IsNullOrEmpty($Zone)) {Throw "$($MyInvocation.MyCommand): No Zone specified!"}
		$NumericZone = $BL_INTERNET_URLZONE[$Zone]
		If ($ESCDomain) {$NumericZone = $NumericZone -bor [BLInternetSecurityManager]::URLZONE_ESC_FLAG}
		If ($Force) {$bForce = 1} Else {$bForce = 0}
		$ExitCode = [BLInternetSecurityManager]::SetZoneMapping($NumericZone, $URL, [BLInternetSecurityManager]::SZM_CREATE, $bForce)
		Switch ($ExitCode) {
			0 {}
			-2147024816 {
				"$($MyInvocation.MyCommand): URL '$($URL)' is already added in a zone different from '$($Zone)'; use the '-Force' switch to change the existing entry!" | Write-Error
				$Return += 1
			}
			Default {
				"$($MyInvocation.MyCommand): Trying to add URL '$($URL)' to zone '$($Zone)' returned error $($ExitCode)!" | Write-Error
				$Return += 1
			}
		}
	}
	End {
		If ($Return -eq 0) {
			0 | Write-Output
		} Else {
			1 | Write-Output
		}
	}
}

## ====================================================================================================
## Group "INI Management"
## Functions that work in memory with a hash table; designed especially to facilitate creation of ini files based on ConfigDB variables.
## ====================================================================================================

Function Get-BLIniHTContent([string]$Path) {
## Returns a hash table with the section names as keys; each value consists of another hash table with the values and data pairs.
## There is no "Set-BLIIniHTContent"; pipe the output of "Out-BLIniHT" to "Set-Content" to do this.
## Error: returns $Null
	If (-Not (Test-Path -Path $Path)) {
		Return $Null
	}
	$ini = @{}
	$Section = "____ROOT____"
	$ini[$Section] = @{}
	Switch -RegEx -File $Path {
		"^\[(.+)\]" {					# Section
			$Section = $Matches[1]
			$ini[$Section] = @{}
			$CommentCount = 0
		}
		"^(;.*)$" {						# Comment
			$Value = $Matches[1]
			$CommentCount +=  1
			$Key = "____COMMENT____{0:D4}" -f $CommentCount
			$ini[$Section][$Key] = $Value
		}
		"(.+?)\s*=(.*)" {				# Key
			$Key = $Matches[1].Trim()
			$Value = $Matches[2].Trim()
			$ini[$Section][$Key] = $Value
		}
	}
	Return $ini
}

Function Get-BLIniHTSection([hashtable]$ini, [string]$Section = "____ROOT____") {
## Returns a hash table with all key and value pairs in the specified section; if the section is not found, an empty hashtable will be returned.
## Error: returns $Null
	If ([string]::IsNullOrEmpty($Section)) {
		"No section passed!" | Write-BLLog -LogType CriticalError
		Return $Null
	}
	If (-Not $ini.ContainsKey($Section)) {
		Return @{}
	}
	Return $ini[$Section]
}

Function Get-BLIniHTSectionNames([hashtable]$ini) {
## Returns a sorted array with all section names found in the ini hashtable
	$SectionNames = @()
	ForEach ($Key In ($ini.Keys | ? {$Key -ne "____ROOT____"} | sort)) {
		$SectionNames += $Key
	}
	Return $SectionNames
}

Function Get-BLIniHTValue([hashtable]$ini, [string]$Section = "____ROOT____", [string]$Key, [string]$Default = "") {
## Returns the value for the key specified in the section; if the section or key is not found, the $Default value will be returned.
## Error: returns $Null
	If ([string]::IsNullOrEmpty($Section)) {
		"No section passed!" | Write-BLLog -LogType CriticalError
		Return $Null
	}
	If ([string]::IsNullOrEmpty($Key)) {
		"No key passed!" | Write-BLLog -LogType CriticalError
		Return $Null
	}
	If (-Not $ini.ContainsKey($Section)) {
		Return $Default
	}
	If (-Not $ini[$Section].ContainsKey($Key)) {
		Return $Default
	}
	Return $ini[$Section][$Key]
}

Function Set-BLIniHTSection([hashtable]$ini, [string]$Section = "____ROOT____", [hashtable]$Content = @{}) {
## Fills a section with the content of a hash table.
## If the section existed already, it will be overweritten!
## Success: returns 0
## Error: returns 1
	If ([string]::IsNullOrEmpty($Section)) {
		"No section passed!" | Write-BLLog -LogType CriticalError
		Return 1
	}
	$ini[$Section] = $Content
	Return 0
}

Function Set-BLIniHTValue([hashtable]$ini, [string]$Section = "____ROOT____", [string]$Key, [string]$Value = "", [string]$Default = "", [array]$AllowedValues = @(), [switch]$ForceEmpty) {
## Adds a value to the ini hash array. 
## If $value is $Null or empty, the $default value will be set; this is for use with ConfigDB variables that may or may not exist and may or may not be empty.
## If both $value and $default are empty, the key is ignored and will not be added to the ini settings, unless $ForceEmpty is used.
## Success: returns 0
## Error: returns 1
	If ([string]::IsNullOrEmpty($Section)) {
		"No section passed!" | Write-BLLog -LogType CriticalError
		Return 1
	}
	If ([string]::IsNullOrEmpty($Key) -Or ($Key.Trim().Length -eq 0)) {
		"No key passed!" | Write-BLLog -LogType CriticalError
		Return 1
	}
	$Key = $Key.Trim()
	$Value = $Value.Trim()
	If ($Value.Length -eq 0) {
		$Value = $Default
	}
	If (-Not $ini.ContainsKey($Section)) {
		$ini[$Section] = @{}
	}
	If (($Value.Length -ne 0) -Or $ForceEmpty) {
		If (($AllowedValues.Count -gt 1) -And ($AllowedValues -NotContains $Value)) {
			"Could not set key '$Key' to  Value '$Value'; the value is not in the allowed list of '$($AllowedValues -Join ", ")'!" | Write-BLLog -LogType CriticalError
			Return 1
		}
		$ini[$Section][$Key] = $Value
	}
	Return 0
}

Function Remove-BLIniHTKey([hashtable]$ini, [string]$Section = "____ROOT____", [string]$Key) {
## Removes the specified key from the ini hash table.
## Success: returns 0
## Error: returns 1
	If ([string]::IsNullOrEmpty($Section)) {
		"No section passed!" | Write-BLLog -LogType CriticalError
		Return 1
	}
	If ([string]::IsNullOrEmpty($Key)) {
		"No key passed!" | Write-BLLog -LogType CriticalError
		Return 1
	}
	If (-Not $ini.ContainsKey($Section)) {
		"Section '$Section' not found!" | Write-BLLog -LogType CriticalError
		Return 1
	}
	If (-Not $ini[$Section].ContainsKey($Key)) {
		Return 0
	}
	$ini[$Section].Remove($Key)
	Return 0
}

Function Remove-BLIniHTSection([hashtable]$ini, [string]$Section = "____ROOT____") {
## Removes the specified key from the ini hash table.
## Success: returns 0
## Error: returns 1
	If ([string]::IsNullOrEmpty($Section)) {
		"No section passed!" | Write-BLLog -LogType CriticalError
		Return 1
	}
	If (-Not $ini.ContainsKey($Section)) {
		Return 0
	}
	$ini.Remove($Section)
	Return 0
}

Function Out-BLIniHT {
## Returns a string array with the contents of the ini hash table, sorted first by section, then by keys
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)]
	[hashtable]$ini,
	[Parameter(Mandatory=$False, Position=1)]
	[string[]]$SectionOrder = @()
)
	Process {
		$OutString = @()
		$SectionRoot = "____ROOT____"
		If ($ini.ContainsKey($SectionRoot) -And ($ini[$SectionRoot].Keys.Count -gt 0)) {
			ForEach ($Key In $ini[$SectionRoot].Keys | Sort-Object) {
				$OutString += $ini[$SectionRoot][$Key]
			}
		}
		$FirstSection = $True
		If ($SectionOrder.Count -gt 0) {
			$SectionSource = $SectionOrder
		} Else {
			$SectionSource = @()
			ForEach ($Key In ($ini.Keys | ? {$_ -ne $SectionRoot} | Sort-Object)) {
				$SectionSource += $Key
			}
		}
		ForEach ($Section In $SectionSource) {
			If ($FirstSection) {
				$FirstSection = $False
			} Else {
				$OutString += ""
			}
			$OutString += "[$Section]"
			ForEach ($Key In ($ini[$Section].Keys | Sort-Object)) {
				If ($Key.StartsWith("____COMMENT____")) {
					$OutString += $ini[$Section][$Key]
				} Else {
					$OutString += "$($Key)=$($ini[$Section][$Key])"
				}
			}
		}
		Return $OutString
	}
}

## ====================================================================================================
## Group "INI File Management"
## Legacy functions that work immediately on an ini file.
## ====================================================================================================

Function Export-BLIniFile {
## Old name: SCCM:Export-Ini
## Writes (INI format) hash table contents into an INI file
param (
	[hashtable]$INIObject = $(throw "please specify a value for the INIObject parameter"),
	[string]$FileName = $(throw "please specify a value for the FileName parameter")
)
	trap {"Error while trying to export the hash table contents to the INI file '$FileName'. Last Error was $Error[0]" | Write-BLLog -LogType CriticalError; return 1; continue}
	If ($(Test-Path $FileName -IsValid)) {
		$Content = @()
		ForEach ($Category in $INIObject.Keys) {
			$Content += "[$Category]"
			ForEach ($Key in $INIObject.$Category.Keys) {
				$TrimmedKey = $Key.Trim()
				$Content += "$TrimmedKey=$($INIObject.$Category.$Key)"
			}
		}
		$Content | Set-Content $FileName -Force | Out-Null
		"INI file '$FileName' successfuly created / modified." | Write-BLLog -LogType Information
		return 0
	} Else {
		"Invalid FileName parameter '$FileName'" | Write-BLLog -LogType CriticalError
		return 1
	}
}

Function Get-BLIniKey {
## Old name: SCCM:Get-IniKey
## Determines a specific INI file key entry value
## (imports INI file into a hash table, searches for the key within the given category and returns its value)
param (
	[string]$FileName = $(throw "Supply a valid filename (full path) parameter"),
	[string]$Category = $(throw "Supply a value for the Category parameter"),
	[string]$Key = $(throw "Supply a value for the Key parameter")
)
	trap {"Error while trying to read the key '$Key' in category '$Category' from INI file '$FileName'. Last Error was $Error[0]" | Write-BLLog -LogType CriticalError; return $Null; continue}
	$TrimmedKey = $Key.Trim()
	$ini = Import-BLIniFile -FileName $FileName
	If ($ini.Count) {
		If ($ini.Contains($Category)) {
			If ($ini.$Category.Contains($TrimmedKey)) {
				return $ini.$Category.$TrimmedKey
			} Else {
				"Key '$TrimmedKey' does not exist in '$FileName', category '$Category'" | Write-BLLog -LogType Warning
				return ""
			}
		} Else {
			"Category '$Category' does not exist in '$FileName'" | Write-BLLog -LogType Warning
			return ""
		}
	} Else {
		return ""
	}
}

Function Import-BLIniFile {
## Old name: SCCM:Import-Ini
## Imports INI file contents into a hash table, returns hash table
Param (
	[string]$FileName = $(throw "Please specify a value for the FileName parameter")
)
	trap {"Error while trying to import INI file '$FileName'. Last Error was $Error[0]" | Write-BLLog -LogType CriticalError; return @{}; continue}
	$ini = @{}
	If (Test-Path $FileName) {
		switch -regex -file $FileName {
			"^\[(.+)\]$" {
				$Category = $matches[1]
				$ini.$Category = @{}
			}
			"(.+?)=(.+)" {
				$Key,$Value = $matches[1..2]
				$Key = $Key.Trim()
				$ini.$Category.$Key = $Value.Trim()
			}
		}
		"INI file '$FileName' successfuly imported." | Write-BLLog -LogType Information
	} Else {
		"Could not find INI file '$FileName'" | Write-BLLog -LogType CriticalError
	}
	return $ini
}

Function Remove-BLIniCategory {
## Old name: SCCM:Remove-IniCategory
## Removes a complete INI category from an INI file
## (imports it into a hash table, removes category and exports the modified hash table to the original file)
Param (
	[string]$FileName = $(throw "Supply a value for the FileName parameter"),
	[string]$Category = $(throw "Supply a value for the Category parameter")
)
	trap {"Error while trying to remove the category '$Category' from INI file '$FileName'. Last Error was $Error[0]" | Write-BLLog -LogType CriticalError; return 1; continue}
	$ini = Import-BLIniFile -FileName $FileName
	If ($ini.Count) {
		If ($ini.Contains($Category)) {
			$ini.Remove($Category)
			$result = Export-BLIniFile -INIObject $ini -FileName $FileName
			If ($result -eq 0) {
				"Category '$Category' was removed from INI file '$FileName'" | Write-BLLog -LogType Information
				return 0
			} Else {
				"An error occurred when trying to remove category '$Category' from INI file '$FileName'" | Write-BLLog -LogType CriticalError
				return 1
			}
		} Else {
			"Category '$Category' does not exist in INI file '$FileName'" | Write-BLLog -LogType Warning
			return 0
		}
	} Else {
		return 0
	}
}

Function Remove-BLIniKey {
## Old name: SCCM:Remove-IniKey
## Removes a single categories key from an INI file
## (imports INI file into a hash table, removes the category's key and exports the modified hash table to the original file)
param (
	[string]$FileName = $(throw "Supply a value for the FileName parameter"),
	[string]$Category = $(throw "Supply a value for the Category parameter"),
	[string]$Key = $(throw "Supply a value for the Key parameter")
)
	trap {"Error while trying to remove the key '$Key' in category '$Category' from INI file '$FileName'. Last Error was $Error[0]" | Write-BLLog -LogType CriticalError; return 1; continue}
	$TrimmedKey = $Key.Trim()
	$ini = Import-BLIniFile -FileName $FileName
	If ($ini.Count)	{
		If ($ini.Contains($Category)) {
			If ($ini.$Category.Contains($TrimmedKey)) {
				$ini.$Category.Remove($TrimmedKey)
				$result = Export-BLIniFile -INIObject $ini -FileName $FileName
				If ($result -eq 0) {
					"Key '$TrimmedKey' was removed from INI file '$FileName', category '$Category'" | Write-BLLog -LogType Information
					return 0
				} Else {
					"An error occurred when trying to remove key '$TrimmedKey' from INI file '$FileName', category '$Category'" | Write-BLLog -LogType CriticalError
					return 1
				}
			} Else {
				"Key $TrimmedKey does not exist in INI file '$FileName', category '$Category'" | Write-BLLog -LogType Warning
				return 0
			}
		} Else {
			"Category '$Category' does not exist in '$FileName'" | Write-BLLog -LogType Warning
			return 0
		}
	}
}

Function Set-BLIniKey {
## Old name: SCCM:Set-IniKey
## Sets a specific INI file key entry to a given value
## (imports INI file into a hash table, searches for the key within the given category, creates or modifies the hash table entry and writes the result to the INI file)
Param (
	[string]$FileName = $(throw "Supply a value for the FileName parameter"),
	[string]$Category = $(throw "Supply a value for the Category parameter"),
	[string]$Key = $(throw "Supply a value for the Key parameter"),
	[string]$Value = $(throw "Supply a value for the Value parameter"),
	[switch]$Force
)
	trap {"Error while trying to set the key '$Key' in INI file '$FileName', category '$Category'. Last Error was $Error[0]" | Write-BLLog -LogType CriticalError; return 1; continue}
	$TrimmedKey = $Key.Trim()
	$ini = Import-BLIniFile -FileName $FileName
	If ($ini.Count) {
		If (!($ini.Contains($Category))) {
			If ($Force) {
				$ini.$Category = @{}
			} Else {
				"Category '$Category' does not exist in INI file '$FileName'" | Write-BLLog -LogType Warning
				return 1
			}
		}
		If ($ini.$Category.Contains($TrimmedKey)) {
			If (!$Force) {
				"Key '$TrimmedKey' already exists in INI file '$FileName', category '$Category'" | Write-BLLog -LogType Warning
				return 2
			}
		}
		$ini.$Category.$TrimmedKey = $Value
		Export-BLIniFile -INIObject $ini -FileName $FileName
	}
}

## ====================================================================================================
## Group "Remote Desktop Services and Citrix"
## ====================================================================================================

Function Get-BLRDSApplicationMode() {
## Old name: SCCM:Query-RDS-Installation
## Checks whether the current system is a terminal server
## returns 0: No Terminal Server  1: Terminal Server
	$TerminalServer = Get-ItemProperty -ErrorAction SilentlyContinue -path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
	$IsTerminalServer = $TerminalServer.TSAppCompat
	If ($IsTerminalServer -eq $null) { $IsTerminalServer = 0 }
	If ($IsTerminalServer -eq 0) {
#		"This system is not a Remote Desktop Server" | Write-BLLog -LogType Information
	} Else {
#		"This system is a Remote Desktop Server" | Write-BLLog -LogType Information
	}
	return $IsTerminalServer
}

Function Set-BLRDSInstallMode() {
## Old name: SCCM:Invoke-RDS-InstallMode
## Enables installation mode If (and only if) Terminal Services in Application Mode are enabled
	$bIsTerminalServer = Get-BLRDSApplicationMode
	If ($bIsTerminalServer) {
		"Switching terminal server to install mode" | Write-BLLog -LogType Information
		Start-BLProcess -Filename "$env:SystemRoot\system32\change.exe" -Arguments "user /install" | Out-Null
	}
}

Function Set-BLRDSExecuteMode() {
## Old name: SCCM:Invoke-RDS-ExecuteMode
## Enables excution mode If (and only if) Terminal Services in Application Mode are enabled
	$bIsTerminalServer = Get-BLRDSApplicationMode
	If ($bIsTerminalServer) {
		"Switching terminal server to execute mode" | Write-BLLog -LogType Information
		Start-BLProcess -Filename "$env:SystemRoot\system32\change.exe" -Arguments "user /execute" | Out-Null
	}
}

## ====================================================================================================
## Group "ConfigDB"
## ====================================================================================================

Function New-BLConfigDBWebClient() {
	## Information that will be sent to the web service in the header.
	## Length limit might be ~8KB for the serialized, compressed header.
	## For changes that require the web service to be changed as well, increment $ClientVersion by 1 and adjust the web service accordingly so that it remains backward compatible.
	[string]$ClientVersion = "2"
	## Information when the key was added:										Version
	$HeaderData = @{
		"ClientType" =			"BaseLibrary"									## 2
		"UserName" =			$ENV:USERNAME									## 2
		"UserDomain" =			$ENV:USERDOMAIN									## 2
		"UserDNSDomain" =		$ENV:USERDNSDOMAIN								## 2
		"ComputerName" =		$ENV:COMPUTERNAME								## 2
		"ComputerDomain" =		Get-BLComputerDomain -NetBIOS					## 2
		"ComputerDNSDomain" =	Get-BLComputerDomain							## 2
		"ComputerTime" =		Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fffffff'	## 2
		"Elevated" =			Test-BLElevation								## 2
		"Interactive" =			[Environment]::UserInteractive					## 2
	}
	$WebClient = New-Object System.Net.WebClient
	$WebClient.Headers.Add("ConfigDBT", "BaseLibrary")	# DEPRECATED, will be removed in later versions of the BaseLibrary!
	$WebClient.Headers.Add("ConfigDBU", [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ENV:USERNAME)))	# DEPRECATED, will be removed in later versions of the BaseLibrary!
	$WebClient.Headers.Add("CfgDBClient-Version", $ClientVersion)
	If ($Host.Version -ge ([Version]"3.0")) {
		$HeaderData_Serialized = [Management.Automation.PSSerializer]::Serialize($HeaderData)
	} Else {
		$TempFile = [System.IO.Path]::GetTempFileName()
		Export-CliXml -InputObject $HeaderData -Path $TempFile -Encoding UTF8 | Out-Null
		$HeaderData_Serialized = [IO.File]::ReadAllText($TempFile, [Text.Encoding]::"UTF8")
		Remove-Item -Path $TempFile -Force
	}
	$WebClient.Headers.Add("CfgDBClient-Data", (Compress-BLString -String $HeaderData_Serialized -AsBase64 -Force))
	Return $WebClient
}

Function New-BLConfigDBLocationObject() {	## Helper function: Not exported!
[CmdletBinding()]
Param(
	[string]$Path,
	[string]$Source,
	[string]$Type,
	[uint16]$Priority,
	[bool]$Active
)
	Return "" | Select-Object -Property `
		@{Name = "Path";		Expression = {$Path}},
		@{Name = "Source";		Expression = {$Source}},
		@{Name = "Type";		Expression = {$Type}},
		@{Name = "Priority";	Expression = {$Priority}},
		@{Name = "Active";		Expression = {$Active}}
}

Function Test-BLConfigDBLocation {	## Required by Get-BLConfigDBLocation, so must be defined before its caller.
[CmdletBinding()]
Param(
	[string]$Path
)
	If ([string]::IsNullOrEmpty($Path)) {Return $False}
	If ($Path.ToLower().StartsWith("http")) {
		Try {
			$WebClient = New-BLConfigDBWebClient
			$HttpQuery = $Path.TrimEnd("/") + "/Status"
			$Result = $WebClient.DownloadString($HttpQuery) -eq "OK"
		} Catch [System.Net.WebException] {
			"Did not get a response to query '$($HttpQuery)'; error information:" | Write-Warning
			If ($_.Exception.InnerException) {
				$_.Exception.InnerException.Message | Write-Warning
			} Else {
				$_.Exception.Message | Write-Warning
			}
			$Result = $False
		} Finally {
			Try {$WebClient.Dispose()} Catch {}
		}
	} Else {
		$Result = Test-Path -Path $Path
	}
	Return $Result
}

Function ConvertTo-BLConfigDBObject {	## Helper function: Not exported!
## Replaces Import-BLConfigDBFile (old name: SCCM:Read-Config-File)
## Reads a string into a hash table.
## Format of the defaults.txt file: Key<FS>Value<FS>[Comment]
## Format of the .cfg files: Key<FS>Value<FS>Type<FS>Details<FS>
## Supported types as of 11.2014: "Password"; if the variable contains a password, the last field will contain the pattern to extract the password from the string.
## <FS> = File Separator, ASCII(28)
##
## $cfg: hash table into which the configuration file is read
## $Content: the string with the .cfg file content
## $CreateFiles: wether to read embedded @FILES@: to C:\RIS\FILES
## returns 0: success  >=0 error code
[CmdletBinding()]
Param(
	[hashtable]$cfg,
	[string]$Content,
	[switch]$CreateFiles
)
	$State_VARS = 1
	$State_NONE = 2
	$State_FILE = 3
	$State = $State_VARS
	$Base64DirName = ""
	$Base64FileName = ""
	$Base64StringBuilder = New-Object -TypeName Text.StringBuilder		## Using StringBuilder is about 30x (for a 300K file) faster than "+="!
	$FS = [char]28
	$GS = [char]29
	
	$ContentArray = $Content.Split("`r`n", [StringSplitOptions]::RemoveEmptyEntries)
	$FSLine = $Null
	ForEach ($Element In $ContentArray) {
		If ($Element -match "^([^\s*#]).+?$($FS).*?$($FS).*`$") {	## Find the first not commented line that has at least two FS in it.
			$FSLine = $Element
			Break
		}
	}
	$FSCount = [regex]::Matches($FSLine, $FS).Count
	"Detected a config file with $FSCount FS separators." | Write-BLLog
	Switch ($FSCount) {
		0 {
			"No lines with at least two FS found, assuming this is an empty defaults.txt file; no further processing." | Write-Verbose
			Return 0
		}
		{@(1, 3) -Contains $_} {	## 1 shouldn't even arrive here, because we're only looking for lines with at least 2 FS; this is 'just in case'.
			"This config file has an unsupported format; don't know how to handle $($FSCount) File Separators." | Write-BLLog -LogType CriticalError
			Return 1
		}
		{@(2, 4) -Contains $_} {
			$FSCount_Effective = $FSCount
			Continue
		}
		Default {
			$FSCount_Effective = 4
			"This config file has an unexpected FS count of $($FSCount); will treat it as if it had $($FSCount_Effective) FS!" | Write-BLLog -LogType Warning
		}
	}

	## Pre-calculate some stuff for variables containing Well Known Sids; these might be required more than once:
	$WKS = @{}
	$SidComputer = (Resolve-BLSid).Sid
	$WKS["LocalAdmin"] =		(Resolve-BLSid -Name ($SidComputer + "-500")).Name
	$WKS["LocalGuest"] =		(Resolve-BLSid -Name ($SidComputer + "-501")).Name
	$WKS["LocalSystem"] =		(Resolve-BLSid -Name S-1-5-18).Name
	$WKS["LocalService"] =		(Resolve-BLSid -Name S-1-5-19).Name
	$WKS["NetworkService"] =	(Resolve-BLSid -Name S-1-5-20).Name
	$WKS["LocalAdminsGroup"] =	(Resolve-BLSid -Name S-1-5-32-544).Name
	$WKS["LocalUsersGroup"] =	(Resolve-BLSid -Name S-1-5-32-545).Name
	If ($ComputerDomain = Get-BLComputerDomain) {
		$SidComputerDomain = (Resolve-BLSid -Name $ComputerDomain).Sid							## This should work even if no DC is available.
		$objSidComputerDomainAdmin = Resolve-BLSid -Name ($SidComputerDomain + "-500") 2>&1		## Might fail if no DC is available!
		If (-not ($objSidComputerDomainAdmin -is [System.Management.Automation.ErrorRecord])) {
			$WKS["DomainAdmin"] =		$objSidComputerDomainAdmin.Name
			$WKS["DomainGuest"] =		(Resolve-BLSid -Name ($SidComputerDomain + "-501")).Name
			$WKS["DomainAdminsGroup"] =	(Resolve-BLSid -Name ($SidComputerDomain + "-512")).Name
			$WKS["DomainUsersGroup"] =	(Resolve-BLSid -Name ($SidComputerDomain + "-513")).Name
		}
	}
	## Regular Expression to find Well Known SID definitions in the values; format: [${WKSAUTHORITY}\]${WKS:...}
	$RE_WKSString = '(?:\$\{(?<WKSAuthority>WKSAUTHORITY)\}\\)?\$\{WKS:(?<WKSString>.*?)\}'

	## Build a regular expression for the number of FS actually found.
	$RE_VariableLine = "^(.+?)$($FS)" + "(.*?)$($FS)" * ($FSCount - 1) + ".*"
	"Regular expression used for parsing 'variable' lines: '$($RE_VariableLine)'" | Write-Verbose
	
	$ExitCode = 0
	$cfg["#Types"] = @{}
	$cfg["#Details"] = @{}
	$cfg["#WKS"] = @{}		# Used to store the original content of a value that contained a ${WKS:...} definition. Just in case.
	Switch -regex ($ContentArray) {
		'^@EOF@$' {
			If (-Not $CreateFiles) {
				"Matched '@EOF@' with CreateFiles=False, leaving." | Write-Verbose
				Break
			}
			If ($State -eq $State_FILE) {
				"Matched '@EOF@' while in file expand mode, generating the file." | Write-Verbose
				$Base64DirName = Split-Path $Base64FileName -Parent
				If (-Not (Test-Path -Path $Base64DirName)) {
					New-Item -Type Directory -Path $Base64DirName | Out-Null
					If (-Not $?) {
						"Could not create directory for file '$($Base64FileName)'!" | Write-BLLog -LogType CriticalError
						$ExitCode = 1
					}
				}
				Set-Content -Value ([System.Convert]::FromBase64String($Base64StringBuilder.ToString())) -Encoding Byte -Path $Base64FileName
				If (-Not $?) {
					"Could not write file '$($Base64FileName)'!" | Write-BLLog -LogType CriticalError
					$ExitCode = 1
				}
				$State = $State_NONE
				"`t  ... OK" | Write-BLLog -NoTrim
				Continue
			}
		}

		'^\s*#' {
			Continue
		}

		$RE_VariableLine {
			"Matched 'variable' line: $($Matches[0])" | Write-Verbose
			$Key = $Matches[1].Trim()		## These two are hard cast in iron.
			$Value = $Matches[2].Trim()
			$Type = ""						## Fields 3 (variable type) and 4 (variable details), defined since 11.2014
			$Details = ""
			Switch ($FSCount_Effective) {
				2 {
					Continue
				}
				4 {
					$Type = $Matches[3].Trim()
					$Details = $Matches[4].Trim()
				}
			}
			If ($Value -eq "<empty>") {
				$Value = ""
			}
			If ($CreateFiles -And ($Value -match "^@FILE@:(.*)")) {
				$Value = Join-Path $BL_CFGDB_EmbeddedFilesFolder $Matches[1]
			}
			## Additional value processing for Well Known SIDs:
			If ($Value -match $RE_WKSString) {
				$cfg["#WKS"][$Key] = $Value		## Save the original value for troubleshooting
				While ($Value -match $RE_WKSString) {
					$WellKnownSid = $Matches["WKSString"]
					$ReplaceMatch = $Matches[0]
					$RemoveAuthority = [string]::IsNullOrEmpty($Matches["WKSAuthority"])
					$Account = ""
					Switch ($WellKnownSid) {
						## Aliases for easier reading in the ConfigDB:
						{"LocalAdmin", "LocalGuest", "LocalService", "LocalSystem", "NetworkService", "LocalAdminsGroup", "LocalUsersGroup" -contains $_} {
							$Account = $WKS[$_]
						}
						{"DomainAdmin", "DomainGuest", "DomainAdminsGroup", "DomainUsersGroup" -contains $_} {
							If (-not [string]::IsNullOrEmpty($ComputerDomain)) {
								If ($objSidComputerDomainAdmin -is [System.Management.Automation.ErrorRecord]) {	## Domain member, but the Sid could not be resolved
									$ErrorMessage = $objSidComputerDomainAdmin.Exception.Message.Split(":", 2)[1].Trim(' "')
									"Variable '$($Key)': can not resolve Well Known Sid Alias '$($WellKnownSid)': $($ErrorMessage)" | Write-BLLog -LogType Warning
								} Else {
									$Account = $WKS[$_]
								}
							} Else {
								$ErrorMessage = "This computer is not a domain member."
								"Variable '$($Key)': can not replace Well Known Sid Alias '$($WellKnownSid)': $($ErrorMerssage)" | Write-BLLog -LogType Warning
							}
						}
						Default {
							$SidQuery = ""
							If ($WellKnownSid -match '\AS-1-5-21-(?<Domain>.*?)-(?<RID>\d{3})\Z') {	## Domain based SID; domain may be empty, in which case we'll use the computer's domain.
								If ([string]::IsNullOrEmpty($ComputerDomain)) {
									$ErrorMessage = "This computer is not a domain member."
									"Variable '$($Key)': can not replace domain based Well Known Sid '$($WellKnownSid)': $($ErrorMessage)" | Write-BLLog -LogType Warning
								} Else {
									If ([string]::IsNullOrEmpty($Matches["Domain"])) {
										$SidQuery = $SidComputerDomain + "-" + $Matches["RID"]
									} Else {
										$objSidDomain = Resolve-BLSid -Name $Matches["Domain"] 2>&1
										If ($objSidDomain -is [System.Management.Automation.ErrorRecord]) {
											$ErrorMessage = $objSidDomain.Exception.Message.Split(":", 2)[1].Trim(' "')
											"Variable '$($Key)': can not resolve the domain '$($Matches["Domain"])' in Well Known Sid '$($WellKnownSid)': $($ErrorMessage)" | Write-BLLog -LogType Warning
										} Else {
											$SidQuery = $objSidDomain.Sid + "-" + $Matches["RID"]
										}
									}
								}
							} Else {
								$SidQuery = $WellKnownSid
							}
							If (-not [string]::IsNullOrEmpty($SidQuery)) {
								$objSidQuery = Resolve-BLSid -Name $SidQuery 2>&1
								If ($objSidQuery -is [System.Management.Automation.ErrorRecord]) {
									$ErrorMessage = $objSidQuery.Exception.Message.Split(":", 2)[1].Trim(' "')
									"Variable '$($Key)': can not resolve Well Known Sid '$($WellKnownSid)': $($ErrorMessage)" | Write-BLLog -LogType Warning
								} Else {
									$Account = $objSidQuery.Name
								}
							}
						}
					}
					If ([string]::IsNullOrEmpty($Account)) {
						$Value = $Value.Replace($ReplaceMatch, "##NOT_RESOLVED:$($WellKnownSid), $($ErrorMessage)##")
					} Else {
						If ($RemoveAuthority) {
							If ($Account.Contains("\")) {
								$Account = $Account.Split("\")[1]
							}
							"Variable '$($Key)': replaced Well Known Sid '$($WellKnownSid)' with '$($Account)'." | Write-BLLog
						} Else {
							"Variable '$($Key)': replaced Authority and Well Known Sid '$($WellKnownSid)' with '$($Account)'." | Write-BLLog
						}
						$Value = $Value.Replace($ReplaceMatch, $Account)
					}
				}
			}	## If ($Value -match $RE_WKSString) {
			$cfg[$Key] = $Value
			$cfg["#Types"][$Key] = $Type
			$cfg["#Details"][$Key] = $Details
			Switch ($Type) {	## Additional checking
				"" {
					Continue
				}
				$BL_CFGDB_TYPE_Password {
					$DetailElements = @{}
					Split-BLConfigDBElementList -ht $DetailElements -List $Details -Delim $GS -ByOrder $False -Defaults @{
						"PatternPW" = "@error@"
						"ValnameDOM" = "@error@"
						"PatternDOM" = "@error@"
						"ValnameUser" = "@error@"
						"PatternUser" = "@error@"
					}
					If ($DetailElements.Count -gt 0) {
						ForEach ($Pattern In "PatternPW", "PatternDOM", "PatternUser") {
							If (-Not (Test-BLRegularExpression -String $DetailElements[$Pattern] -ErrorAction SilentlyContinue)) {
								"$($Key), Field 'Details': Pattern '$($DetailElements[$Pattern])' for $($Pattern) is not a valid regular expression!" | Write-BLLog -LogType CriticalError
								$ExitCode = 1
							}
						}
					} Else {
						"$($Key): Field 'Details' does not contain all required keys for type 'Password'!" | Write-BLLog -LogType CriticalError
						$ExitCode = 1
					}
				}
				Default {
					"$($Key): Field 'Type' contains a value of '$($Type)' which is not supported by this function!" | Write-BLLog -LogType Warning
				}
			}
			Continue
		}

		'^@FILE@ *(.*) *' {
			$Base64FileName = Join-Path $BL_CFGDB_EmbeddedFilesFolder $Matches[1]
			$State = $State_FILE
			$Base64StringBuilder.Clear() | Out-Null
			"`t- Extracting file: '$($Base64FileName)' ..." | Write-BLLog -NoTrim
			Continue
		}

		'(.*)' {	# innerhalb eines FILE Bereichs
			If ($State -eq $State_FILE) {
				$Base64StringBuilder.Append($Matches[1]) | Out-Null
			}
			Continue
		}
	}
	Return $ExitCode
}

Function Export-BLConfigDBConvertedTemplateFile {
Param(
	[hashtable]$lcfg,
	[string]$templateName,
	[string]$configName,
	[ValidateSet("unicode", "utf7", "utf8", "utf32", "ascii", "bigendianunicode", "default", "oem")][Alias("Encoding")]		## The alias is for historical reasons when encoding was only supported for output
	[string]$configEncoding = "Unicode",
	[string]$templateEncoding = "1252"
)
## Old name: SCCM:applyTemplate
## substitutes placeholders %%NAME%% in file by corresponding value from hastable $lcfg and create resultfile
## configEncoding:  "Unicode", "UTF7", "UTF8", "UTF32", "ASCII", "BigEndianUnicode", "Default", and "OEM". "Unicode" is the default
## templateEncoding:  "Unicode", "UTF7", "UTF8", "UTF32", "ASCII", "BigEndianUnicode", "Default", or a codepage number. ANSI CP1252 is the default
## returns 0: success  >=0 error code
	# read template
	$intCodePage = 0
	Remove-Item Variable:EncodingInput -ErrorAction SilentlyContinue
	Remove-Item Variable:EncodingOutput -ErrorAction SilentlyContinue
	If ([int32]::TryParse($templateEncoding, [ref]$intCodePage)) {
		$EncodingInput = [text.encoding]::GetEncoding($intCodePage)
	} Else {
		$EncodingInput = [text.encoding]::$templateEncoding
	}
	If (-Not $EncodingInput) {
		"Template file encoding '$($templateEncoding)' is unknown/not supported!" | Write-BLLog -LogType CriticalError
		Return 1
	}
	
	If (-Not (Test-Path -Path $templateName)) {
		"Template file '$templateName' not found!" | Write-BLLog -LogType CriticalError
		Return 1
	}
	$content = [IO.File]::ReadAllText($templateName, $EncodingInput)
	# replace vars in template
	$content = Get-BLConfigDBConvertedTemplate $lcfg $content
	#create Config file
	$content | Out-File $configName -Encoding $configEncoding
	"Template '$templateName' applied: '$configName'" | Write-BLLog -LogType Information
	return 0
}

Function Get-BLConfigDBCfgList {
<#
.SYNOPSIS
Gets a list of config files from the current location where a variable matches a filter.

.DESCRIPTION
The function Get-BLConfigDBCfgList gets a list of config files from the current location where a variable matches a filter.
The function will return an array file names without extension.
If no match is found, an empty array is returned; if an error occurred, $Null is returned.
The function supports both http and folder ConfigDB locations.

.PARAMETER Variable
Mandatory
The variable to query.

.PARAMETER Operator
Mandatory
The operator for the query:
eq     The variable content must be equal to the Value argument
ne     The variable content must NOT be equal to the Value argument
like   The variable content must match the Value argument (wildcards allowed)
nlike  The variable content must NOT match the Value argument (wildcards allowed)
match  The variable content must match the regular expression in the Value argument
nmatch The variable content must NOT match the regular expression in the Value argument

.PARAMETER Value
Mandatory
The value to match.

.INPUTS
System.String
System.String
System.String

.OUTPUTS
System.String[]

.EXAMPLE
Get-BLConfigDBCfgList "_KONFIG_FUNCTION" eq "DC"
Get all .cfg files where the variable "_KONFIG_FUNCTION" equals "DC".

.LINK
Get-BLConfigDBUAFile
Get-BLConfigDBVariables

.NOTES
None
#>
[CmdletBinding()]
Param(
	[Parameter(Position=0, ValueFromPipelineByPropertyName=$True)]
	[string]$Variable = "DUMMY_QUERY_ALL",
	[Parameter(Position=1, ValueFromPipelineByPropertyName=$True)]
	[ValidateSet("eq", "ne", "like", "nlike", "match", "nmatch")]
	[string]$Operator = "eq",
	[Parameter(Position=2, ValueFromPipelineByPropertyName=$True)]
	[string]$Value = ""
)
	$FS = [char]28
	$AllLocations = Get-BLConfigDBLocation
	$Location = $AllLocations | Where {$_.Active}
	If (-Not $Location) {
		"Could not determine an active ConfigDB download location; current locations:" | Write-BLLog -LogType CriticalError
		$AllLocations | Format-Table -AutoSize | Out-String | Write-BLLog -LogType CriticalError
		Return 1
	}
	$CFG_Location = $Location.Path
	"Retrieving config list for '$($Variable) $($Operator) `"$($Value)`"' from '$($CFG_Location)' ..." | Write-BLLog -LogType Information
	If ($CFG_Location.ToLower().StartsWith("http")) {
		$HttpQuery = "?var=" +
					[System.Web.HttpUtility]::UrlEncode($Variable) +
					"&op=" +
					[System.Web.HttpUtility]::UrlEncode($Operator) +
					"&value=" +
					[System.Web.HttpUtility]::UrlEncode($Value)
		$URL = $CFG_Location + $BL_CFGDB_VirtualFolderCfg + $HttpQuery
		Try {
			$WebClient = New-BLConfigDBWebClient
			"Sending query '$($URL)' at " + (Get-Date).ToLongTimeString() | Write-BLLog -LogType Information
			$CFG_List = $WebClient.DownloadString($URL)
			"Response complete at " + (Get-Date).ToLongTimeString() | Write-BLLog -LogType Information
            Return ,$CFG_List.Split("`r`n", [StringSplitOptions]::RemoveEmptyEntries)
		} Catch [System.Net.WebException] {
			"Could not query for the file list; error information:"  | Write-BLLog -LogType CriticalError
			If ($_.Exception.InnerException) {
				$_.Exception.InnerException.Message | Write-BLLog -LogType CriticalError
			} Else {
				$_.Exception.Message | Write-BLLog -LogType CriticalError
			}
			Return $Null
		}
	} Else {
		If (Test-Path -Path $CFG_Location) {
			"Using file path '$($CFG_Location)' instead of the ConfigDB http service; this should only be done during tests or setup!" | Write-BLLog -LogType Warning
		} Else {
			"File path '$($CFG_Location)' not found!" | Write-BLLog -LogType CriticalError
			Return $Null
		}
		$CFG_List = @()
		ForEach ($File In (Get-ChildItem -Path $CFG_Location -Filter "*.cfg")) {
			$StreamReader = New-Object -TypeName System.IO.StreamReader -ArgumentList $File.FullName, ([Text.Encoding]::GetEncoding(1252))
			$VariableMatch = $Variable.ToUpper() + $FS
			$Result = $Null
			While (($Line = $StreamReader.ReadLine()) -ne $Null) {
				If ($Line -eq "@EOF@") {Break}
				If ($Line.ToUpper().StartsWith($VariableMatch)) {
					$Result = $Line.Split($FS)
					Break
				}
			}
			$StreamReader.Close()
			If ($Result) {
				$Found = $False
				Switch ($Operator.ToLower()) {
					"eq"		{$Found = $Result[1] -eq $Value; Break}
					"ne"		{$Found = $Result[1] -ne $Value; Break}
					"like"		{$Found = $Result[1] -like $Value; Break}
					"nlike"		{$Found = $Result[1] -like $Value; Break}
					"match"		{$Found = $Result[1] -match $Value; Break}
					"nmatch"	{$Found = $Result[1] -match $Value; Break}
				}
				If ($Found) {
					$CFG_List += $File.BaseName
				}
			}
		}
		Return ,$CFG_List
    }
}

Function Get-BLConfigDBConvertedTemplate([hashtable]$cfg, [string]$template) {
## Old name: SCCM:substInTemplate
## substitutes placeholders %%NAME%% in string by corresponding value from hastable $cfg
## returns 0: success  >=0 error code
    $cfg.GetEnumerator() | ForEach-Object { $template = $template.Replace("%%" + $_.Key + "%%", $_.Value) }
    return [string]$template
}

Function Get-BLConfigDBLocation {
<#
.SYNOPSIS
Gets the active ConfigDB location.

.DESCRIPTION
The function Get-BLConfigDBLocation gets the active ConfigDB location.
The function will return an array of custom objects.
One of the objects should have the property "Active" as "$True"; if "Active" is $False for all locations, then there (currently) is no valid ConfigDB location.

.PARAMETER NoCache
Optional
Get-BLConfigDBLocation tests whether a potential ConfigDB location exists. 
If (in a failover scenario with several http services) one or more services are not available, this test can take some time, so onve an active location is found, it will be cached for 10 minutes and used in subsequent calls of Get-BLConfigDBLocation.
With -NoCache, the cache will not be used.

.INPUTS
System.Management.Automation.SwitchParameter

.OUTPUTS
System.Object[]

.EXAMPLE
Get-BLConfigDBLocation -Verbose | Format-Table -Autosize
Gets the current ConfigDB locations; the output will look like this:
------------------------------------------------------------------------------------------
VERBOSE: Testing 'http://localhost:50080/' ...
VERBOSE: ... OK, location found.

Path                            Source              Type    Priority Active
----                            ------              ----    -------- ------
                                ATOS_CFGDB_SETUP    Setup          0  False
http://localhost:50080/         ATOS_CFGDB_LOCATION Manual         1   True
http://server.domain.svc:50080/ DNS                 Default        2  False
------------------------------------------------------------------------------------------
Another call within 10 minutes will show that the active location now came from the cache.

.LINK
Set-BLConfigDBLocation

.NOTES
None
#>
[CmdletBinding()]
Param(
	[switch]$NoCache
)
## Returns the current ConfigDB location configuration; .Path may be empty for all locations.
	$Result = @()
	$Priority = 0
	## ==== Step 1: collect all possible paths ==========
	## Setup; highest priority
	$LocationTypeActive = $Null
	$LocationList = [Environment]::GetEnvironmentVariable($BL_CFGDB_ENV_Setup, "Machine")	## Location during initial setup, that is, in TS Installer. This variable MUST be deleted by the setup routine once setup is complete.
	If ([string]::IsNullOrEmpty($LocationList)) {
		$Result += New-BLConfigDBLocationObject -Path "" -Source $BL_CFGDB_ENV_Setup -Type "Setup" -Priority ($Priority++) -Active $False
	} Else {
		$LocationTypeActive = "Setup"
		ForEach ($Location In $LocationList.Split(";", [StringSplitOptions]::RemoveEmptyEntries)) {
			$Location = $Location.Trim()
			If ($Location.ToLower().StartsWith("http")) {$Location = $Location.TrimEnd("/") + "/"} Else {$Location = $Location.TrimEnd("\") + "\"}
			$Result += New-BLConfigDBLocationObject -Path $Location -Source $BL_CFGDB_ENV_Setup -Type "Setup" -Priority ($Priority++) -Active $False
		}
	}
	## Manual; priority over default
	$LocationList = [Environment]::GetEnvironmentVariable($BL_CFGDB_ENV_Location, "Machine")		## Location mainly for test/development; may be file path or http.
	If ([string]::IsNullOrEmpty($LocationList)) {
		$Result += New-BLConfigDBLocationObject -Path "" -Source $BL_CFGDB_ENV_Location -Type "Manual" -Priority ($Priority++) -Active $False
	} Else {
		If (-Not $LocationTypeActive) {$LocationTypeActive = "Manual"}
		ForEach ($Location In $LocationList.Split(";", [StringSplitOptions]::RemoveEmptyEntries)) {
			$Location = $Location.Trim()
			If ($Location.ToLower().StartsWith("http")) {$Location = $Location.TrimEnd("/") + "/"} Else {$Location = $Location.TrimEnd("\") + "\"}
			$Result += New-BLConfigDBLocationObject -Path $Location -Source $BL_CFGDB_ENV_Location -Type "Manual" -Priority ($Priority++) -Active $False
		}
	}
	## Default; use the DNS _cfgdb SRV entry
	If (-Not $LocationTypeActive) {$LocationTypeActive = "Default"}
	$SrvEntries = Get-BLDnsSrvRecord -Name "$($BL_CFGDB_ServiceName)._tcp" -WarningAction SilentlyContinue
	If (-Not $SrvEntries) {
		"No SRV entries '$($BL_CFGDB_ServiceName)._tcp' found in DNS." | Write-Verbose
		$Result += New-BLConfigDBLocationObject -Path "" -Source "DNS" -Type "Default" -Priority ($Priority++) -Active $False
	} Else {
		ForEach ($SrvEntry In $SrvEntries) {	## The entries are already sorted by priority
			Switch ($SrvEntry.Port) {
				445 {	## SMB/CIFS
					$Location = "\\" + $SrvEntry.Name + "\$($BL_CFGDB_ServiceName)\"
				}
				Default {
					$Location = "http://" + $SrvEntry.Name + ":" + $SrvEntry.Port + "/"
				}
			}
			$Result += New-BLConfigDBLocationObject -Path $Location -Source "DNS" -Type "Default" -Priority ($Priority++) -Active $False
		}
	}
	
	## ==== Step 2: check which path to use (including failover) ==========
	If ($NoCache -Or [string]::IsNullOrEmpty($Script:BL_CFGDB_LocationCache.Location) -Or ((Get-Date) -ge $Script:BL_CFGDB_LocationCache.Expires)) {
		$Script:BL_CFGDB_LocationCache.Location = ""
		$Script:BL_CFGDB_LocationCache.Expires = Get-Date
		ForEach ($LocationObject In ($Result | Where {($_.Type -eq $LocationTypeActive) -And ($_.Path -ne "")})) {
			"Testing '$($LocationObject.Path)' ..." | Write-Verbose
			If (Test-BLConfigDBLocation -Path $LocationObject.Path) {
				$LocationObject.Active = $True
				"... OK, location found." | Write-Verbose
				$Script:BL_CFGDB_LocationCache.Location = $LocationObject.Path
				$Script:BL_CFGDB_LocationCache.Expires = (Get-Date).AddMinutes(10)
				Break
			} Else {
				"... not found." | Write-Verbose
			}
		}
	} Else {
		"ConfigDB location answered from cache: $($Script:BL_CFGDB_LocationCache.Location)." | Write-Verbose
		($Result | Where {($_.Type -eq $LocationTypeActive) -And ($_.Path -eq $Script:BL_CFGDB_LocationCache.Location)}).Active = $True
	}
	Return $Result
}

Function Get-BLConfigDBUAFile {
<#
.SYNOPSIS
Gets a string with the Unattend.xml for the computer.

.DESCRIPTION
The function Get-BLConfigDBUAFile gets a string with the Unattend.xml for the computer.
The function will return an array file names without extension.
Returns $Null if an error occurred.
The function supports both http and folder ConfigDB locations.

.PARAMETER ComputerName
Optional
The name of the computer for which to get the Unattend.xml.

.INPUTS
System.String

.OUTPUTS
System.String

.EXAMPLE
Get-BLConfigDBUAFile
Gets the Unattend.xml content for the current computer.

.LINK
Get-BLConfigDBCfgList
Get-BLConfigDBVariables

.NOTES
None
#>
[CmdletBinding()]
Param(
	[string]$ComputerName = $ENV:ComputerName
)

	$FS = [char]28
	$AllLocations = Get-BLConfigDBLocation
	$Location = $AllLocations | Where {$_.Active}
	If (-Not $Location) {
		"Could not determine an active ConfigDB download location; current locations:" | Write-BLLog -LogType CriticalError
		$AllLocations | Format-Table -AutoSize | Out-String | Write-BLLog -LogType CriticalError
		Return 1
	}
	$CFG_Location = $Location.Path
	$UA_Content = $Null	
	"Retrieving Unattend.xml for '$($ComputerName) ..." | Write-BLLog -LogType Information
	If ($CFG_Location.ToLower().StartsWith("http")) {
		$HttpQuery = [System.Web.HttpUtility]::UrlEncode($ComputerName)
		$URL = $CFG_Location + $BL_CFGDB_VirtualFolderUA + $HttpQuery
		Try {
			$WebClient = New-BLConfigDBWebClient
			"Starting download of '$($URL)' at " + (Get-Date).ToLongTimeString() | Write-BLLog -LogType Information
			$UA_Content = $WebClient.DownloadString($URL)
			"Download complete at " + (Get-Date).ToLongTimeString() | Write-BLLog -LogType Information
		} Catch [System.Net.WebException] {
			"Could not query for the Unattend file; error information:"  | Write-BLLog -LogType CriticalError
			If ($_.Exception.InnerException) {
				$_.Exception.InnerException.Message | Write-BLLog -LogType CriticalError
			} Else {
				$_.Exception.Message | Write-BLLog -LogType CriticalError
			}
		}
	} Else {
		$CFG_ConfigFile = $ComputerName + ".cfg"
		$LocalPathCfg = Join-Path $CFG_Location $CFG_ConfigFile
		If (Test-Path -Path $LocalPathCfg) {
			"Using file path '$($LocalPathCfg)' instead of the ConfigDB http service; this should only be done during tests or setup!" | Write-BLLog -LogType Warning
			$LocalPathUA = [System.IO.Path]::GetTempFileName()
			[System.IO.File]::Delete($LocalPathUA)
			& cscript.exe /nologo C:\RIS\LIB\Cfg2UAxml.wsf /CFG:$LocalPathCfg /OUT:$LocalPathUA /TEMPLATE:C:\RIS\LIB\AutoUnattend.template | Write-BLLog -CustomCol "Cfg2UAxml.wsf"
			If ($LASTEXITCODE -ne 0) {
				"Could not generate the unattend file!" | Write-BLLog -LogType CriticalError
			} Else {
				$UA_Content = [IO.File]::ReadAllText($LocalPathUA, [Text.Encoding]::GetEncoding(1252))	
			}
			Try {[System.IO.File]::Delete($LocalPathUA)} Catch {}
		} Else {
			"File path '$($LocalPathCfg)' not found!" | Write-BLLog -LogType CriticalError
		}
	}
	Return $UA_Content
}

Function Get-BLConfigDBVariables {
<#
.SYNOPSIS
Fills the hash table passed with the variables from the ConfigDB file for a given computer.
For help on support for Well Known Sids in the ConfigDB, see the help for 'ConvertTo-BLConfigDBObject'!

.DESCRIPTION
The function Get-BLConfigDBVariables fills the hash table passed with the variables from the ConfigDB file for a given computer.
Format of the defaults.txt file: Key<FS>Value<FS>[Comment]
Format of the .cfg files: Key<FS>Value<FS>Type<FS>Details<FS>
  Supported types as of 12.2015:
  - "Password": the variable contains a password; the Details field will contain the regular expression to extract the password from the string.
<FS> = File Separator, ASCII(28)

The ConfigDB file location will be determined in the following order:
1. Environment variable "ATOS_CFGDB_SETUP"
   Use of this variable is strictly reserved for scripts manipulating or installing the http service!
2. Environment variable "ATOS_CFGDB_LOCATION"
   Manual definition of a location
3. DNS SRV entry "_cfgdb"
You can use Set-BLConfigDBLocation to define a manual path or revert to the default DNS location.
If a file with default settings is passed with the -Defaults argument, the settings from this file are loaded first into the hash table, then the config settings from the ConfigDB will be applied (so a setting defined in the ConfigDB will override a setting in the defaults.txt).
Additionally, the table will then be checked for undefined mandatory settings (set to "@error@" in the defaults file).
The Defaults file is by convention "defaults.txt" in the script's folder.
When a Defaults file is used, it's the package developer's task to make sure that all required variables are set to either useful values (if they MAY come from the ConfigDB) or "@error@" (if they HAVE to come from the ConfigDB).
returns 0: success
>=0: error code
The function supports both http and folder ConfigDB locations.
Note that for folder locations, passwords will NOT be merged dynamically into the variables!

The variables defined in the ConfigDB may contain a certain pattern to allow the use of some special account names that are based on 'Well-Known Sids'.
The names of these accounts may differ depending on the OS's language or security policies (like a renamed default administrator).
These accounts can be addressed using a string of the form '${WKS:<Well-known Sid>}' or '${WKSAUTHORITY}\${WKS:<Well-known Sid>}', which will be replaced with the name resolved from the SID.
<Well-known Sid> can be an alias or an actual SID:
  * LocalSystem             - Alias for 'S-1-5-18'; returns the name of the local computer's 'System' account (authority)
  * LocalService            - Alias for 'S-1-5-19'; returns the name of the local computer's 'Local Service' account
  * NetworkService          - Alias for 'S-1-5-20'; returns the name of the local computer's 'Network Service' account
  * LocalAdmin              - Alias for 'S-1-5-21-...-500'; returns the name of the local computer's Administrator account
  * LocalGuest              - Alias for 'S-1-5-21-...-501'; returns the name of the local computer's Guest account
  * LocalAdminsGroup        - Alias for 'S-1-5-32-544'; returns the name of the local computer Administrators group
  * LocalUsersGroup         - Alias for 'S-1-5-32-545'; returns the name of the local computer Users group
  * DomainAdmin             - Alias for 'S-1-5-21-...-500'; returns the name of the computer's Domain Administrator account
  * DomainGuest             - Alias for 'S-1-5-21-...-501'; returns the name of the computer's Domain Guest account
  * DomainAdminsGroup       - Alias for 'S-1-5-21-...-512'; returns the name of the computer's Domain Administrators group
  * DomainUsersGroup        - Alias for 'S-1-5-21-...-513'; returns the name of the computer's Domain Users group
  * S-1-5-21-<Domain>-<RID> - returns the name for the domain based RID; <Domain> can be the domain's FQDN or NetBIOS name. 
                              If <Domain> is empty, the computer's domain will be used.
  * <Well Known Sid>        - returns the name of the well known sid as returned by the API
If the WKS definition is prefixed by '${WKSAUTHORITY}\', the authority as returned by the API will be placed in front of the name.
This can be the NetBIOS(!) domain name in case of a domain based SID or BUILTIN/VORDEFINIERT, NT AUTHORITY/NT-Autorität, ...
Notes:
* You can use the function 'Show-BLWellKnownSidsInformation' to get a list of WKS and their names.
* You can use the function 'Resolve-BLSid' to resolve Sids to names and vice versa (actual names might differ depending on the OS language).
* For troubleshooting, the $cfg hash table will have a key "#WKS" with a hash table containing the key/variable pairs with the original values.
* THE FUNCTION WILL NOT REPORT AN ERROR IF A SID DEFINED LIKE THAT CAN'T BE RESOLVED, it will only write a warning!
  The ConfigDB is read at different times during an installation (for example before and after a domain join), so it is not necessarily an error if a SID can't be resolved.
  In a case like that, the WKS part will be replaced with the original pattern and the error message, see the last example.
Examples:
WKS_Test_01<FS>CCIS-P01S01-PF\${WKS:DomainAdmin}<FS>
  --> Will result in 'CCIS-P01S01-PF\Administrator' before the hardening, 'CCIS-P01S01-PF\ASA_Administrator' after the hardening
WKS_Test_02<FS>${WKS:LocalAdmin}<FS>
  --> Will result in 'Administrator' (local) before the hardening, 'ASA_Administrator' after the hardening
WKS_Test_03<FS>${WKS:S-1-5-32-544}<FS>
  --> Will result in 'Administrators' on English systems, 'Administratoren' on German systems.
WKS_Test_04<FS>${WKSAUTHORITY}\${WKS:S-1-5-32-545}<FS>
  --> Will result in 'BUILTIN\Users' on English systems, 'VORDEFINIERT\Benutzer' on German systems.
WKS_Test_05<FS>${WKS:S-1-5-21--500}<FS>
  --> No domain, so the computer's DOMAIN will be used; results are same as when using the DomainAdmin alias: 'Administrator'/'ASA_Administrator'
WKS_Test_06<FS>${WKS:S-1-5-21-CCIS-P01S01-CM-500}<FS>
  --> Will result in '[ASA_]Administrator in the CM domain; can be used from PF once the trust exists.
WKS_Test_07<FS>${WKSAUTHORITY}\${WKS:S-1-5-21-cm.p01s01.ccis.svc.intranetbw.de-500}<FS>
  --> Will result in 'CCIS-P01S01-CM\[ASA_]Administrator in the CM domain.
WKS_Test_08<FS>${WKSAUTHORITY}\${WKS:LocalSystem}<FS>
  --> Will result in 'NT AUTHORITY\SYSTEM' on English systems, 'NT-AUTORITÄT\SYSTEM' on German systems.
WKS_Test_09<FS>${WKS:NetworkService}<FS>
  --> Will result in 'NETWORK SERVICE' on English systems, 'NETZWERKDIENST' on German systems.
WKS_Test_10<FS>${WKS:1-2-3-4-5}<FS>
  --> Will result in an error, logged as warning from [ConvertTo-BLConfigDBObject].
      The variable's value will be: ##NOT_RESOLVED:S-1-2-3-4-5, 1332: No mapping between account names and security IDs was done##

.PARAMETER cfg
Mandatory
Hash table to be filled; must exist before calling this function (see example).

.PARAMETER ComputerName
Optional
Name of the computer for which to retrieve the ConfigDB file; default: name of the computer.

.PARAMETER Defaults
Optional
Path and name to the Defaults settings file.

.PARAMETER DefaultsOnly
Optional
Reading the computer's .cfg file will be skipped, only the defaults.txt will be used.

.PARAMETER CreateFiles
Optional
If $True, will expand files embedded into the .cfg file (using @FILE@: entries) to C:\RIS\FILES\...

.PARAMETER Path
Optional
Path to the ConfigDB location (http or local); overrides the normal location.
ONLY TO BE USED FOR TESTS OR WHEN DEALING WITH SCRIPTS THAT MANIPULATE THE CONFIGDB LOCATION OR THE WEB SERVICE! 

.INPUTS
System.Collections.Hashtable
System.String
System.String

.OUTPUTS
System.Int32

.EXAMPLE
_
$cfg = @{}
$ExitCode = Get-BLConfigDBVariables $cfg -Defaults "$AppSource\Defaults.txt"
If ($ExitCode -ne 0) {
	"Error setting variables from ConfigDB, unable to continue!" | Write-BLLog -LogType Information
	Exit-BLFunctions -SetExitCode 1
}

.LINK
ConvertTo-BLConfigDBObject
Get-BLConfigDBLocation
Set-BLConfigDBLocation
Write-BLConfigDBSettings

.NOTES
None
#>
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$False, Position=0)]
	[HashTable]$cfg, 
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, Position=1)]
	[string]$ComputerName = "",
	[Parameter(Mandatory=$False)]
	[string]$Defaults = "",
	[Parameter(Mandatory=$False)]
	[switch]$DefaultsOnly,
	[Parameter(Mandatory=$False)]
	[switch]$CreateFiles = $False,
	[Parameter(Mandatory=$False)]
	[string]$Path
)
	If (-Not ($cfg -is [HashTable])) {
		"Required variable 'cfg' not defined as hashtable." | Write-BLLog -LogType CriticalError
		Return 1
	}
	If ($DefaultsOnly -And ([string]::IsNullOrEmpty($Defaults) -Or (-Not (Test-Path -Path $Defaults)))) {
		"Switch 'DefaultsOnly' was specified, but the defaults file '$($Defaults)' is missing." | Write-BLLog -LogType CriticalError
		Return 1
	}
	$ExitCode = 0
	
	If (-Not [string]::IsNullOrEmpty($Defaults)) {
		"Reading default settings from '$($Defaults)' ..." | Write-BLLog
		If (-Not (Test-Path $Defaults)) {
			"Could not find default config file '$($ConfigFileDefault)'!" | Write-BLLog -LogType CriticalError
			Return 1
		} Else {
			## Can't use Get-Content; we need the raw file (not broken down into an array of lines), and -Raw is only available since PS 3.0
			## The .cfg files are exported as Windows-1252
			$ExitCode = ConvertTo-BLConfigDBObject -cfg $cfg -Content ([IO.File]::ReadAllText($Defaults, [Text.Encoding]::GetEncoding(1252)))
			If ($ExitCode -ne 0) {
				Return $ExitCode
			}
		}
	}
	If ($DefaultsOnly) {
		"Reading the computer's config file is disabled by the switch 'DefaultsOnly'; the config will not be tested for @error@ values!" | Write-BLLog -LogType Warning
		"... OK." | Write-BLLog -LogType Information
		Return 0
	}
	
	If ([string]::IsNullOrEmpty($ComputerName)) {
		$ComputerName = $ENV:ComputerName
	}
	If ([string]::IsNullOrEmpty($Path)) {
		$AllLocations = Get-BLConfigDBLocation
		$Location = $AllLocations | Where {$_.Active}
		If (-Not $Location) {
			"Could not determine an active ConfigDB download location; current locations:" | Write-BLLog -LogType CriticalError
			$AllLocations | Format-Table -AutoSize | Out-String | Write-BLLog -LogType CriticalError
			Return 1
		}
		"ConfigDB download location determined by $($Location.Source): '$($Location.Path)'." | Write-BLLog
		$CFG_Location = $Location.Path
	} Else {
		"ConfigDB download location overridden by command line argument: '$($Path)'." | Write-BLLog -LogType Warning
		$CFG_Location = $Path
	}
	
	"Retrieving config file for $($ComputerName) ..." | Write-BLLog -LogType Information
	$CFG_Content = $Null
	If ($CFG_Location.ToLower().StartsWith("http")) {
		$HttpQuery = [System.Web.HttpUtility]::UrlEncode($ComputerName)
		$URL = $CFG_Location + $BL_CFGDB_VirtualFolderCfg + $HttpQuery
		Try {
			$WebClient = New-BLConfigDBWebClient
			"Starting download of '$($URL)' at " + (Get-Date).ToLongTimeString() | Write-BLLog -LogType Information
			$CFG_Content = $WebClient.DownloadString($URL)
			"Download complete at " + (Get-Date).ToLongTimeString() | Write-BLLog -LogType Information
		} Catch [System.Net.WebException] {
			"Could not download config file; error information:"  | Write-BLLog -LogType CriticalError
			If ($_.Exception.InnerException) {
				$_.Exception.InnerException.Message | Write-BLLog -LogType CriticalError
			} Else {
				$_.Exception.Message | Write-BLLog -LogType CriticalError
			}
		} Finally {
			Try {$WebClient.Dispose()} Catch {}
		}
	} Else {
		$CFG_ConfigFile = $ComputerName + ".cfg"
		$LocalPath = Join-Path $CFG_Location $CFG_ConfigFile
		If (Test-Path -Path $LocalPath) {
			"Using file path '$($LocalPath)' instead of the ConfigDB http service; this should only be done during tests or setup!" | Write-BLLog -LogType Warning
			$CFG_Content = [IO.File]::ReadAllText($LocalPath, [Text.Encoding]::GetEncoding(1252))
		} Else {
			"File path '$($LocalPath)' not found!" | Write-BLLog -LogType CriticalError
		}
	}
	If ([string]::IsNullOrEmpty($CFG_Content)) {
		Return 1
	}
	"Reading variables for $($ComputerName) ..." | Write-BLLog -LogType Information
	$ExitCode = ConvertTo-BLConfigDBObject -cfg $cfg -Content $CFG_Content -CreateFiles:$CreateFiles
	If ($ExitCode -eq 0) {
		"... OK." | Write-BLLog -LogType Information
		If (-Not [string]::IsNullOrEmpty($cfg['_@INFO@'])) {
			"File information: $($cfg['_@INFO@'])" | Write-BLLog -LogType Information
		}
		If (-Not [string]::IsNullOrEmpty($Defaults)) {	# The config file has been read, and a default settings file has been specified; verify the configuration:
			"Verifying that all mandatory variables have been set ..." | Write-BLLog -NoTrim -LogType Information
			$cfg.GetEnumerator() | ForEach-Object {
				If ($_.Value -eq "@error@") {
					"Missing configuration value: '$($_.Key)'" | Write-BLLog -LogType CriticalError
					$ExitCode = 1
				}
			}
			If ($ExitCode -eq 0) {
				"... OK." | Write-BLLog -NoTrim -LogType Information
			}
		}
	}
	Return $ExitCode
}

Function Get-BLConfigDBIndexedVariables([hashtable]$cfg, [string]$Prefix = "", [string]$Postfix = "") {
## Returns an array (not a hash table) consisting of a range of indexed variables from the ConfigDB.
##### WORK IN PROGRESS
	$ret = @()
	ForEach ($Key In ($h.Keys | Where {($_.StartsWith("PRE")) -And ($_.EndsWith("POST"))})) {
	}
	For ($i = 0; $i -lt 100; $i++) {
		If ($i -lt 10) {
			[String]$Index = "0" + ([string]$i)
		} Else {
			[String]$Index = ([string]$i)
		}
		$Key = $cfgPrefix + $Index + $cfgPostfix
		If (($cfg.ContainsKey($Key) -eq $True) -And ($cfg[$Key] -ne "")) {
			$ret += [string]$cfg[$Key]
		}
	}
	Return ,$ret
}

Function Set-BLConfigDBLocation {
<#
.SYNOPSIS
Sets the path (http or folder) to the ConfigDB location.

.DESCRIPTION
The function Set-BLConfigDBLocation sets the path (http or folder) to the ConfigDB location.
Note that a folder should only be used for tests and development, since only the web service will deliver the .cfg file with the current passwords.
The function will return an array of custom objects on success, $Null on error.
The path property of the object returned will always have a trailing slash or backslash.
Note that the "Active" location returned by this function not necessarily the same as the one you just set!
If the location is currently "Setup", a Set-BLConfigDBLocation to Type "Default" or "Manual" will NOT disable the "Setup" location.
This is by design - the instance that invoked "Setup" mode will clear it again when appropriate!

.PARAMETER Type
Optional
The type of the ConfigDB location to set:
    Default (use DNS SRV)
    Manual (use the location specified in the path)
	Setup (RESERVED for special occasions like TSInstaller! To deactivate Setup, call Set-BLConfigDBLocation with Type "Setup" and an empty path.)

.PARAMETER Path
Mandatory if Type is Manual or Setup.
The path or an array of paths to the location(s); the locations will be tested in the order in which they are passed, and the first one to respond will be used.
Note that for an http location, the virtual folder "ConfigDB" must NOT be specified.
For a folder location (UNC or local), the full path to the folder with the ".cfg" and "-ua.xml" files needs to be specified.
A trailing slash or backslash will be added automatically if it's missing.

.INPUTS
System.String
System.String

.OUTPUTS
System.Object[]

.EXAMPLE
$Locations = Set-BLConfigDBLocation -Type Default
The ConfigDB location will be found by querying DNS for the SRV entry _cfgdb.

.EXAMPLE
$Locations = Set-BLConfigDBLocation -Type Manual -Path http://server.domain.svc:50080/
The ConfigDB location will be set to http://server.domain.svc:50080/

.EXAMPLE
$Locations = Set-BLConfigDBLocation -Type Manual -Path http://server1.domain.svc:50080/, http://server2.domain.svc:50080/
The ConfigDB locations will be set to http://server1.domain.svc:50080/ and http://server2.domain.svc:50080/

.EXAMPLE
$Locations = Set-BLConfigDBLocation -Type Manual -Path C:\RIS\ConfigDB
Uses the local path "C:\RIS\ConfigDB" as location for the ConfigDB files.
This can be used for script development when a ConfigDB http server isn't available.

.LINK
Get-BLConfigDBLocation

.NOTES
None
#>
[CmdletBinding()]
Param(
	[Parameter(Position=0, ValueFromPipelineByPropertyName=$True)]
	[ValidateSet("Default", "Manual", "Setup")]
	[string]$Type = "Default",
	[Parameter(Position=1, ValueFromPipelineByPropertyName=$True)]
	[string[]]$Path
)
	Process {
		$Path = $Path -join ";"
		If (-Not [string]::IsNullOrEmpty($Path)) {
			If ($Path.ToLower().StartsWith("http")) {$PathDelimiter = "/"} Else {$PathDelimiter = "\"}
			$Path = $Path.TrimEnd($PathDelimiter) + $PathDelimiter
		}
		Try {
			Switch ($Type) {
				"Setup" {
					If ([string]::IsNullOrEmpty($Path)) {
						[Environment]::SetEnvironmentVariable($BL_CFGDB_ENV_Setup, $Null, "Machine")
						"ConfigDB download location type '$($Type)' removed." | Write-BLLog
					} Else {
						[Environment]::SetEnvironmentVariable($BL_CFGDB_ENV_Setup, $Path, "Machine")
						"ConfigDB download location set to type '$($Type)': '$($Path)'." | Write-BLLog
					}
				}
				"Manual" {
					If ([string]::IsNullOrEmpty($Path)) {Throw "Required Argument 'Path' is empty."}
					[Environment]::SetEnvironmentVariable($BL_CFGDB_ENV_Location, $Path, "Machine")
					"ConfigDB download location set to type '$($Type)': '$($Path)'." | Write-BLLog
				}
				"Default" {
					[Environment]::SetEnvironmentVariable($BL_CFGDB_ENV_Location, $Null, "Machine")
					"ConfigDB download location set to type '$($Type)': DNS SRV entry '$($BL_CFGDB_ServiceName)'." | Write-BLLog
				}
			}
			Get-BLConfigDBLocation -NoCache | Write-Output
		} Catch {
			$_ | Out-String | Write-BLLog -LogType CriticalError
		}
	}
}

Function Split-BLConfigDBAccountVariable($Account, [ref]$User, [ref]$Password) {
## Old name: SCCM:Split-Config-Account
## Splits an acocunt entry from ConfigDB in the format "[Realm\]Username;Password"
## into two single variables passed by reference.
## Neither username nor password may be empty.
## The password may contain spaces as well as a semicolon.
## Both objects passed as By Reference variables must exist before calling this function.
## Example for a Function call:
## $SomeUser = ""
## $SomePass = ""
## Split-BLConfigDBAccountVariable $cfg["SQL_DB_ACCOUNT"] ([ref]$SomeUser) ([ref]$SomePass))
## Returns $True if successful, $False otherwise.
#	"Entering " + $MyInvocation.MyCommand + " at " + (Get-Date).ToLongTimeString() | Write-BLLog -LogType Information
	$a = $Account.Split(";", 2)		# Get only the first two tokens; password might contain semicolons! 
	If ($a[1] -eq $Null) {			# Both user and password must be set; if one is missing, return with an error
		$ret = $False
	} Else {
		$User.Value = $a[0].Trim()		# Strip whitespaces from the beginning and end
		$Password.Value = $a[1].Trim()	# Strip whitespaces from the beginning and end
		If (($User.Value.Length -eq 0) -Or ($Password.Value.Length -eq 0)) {
			$ret = $False
		} Else {
			$ret = $True
		}
	}
#	"Leaving " + $MyInvocation.MyCommand + " with return value $ret at " + (Get-Date).ToLongTimeString() | Write-BLLog -LogType Information
	Return $ret
}

Function Split-BLConfigDBElementList([HashTable]$ht, [String]$List, [String]$Delim = ";", [Bool]$ByOrder = $True, [hashtable]$Defaults = @{}, [switch]$Quiet) {
## Old name: SCCM:Split-Config-ElementList
## Fills the hash table passed as first argument with the elements of a delimited list.
## If the delimiter is part of a column, this column MUST be enclosed in double quotes:
##	Example 1: 'Name=admINST;Password="Top;Secret";PwdExpires=0;"Description=Atos; default installation Administrator"'
##	Example 2: 'a;b;"c;c;c";"d"'
## The quotes will be trimmed of the returned strings.
## Depending on the $ByOrder var, the keys of the hash table will be either numeric(!) (matching the zero-based position
## of the element) or a string if the elements are expected in the format "Key1 = Value1; Key2 = Value 2; ..."
## Leading and trailing whitespaces will be trimmed from keys and values.
## If $ByOrder is $False, $Defaults can be used to pass keys and values that are optional in the list; if a value for a key is set to @error@ in $Defaults,
## and there's no corresponding key in the list, the function will log an error (unless -quiet is specified) and return an empty hash table.
#	"Entering " + $MyInvocation.MyCommand + " at " + (Get-Date).ToLongTimeString() | Write-BLLog -LogType Information
	If ([regex]::Matches($List, '"').Count % 2) {
		If (-Not $Quiet) {
			"List '$($List)' is malformed: odd number of double quotes found!" | Write-BLLog -LogType CriticalError
		}
		$ht.Clear()
		Return
	}
	If ($ByOrder -Or ($Defaults.Count -eq 0)) {
		$ht.Clear()
	} Else {
		$Defaults.GetEnumerator() | ForEach-Object {
			$ht.Set_Item($_.Key, $_.Value)
		}
	}
	$SplitList = $List -Split ($Delim + '(?=(?:[^"]*"[^"]*")*[^"]*\Z)')	## Split at all delims that are followed by 0 or an even number of double quotes.
	If ($ByOrder) {
		For ($i = 0; $i -lt $SplitList.Length; $i++) {
			$ht.Set_Item($i, $SplitList[$i].Trim(' "'))
		}
	} Else {
		ForEach ($Element In $SplitList) {
			If ($Element.Trim(' "').Length -gt 0) {
				$a = $Element.Split("=", 2)
				If ($a.Length -gt 1) {
					$ht.Set_Item($a[0].Trim(' "'), $a[1].Trim(' "'))
				} Else {
					$ht.Set_Item($a[0].Trim(' "'), "")
				}
			}
		}
	}
	If ((-Not $ByOrder) -And ($Defaults.Count -gt 0)) {
		$ReturnNull = $False
		$ht.GetEnumerator() | ForEach-Object {
			If ($_.Value -ieq "@error@") {
				If (-Not $Quiet) {
					If (-Not $ReturnNull) {
						"List '$($List)' is missing the following expected keys:" | Write-BLLog -LogType CriticalError
					}
					"`t- '$($_.Key)'" | Write-BLLog -LogType CriticalError -NoTrim
				}
				$ReturnNull = $True
			}
		}
		If ($ReturnNull) {
			$ht.Clear()
		}
	}
	
#	$ht | out-string | Write-Host -ForeGroundColor Green
#	"Leaving " + $MyInvocation.MyCommand + " at " + (Get-Date).ToLongTimeString() | Write-BLLog -LogType Information
}

Function Write-BLConfigDBSettings {
<#
.SYNOPSIS
Filters and writes ConfigDB variables.

.DESCRIPTION
The function Write-BLConfigDBSettings filters and writes ConfigDB variables.
The output can be filtered by variable prefix or regular expression.
Hides passwords automatically if the new .cfg file format is used and the variables are defined correctly (that is, variable is of type 'Password', and the extraction patterns are in the 'Details' field).

.PARAMETER cfg
Mandatory
The hash table with the content of the ConfigDB.

.PARAMETER Filter
Optional
By default, $Filter will be used as a string, and the function will list only variables starting with $Filter.
If -RegEx is used, $Filter will be used as a regular expression and will list only variables matching the regular expression in $Filter.

.PARAMETER RegEx
Optional
If set, $Filter will be used as a regular expression.

.INPUTS
System.Collections.Hashtable
System.String
System.Management.Automation.SwitchParameter

.OUTPUTS

.EXAMPLE
_
$cfg = @{}
Get-BLConfigDBVariables $cfg
Write-BLConfigDBSettings $cfg -Filter DNS_

.LINK
Get-BLConfigDBVariables

.NOTES
None
#>
[CmdletBinding()]
Param(
	[hashtable]$cfg,
	[string]$Filter = "",
	[switch]$RegEx
)
	$GS = [char]29
	If (-Not ($cfg -is [HashTable])) {
		"Required variable 'cfg' is not a hashtable." | Write-BLLog -LogType CriticalError
		Return 1
	}
	"-------------------- Begin of relevant ConfigDB information (filter: $(If ($RegEx) {'RegEx'} Else {'StartsWith'}) '$($Filter)') --------------------" | Write-BLLog -LogType Information
	ForEach ($Key In ($cfg.Keys | Sort-Object)) {
		If ((($Key -ne "#Types")) -And ($Key -ne "#Details")) {
			If ((!$RegEx -And $Key.ToUpper().StartsWith($Filter.ToUpper())) -Or ($RegEx -And ($Key -match $Filter))) {
				If ($cfg["#Types"][$Key] -eq $BL_CFGDB_TYPE_Password) {
					$Details = @{}
					Split-BLConfigDBElementList -ht $Details -List $cfg["#Details"][$Key] -Delim $GS -ByOrder $False
					## Get-BLConfigDBVariables checks that a value containing a password has all required patterns, so we don't check this again here.
					$RE_Password = $Details["PatternPW"]
					If ($RE_Password -eq "full") {
						$Value = "*****"
					} Else {
						$Value = $cfg[$Key] -replace $RE_Password, "*****"
					}
				} Else {
					$Value = $cfg[$Key]
				}
				"'$($Key)' = '$($Value)'" | Write-BLLog -LogType Information
			}
		}
	}
	"-------------------- End of relevant ConfigDB information (filter: $(If ($RegEx) {'RegEx'} Else {'StartsWith'}) '$($Filter)') --------------------" | Write-BLLog -LogType Information
}

## ====================================================================================================
## Group "Miscellaneous"
## ====================================================================================================

Function Compare-BLDirectory {
<#
.SYNOPSIS
Compares two directories.

.DESCRIPTION
The Compare-Directory function compares two directories. One directory is the "reference directory," and the other directory the "difference directory."
The result of the comparison indicates whether a folder or a file is present only in the reference directory (indicated by the <= symbol), only in the difference directory (indicated by the => symbol) or, if the IncludeEqual parameter is specified, in both directories (indicated by the == symbol).
Differing files (time, size, attributes) found in both folders will be indicated by the <> symbol.
Mismatches (file in one directory, folder in the other) will be indicated by the != symbol.

NOTE: a folder indicated as "same" does NOT mean it has the same children in both directories; it just indicates that a folder with the same name exists in both directories.

File/folder classes returned are the same as defined for robocopy.exe; the side indicator is based on the one from Compare-Object.

Item        Exists In   Exists In        Ref/Diff        Ref/Diff      Ref/Diff     Side
Class       Reference   Difference       File Times      File Sizes    Attributes   Indicator
=========== =========== ================ =============== ============= ============ =========
Lonely      Yes         No               n/a             n/a           n/a          <=
Extra       No          Yes              n/a             n/a           n/a          =>
Older       Yes         Yes              Ref < Diff      n/a           n/a          <>
Newer       Yes         Yes              Ref > Diff      n/a           n/a          <>
Changed     Yes         Yes              Equal           Different     n/a          <>
Tweaked     Yes         Yes              Equal           Equal         Different    <>
Same        Yes         Yes              Equal           Equal         Equal        ==
Mismatched  Yes (file)  Yes (directory)  n/a             n/a           n/a          !=

NOTE: WriteTime and Size are not evaluated for folders; this means folders will never have a class of Older, Newer, or Changed!

.PARAMETER ReferenceDirectory
Specifies the directory used as a reference for comparison.

.PARAMETER DifferenceDirectory
Specifies the directory that is compared to the reference directory.

.PARAMETER ExcludeDifferent
Displays only the files or folders of compared directories that are equal.

.PARAMETER IncludeEqual
Displays files and folders of compared objects that are equal. By default, only files and folders that differ between the reference and difference directories are displayed.

.PARAMETER Recurse
Recurses through the child dircetories of the specified directories.

.PARAMETER Filter
Specifies a filter that will be passed to Get-ChildItem.

.PARAMETER FileOnly
Compare only files.

.PARAMETER DirectoryOnly
Compare only directories.

.INPUTS
System.String
You can pipe a string or a folder item to Compare-Directory that will be used as Difference directory.

.OUTPUTS
A custom System.Object[] with 3 properties:
- Item
  The relative (to the reference/difference directory) path of the file or folder name; if the item is a directory, the name will end with a backslash "\".
- Class
  The file/folder class as listed in the description.
- SideIndicator
  The side indicator as listed in the description.

.EXAMPLE
Compare-Directory -ReferenceDirectory "C:\Dir1" -DifferenceDirectory "C:\Dir2" -Recurse
This command compares the contents of two directories files. It displays only the files and folders that appear in one directory only, or differ in both directories, not files that are the same in both directories.
#>
#requires -Version 3
[CmdletBinding()]
Param(
	[Parameter(Position=0)]
	[string]$ReferenceDirectory = $((Get-Location -PSProvider FileSystem).Path),
	[Parameter(Mandatory=$True, Position=1, ValueFromPipeline=$True)]
	[string]$DifferenceDirectory,
	[switch]$ExcludeDifferent,
	[switch]$IncludeEqual,
	[switch]$Recurse,
	[string]$Filter,
	[switch]$DirectoryOnly,
	[switch]$FileOnly
)
	Begin {
		$SideIndicator = @{
			"Lonely" =		"<="
			"Extra" =		"=>"
			"Same" =		"=="
			"Tweaked" =		"<>"
			"Changed" =		"<>"
			"Newer" =		"<>"
			"Older" =		"<>"
			"Mismatched" =	"!="
		}
		$ReferenceDirectory = $ReferenceDirectory.TrimEnd("\") + "\"
		If (-not (Test-Path -Path $ReferenceDirectory)) {
			Throw "Reference directory '$($ReferenceDirectory)' not found!"
		}
		If (-not (Get-Item -Path $ReferenceDirectory).PSIsContainer) {
			Throw "Reference directory '$($ReferenceDirectory)' is not a directory!"
		}
		If ($FileOnly -and $DirectoryOnly) {
			Throw "You want only files AND only directories compared. Very funny."
		}
		If (-Not [System.IO.Path]::IsPathRooted($ReferenceDirectory)) {
			$ReferenceDirectory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ReferenceDirectory)	## Will keep the trailing backslash.
		}
		$gciArgs = @{}
		$gciArgs["Force"] = $True
		$gciArgs["Recurse"] = $Recurse
		If (-not [string]::IsNullOrEmpty($Filter)) {
			$gciArgs["Filter"] = $Filter
		}
		If ($FileOnly) {
			$gciArgs["File"] = $True
		}
		If ($DirectoryOnly) {
			$gciArgs["Directory"] = $True
		}
		$ReferenceItems = [ordered]@{}
		$VerboseTimeFormat = 'yyyyMMdd-HHmm'
		"[$(Get-Date -Format $VerboseTimeFormat)] Reading Reference directory '$($ReferenceDirectory)' ..." | Write-Verbose
		Get-ChildItem -Path $ReferenceDirectory @gciArgs | ForEach-Object {
			$ReferenceItems.Add(($_.FullName -replace "\A$([regex]::Escape($ReferenceDirectory))", ""), $_)
		}
		"[$(Get-Date -Format $VerboseTimeFormat)] ... done." | Write-Verbose
	}
	Process {
		$DifferenceDirectory = $DifferenceDirectory.TrimEnd("\") + "\"
		If (-not (Test-Path -Path $DifferenceDirectory)) {
			Throw "Difference directory '$($DifferenceDirectory)' not found!"
		}
		If (-not (Get-Item -Path $DifferenceDirectory).PSIsContainer) {
			Throw "Difference directory '$($DifferenceDirectory)' is not a directory!"
		}
		If (-Not [System.IO.Path]::IsPathRooted($DifferenceDirectory)) {
			$DifferenceDirectory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DifferenceDirectory)	## Will keep the trailing backslash.
		}
		$DifferenceItems = [ordered]@{}
		"[$(Get-Date -Format $VerboseTimeFormat)] Reading Difference directory '$($DifferenceDirectory)' ..." | Write-Verbose
		Get-ChildItem -Path $DifferenceDirectory @gciArgs | ForEach-Object {
			$DifferenceItems.Add(($_.FullName -replace "\A$([regex]::Escape($DifferenceDirectory))", ""), $_)
		}
		"[$(Get-Date -Format $VerboseTimeFormat)] ... done." | Write-Verbose
		"[$(Get-Date -Format $VerboseTimeFormat)] Creating difference report ..." | Write-Verbose
		$ReferenceItems.GetEnumerator() | ForEach-Object {
			$ReferenceItem = $_.Value
			$ItemName = If ($ReferenceItem.PSIsContainer) {$_.Key + "\"} Else {$_.Key}
			If ($DifferenceItems.Contains($_.Key)) {
				$DifferenceItem = $DifferenceItems[$_.Key]
				If ($ReferenceItem.PSIsContainer -eq $DifferenceItem.PSIsContainer) {
					If ($ReferenceItem.PSIsContainer) {
						If ($ReferenceItem.Mode -ne $DifferenceItem.Mode) {
							$ItemClass = "Tweaked"
						} Else {
							$ItemClass = "Same"
						}
					} Else {
						If ($ReferenceItem.LastWriteTimeUtc -lt $DifferenceItem.LastWriteTimeUtc) {
							$ItemClass = "Older"
						} ElseIf ($ReferenceItem.LastWriteTimeUtc -gt $DifferenceItem.LastWriteTimeUtc) {
							$ItemClass = "Newer"
						} ElseIf ($ReferenceItem.Length -ne $DifferenceItem.Length) {
							$ItemClass = "Changed"
						} ElseIf ($ReferenceItem.Mode -ne $DifferenceItem.Mode) {
							$ItemClass = "Tweaked"
						} Else {
							$ItemClass = "Same"
						}
					}
				} Else {
					$ItemClass = "Mismatched"
				}
				$DifferenceItems.Remove($_.Key)
			} Else {
				$ItemClass = "Lonely"
			}
			If ((($ItemClass -ne "Same") -and !$ExcludeDifferent) -or (($ItemClass -eq "Same") -and $IncludeEqual)) {
				$ItemName | Select-Object -Property `
					@{Name="Item"; Expression={$_}},
					@{Name="Class"; Expression={$ItemClass}},
					@{Name="SideIndicator"; Expression={$SideIndicator[$ItemClass]}}
			}
		}
		If (!$ExcludeDifferent) {
			$DifferenceItems.GetEnumerator() | ForEach-Object {
				$DifferenceItem = $_.Value
				$ItemName = If ($DifferenceItem.PSIsContainer) {$_.Key + "\"} Else {$_.Key}
				$ItemClass = "Extra"
				$ItemName | Select-Object -Property `
					@{Name="Item"; Expression={$_}},
					@{Name="Class"; Expression={$ItemClass}},
					@{Name="SideIndicator"; Expression={$SideIndicator[$ItemClass]}}
			}
		}
		"[$(Get-Date -Format $VerboseTimeFormat)] ... done." | Write-Verbose
	}
	End {
	}
}

Function Compare-BLWmiNamespace {
<#
.SYNOPSIS
Compares the WMI namespaces of two computers.

.DESCRIPTION
The function Compare-BLWmiNamespace compares the WMI namespaces of two computers.
By default, it generates only console output. If you want to work further with the output, use the -PassThru argument.

.PARAMETER ReferenceComputer
Mandatory
The computer whose WMI namespaces will be used as reference.

.PARAMETER DifferenceComputer
Mandatory
The computer whose WMI namespaces will be compared against the reference computer.

.PARAMETER PassThru
Optional
If $True, returns an array of custom objects with the following properties:
    - Namespace <String>
      Namespace
	- Ref <Bool>
      Namespace found on the reference computer.
	- Diff <Bool>
      Namespace found on the difference computer.
    - RefComputer <String>
      Name of the reference computer.
    - DiffComputer <String>
      Name of the difference computer.

.OUTPUTS
None or <System.Object[]>

.EXAMPLE
Compare-BLWmiNamespace -ReferenceComputer "server1" -DifferenceComputer "server2"
Compare the WMI namespaces on server1 and server2.

.EXAMPLE
$Result = Compare-BLWmiNamespace -ReferenceComputer "server1" -DifferenceComputer "server2" -PassThru
Compare the WMI namespaces on server1 and server2 and save the results for further processing in $Result

.EXAMPLE
Compare-BLWmiNamespace -ReferenceComputer "server1" -DifferenceComputer "server2" -PassThru | Export-CliXml -Path "C:\Temp\WmiDiff.xml"
Compare the WMI namespaces on server1 and server2 and save the results for further processing in the file "C:\Temp\WmiDiff.xml".
This file can then later be imported again using Import-CliXml

.LINK
Export-CliXml
Import-CliXml
#>

[CmdletBinding()]
Param(
	[Parameter(Mandatory=$True)]
	[string]$ReferenceComputer,
	[Parameter(Mandatory=$True)]
	[string]$DifferenceComputer,
	[switch]$PassThru
)

	Function Get-BLHereChildNamespace([string]$Namespace, [int]$Depth = 0, [string]$ComputerName) {
		ForEach ($Child In (Get-WmiObject -Namespace $Namespace -Class "__Namespace" -ComputerName $ComputerName -Authentication PacketPrivacy -ErrorAction Stop | Select-Object -ExpandProperty Name | Sort-Object)) {
			$ChildNamespace = "$($Namespace)\$($Child)"
			$ChildNamespace | Write-Output
			If ($NoRecurseList -notcontains $ChildNamespace) {
				Get-BLHereChildNamespace -Namespace $ChildNamespace -Depth ($Depth + 1) -ComputerName $ComputerName
			}
		}
	}

	## ============================================================================================================================================
	$NoRecurseList = @(
		"Root\ccm\Policy",
		"Root\RSOP\User",
		"Root\RSOP\Computer"
	)

	If ($ReferenceComputer -eq ".") {
		$ReferenceHostName = $ENV:ComputerName
	} Else {
		$ReferenceHostName = $ReferenceComputer.Split(".")[0].ToUpper()
	}
	If ($DifferenceComputer -eq ".") {
		$DifferenceHostName = $ENV:ComputerName
	} Else {
		$DifferenceHostName = $DifferenceComputer.Split(".")[0].ToUpper()
	}
	$OldBackgroudColor = [Console]::BackgroundColor
	[Console]::BackgroundColor = [ConsoleColor]::Black
	"" | Write-Host

	Try {
		"Retrieving namespaces on reference computer '$($ReferenceHostName)' ... " | Write-Host -ForegroundColor White -NoNewline
		$ReferenceNamespaces = Get-BLHereChildNamespace -Namespace "Root" -ComputerName $ReferenceComputer
		"OK" | Write-Host -ForegroundColor Green
		"Retrieving namespaces on difference computer '$($DifferenceHostName)' ... " | Write-Host -ForegroundColor White -NoNewline
		$DifferenceNamespaces = Get-BLHereChildNamespace -Namespace "Root" -ComputerName $DifferenceComputer
		"OK" | Write-Host -ForegroundColor Green
	} Catch {
		Write-Host
		$_.Exception.Message | Write-Error
		Exit
	}

	"Comparing ... " | Write-Host -ForegroundColor White -NoNewline
	$AllNamespaces = @()
	ForEach ($Namespace In (($ReferenceNamespaces + $DifferenceNamespaces) | Sort-Object -Unique)) {
		$AllNamespaces += "" | Select-Object -Property `
			@{n="Namespace"; e={$Namespace}},
			@{n="Ref"; e={$False}},
			@{n="Diff"; e={$False}},
			@{n="RefComputer"; e={$ReferenceHostName}},
			@{n="DiffComputer"; e={$DifferenceHostName}}
	}
	ForEach ($Namespace In $AllNamespaces) {
		If ($ReferenceNamespaces -contains $Namespace.Namespace) {
			$Namespace.Ref = $True
		}
		If ($DifferenceNamespaces -contains $Namespace.Namespace) {
			$Namespace.Diff = $True
		}
	}
	"OK" | Write-Host -ForegroundColor Green

	$ColorBoth = [ConsoleColor]::Green
	$ColorRefOnly = [ConsoleColor]::Red
	$ColorDiffOnly = [ConsoleColor]::Yellow
	"Legend:" | Write-Host -ForegroundColor White
	"`tNamespace on BOTH machines: " | Write-Host -ForegroundColor White -NoNewLine
	"<Namespace>" | Write-Host -ForegroundColor $ColorBoth
	"`tNamespace on REFERENCE ONLY ($($ReferenceHostName)): " | Write-Host -ForegroundColor White -NoNewLine
	"<Namespace>" | Write-Host -ForegroundColor $ColorRefOnly
	"`tNamespace on DIFFERENCE ONLY ($($DifferenceHostName)): " | Write-Host -ForegroundColor White -NoNewLine
	"<Namespace>" | Write-Host -ForegroundColor $ColorDiffOnly
	"" | Write-Host

	$AllNamespaces | % {
		If ($_.Ref -and $_.Diff) {
			$ForegroundColor = $ColorBoth
		} ElseIf ($_.Ref) {
			$ForegroundColor = $ColorRefOnly
		} Else {
			$ForegroundColor = $ColorDiffOnly
		}
		$_.Namespace | Write-Host -ForegroundColor $ForegroundColor
	}
	"" | Write-Host
	[Console]::BackgroundColor = $OldBackgroudColor
	"" | Write-Host

	If ($PassThru) {
		$AllNamespaces
	}
}

Function Compress-BLString {
## Compresses a string.
## Use Expand-BLString to expand the object returned.
## Returns a byte[] or, if $AsBase64, a string
[CmdletBinding()]
Param (
	[Parameter(ValueFromPipeline=$True)]
	[string]$String,
	[switch]$AsBase64,
	[switch]$Force
)
	Begin {
	}
	Process {
		Try {
			$MemoryStream = New-Object -TypeName System.IO.MemoryStream
			$GZipStream = New-Object -TypeName System.IO.Compression.GZipStream -ArgumentList $MemoryStream, ([System.IO.Compression.CompressionMode]::Compress)
			$StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $GZipStream
			$StreamWriter.Write($String)
			$StreamWriter.Close()
			$Data = $MemoryStream.ToArray()
			If ($Data.Count -gt $String.Length) {
				If ($Force) {
					"[$($MyInvocation.MyCommand.Name)] Compressed string is longer than the original, but compression is forced." | Write-Verbose
				} Else {
					"[$($MyInvocation.MyCommand.Name)] Compressed string is longer than the original; returning the uncompressed string." | Write-Verbose
					$Data = [System.Text.Encoding]::UTF8.GetBytes($String)
				}
			}
			If ($AsBase64) {
				Return ,([System.Convert]::ToBase64String($Data))
			} Else {
				Return ,$Data
			}
		} Catch {
			Throw $_
		}
	}
	End {
	}
}

Function ConvertTo-BLBool([string]$Text, [bool]$Default) {
## Evaluates the passed string and returns a boolean $True or $False
## If the string isn't supported, the default value will be returned.
	Switch ($Text) {
		{@("1", "y", "yes", "true", "on", "enable") -contains $_} {$ret = $True}
		{@("0", "n", "no", "false", "off", "disable") -contains $_} {$ret = $False}
		Default {$ret = $Default}
	}
	Return $ret
}

Function ConvertTo-BLStringBitmask([uint64]$Bitmask, [HashTable]$ht, [switch]$SortByKey, [switch]$ReturnUndefined) {
## Returns a string array with the names of all hash table keys whose values are set in the bitmask.
## The array will by default be sorted by value; use -SortByKey to sort by key.
## Will return an additional hexadecimal entry with any bits not defined in the hash table if undefined set bits are found.
## If $ReturnUndefined is set, the Undefined value will always be added to the return array.
	$StringBitmask = @()
	$Undefined = $BitMask
	If ($SortByKey) {
		ForEach ($Key In ($ht.Keys | sort)) {
			If ($ht[$Key] -band $BitMask) {
				$StringBitmask += ($ht.GetEnumerator() | Where {$_.Value -eq $ht[$Key]}).Key
				$Undefined = $Undefined -bxor $ht[$Key]
			}
		}
	} Else {
		ForEach ($Value In ($ht.Values | sort)) {
			If ($Value -band $BitMask) {
				$StringBitmask += ($ht.GetEnumerator() | Where {$_.Value -eq $Value}).Key
				$Undefined = $Undefined -bxor $Value
			}
		}
	}
	If (($Undefined -gt 0) -or $ReturnUndefined) {
		$StringBitmask += "0x{0:X16}" -f $Undefined
	}
	Return ,$StringBitmask
}

Function Copy-BLArchiveContent([string]$Archive, [string]$DestFolder, [string]$ExtractOption = "x", [string[]]$Options = "", [string[]]$Pattern = "") {
## Uses external program "7z.exe"
	& $SevenZip $ExtractOption $Options -y "-o$DestFolder" "$Archive" $Pattern | Write-BLLog -LogType Information -CustomCol "7z.exe"
	$ExitCode = $LASTEXITCODE
	Return $ExitCode
}

Function Copy-BLWindowsCertToJava {
<#
.SYNOPSIS
Copies Root certificates from the Windows certificate store into a Java certificate store.

.DESCRIPTION
The function Copy-BLWindowsCertToJava copies Root certificates from the Windows certificate store into a Java certificate store.
Note: unless there is a syntax error in the command line, the function will always return an object.
To test for errors, the object returned needs to be inspected, for example like this:
If ($Results | ? {$_.ErrorInit -Or $_.ErrorImport}) {...}
Of the common arguments, -Verbose is supported.
Note: for performance reasons, the progress bar will be disabled if Verbose is $True.

.PARAMETER JavaHome
Mandatory
The path to the home of the Java installation that should be updated with the Windows certificates.
This is the path where the "lib" and "bin" folders are stored.

.PARAMETER AllInstalled
Mandatory
Update all installed Java versions.

.PARAMETER StorePass
Optional
The password for the Java certificate store to be updated with the Windows certificates.

.INPUTS
System.String[]

.OUTPUTS
System.Object[]
An object with the following properties will be returned for each JavaHome path processed:
    - JavaHome <string> The path of the JavaHome folder processed.
    - KeyStore <string The path to the keystore processed
    - BackupStore <string> The path to the backup of the keystore that was created during processing
    - ErrorInit <string> Error string if an error occurred before the processing of the Java certstore started
    - ErrorImport <System.Object[]> Array with the following properties if an error occurred during import:
	    - Thumbprint <string> Thumbprint of the certificate that couldn't be imported
	    - Error <string> keytool.exe's output

.EXAMPLE
$Result = .\Copy-BLWindowsCertToJava -AllInstalled
Update all Java installations found.

.EXAMPLE
$Result = .\Copy-BLWindowsCertToJava -JavaHome "C:\Program Files (x86)\Java\jre1.8.0_45" -Verbose
Update all Java installations found in "C:\Program Files (x86)\Java\jre1.8.0_45", and use verbose output.

.EXAMPLE
_
$Results = Copy-ISWindowsCertToJava -AllInstalled
If ($Results | ? {$_.ErrorInit -Or $_.ErrorImport}) {
	"There were errors" | Write-Error
}
Update all Java installations found and check for errors.
#>
[CmdletBinding(DefaultParameterSetName="Copy_By_Path")]
Param (
	[Parameter(ValueFromPipeline=$True, Position=0, ParameterSetName="Copy_By_Path")]
	[string[]]$JavaHome,
	[Parameter(ValueFromPipeline=$True, Position=0, ParameterSetName="Copy_By_Install")]
	[switch]$AllInstalled,
	[Parameter(ValueFromPipeline=$False, Position=1)]
	[string]$StorePass = "changeit"
)
	Begin {
		If (($JavaHome.Count -eq 0) -And (-Not $AllInstalled)) {
			Throw "Either -JavaHome or -AllInstalled must be specified!"
		}
		If ($AllInstalled) {
			$JavaHome = @()
			ForEach ($Wow6432Node In ("", "\Wow6432Node")) {
				$JavaREKey = "HKLM:\SOFTWARE$($Wow6432Node)\JavaSoft\Java Runtime Environment"
				$JavaHome += Get-BLRegistryKeyX64 -Path "$JavaREKey\*" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty JavaHome
			}
			$JavaHome = $JavaHome | Sort-Object -Unique
			If ($JavaHome.Count -eq 0) {
				$Result = "" | Select-Object "JavaHome", "KeyStore", "BackupStore", "ErrorInit", "ErrorImport"
				$Result.ErrorInit = "No installed Java versions found!"
				Return $Result
			} Else {
				"Found the following installed JavaHome folders:" | Write-Verbose
				$JavaHome | % {"    - $_" | Write-Verbose}
			}
		}
		$Verbose = $VerbosePreference -ne [System.Management.Automation.ActionPreference]::SilentlyContinue
		$WindowsCertCache = @{}
		$CertExportCachePath = Join-Path -Path $ENV:Temp -ChildPath "CertCache"
		"Retrieving Windows Root CAs ..." | Write-Verbose
		$RootCerts = Get-ChildItem "Cert:\LocalMachine\Root" -Recurse -ErrorAction Stop
		"... OK." | Write-Verbose
		If (Test-Path -Path $CertExportCachePath) {
			"Clearing old cache ..." | Write-Verbose
			Remove-Item -Path $CertExportCachePath -Recurse -Force -ErrorAction Stop
		}
		New-Item -Path $CertExportCachePath -ItemType Directory -ErrorAction Stop | Out-Null
		$ErrorList = New-Object System.Collections.ArrayList
	}
	Process {
		ForEach ($HomeDir In $JavaHome) {
			$Result = "" | Select-Object "JavaHome", "KeyStore", "BackupStore", "ErrorInit", "ErrorImport"
			"Processing Java home '$($HomeDir)' ..." | Write-Verbose
			$Result.JavaHome = $HomeDir
			$JavaCAStorePath = Join-Path -Path $HomeDir -ChildPath "lib\security\cacerts"
			$JavaKeytoolPath = Join-Path -Path $HomeDir -ChildPath "bin\keytool.exe"
			If (-Not (Test-Path -Path $JavaCAStorePath)) {
				$Result.ErrorInit = "Java CA Store not found: '$($JavaCAStorePath)'"
				$Result | Write-Output
				Continue
			}
			If ((-Not $Result.ErrorInit) -And (-Not (Test-Path -Path $JavaKeytoolPath))) {
				$Result.ErrorInit = "Java KeyTool not found: '$($JavaKeytoolPath)'"
				$Result | Write-Output
				Continue
			}
			Try {
				New-Item -Path "$($JavaCAStorePath).tmp" -ItemType File -Force -ErrorAction Stop | Remove-Item -ErrorAction Stop
			} Catch {
				$Result.ErrorInit = $Error[0].Exception.Message
				$Result | Write-Output
				Continue
			}
			If (!$Verbose) {Write-Progress -Activity "Querying Java Certificates" -Status $JavaKeytoolPath -PercentComplete 0 -SecondsRemaining -1}
			$Output = & $JavaKeytoolPath -list -v -storepass $StorePass -keystore $JavaCAStorePath 2>&1
			<# Output format example:
			Alias name: entrustnet_8cf427fd790c3ad166068de81e57efbb932272d4
			Creation date: 07.10.2015
			Entry type: trustedCertEntry

			Owner: CN=Entrust Root Certification Authority - G2, OU="(c) 2009 Entrust, Inc. - for authorized use only", OU=See www.entrust.net/legal-terms, O="Entrust, Inc.", C=US
			Issuer: CN=Entrust Root Certification Authority - G2, OU="(c) 2009 Entrust, Inc. - for authorized use only", OU=See www.entrust.net/legal-terms, O="Entrust, Inc.", C=US
			Serial number: 4a538c28
			Valid from: Tue Jul 07 17:25:54 UTC 2009 until: Sat Dec 07 17:55:54 UTC 2030
			Certificate fingerprints:
					 MD5:  4B:E2:C9:91:96:65:0C:F4:0E:5A:93:92:A0:0A:FE:B2
					 SHA1: 8C:F4:27:FD:79:0C:3A:D1:66:06:8D:E8:1E:57:EF:BB:93:22:72:D4
					 SHA256: 43:DF:57:74:B0:3E:7F:EF:5F:E4:0D:93:1A:7B:ED:F1:BB:2E:6B:42:73:8C:4E:6D:38:41:10:3D:3A:A7:F3:39
					 Signature algorithm name: SHA256withRSA
					 Version: 3

			Extensions:

			#1: ObjectId: 2.5.29.19 Criticality=true
			BasicConstraints:[
			  CA:true
			  PathLen:2147483647
			]

			#2: ObjectId: 2.5.29.15 Criticality=true
			KeyUsage [
			  Key_CertSign
			  Crl_Sign
			]

			#3: ObjectId: 2.5.29.14 Criticality=false
			SubjectKeyIdentifier [
			KeyIdentifier [
			0000: 6A 72 26 7A D0 1E EF 7D   E7 3B 69 51 D4 6C 8D 9F  jr&z.....;iQ.l..
			0010: 90 12 66 AB                                        ..f.
			]
			]



			*******************************************
			*******************************************
			#>			
			If ($LASTEXITCODE -ne 0) {
				If (!$Verbose) {Write-Progress -Activity "Done" -Completed}
				$Result.ErrorInit = $Output
				$Result | Write-Output
				Continue
			}
			$JavaCertCache = @{}
			$Index = 0
			ForEach ($Line In $Output) {
				If ($Line -match "\AAlias name: (?<Alias>.*)\Z") {
					$Alias = $Matches["Alias"]
				}
				If ($Line -match "\ASerial number: (?<Serial>.*)\Z") {
					If (!$Verbose) {Write-Progress -Activity "Caching Java Certificates" -Status $Alias -PercentComplete ((100 * $Index) / $Output.Count) -SecondsRemaining -1}
					$JavaCertCache[$Alias] = $Matches["Serial"]
				}
				$Index += 1
			}
			$Result.KeyStore = $JavaCAStorePath
			If ($WindowsCertCache.Count -eq 0) {	## Build the windows cert file and alias cache; we don't do this in Begin{} because it's only worth it if we have a valid JavaHome path to work with.
				$Index = 0
				ForEach ($Certificate In $RootCerts) {
					If (!$Verbose) {Write-Progress -Activity "Caching Windows certificates" -Status "$($Certificate.FriendlyName), $($Certificate.Thumbprint)" -PercentComplete ((100 * $Index) / $RootCerts.Count) -SecondsRemaining -1}
					## The alias must be unique in the Java cert store, and is case sensitive. 
					## There seems to be no documentation available which characters are allowed in an alias, so we follow the alias name convention in the original store 
					## and use only lower case characters from a-z, no spaces.
					## The Alias will be built from the friendly name (which is not unique) and its thumbprint.
					$UmlautMap = @{
						"ä" = "ae"
						"ö" = "oe"
						"ü" = "ue"
						"ß" = "ss"
					}
					$Alias = $Certificate.FriendlyName
					$UmlautMap.Keys | % {$Alias = $Alias -replace $_, $UmlautMap[$_]}
					$Alias = (($Alias -replace "[^a-z0-9]", "") + "_" + $Certificate.Thumbprint).ToLower()
					"Exporting '$($Alias)' to cache ..." | Write-Verbose
					$Export = $Certificate.Export(([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
					$CertFile = Join-Path -Path $CertExportCachePath -ChildPath "$($Alias).tmp"
					[System.IO.File]::WriteAllBytes($CertFile, $Export)
					$FormattedSN = $Certificate.SerialNumber.TrimStart("0")
					If ([string]::IsNullOrEmpty($FormattedSN)) {$FormattedSN = "0"}
					$WindowsCertCache[$Alias] = $FormattedSN	## Windows serials may have leading zeros, Java serials don't!
					$Index += 1
				}
			}
			$BackupStore = $JavaCAStorePath + "." + (Get-Date -Format "yyyyMMdd-HHmmss")
			Copy-Item -Path $JavaCAStorePath -Destination $BackupStore
			$Result.BackupStore = $BackupStore
			$Index = 0
			ForEach ($Alias In $WindowsCertCache.Keys) {
				If (!$Verbose) {Write-Progress -Activity "Importing into '$($HomeDir)'" -Status $Alias -PercentComplete ((100 * $Index) / $WindowsCertCache.Count) -SecondsRemaining -1}
				$ImportCert = $True
				$ImportLog = "added."
				If ($JavaCertCache.ContainsKey($Alias)) {
					If ($WindowsCertCache[$Alias] -eq $JavaCertCache[$Alias]) {
						$ImportCert = $False
						$ImportLog = "skipped, found with the same serial number."
					} Else {
						& $JavaKeytoolPath -delete -alias $Alias -storepass $StorePass -keystore $JavaCAStorePath 2>&1 | Out-Null
						$ImportLog = "updated, S/N Windows: '$($WindowsCertCache[$Alias])'; S/N Java: '$($JavaCertCache[$Alias])'"
					}
				}
				If ($ImportCert) {
					$CertFile = Join-Path -Path $CertExportCachePath -ChildPath "$($Alias).tmp"
					$Output = & $JavaKeytoolPath -import -file $CertFile -alias $Alias -storepass $StorePass -keystore $JavaCAStorePath -noprompt 2>&1
					If ($LASTEXITCODE -ne 0) {
						$ImportLog = "ERROR: '$($Output)'"
						$ErrorList.Add(("" | Select-Object -Property @{Name="Thumbprint"; Expression={$Alias.Split('_')[1].ToUpper()}}, @{Name="Error"; Expression={$Output}})) | Out-Null
					}
				}
				"[$($HomeDir)] $($Alias) - $($ImportLog)" | Write-Verbose
				$Index += 1
			}
			If ($ErrorList.Count -gt 0) {
				$Result.ErrorImport = $ErrorList
				$ErrorList.Clear()
			}
			$Result | Write-Output
		}
		If (!$Verbose) {Write-Progress -Activity "Done" -Completed}
	}
	End {
		If (Test-Path -Path $CertExportCachePath) {
			Remove-Item -Path $CertExportCachePath -Recurse -Force 
		}
	}
}

Function Disable-BLGeneratePublisherEvidence([string]$Path, [switch]$PassThru) {
## Sets the "enabled" attribute  in the generatePublisherEvidence of the specified xml file to "false".
## If the file does not exist, it will be created (but the file's folder MUST exist).
## This can be required to prevent a CRL check in .NET 2.0 that queries Verisign and can lead to long delays (Citrix consoles, ASP .NET sites, ...)
## See 'FIX: A .NET Framework 2.0 managed application that has an Authenticode signature takes longer than usual to start', http://support.microsoft.com/kb/936707
## If -PassThru is not specifed:
##		Returns nothing on success; throws an error if the folder doesn't exist or the file couldn't be written.
## If -PassThru is specifed:
## 		Returns the xml configuration on success, $Null if an error occurred, .
	Try {
		If ([string]::IsNullOrEmpty($Path)) {Throw "Mandatory argument 'Path' is empty!"}
		$SaveFile = $False
		$xmlConfigItem = Get-Item -Path $Path -ErrorAction SilentlyContinue
		If ($xmlConfigItem) {
			[xml]$xml = Get-Content -Path $xmlConfigItem.FullName
			$NodeConfiguration = $xml.SelectSingleNode("configuration")
			$NodeRuntime = $xml.SelectSingleNode("configuration/runtime")
			If (-Not $NodeRuntime) {
				$SaveFile = $True
				$NodeRuntime = $NodeConfiguration.AppendChild($xml.CreateElement("runtime"))
			}
			$NodePublisher = $xml.SelectSingleNode("configuration/runtime/generatePublisherEvidence")
			If (-Not $NodePublisher) {
				$SaveFile = $True
				$NodePublisher = $NodeRuntime.AppendChild($xml.CreateElement("generatePublisherEvidence"))
			}
			If ($NodePublisher.GetAttribute("enabled") -ne "false") {
				$SaveFile = $True
				$NodePublisher.SetAttribute("enabled", "false")
			}
		} Else {
			$Folder = Split-Path -Path $Path -Parent
			If (-Not (Test-Path -Path $Folder)) {
				If ($PassThru) {
					Return $Null
				} Else {
					Throw "Folder '$Folder' not found!"
				}
			}
			$SaveFile = $True
			$xml = [xml]@"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
	<runtime>
		<generatePublisherEvidence enabled="false" />
	</runtime>
</configuration>
"@
		}
		If ($SaveFile) {
			$xml.Save($Path)
		}
		If ($PassThru) {
			Return $xml
		}
	} Catch {
		If ($PassThru) {
			Write-Error $_.Exception.Message
			Return $Null
		} Else {
			Throw $_
		}
	}
}

Function Expand-BLString {
## Expands a Byte Array or Base64 String that was compressed with Compress-BLString.
## Use Compress-BLString to create a compressed string.
## For GZip format information, see 'Gzip', http://forensicswiki.org/wiki/Gzip
[CmdletBinding()]
Param (
	[Parameter(ValueFromPipeline=$True)]
	$Data
)
	Begin {
	}
	Process {
		Try {
			If ($Data -is [System.String]) {
				"[$($MyInvocation.MyCommand.Name)] Detected Base64 encoded string as input." | Write-Verbose
				$Data = [System.Convert]::FromBase64String($Data)
			} ElseIf ($Data -is [System.Byte[]]) {
				"[$($MyInvocation.MyCommand.Name)] Detected byte array as input." | Write-Verbose
			} Else {
				Throw "Received invalid data type as input: '$($Data.GetType().FullName)'; expected 'System.String' or 'System.Byte[]'!"
			}
			If (($Data[0] -eq 31) -and ($Data[1] -eq 139) -and ($Data[2] -eq 8)) {	## GZip Header
				"[$($MyInvocation.MyCommand.Name)] Detected compressed data." | Write-Verbose
				$MemoryStream = New-Object -TypeName System.IO.MemoryStream
				$MemoryStream.Write($Data, 0, $Data.Count)
				$MemoryStream.Seek(0, 0) | Out-Null
				$GZipStream = New-Object -TypeName System.IO.Compression.GZipStream -ArgumentList $MemoryStream, ([System.IO.Compression.CompressionMode]::Decompress)
				$StreamReader = New-Object -TypeName System.IO.StreamReader -ArgumentList $GZipStream
				Return $StreamReader.ReadToEnd()
			} Else {
				"[$($MyInvocation.MyCommand.Name)] Detected uncompressed data." | Write-Verbose
				Return [System.Text.Encoding]::UTF8.GetString($Data)
			}
		} Catch {
			Throw $_
		}
 	}
	End {
	}
}

Function Format-BLHashTable { 
## Returns a hash table as a sorted, autosized table with custom column headers;
## use $SortByValue to sort by value (default is to sort by Key)
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)]
	[hashtable]$ht,
	[Parameter(Mandatory=$False, Position=1)]
	[string]$HeaderKey = "Name",
	[Parameter(Mandatory=$False, Position=2)]
	[string]$HeaderValue = "Value",
	[Parameter(Mandatory=$False, Position=3)]
	[switch]$SortByValue,
	[Parameter(Mandatory=$False, Position=4)]
	[switch]$Descending
)
	Process {
		If ($ht) {
			$ArgumentsSort = @{}
			If ($SortByValue) {
				$ArgumentsSort["Property"] = "Value"
			} Else {
				$ArgumentsSort["Property"] = "Key"
			}
			$ArgumentsSort["Descending"] = $Descending
			
			$ArgumentsFormatTable = @{}
			$ArgumentsFormatTable["Property"] = @{Label=$HeaderKey; Expression={$_.Name}}, @{Label=$HeaderValue; Expression={$_.Value}}
			$ArgumentsFormatTable["AutoSize"] = $True
			
			Return $ht.GetEnumerator() | Sort @ArgumentsSort | Format-Table @ArgumentsFormatTable | Out-String
		}
	}
}

Function Format-BLXML { 
## Returns XML as formatted string
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)]
	[xml]$xml,
	[Parameter(Mandatory=$False, Position=1)]
	[uint32]$Indent = 2,
	[Parameter(Mandatory=$False, Position=2)]
	[char]$IndentChar = " "
)
	Process {
		If ($xml) {
			$StringWriter = New-Object System.IO.StringWriter 
			$XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter 
			$xmlWriter.Formatting = "indented" 
			$xmlWriter.Indentation = $Indent
			$xmlWriter.IndentChar = $IndentChar
			$xml.WriteContentTo($XmlWriter) 
			$XmlWriter.Flush() 
			$StringWriter.Flush() 
			Return $StringWriter.ToString()
		}
	}
}

Function Get-BLDfsrReplicatedFolderInfo {
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)]
	[string[]]$ComputerName = @($ENV:ComputerName),
	[Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True)]
	[string]$ReplicationGroupName = "Domain System Volume"
)
## See 'DfsrReplicatedFolderInfo class', http://msdn.microsoft.com/en-us/library/bb540019(v=vs.85).aspx
	Begin {
		$Result = @()
		$StateValueMap = @(
			"Uninitialized",
			"Initialized",
			"Initial Sync",
			"Auto Recovery",
			"Normal",
			"In Error"
		)
	}
	Process {
		ForEach ($Computer In $ComputerName) {
			$Result += Get-WmiObject -Namespace "Root\MicrosoftDfs" -Class "DfsrReplicatedFolderInfo" -ComputerName $Computer | Where {$_.ReplicationGroupName -eq $ReplicationGroupName} |
				Select-Object -Property `
					"CurrentConflictSizeInMb",
					"CurrentStageSizeInMb",
					"LastConflictCleanupTime",
					"LastErrorCode",
					"LastErrorMessageId",
					"LastTombstoneCleanupTime",
					"MemberGuid",
					"MemberName",
					"ReplicatedFolderGuid",
					"ReplicatedFolderName",
					"ReplicationGroupGuid",
					"ReplicationGroupName",
					"State",
					@{Name="StateToString"; Expression={$StateValueMap[$_.State]}},
					"PSComputerName"
		}
	}
	End {
		Return $Result
	}
}

Function Get-BLDnsSrvRecord {
[CmdletBinding()]
Param(
	[string]$Name,
	[switch]$API,		## NOT USED ANYMORE, only for backward compatibility; API is the new default.
	[switch]$nslookup	## Force nslookup (expect response times of 2-4 seconds!)
)
## Returns the DNS SRV record for the name queried using either the parsed nslookup.exe output or the API output.
## API:
##   - Works in PS 2.0 and later and on W2kR2 and later.
##   - Output currently doesn't return the IP addresses.
##   - Does NOT attach any DNS suffixes.
##   - No information available about the DNS server used, but failover seems to work.
## nslookup:
##   - Relies on nslookup output format (tested on W2k8R2, W2k12, W2k12R2, all English)
##   - Returns the IP address(es) of the SRV hosts.
##   - Attaches DNS suffixes automatically (if the name doesn't end with a ".")
##   - nslookup by default uses only the first DNS server configured!
##   - The nslookup query uses jobs to query all DNS servers found, which involves an overhead of 2-4 seconds!
	$ErrorOutput = @()
	$SrvLocationFound = $False
	$NWAProperties = @("Description", "DNSDomain", "DNSDomainSuffixSearchOrder", "DNSServerSearchOrder", "IPAddress")
	$NetworkAdapterConfigurations = Get-WmiObject -Namespace "Root\cimv2" -Query "Select $($NWAProperties -join ",") From Win32_NetworkAdapterConfiguration Where IPEnabled='TRUE'" | ? {$_.IPAddress} | Select-Object -Property $NWAProperties
	If (-Not $nslookup) {
		$Result = $Null
		$DomainSuffixes = $NetworkAdapterConfigurations | ? {$_.DNSDomainSuffixSearchOrder}  | Select-Object -ExpandProperty DNSDomainSuffixSearchOrder -Unique
		If ($Name.EndsWith(".")) {
			"Querying DNS API for '$($Name)'." | Write-Verbose
			$Result = [BLDnsSrvQuery]::GetSRVRecords($Name)
			If ([string]::IsNullOrEmpty($Result[0].Exception)) {
				$SrvLocationFound = $True
			} Else {
				$ErrorOutput += "" | Select-Object -Property `
					@{Name="SRV"; Expression={$Name}},
					@{Name="Response"; Expression={$Result[0].Exception}}
			}
		} Else {
			If ([regex]::Matches($Name, "\.").Count -gt 1) {	## An SRV query requires at least one "." (protocol type), so if there's more than one "." in the name, we need to try the name passed first before adding domain suffixes.
				$DomainSuffixes = @("") + $DomainSuffixes
			}
			ForEach ($DomainSuffix In $DomainSuffixes) {
				$SrvFqdn = $Name + "." + $DomainSuffix
				"Querying DNS API for '$($SrvFqdn)'." | Write-Verbose
				$Result = [BLDnsSrvQuery]::GetSRVRecords($SrvFqdn)
				If ([string]::IsNullOrEmpty($Result[0].Exception)) {
					$SrvLocationFound = $True
					Break
				} Else {
					$ErrorOutput += "" | Select-Object -Property `
						@{Name="SRV"; Expression={$SrvFqdn}},
						@{Name="Response"; Expression={$Result[0].Exception}}
				}
			}
		}
		If ($SrvLocationFound) {
			Return ($Result | Select-Object -Property * -ExcludeProperty Exception | Sort-Object -Property Priority)
		} Else {
			"No SRV entry found; API responses:" | Write-Warning
			$ErrorOutput | Format-List | Out-String | Write-Warning
			Return
		}
	} Else {
		<#	nslookup.exe output example:
			Server:  UnKnown
			Address:  10.32.218.116

			_cfgdb._tcp.PB1.infra3.svc      SRV service location:
					  priority       = 1
					  weight         = 10
					  port           = 50080
					  svr hostname   = pb1icmpb001.pb1.infra3.svc
			_cfgdb._tcp.PB1.infra3.svc      SRV service location:
					  priority       = 0
					  weight         = 0
					  port           = 50080
					  svr hostname   = pb1imspb001.pb1.infra3.svc
			pb1icmpb001.pb1.infra3.svc      internet address = 10.32.218.119
			pb1imspb001.pb1.infra3.svc      internet address = 10.32.218.121
			pb1imspb001.pb1.infra3.svc      internet address = 10.32.218.122
		#>
		$DNSServers = $NetworkAdapterConfigurations | ? {$_.DNSServerSearchOrder} | Select-Object -ExpandProperty DNSServerSearchOrder -Unique
		If (-Not $DNSServers) {
			"No DNS servers configured!" | Write-Error
			Return
		}
		"[$(Get-Date -Format "HH:mm:ss")] Querying the following DNS servers: $($DNSServers -join ", ")" | Write-Verbose
		$JobList = New-Object System.Collections.ArrayList
		ForEach ($DNSServer In $DNSServers) {
			$Job = Start-Job -Name $DNSServer -ArgumentList $Name, $DNSServer -ScriptBlock {
				Param(
					[string]$Name,
					[string]$DNSServer
				)
				& "${ENV:Systemroot}\system32\nslookup.exe" -type=SRV $Name $DNSServer 2>&1
			}
			$JobList.Add($Job) | Out-Null
		}
		"[$(Get-Date -Format "HH:mm:ss")] Waiting for responses ..." | Write-Verbose
		Do {
			ForEach ($Job In ($JobList | ? {$_.State -eq "Completed"})) {
				$Output = Receive-Job -Job $Job
				Remove-Job -Job $Job
				$JobList.Remove($Job)
#				"[$(Get-Date -Format "HH:mm:ss")] Received response from $($Job.Name):`r`n$($Output -join "`r`n")" | Write-Verbose
				If ($Output | Select-String -Pattern "SRV service location" -SimpleMatch) {
					"[$(Get-Date -Format "HH:mm:ss")] Received SRV location from $($Job.Name)." | Write-Verbose
					$Output | Write-Verbose
					$SrvLocationFound = $True
					Break
				} Else {
					$ErrorOutput += "" | Select-Object -Property `
						@{Name="DNSServer"; Expression={$Job.Name}},
						@{Name="Response"; Expression={$Output -join "`r`n"}}
				}
			}
			Start-Sleep -MilliSeconds 25
		} Until ($SrvLocationFound -Or ($JobList.Count -eq 0))
		"[$(Get-Date -Format "HH:mm:ss")] ... OK, removing remaining jobs ..." | Write-Verbose
		$JobList | % {Remove-Job -Job $_ -Force}
		"[$(Get-Date -Format "HH:mm:ss")] ... OK." | Write-Verbose
		If (-Not $SrvLocationFound) {
			"No SRV entry found; DNS responses:" | Write-Warning
			$ErrorOutput | Format-List | Out-String | Write-Warning
			Return
		}
		$SrvEntries = @()
#		$Output = & "${ENV:Systemroot}\system32\nslookup.exe" -type=SRV $Name 2>&1
		Switch -Regex ($Output) {
			'\A\s*(?<Property>priority|weight|port|svr hostname)\s*=\s*(?<Value>.+)\Z' {
				If ($Matches["Property"] -eq "priority") {
					$SrvEntry = "" | Select-Object Name, Priority, Weight, Port, Address
				}
				$SrvEntry.($Matches["Property"].Replace("svr hostname", "Name")) = $Matches["Value"]
				If ($Matches["Property"] -eq "svr hostname") {
					$SrvEntries += $SrvEntry
				}
				$SrvEntry.Address = @()
			}
			'\A\s*(?<FQDN>[^\s]+)\s*internet address = (?<Address>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\Z)' {
				$SrvEntries | Where {($_.Name -eq $Matches["FQDN"]) -And ($_.Address -NotContains $Matches["Address"])} | % {$_.Address += $Matches["Address"]}
			}
		}
		If ($SrvEntries) {
			Return $SrvEntries | Sort-Object -Property Priority
		} Else {
			"Unable to parse the nslookup output as expected:" | Write-Warning
			$Output | Write-Warning
		}
	}
}

Function Get-BLHashFromFile {
Param (
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)]
	[string]$Path,
	[Parameter(Mandatory=$False, Position=1)][ValidateSet("MD5", "SHA1", "SHA256", "SHA384", "SHA512", "RIPEMD160")]
	[string]$Type = "MD5",
	[Parameter(Mandatory=$False, Position=2)]
	[switch]$Upper
)
	Process {
		If (-Not (Test-Path -Path $Path)) {
			"File not found: '$Path'!" | Write-Error
		} Else {
			$StringBuilder = New-Object -TypeName System.Text.StringBuilder
			$FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $Path, ([System.IO.FileMode]::Open), ([System.IO.FileAccess]::Read)
			Switch ($Type) {
				"MD5"		{$Provider = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider}
				"SHA1"		{$Provider = New-Object -TypeName System.Security.Cryptography.SHA1CryptoServiceProvider}
				"SHA256"	{$Provider = New-Object -TypeName System.Security.Cryptography.SHA256CryptoServiceProvider}
				"SHA384"	{$Provider = New-Object -TypeName System.Security.Cryptography.SHA384CryptoServiceProvider}
				"SHA512"	{$Provider = New-Object -TypeName System.Security.Cryptography.SHA512CryptoServiceProvider}
				"RIPEMD160"	{$Provider = New-Object -TypeName System.Security.Cryptography.CryptoServiceProvider}
			}
			If ($Upper) {$Format = "X2"} Else {$Format = "x2"}
			$Provider.ComputeHash($FileStream) | Foreach-Object {
				$StringBuilder.Append($_.ToString($Format)) | Out-Null
			}
			$FileStream.Close()
			$StringBuilder.ToString()
		}
	}
}

Function Get-BLHashFromString {
## Generates a hash of a string.
## Default is MD5 with the hash in lower case; use -Upper to return the hash in upper case.
Param (
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)]
	[string]$String,
	[Parameter(Mandatory=$False, Position=1)][ValidateSet("MD5", "SHA1", "SHA256", "SHA384", "SHA512", "RIPEMD160")]
	[string]$Type = "MD5",
	[Parameter(Mandatory=$False, Position=2)]
	[switch]$Upper
)
	Process {
		$StringBuilder = New-Object -TypeName System.Text.StringBuilder
		$HashAlgorithm = [System.Security.Cryptography.HashAlgorithm]::Create($Type)
		If ($Upper) {$Format = "X2"} Else {$Format = "x2"}
		$HashAlgorithm.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String)) | ForEach-Object {
			$StringBuilder.Append($_.ToString($Format)) | Out-Null
		}
		$StringBuilder.ToString()
	}
}

Function Get-BLInternetExplorerVersion {
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$true, Position=0)]
	[string[]]$ComputerName = @($ENV:ComputerName)
)
	Begin {
		$IePath = "HKLM:\SOFTWARE\Microsoft\Internet Explorer"
	}
	Process {
		$ComputerName |
			ForEach-Object {
				$Result = "" | Select-Object -Property Version, UpdateVersion, InstallDate, ComputerName, Exception
				$Result.ComputerName = $_
				Try {
					[version]$Result.Version = Get-BLRegistryValueX64 -Path $IePath -Name "svcVersion" -ComputerName $ComputerName -ErrorAction SilentlyContinue
					If ([string]::IsNullOrEmpty($Result.Version)) {
						[version]$Result.Version = Get-BLRegistryValueX64 -Path $IePath -Name "Version" -ComputerName $ComputerName
					} Else {
						$Result.UpdateVersion = Get-BLRegistryValueX64 -Path $IePath -Name "svcUpdateVersion" -ComputerName $ComputerName	## Can be "RTM", so can't be [version]!
					}
					$binInstallDate = Get-BLRegistryValueX64 -Path "$($IePath)\Migration" -Name "IE Installed Date" -ComputerName $ComputerName
					If ($binInstallDate) {
						$Result.InstallDate = [datetime]::FromFileTime(([BitConverter]::ToUInt64($binInstallDate, 0)))
					}
				} Catch {
					$Result.Exception = $_
				}
				$Result | Write-Output
			}
	}
	End {
	}
}

Function Get-BLRandomString {
<#
.SYNOPSIS
Generates a random string based on character classes.

.DESCRIPTION
The function New-BLRandomString generates a random string based on character classes.
It can optionally contain mandatory characters from specified classes, for example to generate a password that meets complexity requirements.
There are four predefined character classes; other sets can be passed as well.
The function supports the -Verbose argument to show how the string will be built.

.PARAMETER Length
The length of the string to generate.

.PARAMETER Upper
If $True, the string will contain at least one character from the predefined Upper character class (use the -List argument to show the predefined classes).

.PARAMETER Lower
If $True, the string will contain at least one character from the predefined Lower character class (use the -List argument to show the predefined classes).

.PARAMETER Digit
If $True, the string will contain at least one digit (use the -List argument to show the predefined classes).

.PARAMETER Special
If $True, the string will contain at least one character from the predefined Special character class (use the -List argument to show the predefined classes).

.PARAMETER FirstCharacterClass
Specifies a string containing a set of characters from which the first character of the string will be selected.

.PARAMETER MandatoryClasses
Specifies an array of strings with character classes. (At least) one character from each array element will be used in the string.
 
.PARAMETER DefaultClass
Specifies a string containing a set of characters from which the (non-mandatory parts of the) string will be built.
If this variable is not set, the combined characters of all mandatory classes will be used.

.PARAMETER Count
The number of strings to generate.

.PARAMETER List
Returns a hash table with the predefined character classes.

.OUTPUTS
System.String or System.String[] (if $Count -gt 0) 

.EXAMPLE
Get-BLRandomString
Will generate a string based on the default classes defined in the script.
No character from a certain set is guaranteed to be in the string.

Get-BLRandomString -Length 16 -Count 100
Will generate 100 strings with a length of 16 characters based on the default classes defined in the script.
No character from a certain set is guaranteed to be in the string.

.EXAMPLE
Get-BLRandomString -Length 8 -Upper -Digit -FirstCharacterClass "ABC"
Will generate a string with a length of 8 characters based on the default classes defined in the script.
The string will start with either A, B, or C.
At least one upper character and one digit will be in the string.

.EXAMPLE
Get-BLRandomString -Length 16 -Digit -Special -DefaultClass "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" -Verbose
Will generate a string with a length of 16 characters.
At least one special character and one digit will be in the string.
The rest of the string will be filled with random alphanumeric characters.

.EXAMPLE
Get-BLRandomString -MandatoryClasses "01234", "56789", "()[]{}<>" -FirstCharacterClass "AEIOU" -DefaultClass "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
Will generate a string with the default length of 12 characters.
The function will display (in the Verbose stream) how the string will be built.
At least one digit from 0-4, one digit from 5-9, and one bracket will be in the string.
The first character will be an uppercase vowel.
The rest of the string will be filled with random alphanumeric characters.

Get-BLRandomString -Length 10KB -DefaultClass "0123456789ABCDEF"
Creates a 10KB string of hexadecimal characters.

#>
[CmdletBinding(DefaultParameterSetName='GetPassword', ConfirmImpact='None')]
[OutputType([String])]
Param(
	[Parameter(Mandatory=$False, Position=0, ParameterSetName='GetPassword')]
	[ValidateRange(1, 4294967295)]
	[uint32]$Length = 12,
	[Parameter(Mandatory=$False, ParameterSetName='GetPassword')]
	[switch]$Upper,
	[Parameter(Mandatory=$False, ParameterSetName='GetPassword')]
	[switch]$Lower,
	[Parameter(Mandatory=$False, ParameterSetName='GetPassword')]
	[switch]$Digit,
	[Parameter(Mandatory=$False, ParameterSetName='GetPassword')]
	[switch]$Special,
	[Parameter(Mandatory=$False, ParameterSetName='GetPassword')]
	[String]$FirstCharacterClass,
	[Parameter(Mandatory=$False, ParameterSetName='GetPassword')]
	[string[]]$MandatoryClasses = @(),
	[Parameter(Mandatory=$False, ParameterSetName='GetPassword')]
	[string]$DefaultClass,
	[Parameter(Mandatory=$False, ParameterSetName='GetPassword')]
	[ValidateRange(1, 4294967295)]
	[uint32]$Count = 1,
	[Parameter(Mandatory=$False, ParameterSetName='GetClassList')]
	[switch]$List
)
	$ScriptCharacterClasses = @{
		'Upper' = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
		'Lower' = 'abcdefghijklmnopqrstuvwxyz'
		'Digit' = '0123456789'
		'Special' = '!"#$%&()*+-./:;<=>?@[\]_{|}' + "'"
	}
	If ($PsCmdlet.ParameterSetName -eq "GetClassList") {
		$ScriptCharacterClasses
		Return
	}
	$MandatoryClassesUsed = @()
	ForEach ($Variable In $ScriptCharacterClasses.Keys) {
		If ((Get-Variable -Name $Variable).Value) {
			$MandatoryClassesUsed += $ScriptCharacterClasses[$Variable]
		}
	}
	$MandatoryClassesUsed += $MandatoryClasses
	If ([string]::IsNullOrEmpty($DefaultClass)) {
		If ($MandatoryClassesUsed.Count -eq 0) {
			$DefaultClassUsed = -join $ScriptCharacterClasses.Values
		} Else {
			$DefaultClassUsed = -join $MandatoryClassesUsed
		}
	} Else {
		$DefaultClassUsed = $DefaultClass
	}
	If ([string]::IsNullOrEmpty($FirstCharacterClass)) {
		"The string will start with a random character from any class." | Write-Verbose
	} Else {
		"The string will start with one of these characters:" | Write-Verbose
		"- $($FirstCharacterClass)" | Write-Verbose
	}
	If ($MandatoryClassesUsed.Count -eq 0) {
		"The string will not contain any mandatory characters." | Write-Verbose
	} Else {
		"The string will contain at least one from each of the following character classes:" | Write-Verbose
		ForEach ($MandatoryClass In $MandatoryClassesUsed) {
			"- $($MandatoryClass)" | Write-Verbose
		}
	}
	"The rest of the string will be built from these characters:" | Write-Verbose
	"- $($DefaultClassUsed)" | Write-Verbose
	
	$MandatoryClassesCount = [int](![string]::IsNullOrEmpty($FirstCharacterClass)) + $MandatoryClassesUsed.Count 
	If ($Length -lt $MandatoryClassesCount) {
		"The string length of $($Length) is not sufficient to use characters from $($MandatoryClassesCount) classes." | Write-Error
		Return
	}
	
	$RandomString = New-Object -TypeName System.Char[] -ArgumentList $Length
	## A function to get the random value would be prettier, but that takes about 15 times as long as the expanded version.
	$RNGCryptoServiceProvider = New-Object -TypeName System.Security.Cryptography.RNGCryptoServiceProvider
	$RandomBytes = New-Object -TypeName System.Byte[] -ArgumentList 4
	$StringCount = $Count
	Do {
		## First fill the complete array with random characters; after that, one random character for each mandatory class will be replaced with the final value.
		$Index = $Length
		Do {
			$RNGCryptoServiceProvider.GetBytes($RandomBytes)
			$RandomString[--$Index] = $DefaultClassUsed[([BitConverter]::ToUInt32($RandomBytes, 0) % $DefaultClassUsed.Length)]
		} Until ($Index -eq 0)
		## This arraylist keeps track of the indexes used for the mandatory classes:
		[System.Collections.ArrayList]$FreeIndexes = 0..($Length - 1)
		## Set the first element from the special class, if so desired:
		If (-not [string]::IsNullOrEmpty($FirstCharacterClass)) {
			$RNGCryptoServiceProvider.GetBytes($RandomBytes)
			$RandomString[0] = $FirstCharacterClass[([BitConverter]::ToUInt32($RandomBytes, 0) % $FirstCharacterClass.Length)]
			$FreeIndexes.Remove(0)
		}
		## Replace random positions of the password for each mandatory class:
		ForEach ($MandatoryClass In $MandatoryClassesUsed) {
			$RNGCryptoServiceProvider.GetBytes($RandomBytes)
			$Index = $FreeIndexes[([BitConverter]::ToUInt32($RandomBytes, 0) % $FreeIndexes.Count)]
			$RNGCryptoServiceProvider.GetBytes($RandomBytes)
			$RandomString[$Index] = $MandatoryClass[([BitConverter]::ToUInt32($RandomBytes, 0) % $MandatoryClass.Length)]
			$FreeIndexes.Remove($Index)
		}
		-join $RandomString
	} Until (--$StringCount -eq 0)
}

Function Get-BLSCCMManagementPoint {
[CmdletBinding()]
Param()
## Old name: SCCM:Get-ManagementPoint
## Retrieves the SMS Client's Management Point
## Returns: IP address of MP if successful,
##          empty string otherwise.
#	"Entering " + $MyInvocation.MyCommand + " at " + (Get-Date).ToLongTimeString() | Write-BLLog -LogType Information
	Try {
		$SMSClient = New-Object -ComObject "Microsoft.SMS.Client" -ErrorAction Stop
		$mp = $SMSClient.GetCurrentManagementPoint()
		[Runtime.InteropServices.Marshal]::FinalReleaseComObject($SMSClient) | Out-Null
	} Catch {
		$mp = ""
		$_.Exception.Message | Out-String | Write-Warning
	}
	Return $mp
}

Function Get-BLSubnetInformation([string]$IPAddress, [string]$SubnetMask) {
## Returns subnet information based on the IP address and netmask.
## No fancy format checks yet due to tiome constraints, so try things like "-IPAddress 256.512.321.789" at your own risk.
	$IPArray = $IPAddress.Split(".")
	$NMArray = $SubnetMask.Split(".")
	$SNArray = @(0, 0, 0, 0)
	$BCArray = @(0, 0, 0, 0)
	$RoutingPrefix = 0
	For ($i = 0; $i -lt 4; $i++) {
		$RoutingPrefix += [regex]::matches(([convert]::ToString($NMArray[$i], 2)), "1").Count
		$SNArray[$i] = [uint32]$IPArray[$i] -band [uint32]$NMArray[$i]
		$BCArray[$i] = [uint32]$IPArray[$i] -bor ((-bnot [uint32]$NMArray[$i]) -band 255)
		
	}
	$Result = "" | Select-Object IPAddress, SubnetMask, Subnet, RoutingPrefix, Broadcast, FirstHost, LastHost
	$Result.IPAddress = $IPAddress
	$Result.SubnetMask = $SubnetMask
	$Result.Subnet = $SNArray -join "."
	$Result.RoutingPrefix = $RoutingPrefix
	$Result.Broadcast = $BCArray -join "."
	If ($SubnetMask -ne "255.255.255.255") {
		$SNArray[3] += 1
		$BCArray[3] -= 1
	}
	$Result.FirstHost = $SNArray -join "."
	$Result.LastHost = $BCArray -join "."
	Return $Result
}

Function Invoke-BLCommandTimeout([uint32]$Timeout, [scriptblock]$ScriptBlock, $ArgumentList) {
## Starts a script block and limits its running time to the timeout specified.
## Any pipeline output of the script block will be put into the pipeline.
## Throws an error if the timeout was reached; use "try {} catch {}" to check the results.
	$Counter = 0
	$Job = Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
	If (-Not $Job) {
		Throw "Could not create the job!"
	}
	Do {
		If ($Job.HasMoreData) {Receive-Job -Job $Job}
		Start-Sleep -Seconds 1
		$Counter += 1
	} While (($Counter -lt $Timeout) -And ($Job.State -ne "Completed"))
	Receive-Job -Job $Job
	Remove-Job -Job $Job -Force
	If ($Counter -ge $Timeout) {
		Throw "Timeout"
	}
}

Function Invoke-BLCommand32Bit([scriptblock]$ScriptBlock, $ArgumentList) {
## Starts a script block in the 32bit environment.
## Any pipeline output of the script block will be put into the pipeline.
	$Job = Start-Job -RunAs32 -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
	If (-Not $Job) {
		Throw "Could not create the job!"
	}
	Receive-Job -Job $Job -Wait
	Remove-Job -Job $Job -Force
}

Function Read-BLHost {
<#
.SYNOPSIS
Reads a line or a single char from the console, and/or checks if a key is available.

.DESCRIPTION
The Read-BLHost function reads a line or character of input from the console. You can use it to prompt a user for input. Because you can save the input as a secure string, you can use this cmdlet to prompt users for secure data, such as passwords, as well as shared data.
If $AsChar is True, the function will return immediately after a single key was pressed.
If $Peek is True, the function does a non-blocking check if a key was pressed.

.PARAMETER Prompt
Specifies the text of the prompt. Type a string. If the string includes spaces, enclose it in quotation marks. Windows PowerShell appends a colon (:) to the text that you enter.

.PARAMETER Bar
Draws the background of the prompt over the whole console width; otherwise only the prompt string will have $BackgroundColor.
Useful (only) if $BackgroundColor differs from the console background color.

.PARAMETER AsSecureString
Displays asterisks (*) in place of the characters that the user types as input.
Returns a System.Security.SecureString.

.PARAMETER AsChar
Waits for a single key press (without requiring <CR>).
Returns (depending on KeyInfo) a System.Char or a System.ConsoleKeyInfo.

.PARAMETER Peek
This call is non-blocking, it does not wait for user input!
Do not forget a "Start-Sleep" if you're querying in a loop.
Returns (depending on KeyInfo) a System.Char or a System.ConsoleKeyInfo if a key was pressed, $Null otherwise.

.PARAMETER NoEcho
Does not echo the characters entered to the console.

.PARAMETER AllowedChars
A string with characters that are allowed as input.
If set, characters entered that are not a part of this string will be ignored, not echoed, and not returned.
It is strongly recommended to inform the user about the characters he is allowed to enter!

.PARAMETER KeyInfo
Returns a System.KeyInfo object instead of a System.Char if Peek or AsChar is selected.
Use this if more precise information about the key is required (like function keys, backspace, modifiers like alt or shift ...).

.PARAMETER KeepBuffer
By default, the keyboard buffer will be cleared before an input query.
In case of Peek, if there were several elements in the buffer when the function was called, only the last character will be returned.
If KeepBuffer is True, the buffer will be kept.

.PARAMETER BackgroundColor
Specifies the background color. There is no default.

.PARAMETER ForegroundColor
Specifies the text color. There is no default.

.INPUTS
None
You cannot pipe input to this cmdlet.

.OUTPUTS
If AsSecure: System.Security.SecureString
If AsChar: System.Char or System.ConsoleKeyInfo, depending on KeyInfo
If Peek and key pressed: System.Char or System.ConsoleKeyInfo, depending on KeyInfo
If Peek and no key pressed: $Null
Otherwise: System.String

.EXAMPLE
Read-BLHost -AsChar
Waits for input of a single character (CR not required)

.EXAMPLE
"Enter X, or wait for 10 seconds"; For ($i = 0; $i -lt 40; $i++) {Start-Sleep -MilliSeconds 250; Write-Host "." -NoNewline;	If (Read-BLHost -Peek -AllowedChars "X") {Break}}
Breaks out of a loop if X is pressed, and ignores all other characters.

.EXAMPLE
Read-BLHost -BackgroundColor DarkRed -ForegroundColor White -Bar -Prompt "Enter 'yes' to confirm something important"
Much like Read-Host, but allows setting fore- and background color like Write-Host, and draws a bar where the input is expected.

.LINK
Read-Host
#>
[CmdletBinding(DefaultParameterSetName="ReadHost")]
Param(
	[Parameter(ParameterSetName="ReadHost")]
	[Parameter(ParameterSetName="AsChar")]
		[string]$Prompt,
	[Parameter(ParameterSetName="ReadHost")]
	[Parameter(ParameterSetName="AsChar")]
		[switch]$Bar,
	[Parameter(ParameterSetName="ReadHost")]
		[switch]$AsSecureString,
	[Parameter(ParameterSetName="AsChar")]
		[switch]$AsChar,
	[Parameter(ParameterSetName="Peek")]
		[switch]$Peek,
	[Parameter(ParameterSetName="Peek")]
	[Parameter(ParameterSetName="AsChar")]
		[switch]$NoEcho,
	[Parameter(ParameterSetName="Peek")]
	[Parameter(ParameterSetName="AsChar")]
		[string]$AllowedChars,
	[Parameter(ParameterSetName="Peek")]
	[Parameter(ParameterSetName="AsChar")]
		[switch]$KeyInfo,
		[switch]$KeepBuffer,
		[ConsoleColor]$ForegroundColor,
		[ConsoleColor]$BackgroundColor
)
	If (($Peek -Or $AsChar) -And ($Host.Name -ne "ConsoleHost")) {
		Throw "The 'Peek' and 'AsChar' arguments of 'Read-BLHost' are only supported in the Default PS Console Host!"
	}
	If ([string]::IsNullOrEmpty($BackgroundColor)) {
		$OldBackgroundColor = $Null
	} Else {
		$OldBackgroundColor = [Console]::BackgroundColor
		[Console]::BackgroundColor = $BackgroundColor
	}
	If ([string]::IsNullOrEmpty($ForegroundColor)) {
		$OldForegroundColor = $Null
	} Else {
		$OldForegroundColor = [Console]::ForegroundColor
		[Console]::ForegroundColor = $ForegroundColor
	}
	If ($Bar) {
		"{0, -$([Console]::WindowWidth - 1)}`r" -f " " | Write-Host -NoNewline
	}
	$Return = $Null
	$PeekConsoleOutputFromBuffer = $False
	If (-Not $KeepBuffer) {
		While ([Console]::KeyAvailable) {
			$Return = [Console]::ReadKey("NoEcho")
			$PeekConsoleOutputFromBuffer = $Peek -And (-Not $NoEcho)
		}
		## Now we've silently cleared everything that was already in the buffer;
		## In case of ReadHost or AsChar, the value now in $Return will be discarded and read again from the keyboard.
		## In case of Peek, $Return will contain the last buffer element, which will then be passed back.
		## Finally, since we now cleared everything silently, we might have to update the console output if Peek is active and echo is enabled.
	}
	If ($Peek -Or $AsChar) {
		$InputRestricted = ![string]::IsNullOrEmpty($AllowedChars)
		If (![string]::IsNullOrEmpty($AllowedChars)) {
			$AllowedChars = $AllowedChars.ToUpper()
		}
		If ($NoEcho -Or $InputRestricted) {
			$ReadKeyOptions = "NoEcho"
		} Else {
			$ReadKeyOptions = ""
		}
		If ($AsChar -And ![string]::IsNullOrEmpty($Prompt)) {
			Write-Host "$($Prompt): " -NoNewline
		}
		Do {
			## If there was something in the keyboard buffer, and we're allowed to clear it, it's now already in $Return.
			## If Peek, AND we're not supposed to clear the buffer, we don't have the return value yet and still need to set it if something is available.
			## If AsChar, we simply discard anything that was already in the buffer.
			If ($AsChar -Or ($Peek -And [Console]::KeyAvailable)) {
				$Return = [Console]::ReadKey($ReadKeyOptions)
			}
			If ($Return) {
				If ($InputRestricted) {
					If ($AllowedChars.IndexOf(([string]$Return.KeyChar).ToUpper()) -ge 0) {
						If (-Not $NoEcho) {
							Write-Host $Return.KeyChar -NoNewline
						}
					} Else {
						Write-Host "!" -NoNewline -ForegroundColor Black -BackgroundColor Red
						Start-Sleep -Milliseconds 250
						Write-Host "$([char]8) $([char]8)" -NoNewline
						$Return = $Null
					}
				} Else {
					If ($PeekConsoleOutputFromBuffer) {
						Write-Host $Return.KeyChar -NoNewline
					}
				}
			}
		} Until ($Return -Or $Peek)
		If ($Return) {
			If (-Not $KeyInfo) {
				$Return = $Return.KeyChar
			}
		}
	} Else {
		$ReadHostOptions = @{}
		If (![string]::IsNullOrEmpty($Prompt)) {$ReadHostOptions["Prompt"] = $Prompt}
		If ($AsSecureString) {$ReadHostOptions["AsSecureString"] = $True}
		$Return = Read-Host @ReadHostOptions
	}
	
	If (![string]::IsNullOrEmpty($OldBackgroundColor)) {
		[Console]::BackgroundColor = $OldBackgroundColor
	}
	If (![string]::IsNullOrEmpty($OldForegroundColor)) {
		[Console]::ForegroundColor = $OldForegroundColor
	}
	Return $Return
}

Function Split-BLDistinguishedName {
<#
.SYNOPSIS
Returns the specified part of a distinguished name.

.DESCRIPTION
The function Split-BLDistinguishedName returns only the specified part of a distinguished name, such as the parent container or OU, or the leaf name.
The script does not implement the full definition of RFC 4514; currently, only the attribute types CN, DC, OU are supported.
This script is similar to Split-Path.

.PARAMETER Path
Specifies the distinguished name to be split. If the path includes spaces, enclose it in quotation marks. You can also pipe a path to Split-BLDistinguishedName.

.PARAMETER Parent
Returns only the parent containers of the item specified by the path. For example, in the path "CN=Doe\, John,CN=Users,DC=acme,DC=com", it returns "CN=Users,DC=acme,DC=com". The Parent parameter is the default split location parameter.

.PARAMETER Leaf
Returns only the first item or container in the path. For example, in the path "CN=Doe\, John,CN=Users,DC=acme,DC=com", it returns only "CN=Doe\, John".

.PARAMETER FormattedLeaf
Returns only the first item or container in the path, unescapes characters, and removes the "CN=" or "OU=". For example, in the path "CN=Doe\, John,CN=Users,DC=acme,DC=com", it returns "Doe, John".

.PARAMETER Qualifier
Returns only the qualifier of the specified path. The qualifier in this script is the path built by the domain components, such as "DC=acme,DC=com". For example, in the path "CN=Doe\, John,CN=Users,DC=acme,DC=com", it returns "DC=acme,DC=com".

.PARAMETER NoQualifier
Returns the path without the qualifier. The qualifier in this script is the path built by the domain components, such as "DC=acme,DC=com". For example, in the path "CN=Doe\, John,CN=Users,DC=acme,DC=com", it returns only "CN=Doe\, John,CN=Users".

.INPUTS
System.String
You can pipe a string that contains a path to Split-BLDistinguishedName.

.OUTPUTS
System.String

.EXAMPLE
Split-BLDistinguishedName "CN=Doe\, John,CN=Users,DC=acme,DC=com" -Qualifier
DC=acme,DC=com
This command returns only the domain components of the path.

.EXAMPLE
Split-BLDistinguishedName "CN=Doe\, John,CN=Users,DC=acme,DC=com" -NoQualifier
CN=Doe\, John,CN=Users
This command removes the domain components of the path.

.EXAMPLE
Split-BLDistinguishedName "CN=Doe\, John,CN=Users,DC=acme,DC=com" -Parent
CN=Users,DC=acme,DC=com
This command returns the parent of the leaf object.

.EXAMPLE
Split-BLDistinguishedName "CN=Doe\, John,CN=Users,DC=acme,DC=com" -Leaf
CN=Doe\, John
This command returns the leaf object.

.EXAMPLE
Split-BLDistinguishedName "CN=Doe\, John,CN=Users,DC=acme,DC=com" -FormattedLeaf
Doe, John
This command returns the leaf object wit unescaped characters and without the attribute type.


.NOTES
The split location parameters (Qualifier, Parent, Leaf, FormattedLeaf, and NoQualifier) are exclusive. You can use only one in each command.
    
#>
[CmdletBinding(DefaultParameterSetName="Split_By_Parent")]
Param(
	[Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Position=0)][ValidateNotNull()]
	[string[]]$Path,
	[Parameter(ParameterSetName="Split_By_Parent")]
	[switch]$Parent,
	[Parameter(ParameterSetName="Split_By_Leaf")]
	[switch]$Leaf,
	[Parameter(ParameterSetName="Split_By_FormattedLeaf")]
	[switch]$FormattedLeaf,
	[Parameter(ParameterSetName="Split_By_Qualifier")]
	[switch]$Qualifier,
	[Parameter(ParameterSetName="Split_Without_Qualifier")]
	[switch]$NoQualifier
)
	Begin {
	}
	Process {
		$Path |
			% {
				$PathComponents = $_ -split '(?<!\\),'
				Switch ($PsCmdlet.ParameterSetName) {
					"Split_By_Parent" {
						$PathComponents[1..($PathComponents.Count-1)] -join ',' | Write-Output
					}
					"Split_By_Leaf" {
						$PathComponents[0] | Write-Output
					}
					"Split_By_FormattedLeaf" {
						$PathComponents[0].Split("=", 2)[1] -replace '\\(.)', '$1' | Write-Output
					}
					"Split_By_Qualifier" {
						($PathComponents | ? {$_.ToLower().StartsWith('dc=')}) -join ',' | Write-Output
					}
					"Split_Without_Qualifier" {
						($PathComponents | ? {!$_.ToLower().StartsWith('dc=')}) -join ',' | Write-Output
					}
				}
			}
	}
	End {
	}
}

Function Test-BLPSHostTranscription() {
## Tests if the PS host supports transcription
	Try {
		$ExternalHost = $Host.GetType().GetProperty("ExternalHost", [reflection.bindingflags]"NonPublic,Instance").GetValue($Host, @())
		$ExternalHost.GetType().GetProperty("IsTranscribing", [reflection.bindingflags]"NonPublic,Instance").GetValue($ExternalHost, @()) | Out-Null
		Return $True
	} Catch {
		Return $False
	}
}

Function Test-BLPSHostWriteHost() {
## Tests if the PS host supports Write-Host
	Try {
		$ExternalHost = $Host.GetType().GetProperty("ExternalHost", [reflection.bindingflags]"NonPublic,Instance").GetValue($Host, @())
		$ExternalHost.GetType().GetProperty("ConsoleTextWriter", [reflection.bindingflags]"NonPublic,Instance").GetValue($ExternalHost, @()) | Out-Null
		Return $True
	} Catch {
		Return ($Host.UI.RawUI.CursorPosition -ne $Null)
	}
}

Function Test-BLRegularExpression {
## Tests if the string passed is a valid regular expression.
## Returns $True or $False if -PassThru is $False
## if PassThru is true, returns a regular expression if successful, $Null otherwise
[CmdletBinding()]
Param(
	[Parameter(ValueFromPipeline=$True)]
	[string]$String,
	[Parameter()]
	[switch]$PassThru
)
	Process {
		Try {
			If ([string]::IsNullOrEmpty($String)) {
				Throw "Required argument 'String' is empty!"
			}
			If ($PassThru) {
				$Result = [regex]$String
			} Else {
				[regex]$String | Out-Null
				$Result = $True
			}
		} Catch {
			$_.Exception.Message | Write-Error
			If ($PassThru) {
				$Result = $Null
			} Else {
				$Result = $False
			}
		}
		$Result | Write-Output
	}
}

## ====================================================================================================
## Group "Active Directory"
## Functions that do NOT require the use of AD PS Cmdlets, so they can be run on any machine against AD.
## ====================================================================================================

Function Get-BLADDomainController([switch]$Verbose) {
## Returns the FQDN of an available domain controller for the domain the machine is in.
## Priority: 1. itself (if DC), 2. PDC emulator, 3. First DC responding to a ping.
## Error: returns $Null
	$ADDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
	If ($Verbose) {
		"Domain Controllers for this domain:" | Write-BLLog
		ForEach ($DC In $ADDomain.DomainControllers) {
			"- $($DC.Name)" | Write-BLLog
		}
	}
	## Check if running on a DC; if so, return own name.
	ForEach ($DC In $ADDomain.DomainControllers) {
		If ($DC.Name -eq "${ENV:ComputerName}.$($ADDomain.Name)") {
			If ($Verbose) {
				"This computer is a Domain Controller." | Write-BLLog
			}
			Return $DC.Name
		}
	}
	If ($Verbose) {
		"This computer is not a Domain Controller; trying PDCe ..." | Write-BLLog
	}
	## Check if PDCe responds; return it if this is the case.
	If (Test-Connection -ComputerName $ADDomain.PdcRoleOwner.Name -Count 2 -Quiet) {
		If ($Verbose) {
			"PDCe $($ADDomain.PdcRoleOwner.Name) responding." | Write-BLLog
		}
		Return $ADDomain.PdcRoleOwner.Name
	}
	If ($Verbose) {
		"PDCe not responding, looking for another DC ..." | Write-BLLog
	}
	## Look for any other responding DC
	ForEach ($DC In $ADDomain.DomainControllers) {
		If ($DC.Name -ne $ADDomain.PdcRoleOwner.Name) {
			If (Test-Connection -ComputerName $DC.Name -Count 2 -Quiet) {
				If ($Verbose) {
					"Domain Controller $($DC.Name) responding." | Write-BLLog
				}
				Return $DC.Name
			}
		}
	}
	If ($Verbose) {
		"No Domain Controller responded." | Write-BLLog
	}
	Return $Null
}

Function Get-BLADPreferredBridgehead {
<#
.SYNOPSIS
Returns a list of preferred bridgeheads (IP transport only).

.DESCRIPTION
The function Get-BLADPreferredBridgehead returns a list of preferred bridgeheads (IP transport only).
The list might be empty.
To check for errors, compare $Error.Count from before the call and after the call.
Note: this will only return preferred bridgeheads, not the currently used bridgeheads determined by the KCC!

.PARAMETER Domain
Optional
The FQDN of the domain for which to retrieve the preferred bridgeheads.

.EXAMPLE
Get-BLADPreferredBridgehead

#>
[CmdletBinding()]
Param (
	[string]$Domain
)
	$ComputerDomain = Get-WmiObject -Query "SELECT Domain, PartOfDomain FROM Win32_ComputerSystem"
	If (-Not $ComputerDomain.PartOfDomain) {
		Throw "This computer is not part of a domain!"
	}
	If ([string]::IsNullOrEmpty($Domain)) {
		$Domain = $ComputerDomain.Domain
	}
	$DomainDN =	"DC=" + $Domain.Replace('.', ',DC=')
	## If something goes wrong with [ADSI], there will be something returned that is almost, but not quite, entirely unlike the System.DirectoryServices.DirectoryEntry expected on success.
	## "-is [System.DirectoryServices.DirectoryEntry]" will return $True, but a .GetType() will result in the error that ADSI ran into.
	$IPTransports = [ADSI]"LDAP://CN=IP,CN=Inter-Site Transports,CN=Sites,CN=Configuration,$($DomainDN)"
	If ((Get-Member -InputObject $IPTransports | Select-Object -ExpandProperty Name) -contains "whenCreated") {
		## The object returned looks good; break the System.DirectoryServices.PropertyValueCollection returned into strings
		$IPTransports.bridgeheadServerListBL | % {$_ | Write-Output}
	} Else {
		## Couldn't find the expected property "whenCreated", so the ADSI call failed.
		## Provoke an exception that can be trapped, and return the message.
		Try {
			$IPTransports.GetType() | Out-Null
		} Catch {
			$Error[0].Exception.InnerException.Message | Write-Error
		}
	}
}

Function Get-BLADUser([string]$SamAccountName, [switch]$ADO, [array]$AttributeList = @()) {
## Returns a user (not compatible with Get-ADUser)
## Default is to use the WinNT provider.
## If -ADO is enabled, the query will be done with the DS ADO provider; a list of attributes to return can then be passed.
	Try {
		If (-Not $ADO) {
			$ADUser = [ADSI]"WinNT://$(Get-BLComputerDomain)/$($SamAccountName)"
		} Else {
			If ($AttributeList.Count -eq 0) {
				$AttributeList = @(
					"distinguishedName"
					"givenName"
					"name"
					"objectClass"
					"objectGUID"
					"sAMAccountName"
					"objectSid"
					"sn"
					"userPrincipalName"
				)
			}
			$RootDSE = [ADSI]"LDAP://RootDSE"
			$ADODBConnection = New-Object -ComObject "ADODB.Connection"
			$ADODBConnection.Provider = "ADsDSOObject"
			$ADODBConnection.Open("Active Directory Provider")
			$ADODBCommand = New-Object -ComObject "ADODB.Command"
			$ADODBCommand.ActiveConnection = $ADODBConnection
			$BaseDN = "LDAP://$($RootDSE.defaultNamingContext)"
			$Filter = "(&(objectCategory=person)(objectClass=user)(samaccountname=$SamAccountName))"
			$Attributes = $AttributeList -Join ","
			$Query = "<" + $BaseDN + ">;" + $Filter + ";" + $Attributes + ";subtree"
			$ADODBCommand.CommandText = $Query
			$ADODBCommand.Properties.Item("Page Size").Value = 1000
			$ADODBCommand.Properties.Item("Timeout").Value = 60
			$ADODBCommand.Properties.Item("Cache Results").Value = $False
			$RecordSet = $ADODBCommand.Execute()
			If ($RecordSet.EOF) {
				Throw "User '$SamAccountName' not found!"
			}
			$ADUser = New-Object Object
			ForEach ($Attribute In $AttributeList) {
				$ADUser | Add-Member -MemberType "NoteProperty" -Name $Attribute -Value $RecordSet.Fields.Item($Attribute).Value
			}
		}
	} Catch {
		$ADUser = $Null
		$_ | Out-String | Write-BLLog -LogType CriticalError
	} Finally {
		If ($RecordSet) {$RecordSet.Close()}
		If ($ADODBCommand) {
			[Runtime.InteropServices.Marshal]::FinalReleaseComObject($ADODBCommand) | Out-Null
		}
		If ($ADODBConnection) {
			$ADODBConnection.Close()
			[Runtime.InteropServices.Marshal]::FinalReleaseComObject($ADODBConnection) | Out-Null
		}
	}
	Return $ADUser
}

## ====================================================================================================
## Group "Forms and UI"
## ====================================================================================================
Function Read-BLUIMessageBox {
<#
.SYNOPSIS
Shows a message box and returns the user input.

.DESCRIPTION
The function Show-BLMessageBox shows a message box and returns the user input.
The message box is script modal.

.PARAMETER Text
Optional
The text to display inside the message box.

.PARAMETER Caption
Optional
The window title of the message box.

.PARAMETER Icon
<System.Windows.Forms.MessageBoxIcon>
Optional
The icon to show at the left of the text.
    - None:        No icon.
    - Hand:        A white X in a circle with a red background.
    - Error:       A white X in a circle with a red background.
    - Stop:        A white X in a circle with a red background.
    - Question:    A question mark in a circle. [...] it does not clearly represent a specific type of message [...] Therefore, do not use this question mark message symbol in your message boxes.
    - Exclamation: An exclamation point in a triangle with a yellow background.
    - Warning:     An exclamation point in a triangle with a yellow background.
    - Asterisk:    A lowercase letter i in a circle.
    - Information: A lowercase letter i in a circle.

.PARAMETER Buttons
<System.Windows.Forms.MessageBoxButtons>
Optional
The buttons to show.
    - OK
    - OKCancel
    - AbortRetryIgnore
    - YesNoCancel
    - YesNo
    - RetryCancel
The button names displayed will be localized to the user's UI language.

.PARAMETER DefaultButton
<System.Windows.Forms.MessageBoxDefaultButton>
Optional
The button that has the focus (from left to right).
    - Button1
    - Button2
    - Button3

.OUTPUTS
System.String
Depending on the available buttons:
    - None
    - OK
    - Cancel
    - Abort
    - Retry
    - Ignore
    - Yes
    - No

.EXAMPLE
$Result = Read-BLUIMessageBox -Text "OK to continue?" -Caption "Confirm" -Buttons OKCancel -Icon Exclamation -DefaultButton Button1

.LINK
MessageBox.Show Method: http://msdn.microsoft.com/en-us/library/system.windows.forms.messagebox.show.aspx
System.Windows.Forms.MessageBoxButtons: http://msdn.microsoft.com/en-us/library/system.windows.forms.messageboxbuttons.aspx
System.Windows.Forms.MessageBoxIcon: http://msdn.microsoft.com/en-us/library/system.windows.forms.messageboxicon.aspx
System.Windows.Forms.DialogResult: http://msdn.microsoft.com/en-us/library/system.windows.forms.dialogresult.aspx
System.Windows.Forms.MessageBoxDefaultButton: http://msdn.microsoft.com/en-us/library/system.windows.forms.messageboxdefaultbutton.aspx

#>
[CmdletBinding()]
Param(
	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$true, Position=0)]
	[string]$Text = "",
	[Parameter(Position=1)]
	[string]$Caption = "",
	[Parameter(Position=2)]
	[System.Windows.Forms.MessageBoxButtons]$Buttons = "OK",
	[Parameter(Position=3)]
	[System.Windows.Forms.MessageBoxIcon]$Icon = "None",
	[Parameter(Position=4)]
	[System.Windows.Forms.MessageBoxDefaultButton]$DefaultButton = "Button1"
)
	Begin {
		If (-Not [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")) {
			Throw "Could not load required assembly 'System.Windows.Forms'!"
		}
	}
	Process {
		If ($Result = [System.Windows.Forms.MessageBox]::Show([BLWin32Window]::CurrentWindow, $Text, $Caption, $Buttons, $Icon, $DefaultButton)) {
			$Result.ToString() | Write-Output
		}
	}
	End {
	}
}

## ====================================================================================================
## Group "New from old BaseLibrary"
## ====================================================================================================

Function Import-BLConfigDB {
## Old name: ImportCFGzip.cmd
## Imports the CFG-zip file
	# TODO
}

Function Get-BLMultiValue ($Cfg, $Pattern) {
## Old name: function get_MultiValue( $Cfg, $Pattern)
## Gets the values of multiline config item
	$cfg.GetEnumerator() | Where { $_.Key -match $Pattern } | sort -Property Key
}

Function Enable-BLRemoteDesktopConfig {
## Old name: function Set-RemoteDesktopConfig
## Enables RDP
	(Get-WmiObject "Win32_TerminalServiceSetting" -Namespace root\CIMV2\terminalservices).SetAllowTSConnections(1)
}

Function Disable-BLIPv6 {
## Old name: function disableIPv6()
## Disables IPv6
	New-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\services\TCPIP6\Parameters" -Name "DisabledComponents" -Value 0xffffffff -PropertyType "DWord"
}

Function Disable-BLFirewall {
## Old name: function deactivateFirewall()
## Disables the firewall
	netsh advfirewall set AllProfiles state off
}

Function Set-BLDriveLetters {
## Old name: function setDriveLetters()
## Sets the CD-ROM drive letters
	cscript /nologo C:\RIS\Install\setDriveLetters.vbs
}

Function Set-BLPageFileSize ([int]$pfsize=4096){
## Old name: function setPagefileSize($pfsize=4096)
## Sets the size of the page file
	"Setting Pagefile size to $pfsize MB"
	$System = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
	$System.AutomaticManagedPagefile = $False
	$System.Put()
	$CurrentPageFile = Get-WmiObject -query "select * from Win32_PageFileSetting where name='c:\\pagefile.sys'"
	$CurrentPageFile.InitialSize = [int]$pfsize
	$CurrentPageFile.MaximumSize = [int]$pfsize
	$CurrentPageFile.Put()
}

Function Dismount-BLISOFiles {
## Old name: dismISO.ps1
## Dismounts all ISOs mounted in all VMs on this host
	"Dismounting all ISOs from running VMs" | Write-BLLog -LogType Information
	Get-VMDvdDrive -Vmname * | ? {$_.DvdMediaType -ne "None"} | Write-BLLog -LogType Information
	Get-VMDvdDrive -Vmname * | ? {$_.DvdMediaType -ne "None"} | Set-VMDvdDrive -Path $null
## Test if the Error will be catched
	if($?){
		"ISOs successfully dismounted" | Write-BLLog -LogType Information
	}else{
		"Some error occurred!" | Write-BLLog -LogType CriticalError
	}
}

Function Get-BLNetmask ([int]$x) {
## Help-function for Function Set-BLIPConfig
   $local:msk = 0x80000000L
   $local:result = 0;
   while ($x -gt 0)
   {
      $result += $msk
      $msk /= 2
      $x--
   }
  $result = "{0:x8}" -f $result
  
  return [string][int]("0x"+$result.substring(0,2)) + "." + [string][int]("0x"+$result.substring(2,2)) +
         "." + [string][int]("0x"+$result.substring(4,2)) + "." + [string][int]("0x"+$result.substring(6,2))
}
    
Function Set-BLAdapterIP ($sVal) {
## Help-function for Function Set-BLIPConfig
    if ($sVal)
    {
    	$local:aV = $sVal -split ","
        $local:IP = $av[0] -split "/"
        $local:GW = $av[1]
        $local:NameFilter = $av[2].Replace("*", ".*")

        $local:NetMask = Get-BLNetmask([int]$IP[1])
        $local:IP = $IP[0]
        
        #$a = Get-WmiObject -class  Win32_NetworkAdapter -Filter "NetConnectionID like '$NameFilter'"
        Get-WmiObject -class  Win32_NetworkAdapter | where { $_.NetConnectionID -match "$NameFilter" } | foreach { 
            $local:idx = $_.Index
            write-host ("NIC:" +  $_.NetConnectionID + " ==> $IP/$Netmask $GW" )
            $local:a = Get-WmiObject -class  Win32_NetworkAdapterConfiguration -Filter "Index = $idx"
            $a.EnableStatic($IP, $Netmask) | out-null
            if (!$?) {
				Write-Host "ERROR in EnableStatic()"
				$ExitCode = 1
			}
            if ($GW)
            {
                $a.SetGateways($GW,20) | out-null
                if (!$?) {
					Write-Host "ERROR in SetGateways()"
					$ExitCode = 1
				}
            }
            if ($DNS_SERVERS)
            {
                $a.SetDNSServerSearchOrder($DNS_SERVERS -split " ") | out-null
                if (!$?) { 
					Write-Host "ERROR in SetDNSServerSearchOrder()"
					$ExitCode = 1
				}
            }
        }
	}
}

Function Set-BLIPConfig ($cfgThis) {
## Old name: SetIPconfig.ps1
## Sets up the IP configuration
	If ($ExitCode -ne 0) {
		"Error setting variables from ConfigDB, unable to continue!" | Write-BLLog -LogType CriticalError
		SCCM:FollowUp-Installation -SetExitCode $ExitCode
	}

	$DNS_SERVERS = $cfgThis["DNS_SERVERS"]

	# für alle bekannten NIC-Variablen   "ISCSI_BOOT_NIC", wird außen vor gelassen (im BIOS gesetzt)
	"CLUSTER_NIC","ISCSI_DATA_NIC","LIVEMIGRATION_NIC","MGMT_NIC", `
		"VM_VNET_1","VM_VNET_2","VM_VNET_3","VM_VNET_4" ,"VM_VNET_5" | foreach { Set-BLAdapterIP($cfgThis["COMPUTER_" + $_]) }
}

Function Set-BLDNSServers ($cfgThis) {
## Old name: function setDNSServers()
## Sets up the DNS server entries in TCP/IP config
	$dnsservers = $cfgThis.DNS_SERVERS.split(" ")
	$dnsservers
	Get-WmiObject win32_networkadapterconfiguration -filter "ipenabled = 'true'" |
	   foreach { $_ ; $_.SetDNSServerSearchOrder($dnsservers) }
}

Function Set-BLNICNames ($cfgThis) {
## Old name: function setNICNames()
## Renames the LAN adapters applying the ConfigDB
	"Set names of physical NICs"
	# $PCI2NIC = "1 0 1 ISCSI;1 0 0 MGGMT;4 0 0 STORAGE;4 0 1 LIVEMIGRATION"
	$local:PCI2NIC = $cfgThis["COMPUTER_PCI2NICNAME"]
	if ($PCI2NIC -ne "") {
		foreach ($OneNIC in ($PCI2NIC -split ";")) {
			"Set Device:$OneNIC"
			Set-BLNICName $OneNIC
		}
	}
}

Function Set-BLNICName ($location) {
## Help-function for Function Set-BLIPConfig
## Old name: function Set-NicName($location)
## Help-function for Set-BLNICNames
	# Mit dieser Funktion werden die LAN-Verbindungen umbenannt nach der Belegung des PCI-Busses
	# "1 0 1 ISCSI"
	$local:params = $location -split " "
	$local:searchPCI = "PCI bus " + $params[0] + ", device " + $params[1] + ", function " + $params[2]
	$local:nicInfo = Get-WMIObject -query "select * from Win32_PnPSignedDriver where Location='$searchPCI'"

	if ($nicinfo -and $params[3]) {
		$nic = Get-WMIObject Win32_NetworkAdapter | ?{$_.PNPDeviceID -eq $nicInfo.DeviceID}
		if ($nic) {
			$nic.NetConnectionID = $params[3]
			$local:wegdamit = $nic.Put()
            $nic | select Caption,NetConnectionID
		}
	}
}

Function Get-BLGeneratedMAC ($ip) {
## Old name: function genMAC($ip)
## Generates a MAC address
	#Generate MAC from IP: # MAC Prefix: "A00A"
	$ipa = $ip -split ".",4,"SimpleMatch"
	"A00A" + "{0:X2}" -f [int]$ipa[0] + "{0:X2}" -f [int]$ipa[1] + "{0:X2}" -f [int]$ipa[2] + "{0:X2}" -f [int]$ipa[3]
}

Function Rename-BLCSV {
## Old name: rename_CSV.ps1
## Renames the CSVs
	Import-Module FailoverClusters
	$objs = @()
	$csvs = Get-ClusterSharedVolume
	foreach ( $csv in $csvs ) {
		$Signature     = ( $csv | Get-ClusterParameter DiskSignature ).Value.substring(2)
		$LUN         = ( Get-WmiObject Win32_DiskDrive | Where { "{0:x}" -f $_.Signature -eq $Signature } ).SCSILogicalUnit
		$CSVPath       = ( $csv | select -Property Name -ExpandProperty SharedVolumeInfo).FriendlyVolumeName  

		$NewLUNFullPath = "C:\ClusterStorage\LUN$LUN"

		If ($CSVPath -ne $NewLUNFullPath) {
			write-Host "The folder '$CSVPath' will be renamed to '$NewLUNFullPath'`r"
			ren $CSVPath $NewLUNFullPath
		} Else {
			write-host "$NewLUNFullPath already exists`r"
		}
	}
}

Function Disable-BLUAC {
	"Disabling UAC"
	New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 0 -Force
	If ($?) {
		"SUCCESS"
	} Else {
		"FAILURE"
		$Global:exitCode += 1
	}
}

Function Disable-BLSMStartup {
	"Disabling ServerManagerAtLogon"
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager" -Name "DoNotOpenServerManagerAtLogon" 1
	If ($?) {
		"SUCCESS"
	} Else {
		"FAILURE"
		$Global:exitCode += 1
	}
}

Function Set-BLAutoAdminLogon {
	"Enabling AutoAdminLogon"
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WInlogon" -Name "AutoAdminLogon" -Value 1
	If ($?) {
		"SUCCESS"
	} Else {
		"FAILURE"
		$Global:exitCode += 1
	}
}

Function Set-BLRemoteDesktop {
	"Enabling Remote Desktop"
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -Value 0 -Force
	If ($?) {
		"SUCCESS"
	} Else {
		"FAILURE"
		$Global:exitCode += 1
	}
}

Function Disable-BLFirewall {
	"Disabling Firewall"
	Get-NetFirewallProfile | Set-NetFirewallProfile -Enabled False
	If ($?) {
		"SUCCESS"
	} Else {
		"FAILURE"
		$Global:exitCode += 1
	}
}

Function Expand-BLZipFile ($file, $destination) {
	"Expanding ZIP file $file to $destination"
	$shell = New-object -com shell.application
	$zip = $shell.NameSpace($file)
	foreach($item in $zip.items())
	{
		$shell.Namespace($destination).copyhere($item)
	}
}


## ====================================================================================================
## Export functions and variables
## ====================================================================================================
## Host capabilities
$BL_PSHost.SupportsTranscription = Test-BLPSHostTranscription
$BL_PSHost.SupportsWriteHost = Test-BLPSHostWriteHost
$BL_PSHost.SupportsWindowTitle = If ($Host.UI.RawUI.WindowTitle -eq $Null) {$False} Else {$True}

## Legacy: used for backward compatibility after adding Get-BLAccountFromSID and renaming Get-BLSID to Get-BLSIDFromAccount
New-Alias -Name Get-BLSID -Value Get-BLSIDFromAccount
Initialize-BLCustomTypes

Export-ModuleMember -Function `
	Add-BLLocalAdminGroupMember,
	Add-BLLocalGroupMember,
	Compare-BLDirectory,
	Compare-BLWmiNamespace,
	Compress-BLString,
	ConvertTo-BLBool,
	ConvertFrom-BLEvt,
	ConvertFrom-BLSecureString,
	ConvertTo-BLStringBitmask,
	Copy-BLArchiveContent,
	Copy-BLWindowsCertToJava,
	Disable-BLGeneratePublisherEvidence,
	Enter-BLExecutionAsTask,
	Exit-BLFunctions,
	Expand-BLString,
	Export-BLConfigDBConvertedTemplateFile,
	Export-BLIniFile,
	Format-BLHashTable,
	Format-BLXML,
	Get-BLAccountFromSID,
	Get-BLAccountsWithUserRight,
	Get-BLADDomainController,
	Get-BLADPreferredBridgehead,
	Get-BLAdsiObject,
	Get-BLADUser,
	Get-BLComputerBootTime,
	Get-BLComputerDomain,
	Get-BLComputerPendingReboot,
	Get-BLConfigDBCfgList,
	Get-BLConfigDBConvertedTemplate,
	Get-BLConfigDBUAFile,
	Get-BLConfigDBVariables,
	Get-BLConfigDBLocation,
	Get-BLConfigDBUAFile,
	Get-BLCredentialManagerPolicy,
	Get-BLCredentials,
	Get-BLDfsrReplicatedFolderInfo,
	Get-BLDnsSrvRecord,
	Get-BLDotNetFrameworkVersions,
	Get-BLDVDDrives,
	Get-BLEnvironmentVariable,
	Get-BLExecutionAsTaskStatus,
	Get-BLFullPath,
	Get-BLHashFromFile,
	Get-BLHashFromString,
	Get-BLHyperVHostingServer,
	Get-BLIniHTContent,
	Get-BLIniHTSection,
	Get-BLIniHTSectionNames,
	Get-BLIniHTValue,
	Get-BLIniKey,
	Get-BLInternetExplorerVersion,
	Get-BLInternetZoneFromUrl,
	Get-BLInternetZoneMappings,
	Get-BLLocalGroupMembers,
	Get-BLLocalUser,
	Get-BLLogFileName,
	Get-BLLogFolder,
	Get-BLLogonSession,
	Get-BLMsiProperties,
	Get-BLNetInterfaceIndex,
	Get-BLNetRoute,
	Get-BLOSArchitecture,
	Get-BLOSVersion,
	Get-BLPrimaryDNSSuffix,
	Get-BLRandomString,
	Get-BLRDSApplicationMode,
	Get-BLRDSGracePeriodDaysLeft,
	Get-BLRegistryHiveX64,
	Get-BLRegistryKeyX64,
	Get-BLRegistryValueX64,
	Get-BLSCCMManagementPoint,
	Get-BLScheduledTask,
	Get-BLScriptLineNumber,
	Get-BLShortcut,
	Get-BLShortPath,
	Get-BLSIDFromAccount,
	Get-BLSpecialFolder,
	Get-BLSubnetInformation,
	Get-BLSymbolicLinkTarget,
	Get-BLUninstallInformation,
	Get-BLUserRightsForAccount,
	Grant-BLUserRights,
	Import-BLIniFile,
	Import-BLRegistryFile,
	Initialize-BLFunctions,
	Install-BLWindowsHotfix,
	Install-BLWindowsLanguagePack,
	Install-BLWindowsRoleOrFeature,
	Invoke-BLCommand32Bit,
	Invoke-BLCommandTimeout,
	Invoke-BLBatchFile,
	Invoke-BLPowershell,
	Invoke-BLSetupInno,
	Invoke-BLSetupInstallShield,
	Invoke-BLSetupInstallShieldPFTW,
	Invoke-BLSetupMsi,
	Invoke-BLSetupNSIS,
	Invoke-BLSetupOther,
	Invoke-BLSetupWise,
	Invoke-BLTimeoutCommand,
	New-BLLocalUser,
	New-BLRegistryKey,
	New-BLRegistryKeyX64,
	New-BLShortcut,
	New-BLUninstallEntry,
	Out-BLIniHT,
	Read-BLHost,
	Read-BLUIMessageBox,
	Remove-BLIniHTKey,
	Remove-BLIniHTSection,
	Remove-BLIniCategory,
	Remove-BLIniKey,
	Remove-BLInternetZoneMapping,
	Remove-BLLocalGroupMember,
	Remove-BLLocalUser,
	Remove-BLRegistryKeyX64,
	Remove-BLRegistryValueX64,
	Remove-BLScheduledTask,
	Remove-BLShortcut,
	Remove-BLUninstallEntry,
	Remove-BLUserProfile,
	Resolve-BLSid,
	Revoke-BLUserRights,
	Set-BLConfigDBLocation,
	Set-BLCredentialManagerPolicy,
	Set-BLEnvironmentPATH,
	Set-BLEnvironmentVariable,
	Set-BLExecutionAsTaskExitCode,
	Set-BLExecutionAsTaskStatus,
	Set-BLIniHTSection,
	Set-BLIniHTValue,
	Set-BLIniKey,
	Set-BLInternetZoneMapping,
	Set-BLLocalUser,
	Set-BLLogDebugMode,
	Set-BLLogLevel,
	Set-BLRDSExecuteMode,
	Set-BLRDSInstallMode,
	Set-BLRegistryValueX64,
	Set-BLScheduledTask,
	Set-BLServiceCredentials,
	Set-BLServiceStartup,
	Show-BLUserRightsInformation,
	Show-BLWellKnownSidsInformation,
	Split-BLConfigDBAccountVariable,
	Split-BLConfigDBElementList,
	Split-BLDistinguishedName,
	Start-BLProcess,
	Stop-BLExecutionAsTask,
	Test-BLConfigDBLocation,
	Test-BLElevation,
	Test-BLHyperVGuest,
	Test-BLOSVersion,
	Test-BLPSHostTranscription,
	Test-BLPSHostWriteHost,
	Test-BLRegularExpression,
	Test-BLSid,
	Uninstall-BLWindowsHotfix,
	Update-BLExceptionInvocationInfo,
	Update-BLLibraryScript,
	Write-BLConfigDBSettings,
	Write-BLEventLog,
	Write-BLLog,
	
	Import-BLConfigDB,
	Get-BLMultiValue,
	Enable-BLRemoteDesktopConfig,
	Disable-BLIPv6,
	Disable-BLFirewall,
	Set-BLDriveLetters,
	Set-BLPageFileSize,
	Dismount-BLISOFiles,
	Get-BLNetmask,
	Set-BLAdapterIP,
	Set-BLIPConfig,
	Set-BLDNSServers,
	Set-BLNICNames,
	Get-BLGeneratedMAC,
	Rename-BLCSV

Export-ModuleMember -Variable `
	BL_CFGDB_ServiceName,
	BL_CFGDB_VirtualFolderCfg,
	BL_CFGDB_VirtualFolderUA,
	BL_OSVersion,
	BL_PSHost,
	BL_SpecialFolder,
	BL_WUA_RESULT_CODES,
	CFG_ConfigVirtualFolder
	
Export-ModuleMember -Alias `
	Get-BLSID