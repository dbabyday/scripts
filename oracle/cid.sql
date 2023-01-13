set define "&"

prompt;
prompt substitution variable 1 is for SQL_TEXT_LIKE;
column my_SQL_TEXT_LIKE new_value _SQL_TEXT_LIKE noprint;
set feedback off
select '&1' my_SQL_TEXT_LIKE from dual;
set feedback on

select sql_id
from   v$sql
where  sql_text not like '%v$sql%'
       and sql_text not like '%EXPLAIN PLAN%'
       and sql_text not like '%my_SQL_TEXT_LIKE%'
       and sql_text like '%&_SQL_TEXT_LIKE%';

undefine 1
undefine _SQL_TEXT_LIKE