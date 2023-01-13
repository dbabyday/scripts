IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = 'XE_Activity')
	DROP EVENT SESSION [XE_Activity] ON SERVER;
GO
CREATE EVENT SESSION [XE_Activity]
ON SERVER
ADD EVENT sqlserver.existing_connection(
	ACTION 
	(
			  sqlserver.client_app_name	-- ApplicationName from SQLTrace
			, sqlserver.client_hostname	-- HostName from SQLTrace
			, sqlserver.server_principal_name	-- LoginName from SQLTrace
			, sqlserver.server_principal_name	-- LoginName from SQLTrace
			, sqlserver.server_principal_name	-- LoginName from SQLTrace
			, sqlserver.session_id	-- SPID from SQLTrace
	)
	WHERE 
	(
			sqlserver.client_app_name <> '%SQL Monitor - Monitoring%'
			AND sqlserver.server_principal_name <> '%NA\srvcCV_SQL.neen%'
			AND sqlserver.server_principal_name <> '%NA\Srvcscomsql.plx%'
			AND sqlserver.server_principal_name <> '%NA\james.lutsey.admin%'
	)
),
ADD EVENT sqlserver.login(
	ACTION 
	(
			  sqlserver.client_app_name	-- ApplicationName from SQLTrace
			, sqlserver.client_hostname	-- HostName from SQLTrace
			, sqlserver.server_principal_name	-- LoginName from SQLTrace
			, sqlserver.server_principal_name	-- LoginName from SQLTrace
			, sqlserver.server_principal_name	-- LoginName from SQLTrace
			, sqlserver.session_id	-- SPID from SQLTrace
	)
	WHERE 
	(
			sqlserver.client_app_name <> '%SQL Monitor - Monitoring%'
			AND sqlserver.server_principal_name <> '%NA\srvcCV_SQL.neen%'
			AND sqlserver.server_principal_name <> '%NA\Srvcscomsql.plx%'
			AND sqlserver.server_principal_name <> '%NA\james.lutsey.admin%'
	)
),
ADD EVENT sqlserver.logout(
	ACTION 
	(
			  sqlserver.client_app_name	-- ApplicationName from SQLTrace
			, sqlserver.client_hostname	-- HostName from SQLTrace
			, sqlserver.database_name	-- DatabaseName from SQLTrace
			, sqlserver.server_principal_name	-- LoginName from SQLTrace
			, sqlserver.server_principal_name	-- LoginName from SQLTrace
			, sqlserver.server_principal_name	-- LoginName from SQLTrace
			, sqlserver.session_id	-- SPID from SQLTrace
	)
	WHERE 
	(
			sqlserver.client_app_name <> '%SQL Monitor - Monitoring%'
			AND sqlserver.server_principal_name <> '%NA\srvcCV_SQL.neen%'
			AND sqlserver.server_principal_name <> '%NA\Srvcscomsql.plx%'
			AND sqlserver.server_principal_name <> '%NA\james.lutsey.admin%'
	)
),
ADD EVENT sqlserver.rpc_starting(
	ACTION 
	(
			  sqlserver.client_app_name	-- ApplicationName from SQLTrace
			, sqlserver.client_hostname	-- HostName from SQLTrace
			, sqlserver.database_name	-- DatabaseName from SQLTrace
			, sqlserver.server_principal_name	-- LoginName from SQLTrace
			, sqlserver.server_principal_name	-- LoginName from SQLTrace
			, sqlserver.server_principal_name	-- LoginName from SQLTrace
			, sqlserver.session_id	-- SPID from SQLTrace
			-- BinaryData not implemented in XE for this event
	)
	WHERE 
	(
			sqlserver.client_app_name <> '%SQL Monitor - Monitoring%'
			AND sqlserver.server_principal_name <> '%NA\srvcCV_SQL.neen%'
			AND sqlserver.server_principal_name <> '%NA\Srvcscomsql.plx%'
			AND sqlserver.server_principal_name <> '%NA\james.lutsey.admin%'
	)
),
ADD EVENT sqlserver.sql_statement_starting(
	ACTION 
	(
			  sqlserver.client_app_name	-- ApplicationName from SQLTrace
			, sqlserver.client_hostname	-- HostName from SQLTrace
			, sqlserver.database_name	-- DatabaseName from SQLTrace
			, sqlserver.server_principal_name	-- LoginName from SQLTrace
			, sqlserver.server_principal_name	-- LoginName from SQLTrace
			, sqlserver.server_principal_name	-- LoginName from SQLTrace
			, sqlserver.session_id	-- SPID from SQLTrace
	)
	WHERE 
	(
			sqlserver.client_app_name <> '%SQL Monitor - Monitoring%'
			AND sqlserver.server_principal_name <> '%NA\srvcCV_SQL.neen%'
			AND sqlserver.server_principal_name <> '%NA\Srvcscomsql.plx%'
			AND sqlserver.server_principal_name <> '%NA\james.lutsey.admin%'
	)
)
ADD TARGET package0.event_file
(
	SET filename = 'F:\Traces\XE_Activity.xel',
		max_file_size = 5120,
		max_rollover_files = 1
)
