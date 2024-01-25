""
""
"Directory: " + ((Get-Location).Path.Replace("Microsoft.PowerShell.Core\FileSystem::",""))

$bytes=([math]::Round((Get-ChildItem -Recurse | Measure-Object -Sum Length).Sum))

if ($bytes -ge 1TB) {
	"Size: " + ($bytes / 1TB).ToString("#.#") + "T"
}
elseif ($bytes -ge 1GB) {
	"Size: " + ($bytes / 1GB).ToString("#.#") + "G"
}
elseif ($bytes -ge 1MB) {
	"Size: " + ($bytes / 1MB).ToString("#.#") + "M"
}
elseif ($bytes -ge 1KB) {
	"Size: " + ($bytes / 1KB).ToString("#.#") + "K"
}
else {
	"Size: " + ($bytes).ToString() + "bytes"
}

""
""