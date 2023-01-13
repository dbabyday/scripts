column owner for a10
column table_name for a20
column column_name for a20
column data_type for a20

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

