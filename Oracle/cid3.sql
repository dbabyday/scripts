set define "&"

-- prompt;
-- prompt substitution variable 1 is for SQL_TEXT_LIKE;
-- column my_SQL_TEXT_LIKE new_value _SQL_TEXT_LIKE noprint;
-- set feedback off
-- select '&1' my_SQL_TEXT_LIKE from dual;
-- set feedback on


col parsing_schema_name for a19
col module for a35
col ft for a1000

select distinct parsing_schema_name
     , module
     , sql_id
     -- , to_char(sql_fulltext) ft
from   v$sql
where  sql_text not like '%v$sql%'
       and sql_text not like '%EXPLAIN PLAN%'
       and sql_text not like '%my_SQL_TEXT_LIKE%'
       and (
              sql_text like '%F41021%'
              or sql_text like '%F4111%'
              or sql_text like '%F46L10%'
              or sql_text like '%F46L11%'
              or sql_text like '%F46LUI01%'
       )
       and parsing_schema_name='DSISVC'
order by 3;


undefine 1
undefine _SQL_TEXT_LIKE








