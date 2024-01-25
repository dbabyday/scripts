use msdb;

declare @jobName sysname = N'DBA - Log BlitzFirst to Table';
declare @scheduleName sysname = @jobName + N' Schedule';

execute dbo.sp_add_job
	  @job_name=@jobName
	, @enabled=1
	, @notify_level_eventlog=0
	, @notify_level_email=0
	, @notify_level_netsend=0
	, @notify_level_page=0
	, @delete_level=0
	, @description=N'Store sp_BlitzFirst data in a table to capture baselines.'
	, @owner_login_name=N'sa';

execute dbo.sp_add_jobstep
	  @job_name=@jobName
	, @step_name=N'sp_BlitzFirst'
	, @step_id=1
	, @cmdexec_success_code=0
	, @on_success_action=1
	, @on_success_step_id=0
	, @on_fail_action=2
	, @on_fail_step_id=0
	, @retry_attempts=0
	, @retry_interval=0
	, @os_run_priority=0
	, @subsystem=N'TSQL'
	, @command=N'execute sp_BlitzFirst 
	  @OutputDatabaseName = ''CentralAdmin''
	, @OutputSchemaName = ''dbo''
	, @OutputTableName = ''BlitzFirst''
	, @OutputTableNameFileStats = ''BlitzFirst_FileStats''
	, @OutputTableNamePerfmonStats = ''BlitzFirst_PerfmonStats''
	, @OutputTableNameWaitStats = ''BlitzFirst_WaitStats''
	, @OutputTableNameBlitzCache = ''BlitzCache''
	, @OutputTableNameBlitzWho = ''BlitzWho'';'
	, @database_name=N'master'
	, @flags=0;

execute dbo.sp_add_jobschedule
	  @job_name=@jobName
	, @name=@scheduleName
	, @enabled=1
	, @freq_type=4
	, @freq_interval=1
	, @freq_subday_type=4
	, @freq_subday_interval=15
	, @freq_relative_interval=0
	, @freq_recurrence_factor=0
	, @active_start_date=20240115
	, @active_end_date=99991231
	, @active_start_time=0
	, @active_end_time=235959;

execute dbo.sp_add_jobserver
	  @job_name=@jobName
	, @server_name = @@servername;