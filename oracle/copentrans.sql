COMPUTE SUM OF used_ublk ON REPORT
COMPUTE SUM OF used_urec ON REPORT
BREAK ON REPORT

column command_name    format a30
column event           format a30
column tran_start_time format a19
column username        format a20
column wait_class      format a20
column wait_time       format a17

select
	  s.sid
	, s.username
	, c.command_name
	, t.used_ublk
	, t.used_urec
	, case
		when t.start_time is not null  then '20'||substr(t.start_time,7,2)||'-'||substr(t.start_time,1,2)||'-'||substr(t.start_time,4,2)||' '||substr(t.start_time,10,8)
		else null
	  end  tran_start_time
	, s.status
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
	v$sqlcommand c  on c.command_type = s.command
join
	v$transaction t on t.ses_addr = s.saddr
order by
	s.seconds_in_wait desc
/

clear breaks;