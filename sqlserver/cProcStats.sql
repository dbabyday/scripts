use GSF2_AMER_PROD;
--use Operational_Reporting_PROD;

select
	  top (100) db_name(p.database_id) AS DatabaseName
	, schema_name(o.schema_id)+N'.'+o.name AS ProcedureName
	, p.cached_time
	, p.last_execution_time
	, p.execution_count
	, case
	 	 when datediff(second, p.cached_time, p.last_execution_time) < 1 then
	 		 convert(decimal(10, 1), p.execution_count)
	 	 else
	 		 convert(decimal(10, 2), p.execution_count / (datediff(second, p.cached_time, getdate()) / 60.0 / 60.0))
	  end as ExecPerHr
	, convert(decimal(10, 2), (p.total_elapsed_time / p.execution_count) / 1000000.0) AS avg_execution_duration
	, convert(decimal(10, 2), p.last_elapsed_time / 1000000.0) AS last_execution_duration
	, convert(decimal(10, 2), p.max_elapsed_time / 1000000.0) AS max_execution_duration
	--, convert(decimal(10, 2), p.last_worker_time / 1000000.0) AS last_CPU_time
	, p.last_worker_time
	, p.total_worker_time / p.execution_count AS avg_worker_time
	, p.total_logical_reads / p.execution_count AS avg_logical_reads
	, p.total_physical_reads / p.execution_count AS avg_physical_reads
	, p.total_logical_writes / p.execution_count AS avg_logical_writes
	, p.last_logical_reads
	, p.last_physical_reads
	, p.last_logical_writes
	, p.plan_handle
from
	sys.dm_exec_procedure_stats p
join
	sys.objects o on o.object_id=p.object_id
where
	p.database_id = db_id()
	and o.name not like 'usp_SSIS%'
	and o.name not like 'sp_MS%'
	--
	and p.last_execution_time>dateadd(minute,-60,getdate()) -- only procs executed in last hour
	--and p.max_elapsed_time between 1000000*29 and 1000000*31 -- looking for sp that hits GSF's timeout of 30 seconds
	--
	--and o.name in (N'usp_UnitListByUnitHeaderId_Select',N'usp_EventIdByUnitBackFlushEventTableType_Select',N'usp_WorkOrderQuantityLeft_Select',N'usp_RouteStepByRouteVersionId_Select')
	--and o.name in (N'usp_VisualDataManagementCurrentModelPostSmt_Select',N'usp_ContainerSearch_Select',N'usp_VisualDataManagementNextModel_Select',N'usp_WorkOrderLoading_Insert')
	--and o.name in (
 --                 N'usp_ContainerSearch_Select'
 --               , N'usp_IsNextWorkOrderExist_Select'
 --               , N'usp_SmtWorkOrderEfficiencyUnitsData_Select'
 --               , N'usp_StopProductionList_Select'
 --               , N'usp_VisualDataManagementCurrentModelPostSmt_Select'
 --               , N'usp_VisualDataManagementCurrentModelSMT_Select'
 --               , N'usp_VisualDataManagementNextModel_Select'
 --               , N'usp_WorkOrderLoading_Insert'
	--)
	--and o.name=N'usp_VisualDataManagementCurrentModelPostSmt_Select'
	--
order by
	--avg_execution_duration desc;
	--max_execution_duration desc;
	last_execution_duration desc;
	--ExecPerHr desc;
	--2

/*
dbcc freeproccache(put_the_plan_handle_here);

*/





