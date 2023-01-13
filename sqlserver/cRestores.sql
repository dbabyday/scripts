/****************************************************************************************
* 
* DATABASES_RestoreInfo.sql
* 
* Author: Thomas LaRock
* https://www.mssqltips.com/sqlservertip/1860/identify-when-a-sql-server-database-was-restored-the-source-and-backup-date/
* 
*****************************************************************************************/

USE msdb;

SELECT     r.destination_database_name,
           r.restore_date,
           s.database_name AS source_database_name,
           s.type AS backup_type,
           s.backup_start_date,
           s.backup_finish_date,
           m.physical_device_name AS backup_file_used_for_restore
FROM       dbo.restorehistory r
INNER JOIN dbo.backupset AS s ON r.backup_set_id = s.backup_set_id
INNER JOIN dbo.backupmediafamily AS m ON s.media_set_id = m.media_set_id
--WHERE      r.restore_date > '2017-10-18T11:45:00'
ORDER BY   --r.destination_database_name,
           r.restore_date DESC;

