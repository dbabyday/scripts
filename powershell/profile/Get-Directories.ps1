""
""
"    Directory: " + ((Get-Location).Path.Replace("Microsoft.PowerShell.Core\FileSystem::",""))
""
""
"Mode     LastWriteTime         Length   Name"
"------   -------------------   ------   ----------------------------"
Get-ChildItem | Where-Object { $_.Attributes -eq "Directory" } | Sort-Object Name | ForEach-Object {
	$hlength="      "
	$_.Mode + "   " + (Get-Date -date $_.LastWriteTime -format "yyyy-MM-dd HH:mm:ss") + "   " + $hlength + "   " + $_.Name
}
""
""