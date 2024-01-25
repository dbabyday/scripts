set echo off
set feedback on
set verify off
set serveroutput on format wrapped
set define "&"

set feedback off
prompt substitution variable 1 = ID
column my_id new_value _ID noprint;
select &1 my_id from dual;
set feedback on

DECLARE
	l_arctime date;
	qty       number;
BEGIN
	select count(1) into qty from ca.arc_times where id=&&_ID;
	IF qty=0 THEN
		dbms_output.put_line('ERROR: That ID does not exist. Run this query to find the available IDs:');
		dbms_output.put_line('       select id, archive_time from ca.arc_times order by archive_time;');
	ELSE
		select archive_time into l_arctime from ca.arc_times where id=&&_ID;
		dbms_output.put_line('Purging archived privilege records for ID: '||to_char(&&_ID)||', Time: '||to_char(l_arctime,'YYYY-MM-DD HH24:MI:SS'));

		dbms_output.put_line('...deleting from ca.arc_col_privs');
		delete from ca.arc_col_privs where arc_times_id=&&_ID;

		dbms_output.put_line('...deleting from ca.arc_roles');
		delete from ca.arc_roles where arc_times_id=&&_ID;

		dbms_output.put_line('...deleting from ca.arc_role_privs');
		delete from ca.arc_role_privs where arc_times_id=&&_ID;

		dbms_output.put_line('...deleting from ca.arc_sys_privs');
		delete from ca.arc_sys_privs where arc_times_id=&&_ID;

		dbms_output.put_line('...deleting from ca.arc_tab_privs');
		delete from ca.arc_tab_privs where arc_times_id=&&_ID;

		dbms_output.put_line('...deleting from ca.arc_ts_quotas');
		delete from ca.arc_ts_quotas where arc_times_id=&&_ID;

		dbms_output.put_line('...deleting from ca.arc_users');
		delete from ca.arc_users where arc_times_id=&&_ID;

		dbms_output.put_line('...deleting from ca.arc_times');
		delete from ca.arc_times where id=&&_ID;
	END IF;
END;
/

undefine 1
undefine _ID
