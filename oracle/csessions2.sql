set linesize 32767
set pagesize 50

column spid format a10
column machine format a20
column username format a20
column osuser format a20
column program format a50
column wait_class format a20
column event format a40

select   p.spid
       , s.sid
       , s.serial#
       , s.machine
       , s.username
       , s.sql_id
       , s.osuser
       , s.program
       , s.status
       , s.wait_class
       , s.event
       , s.seconds_in_wait
       , s.seconds_in_wait/60/60 hrs_in_wait
         -- s.seconds_in_wait/60/60/24 days_in_wait
from     v$session s
join     v$process p on p.addr = s.paddr
where    s.username like '%OPSS'
         or s.username like '%IAU_APPEND'
         or s.username like '%IAU_VIEWER'
order by s.username
       , s.osuser
       , s.sid; 



-- column kill_session_cmd format a75

-- select 'ALTER SYSTEM KILL SESSION '''||to_char(sid)||','||to_char(serial#)||''' IMMEDIATE;' kill_session_cmd
-- from   v$session
-- where  username='CGNSCONTROL';

