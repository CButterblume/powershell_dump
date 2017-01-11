#Testing installation for FE-Server
#
#
#Testing for Install: FETestWinFeatDeInst -install
#Testing for DeInstall: FETestWinFeatDeInst -deinstall
#
#
Param (
	[switch]$Install,
	[switch]$DeInstall
)
$WinFeatures = "Web-Server", "Web-Static-Content", "Web-Default-Doc", "Web-Scripting-Tools", "Web-Windows-Auth", "Web-Asp-Net", "Web-Log-Libraries", "Web-Http-Tracing", "Web-Stat-Compression", "Web-Dyn-Compression", "Web-ISAPI-Ext", "Web-ISAPI-Filter", "Web-Http-Errors", "Web-Http-Logging", "Web-Net-Ext", "Web-Client-Auth", "Web-Filtering", "Web-Mgmt-Console", "Telnet-Client", "RSAT-AD-Tools", "Desktop-Experience"
foreach ($Feature in $WinFeatures) {
	$TestFeat = Get-WindowsFeature -Name $Feature
	$State = $TestFeat.Installed
	
	if ($Install.isPresent) {
		if ($State -eq $True) {
			Write-Host "Feature $Feature was installed successfully." -foregroundcolor "green" -backgroundcolor "black"
		} elseif ($State -eq $False){
			Write-Host "Feature $Feature was not installed yet." -foregroundcolor "red" -backgroundcolor "black"
		}
	}
	if ($DeInst.isPresent) {
		if ($State -eq $True) {
			Write-Host  "Feature $Feature was not deinstalled yet." -foregroundcolor "red" -backgroundcolor "black"
		} elseif ($State -eq $False){
			Write-Host "Feature $Feature was deinstalled successfully." -foregroundcolor "green" -backgroundcolor "black"
		}	
	}
}