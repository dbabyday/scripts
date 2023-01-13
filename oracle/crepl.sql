set echo off
set linesize 400
set pagesize 500



prompt ;
prompt ;
prompt ;
prompt ;
prompt ======================================================;
prompt ==// REPLICATION LAG                              //==;
prompt ======================================================;


column replicat format a8

select   'D' replicat
       , to_char(max(source_entry_time),'YYYY-MM-DD HH24:MI:SS') canary_entry
       , to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS') time_checked
       , extract(day from (systimestamp - max(source_entry_time)))*24*60 +
              extract(hour from (systimestamp - max(source_entry_time)))*60 +
              extract(minute from (systimestamp - max(source_entry_time))) lag_in_minutes
from     ca.repl_canary_a
union all
select 'E' replicat
       , to_char(max(source_entry_time),'YYYY-MM-DD HH24:MI:SS') canary_entry
       , to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS') time_checked
       , extract(day from (systimestamp - max(source_entry_time)))*24*60 +
              extract(hour from (systimestamp - max(source_entry_time)))*60 +
              extract(minute from (systimestamp - max(source_entry_time))) lag_in_minutes
from     ca.repl_canary_c
order by  1
/



prompt ;
prompt ;
prompt ;
prompt ;
prompt ======================================================;
prompt ==// WAITS                                        //==;
prompt ======================================================;

col osuser format a20
col username format a20
col machine format a20
col event format a55
col max_secs format 999,999
col min_secs format 999,999
col sum_secs format 999,999
col avg_secs format 999,999
col max_mins format 999,999
col min_mins format 999,999
col sum_mins format 999,999
col avg_mins format 999,999



-- wait times in seconds
select   s.osuser
       , s.username
       , s.machine
       , decode(s.event, 'db file scattered read',  'Full Table Scan',
                         'db file sequential read', 'Index Scan', 
                         s.event ) event
       , count(1) qty_ses
       , max(s.seconds_in_wait) max_secs
       , min(s.seconds_in_wait) min_secs
       , sum(s.seconds_in_wait) sum_secs
       , avg(s.seconds_in_wait) avg_secs
from     gv$session s
where    s.wait_class <> 'Idle'
group by s.osuser
       , s.username
       , s.machine
       , s.event
order by qty_ses desc
       , sum_secs desc
       , username
       , event
/



prompt ;
prompt ;
prompt ;
prompt ;
prompt ======================================================;
prompt ==// GG_APPLY_SERVER                              //==;
prompt ======================================================;

column SUM_TOT_MSGS_APPLIED format 999,999,999,999,999,999

select sum(TOTAL_MESSAGES_APPLIED) SUM_TOT_MSGS_APPLIED from v$gg_apply_server order by server_id
/

prompt ;
prompt ;
prompt ;
prompt ;