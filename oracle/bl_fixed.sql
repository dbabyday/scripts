/*

https://github.com/dbabyday
Warranty: The software is provided "AS IS", without warranty of any kind

Name: bl_fixed.sql
Description: Set Sql Plan Baseline fixed=YES

*/


set feedback off
prompt Substitution variable 1 = _SQL_HANDLE;
prompt Substitution variable 2 = _SQL_PLAN;
column  my_sql_handle new_value _SQL_HANDLE noprint;
column my_sql_plan new_value _SQL_PLAN noprint;
select '&1' my_sql_handle, '&2' my_sql_plan from dual;
set feedback on


declare
	l_x pls_integer;
begin
	l_x := DBMS_SPM.ALTER_SQL_PLAN_BASELINE (
		sql_handle        => '&&_SQL_HANDLE',
		plan_name         => '&&_SQL_PLAN',
		attribute_name    => 'fixed',
		attribute_value   => 'YES'
	);
end;
/

undefine 1
undefine 2
undefine _SQL_HANDLE
undefine _SQL_PLAN