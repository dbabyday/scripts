set define "&" 
set echo off


set feedback off
prompt ;
prompt Substitution variable 1 is for TABLE_OWNER;
column my_table_owner new_value _TABLE_OWNER noprint;
prompt Substitution variable 2 is for TABLE_NAME;
column my_table_name new_value _TABLE_NAME noprint;
select '&1' my_table_owner, '&2' my_table_name from dual;
set feedback on


column trigger_name format a50
column table_name format a30
column triggering_event format a16
column trigger_status format a14
column object_status format a13

select t.owner||'.'||t.trigger_name trigger_name
     , t.table_owner||'.'||t.table_name table_name
     , t.triggering_event
     , t.trigger_type
     , t.status trigger_status
     , o.status object_status
from   dba_triggers t
join   dba_objects o on o.owner=t.owner and o.object_name=t.trigger_name
where  table_owner='&&_TABLE_OWNER' 
       and table_name='&&_TABLE_NAME';



undefine 1
undefine 2
undefine _TABLE_OWNER
undefine _TABLE_NAME