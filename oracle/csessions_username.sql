set echo off
set verify off
set define "&"
set linesize 400
set serveroutput on format wrapped
set trimout on

prompt ;
prompt substitution variable 1 is for USERNAME
column myusername new_value _USERNAME noprint;
select '&1' myusername from dual;

column spid format a10
column machine format a37
column username format a20
column osuser format a20
column program format a30
column wait_class format a20
column event format a30
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
       , sql_id
from
       v$session s
left join
       v$transaction t on t.ses_addr = s.saddr
where
       s.username='&&_USERNAME'
order by
       s.seconds_in_wait;



undefine 1
undefine _USERNAME
