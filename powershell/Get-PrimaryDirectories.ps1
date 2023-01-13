Get-WmiObject -ComputerName $cn Win32_volume | Where-Object { $_.Name -ne "C:\" -and $_.Name -ne "D:\" } | Sort-Object Name | ForEach-Object {
    $path = '\\' + $cn + '\' + ($_.Name).Substring(0,1) + '$'
    Get-ChildItem -Path $path | Where-Object { $_.Mode -match "d" } | Sort-Object FullName | Select-Object FullName
}