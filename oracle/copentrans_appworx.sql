set linesize 32767
set pagesize 50

set echo off linesize 500 pagesize 100

col wait_class format a20
column machine format a20
column username format a8
column osuser format a7
column program format a16
col "sid,serial#" format a11
col command_name format a30
col event format a30

select          to_char(s.sid)||','||to_char(s.serial#) "sid,serial#"
              , s.username
              , s.osuser
              , s.program
              , s.machine
              , s.status
              , to_char(s.logon_time,'YYYY-MM-DD HH24:MI:SS') logon_time
              , case when t.start_time is not null  then '20'||substr(t.start_time,7,2)||'-'||substr(t.start_time,1,2)||'-'||substr(t.start_time,4,2)||' '||substr(t.start_time,10,8)
                     else null
                end  tran_start_time
              , s.wait_class
              , s.event
              , s.seconds_in_wait
from            v$session s
left outer join v$process p     on p.addr = s.paddr
left outer join v$sqlcommand c  on c.command_type = s.command
join            v$transaction t on t.ses_addr = s.saddr
order by        s.seconds_in_wait desc;

