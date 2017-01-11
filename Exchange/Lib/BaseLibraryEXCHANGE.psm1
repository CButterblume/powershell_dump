## --------------------------------------------------------------------------------------
## File                 : BaseLibraryEXCHANGE.psm1
##                        -----------------------------
## Purpose              : Contains library functions for the Packages which starts with MS_EXCH2013 (at the moment Microsoft Exchange 2013 incl. CU12)
##                        
## Syntax               : import-module C:\RIS\Lib\BaseLibraryEXCHANGE
##
## Prerequirements      : Uses C:\RIS\Lib\BaseLibrary.psm1
##
## Common Noun prefix for functions in this library: BLEX
##
## Version Mngt
## ============
## Date				Version by			Change Description
## ------------------------------------------------------------------------------------------------------------------
## 30.06.2016		S. Schmalz (IF)		Initial creation
## 30.06.2016		S. Schmalz (IF)		Function Start-BLEXService and Stop-BLEXService sourced out
## 07.09.2016		S. Schmalz (IF)		Function Restart-BLEXService returned nothing. Added a "return 0"
##						on line 310
##
##									
## ------------------------------------------------------------------------------------------------------------------
#region function Start-BLEXService
Function Start-BLEXService {
<#
.SYNOPSIS
The function starts a service on the local machine.

.DESCRIPTION
The function Start-BLEXService starts a service on the local machine. 

.PARAMETER 
ServiceName is mandatory

.INPUTS
ServiceName is a System.String

.OUTPUTS
The function returns a 1 if an error occured or a 0 if the function ran without errors.

.EXAMPLE
$ExitCode = Start-BLEXService -ServiceName <Name of the service> 
The line starts the function that tries to start the given service.
#>
Param (
	[Parameter(Mandatory=$true)]
	$ServiceName
	)
	
	$ServStatus = Get-Service $ServiceName
	if ($ServStatus.Status -ne "Running") {
		if ($ServStatus.Status -eq "Stopped") {
			try {
				$LogType = "Information"
				"The $ServiceName service is not running. Try to start the service now." | Write-BLLog -LogType $LogType
				"Invoking: Start-Service -Name $ServiceName" | Write-BLLog -LogType $LogType
				Start-Service -Name $ServiceName
				Start-Sleep -Seconds 5
			} catch {
				$LogType = "Error"
				$ErrorMessage = $_.Exception.Message
				"This error was thrown while invoking Start-Service -Name $ServiceName : $ErrorMessage" | Write-BLLog -LogType $LogType
				$Error.clear()
				Return 1
			}
		} elseif ($ServStatus -eq "Starting") {
			try {
				$i=0
				While (($ServStatus -eq "Starting") -AND ($i -lt 6)) {
					$LogType = "Warning"
					"The Service is in the status Starting. Wait 10 Seconds for the service to start. And get new status again." | Write-BLLog -LogType $LogType
					"Invoking: Start-Sleep -Seconds 10 and $ServStatus = Get-Service $ServiceName." | Write-BLLog -LogType $LogType
					Start-Sleep -Seconds 10
					$ServStatus = Get-Service $ServiceName
					$i++
				}
				
				$ServStatus = Get-Service $ServiceName
				$StartingTime = $i * 10
				
				if (($ServStatus -eq "Starting") -AND ($i -ge 6)) {
					$LogType = "Error"
					"The Service $ServiceName is after $StartingTime Seconds still in the status Starting. Please investigate further, maybe it is locked up. Setup will stop now." | Write-BLLog -LogType $LogType
					Return 1
				} elseif ($ServStatus -eq "Running") {
					$LogType = "Information"
					"Service has started and is running now." | Write-BLLog -LogType $LogType
					Return 0
				} else {
					$LogType = "Error"
					"The Service is after $StartingTime Seconds not in the status 'running'. Please investigate further, maybe it is locked up. Setup will stop now." | Write-BLLog -LogType $LogType
					Return 1
				}			
			} catch {
				$LogType = "Error"
				$ErrorMessage = $_.Exception.Message
				"This error was thrown while waiting the Service $ServiceName to start and get the new status: $ErrorMessage" | Write-BLLog -LogType $LogType
				$Error.clear()
				Return 1
			}
		} else {
			$LogType = "Error"
			"The Service $ServiceName is in a not expected status. Please take a look at the service." | Write-BLLog -LogType $LogType
			Return 1
		}
	} else {
		$LogType = "Information"
		"The service is already in the status 'running' Nothing to do here." | Write-BLLog -LogType $LogType
		Return 0
	}
	Return $ExitCode
}
#endregion function StartService

#region function Stop-BLEXService
Function Stop-BLEXService {
<#
.SYNOPSIS
The function stops a service on the local machine.

.DESCRIPTION
The function Stop-BLEXService starts a service on the local machine. 

.PARAMETER 
ServiceName is mandatory

.INPUTS
ServiceName is a System.String

.OUTPUTS
The function returns a 1 if an error occured or a 0 if the function ran without errors.

.EXAMPLE
$ExitCode = Stop-BLEXService -ServiceName <Name of the service> 
The line starts the function that tries to stop the given service.
#>
Param (
	[Parameter(Mandatory=$true)]
	$ServiceName
	)
	try {
		$LogType = "Information"
		"Getting actual servicestatus of $ServiceName. Invoking: $ServStatus = Get-Service $ServiceName  -ErrorAction Stop" | Write-BLLog -LogType $LogType
		$ServStatus = Get-Service $ServiceName  -ErrorAction Stop
	} catch {
		$LogType = "Error"
		"The status of the service $ServiceName could not be retrieved. is the Service: $ServiceName spelled right?" | Write-BLLog -LogType $LogType
		Return 1
	}
	if ($ServStatus.Status -ne "Stopped") {
		if ($ServStatus.Status -eq "Running") {
			try {
				$LogType = "Information"
				"The $ServiceName service is not stopped. Try to stop the service now." | Write-BLLog -LogType $LogType
				"Invoking: Stop-Service -Name $ServiceName" | Write-BLLog -LogType $LogType
				Stop-Service -Name $ServiceName -ErrorAction Stop
				Start-Sleep -Seconds 5
				Return 0
			} catch {
				$LogType = "Error"
				$ErrorMessage = $_.Exception.Message
				"This error was thrown while invoking Stop-Service -Name $ServiceName : $ErrorMessage" | Write-BLLog -LogType $LogType
				$Error.clear()
				Return 1
			}
		} elseif ($ServStatus -eq "Stopping") {
			try {
				$i=0
				While (($ServStatus -eq "Stopping") -AND ($i -lt 6)) {
					$LogType = "Warning"
					"The Service is in the status Stopping. Wait 10 Seconds for the service to stop. And get new status again." | Write-BLLog -LogType $LogType
					"Invoking: Start-Sleep -Seconds 10 and $ServStatus = Get-Service $ServiceName." | Write-BLLog -LogType $LogType
					Start-Sleep -Seconds 10
					$ServStatus = Get-Service $ServiceName -ErrorAction Stop
					$i++
				}
				if (($ServStatus -eq "Stopping") -AND ($i -ge 6)) {
					$LogType = "Error"
					$StoppingTime = $i * 10
					"The Service '$ServiceName' is after $StoppingTime Seconds still in the status Stopping. Please investigate further, maybe it is locked up. Setup will stop now." | Write-BLLog -LogType $LogType
					Return 1
				} elseif ($ServStatus -eq "Stopped") {
					$LogType = "Information"
					"Service '$ServiceName' has stopped now." | Write-BLLog -LogType $LogType
					Return 0
				} else {
					$LogType = "Error"
					"The Service '$ServiceName' is after $StartingTime Seconds not in the status 'stopping'. Please investigate further, maybe it is locked up. Setup will stop now." | Write-BLLog -LogType $LogType
					Return 1
				}			
			} catch {
				$LogType = "Error"
				$ErrorMessage = $_.Exception.Message
				"This error was thrown while waiting the Service $ServiceName to stop and get the new status: $ErrorMessage" | Write-BLLog -LogType $LogType
				$Error.clear()
				Return 1
			}
		} elseif ($ServStatus -eq "Stopped") {
			$LogType = "Information"
			"Service $ServiceName is already stopped. Nothing to to now." | Write-BLLog -LogType $LogType
			Return 0
		} else {
			$LogType = "Error"
			"The Service $ServiceName is in a not expected status. Please take a look at the service." | Write-BLLog -LogType $LogType
			Return 1
		}
	} else {
		$LogType = "Information"
		"Service $ServiceName is already in the status 'stopped'. Nothing to to here." | Write-BLLog -LogType $LogType
		Return 0
	}
	Return $ExitCode
}
#endregion function StopService

#region function Restart-BLEXService
Function Restart-BLEXService {
<#
.SYNOPSIS
The function restarts a service on the local machine.

.DESCRIPTION
The function Restart-BLEXService restarts a service on the local machine. 

.PARAMETER 
ServiceName is mandatory

.INPUTS
ServiceName is a System.String

.OUTPUTS
The function returns a 1 if an error occured or a 0 if the function ran without errors.

.EXAMPLE
$ExitCode = Restart-BLEXService -ServiceName <Name of the service> 
The line starts the function that tries to restart the given service.

.NOTES
This function partial uses the functions Start-BLEXService
#>
Param (
	[Parameter(Mandatory=$true)]
	$ServiceName
	)
	try {
		$ServStatus = Get-Service $ServiceName
	} catch {
		$LogType = "Error"
		"Maybe the servicename is not spelled right or it does not exist on this server. Taka a look at the servicename." | Write-BLLog -LogType $LogType
	}
	if ($ServStatus.Status -ne "Running") {
		if ($ServStatus.Status -eq "Stopped") {
			try {
				$LogType = "Information"
				"The $ServiceName service is 'stopped'. Try to start the service now." | Write-BLLog -LogType $LogType
				"Invoking: Start-BLEXService -ServiceName $ServiceName" | Write-BLLog -LogType $LogType
				$ExitCode = Start-BLEXService -ServiceName $ServiceName
			} catch {
				$LogType = "Error"
				$ErrorMessage = $_.Exception.Message
				"This error was thrown while invoking Start-Service -Name $ServiceName : $ErrorMessage" | Write-BLLog -LogType $LogType
				$Error.clear()
				Return 1
			}
		} elseif ($ServStatus -eq "Starting") {
			try {
				$i=0
				While (($ServStatus -eq "Starting") -AND ($i -lt 6)) {
					$LogType = "Warning"
					"The Service is in the status Starting. Wait 10 Seconds for the service to start. And get new status again." | Write-BLLog -LogType $LogType
					"Invoking: Start-Sleep -Seconds 10 and $ServStatus = Get-Service $ServiceName." | Write-BLLog -LogType $LogType
					Start-Sleep -Seconds 10
					$ServStatus = Get-Service $ServiceName
					$i++
				}
				$ServStatus = Get-Service $ServiceName
				$StartingTime = $i * 10
				
				if (($ServStatus -eq "Starting") -AND ($i -ge 6)) {
					$LogType = "Error"
					"The Service $ServiceName is after $StartingTime Seconds still in the status Starting. Please investigate further, maybe it is locked up. Setup will stop now." | Write-BLLog -LogType $LogType
					Return 1
				} elseif ($ServStatus -eq "Running") {
					$LogType = "Information"
					"Service has started and is running now. Trying to restart the service now." | Write-BLLog -LogType $LogType
					"Invoking: Restart-BLEXService $ServiceName"
					$ExitCode = Restart-BLEXService -ServiceName $ServiceName					
				} else {
					$LogType = "Error"
					"The Service is after $StartingTime Seconds not in the status 'running'. Please investigate further, maybe it is locked up. Setup will stop now." | Write-BLLog -LogType $LogType
					Return 1
				}			
			} catch {
				$LogType = "Error"
				$ErrorMessage = $_.Exception.Message
				"This error was thrown while waiting the Service $ServiceName to start and get the new status: $ErrorMessage" | Write-BLLog -LogType $LogType
				$Error.clear()
				Return 1
			}
		} else {
			$LogType = "Error"
			"The Service $ServiceName is in a not expected status. Please take a look at the service." | Write-BLLog -LogType $LogType
			Return 1
		}
	} else {
		$LogType = "Information"
		try {
			"The Service $ServiceName is in the status 'Running'. Trying to restart the service now." | Write-BLLog -LogType $LogType			
			$RestartService = Restart-Service -Name $ServiceName -Force -ErrorAction Stop
			Return 0
		} catch {
			$LogType = "Error"
			$ErrorMessage = $_.Exception.Message
			"This error was thrown while trying to restart the Service $ServiceName : $ErrorMessage" | Write-BLLog -LogType $LogType
			$Error.clear()
			Return 1
		}

		$ServStatus = Get-Service $ServiceName
		$StartingTime = $i * 10
		if ($ServStatus -eq "Starting") {
			try {
				$i=0
				While (($ServStatus -eq "Starting") -AND ($i -lt 6)) {
					$LogType = "Warning"
					"The Service is in the status Starting. Wait 10 Seconds for the service to start. And get new status again." | Write-BLLog -LogType $LogType
					"Invoking: Start-Sleep -Seconds 10 and $ServStatus = Get-Service $ServiceName." | Write-BLLog -LogType $LogType
					Start-Sleep -Seconds 10
					$ServStatus = Get-Service $ServiceName
					$i++
				}
				
				$ServStatus = Get-Service $ServiceName
				$StartingTime = $i * 10
				if (($ServStatus -eq "Starting") -AND ($i -ge 6)) {
					$LogType = "Error"
					"The Service $ServiceName is after $StartingTime Seconds still in the status Starting. Please investigate further, maybe it is locked up. Setup will stop now." | Write-BLLog -LogType $LogType
					Return 1
				} elseif ($ServStatus -eq "Running") {
					$LogType = "Information"
					"Service has started and is running now." | Write-BLLog -LogType $LogType
					Return 0
				} else {
					$LogType = "Error"
					"The Service is after $StartingTime Seconds not in the status 'running'. Please investigate further, maybe it is locked up. Setup will stop now." | Write-BLLog -LogType $LogType
					Return 1
				}			
			} catch {
				$LogType = "Error"
				$ErrorMessage = $_.Exception.Message
				"This error was thrown while waiting the Service $ServiceName to stop and get the new status: $ErrorMessage" | Write-BLLog -LogType $LogType
				$Error.clear()
				Return 1				
			}
		} elseif ($ServStatus -eq "Stopping") {
			try {
				$i=0
				While (($ServStatus -eq "Stopping") -AND ($i -lt 6)) {
					$LogType = "Warning"
					"The Service is in the status Stopping. Wait 10 Seconds for the service to stop. And get new status." | Write-BLLog -LogType $LogType
					"Invoking: Start-Sleep -Seconds 10 and $ServStatus = Get-Service $ServiceName." | Write-BLLog -LogType $LogType
					Start-Sleep -Seconds 10
					$ServStatus = Get-Service $ServiceName
					$i++
				}
				
				$ServStatus = Get-Service $ServiceName
				$StartingTime = $i * 10
				if (($ServStatus -eq "Starting") -AND ($i -ge 6)) {
					$LogType = "Error"
					"The Service $ServiceName is after $StartingTime Seconds still in the status Stopping. Please investigate further, maybe it is locked up. Setup will stop now." | Write-BLLog -LogType $LogType
					Return 1
				} elseif ($ServStatus -eq "Stopped") {
					$LogType = "Information"
					"Service has stopped now. Will start ist now." | Write-BLLog -LogType $LogType
					$ExitCode = Start-BLEXService $ServiceName
				} else {
					$LogType = "Error"
					"The Service is after $StartingTime Seconds not in the status 'stopping'. Please investigate further, maybe it is locked up. Setup will stop now." | Write-BLLog -LogType $LogType
					Return 1
				}			
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
#endregion function RestartService

#region function Test-BLEXExitCode
Function Test-BLEXExitCode {
<#
.SYNOPSIS
This function tests a given ExitCode

.DESCRIPTION
This script tests a given ExitCode. A ExitCode of the types 'int32' (MSI) or 'FeatureOperationExitCode' (Add-Remove-WindowsFeatures) can be tested

.PARAMETER ExitCode
The parameter ExitCode is mandatory!

.PARAMETER NoReturn
The switch NoReturn return no ExitCode. The function is only testing for Errors or Reboots after an installation.

.EXAMPLE
Test-BLEXExitCode -ExitCode <ExitCode Variable>
or
Test-BLEXExitCode -ExitCode "3010"
or
Test-BLEXExitCode -ExitCode "SuccessRestartRequired"
or
Test-BLEXExitCode -ExitCode "3010" -NoReturn

.OUTPUTS
The function returns a 0 if everything is allright or a 1 if the given ExitCode is an "error".
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$true)]
	$ExitCode,
	[SWITCH]$NoReturn
	)
#Get Type of ExitCode
	if ($Exitcode.length -gt 1) {
		$TestType = $ExitCode[0].GetType()
	} else {
		$TestType = $ExitCode.GetType()
	}
	if ($TestType.Name -eq "Int32"){
	#Repair a MSI ExitCode of 3010 or an array of ExitCodes
	#Possible MSI ExitCodes which are interesting to know and/or to log
	#   0 - ERROR_SUCCESS 				  - Action completed successfully.
	#1604 - ERROR_INSTALL_SUSPEND		  -	The product is already installed, and has prevented the installation of this product.
	#1639 - ERROR_INVALID_COMMAND_LINE	  - Invalid command line argument. Consult the Windows Installer SDK for detailed command line help.
	#3010 - ERROR_SUCCESS_REBOOT_REQUIRED - Restart Required to complete the (un-)installation process
		$LogType = "Information"
		"No transformation from string-exitcodes to int-exitcodes needed." | Write-BLLog -LogType $LogType
		
		if ($ExitCode.length -gt 1) {
			$EC = $ExitCode
			[int32]$ExitCode = $Null
			$Count = $EC.length - 1
			$Number = $EC.length
			$i = 0
			"The (un-)installations returned $Number exitcodes. Checking the exitcodes now." | Write-BLLog -LogType $LogType
			While (($i -le $Count) -AND ($ExitCode -ne 1)) {
				if ($EC[$i] -eq  3010) {
					$LogType = "Warning"
					"A Reboot is required to complete the (un-)installation process." | Write-BLEventLog -LogType $LogType
					"A Reboot is required to complete the (un-)installation process." | Write-BLLog -LogType $LogType
					$ExitCode = 0
				} elseif ($EC[$i] -eq 0) {
					$LogType = "Information"
					"(Un-)istallation is complete. No Reboot required." | Write-BLLog -LogType $LogType
					$ExitCode = 0
				} elseif ($EC[$i] -eq 1604) {
					$LogType = "Warning"
					"The product is already installed, and has prevented the installation of this product." | Write-BLEventLog -LogType $LogType
					"The product is already installed, and has prevented the installation of this product." | Write-BLLog -LogType $LogType
					$ExitCode = 0
				} else { 
					$LogType = "Error"
					$ExCo = $EC[$i]
					"An error occurred. The setup has returned the ExitCode $ExCo. Please take a look at the Log: $LogFile." | Write-BLEventLog -LogType $LogType
					"An error occurred. The setup has returned the ExitCode $ExCo. Please take a look at the Log: $LogFile." | Write-BLLog -LogType $LogType
					Return 1
				}
				$i++
			}	
		} elseif ($ExitCode.length -eq 1) {
			$EC = $ExitCode
			[int32]$ExitCode = $Null
			if ($EC -eq 3010) {
				$LogType = "Warning"
				"A Reboot is required to complete the (un-)installation. Setting ExitCode to 0." | Write-BLEventLog -LogType $LogType
                "A Reboot is required to complete the (un-)installation. Setting ExitCode to 0." | Write-BLLog -LogType $LogType
                $ExitCode = 0
			} elseif ($EC -eq 0) {
				$LogType = "Information"
				"(Un-)istallation is complete. No Reboot required. ExitCode value still 0." | Write-BLLog -LogType $LogType
				$ExitCode = 0
			} else { 
				$LogType = "Error"
				"An error occurred. The setup has returned the ExitCode $EC. Please take a look at the Log: $LogFile." | Write-BLEventLog -LogType $LogType
				"An error occurred. The setup has returned the ExitCode $EC. Please take a look at the Log: $LogFile." | Write-BLLog -LogType $LogType
				Return 1
			}
		} elseif ($ExitCode -eq $Null) {
			$LogType = "Error"
			"An error occured, no exitcode was returned by setup or function. Please take a further look at the log files." | Write-BLEventLog -LogType $LogType
			"An error occured, no exitcode was returned by setup or function. Please take a further look at the log files." | Write-BLLog -LogType $LogType
			Return 1
		}
	} elseif ($TestType.Name -eq "FeatureOperationExitCode" ) {
		$LogType = "Information"
		#Convert from FeatureOperationExitCode to MSI ExitCodes: Possible ExitCodes
		#and repair the ExitCode if an array of ExitCodes is returned
		#NoChangeNeeded
		#Success
		#SuccessRestartRequired
		#InvalidArgs
		#Failed
		#FailedRestartRequired
		"A Feature or Role was (un-)installed. A string to int transformation will be done now." | Write-BLLog -LogType $LogType
		if ($ExitCode.length -gt 1) {
			$EC = $ExitCode
			[int32]$ExitCode = $NULL
			$Count = $EC.count
			$i = 0
			While ($i -le ($Count -1)) {
				if (($EC[$i] -eq "NoChangeNeeded") -OR ($EC[$i] -eq "Success")) {
					$LogType = "Information"
					"ExitCode will be transformed from $EC[$i] to 0" | Write-BLLog -LogType $LogType
					$ExitCode = 0 				
				} elseif ($EC[$i] -eq "SuccessRestartRequired") {
                    $LogType = "Warning"
				    "A Reboot is required to complete the (un-)installation. Setting ExitCode to 0." | Write-BLEventLog -LogType $LogType
                    "A Reboot is required to complete the (un-)installation. Setting ExitCode to 0." | Write-BLLog -LogType $LogType
                    $ExitCode = 0
				} elseif ($EC[$i] -eq "FailedRestartRequired") {
					$LogType = "Error"
					"An error occured during the (un-)installation. It returned the ExitCode: FailedRestartRequired. Please restart the server and take a look at the log files." | Write-BLEventLog -LogType $LogType
					Return 1
				} elseif (($EC[$i] -eq "InvalidArgs") -OR ($EC[$i] -eq "Failed")) {
					$LogType = "Error"
					"An error occured during the (un-)installation. It returned the ExitCode: $EC[$i]. Please take a look at the log files." | Write-BLLog -LogType $LogType
                    Return 1
				}
				$i++
			}		
		} elseif ($ExitCode.length -eq 1) {
			$EC = $ExitCode
			[int32]$ExitCode = $NULL
			if ($EC -eq "NoChangeNeeded") {
                $LogType = "Information"
                "Setting ExitCode to 0, because the (un-)installation process returned NoChangeNeeded" | Write-BLLog -LogType $LogType
				$ExitCode = 0
			} elseif ($EC -eq "SuccessRestartRequired") {
			    $LogType = "Warning"
                "A Reboot is required to complete the (un-)installation. Setting ExitCode to 0." | Write-BLEventLog -LogType $LogType
                "A Reboot is required to complete the (un-)installation. Setting ExitCode to 0." | Write-BLLog -LogType $LogType
                $ExitCode = 0
			} elseif ($EC -eq "FailedRestartRequired") {
				$LogType = "Error"
				"An error occured during the (un-)installation. It returned the ExitCode: FailedRestartRequired" | Write-BLEventLog -LogType $LogType
				Return 1
			}
		} else {
			$LogType = "Error"
			"An error occured, no exitcode was returned by setup or function. Please take a further look at the log files." | Write-BLEventLog -LogType $LogType
			"An error occured, no exitcode was returned by setup or function. Please take a further look at the log files." | Write-BLLog -LogType $LogType
			Return 1			
		}
	} else {
		$LogType = "Error"
		$GT = $TestType.Name
		"The Last ExitCode is no Int32 (e.g. MSI) nor a FeatureOperationExitCode (e.g. Add-WindowsFeature). Test of Exitcodes failed." | Write-BLLog -LogType $LogType
		"The type of the Exitcode Var is: $GT" | Write-BLLog -LogType $LogType
		Return 1
	}
	
	If ($NoReturn){
		$LogType = "Information"
		"Switch NoReturn exists. No Exitcode is given back. Exitcode is tested for Reboot/Errors only."  | Write-BLLog -LogType $LogType
	} else {
		Return $ExitCode
	}
}
#endregion Test-BLEXExitCode

#region function Initialize-BLEXReplication
Function Initialize-BLEXReplication {
#Triggers a full AD replication sync from the defined Domain Controller via PSRemoting and repadmin.exe
	Param(
		[Parameter(Mandatory=$True)]
		[string]$DomainController
	)
	
	$LogType = "Information"
	"Trying to open a PSSession to $DomainController. Invoking: New-PSSession -ComputerName $DomainController" | Write-BLLog -LogType $LogType
	$PSS = New-PSSession -ComputerName $DomainController
	
	if(!$PSS){
		$LogType = "CriticalError"
		"Could not create a PSSession on $DomainController." | Write-BLLog -LogType $LogType
		Return 1
	} else {
		$LogType = "Information"
		"The PSSession was created successful." | Write-BLLog -LogType $LogType
		"Trying to trigger a replication on $DomainController. Invoking via PSSession: Start-Process repadmin -Argumentlist /syncall -wait" | Write-BLLog -LogType $LogType
		Invoke-Command -Session $PSS -Scriptblock {
			$Repl = Start-Process repadmin -Argumentlist "/syncall" -wait
			if($Repl) {
				$LogType = "CriticalError"
				"Triggering AD-Replication failed. Please check your AD for errors." | Write-BLLog -LogType $LogType
				Return 1
			} else {
				$LogType = "Information"
				"Triggering AD-Replication was successful." | Write-BLLog -LogType $LogType
				Return 0
			}
		}
		Remove-PSSession -Session $PSS
	}
	Return $ExitCode
}	
#endregion trigger replication

#region Funktion Set-ExPo2Unrestricted
Function Set-BLEXExecutionPolicy {
	Param(
		[Parameter(Mandatory=$True)]
		[string]$Value
	)
	$ExPo = Get-ExecutionPolicy
	$ExPoIF = $ExPo.ToString().ToLower()
	$ValueIF = $Value.ToLower()
	if ($ValueIF -ne $ExPoIF){
		try {
			$LogType = "Information"
			"The ExecutionPolicy is not set to $Value and will now be set to this value." | Write-BLLog -LogType $LogType
			"Invoking: Set-ExecutionPolicy $Value -Force" | Write-BLLog -LogType $LogType
			Set-ExecutionPolicy $Value -Force
			Return 0
		} catch {
			$LogType = "Error"
			$ErrorMessage = $_.Exception.Message
			"This error was thrown while setting the ExecutionPolicy to $Value : $ErrorMessage" | Write-BLLog -LogType $LogType
			$Error.clear()
			Return 1
		}
	} else {
		$LogType = "Information"
		"The ExecutionPolicy is already set to $Value. We got nothing to do." | Write-BLLog -LogType $LogType
		Return 0
	}
	Return $ExitCode
}
#endregion ExecutionPolicy
