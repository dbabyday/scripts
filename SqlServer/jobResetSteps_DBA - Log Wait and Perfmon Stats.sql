USE msdb;
GO



DECLARE
	  @myJobName      nvarchar(128) = N'DBA - Log Wait and Perfmon Stats'
	, @myDatabaseName nvarchar(128) = N'CentralAdmin'
	, @myStepId       int = 0
	, @myStepName     nvarchar(128)
	, @sqlStmt        nvarchar(max);




/* Create logging table */

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






/* Delete job steps */

SELECT @myStepId = MAX(step_id) FROM dbo.sysjobsteps WHERE job_id = (SELECT job_id FROM dbo.sysjobs WHERE name=@myJobName);
WHILE @myStepId > 0
BEGIN
	SET @sqlStmt = N'EXECUTE /* jobResetSteps_DBA - Log Wait and Perfmon Stats */ dbo.sp_delete_jobstep @job_name=@myJobName, @step_id=@myStepId;';
	EXECUTE sp_RaiserrorTime @sqlStmt;
	EXECUTE sp_executesql
		  @sqlStmt
		, N'@myJobName nvarchar(128), @myStepId int'
		, @myJobName=@myJobName, @myStepId=@myStepId;
	SET @myStepId = @myStepId - 1;
END;








/* Add Job Steps */
SET @myStepId = 0;

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




GO
