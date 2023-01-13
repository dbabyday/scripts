/****************************************************************************************************
* 
* troubleshoot_jde_slow_ube.sql
* 
* Purpose: How to identify the database session used by a running UBE, and see the SQL it is running
* When you need to do it:  If a user complains that a particular UBE is running longer than normal.
* 
* Info needed: Ask the user for the UBE name that is running, for example R5534021_PLX001
* 
****************************************************************************************************/




-- get process id for slow ube
-- jdepd01
select jcjobnbr
     , jcprocessid 
from   sv12920.f986110 
where  jcfndfuf2 like '%P4312%' 
       and jcjobsts = 'P'
/



-- use process id to get session and wait event
-- jdepd03
select   b.process
       , b.sid
       , b.serial#
       , substr(sw.event,1,55) event
       , substr(machine,1,15) machine
       , to_char(logon_time,'mm/dd/yyyy hh24:mi:ss') time
from     v$session b
       , v$session_wait sw
where    program like 'runbatch%'
         and b.process = &JCPROCESSID
         and sw.sid = b.sid
order by logon_time
/



-- can run repeatedly to see the sql statements being executed
-- jdepd03
set long 32000
select a.sid
     , a.sql_id
     , b.sql_fulltext
     , b.executions
     , b.rows_processed
     , b.elapsed_time/1000000/b.executions 
from   v$session a
     , v$sqlarea b
where  a.sid in (332)
       and a.sql_id = b.sql_id
/


-- look for inefficient sql statement

/*
	A very "quick-and-dirty" way to force the optimizer to reparse a SQL statement then next time 
	it runs is to force a DDL statement on the table in question. A very easy way to do this is 
	to issue a null comment on the table:  comment on table proddta.f03b11 is ''
	You can also flush the SQL statement out of the SQL cache, recalculate statistics, etc.
*/


select sid from v$session
where process in (3964161,3945842,3775374,4029237,3729796,4019663,3989112,3983259,3971841,4029260,4030506,4032858,2468839,4031076,3611267)
and sql_id='8ut0xv1ph77vv'



select jcjobnbr, jcprocessid from sy920.f986110 where jcfndfuf2='R5503023_PLX00002' and jcjobsts = 'P';
select jcjobnbr, jcprocessid from sv10920.f986110 where jcfndfuf2='R5503023_PLX00002' and jcjobsts = 'P';
select jcjobnbr, jcprocessid from sv11920.f986110 where jcfndfuf2='R5503023_PLX00002' and jcjobsts = 'P';
select jcjobnbr, jcprocessid from sv12920.f986110 where jcfndfuf2='R5503023_PLX00002' and jcjobsts = 'P';
select jcjobnbr, jcprocessid from sv20920.f986110 where jcfndfuf2='R5503023_PLX00002' and jcjobsts = 'P';
select jcjobnbr, jcprocessid from sv21920.f986110 where jcfndfuf2='R5503023_PLX00002' and jcjobsts = 'P';
select jcjobnbr, jcprocessid from sv22920.f986110 where jcfndfuf2='R5503023_PLX00002' and jcjobsts = 'P';










