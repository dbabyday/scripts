
set heading on
set feedback off
set linesize 200
set trimout on
set feedback off

column mixed format a5
column advice format a6
column os_user format a20
column os_terminal format a15
column host format a18
column db_user format a15

alter session set nls_date_format='YYYY-MM-DD HH24:MI:SS';

set feedback on

select   local_tran_id
       , state
       , mixed
       , advice
       , fail_time
       , force_time
       , retry_time
       , os_user
       , os_terminal
       , host
       , db_user
from     dba_2pc_pending
order by fail_time;
