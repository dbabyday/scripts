/**********************************************************************************
* 
* Author:  James Lutsey
* Date:    08/11/2015
* Purpose: Scrpits out statements to change job owner to srvc account for all
*          for all jobs that have user logins as owner
* 
**********************************************************************************/

SELECT 
	'EXEC msdb.dbo.sp_update_job
			@job_id = N''' + CONVERT(nvarchar(50), job_id) + ''',
			@owner_login_name = N''NA\srvcmsqlprod.neen''' AS [Command To Execute],
	name AS [Job Name], 
	SUSER_SNAME(owner_sid) AS [Job Owner] 
FROM 
	msdb.dbo.sysjobs 
WHERE 
	    SUSER_SNAME(owner_sid) NOT LIKE 'NA\srvc%'
	AND SUSER_SNAME(owner_sid) NOT LIKE '##MS%'
	AND SUSER_SNAME(owner_sid) NOT IN ('sa', 'distributor_admin')

