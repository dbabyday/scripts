column owner format a15
column task_name format a30
select
	  owner
	, task_name
	, execution_start
	, execution_end
	, status
	, 'execute dbms_sqltune.drop_tuning_task('''||task_name||''');' drop_tuning_task
from
	dba_advisor_log
where
	task_name not like 'ADDM%'
	and task_name not like '%AUTO%'
	and task_name not like 'SYS_AI%'
	and task_name <> 'INDIVIDUAL_STATS_ADVISOR_TASK'
order by
	execution_start;
