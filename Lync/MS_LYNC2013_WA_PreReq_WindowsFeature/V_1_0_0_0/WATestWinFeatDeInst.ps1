#Testing installation for WA-Server
#
#
#Testing for Install: WATestWinFeatDeInst -install
#Testing for DeInstall: WATestWinFeatDeInst -deinstall
#
#
Param (
	[switch]$Install,
	[switch]$DeInstall
)
$WinFeatures = "Web-Server", "Web-Scripting-Tools", "Web-Windows-Auth", "Web-Includes", "Web-Asp-Net", "Web-Log-Libraries", "Web-Http-Tracing", "Web-Stat-Compression", "Web-Default-Doc", "Web-ISAPI-Ext", "Web-ISAPI-Filter", "Web-Http-Errors", "Web-Http-Logging", "Web-Net-Ext", "Web-Client-Auth", "Web-Filtering", "Web-Mgmt-Console", "Web-Dyn-Compression", "Ink-Handwriting", "IH-Ink-Support", "NET-Win-CFAC", "AS-NET-Framework"
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