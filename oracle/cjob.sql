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

-- job
select    j.owner
        , j.job_name job_name
        , j.enabled
from      dba_scheduler_jobs      j
where     upper(j.owner)=upper('&&job_owner')
          and upper(j.job_name)=upper('&&job_name');

prompt ;

-- programs
select    p.owner
        , p.program_name
        , p.enabled
        , p.program_type
        , p.program_action
from      dba_scheduler_jobs      j
left join dba_scheduler_programs  p on p.owner=j.program_owner and p.program_name=j.program_name
where     upper(j.owner)=upper('&&job_owner')
          and upper(j.job_name)=upper('&&job_name')
order by  p.owner
        , p.program_name;

prompt ;

-- schedules
select    s.owner
        , s.schedule_name
        , to_char(s.start_date,'YYYY-MM-DD HH24:MI:SS') start_date
        , s.repeat_interval
        , to_char(s.end_date,'YYYY-MM-DD HH24:MI:SS') end_date
from      dba_scheduler_jobs      j
left join dba_scheduler_schedules s on s.owner=j.schedule_owner and s.schedule_name=j.schedule_name
where     upper(j.owner)=upper('&&job_owner')
          and upper(j.job_name)=upper('&&job_name')
order by  s.owner
        , s.schedule_name;

prompt ;
prompt ;

undefine job_owner
undefine job_name

set feedback on