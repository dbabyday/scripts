EXECUTE [msdb].[dbo].[sp_update_jobstep] @job_name = N'DBA - Purge PDU', 
                                         @step_id=1, 
                                         @command=N'DECLARE @sql NVARCHAR(MAX) = N''USE [PDU];'' + CHAR(10);
                                         
SELECT @sql += N''DROP TABLE [PDU].['' + SCHEMA_NAME([schema_id]) + ''].['' + [name] + N''];'' + CHAR(10)
FROM   [PDU].[sys].[tables]
WHERE  [modify_date] < DATEADD(DAY,-30,GETDATE());

EXECUTE(@sql);';
