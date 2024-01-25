/*

https://github.com/dbabyday
Warranty: The software is provided "AS IS", without warranty of any kind

Name: cbaselines.sql
Description: See SQL Plan Baselines

*/


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
	  plan_name
	, sql_handle
	, case
		when length(sql_text) > 55 then substr(sql_text,1,52) || '...' 
		else sql_text
	  end sql_text
	, enabled
	, accepted
	, reproduced
	, fixed
	, autopurge
	, adaptive
	, to_char(created,'YYYY-MM-DD') created
	, to_char(last_modified,'YYYY-MM-DD') last_modified
from
	dba_sql_plan_baselines
order by
	created;



