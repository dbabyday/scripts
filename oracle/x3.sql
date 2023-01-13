set echo off
set feedback off
set pagesize 0
set linesize 32767
set trimout on
set trimspool on
set serveroutput on format wrapped

spool y.sql append

BEGIN
	dbms_output.put_line('END;');
	dbms_output.put_line('/');
END;
/

spool off
exit