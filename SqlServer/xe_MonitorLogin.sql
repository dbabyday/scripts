/*
FIND AND REPLACE
	NA\james.lutsey.admin
	MonitorLogin_NAjameslutseyadmin


select s.name extended_event_session , case  when xes.name is not null then 'running' else 'stopped' end status from sys.server_event_sessions s left join sys.dm_xe_sessions xes on xes.name=s.name order by s.name;

ALTER EVENT SESSION MonitorLogin_NAjameslutseyadmin ON SERVER STATE = START;
select s.name extended_event_session , case  when xes.name is not null then 'running' else 'stopped' end status from sys.server_event_sessions s left join sys.dm_xe_sessions xes on xes.name=s.name order by s.name;

ALTER EVENT SESSION MonitorLogin_NAjameslutseyadmin ON SERVER STATE = STOP;
DROP EVENT SESSION MonitorLogin_NAjameslutseyadmin ON SERVER;
select s.name extended_event_session , case  when xes.name is not null then 'running' else 'stopped' end status from sys.server_event_sessions s left join sys.dm_xe_sessions xes on xes.name=s.name order by s.name;


*/

USE master;




IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'MonitorLogin_NAjameslutseyadmin')
	DROP EVENT SESSION MonitorLogin_NAjameslutseyadmin ON SERVER;

CREATE EVENT SESSION MonitorLogin_NAjameslutseyadmin ON SERVER 
	  /* statements starting */
	  ADD EVENT sqlserver.sp_statement_starting (
		ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.session_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.username)
		WHERE (sqlserver.username=N'NA\james.lutsey.admin')
	  )
	, ADD EVENT sqlserver.sql_statement_starting (
		ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.session_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.username)
		WHERE (sqlserver.username=N'NA\james.lutsey.admin')
	  )
	, ADD EVENT sqlserver.module_start (
		SET collect_statement = (1)
		ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.session_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.username)
		WHERE (sqlserver.username=N'NA\james.lutsey.admin')
	  )
	, ADD EVENT sqlserver.rpc_starting (
		ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.session_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.username)
		WHERE (sqlserver.username=N'NA\james.lutsey.admin')
	  )
	 /* statements completed */
	, ADD EVENT sqlserver.sp_statement_completed (
		ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.session_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.username)
		WHERE (sqlserver.username=N'NA\james.lutsey.admin')
	  )
	, ADD EVENT sqlserver.sql_statement_completed (
		ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.session_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.username)
		WHERE (sqlserver.username=N'NA\james.lutsey.admin')
	  )
	, ADD EVENT sqlserver.module_end (
		SET collect_statement = (1)
		ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.session_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.username)
		WHERE (sqlserver.username=N'NA\james.lutsey.admin')
	  )
	, ADD EVENT sqlserver.rpc_completed (
		ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.session_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.username)
		WHERE (sqlserver.username=N'NA\james.lutsey.admin')
	  )


ADD TARGET package0.event_file(
	SET
		  filename = N'G:\ExtendedEvents\MonitorLogin_NAjameslutseyadmin'
		, max_file_size = 5
		, max_rollover_files = 2
)


WITH (
	  MAX_MEMORY = 2 MB
	, EVENT_RETENTION_MODE = ALLOW_MULTIPLE_EVENT_LOSS
	, MAX_DISPATCH_LATENCY = 30 SECONDS
	, MAX_EVENT_SIZE = 0 MB
	, MEMORY_PARTITION_MODE = NONE
	, TRACK_CAUSALITY = OFF
	, STARTUP_STATE = OFF
);


GO

