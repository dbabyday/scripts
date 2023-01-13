SELECT 
	* 
FROM 
	CentralAdmin.dbo.CommandLog
WHERE 
	CommandType = 'DBCC_CHECKDB' -- SELECT DISTINCT CommandType FROM CentralAdmin.dbo.CommandLog
	AND StartTime > '2016-05-04'
	AND ( ErrorNumber != 0 OR ErrorNumber IS NULL )
ORDER BY 
	StartTime ASC
