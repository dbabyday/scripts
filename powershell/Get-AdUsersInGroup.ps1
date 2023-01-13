$g = Read-Host "group"

Get-ADGroupMember $g | Select-Object name,SamAccountName | Sort-Object name | Format-Table -AutoSize
