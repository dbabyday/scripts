
/*
-- pd: execute in jdepd03 to create db link to jdepd01
set echo off feedback on define "&"
drop database link jdepd01_jlutsey;
accept _PW char prompt 'JLUTSEY jdepd01 password: ' hide
create database link jdepd01_jlutsey connect to jlutsey identified by "&_PW" using 'jdepd01';
undefine _PW

-- non-prod: execute in envrionment's database to create db link to jdepr01
set echo off feedback on define "&"
drop database link jdepr01_jlutsey;
accept _PW char prompt 'JLUTSEY jdepr01 password: ' hide
create database link jdepr01_jlutsey connect to jlutsey identified by "&_PW" using 'jdepr01';
undefine _PW

*/


set lines 1000
set define "&"
column event format a30
column machine format a15
column region format a6
column logon_time format a19
column avg_secs format 999999.999
column sql_fulltext format a500


with job as (
	-- py
	select jcfndfuf2, jcjobnbr, jcprocessid
	from   svmpy92.f986110@jdepr01_jlutsey -- PY
	-- from   svm920.f986110@jdepr01_jlutsey -- DV
	-- from   svmcv92.f986110@jdepr01_jlutsey -- CV
	-- from   svmtr92.f986110@jdepr01_jlutsey -- TR
	where  jcfndfuf2 like '%&&_JOB_NAME_LIKE%' and jcjobsts = 'P'
)
select
	  j.jcfndfuf2
	, j.jcjobnbr
	, j.jcprocessid
	, s.sid
	, s.serial#
	, substr(sw.event,1,55) event
	, substr(s.machine,1,15) machine
	-- , s.program
	, to_char(s.logon_time,'YYYY-MM-DD HH24:MI:SS') logon_time
	, sa.executions
	, sa.rows_processed
	, round(sa.elapsed_time/1000000/sa.executions,3) avg_secs
	, sa.sql_id
	, sa.sql_fulltext
from
	job j
join
	v$session s on s.process=to_char(j.jcprocessid)
join
	v$session_wait sw on sw.sid=s.sid
join
	v$sqlarea sa on s.sql_id=sa.sql_id
where
	s.program like 'runbatch%'
order by
	s.logon_time;





prompt ## filtering on jcfndfuf2 like '%&&_JOB_NAME_LIKE%';
prompt ## to clear filter: undefine _JOB_NAME_LIKE;
prompt;

