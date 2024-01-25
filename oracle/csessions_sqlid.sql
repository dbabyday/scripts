set linesize 32767
set pagesize 50

set feedback off define "&"
prompt Substitution variable 1 = sql_id;
column my_sql_id new_value _SQL_ID noprint;
select '&1' my_sql_id from dual;
set feedback on

column machine format a37
column username format a20
column osuser format a20
column program format a50
column wait_class format a20
column event format a40
column wait_time format a17


select 
	  s.blocking_session
	, s.sid
	, s.username
	, s.osuser
	, s.machine
	, s.logon_time
	, case 
		when t.start_time is not null  then '20'||substr(t.start_time,7,2)||'-'||substr(t.start_time,1,2)||'-'||substr(t.start_time,4,2)||' '||substr(t.start_time,10,8)
		else null
	  end  tran_start_time
	, s.wait_class
	, s.event
	, to_char(floor(s.seconds_in_wait/86400))||' days '||
	  lpad(to_char(floor((s.seconds_in_wait-floor(s.seconds_in_wait/86400)*86400)/3600)),2,'0')||':'||
	  lpad(to_char(floor((s.seconds_in_wait-floor(s.seconds_in_wait/86400)*86400-floor((s.seconds_in_wait-floor(s.seconds_in_wait/86400)*86400)/3600)*3600)/60)),2,'0')||':'||
	  lpad(to_char(s.seconds_in_wait-floor(s.seconds_in_wait/86400)*86400-floor((s.seconds_in_wait-floor(s.seconds_in_wait/86400)*86400)/3600)*3600-floor((s.seconds_in_wait-floor(s.seconds_in_wait/86400)*86400-floor((s.seconds_in_wait-floor(s.seconds_in_wait/86400)*86400)/3600)*3600)/60)*60),2,'0')
	  wait_time
from
	v$session s
left join
	v$transaction t on t.ses_addr = s.saddr
where
	sql_id='&&_SQL_ID'
order by
	  s.username
	, s.osuser
	, s.sid;



undefine 1
undefine _SQL_ID


-- column kill_session_cmd format a75

-- select 'ALTER SYSTEM KILL SESSION '''||to_char(sid)||','||to_char(serial#)||''' IMMEDIATE;' kill_session_cmd
-- from   v$session
-- where  username='CGNSCONTROL';

