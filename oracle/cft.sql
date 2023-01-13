set lines 600
set verify off
set define "&"
set lines 200

column sql_fulltext format a500


prompt ;
prompt substitution variable 1 is for SQL_ID
column mysqlid new_value _SQLID noprint;
select '&1' mysqlid from dual;

select sql_fulltext from v$sql where sql_id='&&_SQLID';

undefine _SQLID
undefine 1