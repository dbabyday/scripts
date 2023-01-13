/**************************************************************************************
* 
* JOBS_StopAndRestartSerially.sql
* Author: James Lutsey
* Date:   2017-09-07
* 
* Purpose: Stop and restart the GSF "Backflush" jobs if they are hanging/running long
* 
* Notes: Jobs are listed in the "INSERT INTO #Job" command...you can indicate which of 
*        the jobs you want to stop and which ones you want to start with the bit fields
* 
**************************************************************************************/

IF UPPER(@@SERVERNAME) != 'CO-DB-032'
BEGIN
    RAISERROR(N'Wrong server',16,1) WITH NOWAIT;
    SET NOEXEC ON;
END;

-- 0 = do not execute, just get next start times
-- 1 = execute stop and restart jobs
DECLARE @go BIT = 0;

DECLARE @emailBody       NVARCHAR(MAX) = N'',
        @emailProfile    NVARCHAR(128) = N'',
        @emailRecipients VARCHAR(MAX) = 'james.lutsey@plexus.com',
        @emailSubject    NVARCHAR(255) = N'',
        @jobName         NVARCHAR(128) = N'',
        @nl              NVARCHAR(10)  = CHAR(13) + CHAR(10),
        @sql             NVARCHAR(MAX) = N'',
        @updated         DATETIME2(3);

IF OBJECT_ID('tempdb..#Job',N'U') IS NOT NULL DROP TABLE #Job;
CREATE TABLE #Job 
(
    [id]    INT IDENTITY(1,1) NOT NULL,
    [name]  NVARCHAR(128)     NOT NULL,
    [stop]  BIT               NOT NULL,
    [start] BIT               NOT NULL
);

DECLARE curStartJobs CURSOR LOCAL FAST_FORWARD FOR 
    SELECT   [name]
    FROM     #Job
    WHERE    [start] = 1
    ORDER BY [id];

INSERT INTO #Job ([name],                                  [stop], [start]) 
VALUES           (N'GsfAutomatedOperationCompletion_0100', 1     , 1      ),
                 (N'GsfAutomatedOperationCompletion_0200', 1     , 1      ),
                 (N'GsfAutomatedOperationCompletion_0215', 1     , 1      ),
                 (N'GsfAutomatedOperationCompletion_0230', 1     , 1      ),
                 (N'GsfAutomatedOperationCompletion_0330', 1     , 1      );

-- get the profile name
SELECT TOP 1 @emailProfile = [name]
FROM   [msdb].[dbo].[sysmail_profile]
WHERE  [name] LIKE 'SQL%Notifier';

IF @emailProfile IS NULL
BEGIN
    RAISERROR(N'No email profile was selected',16,1) WITH NOWAIT;
    SET NOEXEC ON;
END;

IF @go = 0
BEGIN
    RAISERROR('I have not added the schedules yet',0,1) WITH NOWAIT;
    SET NOEXEC ON;
END;



------------------------------------------------------------
--// STOP THE JOBS THAT ARE RUNNING LONG                //--
------------------------------------------------------------

-- get the long running jobs
SELECT      @sql += 'EXECUTE [msdb].[dbo].[sp_stop_job] @job_name = ' + [j].[name] + N';' + @nl
FROM        [msdb].[dbo].[sysjobactivity] AS [ja]
INNER JOIN  [msdb].[dbo].[sysjobs] AS [j] ON [ja].[job_id] = [j].[job_id]
INNER JOIN  #Job AS [selected] ON [j].[name] = [selected].[name]
WHERE       [ja].[session_id] = (SELECT TOP 1 [session_id] FROM [msdb].[dbo].[syssessions] ORDER BY [agent_start_date] DESC)
            AND [start_execution_date] IS NOT NULL
            AND [stop_execution_date] IS NULL
            AND [selected].[stop] = 1;
            
-- email notification that we are stopping the jobs
SET @emailSubject  = N'UPDATE: Stopping Jobs';
SET @emailBody    += CONVERT(NVARCHAR(19),GETDATE(),120) + N' - Stopping the jobs:' + @nl + @sql + @nl;

EXECUTE [msdb].[dbo].[sp_send_dbmail] @profile_name = @emailProfile,
                                      @recipients   = @emailRecipients,
                                      @subject      = @emailSubject,
                                      @body         = @emailBody;

-- stop the jobs
EXECUTE(@sql);

-- give some time for the jobs to stop before checking on them
WAITFOR DELAY '00:01:00';



------------------------------------------------------------
--// RESTART THE JOBS THAT WERE RUNNING LONG            //--
------------------------------------------------------------

OPEN curStartJobs;
    FETCH NEXT FROM curStartJobs INTO @jobName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS(   SELECT     1
                         FROM       [msdb].[dbo].[sysjobactivity] AS [ja]
                         INNER JOIN [msdb].[dbo].[sysjobs] AS [j] ON [ja].[job_id] = [j].[job_id]
                         WHERE      [ja].[session_id] = (SELECT TOP 1 [session_id] FROM [msdb].[dbo].[syssessions] ORDER BY [agent_start_date] DESC)
                                    AND [start_execution_date] IS NOT NULL
                                    AND [stop_execution_date] IS NULL
                                    AND [j].[name] = @jobName
                     )
        BEGIN
            -- email notification that we are starting the job
            SET @emailSubject  = N'UPDATE: Starting [' + @jobName + N']';
            SET @emailBody    += CONVERT(NVARCHAR(19),GETDATE(),120) + N' - Starting Job [' + @jobName + N']' + @nl;

            EXECUTE [msdb].[dbo].[sp_send_dbmail] @profile_name = @emailProfile,
                                                  @recipients   = @emailRecipients,
                                                  @subject      = @emailSubject,
                                                  @body         = @emailBody;
            
            SET @updated = GETDATE();

            -- start the job
            EXECUTE [msdb].[dbo].[sp_start_job] @job_name = @jobName;

            -- wait for a while before checking on the job
            WAITFOR DELAY '00:01:00';
        END;
        ELSE
        BEGIN
            -- email notification that the job is already running
            SET @emailSubject  = N'UPDATE: Already Running [' + @jobName + N']';
            SET @emailBody    += CONVERT(NVARCHAR(19),GETDATE(),120) + N' - Job is already running: [' + @jobName + N']' + @nl;

            EXECUTE [msdb].[dbo].[sp_send_dbmail] @profile_name = @emailProfile,
                                                  @recipients   = @emailRecipients,
                                                  @subject      = @emailSubject,
                                                  @body         = @emailBody;
            
            SET @updated = GETDATE();
        END;

        -- periodically check on the job to see if it is still running
        WHILE EXISTS(   SELECT     1
                        FROM       [msdb].[dbo].[sysjobactivity] AS [ja]
                        INNER JOIN [msdb].[dbo].[sysjobs] AS [j] ON [ja].[job_id] = [j].[job_id]
                        WHERE      [ja].[session_id] = (SELECT TOP 1 [session_id] FROM [msdb].[dbo].[syssessions] ORDER BY [agent_start_date] DESC)
                                   AND [start_execution_date] IS NOT NULL
                                   AND [stop_execution_date] IS NULL
                                   AND [j].[name] = @jobName
                     )
        BEGIN -- it is still running
            -- check how long it's been since the last update was emailed
            IF DATEDIFF(MINUTE,@updated,GETDATE()) >= 10
            BEGIN
                -- email another update
                SET @emailSubject  = N'UPDATE: Still Running [' + @jobName + N']';
                SET @emailBody    += CONVERT(NVARCHAR(19),GETDATE(),120) + N' - Job is still running: [' + @jobName + N']' + @nl;

                EXECUTE [msdb].[dbo].[sp_send_dbmail] @profile_name = @emailProfile,
                                                      @recipients   = @emailRecipients,
                                                      @subject      = @emailSubject,
                                                      @body         = @emailBody;
                
                SET @updated = GETDATE();
            END;

            -- wait for a while before checking again
            WAITFOR DELAY '00:01:00';
        END;

        -- update the email body: the job is no longer running
        SET @emailBody += CONVERT(NVARCHAR(19),GETDATE(),120) + N' - Job is no longer running: [' + @jobName + N']' + @nl;


        FETCH NEXT FROM curStartJobs INTO @jobName;
    END;
CLOSE curStartJobs;
DEALLOCATE curStartJobs;



------------------------------------------------------------
--// WE'RE DONE - SEND FINAL UPDATE                     //--
------------------------------------------------------------

-- email update that all the jobs have finished running
SET @emailSubject  = N'UPDATE: Complete';
SET @emailBody    += CONVERT(NVARCHAR(19),GETDATE(),120) + N' - All jobs have finished. You will need to manually check success/failure of the jobs.' + @nl + N'JOBS_Info.sql @jobName values: ';

-- add the comma separated job names to insert into JOBS_Info.sql script
SELECT   @emailBody += [name] + N','
FROM     #Job
ORDER BY [name];

-- remove the last ','
SET @emailBody = LEFT(@emailBody,LEN(@emailBody) - 1);

EXECUTE [msdb].[dbo].[sp_send_dbmail] @profile_name = @emailProfile,
                                      @recipients   = @emailRecipients,
                                      @subject      = @emailSubject,
                                      @body         = @emailBody;
    


------------------------------------------------------------
--// CLEAN UP                                           //--
------------------------------------------------------------

-- reset
SET NOEXEC OFF;

-- clean up temp table(s)
IF OBJECT_ID('tempdb..#Job',N'U') IS NOT NULL DROP TABLE #Job;





