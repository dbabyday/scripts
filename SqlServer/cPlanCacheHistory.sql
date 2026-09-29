/*

https://www.brentozar.com/archive/2018/07/tsql2sday-how-much-plan-cache-history-do-you-have/

*/

SELECT --TOP 50
	  creation_date = CAST(creation_time AS date)
	, creation_hour = CASE
		WHEN CAST(creation_time AS date) <> CAST(GETDATE() AS date) THEN 0
		ELSE DATEPART(hh, creation_time)
	  END
	, SUM(1) AS plans
	, CAST(ROUND(SUM(1) * 100.0 / (SELECT COUNT(1) FROM sys.dm_exec_query_stats), 0) AS INT) AS percent_plans
FROM
	sys.dm_exec_query_stats
GROUP BY
	  CAST(creation_time AS date)
	, CASE
		WHEN CAST(creation_time AS date) <> CAST(GETDATE() AS date) THEN 0
		ELSE DATEPART(hh, creation_time)
	  END
ORDER BY
	  creation_date DESC
	, creation_hour DESC;