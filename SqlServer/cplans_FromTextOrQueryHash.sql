--/*

SELECT
	  d.name
	, t.text
	, SUBSTRING(
		  t.text
		, s.statement_start_offset/2 +1
		, (CASE WHEN s.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), t.text)) * 2 ELSE s.statement_end_offset END - s.statement_start_offset)/2
	  ) AS StmtText
	, s.query_hash
	, s.creation_time
	, s.execution_count
	, s.total_worker_time AS total_cpu_time
	, s.total_elapsed_time
	, s.total_logical_reads
	, s.total_physical_reads
	, p.query_plan
	, 'EXECUTE sp_BlitzCache @OnlySqlHandles=''' + CONVERT(VARCHAR(1000), s.sql_handle, 2) + ''';' AS MoreInfo
	, 'DBCC FREEPROCCACHE(0x' + CONVERT(VARCHAR(1000), s.plan_handle, 2) + ');'
FROM
	sys.dm_exec_query_stats AS s
CROSS APPLY
	sys.dm_exec_sql_text(s.plan_handle) AS t
CROSS APPLY
	sys.dm_exec_query_plan(s.plan_handle) AS p
INNER JOIN
	sys.databases AS d ON t.dbid = d.database_id
WHERE
	t.text LIKE '%MyString%'
	--s.query_hash=0x4E278D01E58D0A98
ORDER BY
	s.creation_time desc;
--	t.text;



--*/


