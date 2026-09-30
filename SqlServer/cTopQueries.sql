select top(10)
	  db_name(t.dbid) database_name
	, replace(replace(left(t.text, 255), char(10), ''), char(13), '') as short_query_text
	--, t.text
	, qs.total_logical_reads
	, qs.min_logical_reads
	, qs.total_logical_reads/qs.execution_count as avg_logical_reads
	, qs.max_logical_reads
	, qs.min_worker_time
	, qs.total_worker_time/qs.execution_count as agv_worker_time
	, qs.max_worker_time
	, qs.min_elapsed_time
	, qs.total_elapsed_time/qs.execution_count as avg_elapsed_time
	, qs.max_elapsed_time
	, qs.execution_count
	, qs.creation_time
from
	sys.dm_exec_query_stats as qs with (nolock)
cross apply
	sys.dm_exec_sql_text(qs.plan_handle) as t
where
	t.dbid = db_id(N'myDbName')
order by
	--qs.execution_count desc
	--qs.total_logical_reads desc
	qs.total_logical_reads/qs.execution_count desc
option (recompile);