set linesize 32767
set pagesize 50

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
	sql_id in (
	  '0bmh3r2thdtzh'
	, '0jfbv51sfrbfy'
	, '0yfkztr51rh2c'
	, '1syv105pqqar9'
	, '2q9ag69sxh0jx'
	, '2q9ag69sxh0jx'
	, '2z8f3jncdyz2p'
	, '3wraft8072uhc'
	, '44r6maqt99wbp'
	, '73fvrr7chcvnw'
	, '8335ndm8rjfns'
	, '90rjz1jhb23jv'
	, '90rjz1jhb23jv'
	, 'b2cnca7v6c528'
	, 'bbn96wyyrbkgg'
	, 'bxfta5s0xpp4p'
	, 'cmgjymk3g15h5'
	)
order by
	  s.username
	, s.osuser
	, s.sid;




-- column kill_session_cmd format a75

-- select 'ALTER SYSTEM KILL SESSION '''||to_char(sid)||','||to_char(serial#)||''' IMMEDIATE;' kill_session_cmd
-- from   v$session
-- where  username='CGNSCONTROL';

