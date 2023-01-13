set linesize 32767
set pagesize 50000
set wrap off

column spid format a10
column machine format a20

select   p.spid,
         s.sid,
         s.serial#,
         s.machine,
         s.username,
         s.server,
         s.osuser,
         s.program
from     v$session s
join     v$process p on p.addr = s.paddr
where    s.username = upper('&USERNAME')
order by p.spid; 

undefine USERNAME;
