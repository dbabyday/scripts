DECLARE @message NVARCHAR(MAX),
        @myJob   NVARCHAR(128),
        @myStep  INT;

SET @myJob  = N'DBA - Weekly Maintenance';
SET @myStep = 4;

IF NOT EXISTS(SELECT 1 FROM [msdb].[dbo].[sysjobs] WHERE [name] = @myJob)
BEGIN
    SET @message = N'Job [' + @myJob + '] does not exist - setting NOEXEC ON;';
    RAISERROR(@message,16,1);
    SET NOEXEC ON;
END

EXEC [msdb].[dbo].[sp_update_jobstep] @job_name = @myJob, 
                                      @step_id  = 4,
                                      @command  = N'sqlcmd -E -S $(ESCAPE_SQUOTE(SRVR)) -d CentralAdmin -Q "EXECUTE dbo.DatabaseIntegrityCheck @Databases = ''ALL_DATABASES'', @CheckCommands = ''CHECKDB'', @PhysicalOnly = ''Y'', @NoIndex = ''Y'', @LogToTable = ''Y''" -b ';
GO
