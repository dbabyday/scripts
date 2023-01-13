# wdccvm0221.neenah.na.plexus.com

$cn = Read-Host -Prompt "Enter computer name or ip address"
$sleepSeconds = Read-Host -Prompt "Delay seconds between tests"

while ($true) {
	$tc = (Test-Connection $cn -Count 1 -ErrorAction SilentlyContinue)
	if ($tc) {
		Write-Host (Get-Date -Format "yyyy-mm-dd HH:mm:ss") - $cn - $tc.IPV4Address.IPAddressToString - $tc.ResponseTime ms
	}
	else {
		Write-Host (Get-Date -Format "yyyy-mm-dd HH:mm:ss") - $cn - no response
	}
	Start-Sleep -s $sleepSeconds
}