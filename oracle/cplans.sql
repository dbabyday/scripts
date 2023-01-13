set feedback off
set echo off
set serveroutput on

column get_plan format a75
column get_plan_hist format a75

exec dbms_output.put_line(chr(10));
exec dbms_output.put_line('Substitution variable 1 is for SQL_ID');
column mysqlid new_value _SQLID noprint;
select '&1' mysqlid from dual;


-- get the current plan for the sql_id
select   'select * from table(dbms_xplan.display_cursor(''&&_SQLID'','||to_char(min(child_number))||'));' get_current_plan
from     v$sql
where    sql_id='&&_SQLID'
group by plan_hash_value;

-- get the different execution plans associated with the sql_id
select 'select * from table(dbms_xplan.display_awr(''&&_SQLID''));' get_plan_hist
from   dual;

exec dbms_output.put_line(chr(10));

undefine 1
undefine _SQLID


set feedback on