/***********************************************************************************************************************************************
* 
* JOBS_Info.sql
* 
* Author: James Lutsey
* Date:   2016-04-13
* 
* Purpose: Get info about jobs, their history, and their schedules
* 
* Notes: 
*     1. Set @selections to indicate if you want job info and/or job history and/or job schedules (default is all)
*     2. If wanted, enter the job and/or step name (@jobName, @stepName)...default is all jobs. Use the commented out script to get job and step names
*     3. Enter other filtering criteria in the WHERE and ORDER BY clauses (starting at lines 159, 527, 631, 699)
*     4. For history, you can see all history, or only unsuccessfull results (@outcome)
*     5. You can select the queries by changing @action
* 
* Date        Name                  Description of change
* ----------  --------------------  ---------------------------------------------------------------------------------
* 2019-03-19  James Lutsey          Added report for job currently running; reordered reports; print selected reports; changed report selection logic to bitwise AND comparison
* 



DECLARE @TimeZone VARCHAR(50);
EXEC MASTER.dbo.xp_regread 'HKEY_LOCAL_MACHINE', 'SYSTEM\CurrentControlSet\Control\TimeZoneInformation', 'TimeZoneKeyName',@TimeZone OUT;
SELECT @TimeZone time_zone, getdate() instance_time, getutcdate() utc_date;


************************************************************************************************************************************************/


SET NOCOUNT ON;
USE msdb;

DECLARE 
	-- USER INPUT
	@selections    INT           = 15,  -- 1 = job info, 2 = job schedules, 4 = job currently running, 8 = job history; add numbers to run multiple queries
	@jobName       VARCHAR(1000) = '', -- list multiple jobs separated by comma: 'job_1,job_2,job_3'
	@stepName      VARCHAR(1000) = '', -- list multiple steps separated by comma: 'step_1,step_2,step_3'
	@outcome       VARCHAR(20)   = 'ALL',  -- ALL, UNSUCCESSFULL
	@action        VARCHAR(7)    = 'EXECUTE', -- SELECT, EXECUTE, BOTH  
	
/*
Executed as user: NA\srvcmsqlqa.neen. Microsoft (R) SQL Server Execute Package Utility  Version 13.0.5893.48 for 64-bit  Copyright (C) 2016 Microsoft. All rights reserved.    Started:  11:01:52 AM  Failed to execute IS server package because of error 0x80131904. Server: CO-DB-779, Package path: \SSISDB\Integrations\ZoeSECIITInventory\ZoeSECIITInventory_Master.dtsx, Environment reference Id: 318.  Description: In order to execute this package, you need to specify values for the required parameters.  Source: .Net SqlClient Data Provider  Started:  11:01:52 AM  Finished: 11:01:52 AM  Elapsed:  0.203 seconds.  The package execution failed.  The step failed.
-- standard backup jobs
DBA - Backup SYSTEM_DATABASES - FULL,DBA - Backup USER_DATABASES - FULL,DBA - Backup USER_DATABASES - DIFF,DBA - Backup USER_DATABASES - LOG
DBA - Weekly Maintenance

-- job names
SELECT name, enabled 
FROM msdb.dbo.sysjobs 
where name like '%%' 
ORDER BY name;

-- step names
SELECT j.name, s.step_id, s.step_name FROM msdb.dbo.sysjobs AS j LEFT OUTER JOIN msdb.dbo.sysjobsteps AS s ON j.job_id = s.job_id ORDER BY j.name, s.step_id;

-- start a job
EXECUTE msdb.dbo.sp_start_job @job_name  = ''
	                        , @step_name = '';

-- enable a job
EXECUTE msdb.dbo.sp_update_job @job_name = '', @enabled  = 1;   -- 1 = enabled, 0 = disabled

-- enable a schedule
EXEC msdb.dbo.sp_update_schedule @schedule_id = 25, 
	                             @enabled     = 1;     -- 1 = enabled, 0 = disabled

-- change job owner
exec dbo.sp_update_job @job_name=N'INT_ZoeSECIITInventory', @owner_login_name=N'sa';

*/

	-- other variables
	@errorMessage  VARCHAR(1000),
	@sql           NVARCHAR(MAX);


------------------------------------------------------------------------------------------
--// VALIDATE USER INPUT                                                              //--
------------------------------------------------------------------------------------------

IF @selections NOT BETWEEN 1 AND 15
BEGIN
	SET @errorMessage  = 'Invalid @selections value'                                            + CHAR(13) + CHAR(10);
	SET @errorMessage += '     1 = job info'                                                    + CHAR(13) + CHAR(10);
	SET @errorMessage += '     2 = job schedules'                                               + CHAR(13) + CHAR(10);
	SET @errorMessage += '     3 = job info, job schedules'                                     + CHAR(13) + CHAR(10);
	SET @errorMessage += '     4 = job currently running'                                       + CHAR(13) + CHAR(10);
	SET @errorMessage += '     5 = job info, job currently running'                             + CHAR(13) + CHAR(10);
	SET @errorMessage += '     6 = job schedules, job currently running'                        + CHAR(13) + CHAR(10);
	SET @errorMessage += '     7 = job info, job schedules, job currently running'              + CHAR(13) + CHAR(10);
	SET @errorMessage += '     8 = job history'                                                 + CHAR(13) + CHAR(10);
	SET @errorMessage += '     9 = job info, job history'                                       + CHAR(13) + CHAR(10);
	SET @errorMessage += '    10 = job schedules, job history'                                  + CHAR(13) + CHAR(10);
	SET @errorMessage += '    11 = job info, job schedules, job history'                        + CHAR(13) + CHAR(10);
	SET @errorMessage += '    12 = job currently running, job history'                          + CHAR(13) + CHAR(10);
	SET @errorMessage += '    13 = job info, job currently running, job history'                + CHAR(13) + CHAR(10);
	SET @errorMessage += '    14 = job schedules, job currently running, job history'           + CHAR(13) + CHAR(10);
	SET @errorMessage += '    15 = job info, job schedules, job currently running, job history';
	RAISERROR(@errorMessage,16,1);
	RETURN;
END

-- format the list if there are multiple jobs listed.
SET @jobName  = REPLACE(@jobName, ',',''',''');
SET @stepName = REPLACE(@stepName,',',''',''');

-- verify propper input for @action
IF (UPPER(@action) != 'SELECT') AND (UPPER(@action) != 'EXECUTE') AND (UPPER(@action) != 'BOTH')
BEGIN
	RAISERROR('Incorrect input for @action. Enter ''SELECT'', ''EXECUTE'', or ''BOTH''',16,1);
	RETURN;
END

-- report which queries are selected
raiserror(N'The following reports are being run:',0,1) with nowait;
if @selections & 1 = 1 raiserror(N'    - job info',0,1) with nowait;
if @selections & 2 = 2 raiserror(N'    - job schedules',0,1) with nowait;
if @selections & 4 = 4 raiserror(N'    - job currently running',0,1) with nowait;
if @selections & 8 = 8 raiserror(N'    - job history',0,1) with nowait;
raiserror(N'',0,1) with nowait;


------------------------------------------------------------------------------------------
--// JOB INFO                                                                         //--
------------------------------------------------------------------------------------------

IF @selections & 1 = 1
BEGIN
	SET @sql = 
'
SELECT          [j].[job_id] as [- INFO -      job_id],
                CASE [j].[enabled]
                    WHEN 0 THEN ''disabled''
                    WHEN 1 THEN ''enabled''
                END AS [enabled],
                [j].[name],
                [j].[description],
                SUSER_SNAME([j].[owner_sid]) AS [owner],
                [j].[date_created],
                [j].[date_modified],
                [j].[start_step_id],
                [s].[step_id],
                [s].[step_name],
                [s].[command],
                [s].[output_file_name],
                [s].[flags] as [ouput_behavior],
                [s].[database_name],
                [s].[database_user_name], 
                [p].[name] AS [proxy_name],
                CASE [s].[on_success_action]
                    WHEN 1 THEN ''Quit with success''
                    WHEN 2 THEN ''Quit with failure''
                    WHEN 3 THEN ''Go to next step - '' + CAST([s].[step_id] + 1 AS VARCHAR(5))
                    WHEN 4 THEN ''Go to step '' + CAST([s].[on_success_step_id] AS VARCHAR(5))
                END AS [on_success_action],
                CASE [s].[on_fail_action]
                    WHEN 1 THEN ''Quit with success''
                    WHEN 2 THEN ''Quit with failure''
                    WHEN 3 THEN ''Go to next step - '' + CAST([s].[step_id] + 1 AS VARCHAR(5))
                    WHEN 4 THEN ''Go to step '' + CAST([s].[on_fail_step_id] AS VARCHAR(5))
                END AS [on_fail_action],
                CASE [j].[notify_level_email]
                    WHEN 0 THEN ''never''
                    WHEN 1 THEN ''succeeds''
                    WHEN 2 THEN ''fails''
                    WHEN 3 THEN ''completes''
                    WHEN 4 THEN ''In Progress''
                END AS [notify_level_email],
                [o].[email_address] AS [notify_email_address]
FROM            [msdb].[dbo].[sysjobs]      AS [j]
INNER JOIN      [msdb].[dbo].[sysjobsteps]  AS [s] ON [j].[job_id] = [s].[job_id]
LEFT OUTER JOIN [msdb].[dbo].[sysoperators] AS [o] ON [o].[id] = [j].[notify_email_operator_id]
LEFT OUTER JOIN [msdb].[dbo].[sysproxies]   AS [p] ON [s].[proxy_id] = [p].[proxy_id]
WHERE 1=1';

    -- add filtering for job name and/or step name if the user entered values
    IF @jobName != ''
        SET @sql += CHAR(13) + CHAR(10) + '    AND [j].[name] IN (''' + @jobName + ''')';
    IF @stepName != ''
        SET @sql += CHAR(13) + CHAR(10) + '    AND [s].[step_name] IN (''' + @stepName + ''')';

    SET @sql += 
'
ORDER BY
    [j].[name],
    [s].[step_id];
';
	
	IF (UPPER(@action) = 'SELECT') OR (UPPER(@action) = 'BOTH')
		SELECT @sql;
	IF (UPPER(@action) = 'EXECUTE') OR (UPPER(@action) = 'BOTH')
		EXECUTE(@sql);

    RAISERROR(N'------------------------------------------------------------------------
Job Step Output Behavior Values
------------------------------------------------------------------------
 0 - (default) Overwrite output file
 2 - Append to output file
 4 - Write Transact-SQL job step output to step history
 8 - Write log to table (overwrite existing history)
16 - Write log to table (append to existing history)
32 - Write all output to job history
64 - Create a Windows event to use as a signal for the Cmd jobstep to abort',0,1);
END


------------------------------------------------------------------------------------------
--// JOB SCHEDULE INFO                                                                //--
------------------------------------------------------------------------------------------

IF @selections & 2 = 2
BEGIN
	SET @sql = 
'
DECLARE
	@active_end_date        INT,
	@active_end_time        INT,
	@active_start_date      INT,
	@active_start_time      INT,
	@activeEndDT            DATETIME,
	@activeStartDT          DATETIME,
	@i                      INT,
	@freq_interval          INT,
	@freq_type              INT,
	@freq_subday_interval   INT,
	@freq_subday_type       INT,
	@freq_recurrence_factor INT,
	@freq_relative_interval INT,
	@friday                 TINYINT = 0,
	@jobEnabled             VARCHAR(11), 
	@jobName_schedules      NVARCHAR(128), 
	@monday                 TINYINT = 0,
	@next_run_date          INT,
	@next_run_time          INT,
	@nextRunDT              DATETIME,
	@numberOfDays           INT,
	@saturday               TINYINT = 0,
	@scheduleDescription    NVARCHAR(MAX),
	@schedule_id            INT,
	@scheduleEnabled        VARCHAR(11),
	@scheduleName           NVARCHAR(128),
	@sunday                 TINYINT = 0,
	@thursday               TINYINT = 0,
	@tuesday                TINYINT = 0,
	@wednesday              TINYINT = 0;

-- store the schedule info for all jobs
CREATE TABLE #JobSchedules
(
	[ID]                   INT IDENTITY(1,1) PRIMARY KEY,
	[Job_Name]             NVARCHAR(128),
	[Job_Enabled]          VARCHAR(11),
	[Schedule_ID]          INT,
	[Schedule_Name]        NVARCHAR(128),
	[Schedule_Enabled]     VARCHAR(11),
	[Schedule_Description] VARCHAR(1000),
	[Active_Start]         DATETIME,
	[Active_End]           DATETIME,
	[Next_Run]             DATETIME
);

-- loop through all jobs and their schedules
DECLARE curJobSchedules CURSOR FAST_FORWARD FOR
	SELECT 
		[j].[name], 
		CASE [j].[enabled]
			WHEN 0 THEN ''not enabled''
			WHEN 1 THEN ''enabled''
		END, 
		[s].[name],
		CASE [s].[enabled]
			WHEN 0 THEN ''not enabled''
			WHEN 1 THEN ''enabled''
		END,
		[s].[freq_type],
		[s].[freq_interval],
		[s].[freq_subday_type],
		[s].[freq_subday_interval],
		[s].[freq_relative_interval],
		[s].[freq_recurrence_factor],
		[s].[active_start_date],
		[s].[active_end_date],
		[s].[active_start_time],
		[s].[active_end_time],
		[js].[next_run_date],
		[js].[next_run_time],
		[s].[schedule_id]
	FROM 
		[msdb].[dbo].[sysjobs] AS [j]
	LEFT OUTER JOIN	
		[msdb].[dbo].[sysjobschedules] AS [js] 
		ON [j].[job_id] = [js].[job_id]
	LEFT OUTER JOIN 
		[msdb].[dbo].[sysschedules] AS [s] 
		ON [js].[schedule_id] = [s].[schedule_id];

OPEN curJobSchedules;
	FETCH NEXT FROM curJobSchedules INTO
		@jobName_schedules,
		@jobEnabled,
		@scheduleName,
		@scheduleEnabled,
		@freq_type,
		@freq_interval,
		@freq_subday_type,
		@freq_subday_interval,
		@freq_relative_interval,
		@freq_recurrence_factor,
		@active_start_date,
		@active_end_date,
		@active_start_time,
		@active_end_time,
		@next_run_date,
		@next_run_time,
		@schedule_id;
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @scheduleDescription = '''';

		-- the job only runs once at the specified time
		IF @freq_type = 1
			SET @scheduleDescription += ''One time only: '' + CONVERT(VARCHAR(25),msdb.dbo.agent_datetime(@active_start_date,@active_start_time),120);
		
		-- daily
		ELSE IF @freq_type = 4
		BEGIN
			SET @scheduleDescription += ''Every '';

			-- how many days between executions
			IF @freq_interval = 1
				SET @scheduleDescription += ''day'';
			ELSE 
				SET @scheduleDescription += CAST(@freq_interval AS VARCHAR(10)) + '' days'';

			IF @freq_subday_type = 1 -- at the specified time
				SET @scheduleDescription += '' at '' + STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
			ELSE IF @freq_subday_type = 2 -- seconds
				SET @scheduleDescription += '', every '' + CAST(@freq_subday_interval AS VARCHAR(10)) + '' seconds, between '' 
				                         +   STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'') + '' and ''
										 +   STUFF(STUFF(RIGHT(''000000'' + CAST(@active_end_time   AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
			ELSE IF @freq_subday_type = 4 -- minutes
				SET @scheduleDescription += '', every '' + CAST(@freq_subday_interval AS VARCHAR(10)) + '' minutes, between '' 
				                         +   STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'') + '' and ''
										 +   STUFF(STUFF(RIGHT(''000000'' + CAST(@active_end_time   AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
			ELSE IF @freq_subday_type = 8 -- hours
				SET @scheduleDescription += '', every '' + CAST(@freq_subday_interval AS VARCHAR(10)) + '' hours, between '' 
				                         +   STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'') + '' and ''
										 +   STUFF(STUFF(RIGHT(''000000'' + CAST(@active_end_time   AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
		END

		-- weekly
		ELSE IF @freq_type = 8
		BEGIN
			-- determine which days are selected
			IF (@freq_interval >= 64) SELECT @saturday  = 1, @freq_interval -= 64;
			IF (@freq_interval >= 32) SELECT @friday    = 1, @freq_interval -= 32;
			IF (@freq_interval >= 16) SELECT @thursday  = 1, @freq_interval -= 16;
			IF (@freq_interval >=  8) SELECT @wednesday = 1, @freq_interval -=  8;
			IF (@freq_interval >=  4) SELECT @tuesday   = 1, @freq_interval -=  4;
			IF (@freq_interval >=  2) SELECT @monday    = 1, @freq_interval -=  2;
			IF (@freq_interval >=  1) SELECT @sunday    = 1, @freq_interval -=  1;

			SET @numberOfDays = @monday + @tuesday + @wednesday + @thursday + @friday + @saturday + @sunday;
			SET @i = 1; -- used to keep track of how many days have been processed

			SET @scheduleDescription += ''Every '';

			IF @freq_recurrence_factor > 1 -- number of weeks between execution; if 0, then it is not used
				SET @scheduleDescription += CAST(@freq_recurrence_factor AS VARCHAR(10)) + '' weeks on '';
			
			-- add the selected days to the description
			IF @monday = 1
			BEGIN
				IF      (@i = 1 AND @i != @numberOfDays) SET @scheduleDescription += ''Monday'';
				ELSE IF (@i = 1 AND @i  = @numberOfDays) SET @scheduleDescription += ''Monday at '' + STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
				ELSE IF (@i = @numberOfDays)             SET @scheduleDescription += '', and Monday at '' + STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
				ELSE                                     SET @scheduleDescription += '', Monday'';
				SET @i += 1;
			END
			
			IF @tuesday = 1
			BEGIN
				IF      (@i = 1 AND @i != @numberOfDays) SET @scheduleDescription += ''Tuesday'';
				ELSE IF (@i = 1 AND @i  = @numberOfDays) SET @scheduleDescription += ''Tuesday at '' + STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
				ELSE IF (@i = @numberOfDays)             SET @scheduleDescription += '', and Tuesday at '' + STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
				ELSE                                     SET @scheduleDescription += '', Tuesday'';
				SET @i += 1;
			END
			
			IF @wednesday = 1
			BEGIN
				IF      (@i = 1 AND @i != @numberOfDays) SET @scheduleDescription += ''Wednesday'';
				ELSE IF (@i = 1 AND @i  = @numberOfDays) SET @scheduleDescription += ''Wednesday at '' + STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
				ELSE IF (@i = @numberOfDays)             SET @scheduleDescription += '', and Wednesday at '' + STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
				ELSE                                     SET @scheduleDescription += '', Wednesday'';
				SET @i += 1;
			END
			
			IF @thursday = 1
			BEGIN
				IF      (@i = 1 AND @i != @numberOfDays) SET @scheduleDescription += ''Thursday'';
				ELSE IF (@i = 1 AND @i  = @numberOfDays) SET @scheduleDescription += ''Thursday at '' + STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
				ELSE IF (@i = @numberOfDays)             SET @scheduleDescription += '', and Thursday at '' + STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
				ELSE                                     SET @scheduleDescription += '', Thursday'';
				SET @i += 1;
			END
			
			IF @friday = 1
			BEGIN
				IF      (@i = 1 AND @i != @numberOfDays) SET @scheduleDescription += ''Friday'';
				ELSE IF (@i = 1 AND @i  = @numberOfDays) SET @scheduleDescription += ''Friday at '' + STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
				ELSE IF (@i = @numberOfDays)             SET @scheduleDescription += '', and Friday at '' + STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
				ELSE                                     SET @scheduleDescription += '', Friday'';
				SET @i += 1;
			END
			
			IF @saturday = 1
			BEGIN
				IF      (@i = 1 AND @i != @numberOfDays) SET @scheduleDescription += ''Saturday'';
				ELSE IF (@i = 1 AND @i  = @numberOfDays) SET @scheduleDescription += ''Saturday at '' + STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
				ELSE IF (@i = @numberOfDays)             SET @scheduleDescription += '', and Saturday at '' + STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
				ELSE                                     SET @scheduleDescription += '', Saturday'';
				SET @i += 1;
			END
			
			IF @sunday = 1
			BEGIN
				IF      (@i = 1 AND @i != @numberOfDays) SET @scheduleDescription += ''Sunday'';
				ELSE IF (@i = 1 AND @i  = @numberOfDays) SET @scheduleDescription += ''Sunday at '' + STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
				ELSE IF (@i = @numberOfDays)             SET @scheduleDescription += '', and Sunday at '' + STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
				ELSE                                     SET @scheduleDescription += '', Sunday'';
				SET @i += 1;
			END

			-- reset the day tracking variables
			SET @monday    = 0;
			SET @tuesday   = 0;
			SET @wednesday = 0;
			SET @thursday  = 0;
			SET @friday    = 0;
			SET @saturday  = 0;
			SET @sunday    = 0;
		END

		-- monthly
		ELSE IF @freq_type = 16
		BEGIN
			SET @scheduleDescription += ''Every '';

			IF @freq_recurrence_factor > 1 -- number of months between execution; if 0, then it is not used
				SET @scheduleDescription += CAST(@freq_recurrence_factor AS VARCHAR(10)) + '' months on the '';

			SET @scheduleDescription += CAST(@freq_interval AS VARCHAR(5));

			-- add the appropriate suffix and time
			IF (@freq_interval = 1 OR @freq_interval = 21 OR @freq_interval = 31) 
				SET @scheduleDescription += ''st day of the month at '' + STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
			ELSE IF (@freq_interval = 2 OR @freq_interval = 22) 
				SET @scheduleDescription += ''nd day of the month at '' + STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
			ELSE IF (@freq_interval = 3 OR @freq_interval = 23) 
				SET @scheduleDescription += ''rd day of the month at '' + STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
			ELSE
				SET @scheduleDescription += ''th day of the month at '' + STUFF(STUFF(RIGHT(''000000'' + CAST(@active_start_time AS VARCHAR(6)),6),5,0,'':''),3,0,'':'');
		END

		-- monthly, relative
		ELSE IF @freq_type = 32
		BEGIN
			SET @scheduleDescription += ''Every '';

			IF @freq_recurrence_factor > 1 -- number of months between execution; if 0, then it is not used
				SET @scheduleDescription += CAST(@freq_recurrence_factor AS VARCHAR(10)) + '' months on the '';
			
			-- add which occurance during the month; 0 = unused
			IF (@freq_relative_interval =  1) SET @scheduleDescription += ''first '';
			IF (@freq_relative_interval =  2) SET @scheduleDescription += ''second '';
			IF (@freq_relative_interval =  4) SET @scheduleDescription += ''third '';
			IF (@freq_relative_interval =  8) SET @scheduleDescription += ''fourth '';
			IF (@freq_relative_interval = 16) SET @scheduleDescription += ''last '';

			-- which relative day it occurs on
			IF (@freq_interval =  1) SET @scheduleDescription += ''Sunday'';
			IF (@freq_interval =  2) SET @scheduleDescription += ''Monday'';
			IF (@freq_interval =  3) SET @scheduleDescription += ''Tuesday'';
			IF (@freq_interval =  4) SET @scheduleDescription += ''Wednesday'';
			IF (@freq_interval =  5) SET @scheduleDescription += ''Thursday'';
			IF (@freq_interval =  6) SET @scheduleDescription += ''Friday'';
			IF (@freq_interval =  7) SET @scheduleDescription += ''Saturday'';
			IF (@freq_interval =  8) SET @scheduleDescription += ''day'';
			IF (@freq_interval =  9) SET @scheduleDescription += ''weekday'';
			IF (@freq_interval = 10) SET @scheduleDescription += ''weekend day'';

			SET @scheduleDescription += '' of the month'';
		END

		-- starts when sql server agent service starts
		ELSE IF @freq_type = 64
			SET @scheduleDescription += ''Runs when SQL Server Agent service starts'';

		-- starts when the computer is idle
		ELSE IF @freq_type = 128
			SET @scheduleDescription += ''Runs when computer is idle'';

		-- convert the start and end datetime formats
		SET @activeStartDT = msdb.dbo.agent_datetime(@active_start_date,@active_start_time);
		SET @activeEndDT   = msdb.dbo.agent_datetime(@active_end_date,@active_end_time);

		-- conver the next run date format
		IF @next_run_date != 0
			SET @nextRunDT = msdb.dbo.agent_datetime(@next_run_date,@next_run_time);
		ELSE -- if job runs when agent services start or when computer is idle, there is no run time specified
			SET @nextRunDT = CAST(''1900-01-01'' AS DATETIME);
	
		-- insert the info into temp table
		INSERT INTO #JobSchedules ([Job_Name], [Job_Enabled], [Schedule_ID], [Schedule_Name], [Schedule_Enabled], [Schedule_Description], [Active_Start], [Active_End], [Next_Run])
		VALUES (@jobName_schedules, @jobEnabled, @schedule_id, @scheduleName, @scheduleEnabled, @scheduleDescription, @activeStartDT, @activeEndDT, @nextRunDT);

		FETCH NEXT FROM curJobSchedules INTO
			@jobName_schedules,
			@jobEnabled,
			@scheduleName,
			@scheduleEnabled,
			@freq_type,
			@freq_interval,
			@freq_subday_type,
			@freq_subday_interval,
			@freq_relative_interval,
			@freq_recurrence_factor,
			@active_start_date,
			@active_end_date,
			@active_start_time,
			@active_end_time,
			@next_run_date,
			@next_run_time,
			@schedule_id;
	END
CLOSE curJobSchedules;
DEALLOCATE curJobSchedules;

SELECT 
	[Job_Name] AS [- SCHEDULES -      Job_Name],
	[Job_Enabled],
	[Schedule_ID],
	[Schedule_Name],
	[Schedule_Enabled],
	[Schedule_Description],
	RIGHT(CAST(SYSDATETIMEOFFSET() AS VARCHAR(200)),6) [UTC_Offset],
    [Active_Start],
	[Active_End],
	[Next_Run]
FROM 
	#JobSchedules
WHERE 1=1';

	-- add filtering for job name and/or step name if the user entered values
	IF @jobName != ''
		SET @sql += CHAR(13) + CHAR(10) + '    AND [Job_Name] IN (''' + @jobName + ''')';
	
	SET @sql += 
'
ORDER BY
	[Job_Name];

DROP TABLE #JobSchedules;
';
	
	IF (UPPER(@action) = 'SELECT') OR (UPPER(@action) = 'BOTH')
		SELECT @sql;
	IF (UPPER(@action) = 'EXECUTE') OR (UPPER(@action) = 'BOTH')
		EXECUTE(@sql);
END



---------------------------------------------------------------
--// JOBS THAT ARE CURRENTLY RUNNING                       //--
---------------------------------------------------------------

IF @selections & 4 = 4
BEGIN
	declare @jobName2 VARCHAR(1000) = N''''+@jobName+N'''';

set @sql='
    SELECT          [p].[spid] AS [- RUNNING -      spid],
                    [ja].[job_id],
                    [j].[name] AS [job_name],
                    [ja].[start_execution_date], 
                    [ElapsedTime] = 
                        /* days    */ CAST((DATEDIFF(SECOND,[ja].[start_execution_date],GETDATE()) / 86400) AS VARCHAR(6)) + '' days '' + 
                        /* hours   */ RIGHT(''00'' + CAST((((DATEDIFF(SECOND,[ja].[start_execution_date],GETDATE()) - ((DATEDIFF(SECOND,[ja].[start_execution_date],GETDATE()) / 86400) * 86400))) / 3600)   AS VARCHAR(2)),2) + '':'' +
                        /* minutes */ RIGHT(''00'' + CAST(((((DATEDIFF(SECOND,[ja].[start_execution_date],GETDATE()) - ((DATEDIFF(SECOND,[ja].[start_execution_date],GETDATE()) / 86400) * 86400)) - (((DATEDIFF(SECOND,[ja].[start_execution_date],GETDATE()) - ((DATEDIFF(SECOND,[ja].[start_execution_date],GETDATE()) / 86400) * 86400))) / 3600) * 3600)) / 60) AS VARCHAR(2)),2) + '':'' +
                        /* seconds */ RIGHT(''00'' + CAST((((((DATEDIFF(SECOND,[ja].[start_execution_date],GETDATE()) - ((DATEDIFF(SECOND,[ja].[start_execution_date],GETDATE()) / 86400) * 86400)) - (((DATEDIFF(SECOND,[ja].[start_execution_date],GETDATE()) - ((DATEDIFF(SECOND,[ja].[start_execution_date],GETDATE()) / 86400) * 86400))) / 3600) * 3600)) - ((((DATEDIFF(SECOND,[ja].[start_execution_date],GETDATE()) - ((DATEDIFF(SECOND,[ja].[start_execution_date],GETDATE()) / 86400) * 86400)) - (((DATEDIFF(SECOND,[ja].[start_execution_date],GETDATE()) - ((DATEDIFF(SECOND,[ja].[start_execution_date],GETDATE()) / 86400) * 86400))) / 3600) * 3600)) / 60) *60)) AS VARCHAR(2)),2),     
                    [js].[step_id],
                    [js].[step_name] AS [current_step],
                    [js].[subsystem],
                    [js].[command],
                    ''
    ------------------------------------------------------------------------------------------------
    --// '' + QUOTENAME([j].[name]) + '' - STEPS THAT HAVE COMPLETED
    ------------------------------------------------------------------------------------------------
    
    SELECT     [j].[name],
               [js].[step_id],
               [js].[step_name],
               [msdb].[dbo].[agent_datetime]([js].[last_run_date],[js].[last_run_time]) AS [started],
               DATEADD (  SECOND,
                          CAST(RIGHT(RIGHT(''''000000'''' + CAST([js].[last_run_duration] AS VARCHAR(6)),6),2) AS INT),
                          DATEADD (  MINUTE,
                                     CAST(SUBSTRING(RIGHT(''''000000'''' + CAST([js].[last_run_duration] AS VARCHAR(6)),6),3,2) AS INT),
                                     DATEADD (  HOUR,
                                                CAST(LEFT(RIGHT(''''000000'''' + CAST([js].[last_run_duration] AS VARCHAR(6)),6),2) AS INT),
                                                [msdb].[dbo].[agent_datetime]([js].[last_run_date],[js].[last_run_time])
                                             )
                                  )
                       ) AS [ended],
               STUFF(STUFF(RIGHT(''''000000'''' + CAST([js].[last_run_duration] AS VARCHAR(6)),6),5,0,'''':''''),3,0,'''':'''') AS [duration],
               [js].[subsystem],
               [js].[command],
               [js].[output_file_name],
               [js].[database_name],
               [js].[database_user_name], 
               CASE [js].[on_success_action]
                   WHEN 1 THEN ''''Quit with success''''
                   WHEN 2 THEN ''''Quit with failure''''
                   WHEN 3 THEN ''''Go to next step - '''' + CAST([js].[step_id] + 1 AS VARCHAR(5))
                   WHEN 4 THEN ''''Go to step '''' + CAST([js].[on_success_step_id] AS VARCHAR(5))
               END AS [on_success_action],
               CASE [js].[on_fail_action]
                   WHEN 1 THEN ''''Quit with success''''
                   WHEN 2 THEN ''''Quit with failure''''
                   WHEN 3 THEN ''''Go to next step - '''' + CAST([js].[step_id] + 1 AS VARCHAR(5))
                   WHEN 4 THEN ''''Go to step '''' + CAST([js].[on_fail_step_id] AS VARCHAR(5))
               END AS [on_fail_action]
    FROM       [msdb].[dbo].[sysjobs] AS [j]
    INNER JOIN [msdb].[dbo].[sysjobsteps] AS [js] ON [j].[job_id] = [js].[job_id]
    WHERE      [j].[job_id] = '''''' + CAST([j].[job_id] AS VARCHAR(36)) + ''''''
               AND [msdb].[dbo].[agent_datetime]([js].[last_run_date],[js].[last_run_time]) >= '''''' + CONVERT(VARCHAR(20),[ja].[start_execution_date],120) + ''''''
    ORDER BY   [msdb].[dbo].[agent_datetime]([js].[last_run_date],[js].[last_run_time]);'' AS [DetailsForCompletedJobSteps]
    FROM            [msdb].[dbo].[sysjobactivity] AS [ja] 
    INNER JOIN      [msdb].[dbo].[sysjobs] AS [j] ON [ja].[job_id] = [j].[job_id]
    INNER JOIN      [msdb].[dbo].[sysjobsteps] AS [js] ON [ja].[job_id] = [js].[job_id]
                                                 AND [js].[step_id] = CASE 
                                                                          WHEN [ja].[last_executed_step_id] IS NULL THEN [j].[start_step_id]
                                                                          ELSE (  SELECT CASE [js2].[last_run_outcome]
                                                                                             WHEN 0 THEN CASE [js2].[on_fail_action] 
                                                                                                             WHEN 3 THEN [js2].[step_id] + 1
                                                                                                             WHEN 4 THEN [js2].[on_fail_step_id]
                                                                                                         END
                                                                                             WHEN 1 THEN CASE [js2].[on_success_action]
                                                                                                             WHEN 3 THEN [js2].[step_id] + 1
                                                                                                             WHEN 4 THEN [js2].[on_success_step_id]
                                                                                                         END
                                                                                         END
                                                                                  FROM   [msdb].[dbo].[sysjobsteps] AS [js2]
                                                                                  WHERE  [job_id] = [j].[job_id] 
                                                                                         AND [step_id] = [ja].[last_executed_step_id]
                                                                               )
                                                                      END    
    LEFT OUTER JOIN [master].[dbo].[sysprocesses] AS [p] ON [master].[dbo].[fn_varbintohexstr](CONVERT(varbinary(16), [j].[job_id])) = SUBSTRING(REPLACE([program_name], ''SQLAgent - TSQL JobStep (Job '', ''''), 1, 34)
    WHERE           [ja].[session_id] = (SELECT TOP 1 [session_id] FROM [msdb].[dbo].[syssessions] ORDER BY [agent_start_date] DESC)
                    AND [start_execution_date] IS NOT NULL
                    AND [stop_execution_date] IS NULL';
if len(@jobname)>0
begin
	set @sql=@sql+'
                    AND [j].[name] in ('''+@jobName+''')';
end;

set @sql=@sql+'
    ORDER BY        [j].[name];';
execute(@sql);

END;



------------------------------------------------------------------------------------------
--// JOB HISTORY INFO                                                                 //--
------------------------------------------------------------------------------------------

IF @selections & 8 = 8
BEGIN
	SET @sql = '
SELECT          [j].[name] AS [- HISTORY -      name],
                [h].[step_id],
                [h].[step_name], 
                RIGHT(CAST(SYSDATETIMEOFFSET() AS VARCHAR(200)),6) [UTC_Offset],
                [StartDatetime] = [msdb].[dbo].[agent_datetime]([h].[run_date],[h].[run_time]),
                [EndDatetime] = DATEADD
                                (
                                    SECOND, 
                                    
                                    (([h].[run_duration] / 1000000) * 86400) +  -- days * 86,400 seconds/day
                                    ((([h].[run_duration] - (([h].[run_duration] / 1000000)  * 1000000)) / 10000) * 3600) +  -- hours * 3,600 seconds/hour
                                    ((([h].[run_duration] - (([h].[run_duration] / 10000) * 10000))  / 100) * 60) +  -- minutes * 60 seconds/minute
                                    ([h].[run_duration] - ([h].[run_duration] / 100) * 100),  -- seconds 
                                    
                                    CAST(STR([h].[run_date], 8, 0) AS DATETIME) + -- date
                                    CAST(STUFF(STUFF(RIGHT(''000000'' + CAST ([h].[run_time] AS VARCHAR(6)), 6), 5, 0, '':''), 3, 0, '':'') AS DATETIME) -- time
                                ),
                [Duration] = STUFF(STUFF(REPLACE(STR([run_duration], 6, 0), '' '', ''0''), 3, 0, '':''), 6, 0, '':''), 
                [run_status] = CASE [h].[run_status]
                                   WHEN 0 THEN ''Failed''
                                   WHEN 1 THEN ''Succeeded''
                                   WHEN 2 THEN ''Retry''
                                   WHEN 3 THEN ''Canceled''
                               END, 
                [h].[message], 
                [s].[command], 
                [notify_email_desc] = CASE [j].[notify_level_email]
                                          WHEN 0 THEN ''never''
                                          WHEN 1 THEN ''succeeds''
                                          WHEN 2 THEN ''fails''
                                          WHEN 3 THEN ''completes''
                                          WHEN 4 THEN ''In Progress''
                                      END,
                [notify_email_address] = [o].[email_address],
                [owner] = SUSER_SNAME([j].[owner_sid])
FROM            [msdb].[dbo].[sysjobs] AS [j]
INNER JOIN      [msdb].[dbo].[sysjobhistory] AS [h] ON [j].[job_id] = [h].[job_id]
LEFT OUTER JOIN [msdb].[dbo].[sysjobsteps] AS [s] ON [j].[job_id] = [s].[job_id] AND [h].[step_id] = [s].[step_id]
LEFT OUTER JOIN [msdb].[dbo].[sysoperators] AS [o] ON [o].[id] = [j].[notify_email_operator_id]
WHERE           1=1';

	-- add filtering for job name and/or step name if the user entered values
	IF @jobName != ''
		SET @sql += CHAR(13) + CHAR(10) + '                AND [j].[name] IN (''' + @jobName + ''')';
	IF @stepName != ''
		SET @sql += CHAR(13) + CHAR(10) + '                AND [s].[step_name] IN (''' + @stepName + ''')';

	-- add filtering for job outcome if the user entered values
	IF @outcome = 'UNSUCCESSFULL'
		SET @sql += CHAR(13) + CHAR(10) + '                AND [h].[run_status] != 1';

	SET @sql += 
'
                --AND [h].[run_status] != 1 -- 0 = Failed, 1 = Succeeded, 2 = Retry, 3 = Canceled
                --AND [h].[run_date] >= 20180712
                --AND [h].[run_date] = 20160406 --yyyymmdd  
                --AND [h].[run_date] = (DATEPART(YEAR,GETDATE()) * 10000) + (DATEPART(MONTH,GETDATE()) * 100) + DATEPART(DAY,GETDATE()) --today
                --AND [h].[run_time] < 93700    --HHMMSS
ORDER BY        [msdb].[dbo].[agent_datetime]([h].[run_date],[h].[run_time]) DESC, [j].[name], [h].[step_id] DESC,
                --[j].[name], [msdb].[dbo].[agent_datetime]([h].[run_date],[h].[run_time]) ASC, [h].[step_id] ASC,
                --[j].[name], 
                --CAST([h].[run_date] AS VARCHAR(8)) + CAST([h].[run_time] AS VARCHAR(6)) ASC, [h].[step_id] ASC,
                --[h].[run_date] DESC, 
                --[h].[run_time] DESC,
                --[h].[step_id],
                [o].[email_address];
'
	
	IF (UPPER(@action) = 'SELECT') OR (UPPER(@action) = 'BOTH')
		SELECT @sql;
	IF (UPPER(@action) = 'EXECUTE') OR (UPPER(@action) = 'BOTH')
		EXECUTE(@sql);
END;
