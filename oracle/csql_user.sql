set lines 200
set pages 50000

column sql_fulltext format a80
column username format a20

accept username char prompt 'Username: '

select s.username
     , s.sid
     , q.sql_id
     , q.sql_fulltext 
from   v$sql     q
join   v$session s on s.sql_id = q.sql_id
where  s.username='&username';

undefine username
