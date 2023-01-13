set linesize 300

column instance_status format a15
column shutdown_pending format a16

select i.instance_name
     , i.status                                        instance_status
     , to_char(i.startup_time,'YYYY-MM-DD HH24:MI:SS') startup_time
     , i.shutdown_pending
     , i.database_status
     , d.open_mode
     , d.log_mode
from   v$instance i
join   v$database d on upper(d.name) = upper(i.instance_name);

clear columns
