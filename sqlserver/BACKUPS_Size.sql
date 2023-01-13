/**************************************************************************************
*
*  Author: Kraig Hughes
*  Date: 3/10/2004
*  Purpose: Lists all full database backups, their date and time, the size of the
*  backup and the amount of disk allocated to the database.
*
**************************************************************************************/

SELECT bus.database_name AS [Database],
	CONVERT(DATETIME, (LEFT(bus.backup_start_date, 11))) AS [Backup Date],
	MAX(STR(bus.backup_size/1048576, 15, 2)) AS [Data_Size_MB],
	MAX(STR(buf.file_size/1048576, 15, 2)) AS [Disk_Allocated_MB]
FROM msdb..backupfile AS buf 
INNER JOIN msdb..backupset AS bus 
ON buf.backup_set_id = bus.backup_set_id 
WHERE buf.file_type = 'D'
AND bus.type = 'D'
--AND bus.database_name = DB_NAME()
GROUP BY bus.database_name,
CONVERT(DATETIME, (LEFT(bus.backup_start_date, 11)))
ORDER BY [Database], [Backup Date]