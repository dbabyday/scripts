set linesize 32767
set pagesize 50

column spid format a10
column machine format a20
column username format a20
column osuser format a20
column program format a50
column wait_class format a20
column event format a40

select   --p.spid ,
         s.sid
       , s.blocking_session
       -- , s.serial#
       -- , s.machine
       -- , s.username
       , s.sql_id
       , case when t.start_time is not null  then '20'||substr(t.start_time,7,2)||'-'||substr(t.start_time,1,2)||'-'||substr(t.start_time,4,2)||' '||substr(t.start_time,10,8)
              else null
         end  tran_start_time
-- , s.osuser
       -- , s.program
       , s.status
       , s.wait_class
       , s.event
       , s.seconds_in_wait
       , s.seconds_in_wait/60/60 hrs_in_wait
         -- s.seconds_in_wait/60/60/24 days_in_wait
from     v$session s
left join v$transaction t on t.ses_addr = s.saddr
-- join     v$process p on p.addr = s.paddr
where    s.username = 'JLUTSEY'
         -- and s.sql_id='9aaq5djztamdm'
         and s.sid not in (1767,5572)
order by s.username
       , s.osuser
       , s.sid; 



-- column kill_session_cmd format a75

-- select 'ALTER SYSTEM KILL SESSION '''||to_char(sid)||','||to_char(serial#)||''' IMMEDIATE;' kill_session_cmd
-- from   v$session
-- where  username='CGNSCONTROL';

