use CentralAdmin;

create table dbo.RedundantQueries (
	  EntryTime datetime not null
	, query_hash binary(8)
	, PlansCached int
	, DistinctPlansCached int
	, SampleQueryText nvarchar(max)
	, Total_Executions bigint
);


go
/*
	Description: Log to a table the top queries that are cached multiple times. 
	             This is usually a result of a non-parameterization scenario, and 
		     contributes to plan cache instability and high cpu utilization.

	Date        Change
	----------  -----------------------------------------------------
	2024-01-18  Initial version
*/
create or alter procedure dbo.LogRedundantQueries
as
with RedundantQueries as (
	select top (10)
		  query_hash
		, statement_start_offset
		, statement_end_offset
		, count(query_hash) as sort_order
		, count(query_hash) as PlansCached
		, count(distinct(query_plan_hash)) as DistinctPlansCached
		, SUM(execution_count) as Total_Executions
	from
		sys.dm_exec_query_stats s
	group by
		  query_hash
		, statement_start_offset
		, statement_end_offset
	order by
		sort_order desc
)
insert into
	dbo.RedundantQueries (
		  EntryTime
		, query_hash
		, PlansCached
		, DistinctPlansCached
		, SampleQueryText
		, Total_Executions
	)
select 
	  getdate() EntryTime
	, r.query_hash
	, r.PlansCached
	, r.DistinctPlansCached
	, q.SampleQueryText
	, r.Total_Executions
from
	RedundantQueries r
cross apply 
	(
		select top 1
			  st.text as SampleQueryText
			, qp.query_plan as SampleQueryPlan
			, qs.total_elapsed_time
		from 
			sys.dm_exec_query_stats qs 
		cross apply
			sys.dm_exec_sql_text(qs.sql_handle) as st
		cross apply 
			sys.dm_exec_query_plan(qs.plan_handle) as qp
		where 
			r.query_hash = qs.query_hash
			AND r.statement_start_offset = qs.statement_start_offset
			AND r.statement_end_offset = qs.statement_end_offset
		order by
			qs.total_elapsed_time desc
	) q;
go



use msdb;

declare @jobName sysname = N'DBA - Log Redundant Queries';
declare @scheduleName sysname = @jobName + N' Schedule';

execute dbo.sp_add_job
	  @job_name=@jobName
	, @enabled=1
	, @notify_level_eventlog=0
	, @notify_level_email=0
	, @notify_level_netsend=0
	, @notify_level_page=0
	, @delete_level=0
	, @description=N'Log to a table the top queries that are cached multiple times. This is usually a result of a non-parameterization scenario, and contributes to plan cache instability and high cpu utilization.'
	, @category_name=N'[Uncategorized (Local)]'
	, @owner_login_name=N'sa';

execute dbo.sp_add_jobstep
	  @job_name=@jobName
	, @step_name=N'LogRedundantQueries'
	, @step_id=1
	, @cmdexec_success_code=0
	, @on_success_action=3
	, @on_success_step_id=0
	, @on_fail_action=2
	, @on_fail_step_id=0
	, @retry_attempts=0
	, @retry_interval=0
	, @os_run_priority=0
	, @subsystem=N'TSQL'
	, @command=N'execute dbo.LogRedundantQueries;'
	, @database_name=N'CentralAdmin'
	, @flags=0;

execute dbo.sp_add_jobstep
	  @job_name=@jobName
	, @step_name=N'Purge RedundantQueries Records'
	, @step_id=2
	, @cmdexec_success_code=0
	, @on_success_action=1
	, @on_success_step_id=0
	, @on_fail_action=2
	, @on_fail_step_id=0
	, @retry_attempts=0
	, @retry_interval=0
	, @os_run_priority=0
	, @subsystem=N'TSQL'
	, @command=N'declare @p_RetentionDays int = 366;

delete from dbo.RedundantQueries
where EntryTime < dateadd(day,-1*@p_RetentionDays,getdate());'
	, @database_name=N'CentralAdmin'
	, @flags=0;

execute dbo.sp_add_jobschedule
	  @job_name=@jobName
	, @name=N'DBA - Log Redundant Queries Schedule'
	, @enabled=1
	, @freq_type=4
	, @freq_interval=1
	, @freq_subday_type=8
	, @freq_subday_interval=1
	, @freq_relative_interval=0
	, @freq_recurrence_factor=0
	, @active_start_date=20240118
	, @active_end_date=99991231
	, @active_start_time=0
	, @active_end_time=235959;

execute dbo.sp_add_jobserver
	  @job_name=@jobName
	, @server_name = @@servername;