
$serverListFile = Read-Host "Server list file path:"

$serverNames = Get-Content -Path $serverListFile

$array = @()

$serverNames | ForEach-Object {
    $serverName = $_
    $ip = (Test-Connection -Count 1 -ComputerName $serverName).IPV4Address.IPAddressToString

    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Server'    -MemberType Noteproperty -Value $serverName
    $object | Add-Member -Name 'IPAddress' -MemberType Noteproperty -Value $ip	
    $array += $object
}

#$array | Sort-Object IPAddress | Format-Table -Autosize
$array | Sort-Object Server | Format-Table -Autosize
