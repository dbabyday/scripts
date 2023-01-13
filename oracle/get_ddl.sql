SET LONG 2000000 PAGESIZE 0 LINESIZE 300 TRIMOUT ON
column stmt format a290

EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'STORAGE',false);

select dbms_metadata.get_ddl('TABLE',t.table_name,t.owner) stmt
from   sys.dba_tables t
where  t.owner='PRODDTA' and t.table_name in ('F5542061','F5643011')
order by t.owner
       , t.table_name;

EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'DEFAULT');