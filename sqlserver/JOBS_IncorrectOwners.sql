SELECT 
	'EXEC msdb..sp_update_job
			@job_name = ''' + name + ''',
			@owner_login_name = ''sa''' AS [Command To Execute],
	name AS [Job Name], 
	SUSER_SNAME(owner_sid) AS [Job Owner] 
FROM 
	msdb.dbo.sysjobs 
WHERE 
	SUSER_SNAME(owner_sid) IN ('NA\lee.hart.admin', 'NA\lee.hart')
