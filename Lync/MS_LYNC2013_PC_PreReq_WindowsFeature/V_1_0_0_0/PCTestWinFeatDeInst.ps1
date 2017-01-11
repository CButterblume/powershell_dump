#Testing installation for PC-Server
#
#
#Testing for Install: PCTestWinFeatDeInst -install
#Testing for DeInstall: PCTestWinFeatDeInst -deinstall
#
#
Param (
	[switch]$Install,
	[switch]$DeInstall
)
$WinFeatures = "NET-Framework", "MSMQ-Server", "MSMQ-Directory"
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