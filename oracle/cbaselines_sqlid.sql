/*

https://github.com/dbabyday
Warranty: The software is provided "AS IS", without warranty of any kind

Name: cbaselines_sqlid.sql
Description: See SQL Plan Baselines for a given SQL_ID

*/


set feedback off define "&"
prompt substitution variable 1 = SQL_ID;
column my_sql_id new_value _SQL_ID noprint;
select '&1' my_sql_id from dual;
set feedback on

column sql_fulltext  format a150
column plan_name     format a35
column sql_text      format a55
column enabled       format a10
column accepted      format a10
column reproduced    format a10
column fixed         format a10
column autopurge     format a10
column adaptive      format a10
column created       format a15
column last_modified format a15

select
	sql_fulltext
from
	v$sql
where
	sql_id='&&_SQL_ID'
fetch next 1 rows only;

select --distinct
	  b.plan_name
	, b.sql_handle
	, b.enabled
	, b.accepted
	, b.reproduced
	, b.fixed
	, b.autopurge
	, b.adaptive
	, to_char(b.created,'YYYY-MM-DD') created
	, to_char(b.last_modified,'YYYY-MM-DD') last_modified
from
	dba_sql_plan_baselines b
join
	v$sql s on
		s.exact_matching_signature=b.signature
		and b.plan_name=s.sql_plan_baseline	
where
	s.sql_id='&&_SQL_ID'
order by
	created;



undefine 1
undefine _SQL_ID
