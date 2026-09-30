IF NOT EXISTS(SELECT 1 FROM sys.schemas WHERE name=N'DbaOnly')
BEGIN
	DECLARE @SqlStmt nvarchar(4000) = N'CREATE SCHEMA DbaOnly';
	EXECUTE sp_executesql @SqlStmt;
END;


GO
CREATE OR ALTER PROCEDURE DbaOnly.cQueryPerformanceHist_ByObjectId
	  @ObjectId int
	, @ShowDetailsForQueryIds bit = 0
	, @TimeZone varchar(3) = 'UTC'
AS
	/* time zone to use for displaying time fields */
	IF @TimeZone NOT IN ('UTC','CDT','CST','CSTM','MYT','EET')
	BEGIN
		RAISERROR('@TimeZone parameter needs to be one of the following: ''UTC'', ''CDT'', ''CST'', ''CSTM'' (CST Mexico), ''MYT'',''EET''',16,1) WITH NOWAIT;
		RETURN;
	END;
	DECLARE @TimeZoneDesc VARCHAR(31);
	SELECT
		@TimeZoneDesc = CASE
			WHEN @TimeZone='UTC'  THEN 'UTC'
			WHEN @TimeZone='CDT'  THEN 'Central Standard Time'
			WHEN @TimeZone='CST'  THEN 'Central Standard Time'
			WHEN @TimeZone='CSTM' THEN 'Central Standard Time (Mexico)'
			WHEN @TimeZone='MYT'  THEN 'Singapore Standard Time'
			WHEN @TimeZone='EET'  THEN 'E. Europe Standard Time'
		END;





	/* get duration aggregates for the queries for a quick look at which ones take the longest */
	SELECT
		  q.query_id
		, OBJECT_SCHEMA_NAME(q.object_id) + N'.' + OBJECT_NAME(q.object_id) AS ObjectName
		, qt.query_sql_text
		, CAST(ROUND(AVG(rs.avg_duration) * 0.000001, 3) AS DECIMAL(12,3)) AS avg_avg_duration
		, CAST(ROUND((MAX(rs.avg_duration) - MIN(rs.avg_duration)) * 0.000001, 3) AS DECIMAL(12,3)) AS range_avg_duration
		, CAST(ROUND(MIN(rs.avg_duration) * 0.000001, 3) AS DECIMAL(12,3)) AS min_avg_duration
		, CAST(ROUND(MAX(rs.avg_duration) * 0.000001, 3) AS DECIMAL(12,3)) AS max_avg_duration
	FROM
		sys.query_store_runtime_stats_interval i
	INNER JOIN
		sys.query_store_runtime_stats AS rs ON rs.runtime_stats_interval_id=i.runtime_stats_interval_id
	INNER JOIN
		sys.query_store_plan AS p ON p.plan_id=rs.plan_id
	INNER JOIN
		sys.query_store_query AS q ON q.query_id=p.query_id
	INNER JOIN
		sys.query_store_query_text AS qt ON q.query_text_id=qt.query_text_id
	WHERE
		q.object_id=@ObjectId
	GROUP BY
		  q.query_id
		, q.object_id
		, qt.query_sql_text
	ORDER BY
		range_avg_duration DESC;


	
	/* get the details */
	IF @ShowDetailsForQueryIds = 1
	BEGIN
		SELECT
			  q.query_id
			, OBJECT_SCHEMA_NAME(q.object_id) + N'.' + OBJECT_NAME(q.object_id) AS ObjectName
			, qt.query_sql_text
			, i.start_time AT TIME ZONE @TimeZoneDesc AS start_time
			, i.end_time AT TIME ZONE @TimeZoneDesc AS end_time
			, p.last_compile_start_time AT TIME ZONE @TimeZoneDesc AS last_compile_start_time
			, '
SELECT TOP(1)
	  ''good bad'' as good_bad
	, CAST(   ''<![CDATA['' + query_plan + '']]>'' AS XML) as query_plan
FROM
	sys.query_store_plan
WHERE
	query_plan_hash=' + CONVERT(VARCHAR(100), p.query_plan_hash, 1) + ';' AS [GetThePlan]
			, p.query_plan_hash
			, rs.count_executions
			, CAST(ROUND(rs.avg_duration * 0.000001, 3) AS DECIMAL(12,3)) AS avg_duration_seconds
			, CAST(ROUND(rs.avg_cpu_time * 0.000001, 3) AS DECIMAL(12,3)) AS avg_cpu_seconds
			, CAST(ROUND(rs.avg_logical_io_reads, 0) AS BIGINT) AS avg_logical_io_reads
			, CAST(ROUND(rs.avg_logical_io_writes, 0) AS BIGINT) AS avg_logical_io_writes
			, CAST(ROUND(rs.avg_physical_io_reads, 0) AS BIGINT) AS avg_physical_io_reads
			, CAST(ROUND(rs.avg_clr_time * 0.000001, 3) AS DECIMAL(12,3)) AS avg_clr_seconds
			, rs.avg_dop
			, CAST(ROUND(rs.avg_query_max_used_memory / 128.0, 0) AS BIGINT) AS avg_query_max_used_memory_mb
			, CAST(ROUND(rs.avg_rowcount, 0) AS BIGINT) AS avg_rowcount
		FROM
			sys.query_store_runtime_stats_interval i
		INNER JOIN
			sys.query_store_runtime_stats AS rs ON rs.runtime_stats_interval_id=i.runtime_stats_interval_id
		INNER JOIN
			sys.query_store_plan AS p ON p.plan_id=rs.plan_id
		INNER JOIN
			sys.query_store_query AS q ON q.query_id=p.query_id
		INNER JOIN
			sys.query_store_query_text AS qt ON q.query_text_id=qt.query_text_id
		WHERE
			q.object_id=@ObjectId
		ORDER BY
			  q.query_id
			, i.start_time desc
			, i.end_time desc;
	END;


GO