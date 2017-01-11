
Param (
	[switch]$Install,
	[switch]$DeInstall
)
Write-Host "Getting installed Hotfixes..."
$Hotfixes = Get-Hotfix
$DeInstHF = "KB2670838"
$InstHF = "KB974405"

if ($Install.isPresent) {
	if ($InstHF) {
		foreach ($Hotfix in $InstHF) {
			if ($Hotfixes.HotFixID -Contains $HotFix) {
				Write-Host "HotFix $HotFix was installed successfully." -foregroundcolor "green" -backgroundcolor "black"
			} else {
				Write-Host "HotFix $HotFix was not installed yet." -foregroundcolor "red" -backgroundcolor "black"
			}	
		}
	}
	if ($DeInstHF){
		foreach ($HotFix in $DeInstHF) {
			if ($Hotfixes.HotFixID -Contains $HotFix) {
				Write-Host "HotFix $HotFix was not deinstalled yet." -foregroundcolor "red" -backgroundcolor "black"			
			} else {
				Write-Host "HotFix $HotFix was deinstalled successfully." -foregroundcolor "green" -backgroundcolor "black"			
			}
		}
	}
}

if ($DeInstall.isPresent) {
	if ($InstHF){
		foreach ($Hotfix in $InstHF) {
			if ($Hotfixes.HotFixID -Contains $HotFix) {
				Write-Host "HotFix $HotFix was not deinstalled yet." -foregroundcolor "red" -backgroundcolor "black"
			} else {
				Write-Host "HotFix $HotFix was deinstalled successfully." -foregroundcolor "green" -backgroundcolor "black"
			}	
		}
	}
	if ($DeInstHF){
		foreach ($HotFix in $DeInstHF) {
			if ($Hotfixes.HotFixID -NotContains $HotFix) {
				Write-Host "HotFix $HotFix was not installed yet or was deinstalled successfully. Reinstall is unprovided for $HotFix" -foregroundcolor "yellow" -backgroundcolor "black"			
			}
		}
	}
}
