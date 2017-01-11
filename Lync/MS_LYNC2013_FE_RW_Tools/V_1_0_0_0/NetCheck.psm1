#Check-Installed-NetFrameworks

$DotNet2_0 = "Dot_Net_Version_2_0"
$DotNet3_0 = "Dot_Net_Version_3_0"
$DotNet3_5 = "Dot_Net_Version_3_5"
$DotNet4_0_Client = "Dot_Net_Version_4_0_Client"
$DotNet4_0 = "Dot_Net_Version_4_0"
$DotNet4_5 = "Dot_Net_Version_4_5"
$DotNet4_5_1 = "Dot_Net_Version_4_5_1"
$DotNet4_5_2 = "Dot_Net_Version_4_5_2"

Function Test-Key ([string]$path, [string]$key, $value){
  if (!(Test-Path $path)) { return $false}
  if ((Get-ItemProperty $path).$key -eq $value) { return $true}
  return $false
}


Function Get-InstalledNetFrameworks() {
  $installed = @()
  if (Test-Key "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727" "Install" 1) { $installed += $DotNet2_0}
  if (Test-Key "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.0\Setup" "InstallSuccess" 1) { $installed += $DotNet3_0}
  if (Test-Key "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5" "Install" 1) { $installed += $DotNet3_5}
  if (Test-Key "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client" "Install" 1) { $installed += $DotNet4_0_Client}
  if (Test-Key "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Install" 1) { $installed += $DotNet4_0}
  if (Test-Key "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Release" 378389) { $installed += $DotNet4_5}
  if (Test-Key "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Release" 378575) { $installed += $DotNet4_5_1}
  if (Test-Key "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Release" 379893) { $installed += $DotNet4_5_2}
  return $installed
}

Function Get-JavaVersions() {
  $installed = @()
  if (Test-Path "HKLM:\SOFTWARE\JavaSoft\Java Runtime Environment") {
      $tmp = Get-ChildItem ( "HKLM:\SOFTWARE\JavaSoft\Java Runtime Environment")
      foreach ($sub in $tmp) {
        $installed += $sub.Name.Substring($sub.Name.LastIndexOf("\")+1, 3)
      }
      $installed = $installed | select -Unique
  }
  return $installed
}

Export-ModuleMember -Function `
    Get-InstalledNetFrameworks, 
    Get-JavaVersions
Export-ModuleMember -Variable `
	DotNet2_0,
	DotNet3_0,
	DotNet3_5,
	DotNet4_0_Client,
	DotNet4_0,
	DotNet4_5,
	DotNet4_5_1,
	DotNet4_5_2
