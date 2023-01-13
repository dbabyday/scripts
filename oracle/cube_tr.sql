
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
column time_in_wait format a13


with job as (
	/*
	-- prod
	select jcfndfuf2, jcjobnbr, jcprocessid
	from   sv10920.f986110@jdepd01_jlutsey -- amer
	where  jcfndfuf2 like '%&&_JOB_NAME_LIKE%' and jcjobsts = 'P'
	union all
	select jcfndfuf2, jcjobnbr, jcprocessid
	from   sv11920.f986110@jdepd01_jlutsey -- emea
	where  jcfndfuf2 like '%&&_JOB_NAME_LIKE%' and jcjobsts = 'P'
	union all
	select jcfndfuf2, jcjobnbr, jcprocessid
	from   sv12920.f986110@jdepd01_jlutsey -- apac
	where  jcfndfuf2 like '%&&_JOB_NAME_LIKE%' and jcjobsts = 'P'
	*/
	
	-- non-prod
	select jcfndfuf2, jcjobnbr, jcprocessid
	-- from   svmpy92.f986110@jdepr01_jlutsey -- py
	-- from   svm920.f986110@jdepr01_jlutsey -- dv
	-- from   svmcv92.f986110@jdepr01_jlutsey -- cv
	from   svmtr92.f986110@jdepr01_jlutsey -- tr
	where  jcfndfuf2 like '%&&_JOB_NAME_LIKE%' and jcjobsts = 'P'
)
select
	  j.jcfndfuf2
	, j.jcjobnbr
	, j.jcprocessid
	, s.sid
	, s.serial#
	, substr(sw.event,1,55) event
	, case
		when sw.seconds_in_wait > 3600 then to_char(round(sw.seconds_in_wait/3600,1))||' hours'
		when sw.seconds_in_wait > 60 then to_char(round(sw.seconds_in_wait/60,1))||' minutes'
		else to_char(sw.seconds_in_wait)||' seconds'
	  end time_in_wait
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
left join
	v$session_wait sw on sw.sid=s.sid
left join
	v$sqlarea sa on s.sql_id=sa.sql_id
where
	s.program like 'runbatch%'
order by
	s.logon_time;





prompt;
prompt ## Filtering on jcfndfuf2 like '%&&_JOB_NAME_LIKE%';
prompt ## To clear filter: UNDEFINE _JOB_NAME_LIKE;
prompt;

