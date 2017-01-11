
Function Start-LyncServices{

	$ReturnCode = 0
	$StartSvcLogFile = "C:\RIS\Log\LYNC_StartServices.html"

	$ServicesNotRunning = Get-CsWindowsService|Where-Object {$_.Status -ne "Running"}

	if ($ServicesNotRunning){

		"The following Lync Services are not Running." | Write-BLLog -LogType Warning
		$ServicesNotRunning.Name | Write-BLLog -LogType Warning
		"Trying to start the services. Invoking: Start-CsWindowsService" | Write-BLLog -LogType Information
	
		Try{
			$ServicesNotRunning|Start-CsWindowsService -Force -Report $StartSvcLogFile
		}
		Catch{
	
			"There was an error starting the Lync services." | Write-BLLog -LogType CriticalError
			$ErrorMessage = $_.Exception.Message
			"The Error Message is: $ErrorMessage"|Write-BLLog -LogType CriticalError
			"Please check the Logfile found under $StartSvcLogFile"|Write-BLLog -LogType CriticalError
			$ReturnCode	= 1
		}
	}
	else{
		"All Lync Services are running. Nothing to do." | Write-BLLog -LogType Information	
	}
	
	Return $ReturnCode
}

$ExitCode = Start-LyncServices

"Start-LyncServices returned Exitcode: $ExitCode" | Write-BLLog -LogType Information