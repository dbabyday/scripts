/*

https://github.com/dbabyday
Warranty: The software is provided "AS IS", without warranty of any kind

Name: cBackupDefaultLocation.sql
Description: See the default location for backups

*/



EXEC  master.dbo.xp_instance_regread @rootkey    = N'HKEY_LOCAL_MACHINE',
                                     @key        = N'Software\Microsoft\MSSQLServer\MSSQLServer',
                                     @value_name = N'BackupDirectory';
