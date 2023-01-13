/**************************************************************************************
*
*  Author: James Lutsey
*  Date: 06/04/2004
*  Purpose: Lists the most expensive queries running on server since last cache
*
**************************************************************************************/

SELECT TOP 10 SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
	((CASE qs.statement_end_offset
		WHEN -1 THEN DATALENGTH(qt.TEXT)
		ELSE qs.statement_end_offset
	END - qs.statement_start_offset)/2)+1) AS [Query]
	, qs.execution_count
	, qs.total_worker_time / qs.execution_count AS [average_cpu(ms)]
	, CASE (qs.total_elapsed_time / 1000000)
		  WHEN 0 THEN '0'
		  ELSE qs.total_physical_reads / (qs.total_elapsed_time / 1000000)
	  END AS [physical_reads/sec]
	, CASE (qs.total_elapsed_time / 1000000)
		  WHEN 0 THEN '0'
		  ELSE qs.total_logical_writes / (qs.total_elapsed_time / 1000000)
	  END AS [logical_writes/sec]
	, CASE (qs.total_elapsed_time / 1000000)
		  WHEN 0 THEN '0'
		  ELSE qs.total_logical_reads / (qs.total_elapsed_time / 1000000)
	  END AS [logical_reads/sec]
	, qs.total_elapsed_time / qs.execution_count AS [average_duration(ms)]
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY 2 DESC