set linesize 200
set pagesize 50

col member format a50

select   l.group#
       , l.members
       , l.status
       , to_char(sysdate,'YYYY-MM-DD HH24:MI:SS') now
       , l.bytes/1024/1024 as mb
       , f.member
from     v$log l
join     v$logfile f on f.group#=l.group#
order by l.group#
       , f.member;