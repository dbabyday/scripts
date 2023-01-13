column owner       format a20;
column object_name format a30;
set pages 60;

select owner,object_name,object_type,status
from dba_objects
where status != 'VALID'
order by 1,3,2,4;
