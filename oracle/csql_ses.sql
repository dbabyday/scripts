
select sid
     , q.sql_id
     , q.sql_fulltext 
from   v$sql     q
join   v$session s on s.sql_id = q.sql_id
where  s.sid=&sid
       and rownum=1;

undefine sid
