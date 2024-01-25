set pagesize 55

set feedback off
prompt Substitution variable 1 = DB_NAME;
prompt Substitution variable 2 = TS_NAME;
column my_db_name new_value _DB_NAME noprint;
column my_ts_name new_value _TS_NAME noprint;
select '&1' my_db_name, '&2' my_ts_name from dual;
set feedback on


column db_name format a10
column tablespace_name format a20

prompt;
prompt ------------------------------------------------;
prompt --// DAILY                                  //--;
prompt ------------------------------------------------;
prompt;

-- daily
select
	  target_name db_name
	, key_value tablespace_name
	, to_char(rollup_timestamp-1,'Day DD Month YYYY') day
	, round((average - (lag(average,1) over (order by rollup_timestamp)))/1024, 0) growth_gb
	, round(average/1024,0) tablespace_used_gb
from
	sysman.mgmt$metric_daily
where
	upper(target_name) = upper('&&_DB_NAME')
	and upper(key_value)=upper('&&_TS_NAME')
	and column_label='Tablespace Used Space (MB)'
order by
	rollup_timestamp;


prompt;
prompt ------------------------------------------------;
prompt --// WEEKLY                                 //--;
prompt ------------------------------------------------;
prompt;

-- weekly
select
	  target_name db_name
	, key_value tablespace_name
	, to_char(lag(rollup_timestamp,1) over (order by rollup_timestamp),'DD Mon')||' - '||to_char(rollup_timestamp-1,'DD Mon YYYY') week
	, round((average - (lag(average,1) over (order by rollup_timestamp)))/1024, 0) growth_gb
	, round(average/1024,0) tablespace_used_gb
from
	sysman.mgmt$metric_daily
where
	upper(target_name) = upper('&&_DB_NAME')
	and upper(key_value)=upper('&&_TS_NAME')
	and column_label='Tablespace Used Space (MB)'
	and to_char(rollup_timestamp,'fmDAY')='MONDAY'
order by
	rollup_timestamp;


prompt;
prompt ------------------------------------------------;
prompt --// MONTHLY                                //--;
prompt ------------------------------------------------;
prompt;

-- monthly
select
	  target_name db_name
	, key_value tablespace_name
	, to_char(lag(rollup_timestamp,1) over (order by rollup_timestamp),'Month YYYY') month
	, round((average - (lag(average,1) over (order by rollup_timestamp)))/1024, 0) growth_gb
	, round(average/1024,0) tablespace_used_gb
from
	sysman.mgmt$metric_daily
where
	upper(target_name) = upper('&&_DB_NAME')
	and upper(key_value)=upper('&&_TS_NAME')
	and column_label='Tablespace Used Space (MB)'
	and to_char(rollup_timestamp,'DD')='01'
order by
	rollup_timestamp;

