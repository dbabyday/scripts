column object_name format a30

select owner||'.'||object_name object_name
     , object_type
     , created
     , last_ddl_time
from   dba_objects
where  owner='&OWNER'
       and object_name='&OBJECT_NAME';

