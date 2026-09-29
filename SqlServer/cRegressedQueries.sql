/*
Derived from:
https://learn.microsoft.com/en-us/sql/relational-databases/performance/tune-performance-with-the-query-store?view=sql-server-ver16
*/
CREATE OR ALTER PROCEDURE dbo.cRegressedQueries
	  @HourOffset INT = -1
	, @Threshold_AvgDurationIncrease INT = 1
	, @Threshold_AvgDurationIncreasePrecent INT = 1000
AS
	SET NOCOUNT ON;

	DECLARE
		  @HistStartHourOffset INT = @HourOffset - 24
		, @HistEndHourOffset INT = @HourOffset - 1;



	WITH
		  hist_runtime_stats_interval_ids AS (
			SELECT
				  runtime_stats_interval_id
				, start_time
				, end_time
			FROM
				sys.query_store_runtime_stats_interval
			WHERE
				start_time >= (SELECT MAX(start_time) FROM sys.query_store_runtime_stats_interval WHERE start_time < DATEADD(hour, @HistStartHourOffset, SYSUTCDATETIME()))
				AND end_time <= (SELECT MIN(end_time) FROM sys.query_store_runtime_stats_interval WHERE end_time > DATEADD(hour, @HistEndHourOffset, SYSUTCDATETIME()))
		  )
		, recent_runtime_stats_interval_ids AS (
			SELECT
				  runtime_stats_interval_id
				, start_time
				, end_time
			FROM
				sys.query_store_runtime_stats_interval
			WHERE
				start_time >= (SELECT MAX(start_time) FROM sys.query_store_runtime_stats_interval WHERE start_time < DATEADD(hour, @HourOffset, SYSUTCDATETIME()))
				AND end_time <= (SELECT MIN(end_time) FROM sys.query_store_runtime_stats_interval WHERE end_time > DATEADD(hour, @HourOffset, SYSUTCDATETIME()))
		  )
		, hist AS (
			SELECT
				  p.query_id query_id
				, q.object_id
				, SUM(rs.avg_duration * rs.count_executions) * 0.000001 AS total_duration
				, SUM(rs.count_executions) AS count_executions
				, COUNT(DISTINCT p.plan_id) AS num_plans
				, MIN(i.start_time) start_time
				, MAX(i.end_time) end_time
			FROM
				sys.query_store_runtime_stats AS rs
			INNER JOIN
				hist_runtime_stats_interval_ids i ON i.runtime_stats_interval_id=rs.runtime_stats_interval_id
			INNER JOIN
				sys.query_store_plan AS p ON p.plan_id = rs.plan_id
			INNER JOIN
				sys.query_store_query AS q ON q.query_id = p.query_id
			GROUP BY
				  p.query_id
				, q.object_id
		  )
		, recent AS (
			SELECT
				  p.query_id query_id
				, q.object_id
				, SUM(rs.avg_duration * rs.count_executions) * 0.000001 AS total_duration
				, SUM(rs.count_executions) AS count_executions
				, COUNT(DISTINCT p.plan_id) AS num_plans
				, MIN(i.start_time) start_time
				, MAX(i.end_time) end_time
			FROM
				sys.query_store_runtime_stats AS rs
			INNER JOIN
				recent_runtime_stats_interval_ids i ON i.runtime_stats_interval_id=rs.runtime_stats_interval_id
			INNER JOIN
				sys.query_store_plan AS p ON p.plan_id = rs.plan_id
			INNER JOIN
				sys.query_store_query AS q ON q.query_id = p.query_id
			GROUP BY
				  p.query_id
				, q.object_id
		  )
		, results AS (
			SELECT
				  OBJECT_SCHEMA_NAME(hist.object_id) + N'.' + OBJECT_NAME(hist.object_id) AS obj_name
				, hist.query_id
				, qt.query_sql_text AS query_text
				, CAST(ROUND(recent.total_duration / recent.count_executions - hist.total_duration / hist.count_executions, 3) AS DECIMAL(12,3)) AS avg_duration_increase
				, CAST(ROUND((recent.total_duration / recent.count_executions - hist.total_duration / hist.count_executions)/(hist.total_duration / hist.count_executions) * 100, 0) AS INT) AS avg_duration_increase_precent
				, CAST(ROUND( recent.total_duration / recent.count_executions, 3) AS DECIMAL(12,3)) AS avg_duration_recent
				, CAST(ROUND(hist.total_duration / hist.count_executions, 3) AS DECIMAL(12,3)) AS avg_duration_hist
				, CAST(ROUND(recent.total_duration, 3) AS DECIMAL(12,3)) AS total_duration_recent
				, CAST(ROUND(hist.total_duration, 3) AS DECIMAL(12,3)) AS total_duration_hist
				, recent.count_executions AS count_executions_recent
				, hist.count_executions AS count_executions_hist
				, recent.start_time recent_start_time_utc
				, recent.end_time recent_end_time_utc
				, hist.start_time hist_start_time_utc
				, hist.end_time hist_end_time_utc
			FROM
				hist
			INNER JOIN
				recent ON hist.query_id = recent.query_id
			INNER JOIN
				sys.query_store_query AS q ON q.query_id = hist.query_id
			INNER JOIN
				sys.query_store_query_text AS qt ON q.query_text_id = qt.query_text_id
		  )
	SELECT top(100)
		  @HourOffset HourOffset
		, obj_name
		, query_id
		, query_text
		, avg_duration_hist
		, avg_duration_recent
		, avg_duration_increase
		, avg_duration_increase_precent
		, total_duration_recent
		, total_duration_hist
		, count_executions_recent
		, count_executions_hist
		, recent_start_time_utc
		, recent_end_time_utc
		, hist_start_time_utc
		, hist_end_time_utc
	FROM
		results
	WHERE
		--query_id=1229101507
		avg_duration_increase >= @Threshold_AvgDurationIncrease
		AND avg_duration_increase_precent >= @Threshold_AvgDurationIncreasePrecent
	ORDER BY
		avg_duration_recent DESC;
GO