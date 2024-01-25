
set feedback off define "&"
prompt substitution variable 1 = USERNAME;
column my_username new_value _USERNAME noprint;
select '&1' my_username from dual;
set feedback on

col dbusername format a20
col os_username format a20
col userhost format a15
col client_program_name format a35
col action_name format a11
col return_code_desc format a66


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
         and dbusername='&&_USERNAME'
order by event_timestamp desc;

undefine 1
undefine _USERNAME