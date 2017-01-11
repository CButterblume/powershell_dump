$Domain = $Env:UserDNSDomain
$DC = ($Env:LogOnServer).Replace("\","")
Write-Host "Opening PSSession to $DC"
$PSS = New-PSSession -ComputerName $DC
$Result = Invoke-Command -Session $PSS -ScriptBlock {Param ($Domain) Get-DNSServerResourceRecord -RRType MX -ZoneName $Domain} -Args $Domain
$i = 1
if ($Result) {
foreach ($Server in $Result) {
	$Res = $Server.RecordData.MailExchange
	$Name = $Res.Split(".")[0]
	$IPAddress = Invoke-Command -Session $PSS -ScriptBlock {Param ($Domain,$Name) Get-DnsServerResourceRecord -Name $Name -ZoneName $Domain} -Args $Domain,$Name
	$IP = $IPAddress.RecordData.IPv4Address
	Write-Host "MailExchanger $i : $Res" -foregroundcolor "green" -backgroundcolor "black"
	Write-Host "MailExchanger $i IP: $IP" -foregroundcolor "green" -backgroundcolor "black"
	Write-Host "---------------------------------------" -foregroundcolor "white" -backgroundcolor "black"
	$i++
}
} else {
 Write-Host "Es wurde kein MX-Eintrag gefunden." -foregroundcolor "red" -backgroundcolor "black"
}