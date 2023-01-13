

/*


select
	  dbid
	, to_char(min(event_timestamp),'YYYY-MM-DD') first_day
	, to_char(max(event_timestamp),'YYYY-MM-DD') last_day
	, count(*)
from
	unified_audit_trail
group by
	dbid
order by
	2;





select
	  database_id
	, to_char(last_archive_ts,'YYYY-MM-DD HH24:MI:SS') last_archive_ts 
from
	dba_audit_mgmt_last_arch_ts
order by
	database_id;




DECLARE
	l_last_archive_ts timestamp := TO_TIMESTAMP('2021-02-01 00:00:00','YYYY-MM-DD HH24:MI:SS');
	l_dbid            number    := 954738332;
BEGIN
	DBMS_AUDIT_MGMT.SET_LAST_ARCHIVE_TIMESTAMP (
		  AUDIT_TRAIL_TYPE  => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED
		, LAST_ARCHIVE_TIME => l_last_archive_ts
		, DATABASE_ID       => l_dbid
	);
END;
/

create table ca.status_clean_audit_trail (
	  event_time  timestamp
	, database_id number
	, last_archive_time timestamp
	, description varchar2(100)
);

column event_time format a30
select 
	  to_char(event_time,'DD-MON-YYYY HH24:MI:SS.FF') event_time
	, database_id
	, to_char(last_archive_time,'YYYY-MM-DD') last_archive_time
	, description 
from
	ca.status_clean_audit_trail
order by
	  event_time;

*/


declare
	l_last_archive_time timestamp;
	l_qty number;
	l_stmt varchar2(4000);
begin
	-- check if our status table exists
	select count(*)
	into l_qty
	from dba_tables
	where owner='CA' and table_name='STATUS_CLEAN_AUDIT_TRAIL';

	-- if not, create it
	if l_qty=0 then
		l_stmt := l_stmt ||            'create table ca.status_clean_audit_trail (';
		l_stmt := l_stmt || chr(10) || '	  event_time  timestamp';
		l_stmt := l_stmt || chr(10) || '	, database_id number';
		l_stmt := l_stmt || chr(10) || '	, last_archive_time timestamp';
		l_stmt := l_stmt || chr(10) || '	, description varchar2(100)';
		l_stmt := l_stmt || chr(10) || ')';
	
		execute immediate l_stmt;
	end if;

	-- clear the status table
	delete from ca.status_clean_audit_trail;
	commit;

	insert into ca.status_clean_audit_trail (event_time, description)
	values (systimestamp,'begin');
	commit;

	select min(event_timestamp) + numtoyminterval(1,'month')
	into l_last_archive_time
	from unified_audit_trail;

	while l_last_archive_time < systimestamp - numtoyminterval(1,'month')
	loop
		for x in (
			select distinct dbid
			from   unified_audit_trail
			where  dbid <> 0
			       and dbid is not null
		)
		loop
			insert into ca.status_clean_audit_trail (event_time, database_id, last_archive_time, description)
			values (systimestamp, x.dbid, l_last_archive_time, 'setting last archive timestamp');
			commit;

			dbms_audit_mgmt.set_last_archive_timestamp (
				  audit_trail_type  => dbms_audit_mgmt.audit_trail_unified
				, last_archive_time => l_last_archive_time
				, database_id       => x.dbid
			);

			insert into ca.status_clean_audit_trail (event_time, database_id, last_archive_time, description)
			values (systimestamp, x.dbid, l_last_archive_time, 'starting dbms_audit_mgmt.clean_audit_trail');
			commit;

			dbms_audit_mgmt.clean_audit_trail (
				  audit_trail_type        => dbms_audit_mgmt.audit_trail_unified
				, use_last_arch_timestamp => true
				, database_id             => x.dbid
			);

			insert into ca.status_clean_audit_trail (event_time, database_id, last_archive_time, description)
			values (systimestamp, x.dbid, l_last_archive_time, 'finished dbms_audit_mgmt.clean_audit_trail');
			commit;
		end loop;

		l_last_archive_time := l_last_archive_time + numtoyminterval(1,'month');
	end loop;

	insert into ca.status_clean_audit_trail (event_time, description)
	values (systimestamp,'end');
	commit;
end;
/


select
	  dbid
	, to_char(min(event_timestamp),'YYYY-MM-DD') first_day
	, to_char(max(event_timestamp),'YYYY-MM-DD') last_day
	, count(*)
from
	unified_audit_trail
group by
	dbid
order by
	min(event_timestamp);
