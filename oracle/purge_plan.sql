set echo off verify off linesize 200

accept sql_id char prompt 'SQL_ID: '

col stmt format a100

select sql_id
     , address
     , hash_value 
     , 'execute sys.dbms_shared_pool.purge('''||address||', '||hash_value||''', ''C'');' stmt
from   v$sqlarea 
where  sql_id='&sql_id';

undefine sql_id