USE [msdb];

DECLARE @isDisabled INT;

SELECT @isDisabled = CAST([is_disabled] AS INT)
FROM   [msdb].[sys].[triggers]
WHERE  [name] = 'trg_SysJobs_enabled';

IF ( @isDisabled = 0 ) DISABLE TRIGGER [dbo].[trg_SysJobs_enabled] ON [dbo].[sysjobs];


EXECUTE msdb.dbo.sp_update_job @job_name = 'DBA - Volume Space Monitoring',
	                           @enabled  = 1;


IF ( @isDisabled = 0 ) ENABLE TRIGGER [dbo].[trg_SysJobs_enabled] ON [dbo].[sysjobs];

