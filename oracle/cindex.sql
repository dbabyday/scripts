set linesize 32767
set pagesize 50000
set define "&"
column index_owner format a15
column index_name  format a30
column table_owner format a15
column table_name  format a15
column column_name format a15

set feedback off
execute dbms_output.put_line('Substitution variable 1 = INDEX_OWNER');
execute dbms_output.put_line('Substitution variable 2 = INDEX_NAME');
column my_index_owner new_value _INDEX_OWNER noprint;
column my_index_name new_value _INDEX_NAME noprint;
select '&1' my_index_owner, '&2' my_index_name from dual;
set feedback on

select   index_owner
       , index_name
       , table_owner
       , table_name
       , column_name
       , column_position 
from     dba_ind_columns 
where    index_owner    = UPPER('&&_INDEX_OWNER')
         and index_name = UPPER('&&_INDEX_NAME')
order by table_owner
       , table_name
       , index_owner
       , index_name
       , column_position;

undefine 1
undefine 2
undefine _TABLE_OWNER;
undefine _TABLE_NAME;
clear columns
