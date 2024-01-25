set pages 50000
set lines 500
set serveroutput on
set feedback off
set echo off
set heading on
set timing off
set verify off

accept delay_seconds number prompt "Enter value for delay_seconds: "

col avg_elapsed_seconds format 999999999.999
col sample_seconds format 999999999.9
col sample_start format a25


DECLARE
	tblexists number(38)    := 0;
	now         varchar(19) := '';
BEGIN
	dbms_output.put_line(chr(10));
	select to_char(sysdate,'YYYY-MM-DD HH24:MI:SS') into now from dual;

	select count(1)
	into   tblexists
	from   sys.dba_tables
	where  owner='JLUTSEY'
	       and table_name='SQL_ELAPSED_TIMES_1';

	IF tblexists=0
	THEN
		execute immediate 'create table JLUTSEY.SQL_ELAPSED_TIMES_1 (sql_id varchar2(13), collection_time timestamp, executions number, elapsed_time number)';
		dbms_output.put_line(now||' - Created table JLUTSEY.SQL_ELAPSED_TIMES_1');
	ELSE
		execute immediate 'truncate table JLUTSEY.SQL_ELAPSED_TIMES_1';
		dbms_output.put_line(now||' - Truncated table JLUTSEY.SQL_ELAPSED_TIMES_1');
	END IF;

	select count(1)
	into   tblexists
	from   sys.dba_tables
	where  owner='JLUTSEY'
	       and table_name='SQL_ELAPSED_TIMES_2';

	IF tblexists=0
	THEN
		execute immediate 'create table JLUTSEY.SQL_ELAPSED_TIMES_2 (sql_id varchar2(13), collection_time timestamp, executions number, elapsed_time number)';
		dbms_output.put_line(now||' - Created table JLUTSEY.SQL_ELAPSED_TIMES_2');
	ELSE
		execute immediate 'truncate table JLUTSEY.SQL_ELAPSED_TIMES_2';
		dbms_output.put_line(now||' - Truncated table JLUTSEY.SQL_ELAPSED_TIMES_2');
	END IF;
END;
/

DECLARE
	now         varchar(19) := '';
BEGIN
	select to_char(sysdate,'YYYY-MM-DD HH24:MI:SS') into now from dual;

	insert into JLUTSEY.SQL_ELAPSED_TIMES_1 (sql_id, collection_time, executions, elapsed_time)
	select   sql_id
	       , systimestamp
	       , sum(executions)
	       , sum(elapsed_time)
	from     v$sql
	where    px_servers_executions=0
	         and upper(sql_text) like '%F4311%'
	         and upper(sql_text) not like '%V$SQL%'
	group by sql_id;
	dbms_output.put_line(now||' - Gathered initial values');
	commit;

	select to_char(sysdate,'YYYY-MM-DD HH24:MI:SS') into now from dual;
	dbms_output.put_line(now||' - Waiting for the specified delay of '||trim(&&delay_seconds)||' seconds...');
END;
/

execute dbms_lock.sleep(&&delay_seconds);

DECLARE
	now         varchar(19) := '';
BEGIN
	select to_char(sysdate,'YYYY-MM-DD HH24:MI:SS') into now from dual;

	insert into JLUTSEY.SQL_ELAPSED_TIMES_2 (sql_id, collection_time, executions, elapsed_time)
	select   sql_id
	       , systimestamp
	       , sum(executions)
	       , sum(elapsed_time)
	from     v$sql
	where    px_servers_executions=0
	         and upper(sql_text) like '%F4311%'
	         and upper(sql_text) not like '%V$SQL%'
	group by sql_id;
	dbms_output.put_line(now||' - Gathered final values');
	commit;
END;
/


select     b.sql_id
         , (b.elapsed_time - a.elapsed_time) / 1000000 / (b.executions - a.executions) avg_elapsed_seconds
         , b.executions - a.executions executions
         , extract(day from (b.collection_time-a.collection_time))*86400 + 
           extract(hour from (b.collection_time-a.collection_time))*3600 + 
           extract(minute from (b.collection_time-a.collection_time))*60 + 
           extract(second from (b.collection_time-a.collection_time)) sample_seconds
         , to_char(a.collection_time,'YYYY-MM-DD HH24:MI:SS') sample_start
         , to_char(b.collection_time,'YYYY-MM-DD HH24:MI:SS') sample_end
from       jlutsey.sql_elapsed_times_1 a
join       jlutsey.sql_elapsed_times_2 b on b.sql_id=a.sql_id
where      a.executions<b.executions
union all
select     b.sql_id
         , b.elapsed_time / 1000000 / b.executions avg_elapsed_seconds
         , b.executions executions
         , null sample_seconds
         , 'no new executions' sample_start
         , to_char(b.collection_time,'YYYY-MM-DD HH24:MI:SS') sample_end
from       jlutsey.sql_elapsed_times_1 a
right join jlutsey.sql_elapsed_times_2 b on b.sql_id=a.sql_id
where      (  a.sql_id is null
              or a.executions=b.executions
           )
           and b.executions<>0
union all
select     b.sql_id
         , b.elapsed_time / 1000000 / b.executions avg_elapsed_seconds
         , b.executions executions
         , null sample_seconds
         , 're-loaded during sample' sample_start
         , to_char(b.collection_time,'YYYY-MM-DD HH24:MI:SS') sample_end
from       jlutsey.sql_elapsed_times_1 a
right join jlutsey.sql_elapsed_times_2 b on b.sql_id=a.sql_id
where      (  a.sql_id is null
              or a.executions>b.executions
           )
           and b.executions<>0
union all  
select    sql_id
         , sum(elapsed_time) / 1000000 / sum(executions) avg_elapsed_seconds
         , sum(executions)
         , null sample_seconds
         , 'parallel executions' sample_start
         , to_char(sysdate,'YYYY-MM-DD HH24:MI:SS') sample_end
from       v$sql
where      px_servers_executions>0
	         and upper(sql_text) like '%F4311%'
           and upper(sql_text) not like '%V$SQL%'
group by   sql_id
order by   avg_elapsed_seconds;



undefine delay_seconds;
undefine sql_id;