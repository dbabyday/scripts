set linesize 500
set pagesize 5000
set verify off
set feedback off

col owner format a15
col job_name format a50
col enabled format a7
col program_name format a50
col schedule_name format a50
col program_action format a100
col repeat_interval format a50

prompt ;
prompt ;


select    j.owner
        , j.job_name job_name
        , j.enabled
        , p.program_action
        , s.repeat_interval
from      dba_scheduler_jobs      j
left join dba_scheduler_programs  p on p.owner=j.program_owner and p.program_name=j.program_name
left join dba_scheduler_schedules s on s.owner=j.schedule_owner and s.schedule_name=j.schedule_name
order by  j.owner
        , j.job_name;

prompt ;
prompt ;


set feedback on