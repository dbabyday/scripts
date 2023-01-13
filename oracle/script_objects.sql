-- display the start time on the terminal
select sysdate from dual;

-- configure SQL*Plus settings
set long 2000000
set pagesize 0
set linesize 32767
set trimout on
set trimspool on
set feedback off
column stmt format a32000


-- get the filename to spool to
column spoolname new_value _SPOOLNAME noprint;
select 'script_objects_'||lower(name)||'_'||to_char(sysdate,'YYYYMMDD')||'.sql' spoolname from v$database;
prompt spooling output to &&_SPOOLNAME
set termout off


-- do not script storage attributes
EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'STORAGE',false);



-- script the objects
spool &&_SPOOLNAME

select   dbms_metadata.get_ddl(case o.object_type when 'DATABASE LINK' then 'DB_LINK' else o.object_type end,o.object_name,o.owner) stmt
from     dba_objects o
join     dba_users   u on u.username=o.owner
where    u.oracle_maintained='N'
         and o.object_type in ('DATABASE LINK','FUNCTION','INDEX','PACKAGE','PROCEDURE','SYNONYM','TABLE','TRIGGER','VIEW') -- ,'TYPE'
         and o.object_name not like 'SYS\_%' escape '\'
order by o.owner
       , o.object_type
       , o.object_name;

spool off



-- reset the storage scripting configuration
EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'DEFAULT');




-- report the end time to the terminal
set termout on
select sysdate from dual;



-- clean up
undefine _SPOOLNAME