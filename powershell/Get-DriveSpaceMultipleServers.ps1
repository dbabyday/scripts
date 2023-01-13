$requestedDrives = Get-Content -Path C:\JamesScripts\PowerShell\Get-DriveSpaceMultipleServers_InputList.txt
$drives = @()

$requestedDrives | ForEach-Object {
    $requestedDrive = $_ -split ','
    $serverName = $requestedDrive[0]
    $driveName  = $requestedDrive[1]

    $volume = Get-WmiObject win32_volume -ComputerName $serverName | Where-Object  { $_.Name -eq $driveName }
    $drive = New-Object -TypeName PSObject

    $drive | Add-Member -Name 'Server'  -MemberType NoteProperty -Value ($serverName)
    $drive | Add-Member -Name 'Drive'   -MemberType NoteProperty -Value ($driveName)
    $drive | Add-Member -Name 'Free_GB' -MemberType NoteProperty -Value ([math]::Round((($volume.Freespace)/1GB),1))
    $drive | Add-Member -Name 'Size_GB' -MemberType NoteProperty -Value ([math]::Round((($volume.Capacity)/1GB),1))
    If ($volume.Capacity -ne $null) {
        $drive | Add-Member -Name 'PctFree' -MemberType NoteProperty -Value ([math]::Round((($volume.Freespace)/($volume.Capacity)*100),0))
    }
    Else {
        $drive | Add-Member -Name 'PctFree' -MemberType NoteProperty -Value 0
    }

    $drives += $drive
}

$drives | Sort-Object Server, Drive | Format-Table -AutoSize
