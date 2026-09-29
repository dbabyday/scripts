


USE CentralAdmin;
GO





/* USER INPUT 
select latch_class from sys.dm_os_latch_stats order by latch_class;
select distinct latch_class from CentralAdmin.dbo.LatchStats order by latch_class;
select distinct checkdate from dbo.LatchStats order by checkdate desc;
*/
DECLARE
	  @latch_class nvarchar(60) = N'ACCESS_METHODS_DATASET_PARENT'  /* ACCESS_METHODS_DATASET_PARENT, BUFFER */
	, @Units varchar(20)        = 'minutes'       /* milliseconds, seconds, minutes, hours, days */
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
	FROM  dbo.LatchStats;
IF @EndingCheckDate IS NULL
	SELECT @EndingCheckDate=MAX(CheckDate)
	FROM  dbo.LatchStats;




WITH
	  OneLatchClass AS (
		SELECT
			  l.ServerName
			, l.CheckDate
			, l.latch_class
			, l.wait_time_ms
			, l.waiting_requests_count
			, ROW_NUMBER() OVER (ORDER BY l.CheckDate) AS JoinKeyStart
			, ROW_NUMBER() OVER (ORDER BY l.CheckDate) - 1 AS JoinKeyEnd
		FROM
			dbo.LatchStats l
		WHERE
			l.latch_class=@latch_class
			AND l.CheckDate >= @BeginningCheckDate
			AND l.CheckDate <= @EndingCheckDate
	  )
SELECT
	  @@SERVERNAME AS ServerName
	, s.latch_class
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
		WHEN e.waiting_requests_count >= s.waiting_requests_count AND e.wait_time_ms >= s.wait_time_ms THEN CAST(ROUND((e.wait_time_ms - s.wait_time_ms) / @ConversionFromMs, 0) AS INT)
		ELSE NULL
	  END AS wait_time
	, CASE
		WHEN e.waiting_requests_count >= s.waiting_requests_count AND e.wait_time_ms >= s.wait_time_ms THEN 
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
		WHEN e.waiting_requests_count >= s.waiting_requests_count AND e.wait_time_ms >= s.wait_time_ms THEN e.waiting_requests_count - s.waiting_requests_count
		ELSE NULL
	  END AS waiting_requests_count
	, CASE
		WHEN e.waiting_requests_count > s.waiting_requests_count AND e.wait_time_ms >= s.wait_time_ms THEN CAST(ROUND((e.wait_time_ms - s.wait_time_ms) / @ConversionFromMs / (e.waiting_requests_count - s.waiting_requests_count), 1) AS decimal(19,1))
		ELSE NULL
	  END AS avg_wait_time_per_wait
	, @Units AS Units
FROM
	OneLatchClass s
INNER JOIN
	OneLatchClass e ON e.JoinKeyEnd=s.JoinKeyStart
WHERE
	e.CheckDate > s.CheckDate
	and s.CheckDate>DATEADD(DAY,-1,GETDATE())
ORDER BY
	S.CheckDate DESC;