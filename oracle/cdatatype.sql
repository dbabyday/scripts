column owner for a10
column table_name for a20
column column_name for a20
column data_type for a20


set feedback off
prompt substitution variable 1 is for OWNER;
prompt substitution variable 2 is for TABLE;
prompt substitution variable 3 is for COLUMN;
column my_owner new_value _OWNER noprint;
column my_table new_value _TABLE noprint;
column my_column new_value _COLUMN noprint;
select '&1' my_owner, '&2' my_table, '&3' my_column from dual;
set feedback on

select owner
     , table_name
     , column_name
     , case when char_used='B' then data_type||'('||to_char(char_col_decl_length)||' BYTE)'
            when char_used='C' then data_type||'('||to_char(char_col_decl_length)||' CHAR)'
            when data_precision is not null then data_type||'('||to_char(data_precision)||','||to_char(data_scale)||')'
            else data_type
       end data_type
from   dba_tab_columns
where  owner='&_OWNER'
       and table_name='&_TABLE'
       and column_name='&_COLUMN';

undefine 1
undefine 2
undefine 3
undefine OWNER
undefine TABLE
undefine COLUMN