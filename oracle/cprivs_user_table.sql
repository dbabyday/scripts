set linesize 200
set pagesize 100
set heading on
set trimout on
set feedback on
set echo off
set verify off

col username format a15
col table_name format a25
col privilege format a20

select distinct
         upper('&&username') username
       , table_name
       , privilege 
from     dba_tab_privs 
where    owner=upper('&owner')
         and table_name='&table_name' 
         and (  grantee=upper('&&username') 
                or grantee in (select granted_role from dba_role_privs where grantee=upper('&&username'))
             ) 
order by 2,3;


undefine owner;
undefine table_name;
undefine username;


