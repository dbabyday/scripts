/*


WhatRunsThisQuery



select s.name extended_event_session , case when xes.name is not null then 'running' else 'stopped' end status from sys.server_event_sessions s left join sys.dm_xe_sessions xes on xes.name=s.name order by s.name;

ALTER EVENT SESSION WhatRunsThisQuery_0xA192445BEC2CEDF2 ON SERVER STATE = START;
select s.name extended_event_session , case when xes.name is not null then 'running' else 'stopped' end status from sys.server_event_sessions s left join sys.dm_xe_sessions xes on xes.name=s.name order by s.name;

ALTER EVENT SESSION WhatRunsThisQuery_0xA192445BEC2CEDF2 ON SERVER STATE = STOP;
DROP EVENT SESSION WhatRunsThisQuery_0xA192445BEC2CEDF2 ON SERVER;
select s.name extended_event_session , case when xes.name is not null then 'running' else 'stopped' end status from sys.server_event_sessions s left join sys.dm_xe_sessions xes on xes.name=s.name order by s.name;


-- Find and Replace: 0xA192445BEC2CEDF2
IF (SELECT CAST(0xA192445BEC2CEDF2 AS BIGINT)) > 0 SELECT CAST(0xA192445BEC2CEDF2 AS BIGINT);
ELSE SELECT CAST(0xA192445BEC2CEDF2 AS bigint) & 0x7FFFFFFFFFFFFFFF + 9223372036854775808;

-- Find and Replace: 11642443148301233650
11642443148301233650

*/

USE master;

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'WhatRunsThisQuery_0xA192445BEC2CEDF2')
	DROP EVENT SESSION WhatRunsThisQuery ON SERVER;

CREATE EVENT SESSION WhatRunsThisQuery_0xA192445BEC2CEDF2
ON SERVER
	ADD EVENT sqlserver.sp_statement_completed (
		ACTION (
			  package0.event_sequence
			, sqlserver.client_app_name
			, sqlserver.client_hostname
			, sqlserver.database_name
			, sqlserver.query_hash
			, sqlserver.session_id
			, sqlserver.session_server_principal_name
			, sqlserver.sql_text
			, sqlserver.username
		)
		WHERE (
			sqlserver.query_hash=(11642443148301233650)
		)
	),
	ADD EVENT sqlserver.sql_statement_completed (
		ACTION (
			  package0.event_sequence
			, sqlserver.client_app_name
			, sqlserver.client_hostname
			, sqlserver.database_name
			, sqlserver.query_hash
			, sqlserver.session_id
			, sqlserver.session_server_principal_name
			, sqlserver.sql_text
			, sqlserver.username
		)
		WHERE (
			sqlserver.query_hash=(11642443148301233650)
		)
	)
	ADD TARGET package0.event_file(
		SET
			  filename = N'G:\ExtendedEvents\WhatRunsThisQuery_0xA192445BEC2CEDF2'
			, max_file_size = 5
			, max_rollover_files = 2
	)
	WITH (
		  MAX_MEMORY = 4 MB
		, EVENT_RETENTION_MODE = ALLOW_MULTIPLE_EVENT_LOSS
		, MAX_DISPATCH_LATENCY = 30 SECONDS
		, MAX_EVENT_SIZE = 0 MB
		, MEMORY_PARTITION_MODE = NONE
		, TRACK_CAUSALITY = OFF
		, STARTUP_STATE = OFF
	);
GO




/* show the extended events */
select s.name extended_event_session , case when xes.name is not null then 'running' else 'stopped' end status from sys.server_event_sessions s left join sys.dm_xe_sessions xes on xes.name=s.name order by s.name;
