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
set feedback off
set define on
set trimout on
set serveroutput on
set verify off

DECLARE
    cur_processes    varchar(10) := '';
    cur_sessions     varchar(10) := '';
    cur_transactions varchar(10) := '';

	num_processes    number(38) := &num_processes;
	num_sessions     number(38) := 0;
	num_transactions number(38) := 0;
BEGIN
	select value into cur_processes    from v$parameter where name='processes';
    select value into cur_sessions     from v$parameter where name='sessions';
    select value into cur_transactions from v$parameter where name='transactions';

    num_sessions     := num_processes * 1.1 + 5;
	num_transactions := num_sessions * 1.1;

	dbms_output.put_line(chr(10));
	dbms_output.put_line('-- current values');
    dbms_output.put_line('-------------------------------------------------------------------------');
    dbms_output.put_line('processes:    '||cur_processes);
    dbms_output.put_line('sessions:     '||cur_sessions);
    dbms_output.put_line('transactions: '||cur_transactions);
    dbms_output.put_line(chr(10));
    dbms_output.put_line('-- printing commands for you to review/use');
	dbms_output.put_line('-------------------------------------------------------------------------');
	dbms_output.put_line('alter system set processes='||to_char(num_processes)||' scope=spfile;');
	dbms_output.put_line('alter system set sessions='||to_char(num_sessions)||' scope=spfile;');
	dbms_output.put_line('alter system set transactions='||to_char(num_transactions)||' scope=spfile;');
	dbms_output.put_line(chr(10));
END;
/


