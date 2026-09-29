USE msdb;

CREATE TABLE #JobSteps (
	  step_id           int           not null identity(1,1) primary key
	, step_name         sysname       not null
	, command           nvarchar(max) not null
	, on_success_action tinyint       not null default 3 /* 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_success_step_id */
	, on_fail_action    tinyint       not null default 2 /* 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_fail_step_id */
	, retry_attempts    int           not null default 0
	, retry_interval    int           not null default 0
	, subsystem         nvarchar(40)  not null default N'TSQL'
);




/****************************************************************************************************************************************************************************/
/****************************************************************************************************************************************************************************/


/*==============================================
==// USER INPUT                             //==
==============================================*/

/* Enter job details */
DECLARE
	  @myJobName      sysname       = N'JobNameHere'
	, @myDescription  nvarchar(512) = N'DescriptionHere'
	, @myDatabaseName sysname       = N'DatabaseName'
	, @myServer       nvarchar(128) = @@SERVERNAME;



/* Enter step names and commands */
INSERT INTO #JobSteps (step_name, command) VALUES
	  (N'step_name', N'command')
	, (N'step_name', N'command')
	, (N'step_name', N'command');


	/* change the last step on_success_action to "Quit with success" */
	UPDATE #JobSteps
	SET on_success_action = 1
	WHERE step_id = (SELECT MAX(step_id) FROM #JobSteps);



/* Enter schedule details */
DECLARE
	  @myScheduleName         sysname = @myJobName + N' Schedule'
	, @myEnabled              tinyint = 1
	, @myFreqType             int = 4  /* 1 = Once, 4 = Daily, 8 = Weekly, 16 = Monthly, 32 = Monthly, relative to freq_interval, 64 = Run when the SQL Server Agent service starts, 128 = Run when teh computer is idle */
	, @myFreqInterval         int = 1  /* day the job is executed, action depends on freq_type */
	, @myFreqSubdayType       int = 4  /* 1 = At specified time, 4 = Minutes, 8 = Hours */
	, @myFreqSubdayInterval   int = 30 /* every N minutes/hours...freq_subday_type */
	, @myFreqRelativeInterval int = 0  /* 1 = First, 2 = Second, 4 = Third, 8 = Fourth, 16 = Last */
	, @myFreqRecurrenceFactor int = 0  /* Number of weeks or months between the scheduled execution of the job */
	, @myActiveStartDate      int = CAST(FORMAT(GETDATE(), 'yyyymmdd') AS int)
	, @myActiveEndDate        int = 99991231
	, @myActiveStartTime      int = 0  /* HHmmss on a 24-hour clock */
	, @myActiveEndTime        int = 235959;  /* HHmmss on a 24-hour clock */



/****************************************************************************************************************************************************************************/
/****************************************************************************************************************************************************************************/





/*==============================================
==// GET CONFIGURATION VALUES               //==
==============================================*/

DECLARE
	  @myOperator nvarchar(128)
	, @myOwner    nvarchar(128);

-- SELECT TOP(1) @myOperator = name
-- FROM   dbo.sysoperators
-- WHERE  email_address = 'IT.MSSQL.Admins@plexus.com';

SELECT @myOwner = name
FROM   sys.server_principals
WHERE  principal_id = 1;





/*==============================================
==// CREATE THE JOB                         //==
==============================================*/

IF EXISTS(SELECT 1 FROM dbo.sysjobs WHERE name = @myJobName)
    EXECUTE dbo.sp_delete_job @job_name = @myJobName, @delete_unused_schedule = 1;


EXECUTE dbo.sp_add_job
      @job_name                   = @myJobName
    , @enabled                    = 1
    , @notify_level_eventlog      = 0
    , @notify_level_email         = 0 /* 0 = Never, 1 = On success, 2 = On failure, 3 = Always */
    , @notify_level_netsend       = 0
    , @notify_level_page          = 0
    , @delete_level               = 0
    --, @notify_email_operator_name = @myOperator
    , @description                = @myDescription
    , @owner_login_name           = @myOwner;

EXECUTE dbo.sp_add_jobserver
      @job_name = @myJobName
    , @server_name = @myServer;






/* Add Job Steps */
DECLARE
	  @myStepId          int
	, @myStepName        sysname
	, @myCommand         nvarchar(max)
	, @myOnSuccessAction tinyint
	, @myOnFailAction    tinyint
	, @myRetryAttempts   int
	, @myRetryInterval   int
	, @mySubsystem       nvarchar(40)
	, @sqlCreateJobStep  nvarchar(max);

SET @sqlCreateJobStep = N'
EXECUTE dbo.sp_add_jobstep
      @job_name          = @myJobName
    , @step_name         = @myStepName
    , @step_id           = @myStepId
    , @on_success_action = @myOnSuccessAction
    , @on_fail_action    = @myOnFailAction
    , @retry_attempts    = @myRetryAttempts
    , @retry_interval    = @myRetryInterval
    , @database_name     = @myDatabaseName
    , @subsystem         = @mySubsystem
    , @command           = @myCommand;
';


DECLARE cur_CreateJobSteps CURSOR LOCAL FAST_FORWARD FOR
	SELECT step_id, step_name, command, on_success_action, on_fail_action, retry_attempts, retry_interval, subsystem
	FROM #JobSteps
	ORDER BY step_id;

OPEN cur_CreateJobSteps;
	FETCH NEXT FROM cur_CreateJobSteps INTO @myStepId, @myStepName, @myCommand, @myOnSuccessAction, @myOnFailAction, @myRetryAttempts, @myRetryInterval, @mySubsystem;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXECUTE sp_executesql
			  @sqlCreateJobStep
			, N'
				  @myStepId          int
				, @myStepName        sysname
				, @myCommand         nvarchar(max)
				, @myOnSuccessAction tinyint
				, @myOnFailAction    tinyint
				, @myRetryAttempts   int
				, @myRetryInterval   int
				, @mySubsystem       nvarchar(40)'
			, @myStepId = @myStepId
			, @myStepName = @myStepName
			, @myCommand = @myCommand
			, @myOnSuccessAction = @myOnSuccessAction
			, @myOnFailAction = @myOnFailAction
			, @myRetryAttempts = @myRetryAttempts
			, @myRetryInterval = @myRetryInterval
			, @mySubsystem = @mySubsystem;

		FETCH NEXT FROM cur_CreateJobSteps INTO @variable01, @variable02;
	END;
CLOSE cur_CreateJobSteps;
DEALLOCATE cur_CreateJobSteps;







/* Final Job Configurations */

EXECUTE dbo.sp_update_job
      @job_name = @myJobName
    , @start_step_id = 1;



/*==============================================
==// CREATE THE SCHEDULE                    //==
==============================================*/

EXECUTE dbo.sp_add_jobschedule
	  @job_name               = @myJobName
	, @name                   = @myScheduleName
	, @enabled                = @myEnabled
	, @freq_type              = @myFreqType
	, @freq_interval          = @myFreqInterval
	, @freq_subday_type       = @myFreqSubdayType
	, @freq_subday_interval   = @myFreqSubdayInterval
	, @freq_relative_interval = @myFreqRelativeInterval
	, @freq_recurrence_factor = @myFreqRecurrenceFactor
	, @active_start_date      = @myActiveStartDate
	, @active_end_date        = @myActiveEndDate
	, @active_start_time      = @myActiveStartTime
	, @active_end_time        = @myActiveEndTime;
