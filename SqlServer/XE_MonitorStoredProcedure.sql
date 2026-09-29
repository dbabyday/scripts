/*
FIND AND REPLACE
	myStoredProcName


select s.name extended_event_session , case  when xes.name is not null then 'RUNNING' else 'stopped' end status from sys.server_event_sessions s left join sys.dm_xe_sessions xes on xes.name=s.name order by s.name;

ALTER EVENT SESSION MonitorSP_myStoredProcName ON SERVER STATE = START;
select s.name extended_event_session , case  when xes.name is not null then 'RUNNING' else 'stopped' end status from sys.server_event_sessions s left join sys.dm_xe_sessions xes on xes.name=s.name order by s.name;

ALTER EVENT SESSION MonitorSP_myStoredProcName ON SERVER STATE = STOP;
DROP EVENT SESSION MonitorSP_myStoredProcName ON SERVER;
select s.name extended_event_session , case  when xes.name is not null then 'RUNNING' else 'stopped' end status from sys.server_event_sessions s left join sys.dm_xe_sessions xes on xes.name=s.name order by s.name;

*/

USE master;

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'MonitorSP_myStoredProcName')
	DROP EVENT SESSION MonitorSP_myStoredProcName ON SERVER;

CREATE EVENT SESSION MonitorSP_myStoredProcName
ON SERVER
	  /* ending events */
	  ADD EVENT sqlserver.module_end (
		SET collect_statement = (1)
		ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.session_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.username)
		WHERE (object_name=N'myStoredProcName')
	  )
	, ADD EVENT sqlserver.rpc_completed (
		ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.session_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.username)
		WHERE (object_name=N'myStoredProcName')
	  )
	  /* starting events */
/*	, ADD EVENT sqlserver.module_start (
		SET collect_statement = (1)
		ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.session_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.username)
		WHERE (object_name=N'myStoredProcName')
	  )
	, ADD EVENT sqlserver.rpc_starting (
		ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.session_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.username)
		WHERE (object_name=N'myStoredProcName')
	  )
*/

ADD TARGET package0.event_file (
	SET
		  filename = N'G:\ExtendedEvents\MonitorSP_myStoredProcName'
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


select s.name extended_event_session , case  when xes.name is not null then 'RUNNING' else 'stopped' end status from sys.server_event_sessions s left join sys.dm_xe_sessions xes on xes.name=s.name order by s.name;


/*
FullName                                      ObjDescription
--------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
package0.callstack                            Collect the current call stack
package0.collect_cpu_cycle_time               Collect the current CPU's cycle count
package0.collect_current_thread_id            Collect the current Windows thread ID
package0.collect_system_time                  Collect the current system time with 100 microsecond precision and interrupt tick resolution
package0.debug_break                          Break the process in the default debugger
package0.event_sequence                       Collect event sequence number
package0.last_error                           Collects the value of the thread's last Windows error code. This is equivalent to the GetLastError API.
package0.process_id                           Collect the Windows process ID
sqlos.cpu_id                                  Collect current CPU ID
sqlos.numa_node_id                            Collect current NUMA node ID
sqlos.scheduler_address                       Collect current scheduler address
sqlos.scheduler_id                            Collect current scheduler ID
sqlos.system_thread_id                        Collect current system thread ID
sqlos.task_address                            Collect current task address
sqlos.task_elapsed_quantum                    Collect current task quantum time
sqlos.task_resource_group_id                  Collect current task resource group ID
sqlos.task_resource_pool_id                   Collect current task resource pool ID
sqlos.task_time                               Collect current task execution time
sqlos.worker_address                          Collect current worker address
sqlserver.client_app_name                     Collect client application name
sqlserver.client_connection_id                Collects the optional identifier provided at connection time by a client
sqlserver.client_hostname                     Collect client hostname
sqlserver.client_pid                          Collect client process ID
sqlserver.compile_plan_guid                   Collect compiled plan guid. Use this to uniquely identify the compiled plan
sqlserver.context_info                        Collect the same value as the CONTEXT_INFO() function
sqlserver.create_dump_all_threads             Create mini dump including all threads
sqlserver.create_dump_single_thread           Create mini dump for the current thread
sqlserver.database_id                         Collect database ID
sqlserver.database_name                       Collect current database name
sqlserver.datapool_ddl_guid                   Collect guid datapool DDL query
sqlserver.distributed_plan_step               Collect distributed plan step
sqlserver.distributed_query_hash              Collect distributed query hash
sqlserver.distributed_query_id                Collect distributed query id
sqlserver.distributed_request_id              Collect distributed query processor id
sqlserver.distributed_statement_id            Collect distributed statement id
sqlserver.dms_plan_step                       Collect DMS plan step
sqlserver.dump_rg_history_rb_by_login_failure Dump pool and group ring buffer to xevent
sqlserver.execution_plan_guid                 Collect execution plan guid. Use this to uniquely identify the execution plan
sqlserver.is_system                           Collect whether current session is system
sqlserver.nt_username                         Collect NT username
sqlserver.num_response_rows                   Number of rows returned by statement
sqlserver.plan_handle                         Collect plan handle
sqlserver.query_hash                          Collect query hash. Use this to identify queries with similar logic. You can use the query hash to determine the aggregate resource usage for queries that differ only by literal values
sqlserver.query_hash_signed                   Collect query hash. Use this to identify queries with similar logic. You can use the query hash to determine the aggregate resource usage for queries that differ only by literal values
sqlserver.query_plan_hash                     Collect query plan hash. Use this to identify similar query execution plans. You can use query plan hash to find the cumulative cost of queries with similar execution plans
sqlserver.query_plan_hash_signed              Collect query plan hash. Use this to identify similar query execution plans. You can use query plan hash to find the cumulative cost of queries with similar execution plans
sqlserver.request_id                          Collect current request ID
sqlserver.server_instance_name                Collects the name of the Server instance
sqlserver.server_principal_name               Collects the name of the Server Principal in whose context the event is being fired
sqlserver.server_principal_sid                Collects the SID of the Server Prinicipal in whose context the event is being fired
sqlserver.session_id                          Collect session ID
sqlserver.session_nt_username                 Collect session's NT username
sqlserver.session_resource_group_id           Collect current session resource group ID
sqlserver.session_resource_pool_id            Collect current session resource pool ID
sqlserver.session_server_principal_name       Collects the name of the Server Principal that originated the session in which the event is being fired
sqlserver.sql_text                            Collect SQL text
sqlserver.transaction_id                      Collect transaction ID
sqlserver.transaction_sequence                Collect current transaction sequence number
sqlserver.tsql_frame                          Collect the sql_handle for the current batch with line number, statement offsets and nesting level
sqlserver.tsql_stack                          Collect Transact-SQL stack
sqlserver.username                            Collect username
*/