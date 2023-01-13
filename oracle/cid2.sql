set lines 1100

col parsing_schema_name for a19
col module for a35
col ft for a1000

select parsing_schema_name
     , module
     , sql_id
     , to_char(sql_fulltext) ft
from   v$sql
where  sql_text not like '%v$sql%'
       and sql_text not like '%EXPLAIN PLAN%'
       and sql_text like '%&sql_text_like%'
order by 3;
