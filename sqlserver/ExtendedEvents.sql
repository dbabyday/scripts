

/*

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'monitor_usp_VisualDataManagementCurrentModelSMT_Select')
	DROP EVENT SESSION monitor_usp_VisualDataManagementCurrentModelSMT_Select ON SERVER;

CREATE EVENT SESSION monitor_usp_VisualDataManagementCurrentModelSMT_Select
ON SERVER 
--ADD EVENT sqlserver.module_end (
ADD EVENT sqlserver.module_start (
	SET collect_statement=1
	ACTION (
		  sqlserver.client_app_name
		, sqlserver.client_hostname
		, sqlserver.database_name
		, sqlserver.query_plan_hash
		, sqlserver.session_server_principal_name
		, sqlserver.username
		, sqlserver.sql_text
	)
	WHERE (
		[object_type]='P ' -- The space behind P is necesssary
		AND [object_name]=N'usp_VisualDataManagementCurrentModelSMT_Select'
	)
)
ADD TARGET package0.event_file(
	SET
		  filename=N'G:\logs\monitor_usp_VisualDataManagementCurrentModelSMT_Select.xel'
		, max_file_size = (1)
		, max_rollover_files = (3)
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

ALTER EVENT SESSION monitor_usp_VisualDataManagementCurrentModelSMT_Select ON SERVER STATE = START;

ALTER EVENT SESSION monitor_usp_VisualDataManagementCurrentModelSMT_Select ON SERVER STATE = STOP;

DROP EVENT SESSION monitor_usp_VisualDataManagementCurrentModelSMT_Select ON SERVER;






CREATE EVENT SESSION [test] ON SERVER 
ADD EVENT sqlserver.sp_statement_completed(SET collect_object_name=(1),collect_statement=(1)
    ACTION(package0.callstack,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.sql_text,sqlserver.tsql_stack)
    WHERE ([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name],N'GSF2_AMER_PRODFIX') AND [object_name]=N'usp_VisualDataManagementCurrentModelSMT_Select'))
ADD TARGET package0.event_file(SET filename=N'G:\logs\test.xel',max_file_size=(100))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

ALTER EVENT SESSION test ON SERVER STATE = START;

ALTER EVENT SESSION test ON SERVER STATE = STOP;

DROP EVENT SESSION test ON SERVER;




--*/



DECLARE @file_name nvarchar(256) = 
	N'G:\logs\test*.xel';


SELECT
	  -- package_name
	  event_name
	, [utc_timestamp]
	-- , cast(duration_ms/1000 as varchar) + '.' + right('000'+cast(duration_ms%3600000%60000%1000 as varchar),3) duration_seconds
	, case
		when duration_ms/3600000<10 then right('00'+cast(duration_ms/3600000 as varchar),2) + ':' + right('00'+cast(duration_ms%3600000/60000 as varchar),2) + ':' + right('00'+cast(duration_ms%3600000%60000/1000 as varchar),2) + '.' + right('000'+cast(duration_ms%3600000%60000%1000 as varchar),3)
		else cast(duration_ms/3600000 as varchar) + ':' + right('00'+cast(duration_ms%3600000/60000 as varchar),2) + ':' + right('00'+cast(duration_ms%3600000%60000/1000 as varchar),2) + '.' + right('000'+cast(duration_ms%3600000%60000%1000 as varchar),3)
	  end duration
	, statement
	, sql_text
	, database_name

	, session_server_principal_name
	, username
	, client_app_nam

	 , physical_reads
	 , logical_reads
	 , writes
	 , row_count
	 , cpu_time
FROM
	(
		SELECT
			  n.value( '(@name)[1]', 'varchar(50)' ) AS event_name
			, n.value( '(@package)[1]', 'varchar(50)' ) AS package_name
			, n.value( '(@timestamp)[1]', 'datetime2' ) AS [utc_timestamp]
			, n.value( '(action[@name="database_name"]/value)[1]', 'nvarchar(max)' ) AS database_name
			, n.value( '(action[@name="session_server_principal_name"]/value)[1]', 'nvarchar(128)' ) AS session_server_principal_name
			, n.value( '(action[@name="username"]/value)[1]', 'nvarchar(128)' ) AS username
			, n.value( '(action[@name="client_app_name"]/value)[1]', 'nvarchar(max)' ) AS client_app_nam
			, n.value( '(data[@name="physical_reads"]/value)[1]', 'bigint' ) AS physical_reads
			, n.value( '(data[@name="logical_reads"]/value)[1]', 'bigint' ) AS logical_reads
			, n.value( '(data[@name="writes"]/value)[1]', 'bigint' ) AS writes
			, n.value( '(data[@name="row_count"]/value)[1]', 'bigint' ) AS row_count
			, n.value( '(data[@name="cpu_time"]/value)[1]', 'bigint' ) AS cpu_time
			, n.value( '(data[@name="duration"]/value)[1]', 'bigint' ) / 1000 AS duration_ms
			, n.value( '(data[@name="sql_text"]/value)[1]', 'nvarchar(max)' ) AS sql_text
			, n.value( '(data[@name="statement"]/value)[1]', 'nvarchar(max)' ) AS statement
			, n.value( '(data[@name="tsql_stack"]/value)[1]', 'nvarchar(max)' ) AS tsql_stack
			, n.value( '(data[@name="xml_report"]/value)[1]', 'nvarchar(max)' ) AS xml_report
		FROM
			(
				SELECT
					CAST(event_data AS XML) AS event_data
				FROM
					sys.fn_xe_file_target_read_file(@file_name, NULL, NULL, NULL )
			) AS ed
		CROSS APPLY
			ed.event_data.nodes( 'event' ) AS q(n)
	) AS TMP_TBL
order by
	[utc_timestamp];




WITH events_cte AS (
	SELECT
		  xevents.event_data.value('(event/@name)[1]', 'varchar(50)' ) AS event_name
		, xevents.event_data.value('(event/@package)[1]', 'varchar(50)' ) AS package_name
		, DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP), xevents.event_data.value('(event/@timestamp)[1]','datetime2')) AS [event time]
		, xevents.event_data.value('(event/action[@name="database_name"]/value)[1]', 'nvarchar(max)') AS [database name]
		, xevents.event_data.value('(event/action[@name="session_server_principal_name"]/value)[1]', 'nvarchar(128)' ) AS session_server_principal_name
		, xevents.event_data.value('(event/action[@name="username"]/value)[1]', 'nvarchar(128)' ) AS username
		, xevents.event_data.value('(event/action[@name="client_app_name"]/value)[1]', 'nvarchar(128)') AS [client app name]
		, xevents.event_data.value('(event/action[@name="client_hostname"]/value)[1]', 'nvarchar(max)') AS [client host name]
		, xevents.event_data.value('(event/data[@name="duration"]/value)[1]', 'bigint') AS [duration (ms)]
		, xevents.event_data.value('(event/data[@name="cpu_time"]/value)[1]', 'bigint') AS [cpu time (ms)]
		, xevents.event_data.value('(event/data[@name="logical_reads"]/value)[1]', 'bigint') AS [logical reads]
		, xevents.event_data.value('(event/data[@name="row_count"]/value)[1]', 'bigint') AS [row count]
		, xevents.event_data.value('(event/data[@name="physical_reads"]/value)[1]', 'bigint' ) AS physical_reads
		, xevents.event_data.value('(event/data[@name="writes"]/value)[1]', 'bigint' ) AS writes
		, xevents.event_data.value('(event/data[@name="sql_text"]/value)[1]', 'nvarchar(max)' ) AS sql_text
		, xevents.event_data.value('(event/data[@name="statement"]/value)[1]', 'nvarchar(max)' ) AS statement
		, xevents.event_data.value('(event/data[@name="tsql_stack"]/value)[1]', 'nvarchar(max)' ) AS tsql_stack
		, xevents.event_data.value('(event/data[@name="xml_report"]/value)[1]', 'nvarchar(max)' ) AS xml_report
	FROM
		sys.fn_xe_file_target_read_file('G:\logs\test*.xel','G:\logs\test*.xem',null, null)
	CROSS APPLY
		(select CAST(event_data as XML) as event_data) as xevents
)
SELECT
	*
FROM
	events_cte
ORDER BY
	[event time] DESC;




WITH events_cte AS (
	SELECT
		  xevents.event_data.value('(event/@name)[1]', 'varchar(50)' ) AS event_name
		, xevents.event_data.value('(event/@package)[1]', 'varchar(50)' ) AS package_name
		, DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP), xevents.event_data.value('(event/@timestamp)[1]','datetime2')) AS [event time]
		, xevents.event_data.value('(event/action[@name="database_name"]/value)[1]', 'nvarchar(max)') AS [database name]
		, xevents.event_data.value('(event/action[@name="session_server_principal_name"]/value)[1]', 'nvarchar(128)' ) AS session_server_principal_name
		, xevents.event_data.value('(event/action[@name="username"]/value)[1]', 'nvarchar(128)' ) AS username
		, xevents.event_data.value('(event/action[@name="client_app_name"]/value)[1]', 'nvarchar(128)') AS [client app name]
		, xevents.event_data.value('(event/action[@name="client_hostname"]/value)[1]', 'nvarchar(max)') AS [client host name]
		, xevents.event_data.value('(event/data[@name="duration"]/value)[1]', 'bigint') AS [duration (ms)]
		, xevents.event_data.value('(event/data[@name="cpu_time"]/value)[1]', 'bigint') AS [cpu time (ms)]
		, xevents.event_data.value('(event/data[@name="logical_reads"]/value)[1]', 'bigint') AS [logical reads]
		, xevents.event_data.value('(event/data[@name="row_count"]/value)[1]', 'bigint') AS [row count]
		, xevents.event_data.value('(event/data[@name="physical_reads"]/value)[1]', 'bigint' ) AS physical_reads
		, xevents.event_data.value('(event/data[@name="writes"]/value)[1]', 'bigint' ) AS writes
		, xevents.event_data.value('(event/data[@name="sql_text"]/value)[1]', 'nvarchar(max)' ) AS sql_text
		, xevents.event_data.value('(event/data[@name="statement"]/value)[1]', 'nvarchar(max)' ) AS statement
		, xevents.event_data.value('(event/data[@name="tsql_stack"]/value)[1]', 'nvarchar(max)' ) AS tsql_stack
		, xevents.event_data.value('(event/data[@name="xml_report"]/value)[1]', 'nvarchar(max)' ) AS xml_report
	FROM
		sys.fn_xe_file_target_read_file('G:\logs\monitor_usp_VisualDataManagementCurrentModelSMT_Select*.xel','G:\logs\monitor_usp_VisualDataManagementCurrentModelSMT_Select*.xem',null, null)
	CROSS APPLY
		(select CAST(event_data as XML) as event_data) as xevents
)
SELECT
	*
FROM
	events_cte
ORDER BY
	[event time] DESC;