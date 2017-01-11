Import-Module C:\RIS\Lib\BaseLibrary.psm1
$Installed = Get-BLRegistryKeyX64 -Path "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{90150000-1153-0409-1000-0000000FF1CE}_Office15.WacServer_{2ABA84B7-9E3A-47B1-A125-FE119DFB1A1C}"
$Update = $Installed.DisplayName

if ($Update -eq "Update for Microsoft Office Web Apps Server 2013 (KB3115022) 64-Bit Edition") {
	Write-Host "Das Update KB3115022 wurde erfolgreich installiert." -foregroundcolor "green" -backgroundcolor "black"
} else {
	Write-Host "Das Update KB3115022 wurde nicht erfolgreich installiert." -foregroundcolor "red" -backgroundcolor "black"
}