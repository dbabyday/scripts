

set feedback off
prompt Substitution variable 1 = _OWNER;
prompt Substitution variable 2 = _TABLE_NAME;
column my_owner new_value _OWNER noprint;
column my_table_name new_value _TABLE_NAME noprint;
select '&1' my_owner, '&2' my_table_name from dual;
set feedback on



column owner      format a15
column table_name format a15

prompt ------------------------------;
prompt --// TABLE                //--;
prompt ------------------------------;

SELECT
	  t.owner
	, t.table_name
	, t.num_rows
	, round((m.inserts + m.updates + m.deletes) / t.num_rows * 100,0) pct_mod
	, s.stale_stats
	, to_char(t.last_analyzed,'YYYY-MM-DD HH24:MI:SS') last_analyzed
FROM
	dba_tables t
LEFT JOIN
	dba_tab_modifications m ON t.owner=m.table_owner AND t.table_name=m.table_name
left join
	DBA_TAB_STATISTICS s on t.owner=s.owner and t.table_name=s.table_name
WHERE
	t.num_rows>0
	and t.owner in ('&&_OWNER')
	and t.table_name in ('&&_TABLE_NAME')
	-- AND (
	-- 	CASE
	-- 	        WHEN t.num_rows=0 THEN 1
	-- 	        WHEN m.table_name is null THEN 0
	-- 	        ELSE (m.inserts + m.updates + m.deletes) / t.num_rows
	-- 	END >= 0.1
	-- 	OR m.truncated='YES'
	-- )
	-- and t.num_rows>100
ORDER BY
	length(pct_mod)
	, pct_mod;




column table_owner for a15
column table_name for a15
column partition_name for a15

prompt ------------------------------;
prompt --// PARTITIONS           //--;
prompt ------------------------------;

SELECT
	  t.table_owner
	, t.table_name
	, t.partition_name
	, t.num_rows
	, round((m.inserts + m.updates + m.deletes) / t.num_rows * 100,0) pct_mod
	-- , m.inserts
	-- , m.updates
	-- , m.deletes
	, s.stale_stats
	, to_char(t.last_analyzed,'YYYY-MM-DD HH24:MI:SS') last_analyzed
FROM
	dba_tab_partitions t
LEFT JOIN
	dba_tab_modifications m ON t.table_owner=m.table_owner AND t.table_name=m.table_name and t.partition_name=m.partition_name
left join
	DBA_TAB_STATISTICS s on t.table_owner=s.owner and t.table_name=s.table_name and t.partition_name=s.partition_name
WHERE
	t.num_rows>0
	and t.table_owner in ('&&_OWNER')
	and t.table_name in ('&&_TABLE_NAME')
	-- AND (
	-- 	CASE
	-- 	        WHEN t.num_rows=0 THEN 1
	-- 	        WHEN m.table_name is null THEN 0
	-- 	        ELSE (m.inserts + m.updates + m.deletes) / t.num_rows
	-- 	END >= 0.1
	-- 	OR m.truncated='YES'
	-- )
	-- and t.num_rows>100
ORDER BY
	length(pct_mod)
	, pct_mod;


undefine 1
undefine 2
undefine _OWNER
undefine _TABLE_NAME