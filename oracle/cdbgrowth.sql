
set feedback off
prompt Substitution variable 1 = DB_NAME;
column my_db_name new_value _DB_NAME noprint;
select '&1' my_db_name from dual;
set feedback on


column db_name format a10
column tablespace_name format a20

-- daily
with db_used_mb as (
	select
		  target_name db_name
		, rollup_timestamp
		, sum(average) db_average
	from
		sysman.mgmt$metric_daily
	where
		upper(target_name) = upper('&&_DB_NAME')
		and column_label='Tablespace Used Space (MB)'
	group by
		  rollup_timestamp
		, target_name
)
select
	  db_name
	, rollup_timestamp
	, round(db_average/1024/1024,1) db_used_tb
	, round((db_average - (lag(db_average) over (order by rollup_timestamp)))/1024, 1) growth_gb
from
	db_used_mb
order by
	rollup_timestamp;


-- weekly
with db_used_mb as (
	select
		  target_name db_name
		, rollup_timestamp
		, sum(average) db_average
	from
		sysman.mgmt$metric_daily
	where
		upper(target_name) = upper('&&_DB_NAME')
		and column_label='Tablespace Used Space (MB)'
	and to_char(rollup_timestamp,'fmDAY')='MONDAY'
	group by
		  rollup_timestamp
		, target_name
)
select
	  db_name
	, rollup_timestamp
	, round(db_average/1024/1024,1) db_used_tb
	, round((db_average - (lag(db_average,1) over (order by rollup_timestamp)))/1024, 0) growth_gb
from
	db_used_mb
order by
	rollup_timestamp;


-- monthly
with db_used_mb as (
	select
		  target_name db_name
		, rollup_timestamp
		, sum(average) db_average
	from
		sysman.mgmt$metric_daily
	where
		upper(target_name) = upper('&&_DB_NAME')
		and column_label='Tablespace Used Space (MB)'
	and to_char(rollup_timestamp,'DD')='01'
	group by
		  rollup_timestamp
		, target_name
)
select
	  db_name
	, rollup_timestamp
	, round(db_average/1024/1024,1) db_used_tb
	, round((db_average - (lag(db_average,1) over (order by rollup_timestamp)))/1024, 0) growth_gb
from
	db_used_mb
	order by
	rollup_timestamp;



undefine 1
undefine _DB_NAME