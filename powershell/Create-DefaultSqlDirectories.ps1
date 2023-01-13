<######################################################################################################################
# 
# Create-DefaultSqlDirectories.ps1
# 
# Author: James Lutsey
# Date:   2018-08-06
# 
# Purpose: Checks if standard directories for SQL Server default locations exist. If not, create them.
#              - F:\Audits
#              - F:\Backups
#              - F:\Databases
#              - G:\Logs
#              - T:\TempDB
# 
# Date        Name                  Description of change
# ----------  --------------------  ---------------------------------------------------------------------------------
# 
# 
######################################################################################################################>

$serverName = Read-Host "Server Name"

Write-Host ""
Write-Host "Checking Server: $serverName"
Write-Host "-------------------------------------------------------------------------"

# verify you can connect to the server
if ( -not (Test-Connection -ComputerName $serverName -Count 1 -Quiet) ) {
    if ( -not (Test-Connection -ComputerName $ServerName -Count 3 -Delay 2 -Quiet) ) {
        Write-Warning "Unable to connect to $serverName"
        Write-Host ""
        Exit
    }
}
Write-Host (Get-Date -format s) " | Connection to server successful"
Write-Host ""

# verify standard volumes exist (F, G, and T)
$f = $false
$g = $false
$t = $false

Get-WmiObject win32_volume -ComputerName $serverName | ForEach-Object {
    if ($_.Name -eq "F:\") { $f = $true }
    if ($_.Name -eq "G:\") { $g = $true }
    if ($_.Name -eq "T:\") { $t = $true }
}

if (-not $f) { Write-Warning -Message "F:\ does not exist" } else { Write-Host (Get-Date -format s) " | Volume F:\ exists" }
if (-not $g) { Write-Warning -Message "G:\ does not exist" } else { Write-Host (Get-Date -format s) " | Volume G:\ exists" }
if (-not $t) { Write-Warning -Message "T:\ does not exist" } else { Write-Host (Get-Date -format s) " | Volume T:\ exists" }

if ( (-not $f) -or (-not $g) -or (-not $t) ) { 
    Write-Host ""
    Exit 
}

Write-Host ""


# verify the directories; create them if they do not exist
$path = "\\$serverName\F$\"
$audits = $path + "Audits\"
if (Test-Path $audits) {
    Write-Host (Get-Date -format s) " | Directory F:\Audits\ exists"
}
else {
    New-Item -Path $path -Name "Audits" -ItemType Directory
    Write-Host (Get-Date -format s) " | Created directory F:\Audits\"
}

$backups = $path + "Backups\"
if (Test-Path $backups) {
    Write-Host (Get-Date -format s) " | Directory F:\Backups\ exists"
}
else {
    New-Item -Path $path -Name "Backups" -ItemType Directory
    Write-Host (Get-Date -format s) " | Created directory F:\Backups\"
}

$databases = $path + "Databases\"
if (Test-Path $databases) {
    Write-Host (Get-Date -format s) " | Directory F:\Databases\ exists"
}
else {
    New-Item -Path $path -Name "Databases" -ItemType Directory
    Write-Host (Get-Date -format s) " | Created directory F:\Databases\"
}

$path = "\\$serverName\G$\"
$logs = $path + "Logs\"
if (Test-Path $logs) {
    Write-Host (Get-Date -format s) " | Directory G:\Logs\ exists"
}
else {
    New-Item -Path $path -Name "Logs" -ItemType Directory
    Write-Host (Get-Date -format s) " | Created directory G:\Logs\"
}

$path = "\\$serverName\T$\"
$tempdb = $path + "TempDB\"
if (Test-Path $tempdb) {
    Write-Host (Get-Date -format s) " | Directory T:\TempDB\ exists"
}
else {
    New-Item -Path $path -Name "TempDB" -ItemType Directory
    Write-Host (Get-Date -format s) " | Created directory T:\TempDB\"
}

Write-Host ""

Write-Host (Get-Date -format s) " | Finished"
Write-Host ""