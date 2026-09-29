USE [msdb];

SET NOCOUNT ON;


------------------------------------------------
--// USER INPUT                             //--
------------------------------------------------

DECLARE @monitoredJob   NVARCHAR(128) = N'INT_CornerstoneToPIRATeSToSN',   -- select name from msdb.dbo.sysjobs order by name;
        @emailNotify    VARCHAR(MAX)  = N'james.lutsey@plexus.com';



------------------------------------------------
--// OTHER VARIABLES                        //--
------------------------------------------------

DECLARE @myJobName      NVARCHAR(128),
        @myDescription  NVARCHAR(512),
        @myOwner        NVARCHAR(128),
        @myServer       NVARCHAR(128),
        @myCommand      NVARCHAR(MAX),
        @msg            NVARCHAR(MAX);

-- verify input
IF NOT EXISTS(SELECT 1 FROM dbo.sysjobs WHERE name = @monitoredJob)
BEGIN
    SET @msg = N'''' + @monitoredJob + N''' does not exist. Enter a new value for @monitoredJob.';
    RAISERROR(@msg,16,1) WITH NOWAIT;
    SET NOEXEC ON;
END;

IF @emailNotify = N''
BEGIN
    SET @msg = N'You must enter an email address for @emailNotify.';
    RAISERROR(@msg,16,1) WITH NOWAIT;
    SET NOEXEC ON;
END;

-- set values
SELECT @myJobName      = N'JobFinishedNotification_' + @monitoredJob + N'_' + REPLACE(REPLACE(REPLACE(CONVERT(NCHAR(19),GETDATE(),120),N'-',N''),N' ',N'_'),N':',N''),
       @myDescription  = N'Monitors execution of job [' + @monitoredJob + N'] and emails ' + @emailNotify + N' when the job finishes.',
       @myServer       = @@SERVERNAME;



------------------------------------------------
--// GET CONFIGURATION VALUES               //--
------------------------------------------------

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
                                  @delete_level               = 1, -- 0 = Never, 1 = On success, 2 = On failure, 3 = Always
                                  @description                = @myDescription, 
                                  @owner_login_name           = @myOwner;

EXECUTE [msdb].[dbo].[sp_add_jobserver] @job_name    = @myJobName, 
                                        @server_name = @myServer;

SET @myCommand = N'
SET NOCOUNT ON;

-- user input
DECLARE @jobName         AS NVARCHAR(128) = N''' + @monitoredJob + N''',
        @emailRecipients AS VARCHAR(MAX)  = ''' + @emailNotify + N''';

-- other variables
DECLARE @duration     AS CHAR(8),
        @emailBody    AS NVARCHAR(MAX),
        @emailProfile AS SYSNAME,
        @emailSubject AS NVARCHAR(255),
        @runStatus    AS NVARCHAR(9),
        @timeStart    AS DATETIME2(0),
        @timeEnd      AS DATETIME2(0);

-- check if the job is still running
WHILE EXISTS(   SELECT     1
                FROM       [msdb].[dbo].[sysjobactivity] AS [ja] 
                INNER JOIN [msdb].[dbo].[sysjobs] AS [j] ON [ja].[job_id] = [j].[job_id]
                WHERE      [ja].[session_id] = (SELECT TOP 1 [session_id] FROM [msdb].[dbo].[syssessions] ORDER BY [agent_start_date] DESC)
                           AND [ja].[start_execution_date] IS NOT NULL
                           AND [ja].[stop_execution_date] IS NULL
                           AND [j].[name] = @jobName
            )
BEGIN
  WAITFOR DELAY ''00:00:10''
END;

-- get the info from the last run
SELECT TOP 1    @timeStart = [msdb].[dbo].[agent_datetime]([h].[run_date],[h].[run_time]),
                @timeEnd   = DATEADD
                                 (
                                     SECOND, 
                                     
                                     (([h].[run_duration] / 1000000) * 86400) +  -- days * 86,400 seconds/day
                                     ((([h].[run_duration] - (([h].[run_duration] / 1000000)  * 1000000)) / 10000) * 3600) +  -- hours * 3,600 seconds/hour
                                     ((([h].[run_duration] - (([h].[run_duration] / 10000) * 10000))  / 100) * 60) +  -- minutes * 60 seconds/minute
                                     ([h].[run_duration] - ([h].[run_duration] / 100) * 100),  -- seconds 
                                     
                                     CAST(STR([h].[run_date], 8, 0) AS DATETIME) + -- date
                                     CAST(STUFF(STUFF(RIGHT(''000000'' + CAST ([h].[run_time] AS VARCHAR(6)), 6), 5, 0, '':''), 3, 0, '':'') AS DATETIME) -- time
                                 ),
                @duration  = STUFF(STUFF(REPLACE(STR([run_duration], 6, 0), '' '', ''0''), 3, 0, '':''), 6, 0, '':''), 
                @runStatus = CASE [h].[run_status]
                                 WHEN 0 THEN N''Failed''
                                 WHEN 1 THEN N''Succeeded''
                                 WHEN 2 THEN N''Retry''
                                 WHEN 3 THEN N''Canceled''
                             END
FROM            [msdb].[dbo].[sysjobs] AS [j]
INNER JOIN      [msdb].[dbo].[sysjobhistory] AS [h] ON [j].[job_id] = [h].[job_id]
LEFT OUTER JOIN [msdb].[dbo].[sysjobsteps] AS [s] ON [j].[job_id] = [s].[job_id] AND [h].[step_id] = [s].[step_id]
LEFT OUTER JOIN [msdb].[dbo].[sysoperators] AS [o] ON [o].[id] = [j].[notify_email_operator_id]
WHERE           [j].[name] = @jobName
                AND [h].[step_id] = 0
ORDER BY        [msdb].[dbo].[agent_datetime]([h].[run_date],[h].[run_time]) DESC, [j].[name], [h].[step_id] DESC;

-- set the values needed for dbmail
SELECT @emailProfile = name FROM msdb.dbo.sysmail_profile WHERE LOWER(name) LIKE ''%sql%notifier%'';

SET @emailSubject = N''['' + @jobName + N''] '' + @runStatus;   

SET @emailBody    = N''Job --> '' + QUOTENAME(@@SERVERNAME) + N''.['' + @jobName + N'']'' + NCHAR(0x000D) + NCHAR(0x000A) + 
                    NCHAR(0x000D) + NCHAR(0x000A) + 
                    N''Outcome --> '' + @runStatus + NCHAR(0x000D) + NCHAR(0x000A) + 
                    NCHAR(0x000D) + NCHAR(0x000A) + 
                    N''Start --> '' + CAST(@timeStart AS NCHAR(19)) + NCHAR(0x000A) + 
                    N''End --> '' + CAST(@timeEnd AS NCHAR(19)) + NCHAR(0x000A) + 
                    N''Duration --> '' + @duration + N'''';

-- email the alert
EXECUTE msdb.dbo.sp_send_dbmail @profile_name = @emailProfile,
                                @recipients   = @emailRecipients, 
                                @subject      = @emailSubject,
                                @body         = @emailBody;
';

EXECUTE [msdb].[dbo].[sp_add_jobstep] @job_name             = @myJobName, 
                                      @step_name            = N'MonitorAndNotify', 
                                      @step_id              = 1, 
                                      @cmdexec_success_code = 0, 
                                      @on_success_action    = 1, -- 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_success_step_id
                                      @on_fail_action       = 3, -- 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_fail_step_id
                                      @retry_attempts       = 0, 
                                      @retry_interval       = 0, -- minutes
                                      @os_run_priority      = 0, 
                                      @database_name        = N'msdb', 
                                      @flags                = 0,
                                      @subsystem            = N'TSQL', 
                                      @command              = @myCommand;

SET @myCommand = N'
SET NOCOUNT ON;

DECLARE @emailBody    AS NVARCHAR(MAX),
        @emailProfile AS SYSNAME,
        @emailRecipients AS VARCHAR(MAX)  = ''' + @emailNotify + N''',
        @emailSubject AS NVARCHAR(255);

SELECT @emailProfile = name FROM msdb.dbo.sysmail_profile WHERE LOWER(name) LIKE ''%sql%notifier%'';

SET @emailSubject = N''Failed | ' + @myJobName + N''';   

SET @emailBody    = N''Job --> [' + @myJobName + N'] failed. It has not been deleted, so you can review the message and choose to re-run it.'';

EXECUTE msdb.dbo.sp_send_dbmail @profile_name = @emailProfile,
                                @recipients   = @emailRecipients, 
                                @subject      = @emailSubject,
                                @body         = @emailBody;
';

EXECUTE [msdb].[dbo].[sp_add_jobstep] @job_name             = @myJobName, 
                                      @step_name            = N'NotifyFailure', 
                                      @step_id              = 2, 
                                      @cmdexec_success_code = 0, 
                                      @on_success_action    = 1, -- 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_success_step_id
                                      @on_fail_action       = 2, -- 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_fail_step_id
                                      @retry_attempts       = 0, 
                                      @retry_interval       = 0, -- minutes
                                      @os_run_priority      = 0, 
                                      @database_name        = N'msdb', 
                                      @flags                = 0,
                                      @subsystem            = N'TSQL', 
                                      @command              = @myCommand;

EXECUTE [msdb].[dbo].[sp_update_job] @job_name       = @myJobName, 
                                     @start_step_id  = 1;



------------------------------------------------
--// START THE JOB                          //--
------------------------------------------------

EXECUTE msdb.dbo.sp_start_job @job_name = @myJobName;



------------------------------------------------
--// CLEAN UP                               //--
------------------------------------------------

SET NOEXEC OFF;
