###############################################################
# 
# Backup my local files to network share
# run as james.lutsey
# 
###############################################################



#------------------------------------------------------------
#--// COPY TO MY USERS NETWORK LOCATION                  //--
#------------------------------------------------------------

$jlPath     = " "
$backupPath = $jlPath + "Backups\" + (Get-Date -format yyyy-MM-dd)
$i          = 2

While (Test-Path $backupPath) {
    If ($backupPath -notmatch "_") {
        $backupPath += "_" + ($i -as [string])
    }
    Else {
        $backupPath = $backupPath.Substring(0,$backupPath.IndexOf("_")) + "_" + ($i -as [string])
    }
    
    $i++
}

New-Item -Path $backupPath -ItemType Directory

# my working folders on the database share
Copy-Item -Path "\\neen-dsk-011\it$\database\users\James\JamesDocumentation" -Destination $backupPath -Recurse
Copy-Item -Path "\\neen-dsk-011\it$\database\users\James\JamesDownloads"     -Destination $backupPath -Recurse
Copy-Item -Path "\\neen-dsk-011\it$\database\users\James\JamesProjects"      -Destination $backupPath -Recurse
Copy-Item -Path "\\neen-dsk-011\it$\database\users\James\JamesScripts"       -Destination $backupPath -Recurse
#Copy-Item -Path "\\neen-dsk-011\it$\database\users\James\JamesTools"         -Destination $backupPath -Recurse

# config files from my VDI
Copy-Item -Path "C:\oracle\product\19.0.0\client_1\network\admin\tnsnames.ora"                             -Destination $backupPath



#------------------------------------------------------------
#--// DELETE OLD BACKUPS                                 //--
#------------------------------------------------------------

$backupRoot = '\\neen-dsk-010\users24$\james.lutsey\Backups\'
$directories = @()
$today = (Get-Date).Date

# keep everything for the past 2 weeks
Get-ChildItem $backupRoot | Where-Object { [datetime](($_.Name).Substring(0,10)) -ge ($today.AddDays(-14)) } | Sort-Object Name | ForEach-Object {
    $directory = New-Object -TypeName psobject
    $directory | Add-Member -MemberType NoteProperty -Name 'Path' -Value ($_.FullName + '\')
    $directory | Add-Member -MemberType NoteProperty -Name 'Delete' -Value 'no'
    $directories += $directory
}

# keep one backup per week for past 2 months
If ($today.DayOfWeek -match 'Friday')    { $fridayBottom = $today.AddDays(-21) }
If ($today.DayOfWeek -match 'Thursday')  { $fridayBottom = $today.AddDays(-20) }
If ($today.DayOfWeek -match 'Wednesday') { $fridayBottom = $today.AddDays(-19) }
If ($today.DayOfWeek -match 'Tuesday')   { $fridayBottom = $today.AddDays(-18) }
If ($today.DayOfWeek -match 'Monday')    { $fridayBottom = $today.AddDays(-17) }
If ($today.DayOfWeek -match 'Sunday')    { $fridayBottom = $today.AddDays(-16) }
If ($today.DayOfWeek -match 'Saturday')  { $fridayBottom = $today.AddDays(-15) }
$fridayTop = $today.AddDays(-14)
$monthTop = ([datetime]([string]$today.Year + '-' + [string]$today.Month + '-01')).AddMonths(-2)

While ( $fridayTop -ge $monthTop ) {
    $count = 0

    Get-ChildItem $backupRoot | Where-Object { ([datetime](($_.Name).Substring(0,10)) -lt $fridayTop) -and ([datetime](($_.Name).Substring(0,10)) -ge $fridayBottom) } | Sort-Object Name | ForEach-Object {
        $directory = New-Object -TypeName psobject
        $directory | Add-Member -MemberType NoteProperty -Name 'Path' -Value ($_.FullName + '\')

        If ( $count -eq 0 ) {
            # save the Friday backup (or if no Friday backup, the next one for the week)
            $directory | Add-Member -MemberType NoteProperty -Name 'Delete' -Value 'no'
        }
        Else {
            # delete the rest for the week
            $directory | Add-Member -MemberType NoteProperty -Name 'Delete' -Value 'yes'
        }
        
        $directories += $directory
        $count ++
    }

    $fridayTop = $fridayBottom
    $fridayBottom = $fridayBottom.AddDays(-7)
}

# delete all backups older than 2 months
Get-ChildItem $backupRoot | Where-Object { ([datetime](($_.Name).Substring(0,10)) -lt $monthTop) } | Sort-Object Name | ForEach-Object {
    $directory = New-Object -TypeName psobject
    $directory | Add-Member -MemberType NoteProperty -Name 'Path' -Value ($_.FullName + '\')
    $directory | Add-Member -MemberType NoteProperty -Name 'Delete' -Value 'yes'
    $directories += $directory
    $count ++
}

        
# TEST: display directories and if they will be deleted or not
# $directories | Sort-Object Path | Format-Table -AutoSize

# delete the directories
$directories | Where-Object { $_.Delete -match 'yes' } | ForEach-Object {
    While (Test-Path -Path $_.Path) { Remove-Item -Path $_.Path -Force -Recurse -ErrorAction SilentlyContinue }
}



#------------------------------------------------------------
#--// CLEAN UP THE RECYLE BIN                            //--
#------------------------------------------------------------

Clear-RecycleBin -Force



#------------------------------------------------------------
#--// SHUTDOWN LOCAL COMPUTER                            //--
#------------------------------------------------------------

#Stop-Computer -Force
#Restart-Computer -Force


<#
IF ((Get-Date).DayofWeek -eq 'Friday') {
    Stop-Computer -Force
    #shutdown.exe -s -f -t 05
    #shutdown.exe -r -t 5
}
Else {
    Restart-Computer -Force
}
#>

#shutdown.exe -r -t 5
