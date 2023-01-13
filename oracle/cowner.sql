set define "&"
column object_name for a50

prompt ;
prompt Substitution variable 1 is for OBJECT_NAME;
column myobject_name new_value _OBJECT_NAME noprint;
set feedback off
select '&1' myobject_name from dual;
set feedback on



select   object_type
       , owner||'.'||object_name object_name
from     dba_objects
where    upper(object_name)=upper('&_OBJECT_NAME')
order by owner
       , object_type;



undefine 1
undefine _OBJECT_NAME