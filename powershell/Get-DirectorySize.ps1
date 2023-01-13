$totalSize = $null
$directory = Read-Host "Directory"

Get-ChildItem $directory -Recurse | ForEach-Object {
    $totalSize += $_.Length
}

$kb = [string]([int]($totalSize / 1.0KB))
$mb = [string]([int]($totalSize / 1.0MB))
$gb = [string]([int]($totalSize / 1.0GB))

Write-Host "$kb KB"
Write-Host "$mb MB"
Write-Host "$gb GB"

$totalSize = $null