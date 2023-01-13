use CentralAdmin;
select 
	--  a.id
	--, a.entry_id ,
	  a.entry_time
	, a.database_name + N'.' + a.schema_name + N'.' + a.object_name object_name
	-- , a.type
	-- , a.type_desc
	-- , a.sql_handle
	, a.cached_time
	, a.last_execution_time
	, a.execution_count
	, a.execution_count_delta
	-- , a.total_elapsed_time
	, convert(decimal(10,3), a.avg_elapsed_time / 1000000.0) avg_elapsed_time
	, convert(decimal(10,3), b.avg_elapsed_time / 1000000.0) pre_avg_elapsed_time
	, convert(decimal(10,3), a.last_elapsed_time / 1000000.0) last_elapsed_time
	, convert(decimal(10,3), a.max_elapsed_time / 1000000.0) max_elapsed_time
	, convert(decimal(10,3), a.min_elapsed_time / 1000000.0) min_elapsed_time
	-- , a.total_worker_time
	-- , a.avg_worker_time
	-- , a.last_worker_time
	-- , a.min_worker_time
	-- , a.max_worker_time
	-- , a.total_physical_reads
	-- , a.avg_physical_reads
	-- , a.last_physical_reads
	-- , a.min_physical_reads
	-- , a.max_physical_reads
	-- , a.total_logical_writes
	-- , a.avg_logical_writes
	-- , a.last_logical_writes
	-- , a.min_logical_writes
	-- , a.max_logical_writes
	-- , a.total_logical_reads
	-- , a.avg_logical_reads
	-- , a.last_logical_reads
	-- , a.min_logical_reads
	-- , a.max_logical_reads
	-- , a.total_spills
	-- , a.avg_spills
	-- , a.last_spills
	-- , a.min_spills
	-- , a.max_spills
	--, a.plan_handle
from 
	dbo.dm_exec_procedure_stats_hist a
join
	dbo.dm_exec_procedure_stats_hist b on
		a.database_name = b.database_name
		and a.object_name = b.object_name
		and a.cached_time = b.cached_time
		and a.entry_id = b.entry_id + 1
where
	a.avg_elapsed_time > 30 * b.avg_elapsed_time  -- average duration X times longer execution the previous 5 minute window
	and a.max_elapsed_time > 1000000*25  -- max duration at least X seconds
	--and a.avg_elapsed_time > 1000000*10  -- average duration is at least X seconds
	--and a.entry_id = (select max(entry_id) from dbo.dm_exec_procedure_stats_hist)  -- if monitoring, only look at the last entry
	--and a.entry_time>dateadd(hour,-2,getdate())
	--and a.object_name not like '%SSIS%'
	--and a.execution_count_delta > 1

	--a.avg_worker_time > 10 * b.avg_worker_time
	
order by
	--a.avg_elapsed_time - b.avg_elapsed_time desc
	  a.database_name
	, a.entry_time desc
	, a.schema_name
	, a.object_name;
