USE CentralAdmin;
GO

IF OBJECT_ID('dbo.usp_JobInfo','P') IS NULL
	EXEC('CREATE PROCEDURE dbo.usp_JobInfo AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.usp_JobInfo
    @displayResults INT           = 7,
	@jobName        VARCHAR(1000) = '',
	@stepName       VARCHAR(1000) = '',
	@notSuccessful  CHAR(1)       = 'N',
	@selectQuery    CHAR(1)       = 'N',
	@help           CHAR(1)       = '',
	@getVersion     BIT           = 0
AS

SET NOCOUNT ON;

DECLARE 
	@message   VARCHAR(MAX),
	@jobHistQuery   BIT = 0,
	@jobInfoQuery   BIT = 0,
	@jobSchedQuery  BIT = 0,
	@sql            VARCHAR(MAX),
	@version        VARCHAR(10);

SET @version = '1.1';



------------------------------------------------------------------------------------------
--// HELP INFO                                                                        //--
------------------------------------------------------------------------------------------

-- return the version if requested
IF @getVersion = 1 
BEGIN
	SELECT @version AS 'version';
	RETURN;
END

-- if user asked for help, display the command and info to use it
IF (@help != '') AND (UPPER(@help) != 'N') AND (UPPER(@help) != 'NO')
BEGIN
	SET @message = '
/***********************************************************************************************************************************************
* 
* usp_JobInfo ' + @version + '
* 
* Author: James Lutsey
* Date:   04/13/2016
* 
* Purpose: Get info about jobs, their history, and their schedules
* 
* Notes: 
*     1. Set @displayResults to indicate if you want job info and/or job history and/or job schedules (default is all)
*     2. If wanted, enter the job and/or step name(s). (default is all jobs) Use the commented out script to get job and step names
*     3. You can select the queries (@selectQuery = ''Y'') to edit the filetering criteria
*     4. Get the version: EXECUTE [CentralAdmin].[dbo].[usp_JobInfo] @getVersion = 1;
* 
* Version History:
*     1.1 - 07/11/2016 - Added the output file name for the job steps to the ''Job Info'' section
* 
************************************************************************************************************************************************/

------------------------------------------------------------------------------------------
--// COMMAND                                                                          //--
------------------------------------------------------------------------------------------

EXECUTE CentralAdmin.dbo.usp_JobInfo  --@help = ''Y''
    @displayResults = 7,  -- 1 = job info, 2 = job history, 4 = job schedules; add numbers to run multiple queries
	@jobName        = '''', -- list multiple jobs separated by comma: ''job_1,job_2,job_3''
	@stepName       = '''', -- list multiple steps separated by comma: ''step_1,step_2,step_3''

	@notSuccessful  = ''N'', -- ''Y'' to select only the job history steps that were not successful
	@selectQuery    = ''N''; -- ''Y'' to select the query being used


------------------------------------------------------------------------------------------
--// @displayResults VALUES                                                           //--
------------------------------------------------------------------------------------------

    1 = job info
    2 = job history
    3 = job info, job history
    4 = job schedules
    5 = job info, job schedules
    6 = job history, job schedules
    7 = job info, job history, job schedules


------------------------------------------------------------------------------------------
--// OTHER JOB COMMANDS                                                               //--
------------------------------------------------------------------------------------------

-- job names
SELECT name FROM msdb.dbo.sysjobs ORDER BY name;

-- step names
SELECT j.name, s.step_id, s.step_name FROM msdb.dbo.sysjobs AS j LEFT OUTER JOIN msdb.dbo.sysjobsteps AS s ON j.job_id = s.job_id ORDER BY j.name, s.step_id;

-- start a job
EXECUTE msdb.dbo.sp_start_job
	  @job_name = ''''
	, @step_name = '''';

-- enable a job
EXECUTE msdb.dbo.sp_update_job 
    @job_name='''',
	@enabled = 1; -- 1 = enabled, 0 = disabled

-- enable a schedule
EXEC msdb.dbo.sp_update_schedule 
    @schedule_id = , 
	@enabled = 1; -- 1 = enabled, 0 = disabled'

	PRINT @message;
	RETURN;
END

------------------------------------------------------------------------------------------
--// VALIDATE USER INPUT                                                              //--
------------------------------------------------------------------------------------------

IF @displayResults NOT BETWEEN 1 AND 7
BEGIN
	SET @message  = 'Invalid @displayResults value'      + CHAR(13) + CHAR(10);
	SET @message += '    1 = job info'                   + CHAR(13) + CHAR(10);
	SET @message += '    2 = job history'                + CHAR(13) + CHAR(10);
	SET @message += '    3 = job info, job history'      + CHAR(13) + CHAR(10);
	SET @message += '    4 = job schedules'              + CHAR(13) + CHAR(10);
	SET @message += '    5 = job info, job schedules'    + CHAR(13) + CHAR(10);
	SET @message += '    6 = job history, job schedules' + CHAR(13) + CHAR(10);
	SET @message += '    7 = job info, job history, job schedules';
	RAISERROR(@message,16,1);
	RETURN;
END

-- format the list if there are multiple jobs listed.
SET @jobName  = REPLACE(@jobName,', ',',');
SET @jobName  = REPLACE(@jobName, ',',''',''');
SET @stepName = REPLACE(@stepName,', ',',');
SET @stepName = REPLACE(@stepName,',',''',''');

-- determine which queries are to be run
IF @displayResults >= 4
BEGIN
	SET @jobSchedQuery = 1;
	SET @displayResults -= 4;
END

IF @displayResults >= 2
BEGIN
	SET @jobHistQuery = 1;
	SET @displayResults -= 2;
END

IF @displayResults >= 1
BEGIN
	SET @jobInfoQuery = 1;
	SET @displayResults -= 1;
END


------------------------------------------------------------------------------------------
--// JOB INFO                                                                         //--
------------------------------------------------------------------------------------------

IF @jobInfoQuery = 1
BEGIN
	SET @sql = 
'
SELECT
	j.job_id,
	CASE j.enabled
		WHEN 0 THEN ''disabled''
		WHEN 1 THEN ''enabled''
	END AS [enabled],
	j.name,
	j.description,
	SUSER_SNAME(j.owner_sid) AS [owner],
	j.date_created,
	j.date_modified,

	j.start_step_id,
	s.step_id,
	s.step_name,
	s.command,
	s.output_file_name,
	s.database_name,
	s.database_user_name, 
	CASE s.on_success_action
		WHEN 1 THEN ''Quit with success''
		WHEN 2 THEN ''Quit with failure''
		WHEN 3 THEN ''Go to next step''
		WHEN 4 THEN ''Go to step ''''on_success_step_id''''''
	END AS [on_success_action],
	s.on_success_step_id,
	CASE s.on_fail_action
		WHEN 1 THEN ''Quit with success''
		WHEN 2 THEN ''Quit with failure''
		WHEN 3 THEN ''Go to next step''
		WHEN 4 THEN ''Go to step ''''on_fail_step_id''''''
	END AS [on_fail_action],
	s.on_fail_step_id,
	CASE j.notify_level_email
		WHEN 0 THEN ''never''
		WHEN 1 THEN ''succeeds''
		WHEN 2 THEN ''fails''
		WHEN 3 THEN ''completes''
		WHEN 4 THEN ''In Progress''
	END AS [notify_level_email],
	o.email_address AS [notify_email_address]

FROM
	msdb.dbo.sysjobs AS j
INNER JOIN
	msdb.dbo.sysjobsteps AS s
	ON j.job_id = s.job_id
LEFT OUTER JOIN 
	msdb.dbo.sysoperators AS o 
	ON o.id = j.notify_email_operator_id
WHERE 1=1';

	-- add filtering for job name and/or step name if the user entered values
	IF @jobName != ''
		SET @sql += CHAR(13) + CHAR(10) + '    AND j.name IN (''' + @jobName + ''')';
	IF @stepName != ''
		SET @sql += CHAR(13) + CHAR(10) + '    AND s.step_name IN (''' + @stepName + ''')';
	
	SET @sql += 
'
ORDER BY
	j.name,
	s.step_id;
';
	
	-- select the query if the user specified
	IF UPPER(@selectQuery) = N'Y'
		SELECT @sql AS 'Query_JobInfo';

	-- execute the query
	EXECUTE(@sql);
END


------------------------------------------------------------------------------------------
--// JOB HISTORY INFO                                                                 //--
------------------------------------------------------------------------------------------

IF @jobHistQuery = 1
BEGIN
	SET @sql = 
'
SELECT 
	j.name, 
	h.step_id,
	h.step_name, 
	[StartDatetime] = 
		CAST(STR(h.run_date, 8, 0) AS DATETIME) + -- date
		CAST(
			STUFF(
				STUFF(
					RIGHT(''000000'' + CAST(h.run_time AS VARCHAR(6)), 6), 
					5, 0, '':''), 
				3, 0, '':'')  
		AS DATETIME), -- time
	[EndDatetime] = 
		DATEADD
		(
			SECOND, 

			((h.run_duration / 1000000) * 86400) +  -- days * 86,400 seconds/day
			(((h.run_duration - ((h.run_duration / 1000000)  * 1000000)) / 10000) * 3600) +  -- hours * 3,600 seconds/hour
			(((h.run_duration - ((h.run_duration / 10000) * 10000))  / 100) * 60) +  -- minutes * 60 seconds/minute
			(h.run_duration - (h.run_duration / 100) * 100),  -- seconds 

			CAST(STR(h.run_date, 8, 0) AS DATETIME) + -- date
			CAST(STUFF(STUFF(RIGHT(''000000'' + CAST (h.run_time AS VARCHAR(6)), 6), 5, 0, '':''), 3, 0, '':'') AS DATETIME) -- time
		),
	[Duration] = STUFF(STUFF(REPLACE(STR(run_duration, 6, 0), '' '', ''0''), 3, 0, '':''), 6, 0, '':''), 
	CASE h.run_status
		WHEN 0 THEN ''Failed''
		WHEN 1 THEN ''Succeeded''
		WHEN 2 THEN ''Retry''
		WHEN 3 THEN ''Canceled''
	END AS [run_status], 
	h.message, 
	s.command, 
	CASE j.notify_level_email
		WHEN 0 THEN ''never''
		WHEN 1 THEN ''succeeds''
		WHEN 2 THEN ''fails''
		WHEN 3 THEN ''completes''
		WHEN 4 THEN ''In Progress''
	END AS [notify_level_email],
	o.email_address AS [notify_email_address],
	SUSER_SNAME(j.owner_sid) AS [owner]
FROM 
	msdb.dbo.sysjobs AS j
INNER JOIN  
	msdb.dbo.sysjobhistory AS h 
	ON j.job_id = h.job_id
LEFT OUTER JOIN 
	msdb.dbo.sysjobsteps AS s
	ON j.job_id = s.job_id
	AND h.step_id = s.step_id
LEFT OUTER JOIN 
	msdb.dbo.sysoperators AS o 
	ON o.id = j.notify_email_operator_id
WHERE 1=1';

	-- add filtering for job name and/or step name if the user entered values
	IF @jobName != ''
		SET @sql += CHAR(13) + CHAR(10) + '    AND j.name IN (''' + @jobName + ''')';
	IF @stepName != ''
		SET @sql += CHAR(13) + CHAR(10) + '    AND s.step_name IN (''' + @stepName + ''')';

	-- add filtering for only job history steps that were not successful if the user indicated
	IF UPPER(@notSuccessful) = N'Y'
		SET @sql += CHAR(13) + CHAR(10) + '    AND h.run_status != 1 -- 0 = Failed, 1 = Succeeded, 2 = Retry, 3 = Canceled';
	SET @sql += 
'
	--AND h.run_date >= 20160330
	--AND h.run_date = 20160406 --yyyymmdd  
	--AND h.run_date = (DATEPART(YEAR,GETDATE()) * 10000) + (DATEPART(MONTH,GETDATE()) * 100) + DATEPART(DAY,GETDATE()) --today
	--AND h.run_time < 93700    --HHMMSS
ORDER BY 
	msdb.dbo.agent_datetime(h.run_date,h.run_time) ASC, j.name, h.step_id ASC,
	--j.name, msdb.dbo.agent_datetime(h.run_date,h.run_time) ASC, h.step_id ASC,
	--j.name, 
	--CAST(h.run_date AS VARCHAR(8)) + CAST(h.run_time AS VARCHAR(6)) ASC, h.step_id ASC,
	--h.run_date DESC, 
	--h.run_time DESC,
	--h.step_id,
	o.email_address;
';
	
	-- select the query if the user specified
	IF UPPER(@selectQuery) = N'Y'
		SELECT @sql AS 'Query_JobHistory';

	-- execute the query
	EXECUTE(@sql);
END


------------------------------------------------------------------------------------------
--// JOB SCHEDULE INFO                                                                //--
------------------------------------------------------------------------------------------

IF @jobSchedQuery = 1
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
	[Job_Name],
	[Job_Enabled],
	[Schedule_ID],
	[Schedule_Name],
	[Schedule_Enabled],
	[Schedule_Description],
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
	
	-- select the query if the user specified
	IF UPPER(@selectQuery) = N'Y'
		SELECT @sql AS 'Query_JobSchedules';

	-- execute the query
	EXECUTE(@sql);
END



