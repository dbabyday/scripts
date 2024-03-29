-- configure SQL*Plus settings
set long 2000000
set pagesize 0
set linesize 32767
set trimout on
set trimspool on
set feedback off
set verify off
column stmt format a32000


set feedback off
prompt substitution variable 1 is for OWNER;
prompt substitution variable 2 is for OBJECT_NAME;
column my_owner new_value _OWNER noprint;
column my_object_name new_value _OBJECT_NAME noprint;
select '&1' my_owner, '&2' my_object_name from dual;
set feedback on


-- get the filename to spool to
column spoolname new_value _SPOOLNAME noprint;
select '&&_OWNER'||'.'||'&&_OBJECT_NAME'||'.'||lower(name)||'_'||to_char(sysdate,'YYYYMMDD_HH24MISS')||'.sql' spoolname from v$database;
prompt spooling output to &&_SPOOLNAME
set termout off


-- do not script storage attributes
EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'STORAGE',false);



-- script the objects
spool &&_SPOOLNAME

select   dbms_metadata.get_ddl(case o.object_type when 'DATABASE LINK' then 'DB_LINK' else o.object_type end,o.object_name,o.owner) stmt
from     dba_objects o
where    o.owner='&&_OWNER'
         and o.object_name='&&_OBJECT_NAME'
         and o.object_type<>'PACKAGE BODY'
order by o.owner
       , o.object_type
       , o.object_name;

spool off



-- reset the storage scripting configuration
EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'DEFAULT');




-- clean up
undefine 1
undefine 2
undefine _SPOOLNAME
undefine _OWNER
undefine _OBJECT_NAME

set pagesize 60
set feedback on
set termout on