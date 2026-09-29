/* how long has sql server been up */
SELECT sqlserver_start_time, DATEDIFF(DAY, sqlserver_start_time, GETDATE()) AS uptime_days FROM sys.dm_os_sys_info;


/* percent plans cached by days */
SELECT 
	  FORMAT(DATEADD(DAY,DATEDIFF(SECOND,qs.creation_time,GETDATE())/-86400-1,GETDATE()), 'yyyy-MM-dd HH:mm:ss') + ' - ' + FORMAT(DATEADD(DAY,DATEDIFF(SECOND,qs.creation_time,GETDATE())/-86400,GETDATE()), 'yyyy-MM-dd HH:mm:ss') TimeInterval
	, DATEDIFF(SECOND,qs.creation_time,GETDATE())/86400 DaysCached
	, COUNT(1) Qty
	, CAST(ROUND(CAST(COUNT(1) AS DECIMAL(12,1)) / (SELECT COUNT(1) FROM sys.dm_exec_query_stats) * 100, 0) AS INT) PercentOfPlans
FROM
	sys.dm_exec_query_stats qs
GROUP BY
	  DATEDIFF(SECOND,qs.creation_time,GETDATE())/86400
	, DATEDIFF(SECOND,qs.creation_time,GETDATE())/-86400
ORDER BY
	DaysCached;




/* percent plans cached by hours for the past 24 hours */
SELECT 
	  FORMAT(DATEADD(HOUR,DATEDIFF(SECOND,qs.creation_time,GETDATE())/-3600-1,GETDATE()), 'HH:mm:ss') + ' - ' + FORMAT(DATEADD(HOUR,DATEDIFF(SECOND,qs.creation_time,GETDATE())/-3600,GETDATE()), 'HH:mm:ss') TimeInterval
	, DATEDIFF(SECOND,qs.creation_time,GETDATE())/3600 HoursCached
	, COUNT(1) Qty
	, CAST(ROUND(CAST(COUNT(1) AS DECIMAL(12,1)) / (SELECT COUNT(1) FROM sys.dm_exec_query_stats) * 100, 1) AS DECIMAL(12,1)) PercentOfPlans
FROM
	sys.dm_exec_query_stats qs
WHERE
	qs.creation_time > DATEADD(HOUR,-24,GETDATE())
GROUP BY
	  DATEDIFF(SECOND,qs.creation_time,GETDATE())/3600
	, DATEDIFF(SECOND,qs.creation_time,GETDATE())/-3600
ORDER BY
	HoursCached;


