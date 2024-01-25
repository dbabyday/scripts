set define on
set verify off
set long 1000000
set lines 10000
set pages 100
set trimout on
set timing off
set heading on
set echo off

set feedback off
prompt Substitution variable 1 = SQL_ID;
column my_sql_id new_value _SQL_ID noprint;
select '&1' my_sql_id from dual;
set feedback on

col sql_fulltext format a5000 wrap
col name format a10
col value_string format a500 wrap


select sql_fulltext 
from   v$sql 
where sql_id='&&_SQL_ID';

select   position
       , name
       , '{'||value_string||'}' value_string
       , datatype_string
       , precision
       , scale
       , to_char(last_captured,'YYYY-MM-DD HH24:MI:SS') last_captured 
from     v$sql_bind_capture 
where    sql_id='&&_SQL_ID'
order by last_captured desc
       , position;

prompt ;

undefine 1
undefine _SQL_ID



/*

bind values
https://blogs.oracle.com/opal/sqlplus-101-substitution-variables#:~:text=Bind%20variables%20store%20data%20values%20for%20SQL%20and,system%20variables%20affect%20how%20substitution%20variables%20are%20processed.


SQL> variable bv number = 8
SQL> print bv


variable KEY1 varchar2(50) = '         830';
variable KEY2 varchar2(50) = 'O8';
variable KEY3 varchar2(50) = 'OB';
variable KEY4 varchar2(50) = 'OJ';

*/