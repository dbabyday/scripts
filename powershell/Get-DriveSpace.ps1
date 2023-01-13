
If($null -eq $cn) {
	$cn = Read-Host "Enter the ComputerName"
}

Get-Date -format s
Get-WmiObject win32_volume -ComputerName $cn | 
    Where-Object  { $_.Name -NotLike "\\?\Volume*" } | 
    select        SystemName,Name,Freespace,Capacity | 
    Sort-Object   Name | 
    Format-Table  -AutoSize SystemName,
                            Name,
                            @{Name="free_GB"; Expression={"{0:N1}" -f (($_.Freespace)/1GB)};              align="right"},
                            @{Name="size_GB"; Expression={"{0:N1}" -f (($_.Capacity)/1GB)};               align="right"},
                            @{Name="pct_free";Expression={"{0:N0}" -f (($_.Freespace)/($_.Capacity)*100)};align="right"}




