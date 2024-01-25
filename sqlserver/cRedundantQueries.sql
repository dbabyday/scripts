with RedundantQueries as (
	select top 10
		  query_hash
		, statement_start_offset
		, statement_end_offset
		/****************************** start of sort options ******************************/
		, count(query_hash) as sort_order            --queries with the most plans in cache
		--, sum(total_logical_reads) as sort_order     --queries reading data
		--, sum(total_worker_time) as sort_order       --queries burning up cpu
		--, sum(total_elapsed_time) as sort_order      --queries taking forever to run
		/****************************** end of sort options ******************************/
		, count(query_hash) as planscached
		, count(distinct(query_plan_hash)) as DistinctPlansCached
		, min(creation_time) as FirstPlanCreationTime
		, max(creation_time) as LastPlanCreationTime
		, max(s.last_execution_time) as LastExecutionTime
		, sum(total_worker_time) as Total_CPU_ms
		, sum(total_elapsed_time) as Total_Duration_ms
		, sum(total_logical_reads) as Total_Reads
		, sum(total_logical_writes) as Total_Writes
		, sum(execution_count) as Total_Executions
		, N'execute sp_BlitzCache @OnlyQueryHashes=''0x' + CONVERT(NVARCHAR(50), query_hash, 2) + '''' as MoreInfo
	from
		sys.dm_exec_query_stats s
	group by
		  query_hash
		, statement_start_offset
		, statement_end_offset
	order by
		sort_order desc
)
select
	  r.query_hash
	, r.PlansCached
	, r.DistinctPlansCached
	, q.SampleQueryText
	, q.SampleQueryPlan
	, r.Total_Executions
	, r.Total_CPU_ms
	, r.Total_Duration_ms
	, r.Total_Reads
	, r.Total_Writes
	--, r.Total_Spills
	, r.FirstPlanCreationTime
	, r.LastPlanCreationTime
	, r.LastExecutionTime
	, r.statement_start_offset
	, r.statement_end_offset
	, r.sort_order
	, r.MoreInfo
from
	redundantqueries r
cross apply
	(
		select top 10
			  st.text as samplequerytext
			, qp.query_plan as samplequeryplan
			, qs.total_elapsed_time
		from
			sys.dm_exec_query_stats qs 
		cross apply
			sys.dm_exec_sql_text(qs.sql_handle) as st
		cross apply
			sys.dm_exec_query_plan(qs.plan_handle) as qp
		where
			r.query_hash = qs.query_hash
			and r.statement_start_offset = qs.statement_start_offset
			and r.statement_end_offset = qs.statement_end_offset
		order by
			qs.total_elapsed_time desc
	) q
order by
	  r.sort_order desc
	, r.query_hash
	, r.statement_start_offset
	, r.statement_end_offset
	, q.total_elapsed_time desc;