$directory = Read-Host "Directory"

Get-ChildItem $directory -Recurse | ForEach-Object {
    $totalSize += $_.Length
}

$kb = [string]([int]($totalSize / 1KB))
$mb = [string]([int]($totalSize / 1MB))
$gb = [string]([int]($totalSize / 1GB))

Write-Host "$kb KB"
Write-Host "$mb MB"
Write-Host "$gb GB"
