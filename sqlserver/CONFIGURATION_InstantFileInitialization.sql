

SET NOCOUNT ON;

IF CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)),4) AS NUMERIC(4,2)) < 13.0
BEGIN
    DBCC TRACEON(3004,3605);
    CREATE DATABASE [TestInstantFileInitializationEnabled];
    DBCC TRACEOFF(3004,3605)
    DROP DATABASE [TestInstantFileInitializationEnabled];
    --DBCC TRACESTATUS(3004,3605);
END;

DECLARE 
	-- USER INPUT
	@startTime    DATETIME,

	-- other variables
	@directory       NVARCHAR(4000),
	@earliestLogDate DATETIME,
	@i               INT,
	@sql             NVARCHAR(100),
	@subdirectory    NVARCHAR(128);

--SET @startTime = DATEADD(MINUTE,-10,GETDATE());
SELECT @startTime = '2017-01-01 00:00:00.000',
       @i         = 0;

-- used to get the ERRORLOG location
DECLARE @tblLocation TABLE
(
    [ID]          INT IDENTITY(1,1) PRIMARY KEY,
    [LogDate]     DATETIME,
    [ProcessInfo] VARCHAR(32), 
    [Message]     NVARCHAR(4000)
);

-- used to get the files in the ERRORLOG directory
DECLARE @tblDirectoryTree TABLE
(
	[ID]           INT IDENTITY(1,1),
	[Subdirectory] NVARCHAR(512),
	[Depth]        INT,
	[IsFile]       BIT
);

DECLARE curLogs CURSOR LOCAL FAST_FORWARD FOR
	SELECT [Subdirectory]
	FROM @tblDirectoryTree
	WHERE [Subdirectory] LIKE 'ERRORLOG%' 
		AND ISNUMERIC(RIGHT([Subdirectory],1)) = 1
	ORDER BY CAST(SUBSTRING([Subdirectory],CHARINDEX('.',[Subdirectory])+1,LEN([Subdirectory])-CHARINDEX('.',[Subdirectory])) AS INT);

-- used to get the messages from the ERRORLOG's
IF OBJECT_ID('tempdb..#Errors','U') IS NOT NULL	DROP TABLE	#Errors;
CREATE TABLE #Errors 
(
	[ID]          INT IDENTITY(1,1),
    [LogDate]     DATETIME,
    [ProcessInfo] VARCHAR(32), 
    [Message]     VARCHAR(8000)
);

-- get the message containing the errorlog file location from the error log
INSERT INTO @tblLocation
EXECUTE master.dbo.xp_readerrorlog 0, 1, N'Logging SQL Server messages in file', NULL, NULL, NULL, N'asc';

-- get the errorlog directory from the message
SELECT TOP 1 @directory = SUBSTRING([Message],CHARINDEX('''',[Message])+1,LEN([Message]) - CHARINDEX('\',REVERSE([Message])) - CHARINDEX('''',[Message]))
FROM @tblLocation;

-- get the files in the directory that contains the errorlogs
INSERT INTO @tblDirectoryTree
EXEC master.sys.xp_dirtree @directory, 1, 1;

IF EXISTS(SELECT 1 FROM @tblDirectoryTree WHERE [Subdirectory] = 'ERRORLOG')
	INSERT #Errors ([LogDate], [ProcessInfo], [Message]) EXEC master.dbo.xp_readerrorlog 0, 1;

OPEN curLogs;
	FETCH NEXT FROM curLogs INTO @subdirectory;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @earliestLogDate = MIN([LogDate]) FROM #Errors;
		IF @earliestLogDate < @startTime
			BREAK;

		SET @sql = 'INSERT #Errors ([LogDate], [ProcessInfo], [Message]) EXEC master.dbo.xp_readerrorlog ' + RIGHT(@subdirectory,LEN(@subdirectory)-CHARINDEX('.',@subdirectory)) + ', 1;';
		EXECUTE(@sql);
		
		FETCH NEXT FROM curLogs INTO @subdirectory;
	END
CLOSE curLogs;
DEALLOCATE curLogs;
 
SET NOCOUNT OFF;
--*/

SELECT @@SERVERNAME AS [server_name],[LogDate],[Message] FROM #Errors WHERE [Message] LIKE 'Zeroing%' OR [Message] LIKE '%Database Instant File Initialization%';

IF ( EXISTS(SELECT 1 FROM #Errors WHERE [Message] LIKE 'Zeroing%.mdf%') )
   OR ( EXISTS(SELECT 1 FROM #Errors WHERE [Message] LIKE 'Database Instant File Initialization: disabled.%') )
BEGIN
    SELECT @@SERVERNAME                     AS [server_name], 
           'no'                             AS [ifi_enabled], 
           SERVERPROPERTY('ProductVersion') AS [version];
END;
ELSE IF ( EXISTS(SELECT 1 FROM #Errors WHERE [Message] LIKE 'Database Instant File Initialization: enabled.%') )
        OR ( EXISTS(SELECT 1 FROM #Errors WHERE [Message] LIKE 'Zeroing%.ldf%') AND NOT EXISTS(SELECT 1 FROM #Errors WHERE [Message] LIKE 'Zeroing%.mdf%') )
BEGIN
    SELECT @@SERVERNAME                     AS [server_name], 
           'yes'                            AS [ifi_enabled], 
           SERVERPROPERTY('ProductVersion') AS [version];
END;
ELSE
BEGIN
    SELECT @@SERVERNAME                            AS [server_name], 
           'No messages in the log'                AS [ifi_enabled], 
           SERVERPROPERTY('ProductVersion')        AS  [version];
END;

 DROP TABLE #Errors;
