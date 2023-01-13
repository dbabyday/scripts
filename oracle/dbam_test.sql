set echo off
set feedback off
set linesize 500
set pagesize 100
set verify off
set serveroutput on format wrapped

col sid new_value _SID noprint;

select sys_context('userenv','sid') sid from dual;

DECLARE
	l_qty             number;
	l_sid             number;
	l_serial          number;
	l_spid            varchar2(24);
	l_username        varchar2(128);
	l_osuser          varchar2(128);
	l_program         varchar2(48);
	l_machine         varchar2(64);
	l_status          varchar2(8);
	l_used_ublk       number;
	l_used_urec       number;
	l_logon_time      varchar2(19);
	l_tran_start_time varchar2(19);
	l_wait_class      varchar2(64);
	l_event           varchar2(64);
	l_wait_time       varchar2(20);
	l_command_name    varchar2(64);
	l_sql_id          varchar2(13);
BEGIN
	select count(1) into l_qty
	from   v$session
	where  sid=&&_SID;

	IF l_qty=0 THEN
		dbms_output.put_line('There is no session connected with SID '||to_char(&&_SID));
	ELSE
		select    s.sid
		        , s.serial#
		        , p.spid
		        , s.username
		        , s.osuser
		        , s.program
		        , s.machine
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
		into      l_sid
		        , l_serial
		        , l_spid
		        , l_username
		        , l_osuser
		        , l_program
		        , l_machine
		        , l_status
		        , l_used_ublk
		        , l_used_urec
		        , l_logon_time
		        , l_tran_start_time
		        , l_wait_class
		        , l_event
		        , l_wait_time
		        , l_command_name
		        , l_sql_id
		from      v$session s
		left join v$process p     on p.addr = s.paddr
		left join v$sqlcommand c  on c.command_type = s.command
		left join v$transaction t on t.ses_addr = s.saddr
		where     s.sid=&&_SID;

		dbms_output.put_line('This Session');
		dbms_output.put_line('-----------------------------------------------');
		dbms_output.put_line('SID:             '||to_char(l_sid));
		dbms_output.put_line('SERIAL#:         '||to_char(l_serial));
		dbms_output.put_line('SPID:            '||l_spid);
		dbms_output.put_line('USERNAME:        '||l_username);
		dbms_output.put_line('OSUSER:          '||l_osuser);
		dbms_output.put_line('PROGRAM:         '||l_program);
		dbms_output.put_line('MACHINE:         '||l_machine);
		dbms_output.put_line('-----------------------------------------------');
		dbms_output.put_line(chr(10)||chr(10));
	END IF;
END;
/

undefine _SID

set echo on feedback on

exec dbms_output.put_line(chr(10)||'START: '||to_char(sysdate,'YYYY-MM-DD HH24:MI:SS')||chr(10));
UPDATE PRODDTA.F0101 SET ABDC = 'BARRYGAYHART-REMOTE' WHERE ABUSER = 'BBD3' /*INC925914*/;
COMMIT;
UPDATE PRODDTA.F0101 SET ABDC = 'BARRYGAYHART' WHERE ABUSER = 'BBD3' /*INC925914*/;
COMMIT;
exec dbms_output.put_line(chr(10)||'END: '||to_char(sysdate,'YYYY-MM-DD HH24:MI:SS')||chr(10));