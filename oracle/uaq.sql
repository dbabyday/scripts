set lines 300

col dbusername for a15
col client_program_name for a30
col os_username for a20
col userhost for a20
col event_timestamp for a20
col object_name for a20
col object_schema for a20
col action_name for a20
col sql_text for a100

select
	  to_char(event_timestamp,'YYYY-MM-DD HH24:MI:SS') event_timestamp
	, os_username
	, userhost
	, client_program_name
	, dbusername
	, object_schema
	, object_name
	, action_name
	, sql_text
	-- , terminal
	-- , sessionid
	-- , statement_id
	-- , scn
from
	unified_audit_trail
where
	-- event_timestamp>sysdate-(1/24)
	event_timestamp>=to_timestamp('2023-01-31 00:00:00','YYYY-MM-DD HH24:MI:SS')
	-- and event_timestamp<to_timestamp('2022-11-29 23:59:59','YYYY-MM-DD HH24:MI:SS')
	and object_schema='PRODDTA'
	and object_name='F5547082'
order by
	event_timestamp;
