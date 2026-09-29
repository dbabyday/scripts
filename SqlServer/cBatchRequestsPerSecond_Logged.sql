

USE CentralAdmin;
GO



/* user input for exact times 
SELECT DISTINCT CheckDate from dbo.PerfmonStats ORDER BY CheckDate DESC;
*/
DECLARE
	  @BeginningCheckDate DATETIMEOFFSET(7) = DATEADD(DAY,-1,SYSDATETIMEOFFSET())  -- '2025-09-21 00:00:00.0000000 -05:00'  -- NULL
	, @EndingCheckDate    DATETIMEOFFSET(7) = SYSDATETIMEOFFSET()  -- '2025-09-22 00:00:00.0000000 -05:00'  -- NULL
	, @Units              VARCHAR(20)       = 'minutes' /* seconds, minutes, hours, days */
	, @UnitsConversion    DECIMAL(12,2);

SELECT
	@UnitsConversion = CASE @Units
		WHEN 'seconds' THEN 1.0
		WHEN 'minutes' THEN 60.0
		WHEN 'hours'   THEN 3600.0
		WHEN 'days'    THEN 86400.0
		ELSE 1.0
	END;






/* If not set, automatically use times for most recent samples */
IF @EndingCheckDate IS NULL
	SELECT @EndingCheckDate=MAX(CheckDate)
	FROM  dbo.PerfmonStats;
IF @BeginningCheckDate IS NULL
	SELECT @BeginningCheckDate=MAX(CheckDate)
	FROM  dbo.PerfmonStats;






WITH
	  RowDates AS (
		SELECT ROW_NUMBER() OVER (ORDER BY ServerName, CheckDate) ID,
		       CheckDate
		FROM dbo.PerfmonStats
		WHERE counter_name='Batch Requests/sec'
	  )
	, CheckDates AS (
		SELECT ThisDate.CheckDate,
		       LastDate.CheckDate as PreviousCheckDate
		FROM RowDates ThisDate
		JOIN RowDates LastDate ON ThisDate.ID = LastDate.ID + 1
	  )
SELECT
	  CAST(ROUND((pMon.cntr_value - pMonPrior.cntr_value) * 1.0 / DATEDIFF(ss, pMonPrior.CheckDate, pMon.CheckDate), 0) AS INT) AS BatchRequestsPerSecond
	, CAST(CAST(ROUND(DATEDIFF(SECOND,pMonPrior.CheckDate,pMon.CheckDate) / @UnitsConversion, 0) AS INT) AS varchar(20)) + ' ' + @Units AS ElapsedTime
	, pMonPrior.CheckDate AS StartCheckDate
	, pMon.CheckDate AS EndCheckDate
	, pMon.object_name
	, pMon.counter_name
	, pMon.ServerName
FROM
	dbo.PerfmonStats pMon
INNER JOIN
	CheckDates Dates ON Dates.CheckDate = pMon.CheckDate
INNER JOIN
	dbo.PerfmonStats pMonPrior ON
		Dates.PreviousCheckDate = pMonPrior.CheckDate
		AND pMon.ServerName     = pMonPrior.ServerName
		AND pMon.object_name    = pMonPrior.object_name
		AND pMon.counter_name   = pMonPrior.counter_name
		AND pMon.instance_name  = pMonPrior.instance_name
WHERE
	DATEDIFF(MI, pMonPrior.CheckDate, pMon.CheckDate) BETWEEN 1 AND 60
	AND pMon.CheckDate >= @BeginningCheckDate
	AND pMon.CheckDate <= @EndingCheckDate
	AND pMon.counter_name='Batch Requests/sec'
ORDER BY
	  pMon.CheckDate DESC;






/* Reference */
SELECT '0 - 1,000' as BatchRequestsPerSec, 'easy to handle with commodity hardware' AS Difficulty
UNION ALL
SELECT '1,000 - 5,000' as BatchRequestsPerSec, 'one bad change to a query can knock over a commodity server' AS Difficulty
UNION ALL
SELECT '5,000 - 25,000' as BatchRequestsPerSec, 'if you are growing, you should be making a scale-out or caching plan' AS Difficulty
UNION ALL
SELECT 'Over 25,000' as BatchRequestsPerSec, 'doable, but needs attention' AS Difficulty;

