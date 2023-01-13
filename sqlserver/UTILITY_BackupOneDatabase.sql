-- execute backup stored procedure for one database

DECLARE 
	-- USER INPUT
	@db      NVARCHAR(128) = N'',
	@jobName NVARCHAR(128) = N'DBA - Backup USER_DATABASES - FULL', -- select name from msdb.dbo.sysjobs order by name
	@execute VARCHAR(10)   = 'NO', -- YES NO

	-- other variables
	@cmd NVARCHAR(MAX);

-- verify user input
IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE name = @db)
BEGIN
	RAISERROR('Database does not exist',16,1);
	RETURN;
END

IF NOT EXISTS(SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @jobName)
BEGIN
	RAISERROR('Job does not exist',16,1);
	RETURN;
END

SELECT
	@cmd    = s.command
FROM
	msdb.dbo.sysjobs AS j
INNER JOIN
	msdb.dbo.sysjobsteps AS s
	ON j.job_id = s.job_id
WHERE
    j.name = @jobName;
	
SELECT @cmd = SUBSTRING(@cmd,CHARINDEX('EXEC',@cmd),CHARINDEX('" -b',@cmd)-CHARINDEX('EXEC',@cmd)) + ';' + CHAR(13)+CHAR(10) + CHAR(13)+CHAR(10);
SELECT @cmd = REPLACE(@cmd,N'@',CHAR(13)+CHAR(10)+N'            @');
IF (CHARINDEX('[CentralAdmin].[dbo]',@cmd) = 0) SELECT @cmd = STUFF(@cmd,CHARINDEX('[dbo].',@cmd),0,'[CentralAdmin].');
SELECT @cmd = REPLACE(@cmd,N'USER_DATABASES',@db);

PRINT @cmd;

IF UPPER(@execute) = 'YES'
    EXECUTE(@cmd);