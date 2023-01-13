set linesize 32767
set pagesize 50000
column index_owner format a15
column index_name  format a30
column table_owner format a15
column table_name  format a15
column column_name format a15

select   index_owner
       , index_name
       , table_owner
       , table_name
       , column_name
       , column_position 
from     dba_ind_columns 
where    index_owner    = UPPER('&INDEX_OWNER')
         and index_name = UPPER('&INDEX_NAME')
order by table_owner
       , table_name
       , index_owner
       , index_name
       , column_position;


undefine TABLE_OWNER;
undefine TABLE_NAME;
clear columns
