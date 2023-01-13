
select   sql_id
       , sql_fulltext 
from     v$sql
where    sql_id='&sql_id';

undefine sql_id

