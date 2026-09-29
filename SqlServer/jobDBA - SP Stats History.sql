/*

jobDBA - SP Stats History.sql

Author: dbabyday
Date: 2024-12-11

Description: Create a SQL Server Agent job that logs stored procedure statistics every 5 minutes

Date        Name                  Description of change
----------  --------------------  ---------------------------------------------------------------------------------


*/




/* USER INPUT */
DROP TABLE IF EXISTS #Databases;
CREATE TABLE #Databases (name sysname);
INSERT INTO #Databases (name) VALUES 
	(N'PutYourDB1NameHere'), (N'PutYourDB2NameHere');
	

IF EXISTS (SELECT 1 FROM #Databases WHERE name IN (N'PutYourDB1NameHere',N'PutYourDB2NameHere'))
BEGIN
	RAISERROR(N'You must enter the database name(s) you want to log results for, into #Databases',16,1) WITH NOWAIT;
	RETURN;
END;







USE CentralAdmin;


CREATE TABLE dbo.dm_exec_procedure_stats_hist (
	  id bigint IDENTITY(1,1) NOT NULL
	, entry_id bigint NULL
	, entry_time datetimeoffset(7) NULL
	, database_name nvarchar(128) NULL
	, schema_name nvarchar(128) NULL
	, object_name nvarchar(128) NULL
	, type char(2) NULL
	, type_desc nvarchar(60) NULL
	, sql_handle varbinary(64) NULL
	, plan_handle varbinary(64) NULL
	, cached_time datetime NULL
	, last_execution_time datetime NULL
	, execution_count bigint NULL
	, execution_count_delta bigint NULL
	, total_worker_time bigint NULL
	, avg_worker_time bigint NULL
	, last_worker_time bigint NULL
	, min_worker_time bigint NULL
	, max_worker_time bigint NULL
	, total_physical_reads bigint NULL
	, avg_physical_reads bigint NULL
	, last_physical_reads bigint NULL
	, min_physical_reads bigint NULL
	, max_physical_reads bigint NULL
	, total_logical_writes bigint NULL
	, avg_logical_writes bigint NULL
	, last_logical_writes bigint NULL
	, min_logical_writes bigint NULL
	, max_logical_writes bigint NULL
	, total_logical_reads bigint NULL
	, avg_logical_reads bigint NULL
	, last_logical_reads bigint NULL
	, min_logical_reads bigint NULL
	, max_logical_reads bigint NULL
	, total_elapsed_time bigint NULL
	, avg_elapsed_time bigint NULL
	, last_elapsed_time bigint NULL
	, min_elapsed_time bigint NULL
	, max_elapsed_time bigint NULL
	, total_spills bigint NULL
	, avg_spills bigint NULL
	, last_spills bigint NULL
	, min_spills bigint NULL
	, max_spills bigint NULL

	, CONSTRAINT pk_dm_exec_procedure_stats_hist PRIMARY KEY CLUSTERED (id)
);


CREATE NONCLUSTERED INDEX dm_exec_procedure_stats_hist_02 ON dbo.dm_exec_procedure_stats_hist (
	  database_name
	, schema_name
	, object_name
	, entry_time
);


CREATE NONCLUSTERED INDEX dm_exec_procedure_stats_hist_03 ON dbo.dm_exec_procedure_stats_hist (
	  entry_time
	, max_elapsed_time
	, avg_elapsed_time
	, database_name
	, object_name
	, cached_time
	, entry_id
);



USE msdb;


DECLARE
	  @v_job_name sysname = N'DBA - SP Stats History'
	, @v_database_name sysname
	, @v_step_name sysname
	, @v_step_id int = 0;




EXECUTE dbo.sp_add_job
	  @job_name=@v_job_name
	, @enabled=1
	, @notify_level_eventlog=0
	, @notify_level_email=0
	, @notify_level_netsend=0
	, @notify_level_page=0
	, @delete_level=0
	, @description=N'Archive stored procedure statistics'
	--, @category_name=N'Uncategorized (Local)'
	, @owner_login_name=N'sa';




/* Add a job step for each database */
DECLARE cur_dbs CURSOR LOCAL FAST_FORWARD FOR
	SELECT   name
	FROM     #Databases
	ORDER BY name;

OPEN cur_dbs;
	FETCH NEXT FROM cur_dbs INTO @v_database_name;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @v_step_name = N'Collect Stored Procedure Stats - ' + @v_database_name;
		SET @v_step_id = @v_step_id + 1;

		EXECUTE dbo.sp_add_jobstep
			  @job_name=@v_job_name
			, @step_name=@v_step_name
			, @database_name=@v_database_name
			, @step_id=@v_step_id
			, @cmdexec_success_code=0
			, @on_success_action=3
			, @on_success_step_id=0
			, @on_fail_action=2
			, @on_fail_step_id=0
			, @retry_attempts=0
			, @retry_interval=0
			, @os_run_priority=0
			, @subsystem=N'TSQL'
			, @flags=0
			, @command=N'
DECLARE
	  @entry_id INT
	, @PreviousStats_entry_id INT;

SELECT @entry_id = ISNULL(MAX(entry_id),0) + 1 
FROM   CentralAdmin.dbo.dm_exec_procedure_stats_hist;

SELECT	@PreviousStats_entry_id = MAX(entry_id)
FROM    CentralAdmin.dbo.dm_exec_procedure_stats_hist
WHERE   database_name=DB_NAME() AND ENTRY_ID<@entry_id;



INSERT INTO CentralAdmin.dbo.dm_exec_procedure_stats_hist (
	  entry_id
	, entry_time
	, database_name
	, schema_name
	, object_name
	, type
	, type_desc
	, sql_handle
	, plan_handle
	, cached_time
	, last_execution_time
	, execution_count
	, execution_count_delta
	, total_worker_time
	, avg_worker_time
	, last_worker_time
	, min_worker_time
	, max_worker_time
	, total_physical_reads
	, avg_physical_reads
	, last_physical_reads
	, min_physical_reads
	, max_physical_reads
	, total_logical_writes
	, avg_logical_writes
	, last_logical_writes
	, min_logical_writes
	, max_logical_writes
	, total_logical_reads
	, avg_logical_reads
	, last_logical_reads
	, min_logical_reads
	, max_logical_reads
	, total_elapsed_time
	, avg_elapsed_time
	, last_elapsed_time
	, min_elapsed_time
	, max_elapsed_time
	, total_spills
	, avg_spills
	, last_spills
	, min_spills
	, max_spills
)
SELECT
	  @entry_id
	, SYSDATETIMEOFFSET()
	, DB_NAME()
	, SCHEMA_NAME(o.schema_id)
	, o.name
	, s.type
	, s.type_desc
	, s.sql_handle
	, s.plan_handle
	, s.cached_time
	, s.last_execution_time
	, s.execution_count
	, s.execution_count
	, s.total_worker_time
	, s.total_worker_time / s.execution_count
	, s.last_worker_time
	, s.min_worker_time
	, s.max_worker_time
	, s.total_physical_reads
	, s.total_physical_reads / s.execution_count
	, s.last_physical_reads
	, s.min_physical_reads
	, s.max_physical_reads
	, s.total_logical_writes
	, s.total_logical_writes / s.execution_count
	, s.last_logical_writes
	, s.min_logical_writes
	, s.max_logical_writes
	, s.total_logical_reads
	, s.total_logical_reads / s.execution_count
	, s.last_logical_reads
	, s.min_logical_reads
	, s.max_logical_reads
	, s.total_elapsed_time
	, s.total_elapsed_time / s.execution_count
	, s.last_elapsed_time
	, s.min_elapsed_time
	, s.max_elapsed_time
	, s.total_spills
	, s.total_spills / s.execution_count
	, s.last_spills
	, s.min_spills
	, s.max_spills
FROM
	sys.dm_exec_procedure_stats s
JOIN
	sys.objects o ON o.object_id = s.object_id
WHERE
	s.database_id = DB_ID();


IF @PreviousStats_entry_id IS NOT NULL
BEGIN
	/* update the stats deltas */
	WITH
		PreviousStats AS (
			SELECT
				  database_name
				, schema_name
				, object_name
				, cached_time
				, execution_count
				, total_worker_time
				, total_physical_reads
				, total_logical_writes
				, total_logical_reads
				, total_elapsed_time
				, total_spills
			FROM
				CentralAdmin.dbo.dm_exec_procedure_stats_hist
			WHERE
				entry_id=@PreviousStats_entry_id	
		)
	UPDATE
		t1
	SET
		  t1.execution_count_delta = t1.execution_count - t2.execution_count
		, t1.avg_worker_time    = CASE WHEN t1.execution_count > t2.execution_count THEN (t1.total_worker_time    - t2.total_worker_time)    / (t1.execution_count - t2.execution_count) ELSE NULL END
		, t1.avg_physical_reads = CASE WHEN t1.execution_count > t2.execution_count THEN (t1.total_physical_reads - t2.total_physical_reads) / (t1.execution_count - t2.execution_count) ELSE NULL END
		, t1.avg_logical_writes = CASE WHEN t1.execution_count > t2.execution_count THEN (t1.total_logical_writes - t2.total_logical_writes) / (t1.execution_count - t2.execution_count) ELSE NULL END
		, t1.avg_logical_reads  = CASE WHEN t1.execution_count > t2.execution_count THEN (t1.total_logical_reads  - t2.total_logical_reads)  / (t1.execution_count - t2.execution_count) ELSE NULL END
		, t1.avg_elapsed_time   = CASE WHEN t1.execution_count > t2.execution_count THEN (t1.total_elapsed_time   - t2.total_elapsed_time)   / (t1.execution_count - t2.execution_count) ELSE NULL END
		, t1.avg_spills         = CASE WHEN t1.execution_count > t2.execution_count THEN (t1.total_spills         - t2.total_spills)         / (t1.execution_count - t2.execution_count) ELSE NULL END
	FROM
		CentralAdmin.dbo.dm_exec_procedure_stats_hist t1
	JOIN
		PreviousStats t2 ON
			t1.database_name = t2.database_name
			and t1.schema_name = t2.schema_name
			AND t1.object_name = t2.object_name
			AND t1.cached_time = t2.cached_time
	WHERE
		t1.entry_id = @entry_id
		AND t1.execution_count >= t2.execution_count;

END;
';

		FETCH NEXT FROM cur_dbs INTO @v_database_name;
	END;
CLOSE cur_dbs;
DEALLOCATE cur_dbs;





/* cleanup step */
SET @v_step_id = @v_step_id + 1;
EXECUTE dbo.sp_add_jobstep
	  @job_name=@v_job_name
	, @step_name=N'Purge Old History'
	, @step_id=@v_step_id
	, @cmdexec_success_code=0
	, @on_success_action=1
	, @on_success_step_id=0
	, @on_fail_action=2
	, @on_fail_step_id=0
	, @retry_attempts=0
	, @retry_interval=0
	, @os_run_priority=0
	, @subsystem=N'TSQL'
	, @command=N'
DELETE FROM dbo.dm_exec_procedure_stats_hist
WHERE entry_time < DATEADD(DAY,-3,GETDATE());
'
	, @database_name=N'CentralAdmin'
	, @flags=0;


EXECUTE dbo.sp_update_job
	  @job_name=@v_job_name
	, @start_step_id = 1;



EXECUTE dbo.sp_add_jobschedule
	  @job_name=@v_job_name
	, @name=N'DBA - SP Stats History Sched'
	, @enabled=1
	, @freq_type=4
	, @freq_interval=1
	, @freq_subday_type=4
	, @freq_subday_interval=5
	, @freq_relative_interval=0
	, @freq_recurrence_factor=0
	, @active_start_date=20220426
	, @active_end_date=99991231
	, @active_start_time=0
	, @active_end_time=235959;



EXECUTE dbo.sp_add_jobserver
	  @job_name=@v_job_name
	, @server_name = N'(local)';
