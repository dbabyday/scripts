set linesize 200
set echo off
set feedback off
set serveroutput on
set trimout on
set trimspool on

column PGA_TARGET_FOR_ESTIMATE format 999999999999999


DECLARE
	db           varchar2(16) := '';
	hostname     varchar2(64) := '';
	timenow      varchar2(19) := '';
	pgalimit     number(10,3) := 0;
	pgatarget    number(10,3) := 0;
	pgaallocated number(10,3) := 0;
	pgainuse     number(10,3) := 0;
	notallocated number(10,3) := 0;
	notused      number(10,3) := 0;
BEGIN
	select instance_name, host_name, to_char(sysdate,'YYYY-MM-DD HH24:MI:SS')
	into   db,            hostname,  timenow
	from   v$instance;

	select value / 1024 / 1024 / 1024
	into   pgalimit
	from   v$parameter 
	where  name='pga_aggregate_limit';

	select value / 1024 / 1024 / 1024
	into   pgatarget
	from   v$parameter 
	where  name='pga_aggregate_target';

	select value / 1024 / 1024 / 1024
	into   pgaallocated
	from   v$pgastat 
	where  name='total PGA allocated';

	select value / 1024 / 1024 / 1024
	into   pgainuse
	from   v$pgastat 
	where  name='total PGA inuse';

	notallocated := (pgalimit - pgaallocated);
	notused := (pgalimit - pgainuse);

	dbms_output.put_line(chr(10));
	dbms_output.put_line('Database: '||db||' ('||hostname||')');
	dbms_output.put_line('Time:     '||timenow);
	dbms_output.put_line(chr(10));
	dbms_output.put_line('pga_aggregate_limit  = '||to_char(pgalimit)||' GB');
	dbms_output.put_line('pga_aggregate_target = '||to_char(pgatarget)||' GB');
	dbms_output.put_line('total PGA allocated  = '||to_char(pgaallocated)||' GB');
	dbms_output.put_line('total PGA inuse      = '||to_char(pgainuse)||' GB');
	dbms_output.put_line(chr(10));
	dbms_output.put_line('pga not allocated  = '||to_char(notallocated)||' GB');
	dbms_output.put_line('pga not used       = '||to_char(notused)||' GB');
	dbms_output.put_line(chr(10));
END;
/



column gb format 9999.9
column estd_time_factor format 999.999
column estd_time format 999,999,999,999,999

select   pga_target_for_estimate
       , pga_target_for_estimate/1024/1024/1024 gb
       , pga_target_factor
       , estd_time / (select estd_time from v$pga_target_advice where pga_target_factor=1) estd_time_factor
       , estd_time
from     v$pga_target_advice
order by pga_target_for_estimate;

