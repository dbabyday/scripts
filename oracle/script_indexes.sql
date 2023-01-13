select sysdate from dual;
set long 2000000
set pagesize 0
set linesize 32767
set trimout on
set trimspool on
set feedback off
set termout off

column stmt format a32000

EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'STORAGE',false);



spool script_indexes_out.sql

select   dbms_metadata.get_ddl(case o.object_type when 'DATABASE LINK' then 'DB_LINK' else o.object_type end,o.object_name,o.owner) stmt
from     dba_objects o
join     dba_users   u on u.username=o.owner
where    u.oracle_maintained='N'
         and o.object_type in ('DATABASE LINK','FUNCTION','INDEX','PACKAGE','PROCEDURE','SYNONYM','TABLE','TRIGGER','VIEW') -- ,'TYPE'
         and o.object_name not like 'SYS\_%' escape '\'
         and o.object_type='INDEX'
order by o.owner
       , o.object_type
       , o.object_name;

spool off



EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'DEFAULT');

set termout on
select sysdate from dual;