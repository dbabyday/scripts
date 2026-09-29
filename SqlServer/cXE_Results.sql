/*

select s.name extended_event_session , case  when xes.name is not null then 'RUNNING' else 'stopped' end status from sys.server_event_sessions s left join sys.dm_xe_sessions xes on xes.name=s.name order by s.name;

ALTER EVENT SESSION MonitorSP_usp_SSISMoistureControlUnitForTimerReset_Select ON SERVER STATE = STOP;
DROP EVENT SESSION MonitorSP_usp_SSISMoistureControlUnitForTimerReset_Select ON SERVER;
select s.name extended_event_session , case  when xes.name is not null then 'RUNNING' else 'stopped' end status from sys.server_event_sessions s left join sys.dm_xe_sessions xes on xes.name=s.name order by s.name;


*/


DECLARE
	  @xeName nvarchar(128) = N'MonitorSP_usp_Ate_UnitDetailPhantom_Select'
	, @xeFileDir nvarchar(128) = N'G:\ExtendedEvents\';


DECLARE
	  @path nvarchar(260) = @xeFileDir + @xeName + N'*.xel'
	, @mdpath nvarchar(260) = @xeFileDir + @xeName + N'*.xem';



WITH events_cte AS (
	SELECT
		  xevents.event_data.value('(event/@name)[1]', 'varchar(50)' ) AS event_name
		, xevents.event_data.value('(event/@package)[1]', 'varchar(50)' ) AS package_name
		, DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP), xevents.event_data.value('(event/@timestamp)[1]','datetime2')) AS event_time
		, xevents.event_data.value('(event/action[@name="database_name"]/value)[1]', 'nvarchar(max)') AS database_name
		, xevents.event_data.value('(event/action[@name="session_server_principal_name"]/value)[1]', 'nvarchar(128)' ) AS session_server_principal_name
		, xevents.event_data.value('(event/action[@name="username"]/value)[1]', 'nvarchar(128)' ) AS username
		, xevents.event_data.value('(event/action[@name="client_app_name"]/value)[1]', 'nvarchar(128)') AS client_app_name
		, xevents.event_data.value('(event/action[@name="client_hostname"]/value)[1]', 'nvarchar(max)') AS client_host_name
		, xevents.event_data.value('(event/data[@name="duration"]/value)[1]', 'bigint') AS [duration (ms)]
		, xevents.event_data.value('(event/data[@name="cpu_time"]/value)[1]', 'bigint') AS [cpu time (ms)]
		, xevents.event_data.value('(event/data[@name="logical_reads"]/value)[1]', 'bigint') AS logical_reads
		, xevents.event_data.value('(event/data[@name="row_count"]/value)[1]', 'bigint') AS row_count
		, xevents.event_data.value('(event/data[@name="physical_reads"]/value)[1]', 'bigint' ) AS physical_reads
		, xevents.event_data.value('(event/data[@name="writes"]/value)[1]', 'bigint' ) AS writes
		, xevents.event_data.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS sql_text
		, xevents.event_data.value('(event/data[@name="statement"]/value)[1]', 'nvarchar(max)' ) AS statement
		, xevents.event_data.value('(event/action[@name="event_sequence"]/value)[1]', 'nvarchar(max)') AS event_sequence
		, xevents.event_data.value('(event/data[@name="line_number"]/value)[1]', 'bigint') AS line_number
		, xevents.event_data.value('(event/data[@name="object_id"]/value)[1]', 'bigint') AS object_id
		, xevents.event_data.value('(event/data[@name="object_name"]/value)[1]', 'nvarchar(max)') AS object_name
		, xevents.event_data.value('(event/data[@name="object_type"]/value)[1]', 'nvarchar(max)') AS object_type
		, xevents.event_data.value('(event/data[@name="offset"]/value)[1]', 'bigint') AS offset
		, xevents.event_data.value('(event/data[@name="offset_end"]/value)[1]', 'bigint') AS offset_end
		, xevents.event_data.value('(event/action[@name="query_hash"]/value)[1]', 'nvarchar(max)') AS query_hash
		, xevents.event_data.value('(event/action[@name="session_id"]/value)[1]', 'nvarchar(max)') AS session_id
	FROM
		sys.fn_xe_file_target_read_file(@path,@mdpath,null, null)
	CROSS APPLY
		(select CAST(event_data as XML) as event_data) as xevents
)
SELECT
	  event_time
	, [duration (ms)]*0.000001 AS [duration (seconds)]
	, [cpu time (ms)]*0.000001 AS [cpu time (seconds)]
	, logical_reads
	, physical_reads
	, writes
	, row_count
	, package_name + '.' + event_name AS action_name
	, event_sequence
	, line_number
	, object_id
	, object_name
	, object_type
	, offset
	, offset_end
	, statement
	, sql_text
	, session_server_principal_name
	, username
	, database_name
	, session_id
	, client_app_name
	, client_host_name
	, query_hash
FROM
	events_cte
WHERE
	statement<>''
	--and [duration (ms)]>3600000000 /* 1 hour */
ORDER BY
	  event_time desc
	, event_sequence;