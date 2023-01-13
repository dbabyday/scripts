/**********************************************************************************************************
* 
* INDEX_CreateJob_ReindexReport.sql
* 
* Author: James Lutsey
* Date: 01/04/2016
* 
* Purpose: Runs usp_IndexReport to email an index report. The usp_IndexReport is based on 
*          Ola Hallengren's Index Optimize stored proc. Executes the report as a job to eliminate 
*          need to stay connected to the server. The job self-deletes upon successful completion.
* 
* Notes:
*     1. Set the parameters, email is required (line 61)
*     2. This job requires CentralAdmin database with stored procedure usp_IndexReport
*     3. To print the command, but not create the job or run the report, SET @JobOrCommand = 1 (line 62)
* 
**********************************************************************************************************/

DECLARE
    @Email                           NVARCHAR(128),
	@JobOrCommand					 INT,
    @Databases                       NVARCHAR(max),
    @FragmentationLow                NVARCHAR(max),
    @FragmentationMedium             NVARCHAR(max),
    @FragmentationHigh               NVARCHAR(max),
    @FragmentationLevel1             INT,
    @FragmentationLevel2             INT,
    @PageCountLevel                  INT,
    @SortInTempdb                    NVARCHAR(max),
    @MaxDOP                          INT,
    @FillFactor                      INT,
    @PadIndex                        NVARCHAR(max),
    @LOBCompaction                   NVARCHAR(max),
    @UpdateStatistics                NVARCHAR(max),
    @OnlyModifiedStatistics          NVARCHAR(max),
    @StatisticsSample                INT,
    @StatisticsResample              NVARCHAR(max),
    @PartitionLevel                  NVARCHAR(max),
    @MSShippedObjects                NVARCHAR(max),
    @Indexes                         NVARCHAR(max),
    @TimeLimit                       INT,
    @Delay                           INT,
    @WaitAtLowPriorityMaxDuration    INT,
    @WaitAtLowPriorityAbortAfterWait NVARCHAR(max),
    @LockTimeout                     INT,
    @LogToTable                      NVARCHAR(max),
    @JobStepCommand                  NVARCHAR(max),
	@Message						 NVARCHAR(max),
	@JobId_Old						 UNIQUEIDENTIFIER,
	@JobId_New						 UNIQUEIDENTIFIER,
	@ReturnCode						 INT,
	@ErrorMessage					 NVARCHAR(max);

	
------------------------------------------------------------------------------------------------------------------
--// SET THE PARAMETERS                                                                                       //--
--//     required: @Email                                                                                     //--
--//     optional: uncomment any other parameters you want to set and enter the value                         //--
------------------------------------------------------------------------------------------------------------------

SET @Email                           = 'james.lutsey@plexus.com';
SET @JobOrCommand                    = 0;  -- 0 = Run as a job; 1 = print the command but do not run
--SET @Databases                       = ''; -- default: 'ALL_DATABASES'
--SET @FragmentationLow                = ''; -- default: NULL
--SET @FragmentationMedium             = ''; -- default: 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'
--SET @FragmentationHigh               = ''; -- default: 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'
--SET @FragmentationLevel1             = ;   -- default: 5
--SET @FragmentationLevel2             = ;   -- default: 30
--SET @PageCountLevel                  = ;   -- default: 1000
--SET @SortInTempdb                    = ''; -- default: 'N'
--SET @MaxDOP                          = ;   -- default: NULL
--SET @FillFactor                      = ;   -- default: NULL
--SET @PadIndex                        = ''; -- default: NULL
--SET @LOBCompaction                   = ''; -- default: 'Y'
--SET @UpdateStatistics                = ''; -- default: NULL
--SET @OnlyModifiedStatistics          = ''; -- default: 'N'
--SET @StatisticsSample                = ;   -- default: NULL
--SET @StatisticsResample              = ''; -- default: 'N'
--SET @PartitionLevel                  = ''; -- default: 'Y'
--SET @MSShippedObjects                = ''; -- default: 'N'
--SET @Indexes                         = ''; -- default: NULL
--SET @TimeLimit                       = ;   -- default: NULL
--SET @Delay                           = ;   -- default: NULL
--SET @WaitAtLowPriorityMaxDuration    = ;   -- default: NULL
--SET @WaitAtLowPriorityAbortAfterWait = ''; -- default: NULL
--SET @LockTimeout                     = ;   -- default: NULL
--SET @LogToTable                      = ''; -- default: 'N'

SET @ReturnCode = 0;


IF (@Email = '')
BEGIN
	SET @ErrorMessage = 'You must enter an email address (line 61)';
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT;
    RETURN;
END

IF ((@JobOrCommand <> 0) AND (@JobOrCommand <> 1))
BEGIN
	SET @ErrorMessage = 'You must select a method to run this script (line 62). 0 = run the report as a job, 1 = print the command but do not run the report.';
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT;
    RETURN;
END


----------------------------------------------------------------------------------------------------
--// CHECK FOR THE PREREQUISITES                                                                //--
----------------------------------------------------------------------------------------------------

-- does the CentralAdmin database exist?
IF (DB_ID('CentralAdmin') IS NULL)
BEGIN
	SET @ErrorMessage = 'The CentralAdmin database does not exist on this instance. You must create database ''CentralAdmin'' and stored procedure ''usp_IndexReport'' before using this script.';
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT;
	RETURN;
END

-- does the stored procedure exist?
IF (OBJECT_ID('CentralAdmin.dbo.usp_IndexReport') IS NULL)
BEGIN
	SET @ErrorMessage = 'Stored procedure, usp_IndexReport, does not exist in the CentralAdmin database. You can create it by running script ''INDEX_CreateProc_ReindexReport.sql''.';
	RAISERROR(@ErrorMessage,16,1) WITH NOWAIT;
	RETURN;
END


BEGIN TRANSACTION


------------------------------------------------------------------------------------------------------------------
--// DELETE THE JOB IF IT ALREADY EXISTS                                                                      //--
------------------------------------------------------------------------------------------------------------------

SELECT @JobId_Old = job_id FROM msdb.dbo.sysjobs_view WHERE name = N'DBA - IndexReport';
IF (@JobId_Old IS NOT NULL)
	EXEC msdb.dbo.sp_delete_job @job_id=@JobId_Old, @delete_unused_schedule=1;


------------------------------------------------------------------------------------------------------------------
--// ADD CATEGORY IF IT DOES NOT EXIST                                                                        //--
------------------------------------------------------------------------------------------------------------------

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END


------------------------------------------------------------------------------------------------------------------
--// BUILD THE STRING FOR THE COMMAND TO RUN THE STORED PROCEDURE                                             //--
------------------------------------------------------------------------------------------------------------------

SET @JobStepCommand = N'EXECUTE [CentralAdmin].[dbo].[usp_IndexReport] @Email = ''' + @Email + '''';

IF (@Databases IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @Databases = ''' + @Databases + '''';

IF (@FragmentationLow IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @FragmentationLow = ''' + @FragmentationLow + '''';

IF (@FragmentationMedium IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @FragmentationMedium = ''' + @FragmentationMedium + '''';

IF (@FragmentationHigh IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @FragmentationHigh = ''' + @FragmentationHigh + '''';

IF (@FragmentationLevel1 IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @FragmentationLevel1 = ' + CAST(@FragmentationLevel1 AS NVARCHAR(3));

IF (@FragmentationLevel2 IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @FragmentationLevel2 = ' + CAST(@FragmentationLevel2 AS nvarchar(3));

IF (@PageCountLevel IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @PageCountLevel = ' + CAST(@PageCountLevel AS NVARCHAR(10));

IF (@SortInTempdb IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @SortInTempdb = ''' + @SortInTempdb + '''';

IF (@MaxDOP IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @MaxDOP = ' + CAST(@MaxDOP AS NVARCHAR(3));

IF (@FillFactor IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @FillFactor = ' + CAST(@FillFactor AS NVARCHAR(3)); -- CHECK THIS SIZE

IF (@PadIndex IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @PadIndex = ''' + @PadIndex + '''';

IF (@LOBCompaction IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @LOBCompaction = ''' + @LOBCompaction + '''';

IF (@UpdateStatistics IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @UpdateStatistics = ''' + @UpdateStatistics + '''';

IF (@OnlyModifiedStatistics IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @OnlyModifiedStatistics = ''' + @OnlyModifiedStatistics + '''';

IF (@StatisticsSample IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @StatisticsSample = ' + CAST(@StatisticsSample AS NVARCHAR(20)); -- CHECK THIS SIZE

IF (@StatisticsResample IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @StatisticsResample = ''' + @StatisticsResample + '''';

IF (@PartitionLevel IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @PartitionLevel = ''' + @PartitionLevel + '''';

IF (@MSShippedObjects IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @MSShippedObjects = ''' + @MSShippedObjects + '''';

IF (@Indexes IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @Indexes = ''' + @Indexes + '''';

IF (@TimeLimit IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @TimeLimit = ' + CAST(@TimeLimit AS NVARCHAR(100)); -- CHECK THIS SIZE

IF (@Delay IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @Delay = ' + CAST(@Delay AS NVARCHAR(100)); -- CHECK THIS SIZE

IF (@WaitAtLowPriorityMaxDuration IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @WaitAtLowPriorityMaxDuration = ' + CAST(@WaitAtLowPriorityMaxDuration AS NVARCHAR(100)); -- CHECK THIS SIZE

IF (@WaitAtLowPriorityAbortAfterWait IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @WaitAtLowPriorityAbortAfterWait = ''' + @WaitAtLowPriorityAbortAfterWait + '''';

IF (@LockTimeout IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @LockTimeout = ' + CAST(@LockTimeout AS NVARCHAR(100)); -- CHECK THIS SIZE

IF (@LogToTable IS NOT NULL)
	SET @JobStepCommand = @JobStepCommand + ', @LogToTable = ''' + @LogToTable + '''';

PRINT @JobStepCommand;
PRINT '';

IF (@JobOrCommand = 1) 
	GOTO EndSave;	


------------------------------------------------------------------------------------------------------------------
--// CREATE THE JOB                                                                                           //--
------------------------------------------------------------------------------------------------------------------

EXEC @ReturnCode =  msdb.dbo.sp_add_job 
						@job_name=N'DBA - IndexReport', 
						@enabled=1, 
						@notify_level_eventlog=2, 
						@notify_level_email=0,   
						@notify_level_netsend=0, 
						@notify_level_page=0, 
						@delete_level=0, 
						@description=N'Email a report of the details and reindex commands for the indexes that meet the size and fragmentation parameters.', 
						@category_name=N'Database Maintenance',
						@job_id = @JobId_New OUTPUT;
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


------------------------------------------------------------------------------------------------------------------
--// ADD STEP TO RUN THE STORED PROCEDURE                                                                     //--
------------------------------------------------------------------------------------------------------------------

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
						@job_id=@JobId_New, 
						@step_name=N'IndexReport', 
						@step_id=1, 
						@cmdexec_success_code=0, 
						@on_success_action=3, 
						@on_success_step_id=0, 
						@on_fail_action=2, 
						@on_fail_step_id=0, 
						@retry_attempts=0, 
						@retry_interval=0, 
						@os_run_priority=0,  
						@subsystem=N'TSQL', 
						@command=@JobStepCommand,
						@database_name=N'CentralAdmin',  
						@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


------------------------------------------------------------------------------------------------------------------
--// ADD STEP TO SELF-DELETE THIS JOB                                                                         //--
------------------------------------------------------------------------------------------------------------------

--SET @JobStepCommand =	N'EXEC msdb.dbo.sp_delete_job @job_id=''' + CAST(@JobId_New AS NVARCHAR(36)) + ''', @delete_unused_schedule=1;';

--EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
--						@job_id=@JobId_New, 
--						@step_name='Self-Delete', 
--						@step_id=2, 
--						@cmdexec_success_code=0, 
--						@on_success_action=1, 
--						@on_success_step_id=0, 
--						@on_fail_action=2, 
--						@on_fail_step_id=0, 
--						@retry_attempts=0, 
--						@retry_interval=0, 
--						@os_run_priority=0, 
--						@subsystem=N'TSQL', 
--						@database_name=N'msdb', 
--						@command=@JobStepCommand;
--IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


------------------------------------------------------------------------------------------------------------------
--// MODIFY JOB SETTTINGS                                                                                     //--
------------------------------------------------------------------------------------------------------------------

EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @JobId_New, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @JobId_New, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

COMMIT TRANSACTION


------------------------------------------------------------------------------------------------------------------
--//  START THE JOB                                                                                           //--
------------------------------------------------------------------------------------------------------------------

EXEC msdb.dbo.sp_start_job @job_id = @JobId_New;


------------------------------------------------------------------------------------------------------------------
--// FINISH                                                                                                   //--
------------------------------------------------------------------------------------------------------------------

GOTO EndSave

QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION

EndSave:

GO


