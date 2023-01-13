
set linesize 200 pagesize 50
col window_name format a20
col repeat_interval format a75
col duration format a30

select window_name, repeat_interval, duration from dba_scheduler_windows order by window_name;

SELECT client_name, status FROM dba_autotask_operation;

SELECT * FROM dba_autotask_schedule;


begin
    dbms_scheduler.disable(name => 'FRIDAY_WINDOW');

    dbms_scheduler.set_attribute(  name      => 'FRIDAY_WINDOW',
                                   attribute => 'repeat_interval',
                                   value     => 'freq=daily;byday=MON;byhour=17;byminute=0;bysecond=0'  );

    dbms_scheduler.set_attribute(  name      => 'FRIDAY_WINDOW',
                                   attribute => 'DURATION',
                                   value     => numtodsinterval(5, 'hour')  );

    dbms_scheduler.enable(name => 'FRIDAY_WINDOW');
end;
/



select * from dba_scheduler_windows;

SELECT * FROM dba_autotask_operation;

SELECT * FROM dba_autotask_schedule;



-- To check table statistics use:
select owner,
table_name,
num_rows,
sample_size,
last_analyzed
from dba_tables where owner in ('PRODCTL','PRODDTA')
order by last_analyzed
/

-- To check for index statistics use:
select index_name,
table_name,
num_rows,
sample_size,
distinct_keys,
last_analyzed,
status
from dba_indexes where table_owner in ('PRODCTL','PRODDTA')
order by last_analyzed
/

select   owner
       , table_name
       , partition_name
       , last_analyzed
       , stale_stats
from     dba_tab_statistics 
where    owner in ('PRODCTL','PRODDTA')
         and stale_stats='YES'
order by last_analyzed desc
/


SELECT WINDOW_NAME, RESOURCE_PLAN FROM DBA_SCHEDULER_WINDOWS
WHERE ACTIVE='TRUE';

SELECT JOB_NAME, STATE FROM DBA_SCHEDULER_JOBS;

SELECT * FROM ALL_SCHEDULER_RUNNING_JOBS;

SELECT * FROM ALL_SCHEDULER_RUNNING_CHAINS WHERE JOB_NAME='MY_JOB1';

select * from dba_SCHEDULER_JOB_LOG order by log_date desc;

select * from dba_SCHEDULER_JOB_RUN_DETAILS order by log_date desc;
