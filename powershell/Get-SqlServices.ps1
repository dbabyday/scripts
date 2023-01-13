$servers  = Get-Content -Path 'C:\JamesScripts\PowerShell\Get-SqlServices_ServerList.txt'
$services = @()

$servers | ForEach-Object {
    $server = $_

    Get-WmiObject Win32_Service -ComputerName $server -Filter "name Like '%SQL%' or DisplayName Like '%SQL%'" | ForEach-Object {
        $service = New-Object -TypeName PSObject

        $service | Add-Member -Name 'Server' -MemberType NoteProperty -Value $server
        $service | Add-Member -Name 'State' -MemberType NoteProperty -Value $_.State
        $service | Add-Member -Name 'DisplayName' -MemberType NoteProperty -Value $_.DisplayName
        $service | Add-Member -Name 'Name' -MemberType NoteProperty -Value $_.Name
        $service | Add-Member -Name 'StartName' -MemberType NoteProperty -Value $_.StartName

        $services += $service
    }
}

$services | Sort-Object Server, DisplayName, State | Format-Table -AutoSize










