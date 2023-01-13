"Mode     LastWriteTime         Length   Name"
"------   -------------------   ------   ----------------------------"
Get-ChildItem | Sort-Object Name | ForEach-Object {
	if ($_.Mode -eq "d-----") {
		$hlength="      "
	}
	elseif ($_.Length -ge 1000000000000) {
		$hlength=(($_.Length / 1000000000000).ToString("#.#") + "T").PadLeft(6)
	}
	elseif ($_.Length -ge 1000000000) {
		$hlength=(($_.Length / 1000000000).ToString("#.#") + "G").PadLeft(6)
	}
	elseif ($_.Length -ge 1000000) {
		$hlength=(($_.Length / 1000000).ToString("#.#") + "M").PadLeft(6)
	}
	elseif ($_.Length -ge 1000) {
		$hlength=(($_.Length / 1000).ToString("#.#") + "K").PadLeft(6)
	}
	else {
		$hlength=($_.Length).ToString().PadLeft(6)
	}
	
	$_.Mode + "   " + (Get-Date -date $_.LastWriteTime -format "yyyy-MM-dd HH:mm:ss") + "   " + $hlength + "   " + $_.Name
}