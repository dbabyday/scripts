set linesize 32767
set pagesize 50000
set wrap off

column index_owner format a15
column column_name format a20

select   index_owner
       , index_name
       , column_name
       , column_position
from     dba_ind_columns
where    table_name = upper('&TABLE')
order by index_owner
       , index_name
       , column_position;

undefine TABLE;
clear columns

