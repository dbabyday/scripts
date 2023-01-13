




select   sql_id
       , piece
       , sql_text 
from     v$sqltext
where    sql_id in (select sql_id from v$sql_plan where object_name='&index_name')
order by sql_id
       , piece;

undefine index_name

