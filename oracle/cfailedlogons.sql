set linesize 250 
set pagesize 70
set echo off
set feedback on

col dbusername format a20
col os_username format a20
col userhost format a15
col client_program_name format a35
col action_name format a11
col return_code_desc format a66


prompt ;
prompt ;
prompt --------------------------------------------;
prompt --// Latest 50 Failed Logons            //--;
prompt --------------------------------------------;
prompt ;

select   to_char(event_timestamp,'YYYY-MM-DD HH24:MI:SS') event_timestamp
       , dbusername
       , os_username
       , userhost
       , client_program_name
       , case return_code when 1005  then 'ORA-01005: Null password given'
                          when 1017  then 'ORA-01017: Invalid Username/Password'
                          when 28000 then 'ORA-28000: The accont is locked'
                          when 28001 then 'ORA-28001: expired password'
                          when 28003 then 'ORA-28003: password verification for the specified password failed'
                          when 28007 then 'ORA-28007: The password cannot be reused'
                          else to_char(return_code)
         end return_code_desc
from     unified_audit_trail
where    unified_audit_policies='ORA_LOGON_FAILURES'
         and event_timestamp > systimestamp - numtodsinterval(30,'day')
order by event_timestamp desc
fetch next 50 rows only
/



prompt ;
prompt --------------------------------------------;
prompt --// Grouped Results from Past 24 Hours //--;
prompt --------------------------------------------;
prompt ;

select   to_char(min(event_timestamp),'YYYY-MM-DD HH24:MI:SS') first
       , to_char(max(event_timestamp),'YYYY-MM-DD HH24:MI:SS') last
       , count(*) qty
       , dbusername
       , os_username
       , userhost
       , client_program_name
       , case return_code when 1005  then 'ORA-01005: Null password given'
                          when 1017  then 'ORA-01017: Invalid Username/Password'
                          when 28000 then 'ORA-28000: The accont is locked'
                          when 28001 then 'ORA-28001: expired password'
                          when 28003 then 'ORA-28003: password verification for the specified password failed'
                          when 28007 then 'ORA-28007: The password cannot be reused'
                          else to_char(return_code)
         end return_code_desc
from     unified_audit_trail
where    unified_audit_policies='ORA_LOGON_FAILURES'
         and event_timestamp > systimestamp - numtodsinterval(24,'hour')
         -- and dbusername='JDECNC'
group by dbusername
       , os_username
       , userhost
       , client_program_name
       , action_name
       , return_code
order by last desc
/