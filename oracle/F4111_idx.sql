16:16:01 jlutsey(388)jdedv01 SQL> select dbms_metadata.get_ddl('INDEX',index_name,owner) stmt from dba_indexes where owner='PRODDTA' and index_name in ('F4111_14','F4111_15','F4111_16','F4111_17','F4111_18') order by index_name;

no rows selected

16:29:22 jlutsey(388)jdedv01 SQL> spool off
