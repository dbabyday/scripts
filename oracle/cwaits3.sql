set echo off
set linesize 400
set pagesize 50

col osuser format a20
col username format a20
col machine format a20
col wait format a55
col max_secs format 999,999
col min_secs format 999,999
col sum_secs format 999,999
col avg_secs format 999,999
col max_mins format 999,999
col min_mins format 999,999
col sum_mins format 999,999
col avg_mins format 999,999


prompt ;
prompt Note:;
prompt - db file scattered read = Full Table Scan;
prompt - db file sequential read = Index Scan;
prompt ;

-- wait times in seconds
select   
	  s.wait_class
	, s.event wait
	, s.username
	, count(1) qty_ses
	, max(s.seconds_in_wait) max_secs
	, min(s.seconds_in_wait) min_secs
	, sum(s.seconds_in_wait) sum_secs
	, avg(s.seconds_in_wait) avg_secs
from     gv$session s
where    s.wait_class <> 'Idle'
group by
	  s.wait_class
	, s.event
	, s.username
order by
	  qty_ses desc
	, sum_secs desc
	, s.wait_class
	, s.event
	, s.username
/


