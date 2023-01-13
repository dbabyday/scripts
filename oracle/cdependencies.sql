set echo off
set feedback off
set verify off
set define "&"
set linesize 300

prompt substitution variable 1 is for REFERENCED_OWNER
prompt substitution variable 2 is for REFERENCED_NAME
column my_referenced_owner new_value _referenced_owner noprint
column my_referenced_name new_value _referenced_name noprint
select '&1' my_referenced_owner
     , '&2' my_referenced_name
from    dual;


set feedback on
column dependent_object format a40
column referenced_object format a40


select   owner||'.'||name dependent_object
       , type dependent_type
       , referenced_owner||'.'||referenced_name referenced_object
       , referenced_type
from     dba_dependencies
where    referenced_owner='&&_referenced_owner'
         and referenced_name='&&_referenced_name'
order by owner
       , name
       , type;



undefine 1
undefine 2
undefine _referenced_owner
undefine _referenced_name