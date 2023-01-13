use CentralAdmin;
select 
	--  id
	--, entry_id ,
	  entry_time
	, database_name + N'.' + schema_name + N'.' + object_name object_name
	-- , type
	-- , type_desc
	-- , sql_handle
	, cached_time
	, last_execution_time
	 , execution_count
	, execution_count_delta
	-- , total_elapsed_time
	, convert(decimal(10,3), avg_elapsed_time / 1000000.0) avg_elapsed_time
	, convert(decimal(10,3), last_elapsed_time / 1000000.0) last_elapsed_time
	, convert(decimal(10,3), max_elapsed_time / 1000000.0) max_elapsed_time
	, convert(decimal(10,3), min_elapsed_time / 1000000.0) min_elapsed_time
	-- , total_worker_time
	, avg_worker_time
	-- , last_worker_time
	-- , min_worker_time
	-- , max_worker_time
	-- , total_physical_reads
	, avg_physical_reads
	-- , last_physical_reads
	-- , min_physical_reads
	-- , max_physical_reads
	-- , total_logical_writes
	, avg_logical_writes
	-- , last_logical_writes
	-- , min_logical_writes
	-- , max_logical_writes
	-- , total_logical_reads
	, avg_logical_reads
	-- , last_logical_reads
	-- , min_logical_reads
	-- , max_logical_reads
	-- , total_spills
	, avg_spills
	-- , last_spills
	-- , min_spills
	-- , max_spills
	, plan_handle
from 
	dbo.dm_exec_procedure_stats_hist
where
	database_name=N'GSF2_AMER_PROD'
	and schema_name=N'dbo'
	and object_name=N'usp_VisualDataManagementNextModel_Select'
	--and avg_elapsed_time is not null
	--and avg_elapsed_time>1000000*1
	--and entry_time > getdate()-2
	--entry_time>dateadd(hour,-3,getdate()) 
	--and avg_elapsed_time>1000000*1  -- 1000000 microseconds per second
	--and max_elapsed_time between 1000000*29 and 1000000*31
order by
	  database_name
	, schema_name
	, object_name
	, entry_time desc;

	--, avg_worker_time desc;


/*

dbcc freeproccache(put_the_plan_handle_here);




*/