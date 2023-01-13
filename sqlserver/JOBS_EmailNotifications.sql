USE [msdb];
GO

DECLARE @operatorName NVARCHAR(128);
SET @operatorName = ''; -- SELECT id, name, enabled, email_address FROM msdb..sysoperators
 
SET NOCOUNT ON;
 
IF (@operatorName = '')
BEGIN

    SELECT 
        j.name, 
        CASE j.notify_level_email
            WHEN 0 THEN 'Never'
            WHEN 1 THEN 'When the job succeeds'
            WHEN 2 THEN 'When the job fails'
            WHEN 3 THEN 'Whenever the job completes (regardless of job outcome)'
        END AS notify_level_email,
        o.name,
        o.email_address,
        [Set email notification when job fails] = N'-- find the operator name you want and enter it in line 6
SELECT id, name, enabled, email_address FROM msdb..sysoperators' + CHAR(13)+CHAR(10)
    FROM 
        msdb..sysjobs AS j
    LEFT OUTER JOIN 
        msdb..sysoperators AS o 
        ON o.id = j.notify_email_operator_id
    WHERE 
        j.enabled = 1
        --AND j.notify_level_email = 0
    ORDER BY 
        j.name;

END
ELSE
BEGIN

    SELECT 
        j.name, 
        CASE j.notify_level_email
            WHEN 0 THEN 'Never'
            WHEN 1 THEN 'When the job succeeds'
            WHEN 2 THEN 'When the job fails'
            WHEN 3 THEN 'Whenever the job completes (regardless of job outcome)'
        END AS notify_level_email,
        o.name,
        o.email_address,
        [Set email notification when job fails] = N'-- ' + j.name + '
EXEC msdb.dbo.sp_update_job 
         @job_id=N''' + CONVERT(nvarchar(50), j.job_id) + N''', 
         @notify_level_email=2, 
         @notify_level_netsend=2,
         @notify_level_page=2, 
         @notify_email_operator_name=N''' + @operatorName + N'''
GO' + CHAR(13)+CHAR(10)
    FROM 
        msdb..sysjobs AS j
    LEFT OUTER JOIN 
        msdb..sysoperators AS o 
        ON o.id = j.notify_email_operator_id
    WHERE 
        j.enabled = 1
        --AND j.notify_level_email = 0
    ORDER BY 
        j.name;

END;


