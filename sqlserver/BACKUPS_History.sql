/**********************************************************************
* 
* BACKUPS_History.sql
* Author: Aasim Abdullah
* http://blog.sqlauthority.com/2010/11/04/sql-server-finding-last-backup-time-for-all-database/#comment-97777
* 
* Purpose: get backup history from msdb
* 
**********************************************************************/

DECLARE @db NVARCHAR(128) = '';  -- select name FROM sys.databases ORDER BY name;

SELECT 
	s.database_name,
	m.physical_device_name,
	CAST(CAST(s.backup_size / 1048576 AS INT) AS VARCHAR(14)) + ' ' + 'MB' AS [bkSize],
	CAST(CAST(s.compressed_backup_size / 1048576 AS INT) AS VARCHAR(14)) + ' ' + 'MB' AS [CompressedSize],
	CONVERT (NUMERIC (20,1),(CONVERT(FLOAT,s.backup_size) / CONVERT(FLOAT,s.compressed_backup_size))) [Compression Ratio],
	CASE 
		WHEN DATEDIFF(HOUR, s.backup_start_date, s.backup_finish_date) < 24 THEN 
			RIGHT('00' + CAST(DATEDIFF(SECOND, s.backup_start_date, s.backup_finish_date) / 3600 AS VARCHAR(2)),2) + ':' +        -- HOURS
			RIGHT('00' + CAST((DATEDIFF(SECOND, s.backup_start_date, s.backup_finish_date) % 3600) / 60 AS VARCHAR(2)),2) + ':' + -- MINUTES
			RIGHT('00' + CAST((DATEDIFF(SECOND, s.backup_start_date, s.backup_finish_date) % 3600) % 60 AS VARCHAR(2)),2)         -- SECONDS
		ELSE 
			CAST(DATEDIFF(SECOND, s.backup_start_date, s.backup_finish_date) / 86400 AS VARCHAR(2)) + ' day(s) ' +                          -- DAYS
			RIGHT('00' + CAST((DATEDIFF(SECOND, s.backup_start_date, s.backup_finish_date) % 86400) / 3600 AS VARCHAR(2)),2) + ':' +        -- HOURS
			RIGHT('00' + CAST(((DATEDIFF(SECOND, s.backup_start_date, s.backup_finish_date) % 86400) % 3600) / 60 AS VARCHAR(2)),2) + ':' + -- MINUTES
			RIGHT('00' + CAST(((DATEDIFF(SECOND, s.backup_start_date, s.backup_finish_date) % 86400) % 3600) % 60 AS VARCHAR(2)),2)         -- SECONDS
	END AS Duration,
	s.backup_start_date,
	s.backup_finish_date,
	CAST(s.first_lsn AS VARCHAR(50)) AS first_lsn,
	CAST(s.last_lsn AS VARCHAR(50)) AS last_lsn,
	CASE s.[type] 
		WHEN 'D' THEN 'Full'
		WHEN 'I' THEN 'Differential'
		WHEN 'L' THEN 'Transaction Log'
	END AS [BackupType],
	s.server_name,
	s.recovery_model
FROM 
	msdb.dbo.backupset s
INNER JOIN 
	msdb.dbo.backupmediafamily m 
	ON s.media_set_id = m.media_set_id
WHERE 
	s.database_name LIKE '%' + @db + '%'
    --AND s.backup_start_date > '2017-05-12 22:00:00'
    --AND s.backup_start_date < '2017-05-13 05:00:00'
    --AND s.[type] = 'L'
ORDER BY 
	s.backup_start_date DESC, 
	--s.backup_finish_date DESC,
	s.database_name;
GO

