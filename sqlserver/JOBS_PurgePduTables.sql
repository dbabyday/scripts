IF DB_ID('PDU') IS NULL
    CREATE DATABASE [PDU];

USE [msdb];

DECLARE @myJobName      NVARCHAR(128),
        @myDescription  NVARCHAR(512),
        @myOperator     NVARCHAR(128),
        @myOwner        NVARCHAR(128),
        @myScheduleName NVARCHAR(128),
        @myServer       NVARCHAR(128);



------------------------------------------------
--// USER INPUT                             //--
------------------------------------------------

SELECT @myJobName      = N'DBA - Purge PDU',
       @myDescription  = N'Drops tables older than 30 days from database [PDU]',
       @myScheduleName = N'DBA - Purge PDU - Daily',
       @myServer       = @@SERVERNAME;

-- NOTE: you must enter @step_name in each sp_add_jobstep



------------------------------------------------
--// GET CONFIGURATION VALUES               //--
------------------------------------------------

SELECT TOP 1 @myOperator = [name]
FROM   [msdb].[dbo].[sysoperators]
WHERE  [email_address] = 'IT.MSSQL.Admins@plexus.com';

SELECT @myOwner = [name]
FROM   [sys].[server_principals]
WHERE  [principal_id] = 1;



------------------------------------------------
--// CREATE THE JOB                         //--
------------------------------------------------

IF EXISTS(SELECT 1 FROM [msdb].[dbo].[sysjobs] WHERE [name] = @myJobName)
    EXECUTE [msdb].[dbo].[sp_delete_job] @job_name = @myJobName, @delete_unused_schedule = 1;


EXECUTE [msdb].[dbo].[sp_add_job] @job_name                   = @myJobName, 
                                  @enabled                    = 1, 
                                  @notify_level_eventlog      = 0, 
                                  @notify_level_email         = 2, 
                                  @notify_level_netsend       = 2, 
                                  @notify_level_page          = 2, 
                                  @delete_level               = 0,
                                  @notify_email_operator_name = @myOperator,
                                  @description                = @myDescription, 
                                  @category_name              = N'[Uncategorized (Local)]', 
                                  @owner_login_name           = @myOwner;

EXECUTE [msdb].[dbo].[sp_add_jobserver] @job_name    = @myJobName, 
                                        @server_name = @myServer;

EXECUTE [msdb].[dbo].[sp_add_jobstep] @job_name             = @myJobName, 
                                      @step_name            = N'Purge PDU tables older 30 days', 
                                      @step_id              = 1, 
                                      @cmdexec_success_code = 0, 
                                      @on_success_action    = 1, -- 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_success_step_id
                                      @on_fail_action       = 2, -- 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_fail_step_id
                                      @retry_attempts       = 0, 
                                      @retry_interval       = 0, -- minutes
                                      @os_run_priority      = 0, 
                                      @database_name        = N'PDU', 
                                      @flags                = 0,
                                      @subsystem            = N'TSQL', 
                                      @command              = N'
DECLARE @sql NVARCHAR(MAX) = N''USE [PDU];'' + CHAR(10);
                                         
SELECT @sql += N''DROP TABLE [PDU].['' + SCHEMA_NAME([schema_id]) + ''].['' + [name] + N''];'' + CHAR(10)
FROM   [PDU].[sys].[tables]
WHERE  [modify_date] < DATEADD(DAY,-30,GETDATE());

EXECUTE(@sql);
';

EXECUTE [msdb].[dbo].[sp_update_job] @job_name                     = @myJobName, 
                                     @start_step_id                = 1;



------------------------------------------------
--// CREATE THE SCHEDULE                    //--
------------------------------------------------

EXECUTE [msdb].[dbo].[sp_add_jobschedule] @job_name               = @myJobName, 
                                          @name                   = @myScheduleName, 
                                          @enabled                = 1, 
                                          @freq_type              = 4, -- 1 = Once, 4 = Daily, 8 = Weekly, 16 = Monthly, 32 = Monthly, relative to frequency_interval, 64 = Run when the SQL Server Agent service starts, 128 = Run when teh computer is idle
                                          @freq_interval          = 1, 
                                          @freq_subday_type       = 1, -- 1 = At specified time, 4 = Minutes, 8 = Hours
                                          @freq_subday_interval   = 0, 
                                          @freq_relative_interval = 0, -- 1 = First, 2 = Second, 4 = Third, 8 = Fourth, 16 = Last
                                          @freq_recurrence_factor = 0, -- Number of weeks or months between the scheduled execution of the job
                                          @active_start_date      = 20170101, 
                                          @active_end_date        = 99991231, 
                                          @active_start_time      = 0, 
                                          @active_end_time        = 235959;


