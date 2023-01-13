<#
C:\JamesScripts\PowerShell\Create-ModelLogBackupDirectory.ps1
#>

$instance = 'GDL-SQL-PD-001'

#$backupDirectory = '\\na\databackup\Neen_SQL_Backups\'
#$backupDirectory = '\\na\databackup\Dev_SQL_Backups\'
$backupDirectory = '\\na\databackup\Guad_SQL_Backups\'

$instanceBackupDirectory = $backupDirectory + $instance.Replace('\','$') + '\'
$dbBackupDirectory     = $instanceBackupDirectory + 'model\'
$logBackupDirectory    = $dbBackupDirectory     + 'LOG\'

If (Test-Path -Path $logBackupDirectory) {
    'The path exists: ' + $logBackupDirectory
}
Else {
    If (Test-Path -Path $dbBackupDirectory) {
        'The database backup directory exists.'
        'Creating the LOG directory...'
        New-Item -Path $dbBackupDirectory -Name LOG -ItemType Directory
        'Finished, the path now exists: ' + $logBackupDirectory
    }
    Else {
        If (Test-Path -Path $instanceBackupDirectory) {
            'The instance backup directory exists.'
            'Creating the database backup directory...'
            New-Item -Path $instanceBackupDirectory -Name model -ItemType Directory                

            'Creating the LOG directory...'
            New-Item -Path $dbBackupDirectory -Name LOG -ItemType Directory

            'Finished, the path now exists: ' + $logBackupDirectory
        }
        Else {
                'Create the instance backup directory...'
                New-Item -Path $backupDirectory -Name $instance.Replace('\','$') -ItemType Directory                

                'Creating the database backup directory...'
                New-Item -Path $instanceBackupDirectory -Name model -ItemType Directory                

                'Creating the LOG directory...'
                New-Item -Path $dbBackupDirectory -Name LOG -ItemType Directory

                'Finished, the path now exists: ' + $logBackupDirectory
        }
    }
}

"You can run the following command:"
""
":CONNECT $instance"
"BACKUP LOG model TO DISK = N'" + $logBackupDirectory + ($instance.Replace('\','$')) + "_model_LOG_" + (Get-Date -Format yyyyMMdd) + ".trn';"
"GO"
""




