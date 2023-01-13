col obj_name format a35

select owner||'.'||object_name obj_name
     , object_type
     , to_char(created,'YYYY-MM-DD HH24:MI:SS') created
     , to_char(last_ddl_time,'YYYY-MM-DD HH24:MI:SS') last_ddl_time
     , status
from   sys.dba_objects
where  owner='&owner'
       and object_name='&object_name';

undefine object_name