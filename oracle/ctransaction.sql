col username   format a15
col schemaname format a15
col osuser     format a20
col machine    format a15
col terminal   format a15
col program    format a15
col module     format a15

select   t.start_time
       , s.sid
       , s.serial#
       , s.username
       , s.status
       , t.used_ublk
       , s.schemaname
       , s.osuser
       , s.process
       , s.machine
       , s.terminal
       , s.program
       , s.module
       , s.type
       , to_char(s.logon_time,'DD/MON/YY HH24:MI:SS') logon_time
from     v$transaction t
left outer join v$session     s on s.saddr = t.ses_addr
where    s.sid=&SID;

undefine SID
