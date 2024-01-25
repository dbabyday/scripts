Title		: ASH Scratch Pad 1-Nov-2021, v3f
Author		: Craig A. Shallahamer, craig@orapub.com
Copyright	: (c)OraPub, Inc.
Warrenty	: Absolultey no warrenty. Use at your own risk.

Thank you to everyone who has helped improve this toolkit!

There are five scripts. Each script uses the same core Oracle SQL*Plus DEFINES. The
common defines and common column formats are shown just a little below. The script
specific defines are shown with each script. Obviously, if nothing has changed, then you
do not need to reset the define.

The defines and scripts are created to be copied and pasted directly into SQL*Plus.

The scripts are:

1. Profile Anything - Get a summary of the situation at any level; instance, sql_id,
   session, module, force matching signature,... anything in the source table.

2. Top Anything - Get the top and not so top anything by CPU or WAIT or either; sql_id,
   session, plan_hash_value, event... anything in the source table.
   
3. Timeline Most Anything - Get a sample by sample linear report for a specific session,
   module, sql_id... most anything.
   
4. Tick Report - Get a summary of the entire system grouped by X number of seconds.
   This is like a timeline report, but each line represents all the activity for X seconds.

5. SQL Statement Run Time Inference Report - Infer SQL runtimes using
   the modified max/min sample_time method. See https://blog.orapub.com for blog posting.

Check out OraPub for ASH webinars, memberships and ASH Live Video Classroom (LVC) training!


-----------------------------------------------------------------------
Understanding ASH Data
-----------------------------------------------------------------------

set tab off
set verify on
set linesize 300
col minSt format a25
col maxSt format a25

select count(*) from v$active_session_history;

select min(sample_time) minSt, max(sample_time) maxSt from   v$active_session_history;

select distinct session_state, session_type from v$active_session_history;

select sum(decode(session_state,'ON CPU',1,0)) oncpu,
       sum(decode(session_state,'WAITING',1,0)) waiting
from   v$active_session_history;

select sum(decode(session_state,'ON CPU',1,0)) oncpu,
       sum(decode(session_state,'WAITING',1,0)) waiting
from   v$active_session_history
where  sample_time >= current_timestamp - interval '3' minute;


-----------------------------------------------------------------------
Common ASH Scratch Pad Defines
-----------------------------------------------------------------------

All Scratch Pad scripts need the three below defines set; datasource, dbahistdetails
and timing details.

def datasource=v$active_session_history
def datasource=dba_hist_active_sess_history
def datasource=OP_DBA_HIST_ACTV_SESS_HIST
def datasource=BH2016JUNESPIKE

select dbid, instance_number,
       min(sample_time) minSt, max(sample_time) maxSt, count(*)
from   &datasource
group by dbid, instance_number
/

def dbahistdetails=' and dbid=954738332 and instance_number=1'
def dbahistdetails=' and dbid=954738332 and instance_number=1'
def dbahistdetails=' and dbid=3340869378 and instance_number=1'
def dbahistdetails=' and dbid=3627646567 and instance_number=3'
def dbahistdetails=' and 1=1'

def timingdetails="sample_time >= current_timestamp - interval '1' minute" 

def timingdetails="sample_time between to_date('29-Oct-2023 22:00','DD-Mon-YYYY HH24:MI') and to_date('30-Oct-2023 02:00','DD-Mon-YYYY HH24:MI')"
def timingdetails="sample_time between to_date('05-Sep-2017 11:00','DD-Mon-YYYY HH24:MI') and to_date('05-Sep-2017 14:00','DD-Mon-YYYY HH24:MI')"
def timingdetails="sample_time between to_date('01-Jan-2018 08:00','DD-Mon-YYYY HH24:MI') and to_date('01-Jan-2021 08:00','DD-Mon-YYYY HH24:MI')"
def timingdetails="sample_time between to_date('22-Jun-2014 10:00','DD-Mon-YYYY HH24:MI') and to_date('22-Jun-2019 14:00','DD-Mon-YYYY HH24:MI')"
def timingdetails="sample_time between to_date('22-Jun-2016 14:02','DD-Mon-YYYY HH24:MI') and to_date('22-Jun-2016 14:04','DD-Mon-YYYY HH24:MI')"
def timingdetails="1=1"

---
--- Check to ensure you are looking at the right data
---

set tab off
set verify on
set linesize 300
col minSt format a25
col maxSt format a25

-- This will work for both v$ and DBA_HIST ASH data.
--
select min(sample_time) minSt, max(sample_time) maxSt, count(*)
from   &datasource
where  &timingdetails
       &dbahistdetails
/

-- This will work ONLY if you are using DBA_HIST like data.
--
col inum format 999
select dbid, instance_number inum,
       min(sample_time) minSt, max(sample_time) maxSt, count(*)
from   &datasource
where  &timingdetails
       &dbahistdetails
group by dbid, instance_number
/


-----------------------------------------------------------------------
Extracting Your Chosen Data
-----------------------------------------------------------------------

To minimize touching a production system, it can be very helpful
to extract production ASH data and then import it into a non-production system.

Also, quickly saving "incident" data can be verfy helpful for later extended analysis
and for educational purposes.

create table myASHextract as
select *
from   &datasource
where  &timingdetails
       &dbahistdetails
/

Here is an actual example to grab the entire v$ash ring:

create table myASHextract as
select	*
from	v$active_session_history
/


-----------------------------------------------------------------------
-- Common Column Formats
-----------------------------------------------------------------------

set tab off
set verify on
set linesize 300
col minSt format a25
col maxSt format a25

col sql_id format a15
col session_type format a15
col SESSION_STATE format a7 heading "STATE"
col program format a25 trunc
col module format a15 trunc
col action format a25
col sid format 9999
col event format a25 trunc
col blocking_session heading 'BLK SID'
col session_state format a13
col force_matching_signature format 99999999999999999999
col in_parse heading "P"
col in_hard_parse heading "HP"
col bt format a20  heading "START"
col st format a11 heading "SAMPLE TIME"
col inum format 999


-----------------------------------------------------------------------
--- TOP ANYTHING
-----------------------------------------------------------------------

-- What is the top SQL?
-- What is the top SQL when waiting?
-- What is the top session? (w/session_type, program)
-- What is the top session when waiting? (w/session_state,sql_id,event)
-- What is the top force matching signature when the event is...

def ashCols='event,SQL_ID,program'
def ashCols='event,force_matching_signature'
def ashCols='event,module'
def ashCols='event,session_id,session_serial#'
def ashCols='event,session_id,session_type,program,sql_id'
def ashCols='session_state,SQL_ID'
def ashCols='program'
def ashCols='module,action,sql_id'
def ashCols='session_id,session_type,session_state,SQL_ID,event'
def ashCols='session_id,session_state,SQL_ID,event'
def ashCols='session_type,session_id,event'
def ashCols='session_id,session_serial#'
def ashCols='SQL_ID'
def ashCols='SQL_ID,session_id,session_serial#'
def ashCols='event,SQL_ID,session_id,session_serial#'
def ashCols="to_char(sample_time,'DD HH24:MI:SS')"
def ashCols="sql_id,to_char(SQL_EXEC_START,'MI:SS'),sql_exec_id"
def ashCols="sql_id,SQL_PLAN_HASH_VALUE,to_char(SQL_EXEC_START,'MI:SS') DT,sql_exec_id"
def ashCols="sql_id,SQL_PLAN_HASH_VALUE,to_char(SQL_EXEC_START,'MI:SS')||sql_exec_id"
def ashCols="to_char(sample_time,'HH24') dt,SQL_ID"
def ashCols="in_hard_parse,force_matching_signature"

col dt format a11 heading "SAMPLE TIME"

def ashstate='ON CPU'
def ashstate='WAITING'
def ashstate='%'

def ashWhere='1=1'
def ashWhere="in_hard_parse='Y'"
def ashWhere="event='db file sequential read'"
def ashWhere="sql_id='9jfcug4cmwtj6'"

def ashCount="1"

select * from (
  select count(&ashCount) the_count, &ashCols
  from   &datasource
  where  &timingdetails
         &dbahistdetails
    and  session_state like '&ashstate'
    and  &ashWhere
  group by &ashCols
  order by 1 desc, 2 desc
) 
where rownum < 50
/


-----------------------------------------------------------------------
--- TIMELINE
-----------------------------------------------------------------------

def ashCols='event,sql_id,blocking_session'
def ashCols='event,sql_id,blocking_session,module'
def ashCols='event,sql_id,module,program,blocking_session'
def ashCols='event,program'
def ashCols='event,sql_id,blocking_session,blocking_inst_id'
def ashCols='event,sql_id,blocking_session,program'
def ashCols='event,sql_id,SQL_PLAN_HASH_VALUE'
def ashCols='event,sql_id,SQL_PLAN_HASH_VALUE,sql_exec_id'
def ashCols="sql_id,event,program,to_char(SQL_EXEC_START,'YYYY-MM-DD HH:MI:SS') BT,sql_exec_id,event, user_id"
def ashCols="event,sql_id,SQL_PLAN_HASH_VALUE,to_char(SQL_EXEC_START,'YYYY-MM-DD HH:MI:SS') BT"
def ashCols="event,sql_id,SQL_PLAN_HASH_VALUE,to_char(SQL_EXEC_START,'YYYY-MM-DD HH:MI:SS') BT,sql_exec_id"
def ashCols="event,sql_id,blocking_session,to_char(SQL_EXEC_START,'MI:SS') BT,sql_exec_id"
def ashCols="wait_class"
def ashCols="user_id, session_id, session_serial#"
def ashCols="sql_id"

def ashWhere='session_id=8626'
def ashWhere='session_id=16234 and session_serial#=27262'
def ashWhere="client_id='COBOL-120-Step-Diaster'"
def ashWhere='session_id=321'
def ashWhere="event like 'enq:%TX%'"
def ashWhere="event like 'enq:%MF%'"
def ashWhere="1=1"
def ashWhere="wait_class='User I/O'"
def ashWhere="sql_id='6caws9q7ft956'"
def ashWhere="MODULE like 'AMSOPTECH%'"
def ashWhere="user_id in (806,807)"
def ashWhere="sql_id in (select sql_id from v$sql where lower(sql_text) like '%f58int%')"
def ashWhere="sql_id='1rbnmurhq7srp'"
select sample_id, to_char(sample_time,'DD HH24:MI:SS') ST,
       session_id sid, session_state,
       &ashCols
from   &datasource
where  &timingdetails
       &dbahistdetails
  and  &ashWhere
order by 1,3
/

select &ashCols, count(*), to_char(min(sample_time),'YYYY-MM-DD HH24:MI:SS') min_sample_time, to_char(max(sample_time),'YYYY-MM-DD HH24:MI:SS') max_sample_time
from   &datasource
where  &timingdetails
       &dbahistdetails
  and  &ashWhere
group by &ashCols
having min(sample_time)<to_timestamp('2023-10-19 08:06:00','YYYY-MM-DD HH24:MI:SS')
	AND max(sample_time)>to_timestamp('2023-10-19 08:14:00','YYYY-MM-DD HH24:MI:SS')
order by 2,3
/


   USER_ID SESSION_ID SESSION_SERIAL#   COUNT(*) MIN_SAMPLE_TIME     MAX_SAMPLE_TIME
---------- ---------- --------------- ---------- ------------------- -------------------
       807      16234           27262         60 2023-10-19 08:05:07 2023-10-19 08:14:58
       807       8668           55838         60 2023-10-19 08:05:07 2023-10-19 08:14:58

-----------------------------------------------------------------------
--- PROFILE
-----------------------------------------------------------------------

-- Make sure both key/value pairs are set, 1 and 2
--
-- profile all sessions (session_id  %)
-- profile the wait situation for all sessions (session_id   %)
-- profile session 50 (session_id  50)
-- profile session 50 serial # 1234 (session_id 50, session_serial# 1234)
-- profile sql_id (sql_id   abc123)

def ashcolkey1=1
def ashcolval1=1

def ashcolkey1=sql_id
def ashcolval1='7pkuzfhjsgp0f'

def ashcolkey1=module
def ashcolval1='inventory'

def ashcolkey1=session_id
def ashcolval1=2177

def ashcolkey2=1
def ashcolval2=1

def ashcolkey2=session_serial#
def ashcolval2=12301


set verify off
col totAS heading "Total|AS"
col cpuPct format 990.0 heading "CPU|PCT"
col waitingPct format 990.0 heading "WAITING|PCT"
col ioPct format 990.0 heading "WAITING|IO PCT"
col otherPct format 990.0 heading "WAITING|OTHER PCT"
col oncpuinparseX heading "CPU|PARSING PCT" format 990.0
col oncpuinhardparseX heading "CPU HARD|PARSING PCT" format 990.0
col waitinginparseX heading "WAITING|PARSING PCT" format 990.0
col waitinginhardparseX heading "WAITING HARD|PARSING PCT" format 990.0
--
-- Summary with CPU parsing details
--
select totAS,
       100*oncpu/(oncpu+waiting) cpuPct,
       100*waiting/(oncpu+waiting) waitingPct,
       100*(userIO+sysIO)/waiting ioPct,
       100*(waiting-userIO-sysIO)/waiting otherPct,
       100*oncpuinparse/oncpu oncpuinparseX,
       100*oncpuinhardparse/oncpu oncpuinhardparseX,
       100*waitinginparse/waiting waitinginparseX,
       100*waitinginhardparse/waiting waitinginhardparseX
from
(
  select 
    count(*) totAS,
    sum(decode(session_state,'ON CPU',1,0)) oncpu,
    sum(decode(session_state,'WAITING',1,0)) waiting,
    sum(decode(session_state,'WAITING',decode(wait_class,'User I/O',1,0))) userIO,
    sum(decode(session_state,'WAITING',decode(wait_class,'System I/O',1,0))) sysIO,
    sum(decode(session_state,'ON CPU',decode(in_parse,'Y',1,0))) oncpuinparse,
    sum(decode(session_state,'ON CPU',decode(in_hard_parse,'Y',1,0))) oncpuinhardparse,
    sum(decode(session_state,'WAITING',decode(in_parse,'Y',1,0))) waitinginparse,
    sum(decode(session_state,'WAITING',decode(in_hard_parse,'Y',1,0))) waitinginhardparse
  from   &datasource
  where  &timingdetails
         &dbahistdetails
    and  &ashcolkey1 like '&ashcolval1%'
    and  &ashcolkey2 like '&ashcolval2%'
)
/
--
-- WAIT Details
--
select count(*), event
from   &datasource
where  &timingdetails
       &dbahistdetails
  and  session_state = 'WAITING'
  and  &ashcolkey1 like '&ashcolval1%'
  and  &ashcolkey2 like '&ashcolval2%'
group by event
order by 1 desc
/


-----------------------------------------------------------------------
--- TICK REPORT : Inteval Timeline Report
-----------------------------------------------------------------------

set pagesize 100

def group_sec=10

col trunc_group_seconds noprint
col cpu_pct format 999.0
col wait_pct format 999.0
col event format a45
col min_sample_dt format a20
col tas format 9990.0
col aas format 9990.0

select	a.trunc_group_seconds, a.min_sample_dt, a.min_sample_id, a.TAS, a.AAS,
	100*a.cpu_count/(a.cpu_count+a.wait_count) cpu_pct, 100*a.wait_count/(a.cpu_count+a.wait_count) wait_pct,
	b.event
from	(
	select	trunc_group_seconds, min(sample_dt) min_sample_dt, min(sample_id) min_sample_id, 
		count(*) TAS,
		count(distinct(sample_id)) tot_sample_ids,
		round(count(*)/count(distinct(sample_id)),1) AAS,
		sum(decode(session_state,'ON CPU',1,0)) cpu_count,
		sum(decode(session_state,'WAITING',1,0)) wait_count
	from	(
		select	to_char(sample_time,'YYYY-Mon-DD HH24:MI:SS') sample_dt,
			to_char(sample_time,'DDD')*24*60*60+to_char(sample_time,'SSSSS') sample_time_in_seconds,
			trunc(to_char(sample_time,'DDD')*24*60*60+to_char(sample_time,'SSSSS')/&group_sec) trunc_group_seconds,
			sample_id,
			session_id,
			session_state
		from	&datasource
		where	&timingdetails
			&dbahistdetails
		--where rownum < 200
		order by 1
		)
	group by trunc_group_seconds 
	) a,
	(
	select	trunc_group_seconds, event
	from	(
		select	trunc_group_seconds, event,
			rank() over (partition by trunc_group_seconds order by cnt desc) the_rank
		from	(
			select	trunc(to_char(sample_time,'DDD')*24*60*60+to_char(sample_time,'SSSSS')/&group_sec) trunc_group_seconds,
				event,
				count(*) cnt
			from	&datasource
			where	&timingdetails
				&dbahistdetails
			  and	session_state = 'WAITING'
			group by trunc(to_char(sample_time,'DDD')*24*60*60+to_char(sample_time,'SSSSS')/&group_sec),
				 event
			)
		)
	where	the_rank = 1
	--order by 1
	) b
where a.trunc_group_seconds = b.trunc_group_seconds
order by a.min_sample_id
/


-----------------------------------------------------------------------
--- SQL Statement Run Time Inference Report
-----------------------------------------------------------------------

-- This script is used to find the run time for a specific sql_id or
-- the top run time SQL. AND, the output can be for people or comma
-- deliminted (for data analysis).
--
-- There are also options related to the format of the sample_date 
-- column (date, timestamp)

-- START by determining which date format is appropriate,
-- by looking at the script output.
-- Then, set the runtime_sec_[ts|dt] columns to the appropriate print or noprint value
-- Then, set the order_by to reflect the selected date format.
--
-- ts column: print when sample_date is a date, else noprint
-- dt column: print when sample_date is a timestamp, else noprint
-- not sure? then set print for both
col runtime_sec_ts noprint  
col runtime_sec_dt print
--end


-- comma delimited output for statistical and machine learning analysis
set pagesize 0
set heading off
set verify off
col start_date_time noprint
col sql_exec_id noprint
col sql_plan_hash_value noprint
col sql_id noprint
col mydelim print
def mydelim=','
--end


-- to find the longest running SQL
col sql_id print
def sql_id   = '%'
def where    = 'and sql_exec_id > 0' -- kernel SQL may have exec_id blank
--def where  = 'and 1=1'
--end


-- to find run times for a given SQL
col sql_id noprint
def where      = 'and 1=1' 
def sql_id     = '4b3rdu4yh4ztc'
--end


-- standard column display
-- begin
set pagesize 60
set heading on
set verify on
col sort_dt noprint
col start_date_time print
col sql_exec_id print
col sql_plan_hash_value print
col runtime_sec_dt_v1 noprint
col min_sample_time   noprint
col max_sample_time   noprint
col mydelim noprint
def mydelim=''
--end


def order_by = 'runtime_sec_ts desc'
def order_by = 'runtime_sec_dt desc'  -- probably what you want

col start_date_time format a20
col runtime_sec_dt format 9999990
col runtime_sec_ts format 9999990

-- To compare the runtime strategies, set the below to print, not noprint
col runtime_sec_dt_v1 noprint
col min_sample_time   noprint
col max_sample_time   noprint

select * from (
select  min_sample_time, max_sample_time,
        sql_id, start_date_time, sql_exec_id,
		sql_plan_hash_value,
        abs(extract( day from runtime_ts ))*24*60 +
        abs(extract( hour from runtime_ts ))*60 +
        abs(extract( minute from runtime_ts ))*60 +
        abs(extract( second from runtime_ts )) runtime_sec_ts,
		runtime_dt*24*60*60 runtime_sec_dt,
		runtime_dt_v1*24*60*60 runtime_sec_dt_v1,
		'&mydelim' mydelim
from (
   select  
           to_char(max(sample_time), 'YYYY-Mon-DD HH24:MI:SS') max_sample_time,
           to_char(min(sample_time), 'YYYY-Mon-DD HH24:MI:SS') min_sample_time,
		   max(sample_time)-min(sample_time) runtime_dt_v1,
		   max(sample_time)-min(sql_exec_start) runtime_dt,
		   max(to_timestamp(sample_time))-min(to_timestamp(sample_time)) runtime_ts_v1,
		   max(to_timestamp(sample_time))-min(to_timestamp(sql_exec_start)) runtime_ts,
           to_char(nvl(SQL_EXEC_START,to_date('1990','YYYY')),'YYYYMMDDHH24MISS') sort_dt,
           to_char(nvl(SQL_EXEC_START,to_date('1990','YYYY')),'YYYY-Mon-DD HH24:MI:SS') start_date_time,
           sql_exec_id,
		   sql_plan_hash_value,
		   sql_id
    from   &datasource
	where  &timingdetails
		   &dbahistdetails
		   &where
      and  sql_id like '&sql_id%'
    group by 
           to_char(nvl(SQL_EXEC_START,to_date('1990','YYYY')),'YYYYMMDDHH24MISS')  ,
           to_char(nvl(SQL_EXEC_START,to_date('1990','YYYY')),'YYYY-Mon-DD HH24:MI:SS')  ,
           sql_exec_id,
		   sql_plan_hash_value,
		   sql_id
	order by runtime_dt desc
)
order by &order_by
)
where rownum < 200
/



--END

