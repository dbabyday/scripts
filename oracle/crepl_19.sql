set echo off
set feedback off
set linesize 400
set pagesize 500



prompt ;
prompt ;
prompt ;
prompt ;
prompt ======================================================;
prompt ==// REPLICATION LAG                              //==;
prompt ======================================================;

column source_db format a9
column target_db format a9
column incoming_path format a25

select   remote_database source_db
       , local_database  target_db
       , incoming_path
       , round(incoming_lag/60,0) incoming_lag_minutes
--       , round(incoming_lag/3600,1) incoming_lag_hours
from     gg_adm.gg_lag
order by incoming_path
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