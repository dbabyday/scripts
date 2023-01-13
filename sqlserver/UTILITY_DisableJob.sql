SELECT 
    j.name,
	CASE j.enabled
		WHEN 0 THEN 'no'
		WHEN 1 THEN 'yes'
	END AS [enabled],
	j.description,
	s.step_name,
	s.command
FROM msdb..sysjobs j
JOIN msdb..sysjobsteps s ON j.job_id = s.job_id


--USE [msdb];
--GO
--EXEC dbo.sp_update_job
--	@job_name = N'DBA - Cleanup DB Backup Files.Subplan_1',
--	@description = N'disabled: new backup jobs now include file cleanup',
--	@enabled = 0;  -- 0 = disabled; 1 = enabled
--GO



