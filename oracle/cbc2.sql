set echo off
set linesize 500
set pagesize 100
set feedback on
set termout off
set define "&"

column machine format a20
column username format a20
column osuser format a20
column program format a50
column wait_class format a20
column event format a40
column waiting format a9
column wait format a45



/*===========================*/
/*== SET UP                ==*/
/*===========================*/

/* drop the tables if you get errors from column differences 
drop table ca.blocking_chain;
drop table ca.sessions_snapshot;
*/

/* create the work tables if they do not exist */
DECLARE
	l_qty   number;
	l_stmt  varchar2(500);
BEGIN
	/* check if table ca.blocking_chain exists with the latest update (column process) */
	select count(1) into l_qty
	from   dba_tab_columns
	where  owner='CA'
	       and table_name='BLOCKING_CHAIN'
	       and column_name='PROCESS';

	/* create the table if it does not exist */
	IF l_qty=0 THEN
		execute immediate 'drop table ca.blocking_chain';
		l_stmt := 'create table ca.blocking_chain (order_id number, level_id number, blocking_sid number, sid number, serial# number, machine varchar2(64), process varchar2(24), username varchar2(128), server varchar2(9), osuser varchar2(128), program varchar2(48), status varchar2(8), wait_class varchar2(64), event varchar2(64), seconds_in_wait number, sql_id varchar2(13))';
		execute immediate l_stmt;
	END IF;

	/* check if table ca.sessions_snapshot exists */
	select count(1) into l_qty
	from   dba_tab_columns
	where  owner='CA'
	       and table_name='SESSIONS_SNAPSHOT'
	       and column_name='PROCESS';

	/* create the table if it does not exist */
	IF l_qty=0 THEN
		execute immediate 'drop table ca.sessions_snapshot';
		l_stmt := 'create table ca.sessions_snapshot (blocking_sid number, sid number, serial# number, machine varchar2(64), process varchar2(24), username varchar2(128), server varchar2(9), osuser varchar2(128), program varchar2(48), status varchar2(8), wait_class varchar2(64), event varchar2(64), seconds_in_wait number, sql_id varchar2(13))';
		execute immediate l_stmt;
	END IF;
END;
/





/*===========================*/
/*== DO THE WORK           ==*/
/*===========================*/

DECLARE
	l_order_id number := 1;
	l_level_id number := 0;
	l_blocking_sid number;
	l_qty   number;
	l_sid   number;
	l_stmt  varchar2(500);
BEGIN
	/* load the sessions */
	l_stmt := 'truncate table ca.blocking_chain';
	execute immediate l_stmt;
	l_stmt := 'truncate table ca.sessions_snapshot';
	execute immediate l_stmt;
	insert into ca.sessions_snapshot (
	             blocking_sid,   sid,   serial#,   machine, process,   username,   server,   osuser,   program,   status,   wait_class,   event,   seconds_in_wait,   sql_id)
	select s.blocking_session, s.sid, s.serial#, s.machine, s.process, s.username, s.server, s.osuser, s.program, s.status, s.wait_class, s.event, s.seconds_in_wait, s.sql_id
	from   v$session s;

	/* loop through the lead blockers */
	FOR x IN (  select   distinct blocker.sid
	            from     ca.sessions_snapshot blocked
	            join     ca.sessions_snapshot blocker on blocker.sid=blocked.blocking_sid
	            where    blocker.blocking_sid is null
	            order by blocker.sid
	         )
	LOOP
		/* insert the lead blocker */
		insert into ca.blocking_chain (order_id, level_id, blocking_sid, sid, serial#, machine, process, username, server, osuser, program, status, wait_class, event, seconds_in_wait, sql_id)
		select l_order_id, l_level_id, blocking_sid, sid, serial#, machine, process, username, server, osuser, program, status, wait_class, event, seconds_in_wait, sql_id
		from   ca.sessions_snapshot
		where  sid=x.sid;
		l_order_id := l_order_id + 1;
		l_level_id := 1;

		/* drill down and up the blocking levels under this lead blocker */
		WHILE l_level_id>0
		LOOP
			/* grab the blocking sid one level up */
			select sid into l_blocking_sid
			from   ca.blocking_chain
			where  order_id = (select max(b.order_id) from ca.blocking_chain b where b.level_id=l_level_id-1);

			/* check how many sessions are blocked by it that we have not yet logged */
			select count(1) into l_qty
			from   ca.sessions_snapshot
			where  blocking_sid=l_blocking_sid
			       and sid not in (select sid from ca.blocking_chain);

			IF (l_qty>0) THEN
				/* get the next session blocked by it that we have not yet logged */
				select   sid into l_sid
				from     ca.sessions_snapshot
				where    blocking_sid=l_blocking_sid
				         and sid not in (select sid from ca.blocking_chain)
				order by sid
				fetch next 1 rows only;

				/* insert the session into our blocking chain results table */
				insert into ca.blocking_chain (order_id, level_id, blocking_sid, sid, serial#, machine, process, username, server, osuser, program, status, wait_class, event, seconds_in_wait, sql_id)
				select l_order_id, l_level_id, blocking_sid, sid, serial#, machine, process, username, server, osuser, program, status, wait_class, event, seconds_in_wait, sql_id
				from   ca.sessions_snapshot
				where  sid=l_sid;
				/* always increment the order_id value so we keep the blocking chain results organized */
				l_order_id := l_order_id + 1;
				/* increment the level so we look next for sessions blocked by this session...keeping the blocking chain results in order_id */
				l_level_id := l_level_id + 1;
			ELSE
				/* no more session blocked from this blocking session, so go up a level and check for more there */
				l_level_id := l_level_id - 1;
			END IF;
		END LOOP;
	END LOOP;

	commit;
END;
/





/*===========================*/
/*== DISPLAY THE RESULTS   ==*/
/*===========================*/

/* dynamically set the sqlplus column format width for sid */
column sid_col_format new_value _SID_COL_FORMAT noprint;
select	case
		when max(level_id) is null then 'a10'
		else 'a'||to_char(max(level_id)*4+7)
	end sid_col_format from ca.blocking_chain;
column sid format &&_SID_COL_FORMAT

column "MACHINE:CLIENT_PROCESS_ID" format a40

set termout on

prompt ;
prompt There is a database session from JDE that has been idle for about N hours.;
prompt It has an open transaction that is blocking N other database sessions from JDE.;
prompt ;

select	  rpad('.',4*level_id,'.')||to_char(sid) sid
	-- , blocking_sid
	-- , serial#
	, username
	-- , osuser
	-- , substr(machine,1,20) machine
	-- , process client_process_id
	, machine||':'||process "MACHINE:CLIENT_PROCESS_ID"
	-- , program
	-- , status
	, wait_class||' - '||event wait
	-- , event
	, case 
		when seconds_in_wait is null then null
		when seconds_in_wait>3600 then to_char(round(seconds_in_wait/60/60,1))||' hrs'
		when seconds_in_wait>60 then to_char(round(seconds_in_wait/60,1))||' min'
		else to_char(seconds_in_wait)||' sec'
	  end waiting
	-- , sql_id
	-- , server
	, 'alter system kill session '''||to_char(sid)||','||serial#||''';' kill_cmd
from     ca.blocking_chain
order by order_id;


prompt ;
prompt ;
prompt ;
prompt Lead blocking session details;
prompt --------------------------------------------------------------;
prompt ;



/*===========================*/
/*== CLEAN UP              ==*/
/*===========================*/

undefine _SID_COL_FORMAT
column sid format 99999999999