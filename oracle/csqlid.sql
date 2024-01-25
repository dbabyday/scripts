
set feedback off define "&"
prompt substitution variable 1 = sql_id;
column my_sql_id new_value _SQL_ID noprint;
select '&1' my_sql_id from dual;
set feedback on

column sql_fulltext format a150

select sql_fulltext from v$sql where sql_id='&&_SQL_ID';


prompt;
prompt;
prompt ---------------------------;
prompt --// DETAILS           //--;
prompt ---------------------------;
prompt;

column parsing_schema_name format a20
column sql_profile format a20
column sql_patch format a20
column sql_plan_baseline format a20
select
	  executions
	, parsing_schema_name
	, last_active_time
	, sql_profile
	, sql_patch
	, sql_plan_baseline
from
	v$sql
where
	sql_id='&&_SQL_ID';


prompt;
prompt;
prompt ---------------------------;
prompt --// RUNNING NOW       //--;
prompt ---------------------------;
prompt;

column username format a15
column osuser format a25
column program format a30
column machine format a20
select
	  sid
	, username
	, osuser
	, program
	, machine
	, logon_time
from
	v$session
where
	sql_id='&&_SQL_ID'
order by
	logon_time;



undefine 1
undefine _SQL_ID
