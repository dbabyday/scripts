set linesize 300

column instance_status format a15
column shutdown_pending format a16

spool "Test-OracleDbConnection.lst" append

select sysdate
     , i.instance_name
     , i.status                                        instance_status
     , to_char(i.startup_time,'YYYY-MM-DD HH24:MI:SS') startup_time
     , i.shutdown_pending
     , i.database_status
     , d.open_mode
from   v$instance i
join   v$database d on upper(d.name) = upper(i.instance_name);

spool off

exit