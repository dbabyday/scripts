/****************************************************************************************************
* 
* troubleshoot_jde_slowness.sql
* 
* Purpose: How to check the general state of the JDE database
* When you need to do it:  If users complain of slowness in the database.
* 
* Info needed: Ask the users if the issue is with a JDE UBE or interactive queries
* 
****************************************************************************************************/




-- look for full table scans
-- Run the following query in the JDEPD01 database
select   s.sid
       , s.program
       , target
       , time_remaining/60 timer
       , round(sofar/totalwork*100,2) pct
from     v$session_longops l
       , v$session s
where    opname not like '%aggregate%'
         and totalwork != 0
         and sofar <> totalwork
         and l.sid = s.sid
order by 4 desc
/

/*
	An overloaded database “may” be experiencing many full table scans, but it’s also 
	informative to watch the full table scans occur over a matter of minutes.  This 
	will give you an idea where they are coming from and how long they are running.  
	It will also often give you some quick insight into what may benefit from a new index.
*/




-- look for the active interactive queries
-- Run the following query in the JDEPD01
  set long 32000
  select   b.sql_id
         , c.sql_fulltext
         , c.executions
         , c.rows_processed
         , c.elapsed_time/1000000/executions
         , c.elapsed_time/1000000
  from     v$session b
         , v$sqlarea c
  where    b.wait_class != 'Idle'
           and b.program like 'JDBC%'
           and b.sql_id = c.sql_id
  order by 5
  /

/*
	Users that complain about slow interactive queries can often be located simply by watching 
	the active queries coming from a JDBC connection.  (Interactive queries come through the web servers.)  
	At Plexus, you can identify the region associated with these queries by also looking at the 
	column MACHINE in v$session.  This will tell you the web server that issued the SQL statement.
*/




-- look for querys running against a named table
select   sql_id
       , sql_fulltext
       , executions
       , elapsed_time/1000000/executions avg_elapsed_seconds
       , elapsed_time/1000000 elapsed_seconds
       , last_active_time
       , module
from     v$sql
where    upper(sql_text) like '%F4111%'
         and executions > 0
         -- and module like 'runbatch%'
order by avg_elapsed_seconds
/


select   sql_text
       , executions
       , elapsed_time/1000000/executions
       , elapsed_time/1000000
       , module
from     v$sqlarea
where    upper(sql_text) like '%&table_name%'
         and executions > 0
         and module like 'JDBC Thin Client'
order by elapsed_time
/



-- Sometimes all you know is that batch job performance is “slow”.
-- The following query will show you all active SQL statements coming from UBEs:
select   b.process
       , b.sid
       , b.serial#
       , substr(sw.event,1,55) event
       , substr(machine,1,15) machine
       , to_char(logon_time,'mm/dd/yyyy hh24:mi:ss') time
from     v$session b
       , v$session_wait sw
where    program like 'runbatch%'
and      sw.sid = b.sid
order by logon_time
/

/*
	The previous query might return a lot of information if there are multiple UBEs 
	running at the same time, which is typically the case at Plexus.  A way to filter 
	the queries from UBEs down to a more meaningful list is to issue the next query:
*/


-- filter ube sessions
select   b.process
       , b.sid
       , b.serial#
       , substr(sw.event,1,55) event
       , substr(machine,1,15) machine
       , to_char(logon_time,'mm/dd/yyyy hh24:mi:ss') time
from     v$session b
       , v$session_wait sw
where    program like 'runbatch%'
         and sw.sid = b.sid
         and b.event not like 'SQL*Net%'
order by logon_time
/

/*
	Usually, well-running UBEs will be active in the database but spend most of their 
	time in a Sql*Net wait event. Filtering those out, you can focus on the remaining 
	SQL statements as a source of the database issue.  

	Normally, a well-running UBE will spend at least twice the amount of time outside 
	of the database as it spends inside the database.  If you happen to do a database trace 
	and see that most of the time spent by a UBE is inside the database, you can almost 
	certainly know that the UBE is not running efficiently.
*/



-- get detailed information on all UBEs that are currently active in the database.
-- The following script provides additional details that may be helpful in tuning UBEs:
/*

@troubleshootJDE_wait_details_ubes.sql

Sample output:
Statement Number: 1
--------------------------------------------
SID Id         : 3275
OS User        : jde920
Oracle User    : JDER
Source Machine : gcc-jde-pd-010
Source Program : runbatch@gcc-jde-pd-010 (TNS V1-V3)
Source Terminal:
Source Process : 304550
Wait Event     : PX Deq: Join ACK
Disk Reads     : 1386045
Buffer Gets    : 115249503
First Load Time: 2019-05-31/18:00:10
Executions     : 643239
Avg Run Seconds: 2.5799
SQL Profile    :
Rows Processed : 11159302
No Secs Waiting: 0
Wait Parm 1    : 0
Wait Parm Info : sleeptime/senderid
Wait Parm 2    : 0
Wait Parm Info : passes
Wait Parm 3    : 0
Wait Parm Info :
SQL Id         : fga9hmjb62pp8
SQL Child No   : 2
SQL Statement-------->
.....SELECT  *  FROM PRODDTA.F0911  WHERE  ( GLMCU = :KEY1 AND GLOBJ = :KEY2
.....AND GLSBL = :KEY3 AND GLSBLT = :KEY4 AND GLLT = :KEY5 )  ORDER BY GLDCT
.....ASC,GLDOC ASC,GLKCO ASC,GLDGJ DESC,GLJELN ASC,GLLT ASC,GLEXTL ASC
"Peeked" Bind Values Captured-------->
1-       680
2- 123000
3- 35701746
4- W
5- AA
****** Optimizer Path -------->
Operation: INDEX
Object: PRODDTA.F0911_32
Index Column: GLSBL
Index Column: GLSBLT
Index Column: GLLT
Operation: PX COORDINATOR
Object: .
Operation: PX PARTITION RANGE
Object: .
Operation: PX RECEIVE
Object: .
Operation: PX SEND
Object: SYS.:TQ10000
Operation: PX SEND
Object: SYS.:TQ10001
--------------------------------------------

*/