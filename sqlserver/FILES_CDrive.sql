----------------------------------------------------------------
--// FIND DB FILES ON C:\                                   //--
----------------------------------------------------------------

SELECT 
	DB_NAME(database_id) AS 'database',
	name AS [file_name], 
	type_desc,
	size * 8 / 1024 AS [size_MB],  -- size is in 8 KB pages
	physical_name
FROM 
    sys.master_files
WHERE 
    physical_name LIKE N'C:\%'
	AND DB_NAME(database_id) NOT IN ('master', 'model', 'msdb')
	AND type_desc IN ('ROWS', 'LOG');
GO


