set linesize 32767
set pagesize 50000

column table_name format a40
column column_name format a20
column data_type format a20
column nullable format a8

select   owner||'.'||table_name as table_name
       , column_id
       , column_name
       , data_type
       , data_length
       , data_precision
       , data_scale
       , nullable
from     dba_tab_columns
where    owner = '&owner'
         and table_name = '&table'
order by column_id;