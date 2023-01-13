set echo off
set linesize 400
set pagesize 50

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



-- -- wait times in minutes
-- select   s.osuser
--        , s.username
--        , s.machine
--        , decode(s.event, 'db file scattered read',  'Full Table Scan',
--                          'db file sequential read', 'Index Scan', 
--                          s.event ) event
--        , count(1) qty_ses
--        , max(s.seconds_in_wait)/60 max_mins
--        , min(s.seconds_in_wait)/60 min_mins
--        , sum(s.seconds_in_wait)/60 sum_mins
--        , avg(s.seconds_in_wait)/60 avg_mins
-- from     gv$session s
-- where    s.wait_class <> 'Idle'
-- group by s.osuser
--        , s.username
--        , s.machine
--        , s.event
-- order by qty_ses desc
--        , sum_minsdesc
--        , username
--        , event
-- /

