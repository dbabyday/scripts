set define "&"

column file_name format a50

set termout off
column dbname new_value _DBNAME noprint;
select name dbname from v$database;
set termout on

select   tablespace_name
       , file_name
from     dba_data_files
where    file_name not like lower('/oradb/'||'&&_DBNAME'||'/data/'||tablespace_name||'__.dbf')
order by tablespace_name	
       , file_name;

undefine _DBNAME

/*

alter database move datafile '/oradb/jdedv01/data/INTEGRATIONSDTA01.dbf' to '/oradb/jdedv01/data/integrationsdta01.dbf';
alter database move datafile '/oradb/jdedv01/data/INTEGRATIONSIDX01.dbf' to '/oradb/jdedv01/data/integrationsidx01.dbf';

*/