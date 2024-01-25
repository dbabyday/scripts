/*

-- Get list of tuning task present in database
SELECT TASK_NAME, STATUS FROM DBA_ADVISOR_LOG WHERE TASK_NAME like 'JamesTuningTask%';
SELECT TASK_NAME, STATUS FROM DBA_ADVISOR_LOG WHERE lower(TASK_NAME) like '%tuning%';


*/

set serveroutput on
set echo off
set feedback off
set linesize 500
set pagesize 0
set trimout off
set trimspool off
set verify off
set define on
set long 65536
set longchunksize 65536

execute dbms_output.put_line('Substitution variable 1 = sql_id');
column my_sqlid new_value _SQLID noprint;
select '&1' my_sqlid from dual;

DECLARE
	l_qty               number(38);
	l_sql_tune_task_id  varchar2(100);
BEGIN
	-- check if the sql_id exists
	select count(1) into l_qty
	from   v$sql
	where  sql_id='&&_SQLID';

	-- if not, let's get out of here
	IF l_qty=0 THEN
		dbms_output.put_line('WARNING: sql_id &&_SQLID does not exist in v$sql...exiting.');
		return;
	END IF;

	-- create tuning task
	l_sql_tune_task_id := dbms_sqltune.create_tuning_task (
	                        sql_id      => '&&_SQLID',
	                        scope       => dbms_sqltune.scope_comprehensive,
	                        time_limit  => 500,
	                        task_name   => 'JamesTuningTask_&&_SQLID',
	                        description => 'Tuning task1 for statement &&_SQLID');
	dbms_output.put_line('l_sql_tune_task_id: ' || l_sql_tune_task_id);

	-- execute the tuning advisor
	dbms_sqltune.execute_tuning_task(task_name => 'JamesTuningTask_&&_SQLID');
END;
/

-- display the report
select dbms_sqltune.report_tuning_task('JamesTuningTask_&&_SQLID') line from dual;

-- do not drop the tuning task, so we can accept a sql profile
-- however, print the command to manually drop the tuning task after we are done
execute dbms_output.put_line(chr(10));
execute dbms_output.put_line('-- The tuning task still exists, so you have the option to accept a recommended SQL profile');
execute dbms_output.put_line('-- Use the following command to drop the tuning task when you are done');
execute dbms_output.put_line('execute dbms_sqltune.drop_tuning_task(''JamesTuningTask_&&_SQLID'');');
execute dbms_output.put_line(chr(10));

undefine 1
undefine _SQLID

set feedback on


set linesize 300
set pagesize 70

-- WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

-- set serveroutput on
-- set echo off
-- set feedback off
-- set lines 500
-- set pages 50000
-- set trimout on
-- set trimspool on
-- set verify off
-- set define on
-- set long 65536
-- set longchunksize 65536
-- set linesize 200

-- undefine sql_id;


-- -- 1. Create Tuning Task
-- DECLARE
--   l_sql_tune_task_id  VARCHAR2(100);
-- BEGIN
--   l_sql_tune_task_id := DBMS_SQLTUNE.create_tuning_task (
--                           sql_id      => '&&_SQLID',
--                           scope       => DBMS_SQLTUNE.scope_comprehensive,
--                           time_limit  => 500,
--                           task_name   => 'JamesTuningTask_&&_SQLID',
--                           description => 'Tuning task1 for statement &&_SQLID');
--   DBMS_OUTPUT.put_line('l_sql_tune_task_id: ' || l_sql_tune_task_id);
-- END;
-- /


-- -- 2. Execute Tuning task
-- EXEC DBMS_SQLTUNE.execute_tuning_task(task_name => 'JamesTuningTask_&&_SQLID');


-- -- 3. Get the Tuning advisor report
-- select dbms_sqltune.report_tuning_task('JamesTuningTask_&&_SQLID') from dual;


-- -- 4. Drop the tuning task
-- execute dbms_sqltune.drop_tuning_task('JamesTuningTask_&&_SQLID');


-- undefine sql_id;