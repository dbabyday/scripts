column BEGIN_INTERVAL_TIME format a25
column END_INTERVAL_TIME format a25
column executions_total format 999,999,999,999
column executions_delta format 999,999,999,999
column parsing_schema_name format a20
column executions_choice noprint

/* highest executions in most recent snapshot */
with most_recent_snapshot as (
	select   snap_id
	       , begin_interval_time
	       , end_interval_time
	from     dba_hist_snapshot
	order by begin_interval_time desc
	fetch next 1 rows only
)
select   snap.snap_id
       , to_char(snap.begin_interval_time,'YYYY-MM-DD HH24:MI:SS') begin_interval_time
       , to_char(snap.end_interval_time,'YYYY-MM-DD HH24:MI:SS') end_interval_time
       , stat.sql_id
       , stat.executions_delta
       , stat.executions_total
       , case when stat.executions_delta=0 then stat.executions_total else stat.executions_delta end executions_choice
from     most_recent_snapshot snap
join     dba_hist_sqlstat  stat on stat.snap_id=snap.snap_id
-- order by stat.executions_delta desc
order by executions_choice desc
fetch next 20 rows only;


/* executions over time for sql_id */
select   snap.snap_id
       , to_char(snap.begin_interval_time,'YYYY-MM-DD HH24:MI:SS') begin_interval_time
       , to_char(snap.end_interval_time,'YYYY-MM-DD HH24:MI:SS') end_interval_time
       , stat.sql_id
       , stat.executions_delta
       , stat.executions_total
       , stat.parsing_schema_name
from     dba_hist_snapshot snap
join     dba_hist_sqlstat  stat on stat.snap_id=snap.snap_id
where    stat.sql_id='&sql_id'
order by snap.begin_interval_time;




