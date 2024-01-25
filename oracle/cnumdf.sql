set serveroutput on
set feedback off

declare
	l_db_files number;
	l_datafiles number;
	l_tempfiles number;
begin
	select to_number(value) into l_db_files from v$parameter where name='db_files';
	select count(*) into l_datafiles from dba_data_files;
	select count(*) into l_tempfiles from dba_temp_files;

	dbms_output.put_line(chr(10));
	dbms_output.put_line('db_files : '||to_char(l_db_files));
	dbms_output.put_line('files    : '||to_char(l_tempfiles+l_datafiles)||' ('||to_char(l_datafiles)||' datafiles, '||to_char(l_tempfiles)||' tempfiles)');
	dbms_output.put_line('available: '||to_char(l_db_files-l_tempfiles-l_datafiles));
	dbms_output.put_line('percent  : '||to_char(round((l_datafiles+l_tempfiles)/l_db_files*100,0))||'%');
	dbms_output.put_line(chr(10));
end;
/


set feedback on