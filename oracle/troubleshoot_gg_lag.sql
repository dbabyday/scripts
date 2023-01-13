
/* if using SQL*Plus, set the variables for the queries */
/* if using Oracle SQL Developer or TOAD, you will be pompted for the values in the queries */
variable lag_threshold_minutes number       = 5;
variable start_time            varchar2(19) = '2022-10-19 15:00:00';
variable end_time              varchar2(19) = '2022-10-19 16:00:00';




/* see when there was a lag */
select   'A' replicat
       , to_char(source_entry_time,'YYYY-MM-DD HH24:MI:SS') source_entry_time
       , to_char(target_entry_time,'YYYY-MM-DD HH24:MI:SS') target_entry_time
       , extract(day from (target_entry_time-source_entry_time))*24*60 +
              extract(hour from (target_entry_time-source_entry_time))*60 +
              extract(minute from (target_entry_time-source_entry_time)) lag_in_minutes
from     ca.repl_canary_a
where    extract(day from (target_entry_time-source_entry_time))*24*60 +
              extract(hour from (target_entry_time-source_entry_time))*60 +
              extract(minute from (target_entry_time-source_entry_time)) >= :lag_threshold_minutes
union all
select   'C' replicat
       , to_char(source_entry_time,'YYYY-MM-DD HH24:MI:SS') source_entry_time
       , to_char(target_entry_time,'YYYY-MM-DD HH24:MI:SS') target_entry_time
       , extract(day from (target_entry_time-source_entry_time))*24*60 +
              extract(hour from (target_entry_time-source_entry_time))*60 +
              extract(minute from (target_entry_time-source_entry_time)) lag_in_minutes
from     ca.repl_canary_c
where    extract(day from (target_entry_time-source_entry_time))*24*60 +
              extract(hour from (target_entry_time-source_entry_time))*60 +
              extract(minute from (target_entry_time-source_entry_time)) >= :lag_threshold_minutes
order by source_entry_time;




/* see the highest 10 wait events */
select	  a.wait_class
	, a.event
	, round(sum(time_waited) / 1000000, 1) seconds_waited
	, round(sum(time_waited) / 1000000 / 60, 1) minutes_waited
	, round(sum(time_waited) / 1000000 / 60 / 60, 1) hours_waited
from	  dba_hist_active_sess_history a
where	  a.wait_class is not null
	  and a.sample_time >= to_timestamp(:start_time,'YYYY-MM-DD HH24:MI:SS')
	  and a.sample_time <  to_timestamp(:end_time,'YYYY-MM-DD HH24:MI:SS')
group by  a.wait_class
	, a.event
order by  sum(a.time_waited) desc
fetch next 10 rows only;




/* if using SQL*Plus, set the variables for the queries */
/* if using Oracle SQL Developer or TOAD, you will be pompted for the values in the queries */
variable event varchar2(64) = 'enq: TX - row lock contention';

/* see what SQLs had that wait */
select	  a.sql_id
	, count(1) qty
	, u.username
	-- , (select sql_text from v$sql where sql_id=a.sql_id) sql_text
	-- , (select sql_fulltext from v$sql where sql_id=a.sql_id) sql_fulltext
from	  dba_hist_active_sess_history a
left join dba_users u on u.user_id=a.user_id
where	  a.event = :event
	  and a.sample_time >= to_timestamp(:start_time,'YYYY-MM-DD HH24:MI:SS')
	  and a.sample_time <  to_timestamp(:end_time,'YYYY-MM-DD HH24:MI:SS')
group by  a.sql_id
	, u.username
order by  count(1) desc;

