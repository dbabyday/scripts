set define on

col object_name format a50

select owner||'.'||table_name Object_name
     , num_rows
     , to_char(last_analyzed,'YYYY-MM-DD HH24:MI:SS') last_analyzed
from   dba_tables
where  owner=upper('&&OWNER')
       and table_name=upper('&&TABLE_NAME')
union
select owner||'.'||index_name Object_name
     , num_rows
     , to_char(last_analyzed,'YYYY-MM-DD HH24:MI:SS') last_analyzed
from   dba_indexes
where  owner=upper('&&OWNER')
       and table_name=upper('&&TABLE_NAME');

undefine OWNER
undefine TABLE_NAME

