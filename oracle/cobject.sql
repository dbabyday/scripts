set echo off
set feedback on
set verify off
set define "&"
set linesize 300
set trimout on

prompt ;
prompt substitution variable 1 is for OWNER;
prompt substitution variable 2 is for OBJECT_NAME;
column input_owner new_value _OWNER noprint;
column input_object_name new_value _OBJECT_NAME noprint;
select '&1' input_owner, '&2' input_object_Name from dual;

column owner format a15
column object_name format a30


select   owner
       , object_name
       , object_type
       , status
       , last_ddl_time
       , created
from     dba_objects
where    upper(owner)=upper('&&_OWNER')
         and upper(object_name)=upper('&&_OBJECT_NAME')
order by object_type;

undefine 1
undefine 2
undefine _OWNER
undefine _OBJECT_NAME
