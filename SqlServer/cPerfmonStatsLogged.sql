

USE CentralAdmin;
GO



/* user input for exact times 
SELECT DISTINCT CheckDate from dbo.PerfmonStats ORDER BY CheckDate DESC;
*/
DECLARE
	  @BeginningCheckDate     datetimeoffset(7) = NULL  /* NULL   '2025-02-11 10:18:14.1086631 -06:00'   DATEADD(DAY,-1,SYSDATETIMEOFFSET()) */
	, @EndingCheckDate        datetimeoffset(7) = NULL  /* NULL   '2025-02-11 12:02:43.4657002 -06:00'   SYSDATETIMEOFFSET()                 */
	  /*
	     If you want to see results from a specific coutner, enter any/all of the following search criteria
	     select distinct object_name, counter_name, instance_name from CentralAdmin.dbo.PerfmonStats order by 1,2,3;
	  */
	, @Specific_object_name   nvarchar(128)     = N''
	, @Specific_counter_name  nvarchar(128)     = N''
	, @Specific_instance_name nvarchar(128)     = N''
	  /* You can change the time units for the sample durations that get displayed */
	, @Units                  varchar(20)       = 'minutes' /* seconds, minutes, hours, days */
	, @UnitsConversion        decimal(12,2)
	  /* Troubleshooting the dynamic sql */
	, @PrintDyanmicSql BIT = 0
	, @ExecuteDynamicSql BIT = 1;

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





DECLARE @SqlStmt nvarchar(max) = N'
WITH   /* cPerfmonStatsLogged.sql */
	  RowDates AS (
		SELECT ROW_NUMBER() OVER (ORDER BY ServerName, CheckDate) ID,
		       CheckDate
		FROM dbo.PerfmonStats
		GROUP BY ServerName, CheckDate
	  )
	, CheckDates AS (
		SELECT ThisDate.CheckDate,
		       LastDate.CheckDate as PreviousCheckDate
		FROM RowDates ThisDate
		JOIN RowDates LastDate ON ThisDate.ID = LastDate.ID + 1
	  )
SELECT
	  pMon.ServerName
	, pMon.CheckDate
	, pMon.object_name
	, pMon.counter_name
	, pMon.instance_name
	, CAST(CAST(ROUND(DATEDIFF(SECOND,pMonPrior.CheckDate,pMon.CheckDate) / @UnitsConversion, 0) AS INT) AS varchar(20)) + '' '' + @Units AS ElapsedTime
	, pMon.cntr_value
	, (pMon.[cntr_value] - pMonPrior.[cntr_value]) AS cntr_delta
	, (pMon.cntr_value - pMonPrior.cntr_value) * 1.0 / DATEDIFF(ss, pMonPrior.CheckDate, pMon.CheckDate) AS cntr_delta_per_second
	, pMon.ServerName + CAST(pMon.CheckDate AS NVARCHAR(50)) AS JoinKey
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
	AND pMon.CheckDate <= @EndingCheckDate';



IF @Specific_object_name <> N''
BEGIN
	SET @SqlStmt = @SqlStmt + N'
	AND pMon.object_name = @Specific_object_name';
END;

IF @Specific_counter_name <> N''
BEGIN
	SET @SqlStmt = @SqlStmt + N'
	AND pMon.counter_name = @Specific_counter_name';
END;

IF @Specific_instance_name <> N''
BEGIN
	SET @SqlStmt = @SqlStmt + N'
	AND pMon.instance_name = @Specific_instance_name';
END;




SET @SqlStmt = @SqlStmt + N'
ORDER BY
	  object_name
	, counter_name
	, instance_name
	, pMon.CheckDate DESC;';



IF @PrintDyanmicSql = 1
BEGIN
	PRINT @SqlStmt;
END;

IF @ExecuteDynamicSql = 1
BEGIN
	EXECUTE sp_executesql
		  @SqlStmt
		, N'@BeginningCheckDate datetimeoffset(7)
		  , @EndingCheckDate datetimeoffset(7)
		  , @Specific_object_name nvarchar(128)
		  , @Specific_counter_name nvarchar(128)
		  , @Specific_instance_name nvarchar(128)
		  , @Units varchar(20)
		  , @UnitsConversion decimal(12,2)'
		, @BeginningCheckDate = @BeginningCheckDate
		, @EndingCheckDate = @EndingCheckDate
		, @Specific_object_name = @Specific_object_name
		, @Specific_counter_name = @Specific_counter_name
		, @Specific_instance_name = @Specific_instance_name
		, @Units = @Units
		, @UnitsConversion = @UnitsConversion;
END;