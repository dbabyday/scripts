<#
$cn = 'co-db-032.na.plexus.com'
$processes = @()

Get-Process -ComputerName $cn | ForEach-Object {
    $eachPid = $_.Id
    $parentPid = (Get-WmiObject win32_process -ComputerName $cn -Filter "processid='$eachPid'").parentprocessid
    $parent = Get-Process -Id $parentPid -ErrorAction SilentlyContinue

    $id         = $_.Id
    $name       = $_.Name
    $parentId   = $parentPid
    $parentName = $parent.Name
    
    $process = New-Object -TypeName PSObject
    $process | Add-Member -Name 'id' -MemberType NoteProperty -Value $id
    $process | Add-Member -Name 'name' -MemberType NoteProperty -Value $name
    $process | Add-Member -Name 'parent_id' -MemberType NoteProperty -Value $parentId
    $process | Add-Member -Name 'parent_name' -MemberType NoteProperty -Value $parentName

    $processes += $process
}

$processes | Format-Table -AutoSize
#>

<#
Clear-Host
Get-Process -Id $pid
(Get-WmiObject win32_process -Filter "processid=964").parentprocessid
Get-Process -Id 856
(Get-WmiObject win32_process -Filter "processid=856").parentprocessid
Get-Process -Id 716
#>

Get-WmiObject win32_process -ComputerName $cn -Filter "processid=392"