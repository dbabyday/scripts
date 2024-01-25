/*

https://github.com/dbabyday
Warranty: The software is provided "AS IS", without warranty of any kind

Name: cblp.sql
Description: See the Plan for SQL Plan Baselines

*/


set feedback off
prompt Substitution variable 1 = PLAN_NAME;
column my_plan_name new_value _PLAN_NAME noprint;
select '&1' my_plan_name from dual;
set feedback on

SELECT 
	  PLAN_TABLE_OUTPUT
FROM
	  DBA_SQL_PLAN_BASELINES b
	, TABLE (DBMS_XPLAN.DISPLAY_SQL_PLAN_BASELINE (b.sql_handle,b.plan_name,'basic')) t 
WHERE
	b.PLAN_NAME IN (
		  '&&_PLAN_NAME'
	);

undefine 1
undefine _PLAN_NAME