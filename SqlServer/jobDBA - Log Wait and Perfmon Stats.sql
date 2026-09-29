/*=======================================================================
==// Verify sp_RaiserrorTime Exists                                  //==
=======================================================================*/

IF NOT EXISTS (SELECT 1 FROM master.sys.procedures WHERE name=N'sp_RaiserrorTime')
BEGIN
    RAISERROR('master.dbo.sp_RaiserrorTime does not exist. Create that procedure first. Setting NOEXEC ON to skip this execution.',16,1) WITH NOWAIT;
    SET NOEXEC ON;   /*         SET NOEXEC OFF;         */
END;





/*=======================================================================
==// Create the logging tables                                       //==
=======================================================================*/

USE CentralAdmin;
GO


IF ((SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='WaitStats' AND COLUMN_NAME IN ( 'ID','ServerName','CheckDate','wait_type','wait_time_ms','signal_wait_time_ms','waiting_tasks_count')) <> 7)
BEGIN
	EXECUTE sp_RaiserrorTime N'Create dbo.WaitStats';
	DROP TABLE IF EXISTS dbo.WaitStats;
	CREATE TABLE dbo.WaitStats (
		  ID                  INT IDENTITY(1,1) NOT NULL
		, ServerName          NVARCHAR(128) NOT NULL
		, CheckDate           DATETIMEOFFSET(7) NOT NULL
		, wait_type           NVARCHAR(60) NOT NULL
		, wait_time_ms        BIGINT NOT NULL
		, signal_wait_time_ms BIGINT NOT NULL
		, waiting_tasks_count BIGINT NOT NULL

		, CONSTRAINT PK_WaitStats PRIMARY KEY CLUSTERED (ID)
	);

	CREATE NONCLUSTERED INDEX IX_WaitStats_CheckDate_Includes
	ON dbo.WaitStats (CheckDate)
	INCLUDE (ServerName, wait_type, wait_time_ms, signal_wait_time_ms, waiting_tasks_count)
	WITH (ONLINE=OFF, MAXDOP=0);
END;
ELSE
BEGIN
	EXECUTE sp_RaiserrorTime N'Table dbo.WaitStats already exists';
END;




IF ((SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='PerfmonStats' AND COLUMN_NAME IN ( 'ID','ServerName','CheckDate','object_name','counter_name','instance_name','cntr_value')) <> 7)
BEGIN
	EXECUTE sp_RaiserrorTime N'Create dbo.PerfmonStats';
	DROP TABLE IF EXISTS dbo.PerfmonStats;
	CREATE TABLE dbo.PerfmonStats (
		  ID            INT IDENTITY(1,1) NOT NULL
		, ServerName    NVARCHAR(128) NOT NULL
		, CheckDate     DATETIMEOFFSET(7) NOT NULL
		, object_name   NVARCHAR(128) NOT NULL
		, counter_name  NVARCHAR(128) NOT NULL
		, instance_name NVARCHAR(128) NULL
		, cntr_value    BIGINT NULL
		
		, CONSTRAINT PK_PerfmonStats PRIMARY KEY CLUSTERED (ID)
	);
END;
ELSE
BEGIN
	EXECUTE sp_RaiserrorTime N'Table dbo.PerfmonStats already exists';
END;



IF ((SELECT COUNT(1) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='LatchStats' AND COLUMN_NAME IN ( 'ID','ServerName','CheckDate','latch_class','waiting_requests_count','wait_time_ms','max_wait_time_ms')) <> 7)
BEGIN
	EXECUTE sp_RaiserrorTime N'Create dbo.LatchStats';
	DROP TABLE IF EXISTS dbo.LatchStats;
	CREATE TABLE dbo.LatchStats (
		  ID                     int IDENTITY(1,1) NOT NULL
		, ServerName             nvarchar(128) NOT NULL
		, CheckDate              datetimeoffset(7) NOT NULL
		, latch_class            nvarchar(60) NULL
		, waiting_requests_count bigint NULL
		, wait_time_ms           bigint NULL
		, max_wait_time_ms       bigint NULL
		
		, CONSTRAINT PK_LatchStats PRIMARY KEY CLUSTERED (ID)
	);
END;
ELSE
BEGIN
	EXECUTE sp_RaiserrorTime N'Table dbo.LatchStats already exists';
END;



IF OBJECT_ID(N'dbo.BlitzFirst_WaitStats_Categories',N'U') IS NULL
BEGIN
	EXECUTE sp_RaiserrorTime N'Create dbo.BlitzFirst_WaitStats_Categories';
	CREATE TABLE dbo.BlitzFirst_WaitStats_Categories (
		  WaitType     NVARCHAR(60) NOT NULL
		, WaitCategory NVARCHAR(128) NOT NULL
		, Ignorable    BIT NULL DEFAULT 0

		, PRIMARY KEY CLUSTERED (WaitType)
	);

	INSERT dbo.BlitzFirst_WaitStats_Categories (WaitType, WaitCategory, Ignorable) VALUES 
		  (N'ASYNC_IO_COMPLETION', N'Other Disk IO', 0)
		, (N'ASYNC_NETWORK_IO', N'Network IO', 0)
		, (N'BACKUPIO', N'Other Disk IO', 0)
		, (N'BROKER_CONNECTION_RECEIVE_TASK', N'Service Broker', 0)
		, (N'BROKER_DISPATCHER', N'Service Broker', 0)
		, (N'BROKER_ENDPOINT_STATE_MUTEX', N'Service Broker', 0)
		, (N'BROKER_EVENTHANDLER', N'Service Broker', 1)
		, (N'BROKER_FORWARDER', N'Service Broker', 0)
		, (N'BROKER_INIT', N'Service Broker', 0)
		, (N'BROKER_MASTERSTART', N'Service Broker', 0)
		, (N'BROKER_RECEIVE_WAITFOR', N'User Wait', 1)
		, (N'BROKER_REGISTERALLENDPOINTS', N'Service Broker', 0)
		, (N'BROKER_SERVICE', N'Service Broker', 0)
		, (N'BROKER_SHUTDOWN', N'Service Broker', 0)
		, (N'BROKER_START', N'Service Broker', 0)
		, (N'BROKER_TASK_SHUTDOWN', N'Service Broker', 0)
		, (N'BROKER_TASK_STOP', N'Service Broker', 1)
		, (N'BROKER_TASK_SUBMIT', N'Service Broker', 0)
		, (N'BROKER_TO_FLUSH', N'Service Broker', 1)
		, (N'BROKER_TRANSMISSION_OBJECT', N'Service Broker', 0)
		, (N'BROKER_TRANSMISSION_TABLE', N'Service Broker', 0)
		, (N'BROKER_TRANSMISSION_WORK', N'Service Broker', 0)
		, (N'BROKER_TRANSMITTER', N'Service Broker', 1)
		, (N'CHECKPOINT_QUEUE', N'Idle', 1)
		, (N'CHKPT', N'Tran Log IO', 0)
		, (N'CLR_AUTO_EVENT', N'SQL CLR', 1)
		, (N'CLR_CRST', N'SQL CLR', 0)
		, (N'CLR_JOIN', N'SQL CLR', 0)
		, (N'CLR_MANUAL_EVENT', N'SQL CLR', 1)
		, (N'CLR_MEMORY_SPY', N'SQL CLR', 0)
		, (N'CLR_MONITOR', N'SQL CLR', 0)
		, (N'CLR_RWLOCK_READER', N'SQL CLR', 0)
		, (N'CLR_RWLOCK_WRITER', N'SQL CLR', 0)
		, (N'CLR_SEMAPHORE', N'SQL CLR', 1)
		, (N'CLR_TASK_START', N'SQL CLR', 0)
		, (N'CLRHOST_STATE_ACCESS', N'SQL CLR', 0)
		, (N'CMEMPARTITIONED', N'Memory', 0)
		, (N'CMEMTHREAD', N'Memory', 0)
		, (N'CXCONSUMER', N'Parallelism', 0)
		, (N'CXPACKET', N'Parallelism', 0)
		, (N'DBMIRROR_DBM_EVENT', N'Mirroring', 1)
		, (N'DBMIRROR_DBM_MUTEX', N'Mirroring', 1)
		, (N'DBMIRROR_EVENTS_QUEUE', N'Mirroring', 1)
		, (N'DBMIRROR_SEND', N'Mirroring', 0)
		, (N'DBMIRROR_WORKER_QUEUE', N'Mirroring', 1)
		, (N'DBMIRRORING_CMD', N'Mirroring', 1)
		, (N'DIRTY_PAGE_POLL', N'Other', 1)
		, (N'DIRTY_PAGE_TABLE_LOCK', N'Replication', 0)
		, (N'DISPATCHER_QUEUE_SEMAPHORE', N'Other', 1)
		, (N'DPT_ENTRY_LOCK', N'Replication', 0)
		, (N'DTC', N'Transaction', 0)
		, (N'DTC_ABORT_REQUEST', N'Transaction', 0)
		, (N'DTC_RESOLVE', N'Transaction', 0)
		, (N'DTC_STATE', N'Transaction', 0)
		, (N'DTC_TMDOWN_REQUEST', N'Transaction', 0)
		, (N'DTC_WAITFOR_OUTCOME', N'Transaction', 0)
		, (N'DTCNEW_ENLIST', N'Transaction', 0)
		, (N'DTCNEW_PREPARE', N'Transaction', 0)
		, (N'DTCNEW_RECOVERY', N'Transaction', 0)
		, (N'DTCNEW_TM', N'Transaction', 0)
		, (N'DTCNEW_TRANSACTION_ENLISTMENT', N'Transaction', 0)
		, (N'DTCPNTSYNC', N'Transaction', 0)
		, (N'EE_PMOLOCK', N'Memory', 0)
		, (N'EXCHANGE', N'Parallelism', 0)
		, (N'EXTERNAL_SCRIPT_NETWORK_IOF', N'Network IO', 0)
		, (N'FCB_REPLICA_READ', N'Replication', 0)
		, (N'FCB_REPLICA_WRITE', N'Replication', 0)
		, (N'FT_COMPROWSET_RWLOCK', N'Full Text Search', 0)
		, (N'FT_IFTS_RWLOCK', N'Full Text Search', 0)
		, (N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'Idle', 1)
		, (N'FT_IFTSHC_MUTEX', N'Full Text Search', 1)
		, (N'FT_IFTSISM_MUTEX', N'Full Text Search', 1)
		, (N'FT_MASTER_MERGE', N'Full Text Search', 0)
		, (N'FT_MASTER_MERGE_COORDINATOR', N'Full Text Search', 0)
		, (N'FT_METADATA_MUTEX', N'Full Text Search', 0)
		, (N'FT_PROPERTYLIST_CACHE', N'Full Text Search', 0)
		, (N'FT_RESTART_CRAWL', N'Full Text Search', 0)
		, (N'FULLTEXT GATHERER', N'Full Text Search', 0)
		, (N'HADR_AG_MUTEX', N'Replication', 0)
		, (N'HADR_AR_CRITICAL_SECTION_ENTRY', N'Replication', 0)
		, (N'HADR_AR_MANAGER_MUTEX', N'Replication', 0)
		, (N'HADR_AR_UNLOAD_COMPLETED', N'Replication', 0)
		, (N'HADR_ARCONTROLLER_NOTIFICATIONS_SUBSCRIBER_LIST', N'Replication', 0)
		, (N'HADR_BACKUP_BULK_LOCK', N'Replication', 0)
		, (N'HADR_BACKUP_QUEUE', N'Replication', 0)
		, (N'HADR_CLUSAPI_CALL', N'Replication', 1)
		, (N'HADR_COMPRESSED_CACHE_SYNC', N'Replication', 0)
		, (N'HADR_CONNECTIVITY_INFO', N'Replication', 0)
		, (N'HADR_DATABASE_FLOW_CONTROL', N'Replication', 0)
		, (N'HADR_DATABASE_VERSIONING_STATE', N'Replication', 0)
		, (N'HADR_DATABASE_WAIT_FOR_RECOVERY', N'Replication', 0)
		, (N'HADR_DATABASE_WAIT_FOR_RESTART', N'Replication', 0)
		, (N'HADR_DATABASE_WAIT_FOR_TRANSITION_TO_VERSIONING', N'Replication', 0)
		, (N'HADR_DB_COMMAND', N'Replication', 0)
		, (N'HADR_DB_OP_COMPLETION_SYNC', N'Replication', 0)
		, (N'HADR_DB_OP_START_SYNC', N'Replication', 0)
		, (N'HADR_DBR_SUBSCRIBER', N'Replication', 0)
		, (N'HADR_DBR_SUBSCRIBER_FILTER_LIST', N'Replication', 0)
		, (N'HADR_DBSEEDING', N'Replication', 0)
		, (N'HADR_DBSEEDING_LIST', N'Replication', 0)
		, (N'HADR_DBSTATECHANGE_SYNC', N'Replication', 0)
		, (N'HADR_FABRIC_CALLBACK', N'Replication', 1)
		, (N'HADR_FILESTREAM_BLOCK_FLUSH', N'Replication', 0)
		, (N'HADR_FILESTREAM_FILE_CLOSE', N'Replication', 0)
		, (N'HADR_FILESTREAM_FILE_REQUEST', N'Replication', 0)
		, (N'HADR_FILESTREAM_IOMGR', N'Replication', 0)
		, (N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', N'Replication', 1)
		, (N'HADR_FILESTREAM_MANAGER', N'Replication', 0)
		, (N'HADR_FILESTREAM_PREPROC', N'Replication', 0)
		, (N'HADR_GROUP_COMMIT', N'Replication', 0)
		, (N'HADR_LOGCAPTURE_SYNC', N'Replication', 0)
		, (N'HADR_LOGCAPTURE_WAIT', N'Replication', 1)
		, (N'HADR_LOGPROGRESS_SYNC', N'Replication', 0)
		, (N'HADR_NOTIFICATION_DEQUEUE', N'Replication', 1)
		, (N'HADR_NOTIFICATION_WORKER_EXCLUSIVE_ACCESS', N'Replication', 0)
		, (N'HADR_NOTIFICATION_WORKER_STARTUP_SYNC', N'Replication', 0)
		, (N'HADR_NOTIFICATION_WORKER_TERMINATION_SYNC', N'Replication', 0)
		, (N'HADR_PARTNER_SYNC', N'Replication', 0)
		, (N'HADR_READ_ALL_NETWORKS', N'Replication', 0)
		, (N'HADR_RECOVERY_WAIT_FOR_CONNECTION', N'Replication', 0)
		, (N'HADR_RECOVERY_WAIT_FOR_UNDO', N'Replication', 0)
		, (N'HADR_REPLICAINFO_SYNC', N'Replication', 0)
		, (N'HADR_SEEDING_CANCELLATION', N'Replication', 0)
		, (N'HADR_SEEDING_FILE_LIST', N'Replication', 0)
		, (N'HADR_SEEDING_LIMIT_BACKUPS', N'Replication', 0)
		, (N'HADR_SEEDING_SYNC_COMPLETION', N'Replication', 0)
		, (N'HADR_SEEDING_TIMEOUT_TASK', N'Replication', 0)
		, (N'HADR_SEEDING_WAIT_FOR_COMPLETION', N'Replication', 0)
		, (N'HADR_SYNC_COMMIT', N'Replication', 0)
		, (N'HADR_SYNCHRONIZING_THROTTLE', N'Replication', 0)
		, (N'HADR_TDS_LISTENER_SYNC', N'Replication', 0)
		, (N'HADR_TDS_LISTENER_SYNC_PROCESSING', N'Replication', 0)
		, (N'HADR_THROTTLE_LOG_RATE_GOVERNOR', N'Log Rate Governor', 0)
		, (N'HADR_TIMER_TASK', N'Replication', 1)
		, (N'HADR_TRANSPORT_DBRLIST', N'Replication', 0)
		, (N'HADR_TRANSPORT_FLOW_CONTROL', N'Replication', 0)
		, (N'HADR_TRANSPORT_SESSION', N'Replication', 0)
		, (N'HADR_WORK_POOL', N'Replication', 0)
		, (N'HADR_WORK_QUEUE', N'Replication', 1)
		, (N'HADR_XRF_STACK_ACCESS', N'Replication', 0)
		, (N'INSTANCE_LOG_RATE_GOVERNOR', N'Log Rate Governor', 0)
		, (N'IO_COMPLETION', N'Other Disk IO', 0)
		, (N'IO_QUEUE_LIMIT', N'Other Disk IO', 0)
		, (N'IO_RETRY', N'Other Disk IO', 0)
		, (N'LATCH_DT', N'Latch', 0)
		, (N'LATCH_EX', N'Latch', 0)
		, (N'LATCH_KP', N'Latch', 0)
		, (N'LATCH_NL', N'Latch', 0)
		, (N'LATCH_SH', N'Latch', 0)
		, (N'LATCH_UP', N'Latch', 0)
		, (N'LAZYWRITER_SLEEP', N'Idle', 1)
		, (N'LCK_M_BU', N'Lock', 0)
		, (N'LCK_M_BU_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_BU_LOW_PRIORITY', N'Lock', 0)
		, (N'LCK_M_IS', N'Lock', 0)
		, (N'LCK_M_IS_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_IS_LOW_PRIORITY', N'Lock', 0)
		, (N'LCK_M_IU', N'Lock', 0)
		, (N'LCK_M_IU_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_IU_LOW_PRIORITY', N'Lock', 0)
		, (N'LCK_M_IX', N'Lock', 0)
		, (N'LCK_M_IX_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_IX_LOW_PRIORITY', N'Lock', 0)
		, (N'LCK_M_RIn_NL', N'Lock', 0)
		, (N'LCK_M_RIn_NL_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_RIn_NL_LOW_PRIORITY', N'Lock', 0)
		, (N'LCK_M_RIn_S', N'Lock', 0)
		, (N'LCK_M_RIn_S_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_RIn_S_LOW_PRIORITY', N'Lock', 0)
		, (N'LCK_M_RIn_U', N'Lock', 0)
		, (N'LCK_M_RIn_U_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_RIn_U_LOW_PRIORITY', N'Lock', 0)
		, (N'LCK_M_RIn_X', N'Lock', 0)
		, (N'LCK_M_RIn_X_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_RIn_X_LOW_PRIORITY', N'Lock', 0)
		, (N'LCK_M_RS_S', N'Lock', 0)
		, (N'LCK_M_RS_S_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_RS_S_LOW_PRIORITY', N'Lock', 0)
		, (N'LCK_M_RS_U', N'Lock', 0)
		, (N'LCK_M_RS_U_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_RS_U_LOW_PRIORITY', N'Lock', 0)
		, (N'LCK_M_RX_S', N'Lock', 0)
		, (N'LCK_M_RX_S_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_RX_S_LOW_PRIORITY', N'Lock', 0)
		, (N'LCK_M_RX_U', N'Lock', 0)
		, (N'LCK_M_RX_U_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_RX_U_LOW_PRIORITY', N'Lock', 0)
		, (N'LCK_M_RX_X', N'Lock', 0)
		, (N'LCK_M_RX_X_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_RX_X_LOW_PRIORITY', N'Lock', 0)
		, (N'LCK_M_S', N'Lock', 0)
		, (N'LCK_M_S_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_S_LOW_PRIORITY', N'Lock', 0)
		, (N'LCK_M_SCH_M', N'Lock', 0)
		, (N'LCK_M_SCH_M_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_SCH_M_LOW_PRIORITY', N'Lock', 0)
		, (N'LCK_M_SCH_S', N'Lock', 0)
		, (N'LCK_M_SCH_S_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_SCH_S_LOW_PRIORITY', N'Lock', 0)
		, (N'LCK_M_SIU', N'Lock', 0)
		, (N'LCK_M_SIU_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_SIU_LOW_PRIORITY', N'Lock', 0)
		, (N'LCK_M_SIX', N'Lock', 0)
		, (N'LCK_M_SIX_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_SIX_LOW_PRIORITY', N'Lock', 0)
		, (N'LCK_M_U', N'Lock', 0)
		, (N'LCK_M_U_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_U_LOW_PRIORITY', N'Lock', 0)
		, (N'LCK_M_UIX', N'Lock', 0)
		, (N'LCK_M_UIX_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_UIX_LOW_PRIORITY', N'Lock', 0)
		, (N'LCK_M_X', N'Lock', 0)
		, (N'LCK_M_X_ABORT_BLOCKERS', N'Lock', 0)
		, (N'LCK_M_X_LOW_PRIORITY', N'Lock', 0)
		, (N'LOG_RATE_GOVERNOR', N'Tran Log IO', 0)
		, (N'LOGBUFFER', N'Tran Log IO', 0)
		, (N'LOGMGR', N'Tran Log IO', 0)
		, (N'LOGMGR_FLUSH', N'Tran Log IO', 0)
		, (N'LOGMGR_PMM_LOG', N'Tran Log IO', 0)
		, (N'LOGMGR_QUEUE', N'Idle', 1)
		, (N'LOGMGR_RESERVE_APPEND', N'Tran Log IO', 0)
		, (N'MEMORY_ALLOCATION_EXT', N'Memory', 0)
		, (N'MEMORY_GRANT_UPDATE', N'Memory', 0)
		, (N'MSQL_XACT_MGR_MUTEX', N'Transaction', 0)
		, (N'MSQL_XACT_MUTEX', N'Transaction', 0)
		, (N'MSSEARCH', N'Full Text Search', 0)
		, (N'NET_WAITFOR_PACKET', N'Network IO', 0)
		, (N'ONDEMAND_TASK_QUEUE', N'Idle', 1)
		, (N'PAGEIOLATCH_DT', N'Buffer IO', 0)
		, (N'PAGEIOLATCH_EX', N'Buffer IO', 0)
		, (N'PAGEIOLATCH_KP', N'Buffer IO', 0)
		, (N'PAGEIOLATCH_NL', N'Buffer IO', 0)
		, (N'PAGEIOLATCH_SH', N'Buffer IO', 0)
		, (N'PAGEIOLATCH_UP', N'Buffer IO', 0)
		, (N'PAGELATCH_DT', N'Buffer Latch', 0)
		, (N'PAGELATCH_EX', N'Buffer Latch', 0)
		, (N'PAGELATCH_KP', N'Buffer Latch', 0)
		, (N'PAGELATCH_NL', N'Buffer Latch', 0)
		, (N'PAGELATCH_SH', N'Buffer Latch', 0)
		, (N'PAGELATCH_UP', N'Buffer Latch', 0)
		, (N'PARALLEL_REDO_DRAIN_WORKER', N'Replication', 1)
		, (N'PARALLEL_REDO_FLOW_CONTROL', N'Replication', 0)
		, (N'PARALLEL_REDO_LOG_CACHE', N'Replication', 1)
		, (N'PARALLEL_REDO_TRAN_LIST', N'Replication', 1)
		, (N'PARALLEL_REDO_TRAN_TURN', N'Replication', 1)
		, (N'PARALLEL_REDO_WORKER_SYNC', N'Replication', 1)
		, (N'PARALLEL_REDO_WORKER_WAIT_WORK', N'Replication', 1)
		, (N'POOL_LOG_RATE_GOVERNOR', N'Log Rate Governor', 0)
		, (N'POPULATE_LOCK_ORDINALS', N'Idle', 1)
		, (N'PREEMPTIVE_ABR', N'Preemptive', 0)
		, (N'PREEMPTIVE_CLOSEBACKUPMEDIA', N'Preemptive', 0)
		, (N'PREEMPTIVE_CLOSEBACKUPTAPE', N'Preemptive', 0)
		, (N'PREEMPTIVE_CLOSEBACKUPVDIDEVICE', N'Preemptive', 0)
		, (N'PREEMPTIVE_CLUSAPI_CLUSTERRESOURCECONTROL', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_COCREATEINSTANCE', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_COGETCLASSOBJECT', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_CREATEACCESSOR', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_DELETEROWS', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_GETCOMMANDTEXT', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_GETDATA', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_GETNEXTROWS', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_GETRESULT', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_GETROWSBYBOOKMARK', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_LBFLUSH', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_LBLOCKREGION', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_LBREADAT', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_LBSETSIZE', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_LBSTAT', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_LBUNLOCKREGION', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_LBWRITEAT', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_QUERYINTERFACE', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_RELEASE', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_RELEASEACCESSOR', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_RELEASEROWS', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_RELEASESESSION', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_RESTARTPOSITION', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_SEQSTRMREAD', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_SEQSTRMREADANDWRITE', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_SETDATAFAILURE', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_SETPARAMETERINFO', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_SETPARAMETERPROPERTIES', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_STRMLOCKREGION', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_STRMSEEKANDREAD', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_STRMSEEKANDWRITE', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_STRMSETSIZE', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_STRMSTAT', N'Preemptive', 0)
		, (N'PREEMPTIVE_COM_STRMUNLOCKREGION', N'Preemptive', 0)
		, (N'PREEMPTIVE_CONSOLEWRITE', N'Preemptive', 0)
		, (N'PREEMPTIVE_CREATEPARAM', N'Preemptive', 0)
		, (N'PREEMPTIVE_DEBUG', N'Preemptive', 0)
		, (N'PREEMPTIVE_DFSADDLINK', N'Preemptive', 0)
		, (N'PREEMPTIVE_DFSLINKEXISTCHECK', N'Preemptive', 0)
		, (N'PREEMPTIVE_DFSLINKHEALTHCHECK', N'Preemptive', 0)
		, (N'PREEMPTIVE_DFSREMOVELINK', N'Preemptive', 0)
		, (N'PREEMPTIVE_DFSREMOVEROOT', N'Preemptive', 0)
		, (N'PREEMPTIVE_DFSROOTFOLDERCHECK', N'Preemptive', 0)
		, (N'PREEMPTIVE_DFSROOTINIT', N'Preemptive', 0)
		, (N'PREEMPTIVE_DFSROOTSHARECHECK', N'Preemptive', 0)
		, (N'PREEMPTIVE_DTC_ABORT', N'Preemptive', 0)
		, (N'PREEMPTIVE_DTC_ABORTREQUESTDONE', N'Preemptive', 0)
		, (N'PREEMPTIVE_DTC_BEGINTRANSACTION', N'Preemptive', 0)
		, (N'PREEMPTIVE_DTC_COMMITREQUESTDONE', N'Preemptive', 0)
		, (N'PREEMPTIVE_DTC_ENLIST', N'Preemptive', 0)
		, (N'PREEMPTIVE_DTC_PREPAREREQUESTDONE', N'Preemptive', 0)
		, (N'PREEMPTIVE_FILESIZEGET', N'Preemptive', 0)
		, (N'PREEMPTIVE_FSAOLEDB_ABORTTRANSACTION', N'Preemptive', 0)
		, (N'PREEMPTIVE_FSAOLEDB_COMMITTRANSACTION', N'Preemptive', 0)
		, (N'PREEMPTIVE_FSAOLEDB_STARTTRANSACTION', N'Preemptive', 0)
		, (N'PREEMPTIVE_FSRECOVER_UNCONDITIONALUNDO', N'Preemptive', 0)
		, (N'PREEMPTIVE_GETRMINFO', N'Preemptive', 0)
		, (N'PREEMPTIVE_HADR_LEASE_MECHANISM', N'Preemptive', 1)
		, (N'PREEMPTIVE_HTTP_EVENT_WAIT', N'Preemptive', 0)
		, (N'PREEMPTIVE_HTTP_REQUEST', N'Preemptive', 0)
		, (N'PREEMPTIVE_LOCKMONITOR', N'Preemptive', 0)
		, (N'PREEMPTIVE_MSS_RELEASE', N'Preemptive', 0)
		, (N'PREEMPTIVE_ODBCOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OLE_UNINIT', N'Preemptive', 0)
		, (N'PREEMPTIVE_OLEDB_ABORTORCOMMITTRAN', N'Preemptive', 0)
		, (N'PREEMPTIVE_OLEDB_ABORTTRAN', N'Preemptive', 0)
		, (N'PREEMPTIVE_OLEDB_GETDATASOURCE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OLEDB_GETLITERALINFO', N'Preemptive', 0)
		, (N'PREEMPTIVE_OLEDB_GETPROPERTIES', N'Preemptive', 0)
		, (N'PREEMPTIVE_OLEDB_GETPROPERTYINFO', N'Preemptive', 0)
		, (N'PREEMPTIVE_OLEDB_GETSCHEMALOCK', N'Preemptive', 0)
		, (N'PREEMPTIVE_OLEDB_JOINTRANSACTION', N'Preemptive', 0)
		, (N'PREEMPTIVE_OLEDB_RELEASE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OLEDB_SETPROPERTIES', N'Preemptive', 0)
		, (N'PREEMPTIVE_OLEDBOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_ACCEPTSECURITYCONTEXT', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_ACQUIRECREDENTIALSHANDLE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_AUTHENTICATIONOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_AUTHORIZATIONOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_AUTHZGETINFORMATIONFROMCONTEXT', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_AUTHZINITIALIZECONTEXTFROMSID', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_AUTHZINITIALIZERESOURCEMANAGER', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_BACKUPREAD', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_CLOSEHANDLE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_CLUSTEROPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_COMOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_COMPLETEAUTHTOKEN', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_COPYFILE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_CREATEDIRECTORY', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_CREATEFILE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_CRYPTACQUIRECONTEXT', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_CRYPTIMPORTKEY', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_CRYPTOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_DECRYPTMESSAGE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_DELETEFILE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_DELETESECURITYCONTEXT', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_DEVICEIOCONTROL', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_DEVICEOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_DIRSVC_NETWORKOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_DISCONNECTNAMEDPIPE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_DOMAINSERVICESOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_DSGETDCNAME', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_DTCOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_ENCRYPTMESSAGE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_FILEOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_FINDFILE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_FLUSHFILEBUFFERS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_FORMATMESSAGE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_FREECREDENTIALSHANDLE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_FREELIBRARY', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_GENERICOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_GETADDRINFO', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_GETCOMPRESSEDFILESIZE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_GETDISKFREESPACE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_GETFILEATTRIBUTES', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_GETFILESIZE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_GETFINALFILEPATHBYHANDLE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_GETLONGPATHNAME', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_GETPROCADDRESS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_GETVOLUMENAMEFORVOLUMEMOUNTPOINT', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_GETVOLUMEPATHNAME', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_INITIALIZESECURITYCONTEXT', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_LIBRARYOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_LOADLIBRARY', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_LOGONUSER', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_LOOKUPACCOUNTSID', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_MESSAGEQUEUEOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_MOVEFILE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_NETGROUPGETUSERS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_NETLOCALGROUPGETMEMBERS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_NETUSERGETGROUPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_NETUSERGETLOCALGROUPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_NETUSERMODALSGET', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_NETVALIDATEPASSWORDPOLICY', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_NETVALIDATEPASSWORDPOLICYFREE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_OPENDIRECTORY', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_PDH_WMI_INIT', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_PIPEOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_PROCESSOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_QUERYCONTEXTATTRIBUTES', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_QUERYREGISTRY', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_QUERYSECURITYCONTEXTTOKEN', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_REMOVEDIRECTORY', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_REPORTEVENT', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_REVERTTOSELF', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_RSFXDEVICEOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_SECURITYOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_SERVICEOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_SETENDOFFILE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_SETFILEPOINTER', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_SETFILEVALIDDATA', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_SETNAMEDSECURITYINFO', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_SQLCLROPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_SQMLAUNCH', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_VERIFYSIGNATURE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_VERIFYTRUST', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_VSSOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_WAITFORSINGLEOBJECT', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_WINSOCKOPS', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_WRITEFILE', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_WRITEFILEGATHER', N'Preemptive', 0)
		, (N'PREEMPTIVE_OS_WSASETLASTERROR', N'Preemptive', 0)
		, (N'PREEMPTIVE_REENLIST', N'Preemptive', 0)
		, (N'PREEMPTIVE_RESIZELOG', N'Preemptive', 0)
		, (N'PREEMPTIVE_ROLLFORWARDREDO', N'Preemptive', 0)
		, (N'PREEMPTIVE_ROLLFORWARDUNDO', N'Preemptive', 0)
		, (N'PREEMPTIVE_SB_STOPENDPOINT', N'Preemptive', 0)
		, (N'PREEMPTIVE_SERVER_STARTUP', N'Preemptive', 0)
		, (N'PREEMPTIVE_SETRMINFO', N'Preemptive', 0)
		, (N'PREEMPTIVE_SHAREDMEM_GETDATA', N'Preemptive', 0)
		, (N'PREEMPTIVE_SNIOPEN', N'Preemptive', 0)
		, (N'PREEMPTIVE_SOSHOST', N'Preemptive', 0)
		, (N'PREEMPTIVE_SOSTESTING', N'Preemptive', 0)
		, (N'PREEMPTIVE_SP_SERVER_DIAGNOSTICS', N'Preemptive', 1)
		, (N'PREEMPTIVE_STARTRM', N'Preemptive', 0)
		, (N'PREEMPTIVE_STREAMFCB_CHECKPOINT', N'Preemptive', 0)
		, (N'PREEMPTIVE_STREAMFCB_RECOVER', N'Preemptive', 0)
		, (N'PREEMPTIVE_STRESSDRIVER', N'Preemptive', 0)
		, (N'PREEMPTIVE_TESTING', N'Preemptive', 0)
		, (N'PREEMPTIVE_TRANSIMPORT', N'Preemptive', 0)
		, (N'PREEMPTIVE_UNMARSHALPROPAGATIONTOKEN', N'Preemptive', 0)
		, (N'PREEMPTIVE_VSS_CREATESNAPSHOT', N'Preemptive', 0)
		, (N'PREEMPTIVE_VSS_CREATEVOLUMESNAPSHOT', N'Preemptive', 0)
		, (N'PREEMPTIVE_XE_CALLBACKEXECUTE', N'Preemptive', 0)
		, (N'PREEMPTIVE_XE_CX_FILE_OPEN', N'Preemptive', 0)
		, (N'PREEMPTIVE_XE_CX_HTTP_CALL', N'Preemptive', 0)
		, (N'PREEMPTIVE_XE_DISPATCHER', N'Preemptive', 1)
		, (N'PREEMPTIVE_XE_ENGINEINIT', N'Preemptive', 0)
		, (N'PREEMPTIVE_XE_GETTARGETSTATE', N'Preemptive', 0)
		, (N'PREEMPTIVE_XE_SESSIONCOMMIT', N'Preemptive', 0)
		, (N'PREEMPTIVE_XE_TARGETFINALIZE', N'Preemptive', 0)
		, (N'PREEMPTIVE_XE_TARGETINIT', N'Preemptive', 0)
		, (N'PREEMPTIVE_XE_TIMERRUN', N'Preemptive', 0)
		, (N'PREEMPTIVE_XETESTING', N'Preemptive', 0)
		, (N'PWAIT_HADR_ACTION_COMPLETED', N'Replication', 0)
		, (N'PWAIT_HADR_CHANGE_NOTIFIER_TERMINATION_SYNC', N'Replication', 0)
		, (N'PWAIT_HADR_CLUSTER_INTEGRATION', N'Replication', 0)
		, (N'PWAIT_HADR_FAILOVER_COMPLETED', N'Replication', 0)
		, (N'PWAIT_HADR_JOIN', N'Replication', 0)
		, (N'PWAIT_HADR_OFFLINE_COMPLETED', N'Replication', 0)
		, (N'PWAIT_HADR_ONLINE_COMPLETED', N'Replication', 0)
		, (N'PWAIT_HADR_POST_ONLINE_COMPLETED', N'Replication', 0)
		, (N'PWAIT_HADR_SERVER_READY_CONNECTIONS', N'Replication', 0)
		, (N'PWAIT_HADR_WORKITEM_COMPLETED', N'Replication', 0)
		, (N'PWAIT_HADRSIM', N'Replication', 0)
		, (N'PWAIT_RESOURCE_SEMAPHORE_FT_PARALLEL_QUERY_SYNC', N'Full Text Search', 0)
		, (N'QDS_ASYNC_QUEUE', N'Other', 1)
		, (N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', N'Other', 1)
		, (N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', N'Other', 1)
		, (N'QDS_SHUTDOWN_QUEUE', N'Other', 1)
		, (N'QUERY_TRACEOUT', N'Tracing', 0)
		, (N'REDO_THREAD_PENDING_WORK', N'Other', 1)
		, (N'REPL_CACHE_ACCESS', N'Replication', 0)
		, (N'REPL_HISTORYCACHE_ACCESS', N'Replication', 0)
		, (N'REPL_SCHEMA_ACCESS', N'Replication', 0)
		, (N'REPL_TRANFSINFO_ACCESS', N'Replication', 0)
		, (N'REPL_TRANHASHTABLE_ACCESS', N'Replication', 0)
		, (N'REPL_TRANTEXTINFO_ACCESS', N'Replication', 0)
		, (N'REPLICA_WRITES', N'Replication', 0)
		, (N'REQUEST_FOR_DEADLOCK_SEARCH', N'Idle', 1)
		, (N'RESERVED_MEMORY_ALLOCATION_EXT', N'Memory', 0)
		, (N'RESOURCE_SEMAPHORE', N'Memory', 0)
		, (N'RESOURCE_SEMAPHORE_QUERY_COMPILE', N'Compilation', 0)
		, (N'SLEEP_BPOOL_FLUSH', N'Idle', 0)
		, (N'SLEEP_BUFFERPOOL_HELPLW', N'Idle', 0)
		, (N'SLEEP_DBSTARTUP', N'Idle', 0)
		, (N'SLEEP_DCOMSTARTUP', N'Idle', 0)
		, (N'SLEEP_MASTERDBREADY', N'Idle', 0)
		, (N'SLEEP_MASTERMDREADY', N'Idle', 0)
		, (N'SLEEP_MASTERUPGRADED', N'Idle', 0)
		, (N'SLEEP_MEMORYPOOL_ALLOCATEPAGES', N'Idle', 0)
		, (N'SLEEP_MSDBSTARTUP', N'Idle', 0)
		, (N'SLEEP_RETRY_VIRTUALALLOC', N'Idle', 0)
		, (N'SLEEP_SYSTEMTASK', N'Idle', 1)
		, (N'SLEEP_TASK', N'Idle', 1)
		, (N'SLEEP_TEMPDBSTARTUP', N'Idle', 0)
		, (N'SLEEP_WORKSPACE_ALLOCATEPAGE', N'Idle', 0)
		, (N'SOS_SCHEDULER_YIELD', N'CPU', 0)
		, (N'SOS_WORK_DISPATCHER', N'Idle', 1)
		, (N'SP_SERVER_DIAGNOSTICS_SLEEP', N'Other', 1)
		, (N'SQLCLR_APPDOMAIN', N'SQL CLR', 0)
		, (N'SQLCLR_ASSEMBLY', N'SQL CLR', 0)
		, (N'SQLCLR_DEADLOCK_DETECTION', N'SQL CLR', 0)
		, (N'SQLCLR_QUANTUM_PUNISHMENT', N'SQL CLR', 0)
		, (N'SQLTRACE_BUFFER_FLUSH', N'Idle', 1)
		, (N'SQLTRACE_FILE_BUFFER', N'Tracing', 0)
		, (N'SQLTRACE_FILE_READ_IO_COMPLETION', N'Tracing', 0)
		, (N'SQLTRACE_FILE_WRITE_IO_COMPLETION', N'Tracing', 0)
		, (N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', N'Idle', 1)
		, (N'SQLTRACE_PENDING_BUFFER_WRITERS', N'Tracing', 0)
		, (N'SQLTRACE_SHUTDOWN', N'Tracing', 0)
		, (N'SQLTRACE_WAIT_ENTRIES', N'Idle', 0)
		, (N'THREADPOOL', N'Worker Thread', 0)
		, (N'TRACE_EVTNOTIF', N'Tracing', 0)
		, (N'TRACEWRITE', N'Tracing', 0)
		, (N'TRAN_MARKLATCH_DT', N'Transaction', 0)
		, (N'TRAN_MARKLATCH_EX', N'Transaction', 0)
		, (N'TRAN_MARKLATCH_KP', N'Transaction', 0)
		, (N'TRAN_MARKLATCH_NL', N'Transaction', 0)
		, (N'TRAN_MARKLATCH_SH', N'Transaction', 0)
		, (N'TRAN_MARKLATCH_UP', N'Transaction', 0)
		, (N'TRANSACTION_MUTEX', N'Transaction', 0)
		, (N'UCS_SESSION_REGISTRATION', N'Other', 1)
		, (N'WAIT_FOR_RESULTS', N'User Wait', 0)
		, (N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', N'Other', 1)
		, (N'WAITFOR', N'User Wait', 1)
		, (N'WRITE_COMPLETION', N'Other Disk IO', 0)
		, (N'WRITELOG', N'Tran Log IO', 0)
		, (N'XACT_OWN_TRANSACTION', N'Transaction', 0)
		, (N'XACT_RECLAIM_SESSION', N'Transaction', 0)
		, (N'XACTLOCKINFO', N'Transaction', 0)
		, (N'XACTWORKSPACE_MUTEX', N'Transaction', 0)
		, (N'XE_DISPATCHER_WAIT', N'Idle', 1)
		, (N'XE_LIVE_TARGET_TVF', N'Other', 1)
		, (N'XE_TIMER_EVENT', N'Idle', 1);
END;
ELSE
BEGIN
	EXECUTE sp_RaiserrorTime N'Table dbo.BlitzFirst_WaitStats_Categories already exists';
END;



IF OBJECT_ID(N'dbo.PerfmonCounters',N'U') IS NULL
BEGIN
	EXECUTE sp_RaiserrorTime N'Create dbo.PerfmonCounters';
	CREATE TABLE dbo.PerfmonCounters (
		  ID            INT IDENTITY(1,1) NOT NULL
		, object_name   NVARCHAR(128) NOT NULL
		, counter_name  NVARCHAR(128) NOT NULL
		, instance_name NVARCHAR(128) NULL

		, CONSTRAINT PK_PerfmonCounters PRIMARY KEY CLUSTERED (ID)
	);

	DECLARE @ObjName_InstancePrefix nvarchar(134);
	SELECT @ObjName_InstancePrefix = CASE
			WHEN SERVERPROPERTY('InstanceName') IS NULL THEN N'SQLServer'
			ELSE N'MSSQL$' + CAST(SERVERPROPERTY('InstanceName') AS nvarchar(128))
		END;


	INSERT dbo.PerfmonCounters (object_name, counter_name, instance_name) VALUES 
		  (@ObjName_InstancePrefix + N':Access Methods', N'Forwarded Records/sec', NULL)
		, (@ObjName_InstancePrefix + N':Access Methods', N'Page compression attempts/sec', NULL)
		, (@ObjName_InstancePrefix + N':Access Methods', N'Page Splits/sec', NULL)
		, (@ObjName_InstancePrefix + N':Access Methods', N'Skipped Ghosted Records/sec', NULL)
		, (@ObjName_InstancePrefix + N':Access Methods', N'Table Lock Escalations/sec', NULL)
		, (@ObjName_InstancePrefix + N':Access Methods', N'Worktables Created/sec', NULL)
		, (@ObjName_InstancePrefix + N':Availability Group', N'Active Hadr Threads', N'_Total')
		, (@ObjName_InstancePrefix + N':Availability Replica', N'Bytes Received from Replica/sec', N'_Total')
		, (@ObjName_InstancePrefix + N':Availability Replica', N'Bytes Sent to Replica/sec', N'_Total')
		, (@ObjName_InstancePrefix + N':Availability Replica', N'Bytes Sent to Transport/sec', N'_Total')
		, (@ObjName_InstancePrefix + N':Availability Replica', N'Flow Control Time (ms/sec)', N'_Total')
		, (@ObjName_InstancePrefix + N':Availability Replica', N'Flow Control/sec', N'_Total')
		, (@ObjName_InstancePrefix + N':Availability Replica', N'Resent Messages/sec', N'_Total')
		, (@ObjName_InstancePrefix + N':Availability Replica', N'Sends to Replica/sec', N'_Total')
		, (@ObjName_InstancePrefix + N':Buffer Manager', N'Page life expectancy', NULL)
		, (@ObjName_InstancePrefix + N':Buffer Manager', N'Page reads/sec', NULL)
		, (@ObjName_InstancePrefix + N':Buffer Manager', N'Page writes/sec', NULL)
		, (@ObjName_InstancePrefix + N':Buffer Manager', N'Readahead pages/sec', NULL)
		, (@ObjName_InstancePrefix + N':Buffer Manager', N'Target pages', NULL)
		, (@ObjName_InstancePrefix + N':Buffer Manager', N'Total pages', NULL)
		, (@ObjName_InstancePrefix + N':Databases', N'', NULL)
		, (@ObjName_InstancePrefix + N':Buffer Manager', N'Active Transactions', N'_Total')
		, (@ObjName_InstancePrefix + N':Database Replica', N'Database Flow Control Delay', N'_Total')
		, (@ObjName_InstancePrefix + N':Database Replica', N'Database Flow Controls/sec', N'_Total')
		, (@ObjName_InstancePrefix + N':Database Replica', N'Group Commit Time', N'_Total')
		, (@ObjName_InstancePrefix + N':Database Replica', N'Group Commits/Sec', N'_Total')
		, (@ObjName_InstancePrefix + N':Database Replica', N'Log Apply Pending Queue', N'_Total')
		, (@ObjName_InstancePrefix + N':Database Replica', N'Log Apply Ready Queue', N'_Total')
		, (@ObjName_InstancePrefix + N':Database Replica', N'Log Compression Cache misses/sec', N'_Total')
		, (@ObjName_InstancePrefix + N':Database Replica', N'Log remaining for undo', N'_Total')
		, (@ObjName_InstancePrefix + N':Database Replica', N'Log Send Queue', N'_Total')
		, (@ObjName_InstancePrefix + N':Database Replica', N'Recovery Queue', N'_Total')
		, (@ObjName_InstancePrefix + N':Database Replica', N'Redo blocked/sec', N'_Total')
		, (@ObjName_InstancePrefix + N':Database Replica', N'Redo Bytes Remaining', N'_Total')
		, (@ObjName_InstancePrefix + N':Database Replica', N'Redone Bytes/sec', N'_Total')
		, (@ObjName_InstancePrefix + N':Databases', N'Log Bytes Flushed/sec', N'_Total')
		, (@ObjName_InstancePrefix + N':Databases', N'Log Growths', N'_Total')
		, (@ObjName_InstancePrefix + N':Databases', N'Log Pool LogWriter Pushes/sec', N'_Total')
		, (@ObjName_InstancePrefix + N':Databases', N'Log Shrinks', N'_Total')
		, (@ObjName_InstancePrefix + N':Databases', N'Transactions/sec', NULL)
		, (@ObjName_InstancePrefix + N':Databases', N'Write Transactions/sec', NULL)
		, (@ObjName_InstancePrefix + N':Databases', N'XTP Memory Used (KB)', NULL)
		, (@ObjName_InstancePrefix + N':Exec Statistics', N'Distributed Query', N'Execs in progress')
		, (@ObjName_InstancePrefix + N':Exec Statistics', N'DTC calls', N'Execs in progress')
		, (@ObjName_InstancePrefix + N':Exec Statistics', N'Extended Procedures', N'Execs in progress')
		, (@ObjName_InstancePrefix + N':Exec Statistics', N'OLEDB calls', N'Execs in progress')
		, (@ObjName_InstancePrefix + N':General Statistics', N'Active Temp Tables', NULL)
		, (@ObjName_InstancePrefix + N':General Statistics', N'Logins/sec', NULL)
		, (@ObjName_InstancePrefix + N':General Statistics', N'Logouts/sec', NULL)
		, (@ObjName_InstancePrefix + N':General Statistics', N'Mars Deadlocks', NULL)
		, (@ObjName_InstancePrefix + N':General Statistics', N'Processes blocked', NULL)
		, (@ObjName_InstancePrefix + N':Locks', N'Number of Deadlocks/sec', NULL)
		, (@ObjName_InstancePrefix + N':Memory Manager', N'Memory Grants Pending', NULL)
		, (@ObjName_InstancePrefix + N':SQL Errors', N'Errors/sec', N'_Total')
		, (@ObjName_InstancePrefix + N':SQL Statistics', N'Batch Requests/sec', NULL)
		, (@ObjName_InstancePrefix + N':SQL Statistics', N'Forced Parameterizations/sec', NULL)
		, (@ObjName_InstancePrefix + N':SQL Statistics', N'Guided plan executions/sec', NULL)
		, (@ObjName_InstancePrefix + N':SQL Statistics', N'SQL Attention rate', NULL)
		, (@ObjName_InstancePrefix + N':SQL Statistics', N'SQL Compilations/sec', NULL)
		, (@ObjName_InstancePrefix + N':SQL Statistics', N'SQL Re-Compilations/sec', NULL)
		, (@ObjName_InstancePrefix + N':Workload Group Stats', N'Query optimizations/sec', NULL)
		, (@ObjName_InstancePrefix + N':Workload Group Stats', N'Suboptimal plans/sec', NULL)
		, (@ObjName_InstancePrefix + N':Access Methods', N'Worktables From Cache Base', NULL)
		, (@ObjName_InstancePrefix + N':Access Methods', N'Worktables From Cache Ratio', NULL)
		, (@ObjName_InstancePrefix + N':Buffer Manager', N'Database pages', NULL)
		, (@ObjName_InstancePrefix + N':Buffer Manager', N'Free pages', NULL)
		, (@ObjName_InstancePrefix + N':Buffer Manager', N'Stolen pages', NULL)
		, (@ObjName_InstancePrefix + N':Memory Manager', N'Granted Workspace Memory (KB)', NULL)
		, (@ObjName_InstancePrefix + N':Memory Manager', N'Maximum Workspace Memory (KB)', NULL)
		, (@ObjName_InstancePrefix + N':Memory Manager', N'Target Server Memory (KB)', NULL)
		, (@ObjName_InstancePrefix + N':Memory Manager', N'Total Server Memory (KB)', NULL)
		, (@ObjName_InstancePrefix + N':Buffer Manager', N'Buffer cache hit ratio', NULL)
		, (@ObjName_InstancePrefix + N':Buffer Manager', N'Buffer cache hit ratio base', NULL)
		, (@ObjName_InstancePrefix + N':Buffer Manager', N'Checkpoint pages/sec', NULL)
		, (@ObjName_InstancePrefix + N':Buffer Manager', N'Free list stalls/sec', NULL)
		, (@ObjName_InstancePrefix + N':Buffer Manager', N'Lazy writes/sec', NULL)
		, (@ObjName_InstancePrefix + N':SQL Statistics', N'Auto-Param Attempts/sec', NULL)
		, (@ObjName_InstancePrefix + N':SQL Statistics', N'Failed Auto-Params/sec', NULL)
		, (@ObjName_InstancePrefix + N':SQL Statistics', N'Safe Auto-Params/sec', NULL)
		, (@ObjName_InstancePrefix + N':SQL Statistics', N'Unsafe Auto-Params/sec', NULL)
		, (@ObjName_InstancePrefix + N':Access Methods', N'Workfiles Created/sec', NULL)
		, (@ObjName_InstancePrefix + N':General Statistics', N'User Connections', NULL)
		, (@ObjName_InstancePrefix + N':Latches', N'Average Latch Wait Time (ms)', NULL)
		, (@ObjName_InstancePrefix + N':Latches', N'Average Latch Wait Time Base', NULL)
		, (@ObjName_InstancePrefix + N':Latches', N'Latch Waits/sec', NULL)
		, (@ObjName_InstancePrefix + N':Latches', N'Total Latch Wait Time (ms)', NULL)
		, (@ObjName_InstancePrefix + N':Locks', N'Average Wait Time (ms)', NULL)
		, (@ObjName_InstancePrefix + N':Locks', N'Average Wait Time Base', NULL)
		, (@ObjName_InstancePrefix + N':Locks', N'Lock Requests/sec', NULL)
		, (@ObjName_InstancePrefix + N':Locks', N'Lock Timeouts/sec', NULL)
		, (@ObjName_InstancePrefix + N':Locks', N'Lock Wait Time (ms)', NULL)
		, (@ObjName_InstancePrefix + N':Locks', N'Lock Waits/sec', NULL)
		, (@ObjName_InstancePrefix + N':Transactions', N'Longest Transaction Running Time', NULL)
		, (@ObjName_InstancePrefix + N':Access Methods', N'Full Scans/sec', NULL)
		, (@ObjName_InstancePrefix + N':Access Methods', N'Index Searches/sec', NULL)
		, (@ObjName_InstancePrefix + N':Buffer Manager', N'Page lookups/sec', NULL)
		, (@ObjName_InstancePrefix + N':Cursor Manager by Type', N'Active cursors', NULL)
		, (N'SQL Server 2014 XTP Cursors', N'Expired rows removed/sec', NULL)
		, (N'SQL Server 2014 XTP Cursors', N'Expired rows touched/sec', NULL)
		, (N'SQL Server 2014 XTP Garbage Collection', N'Rows processed/sec', NULL)
		, (N'SQL Server 2014 XTP IO Governor', N'Io Issued/sec', NULL)
		, (N'SQL Server 2014 XTP Phantom Processor', N'Phantom expired rows touched/sec', NULL)
		, (N'SQL Server 2014 XTP Phantom Processor', N'Phantom rows touched/sec', NULL)
		, (N'SQL Server 2014 XTP Transaction Log', N'Log bytes written/sec', NULL)
		, (N'SQL Server 2014 XTP Transaction Log', N'Log records written/sec', NULL)
		, (N'SQL Server 2014 XTP Transactions', N'Transactions aborted by user/sec', NULL)
		, (N'SQL Server 2014 XTP Transactions', N'Transactions aborted/sec', NULL)
		, (N'SQL Server 2014 XTP Transactions', N'Transactions created/sec', NULL)
		, (N'SQL Server 2016 XTP Cursors', N'Expired rows removed/sec', NULL)
		, (N'SQL Server 2016 XTP Cursors', N'Expired rows touched/sec', NULL)
		, (N'SQL Server 2016 XTP Garbage Collection', N'Rows processed/sec', NULL)
		, (N'SQL Server 2016 XTP IO Governor', N'Io Issued/sec', NULL)
		, (N'SQL Server 2016 XTP Phantom Processor', N'Phantom expired rows touched/sec', NULL)
		, (N'SQL Server 2016 XTP Phantom Processor', N'Phantom rows touched/sec', NULL)
		, (N'SQL Server 2016 XTP Transaction Log', N'Log bytes written/sec', NULL)
		, (N'SQL Server 2016 XTP Transaction Log', N'Log records written/sec', NULL)
		, (N'SQL Server 2016 XTP Transactions', N'Transactions aborted by user/sec', NULL)
		, (N'SQL Server 2016 XTP Transactions', N'Transactions aborted/sec', NULL)
		, (N'SQL Server 2016 XTP Transactions', N'Transactions created/sec', NULL)
		, (N'SQL Server 2017 XTP Cursors', N'Expired rows removed/sec', NULL)
		, (N'SQL Server 2017 XTP Cursors', N'Expired rows touched/sec', NULL)
		, (N'SQL Server 2017 XTP Garbage Collection', N'Rows processed/sec', NULL)
		, (N'SQL Server 2017 XTP IO Governor', N'Io Issued/sec', NULL)
		, (N'SQL Server 2017 XTP Phantom Processor', N'Phantom expired rows touched/sec', NULL)
		, (N'SQL Server 2017 XTP Phantom Processor', N'Phantom rows touched/sec', NULL)
		, (N'SQL Server 2017 XTP Transaction Log', N'Log bytes written/sec', NULL)
		, (N'SQL Server 2017 XTP Transaction Log', N'Log records written/sec', NULL)
		, (N'SQL Server 2017 XTP Transactions', N'Transactions aborted by user/sec', NULL)
		, (N'SQL Server 2017 XTP Transactions', N'Transactions aborted/sec', NULL)
		, (N'SQL Server 2017 XTP Transactions', N'Transactions created/sec', NULL);
END;
ELSE
BEGIN
	EXECUTE sp_RaiserrorTime N'Table dbo.PerfmonCounters already exists';
END;

GO








/*=======================================================================
==// Disable the BlitzFirst job that logs metrics                    //==
=======================================================================*/
USE msdb;
GO


IF EXISTS (SELECT 1 FROM dbo.sysjobs where name=N'DBA - Log BlitzFirst to Table')
BEGIN
	EXECUTE sp_RaiserrorTime N'Disable job DBA - Log BlitzFirst to Table';
	EXECUTE dbo.sp_update_job @job_name = 'DBA - Log BlitzFirst to Table', @enabled  = 0;
END;
ELSE
BEGIN
	EXECUTE sp_RaiserrorTime N'Job [DBA - Log BlitzFirst to Table] does not exists...no need to disable it.';
END;
GO








/*=======================================================================
==// Copy over historical records from the BlitzFirst logging tables //==
=======================================================================*/

USE CentralAdmin;
GO


IF OBJECT_ID(N'dbo.BlitzFirst_WaitStats',N'U') IS NOT NULL
BEGIN
	EXECUTE sp_RaiserrorTime N'Copying data from dbo.BlitzFirst_WaitStats into dbo.WaitStats';
	INSERT INTO dbo.WaitStats (
		  ServerName
		, CheckDate
		, wait_type
		, wait_time_ms
		, signal_wait_time_ms
		, waiting_tasks_count
	)
	SELECT
		  x.ServerName
		, x.CheckDate
		, x.wait_type
		, x.wait_time_ms
		, x.signal_wait_time_ms
		, x.waiting_tasks_count
	FROM
		dbo.BlitzFirst_WaitStats x
	WHERE
		x.CheckDate >= DATEADD(DAY, -100, SYSDATETIMEOFFSET())
		AND NOT EXISTS (
			SELECT
				1
			FROM
				dbo.WaitStats y
			WHERE
				y.ServerName = x.ServerName
				AND y.CheckDate = x.CheckDate
				AND y.wait_type = x.wait_type
				AND y.wait_time_ms = x.wait_time_ms
				AND y.signal_wait_time_ms = x.signal_wait_time_ms
				AND y.waiting_tasks_count = x.waiting_tasks_count
		)
	ORDER BY
		x.ID;
END;
ELSE
BEGIN
	EXECUTE sp_RaiserrorTime N'Table dbo.BlitzFirst_WaitStats does not exists...no need to copy data from it.';
END;


IF OBJECT_ID(N'dbo.BlitzFirst_PerfmonStats',N'U') IS NOT NULL
BEGIN
	EXECUTE sp_RaiserrorTime N'Copying data from dbo.BlitzFirst_PerfmonStats into dbo.PerfmonStats';
	INSERT INTO dbo.PerfmonStats (
		  ServerName
		, CheckDate
		, object_name
		, counter_name
		, instance_name
		, cntr_value
	)
	SELECT
		  x.ServerName
		, x.CheckDate
		, x.object_name
		, x.counter_name
		, x.instance_name
		, x.cntr_value
	FROM
		dbo.BlitzFirst_PerfmonStats x
	WHERE
		x.CheckDate >= DATEADD(DAY, -100, SYSDATETIMEOFFSET())
		AND NOT EXISTS (
			SELECT
				1
			FROM
				dbo.PerfmonStats y
			WHERE
				y.ServerName = x.ServerName
				AND y.CheckDate = x.CheckDate
				AND y.object_name = x.object_name
				AND y.counter_name = x.counter_name
				AND y.instance_name = x.instance_name
				AND y.cntr_value = x.cntr_value
		)
	ORDER BY
		x.ID;
END;
ELSE
BEGIN
	EXECUTE sp_RaiserrorTime N'Table dbo.BlitzFirst_PerfmonStats does not exists...no need to copy data from it.';
END;

GO








/*=======================================================================
==// Create the job to log Wait Stats and Perfmon Stats              //==
=======================================================================*/

USE msdb;
GO


DECLARE
	  @myJobName      NVARCHAR(128)
	, @myDescription  NVARCHAR(512)
	-- , @myOperator     NVARCHAR(128)
	, @myOwner        NVARCHAR(128)
	, @myScheduleName NVARCHAR(128)
	, @myDatabaseName NVARCHAR(128)
	, @myServer       NVARCHAR(128)
	, @myStepId       INT = 0
	, @myStepName     NVARCHAR(128);



/* USER INPUT */
SET @myJobName      = N'DBA - Log Wait and Perfmon Stats';
SET @myDescription  = N'Log Wait Stats and Perfmon Stats';
SET @myDatabaseName = N'CentralAdmin';
SET @myScheduleName = @myJobName + N' Schedule';
SET @myServer       = @@SERVERNAME;

/* NOTE: you must enter @step_name in each sp_add_jobstep */





/* GET CONFIGURATION VALUES */

-- SELECT TOP(1) @myOperator = name
-- FROM   dbo.sysoperators
-- WHERE  email_address IN ('IT.MSSQL.Admins@plexus.com','penang_dba@plexus.com');

SELECT @myOwner = name
FROM   sys.server_principals
WHERE  principal_id = 1;



/* CREATE THE JOB */

EXECUTE sp_RaiserrorTime N'Create job DBA - Log Wait and Perfmon Stats';
IF EXISTS(SELECT 1 FROM dbo.sysjobs WHERE name = @myJobName)
	EXECUTE dbo.sp_delete_job @job_name = @myJobName, @delete_unused_schedule = 1;


EXECUTE dbo.sp_add_job
	  @job_name                   = @myJobName
	, @enabled                    = 1
	, @notify_level_eventlog      = 0
	, @notify_level_email         = 2 /* 0 = Never, 1 = On success, 2 = On failure, 3 = Always */
	, @notify_level_netsend       = 2
	, @notify_level_page          = 2
	, @delete_level               = 0
	--, @notify_email_operator_name = @myOperator
	, @description                = @myDescription
	, @owner_login_name           = @myOwner;

EXECUTE dbo.sp_add_jobserver
	  @job_name = @myJobName
	, @server_name = @myServer;




/* Add Job Steps */

/* Step 1 */
EXECUTE sp_RaiserrorTime N'Add step 1';
SET @myStepId = @myStepId + 1;
SET @myStepName = N'Log Wait Stats';
EXECUTE dbo.sp_add_jobstep
	  @job_name             = @myJobName
	, @step_name            = @myStepName
	, @step_id              = @myStepId
	, @cmdexec_success_code = 0
	, @on_success_action    = 3  /* 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_success_step_id */
	, @on_fail_action       = 2  /* 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_fail_step_id */
	, @retry_attempts       = 0
	, @retry_interval       = 0  /* minutes */
	, @os_run_priority      = 0
	, @database_name        = @myDatabaseName
	, @flags                = 0
	, @subsystem            = N'TSQL'
	, @command              = N'
WITH
	  CombinedTasksAndStats AS (
		SELECT  
			  @@SERVERNAME AS ServerName
			, SYSDATETIMEOFFSET() AS CheckDate
			, t.wait_type
			, SUM(t.wait_duration_ms) OVER (PARTITION BY t.wait_type, t.session_id) AS wait_time_ms
			, 0 AS signal_wait_time_ms
			, 0 AS waiting_tasks_count
		FROM
			sys.dm_os_waiting_tasks t
		WHERE
			t.session_id > 50
			AND t.wait_duration_ms >= 0
		UNION ALL
		SELECT
			  @@SERVERNAME AS ServerName
			, SYSDATETIMEOFFSET() AS CheckDate
			, s.wait_type
			, SUM(s.wait_time_ms) OVER (PARTITION BY s.wait_type) AS wait_time_ms
			, SUM(s.signal_wait_time_ms) OVER (PARTITION BY s.wait_type ) AS signal_wait_time_ms
			, SUM(s.waiting_tasks_count) OVER (PARTITION BY s.wait_type) AS waiting_tasks_count
		FROM
			sys.dm_os_wait_stats s
		WHERE
			s.wait_time_ms > 0
	  )
INSERT INTO dbo.WaitStats (
	  ServerName
	, CheckDate
	, wait_type
	, wait_time_ms
	, signal_wait_time_ms
	, waiting_tasks_count
)
SELECT
	  @@SERVERNAME
	, SYSDATETIMEOFFSET()
	, c.wait_type
	, SUM(c.wait_time_ms)
	, SUM(c.signal_wait_time_ms)
	, SUM(c.waiting_tasks_count)
FROM
	CombinedTasksAndStats c
GROUP BY
	c.wait_type;
';



/* Step 2 */
EXECUTE sp_RaiserrorTime N'Add step 2';
SET @myStepId = @myStepId + 1;
SET @myStepName = N'Log Perfmon Stats';
EXECUTE dbo.sp_add_jobstep
	  @job_name             = @myJobName
	, @step_name            = @myStepName
	, @step_id              = @myStepId
	, @cmdexec_success_code = 0
	, @on_success_action    = 3  /* 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_success_step_id */
	, @on_fail_action       = 2  /* 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_fail_step_id */
	, @retry_attempts       = 0
	, @retry_interval       = 0  /* minutes */
	, @os_run_priority      = 0
	, @database_name        = @myDatabaseName
	, @flags                = 0
	, @subsystem            = N'TSQL'
	, @command              = N'
INSERT INTO dbo.PerfmonStats (
	  ServerName
	, CheckDate
	, object_name
	, counter_name
	, instance_name
	, cntr_value
)
SELECT
	  @@SERVERNAME AS ServerName
	, SYSDATETIMEOFFSET() AS CheckDate
	, RTRIM(dmv.object_name)
	, RTRIM(dmv.counter_name)
	, RTRIM(dmv.instance_name)
	, dmv.cntr_value
FROM
	dbo.PerfmonCounters counters
INNER JOIN
	sys.dm_os_performance_counters dmv ON
		counters.counter_name COLLATE SQL_Latin1_General_CP1_CI_AS = RTRIM(dmv.counter_name) COLLATE SQL_Latin1_General_CP1_CI_AS
		AND counters.object_name COLLATE SQL_Latin1_General_CP1_CI_AS = RTRIM(dmv.object_name) COLLATE SQL_Latin1_General_CP1_CI_AS
		AND (
			counters.instance_name IS NULL
			OR counters.instance_name COLLATE SQL_Latin1_General_CP1_CI_AS = RTRIM(dmv.instance_name) COLLATE SQL_Latin1_General_CP1_CI_AS
		);
';



/* Step 3 */
EXECUTE sp_RaiserrorTime N'Add step 3';
SET @myStepId = @myStepId + 1;
SET @myStepName = N'Log Latch Stats';
EXECUTE dbo.sp_add_jobstep
	  @job_name             = @myJobName
	, @step_name            = @myStepName
	, @step_id              = @myStepId
	, @cmdexec_success_code = 0
	, @on_success_action    = 3  /* 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_success_step_id */
	, @on_fail_action       = 2  /* 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_fail_step_id */
	, @retry_attempts       = 0
	, @retry_interval       = 0  /* minutes */
	, @os_run_priority      = 0
	, @database_name        = @myDatabaseName
	, @flags                = 0
	, @subsystem            = N'TSQL'
	, @command              = N'
INSERT INTO dbo.LatchStats (
	  ServerName
	, CheckDate
	, latch_class
	, waiting_requests_count
	, wait_time_ms
	, max_wait_time_ms
)
SELECT
	  @@SERVERNAME AS ServerName
	, SYSDATETIMEOFFSET() AS CheckDate
	, latch_class
	, waiting_requests_count
	, wait_time_ms
	, max_wait_time_ms
FROM
	sys.dm_os_latch_stats;
';



/* Step 4 */
EXECUTE sp_RaiserrorTime N'Add step 4';
SET @myStepId = @myStepId + 1;
SET @myStepName = N'Purge Old Wait Stats';
EXECUTE dbo.sp_add_jobstep
	  @job_name             = @myJobName
	, @step_name            = @myStepName
	, @step_id              = @myStepId
	, @cmdexec_success_code = 0
	, @on_success_action    = 3  /* 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_success_step_id */
	, @on_fail_action       = 2  /* 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_fail_step_id */
	, @retry_attempts       = 0
	, @retry_interval       = 0  /* minutes */
	, @os_run_priority      = 0
	, @database_name        = @myDatabaseName
	, @flags                = 0
	, @subsystem            = N'TSQL'
	, @command              = N'
DELETE FROM
	dbo.WaitStats
WHERE
	CheckDate < DATEADD(DAY, -100, SYSDATETIMEOFFSET());
';



/* Step 5 */
EXECUTE sp_RaiserrorTime N'Add step 5';
SET @myStepId = @myStepId + 1;
SET @myStepName = N'Purge Old Perfmon Stats';
EXECUTE dbo.sp_add_jobstep
	  @job_name             = @myJobName
	, @step_name            = @myStepName
	, @step_id              = @myStepId
	, @cmdexec_success_code = 0
	, @on_success_action    = 3  /* 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_success_step_id */
	, @on_fail_action       = 2  /* 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_fail_step_id */
	, @retry_attempts       = 0
	, @retry_interval       = 0  /* minutes */
	, @os_run_priority      = 0
	, @database_name        = @myDatabaseName
	, @flags                = 0
	, @subsystem            = N'TSQL'
	, @command              = N'
DELETE FROM
	dbo.PerfmonStats
WHERE
	CheckDate < DATEADD(DAY, -100, SYSDATETIMEOFFSET());
';



/* Step 6 */
EXECUTE sp_RaiserrorTime N'Add step 6';
SET @myStepId = @myStepId + 1;
SET @myStepName = N'Purge Old Latch Stats';
EXECUTE dbo.sp_add_jobstep
	  @job_name             = @myJobName
	, @step_name            = @myStepName
	, @step_id              = @myStepId
	, @cmdexec_success_code = 0
	, @on_success_action    = 1  /* 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_success_step_id */
	, @on_fail_action       = 2  /* 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_fail_step_id */
	, @retry_attempts       = 0
	, @retry_interval       = 0  /* minutes */
	, @os_run_priority      = 0
	, @database_name        = @myDatabaseName
	, @flags                = 0
	, @subsystem            = N'TSQL'
	, @command              = N'
DELETE FROM
	dbo.LatchStats
WHERE
	CheckDate < DATEADD(DAY, -100, SYSDATETIMEOFFSET());
';



/* Final Job Configurations */

EXECUTE dbo.sp_update_job
	  @job_name = @myJobName
	, @start_step_id = 1;



/* CREATE THE SCHEDULE */

EXECUTE sp_RaiserrorTime N'Create job schedule';
EXECUTE dbo.sp_add_jobschedule
	  @job_name               = @myJobName
	, @name                   = @myScheduleName
	, @enabled                = 1
	, @freq_type              = 4  /* 1 = Once, 4 = Daily, 8 = Weekly, 16 = Monthly, 32 = Monthly, relative to frequency_interval, 64 = Run when the SQL Server Agent service starts, 128 = Run when teh computer is idle */
	, @freq_interval          = 1
	, @freq_subday_type       = 4  /* 1 = At specified time, 4 = Minutes, 8 = Hours */
	, @freq_subday_interval   = 15
	, @freq_relative_interval = 0  /* 1 = First, 2 = Second, 4 = Third, 8 = Fourth, 16 = Last */
	, @freq_recurrence_factor = 0  /* Number of weeks or months between the scheduled execution of the job */
	, @active_start_date      = 20250214
	, @active_end_date        = 99991231
	, @active_start_time      = 0
	, @active_end_time        = 235959;

GO





/* VERIFICATION */

USE CentralAdmin;
WITH MyTableList AS (
	          SELECT N'dbo' AS SchemaName, N'WaitStats' AS TableName
	UNION ALL SELECT N'dbo' AS SchemaName, N'PerfmonStats' AS TableName
	UNION ALL SELECT N'dbo' AS SchemaName, N'BlitzFirst_WaitStats_Categories' AS TableName
	UNION ALL SELECT N'dbo' AS SchemaName, N'PerfmonCounters' AS TableName
)
SELECT
	  'Do my tables exist?' AS Verification_Description
	, m.SchemaName + N'.' + m.TableName AS MyList
	, SCHEMA_NAME(t.schema_id) + N'.' + t.name AS ExistingTables
FROM MyTableList m
LEFT OUTER JOIN sys.tables t ON t.schema_id=SCHEMA_ID(m.SchemaName) AND t.name=m.TableName
ORDER BY 1;


SELECT 'What is in dbo.BlitzFirst_WaitStats_Categories?' AS Verification_Description, * FROM dbo.BlitzFirst_WaitStats_Categories;
SELECT 'What is in dbo.PerfmonCounters?' AS Verification_Description, * FROM dbo.PerfmonCounters;

USE msdb;
SELECT 'Does the job, DBA - Log Wait and Perfmon Stats, exist?' AS Verification_Description, j.name, s.step_name, s.step_id
FROM dbo.sysjobs j
INNER JOIN dbo.sysjobsteps s on s.job_id=j.job_id
WHERE j.name='DBA - Log Wait and Perfmon Stats'
ORDER BY s.step_id;