-- -- http://oraegy.blogspot.com/2012/11/how-to-increase-processes.html
-- 
-- 
-- How to increase PROCESSES initialization parameter:
-- 
-- 1.    Login as sysdba
--     sqlplus / as sysdba
-- 
-- 2. Check Current Setting of Parameters
--     sql> show parameter sessions
--     sql> show parameter processes
--     sql> show parameter transactions
-- 
-- 3.    If you are planning to increase "PROCESSES" parameter you should also plan to increase "sessions and "transactions" parameters
--     A basic formula for determining  these parameter values is as follows:
-- 
--         processes=x
--         sessions=x*1.1+5
--         transactions=sessions*1.1
-- 
-- 4.    These paramters can't be modified in memory. You have to modify the spfile only (scope=spfile) and bounce the instance.
--     sql> alter system set processes=500 scope=spfile;
--     sql> alter system set sessions=555 scope=spfile;
--     sql> alter system set transactions=610 scope=spfile;
--     sql> shutdown immediate
--     sql> startup


set echo off
set define on
set trimout on
set serveroutput on
set verify off


column resource_name format a15
column initial_allocation format a18
column limit_value format a11

select 
	  resource_name
	, current_utilization
	, max_utilization
	, initial_allocation
	, limit_value
from 
	v$resource_limit 
where 
	resource_name in ('processes','sessions','transactions')
order by
	resource_name;


column name format a15
column value format a15

select
	  name
	, value
from
	v$parameter
where
	name in ('processes','sessions','transactions')
order by
	name;

prompt ;

set feedback off
DECLARE
	num_processes    number(38) := &new_number_of_processes;
	num_sessions     number(38) := 0;
	num_transactions number(38) := 0;
BEGIN
    num_sessions     := num_processes * 1.1 + 5;
	num_transactions := num_sessions * 1.1;

    dbms_output.put_line(chr(10));
    dbms_output.put_line('-- printing commands for you to review/use');
	dbms_output.put_line('-------------------------------------------------------------------------');
	dbms_output.put_line('alter system set processes='||to_char(num_processes)||' scope=spfile;');
	dbms_output.put_line('alter system set sessions='||to_char(num_sessions)||' scope=spfile;');
	dbms_output.put_line('alter system set transactions='||to_char(num_transactions)||' scope=spfile;');
	dbms_output.put_line(chr(10));
END;
/

set feedback on

