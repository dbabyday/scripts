
select    s.sid
	    , s.username
	    , q.sql_id
        , q.sql_text 
from      v$sql     q
join      v$session s on s.sql_id = q.sql_id
left join v$process p     on p.addr = s.paddr
where     q.sql_id='6yna48v400t9b'
order by  s.username
        , s.sid;


