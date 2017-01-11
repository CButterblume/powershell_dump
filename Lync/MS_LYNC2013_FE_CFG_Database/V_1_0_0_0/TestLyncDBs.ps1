$LyncDBs = "lis", "xds","rtcxds","rtcab","rgsconfig","LcsCDR","QoEMetrics","rtcshared","rgsdyn","cpsdyn"
$ComputerName = "RZ1VPFLYC401"
Write-Host "Opening PS Session to $ComputerName"
$PSS = New-PSSession -ComputerName $ComputerName
Write-Host "Searching for databases on  $ComputerName"
Write-Host "Invoking: Add-PSSnapIn *sql*;Dir SQLServer:\\SQL\RZ1VPFLYC401\Lync\Databases | Select Name"
$DBNames = Invoke-Command -Session $PSS -ScriptBlock {Add-PSSnapIn *sql*;Dir SQLServer:\\SQL\RZ1VPFLYC401\Lync\Databases | Select Name}
Write-Host "These DBs were found on $ComputerName :"
$i = 1
foreach ($DB in $DBNames) {
	Write-Host "DB $i :" $DB.Name
	$i++
}

if (($DBNames.Name -Contains $LyncDBs[0]) -AND ($DBNames.Name -Contains $LyncDBs[1]) -AND ($DBNames.Name -Contains $LyncDBs[2]) `
	-AND ($DBNames.Name -Contains $LyncDBs[3]) -AND ($DBNames.Name -Contains $LyncDBs[4]) -AND ($DBNames.Name -Contains $LyncDBs[5]) `
	-AND ($DBNames.Name -Contains $LyncDBs[6]) -AND ($DBNames.Name -Contains $LyncDBs[7]) -AND ($DBNames.Name -Contains $LyncDBs[8]) `
	-AND ($DBNames.Name -Contains $LyncDBs[9]) )  {
	Write-Host "The databases for Lync - 'lis', 'xds','rtcxds','rtcab','rgsconfig','LcsCDR','QoEMetrics','rtcshared','rgsdyn','cpsdyn' - were created succesfully." -foregroundcolor "green" -backgroundcolor "black"
} else {
	Write-Host "The databases, or not all, for Lync - 'lis', 'xds','rtcxds','rtcab','rgsconfig','LcsCDR','QoEMetrics','rtcshared','rgsdyn','cpsdyn' do not exist on $ComputerName." -foregroundcolor "red" -backgroundcolor "black"	
}
Write-Host "Testing the existence of the .mdf-Files on D:\"
$GetMDFs = Invoke-Command -Session $PSS -ScriptBlock {Get-ChildItem -Path D:\ -Recurse -Filter "*.mdf"}
foreach ($DB in $LyncDBs) {
	$DBName = $DB + ".mdf"
	if ($GetMDFs.Name -Contains $DBName) {
		$MDF = $GetMDFs | Where-Object {$_.Name -eq $DBName} | Select-Object Directory
		$Dir = $MDF.Directory.Split("=").Replace("}","")		
		Write-Host "MDF-File $DBName exists in - $Dir" -foregroundcolor "green" -backgroundcolor "black"
	} else {
		Write-Host "MDF-File $DBName des not exist." -foregroundcolor "red" -backgroundcolor "black"
	}
}


Write-Host "Testing the existence of the .ldf-Files on E:\"
$GetLDFs = Invoke-Command -Session $PSS -ScriptBlock {Get-ChildItem -Path E:\ -Recurse -Filter "*.ldf"}
foreach ($DB in $LyncDBs) {
	$DBName = $DB + ".ldf"
	if ($GetLDFs.Name -Contains $DBName) {
		$LDF = $GetLDFs | Where-Object {$_.Name -eq $DBName} | Select-Object Directory
		$Dir = $LDF.Directory.Split("=").Replace("}","")
		Write-Host "LDF-File $DBName exists in - $Dir" -foregroundcolor "green" -backgroundcolor "black"
	} else {
		Write-Host "LDF-File $DBName des not exist" -foregroundcolor "red" -backgroundcolor "black"
	}
}

Write-Host "Removing PSSession"
Remove-PSSession -Session $PSS












