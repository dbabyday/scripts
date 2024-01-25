



set feedback off
prompt Substitution variable 1 = sql_id;
column my_sql_id new_value _SQL_ID noprint
select '&1' my_sql_id from dual;
set feedback on



column username format a30
column osuser format a30


select 
	  a.username
	, a.sid
	, a.osuser
	, a.sql_id
	, b.plan_hash_value
	, b.full_plan_hash_value
from 
	v$session a
join
	v$sql b on b.sql_id=a.sql_id
where
	a.sql_id='&&_SQL_ID'
order by
	b.plan_hash_value
	, a.sid;
	

undefine 1
undefine _SQL_ID
