SET NOCOUNT ON;

/*

SELECT
	s.command as [-- before]
FROM
	msdb.dbo.sysjobs AS j
INNER JOIN
	msdb.dbo.sysjobsteps AS s
	ON j.job_id = s.job_id
WHERE
    j.name IN ('DBA - Backup USER_DATABASES - Log')
    --AND s.step_name IN ('Backup USER_DATABASES - DIFF');

--*/

DECLARE 
	@action VARCHAR(10),
	@add    NVARCHAR(50),
	@cmd    NVARCHAR(MAX),
	@jobId  NVARCHAR(36),
	@sql    NVARCHAR(MAX),
	@stepId NVARCHAR(5);

SET @action = 'EXECUTE' -- EXECUTE PRINT
SET @add = N'[CentralAdmin].'

SELECT
	@cmd    = s.command,
	@jobId  = j.job_id,
	@stepId = CAST(s.step_id AS NVARCHAR(5))
FROM
	msdb.dbo.sysjobs AS j
INNER JOIN
	msdb.dbo.sysjobsteps AS s
	ON j.job_id = s.job_id
WHERE
    j.name IN ('DBA - Backup USER_DATABASES - LOG');
--    AND s.step_name IN ('Backup USER_DATABASES - DIFF');

IF CHARINDEX(UPPER(@add),UPPER(@cmd)) = 0
BEGIN
	IF CHARINDEX(N'[dbo].',@cmd) > 0
	BEGIN
		SET @cmd = STUFF(@cmd,CHARINDEX(N'[dbo].',@cmd),0,@add);
		SET @cmd = REPLACE(@cmd,'''','''''');
		
		SET @sql =  N'EXEC msdb.dbo.sp_update_jobstep '           + CHAR(13)+CHAR(10) +
					N'        @job_id = N'''  + @jobId  + N''', ' + CHAR(13)+CHAR(10) +
					N'        @step_id = '    + @stepId + N', '   + CHAR(13)+CHAR(10) +
					N'        @command = N''' + @cmd    + N''';'  + CHAR(13)+CHAR(10) +  + CHAR(13)+CHAR(10)
		
		IF @action = 'PRINT'
			SELECT @sql, @@SERVERNAME;
		ELSE IF @action = 'EXECUTE'
		BEGIN
			EXECUTE(@sql);
			SELECT 'EXECUTED', @@SERVERNAME;
		END
		ELSE
			SELECT 'Wrong @action value', @@SERVERNAME;
	END
	ELSE
	BEGIN
		SELECT 'non standard step command', @@SERVERNAME, @cmd;
	END
END
ELSE
BEGIN
	SELECT '[CentralAdmin]. already exists', @@SERVERNAME, @cmd;
END


/*

SELECT
	s.command as [-- after]
FROM
	msdb.dbo.sysjobs AS j
INNER JOIN
	msdb.dbo.sysjobsteps AS s
	ON j.job_id = s.job_id
WHERE
    j.name IN ('DBA - Backup USER_DATABASES - Log')
    --AND s.step_name IN ('Backup USER_DATABASES - DIFF');

--*/
