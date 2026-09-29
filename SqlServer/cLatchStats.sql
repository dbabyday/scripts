





DECLARE @Units varchar(20) = 'minutes'; /* milliseconds, seconds, minutes, hours, days */








/* verify @Units...if not set correctly, default to minutes */
IF @Units NOT IN ('milliseconds', 'seconds', 'minutes', 'hours', 'days')
	SET @Units='minutes';

/* set the value to convert from ms to the desired @Units */
DECLARE @ConversionFromMs decimal(18,1);
SELECT @ConversionFromMs =
	CASE @Units
		WHEN 'milliseconds' THEN 1.0
		WHEN 'seconds'      THEN 1000.0
		WHEN 'minutes'      THEN 1000.0 * 60
		WHEN 'hours'        THEN 1000.0 * 60 * 60
		WHEN 'days'         THEN 1000.0 * 60 * 60 * 24
	END;



/* get the SQL Server uptime */
DECLARE @UptimeSeconds INT;
SELECT @UptimeSeconds = DATEDIFF(SECOND, sqlserver_start_time, GETDATE()) FROM sys.dm_os_sys_info;




SELECT 
	  latch_class
	, CAST(ROUND(wait_time_ms / @ConversionFromMs, 0) AS INT) AS wait_time
	, CAST(ROUND(@UptimeSeconds / @ConversionFromMs * 1000.0, 0) AS INT) AS sql_server_uptime
	, @Units AS Units
	, CAST(ROUND(100.0 * wait_time_ms / SUM(wait_time_ms) OVER(), 0) AS INT) AS '%_of_latches'
	, waiting_requests_count
FROM 
	sys.dm_os_latch_stats
WHERE
	wait_time_ms > 0
ORDER BY 
	wait_time_ms DESC;
