If($null -eq $cn) {
	$cn = Read-Host "Enter the ComputerName"
}

Get-CimInstance -ComputerName $cn -ClassName Win32_OperatingSystem | Select LastBootUpTime