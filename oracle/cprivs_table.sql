set linesize 200
set pagesize 100
set heading on
set trimout on
set feedback on
set echo off
set verify off

col grantee format a15
col table_name format a35
col privilege format a20

select   grantee
       , privilege
       , owner||'.'||table_name table_name 
from     dba_tab_privs 
where    owner=upper('&owner')
         and table_name=upper('&table_name')
order by grantee
       , privilege;


undefine owner;
undefine table_name;
undefine username;


