
/*

    Known limitations: Privileges are only gathered for those that are granted 
                       directly to user or to a role that is granted directly 
                       to the user. Privileges for "nested" roles the user is 
                       granted are ignored.

*/

set linesize 32767
set pagesize 50000
set verify off

column grantee format a25
column privilege format a35
column admin_option format a12
column granted_role format a20
column default_role format a12
column object_name format a35 wrap
column grantor format a20
column grantable format a9
column hierarchy format a9

accept grantee char prompt 'Enter value for grantee: '

prompt ;
prompt ;
prompt ;
prompt -------------------------------;
prompt --// ROLES                 //--;
prompt -------------------------------;
prompt ;

select   grantee
       , granted_role
       , admin_option
       , default_role
from     dba_role_privs
where    grantee = upper('&&grantee')
order by granted_role;

prompt ;
prompt ;
prompt -------------------------------;
prompt --// SYSTEM PRIVILEGES     //--;
prompt -------------------------------;
prompt ;

select   grantee
       , privilege
       , admin_option
from     dba_sys_privs
where    grantee = upper('&&grantee')
         or grantee in ( select granted_role
                         from   dba_role_privs
                         where  grantee = upper('&&grantee') )
order by privilege;

prompt ;
prompt ;
prompt ;
prompt -------------------------------;
prompt --// OBJECT PRIVILEGES     //--;
prompt -------------------------------;
prompt ;

select   grantee
       , owner||'.'||table_name object_name
       , privilege
       , grantor
       , grantable
       , hierarchy
from     dba_tab_privs
where    grantee = upper('&&grantee')
         or grantee in ( select granted_role
                         from   dba_role_privs
                         where  grantee = upper('&&grantee') )
order by owner
       , table_name
       , privilege;

undefine grantee;