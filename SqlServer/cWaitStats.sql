




DECLARE @SampleSeconds INT = 60;





/* Store data from start and end of sample time */
DROP TABLE IF EXISTS #WaitStats1;
CREATE TABLE #WaitStats1 (
	  event_time DATETIMEOFFSET
	, wait_type NVARCHAR(60)
	, sum_wait_time_ms BIGINT
	, sum_signal_wait_time_ms BIGINT
	, sum_waiting_tasks BIGINT
);

DROP TABLE IF EXISTS #WaitStats2;
CREATE TABLE #WaitStats2 (
	  event_time DATETIMEOFFSET
	, wait_type NVARCHAR(60)
	, sum_wait_time_ms BIGINT
	, sum_signal_wait_time_ms BIGINT
	, sum_waiting_tasks BIGINT
);






/* get first set of data */
WITH
	UnionedWaits AS (
		SELECT  
			  t.wait_type
			, SUM(t.wait_duration_ms) OVER (PARTITION BY t.wait_type, t.session_id) AS sum_wait_time_ms
			, 0 AS sum_signal_wait_time_ms
			, 0 AS sum_waiting_tasks
		FROM
			sys.dm_os_waiting_tasks t
		WHERE
			t.session_id > 50
			AND t.wait_duration_ms >= 0
		UNION ALL
		SELECT
			  s.wait_type
			, SUM(s.wait_time_ms) OVER (PARTITION BY s.wait_type) AS sum_wait_time_ms
			, SUM(s.signal_wait_time_ms) OVER (PARTITION BY s.wait_type ) AS sum_signal_wait_time_ms
			, SUM(s.waiting_tasks_count) OVER (PARTITION BY s.wait_type) AS sum_waiting_tasks
		FROM
			sys.dm_os_wait_stats s
	)
INSERT INTO
	#WaitStats1 (
		  event_time
		, wait_type
		, sum_wait_time_ms
		, sum_signal_wait_time_ms
		, sum_waiting_tasks
	)
SELECT 
	  SYSDATETIMEOFFSET()
	, w.wait_type
	, SUM(w.sum_wait_time_ms) AS sum_wait_time_ms
	, SUM(w.sum_signal_wait_time_ms) AS sum_signal_wait_time_ms
	, SUM(w.sum_waiting_tasks) AS sum_waiting_tasks
FROM
	UnionedWaits w
WHERE
	/* Inorable Wait Types (according to sp_BlitsFirst) */
	w.wait_type NOT IN ('BROKER_EVENTHANDLER','BROKER_RECEIVE_WAITFOR','BROKER_TASK_STOP','BROKER_TO_FLUSH','BROKER_TRANSMITTER','CHECKPOINT_QUEUE','CLR_AUTO_EVENT','CLR_MANUAL_EVENT','CLR_SEMAPHORE','DBMIRROR_DBM_EVENT','DBMIRROR_DBM_MUTEX','DBMIRROR_EVENTS_QUEUE','DBMIRROR_WORKER_QUEUE','DBMIRRORING_CMD','DIRTY_PAGE_POLL','DISPATCHER_QUEUE_SEMAPHORE','FT_IFTS_SCHEDULER_IDLE_WAIT','FT_IFTSHC_MUTEX','FT_IFTSISM_MUTEX','HADR_CLUSAPI_CALL','HADR_FABRIC_CALLBACK','HADR_FILESTREAM_IOMGR_IOCOMPLETION','HADR_LOGCAPTURE_WAIT','HADR_NOTIFICATION_DEQUEUE','HADR_TIMER_TASK','HADR_WORK_QUEUE','LAZYWRITER_SLEEP','LOGMGR_QUEUE','ONDEMAND_TASK_QUEUE','PARALLEL_REDO_DRAIN_WORKER','PARALLEL_REDO_LOG_CACHE','PARALLEL_REDO_TRAN_LIST','PARALLEL_REDO_TRAN_TURN','PARALLEL_REDO_WORKER_SYNC','PARALLEL_REDO_WORKER_WAIT_WORK','POPULATE_LOCK_ORDINALS','PREEMPTIVE_HADR_LEASE_MECHANISM','PREEMPTIVE_SP_SERVER_DIAGNOSTICS','PREEMPTIVE_XE_DISPATCHER','QDS_ASYNC_QUEUE','QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP','QDS_PERSIST_TASK_MAIN_LOOP_SLEEP','QDS_SHUTDOWN_QUEUE','REDO_THREAD_PENDING_WORK','REQUEST_FOR_DEADLOCK_SEARCH','SLEEP_SYSTEMTASK','SLEEP_TASK','SOS_WORK_DISPATCHER','SP_SERVER_DIAGNOSTICS_SLEEP','SQLTRACE_BUFFER_FLUSH','SQLTRACE_INCREMENTAL_FLUSH_SLEEP','UCS_SESSION_REGISTRATION','WAIT_XTP_OFFLINE_CKPT_NEW_LOG','WAITFOR','XE_DISPATCHER_WAIT','XE_LIVE_TARGET_TVF','XE_TIMER_EVENT')
GROUP BY
	w.wait_type;






/* Wait for the indicated sample duration */
DECLARE @Delay DATETIME;
SELECT @Delay = DATEADD(SECOND, @SampleSeconds, CONVERT(DATETIME, 0));
WAITFOR DELAY @SampleSeconds;






/* get second set of data */
WITH
	UnionedWaits AS (
		SELECT  
			  t.wait_type
			, SUM(t.wait_duration_ms) OVER (PARTITION BY t.wait_type, t.session_id) AS sum_wait_time_ms
			, 0 AS sum_signal_wait_time_ms
			, 0 AS sum_waiting_tasks
		FROM
			sys.dm_os_waiting_tasks t
		WHERE
			t.session_id > 50
			AND t.wait_duration_ms >= 0
		UNION ALL
		SELECT
			  s.wait_type
			, SUM(s.wait_time_ms) OVER (PARTITION BY s.wait_type) AS sum_wait_time_ms
			, SUM(s.signal_wait_time_ms) OVER (PARTITION BY s.wait_type ) AS sum_signal_wait_time_ms
			, SUM(s.waiting_tasks_count) OVER (PARTITION BY s.wait_type) AS sum_waiting_tasks
		FROM
			sys.dm_os_wait_stats s
	)
INSERT INTO
	#WaitStats2 (
		  event_time
		, wait_type
		, sum_wait_time_ms
		, sum_signal_wait_time_ms
		, sum_waiting_tasks
	)
SELECT 
	  SYSDATETIMEOFFSET()
	, w.wait_type
	, SUM(w.sum_wait_time_ms) AS sum_wait_time_ms
	, SUM(w.sum_signal_wait_time_ms) AS sum_signal_wait_time_ms
	, SUM(w.sum_waiting_tasks) AS sum_waiting_tasks
FROM
	UnionedWaits w
WHERE
	/* Inorable Wait Types (according to sp_BlitsFirst) */
	w.wait_type NOT IN ('BROKER_EVENTHANDLER','BROKER_RECEIVE_WAITFOR','BROKER_TASK_STOP','BROKER_TO_FLUSH','BROKER_TRANSMITTER','CHECKPOINT_QUEUE','CLR_AUTO_EVENT','CLR_MANUAL_EVENT','CLR_SEMAPHORE','DBMIRROR_DBM_EVENT','DBMIRROR_DBM_MUTEX','DBMIRROR_EVENTS_QUEUE','DBMIRROR_WORKER_QUEUE','DBMIRRORING_CMD','DIRTY_PAGE_POLL','DISPATCHER_QUEUE_SEMAPHORE','FT_IFTS_SCHEDULER_IDLE_WAIT','FT_IFTSHC_MUTEX','FT_IFTSISM_MUTEX','HADR_CLUSAPI_CALL','HADR_FABRIC_CALLBACK','HADR_FILESTREAM_IOMGR_IOCOMPLETION','HADR_LOGCAPTURE_WAIT','HADR_NOTIFICATION_DEQUEUE','HADR_TIMER_TASK','HADR_WORK_QUEUE','LAZYWRITER_SLEEP','LOGMGR_QUEUE','ONDEMAND_TASK_QUEUE','PARALLEL_REDO_DRAIN_WORKER','PARALLEL_REDO_LOG_CACHE','PARALLEL_REDO_TRAN_LIST','PARALLEL_REDO_TRAN_TURN','PARALLEL_REDO_WORKER_SYNC','PARALLEL_REDO_WORKER_WAIT_WORK','POPULATE_LOCK_ORDINALS','PREEMPTIVE_HADR_LEASE_MECHANISM','PREEMPTIVE_SP_SERVER_DIAGNOSTICS','PREEMPTIVE_XE_DISPATCHER','QDS_ASYNC_QUEUE','QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP','QDS_PERSIST_TASK_MAIN_LOOP_SLEEP','QDS_SHUTDOWN_QUEUE','REDO_THREAD_PENDING_WORK','REQUEST_FOR_DEADLOCK_SEARCH','SLEEP_SYSTEMTASK','SLEEP_TASK','SOS_WORK_DISPATCHER','SP_SERVER_DIAGNOSTICS_SLEEP','SQLTRACE_BUFFER_FLUSH','SQLTRACE_INCREMENTAL_FLUSH_SLEEP','UCS_SESSION_REGISTRATION','WAIT_XTP_OFFLINE_CKPT_NEW_LOG','WAITFOR','XE_DISPATCHER_WAIT','XE_LIVE_TARGET_TVF','XE_TIMER_EVENT')
GROUP BY
	w.wait_type;






/* Display Results */
DECLARE
	  @cores INT
	, @StartTime DATETIMEOFFSET
	, @EndTime DATETIMEOFFSET;

SELECT @cores = SUM(1) FROM sys.dm_os_schedulers WHERE status = 'VISIBLE ONLINE' AND is_online = 1;
SELECT TOP(1) @StartTime=event_time FROM #WaitStats1;
SELECT TOP(1) @EndTime=event_time FROM #WaitStats2;

SELECT
	  @EndTime AS [Sample Ended]
	, CAST(ROUND(DATEDIFF(MILLISECOND, @StartTime, @EndTime) / 1000.0, 1) AS DECIMAL(18,1)) AS [Seconds Sample]
	, a.wait_type
	, c.WaitCategory AS wait_category
	, CAST(ROUND((b.sum_wait_time_ms - a.sum_wait_time_ms) / 1000.0, 1) AS DECIMAL(18,1)) AS [Wait Time (Seconds)]
	, CAST(ROUND((b.sum_wait_time_ms - a.sum_wait_time_ms) * 1.0 / DATEDIFF(MILLISECOND, @StartTime, @EndTime) / @cores, 1) AS DECIMAL(18,1)) AS [Per Core Per Second]	
	, CAST(ROUND((b.sum_signal_wait_time_ms - a.sum_signal_wait_time_ms) / 1000.0, 1) AS DECIMAL(18,1)) AS [Signal Wait Time (Seconds)]
	, CASE
		WHEN b.sum_waiting_tasks = a.sum_waiting_tasks THEN 0.0
		ELSE CAST(ROUND((b.sum_signal_wait_time_ms - a.sum_signal_wait_time_ms) * 1.0 / (b.sum_wait_time_ms - a.sum_wait_time_ms) * 100.0, 1) AS DECIMAL(18,1))
	  END AS [Percent Signal Waits]
	, b.sum_waiting_tasks - a.sum_waiting_tasks AS [Number of Waits]
	, CASE
		WHEN b.sum_waiting_tasks = a.sum_waiting_tasks THEN 0.0
		ELSE CAST(ROUND((b.sum_wait_time_ms - a.sum_wait_time_ms) * 1.0 / (b.sum_waiting_tasks - a.sum_waiting_tasks), 1) AS DECIMAL(18,1))
	  END AS [Avg ms Per Wait]
FROM
	#WaitStats1 a
INNER JOIN
	#WaitStats2 b ON b.wait_type=a.wait_type
INNER JOIN
	CentralAdmin.dbo.BlitzFirst_WaitStats_Categories c ON c.WaitType=a.wait_type
WHERE
	a.sum_wait_time_ms <> b.sum_wait_time_ms
	OR a.sum_signal_wait_time_ms <> b.sum_signal_wait_time_ms
ORDER BY
	[Wait Time (Seconds)] DESC;






/* Clean Up */
DROP TABLE IF EXISTS #WaitStats1;
DROP TABLE IF EXISTS #WaitStats2;
