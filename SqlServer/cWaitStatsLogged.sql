



USE CentralAdmin;
GO


/* user input for exact times 
SELECT DISTINCT CheckDate from dbo.WaitStats ORDER BY CheckDate DESC;
*/
DECLARE
	  @BeginningCheckDate datetimeoffset(7) = NULL  /* '2025-02-11 10:18:14.1086631 -06:00' */
	, @EndingCheckDate    datetimeoffset(7) = NULL  /* '2025-02-11 12:02:43.4657002 -06:00' */
	, @Units              varchar(20)       = 'minutes'; /* seconds, minutes, hours, days */








/* If not set, automatically use times for most recent samples */
IF @EndingCheckDate IS NULL
	SELECT @EndingCheckDate=MAX(CheckDate)
	FROM  dbo.WaitStats;
IF @BeginningCheckDate IS NULL
	SELECT @BeginningCheckDate=MAX(CheckDate)
	FROM  dbo.WaitStats
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
			  w.ServerName
			, w.CheckDate
			, w.wait_type
			, c.WaitCategory AS wait_category
			, w.wait_time_ms
			, w.signal_wait_time_ms
			, w.waiting_tasks_count
		FROM
			dbo.WaitStats w
		INNER JOIN
			dbo.BlitzFirst_WaitStats_Categories c ON c.WaitType=w.wait_type
		WHERE
			w.CheckDate=@BeginningCheckDate
			AND c.Ignorable=0
	  )
	, EndingWaitStats AS (
		SELECT 
			  w.ServerName
			, w.CheckDate
			, w.wait_type
			, c.WaitCategory AS wait_category
			, w.wait_time_ms
			, w.signal_wait_time_ms
			, w.waiting_tasks_count
		FROM
			dbo.WaitStats w
		INNER JOIN
			dbo.BlitzFirst_WaitStats_Categories c ON c.WaitType=w.wait_type
		WHERE
			w.CheckDate=@EndingCheckDate
			AND c.Ignorable=0
	  )
SELECT
	  ISNULL(e.ServerName, b.ServerName) AS ServerName
	, b.CheckDate AS SampleBeginning
	, e.CheckDate AS SampleEnd
	, CAST(ROUND(DATEDIFF(MILLISECOND, b.CheckDate, e.CheckDate) / @ConversionFromMs, 1) AS decimal(18,1)) AS SampleDuration
	, @Units AS Units
	, ISNULL(e.wait_type, b.wait_type) AS wait_type
	, ISNULL(e.wait_category, b.wait_category) AS wait_category
	, CAST(ROUND(
		  CASE
			WHEN b.wait_time_ms <= e.wait_time_ms THEN e.wait_time_ms-b.wait_time_ms
			WHEN b.wait_time_ms > e.wait_time_ms THEN e.wait_time_ms
			WHEN e.wait_time_ms IS NULL THEN 0
			WHEN b.wait_time_ms IS NULL THEN e.wait_time_ms
			ELSE NULL
		  END / @ConversionFromMs, 1
	  ) AS decimal(18,1)) AS [Wait Time]
	, CAST(ROUND(
		CASE
			WHEN b.wait_time_ms <= e.wait_time_ms THEN e.wait_time_ms-b.wait_time_ms
			WHEN b.wait_time_ms > e.wait_time_ms THEN e.wait_time_ms
			WHEN e.wait_time_ms IS NULL THEN 0
			WHEN b.wait_time_ms IS NULL THEN e.wait_time_ms
			ELSE NULL
		END * 1.0 / DATEDIFF(MILLISECOND, @BeginningCheckDate, @EndingCheckDate), 1
	  ) AS decimal(18,1)) AS [Wait Time Per Unit]
	, CAST(ROUND(
		CASE
			WHEN b.signal_wait_time_ms <= e.signal_wait_time_ms THEN e.signal_wait_time_ms-b.signal_wait_time_ms
			WHEN b.signal_wait_time_ms > e.signal_wait_time_ms THEN e.signal_wait_time_ms
			WHEN e.signal_wait_time_ms IS NULL THEN 0
			WHEN b.signal_wait_time_ms IS NULL THEN e.signal_wait_time_ms
			ELSE NULL
		END / @ConversionFromMs, 1
	  ) AS decimal(18,1)) AS [Signal Wait Time]
	, CASE
		WHEN e.wait_time_ms = b.wait_time_ms THEN 0.0
		ELSE CAST(ROUND((e.signal_wait_time_ms - b.signal_wait_time_ms) * 1.0 / (e.wait_time_ms - b.wait_time_ms) * 100.0, 1) AS decimal(18,1))
	  END AS [Percent Signal Waits]
	, CASE
		WHEN b.waiting_tasks_count <= e.waiting_tasks_count THEN e.waiting_tasks_count-b.waiting_tasks_count
		WHEN b.waiting_tasks_count > e.waiting_tasks_count THEN e.waiting_tasks_count
		WHEN e.waiting_tasks_count IS NULL THEN 0
		WHEN b.waiting_tasks_count IS NULL THEN e.waiting_tasks_count
		ELSE NULL
	  END AS [Number of Waits]
	, CASE
		WHEN e.waiting_tasks_count = b.waiting_tasks_count THEN 0.0
		ELSE CAST(ROUND((e.wait_time_ms - b.wait_time_ms) * 1.0 / (e.waiting_tasks_count - b.waiting_tasks_count), 1) AS decimal(18,1))
	  END AS [Avg ms Per Wait]
FROM
	BeginningWaitStats b
FULL JOIN
	EndingWaitStats e ON e.wait_type=b.wait_type
ORDER BY
	[Wait Time] DESC;


