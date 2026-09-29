using namespace System.Management.Automation

$cmd = Get-Command Get-Services
$meta = New-Object CommandMetadata($cmd)
$src = [ProxyCommand]::Create($meta)
$src | Write-Output
