column canary_entry format a20
column canary_table format a21
column replicat     format a10
column replicat_lag format a20
column time_checked format a20
column source_entry_time format a25
column target_entry_time format a25




prompt ;
prompt ;
prompt ;
prompt -----------------------------;
prompt --// HISTORIC LAG        //--;
prompt -----------------------------;
prompt ;


/* REPLICAT A */
set feedback off
variable lag_threshold_minutes number;
declare
	l_min_hist_time timestamp(6);
begin
	:lag_threshold_minutes := 5;

	select min(source_entry_time)
	into   l_min_hist_time
	from   ca.repl_canary_a;

	dbms_output.put_line('Replication stream : A');
	dbms_output.put_line('History time start : '||to_char(l_min_hist_time,'YYYY-MM-DD HH24:MI:SS'));
	dbms_output.put_line('Time now           : '||to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS'));
	dbms_output.put_line('Lag threshold      : '||to_char(:lag_threshold_minutes)||' minutes');
end;
/
set feedback on

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
order by source_entry_time
/


/* REPLICAT C */
set feedback off
declare
	l_min_hist_time timestamp(6);
begin
	select min(source_entry_time)
	into   l_min_hist_time
	from   ca.repl_canary_c;

	dbms_output.put_line('Replication stream : C');
	dbms_output.put_line('History time start : '||to_char(l_min_hist_time,'YYYY-MM-DD HH24:MI:SS'));
	dbms_output.put_line('Time now           : '||to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS'));
	dbms_output.put_line('Lag threshold      : '||to_char(:lag_threshold_minutes)||' minutes');
end;
/
set feedback on

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
order by source_entry_time
/






prompt ;
prompt ;
prompt ;
prompt -----------------------------;
prompt --// CURRENT LAG         //--;
prompt -----------------------------;
prompt ;


select   'A' replicat
       , to_char(max(source_entry_time),'YYYY-MM-DD HH24:MI:SS') canary_entry
       , to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS') time_checked
       , extract(day from (systimestamp - max(source_entry_time)))*24*60 +
              extract(hour from (systimestamp - max(source_entry_time)))*60 +
              extract(minute from (systimestamp - max(source_entry_time))) lag_in_minutes
from     ca.repl_canary_a
union all
select 'C' replicat
       , to_char(max(source_entry_time),'YYYY-MM-DD HH24:MI:SS') canary_entry
       , to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS') time_checked
       , extract(day from (systimestamp - max(source_entry_time)))*24*60 +
              extract(hour from (systimestamp - max(source_entry_time)))*60 +
              extract(minute from (systimestamp - max(source_entry_time))) lag_in_minutes
from     ca.repl_canary_c
order by  1
/