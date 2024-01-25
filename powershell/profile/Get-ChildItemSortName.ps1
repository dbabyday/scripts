""
""
"    Directory: " + ((Get-Location).Path.Replace("Microsoft.PowerShell.Core\FileSystem::",""))
""
""
"Mode     LastWriteTime          Length   Name"
"------   -------------------   -------   ----------------------------"
Get-ChildItem | Where-Object { $_.Attributes -eq "Directory" } | Sort-Object Name | ForEach-Object {
	$bytes=([math]::Round((Get-ChildItem -Recurse -Path $_ | Measure-Object -Sum Length).Sum))
	
	if ($bytes -ge 1TB) {
		$hlength=(($bytes / 1TB).ToString("#.#") + "T").PadLeft(7)
	}
	elseif ($bytes -ge 1GB) {
		$hlength=(($bytes / 1GB).ToString("#.#") + "G").PadLeft(7)
	}
	elseif ($bytes -ge 1MB) {
		$hlength=(($bytes / 1MB).ToString("#.#") + "M").PadLeft(7)
	}
	elseif ($bytes -ge 1KB) {
		$hlength=(($bytes / 1KB).ToString("#.#") + "K").PadLeft(7)
	}
	else {
		$hlength=($bytes).ToString().PadLeft(7)
	}

	$_.Mode + "   " + (Get-Date -date $_.LastWriteTime -format "yyyy-MM-dd HH:mm:ss") + "   " + $hlength + "   " + $_.Name
}

Get-ChildItem | Where-Object{ $_.Attributes -ne "Directory" } | Sort-Object Name | ForEach-Object {
	if ($_.Length -ge 1TB) {
		$hlength=(($_.Length / 1TB).ToString("#.#") + "T").PadLeft(7)
	}
	elseif ($_.Length -ge 1GB) {
		$hlength=(($_.Length / 1GB).ToString("#.#") + "G").PadLeft(7)
	}
	elseif ($_.Length -ge 1MB) {
		$hlength=(($_.Length / 1MB).ToString("#.#") + "M").PadLeft(7)
	}
	elseif ($_.Length -ge 1KB) {
		$hlength=(($_.Length / 1KB).ToString("#.#") + "K").PadLeft(7)
	}
	else {
		$hlength=($_.Length).ToString().PadLeft(7)
	}
	
	$_.Mode + "   " + (Get-Date -date $_.LastWriteTime -format "yyyy-MM-dd HH:mm:ss") + "   " + $hlength + "   " + $_.Name
}
""
""