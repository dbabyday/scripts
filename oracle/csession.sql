
set echo off
set linesize 500
set pagesize 100
set verify off
set serveroutput on format wrapped
set feedback off

prompt ;
prompt substitution variable 1 is for SID
column sid new_value _SID noprint;
select '&1' sid from dual;


DECLARE
	l_qty             number;
BEGIN
	select count(1) into l_qty
	from   v$session
	where  sid=&&_SID;

	IF l_qty=0 THEN
		dbms_output.put_line('There is no session connected with SID '||to_char(&&_SID));
	ELSE
		FOR x IN (
			select    s.sid
			        , s.serial#
			        , p.spid
			        , s.blocking_session
			        , s.username
			        , s.osuser
			        , s.program
			        , s.machine
			        , s.process
			        , s.status
			        , t.used_ublk
			        , t.used_urec
			        , to_char(s.logon_time,'YYYY-MM-DD HH24:MI:SS') logon_time
			        , case when t.start_time is not null  then '20'||substr(t.start_time,7,2)||'-'||substr(t.start_time,1,2)||'-'||substr(t.start_time,4,2)||' '||substr(t.start_time,10,8)
			               else null
			          end  tran_start_time
			        , s.wait_class
			        , s.event
			        , case when s.seconds_in_wait is null then null
			               when s.seconds_in_wait>3600 then to_char(round(s.seconds_in_wait/60/60,1))||' hrs'
			               when s.seconds_in_wait>60 then to_char(round(s.seconds_in_wait/60,1))||' min'
			               else to_char(s.seconds_in_wait)||' sec'
			          end wait_time
			        , c.command_name
			        , s.sql_id
			from      v$session s
			left join v$process p     on p.addr = s.paddr
			left join v$sqlcommand c  on c.command_type = s.command
			left join v$transaction t on t.ses_addr = s.saddr
			where     s.sid=&&_SID
		) LOOP
			dbms_output.put_line('--------------------------------------------------------------');
			dbms_output.put_line('SID                  : '||to_char(x.sid));
			dbms_output.put_line('SERIAL#              : '||to_char(x.serial#));
			dbms_output.put_line('SPID                 : '||x.spid);
			dbms_output.put_line('BLOCKING_SESSION     : '||to_char(x.blocking_session));
			dbms_output.put_line('USERNAME             : '||x.username);
			dbms_output.put_line('OSUSER               : '||x.osuser);
			dbms_output.put_line('PROGRAM              : '||x.program);
			dbms_output.put_line('MACHINE              : '||x.machine);
			dbms_output.put_line('CLIENT OS PROCESS ID : '||x.process);
			dbms_output.put_line('LOGON_TIME           : '||x.logon_time);
			dbms_output.put_line('TRAN_START_TIME      : '||x.tran_start_time);
			dbms_output.put_line('STATUS               : '||x.status);
			dbms_output.put_line('WAIT_CLASS           : '||x.wait_class);
			dbms_output.put_line('EVENT                : '||x.event);
			dbms_output.put_line('WAIT_TIME            : '||x.wait_time);
			dbms_output.put_line('COMMAND_NAME         : '||x.command_name);
			dbms_output.put_line('SQL_ID               : '||x.sql_id);
			dbms_output.put_line('USED_UBLK            : '||to_char(x.used_ublk));
			dbms_output.put_line('USED_UREC            : '||to_char(x.used_urec));
		END LOOP;
		dbms_output.put_line('--------------------------------------------------------------');
	END IF;
END;
/

undefine 1
undefine _SID
column sid format 9999999999 print

set feedback on