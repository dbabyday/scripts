



USE CentralAdmin;
GO


/* user input for exact times 
SELECT DISTINCT CheckDate from dbo.LatchStats ORDER BY CheckDate DESC;
*/
DECLARE
	  @BeginningCheckDate datetimeoffset(7) = NULL  /* '2025-02-11 10:18:14.1086631 -06:00' */
	, @EndingCheckDate    datetimeoffset(7) = NULL  /* '2025-02-11 12:02:43.4657002 -06:00' */
	, @Units              varchar(20)       = 'minutes'; /* seconds, minutes, hours, days */








/* If not set, automatically use times for most recent samples */
IF @EndingCheckDate IS NULL
	SELECT @EndingCheckDate=MAX(CheckDate)
	FROM  dbo.LatchStats;
IF @BeginningCheckDate IS NULL
	SELECT @BeginningCheckDate=MAX(CheckDate)
	FROM  dbo.LatchStats
	WHERE CheckDate<@EndingCheckDate;

/* verify @Units...if not set correctly, default to minutes */
IF @Units NOT IN ('seconds', 'minutes', 'hours', 'days')
	SET @Units='minutes';

/* set the value to convert from ms to the desired @Units */
DECLARE @ConversionFromMs decimal(18,1);
SELECT @ConversionFromMs =
	CASE @Units
		WHEN 'seconds' THEN 1000.0
		WHEN 'minutes' THEN 1000.0 * 60
		WHEN 'hours'   THEN 1000.0 * 60 * 60
		WHEN 'days'    THEN 1000.0 * 60 * 60 * 24
	END;







WITH
	  BeginningWaitStats AS (
		SELECT 
			  l.ServerName
			, l.CheckDate
			, l.latch_class
			, l.waiting_requests_count
			, l.wait_time_ms
			, l.max_wait_time_ms
		FROM
			dbo.LatchStats l
		WHERE
			l.CheckDate=@BeginningCheckDate
	  )
	, EndingWaitStats AS (
		SELECT 
			  l.ServerName
			, l.CheckDate
			, l.latch_class
			, l.waiting_requests_count
			, l.wait_time_ms
			, l.max_wait_time_ms
		FROM
			dbo.LatchStats l
		WHERE
			l.CheckDate=@EndingCheckDate
	  )
SELECT
	  ISNULL(e.ServerName, b.ServerName) AS ServerName
	, b.CheckDate AS SampleBeginning
	, e.CheckDate AS SampleEnd
	, CAST(ROUND(DATEDIFF(MILLISECOND, b.CheckDate, e.CheckDate) / @ConversionFromMs, 1) AS decimal(18,1)) AS SampleDuration
	, @Units AS Units
	, ISNULL(e.latch_class, b.latch_class) AS latch_class
	, CAST(ROUND(
		  CASE
			WHEN b.wait_time_ms <= e.wait_time_ms THEN e.wait_time_ms-b.wait_time_ms
			WHEN b.wait_time_ms > e.wait_time_ms THEN e.wait_time_ms
			WHEN e.wait_time_ms IS NULL THEN 0
			WHEN b.wait_time_ms IS NULL THEN e.wait_time_ms
			ELSE NULL
		  END / @ConversionFromMs, 1
	  ) AS decimal(18,1)) AS wait_time
	, CAST(ROUND(
		CASE
			WHEN b.wait_time_ms <= e.wait_time_ms THEN e.wait_time_ms-b.wait_time_ms
			WHEN b.wait_time_ms > e.wait_time_ms THEN e.wait_time_ms
			WHEN e.wait_time_ms IS NULL THEN 0
			WHEN b.wait_time_ms IS NULL THEN e.wait_time_ms
			ELSE NULL
		END * 1.0 / DATEDIFF(MILLISECOND, @BeginningCheckDate, @EndingCheckDate), 1
	  ) AS decimal(18,1)) AS wait_time_per_unit
	, CASE
		WHEN b.waiting_requests_count <= e.waiting_requests_count THEN e.waiting_requests_count-b.waiting_requests_count
		WHEN b.waiting_requests_count > e.waiting_requests_count THEN e.waiting_requests_count
		WHEN e.waiting_requests_count IS NULL THEN 0
		WHEN b.waiting_requests_count IS NULL THEN e.waiting_requests_count
		ELSE NULL
	  END AS waiting_requests_count
	, CASE
		WHEN e.waiting_requests_count = b.waiting_requests_count THEN 0.0
		ELSE CAST(ROUND((e.wait_time_ms - b.wait_time_ms) * 1.0 / (e.waiting_requests_count - b.waiting_requests_count), 1) AS decimal(18,1))
	  END AS avg_ms_per_wait
FROM
	BeginningWaitStats b
FULL JOIN
	EndingWaitStats e ON e.latch_class=b.latch_class
ORDER BY
	wait_time DESC;


