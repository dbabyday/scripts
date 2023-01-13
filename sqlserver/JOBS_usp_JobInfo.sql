EXECUTE CentralAdmin.dbo.usp_JobInfo  --@help = 'Y'
    @displayResults = 7,  -- 1 = job info, 2 = job history, 4 = job schedules; add numbers to run multiple queries
	@jobName        = '', -- list multiple jobs separated by comma: 'job_1,job_2,job_3'
	@stepName       = '', -- list multiple steps separated by comma: 'step_1,step_2,step_3'

	@notSuccessful  = 'N', -- 'Y' to select only the job history steps that were not successful
	@selectQuery    = 'N'; -- 'Y' to select the query being used
	
/*
-- standard backup jobs
DBA - Backup SYSTEM_DATABASES - FULL,DBA - Backup USER_DATABASES - FULL,DBA - Backup USER_DATABASES - DIFF,DBA - Backup USER_DATABASES - LOG

-- job names
SELECT name FROM msdb.dbo.sysjobs ORDER BY name;

-- step names
SELECT j.name, s.step_id, s.step_name FROM msdb.dbo.sysjobs AS j LEFT OUTER JOIN msdb.dbo.sysjobsteps AS s ON j.job_id = s.job_id ORDER BY j.name, s.step_id;

-- start a job
EXECUTE msdb.dbo.sp_start_job
	  @job_name = ''
	, @step_name = '';

-- enable a job
EXECUTE msdb.dbo.sp_update_job 
    @job_name='',
	@enabled = 1; -- 1 = enabled, 0 = disabled

-- enable a schedule
EXEC msdb.dbo.sp_update_schedule 
    @schedule_id = , 
	@enabled = 1; -- 1 = enabled, 0 = disabled

*/

