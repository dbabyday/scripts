


USE CentralAdmin;
GO





/* USER INPUT 
select wait_type from sys.dm_os_wait_stats order by wait_type;
select distinct wait_type from CentralAdmin.dbo.WaitStats order by wait_type;
select distinct checkdate from dbo.waitstats order by checkdate desc;
*/
DECLARE
	  @wait_type nvarchar(60) = N'HADR_SYNC_COMMIT'  /* Common Always On wait types to check: HADR_SYNC_COMMIT, WRITELOG, HADR_DATABASE_FLOW_CONTROL, HADR_TRANSPORT_FLOW_CONTROL */
	, @Units varchar(20)      = 'seconds'       /* milliseconds, seconds, minutes, hours, days */
	, @BeginningCheckDate datetimeoffset(7) = NULL   /* '2025-12-04 01:00:00.0817655 +08:00' */
	, @EndingCheckDate    datetimeoffset(7) = NULL;  /* '2025-12-04 03:00:01.0303153 +08:00' */






/* verify @Units...if not set correctly, default to milliseconds */
IF @Units NOT IN ('milliseconds', 'seconds', 'minutes', 'hours', 'days')
	SET @Units='milliseconds';

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

/* If dates not set, automatically use min and max times times in the data set */
IF @BeginningCheckDate IS NULL
	SELECT @BeginningCheckDate=MIN(CheckDate)
	FROM  dbo.WaitStats;
IF @EndingCheckDate IS NULL
	SELECT @EndingCheckDate=MAX(CheckDate)
	FROM  dbo.WaitStats;




WITH
	  OneWaitType AS (
		SELECT
			  w.ServerName
			, w.CheckDate
			, w.wait_type
			, w.wait_time_ms
			, w.signal_wait_time_ms
			, w.waiting_tasks_count
			, ROW_NUMBER() OVER (ORDER BY w.CheckDate) AS JoinKeyStart
			, ROW_NUMBER() OVER (ORDER BY w.CheckDate) - 1 AS JoinKeyEnd
		FROM
			dbo.WaitStats w
		WHERE
			w.wait_type=@wait_type
			AND w.CheckDate >= @BeginningCheckDate
			AND w.CheckDate <= @EndingCheckDate
	  )
SELECT
	  @@SERVERNAME AS ServerName
	, s.wait_type
	, s.CheckDate AS StartCheckDate
	, e.CheckDate AS EndCheckDate
	, CASE
		WHEN @Units = 'milliseconds' THEN DATEDIFF(MILLISECOND, s.CheckDate, e.CheckDate)
		WHEN @Units = 'seconds' THEN DATEDIFF(SECOND, s.CheckDate, e.CheckDate)
		WHEN @Units = 'minutes' THEN DATEDIFF(MINUTE, s.CheckDate, e.CheckDate)
		WHEN @Units = 'hours' THEN DATEDIFF(HOUR, s.CheckDate, e.CheckDate)
		WHEN @Units = 'days' THEN DATEDIFF(DAY, s.CheckDate, e.CheckDate)
	  END AS sample_duration
	, CASE
		WHEN e.waiting_tasks_count >= s.waiting_tasks_count AND e.wait_time_ms >= s.wait_time_ms AND e.signal_wait_time_ms >= s.signal_wait_time_ms THEN CAST(ROUND((e.wait_time_ms - s.wait_time_ms) / @ConversionFromMs, 0) AS INT)
		ELSE NULL
	  END AS wait_time
	, CASE
		WHEN e.waiting_tasks_count >= s.waiting_tasks_count AND e.wait_time_ms >= s.wait_time_ms AND e.signal_wait_time_ms >= s.signal_wait_time_ms THEN 
			CAST(ROUND(
				(e.wait_time_ms - s.wait_time_ms) / @ConversionFromMs / 
					CASE
						WHEN @Units = 'milliseconds' THEN DATEDIFF(MILLISECOND, s.CheckDate, e.CheckDate)
						WHEN @Units = 'seconds' THEN DATEDIFF(SECOND, s.CheckDate, e.CheckDate)
						WHEN @Units = 'minutes' THEN DATEDIFF(MINUTE, s.CheckDate, e.CheckDate)
						WHEN @Units = 'hours' THEN DATEDIFF(HOUR, s.CheckDate, e.CheckDate)
						WHEN @Units = 'days' THEN DATEDIFF(DAY, s.CheckDate, e.CheckDate)
					  END
			, 2) AS decimal(19,2))
		ELSE NULL
	  END AS wait_time_per_time
	, CASE
		WHEN e.waiting_tasks_count >= s.waiting_tasks_count AND e.wait_time_ms >= s.wait_time_ms AND e.signal_wait_time_ms >= s.signal_wait_time_ms THEN CAST(ROUND((e.signal_wait_time_ms - s.signal_wait_time_ms) / @ConversionFromMs, 0) AS INT)
		ELSE NULL
	  END AS signal_wait_time
	, CASE
		WHEN e.waiting_tasks_count >= s.waiting_tasks_count AND e.wait_time_ms >= s.wait_time_ms AND e.signal_wait_time_ms >= s.signal_wait_time_ms THEN e.waiting_tasks_count - s.waiting_tasks_count
		ELSE NULL
	  END AS waiting_tasks_count
	, CASE
		WHEN e.waiting_tasks_count > s.waiting_tasks_count AND e.wait_time_ms >= s.wait_time_ms AND e.signal_wait_time_ms >= s.signal_wait_time_ms THEN CAST(ROUND((e.wait_time_ms - s.wait_time_ms) / @ConversionFromMs / (e.waiting_tasks_count - s.waiting_tasks_count), 1) AS decimal(19,1))
		ELSE NULL
	  END AS avg_wait_time_per_wait
	, @Units AS Units
FROM
	OneWaitType s
INNER JOIN
	OneWaitType e ON e.JoinKeyEnd=s.JoinKeyStart
WHERE
	e.CheckDate > s.CheckDate
	and s.CheckDate>DATEADD(DAY,-1,GETDATE())
ORDER BY
	S.CheckDate DESC;
