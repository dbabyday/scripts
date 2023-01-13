/**********************************************************************************************************
* 
* I/O Errors
* 
**********************************************************************************************************/
--/*
SET NOCOUNT ON;

DECLARE 
	@earliestLogDate DATETIME,
	@subdirectory    NVARCHAR(128),
	@directory NVARCHAR(4000),
	@i         INT,
	@qty       INT,
	@hours     INT,
	@sql       NVARCHAR(100),
	@start     DATETIME,
	@startUTC  DATETIME;

SET @hours = 25; -- 25 = day, 73 = weekend, 169 = week

SET @start = DATEADD(HOUR,-1 * @hours,GETDATE());


------------------------------------------------------------------------------------------
--// OPTIONAL: SET SPECIFIC START TIME                                                //--
------------------------------------------------------------------------------------------

--/* 

-- run on local-time server to get utc date/time
-- paste result into @startUTC and/or @endUTC
-- SELECT DATEADD(MINUTE,DATEDIFF(MINUTE,GETDATE(),GETUTCDATE()),'');

SET @startUTC = '2018-01-09 13:00:00.000'; --<----<---- PASTE THE RESULTS HERE <----<----
SET @start = DATEADD(MINUTE,DATEDIFF(MINUTE,GETUTCDATE(),GETDATE()),@startUTC);

--*/


SET @i = 0;

-- used to get the ERRORLOG location
DECLARE @tblLocation TABLE
(
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
IF OBJECT_ID('tempdb..#Errors','U') IS NOT NULL
	DROP TABLE	#Errors;

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
		IF @earliestLogDate < @start
			BREAK;

		SET @sql = 'INSERT #Errors ([LogDate], [ProcessInfo], [Message]) EXEC master.dbo.xp_readerrorlog ' + RIGHT(@subdirectory,LEN(@subdirectory)-CHARINDEX('.',@subdirectory)) + ', 1;';
		EXECUTE(@sql);
		
		FETCH NEXT FROM curLogs INTO @subdirectory;
	END
CLOSE curLogs;
DEALLOCATE curLogs;
 
SET NOCOUNT OFF;
--*/



SELECT 
	[LogDate],
	@@SERVERNAME AS [Server],
	CASE
		WHEN @@SERVERNAME = 'co-db-010' THEN
			CASE
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,33) = 'E:\Backups\co_db_010_sqlbackup01\' THEN 'E:\Backups\co_db_010_sqlbackup01\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,21) = 'E:\databases\plxprtl\' THEN 'E:\databases\plxprtl\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,19) = 'E:\databases\plaid\' THEN 'E:\databases\plaid\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,19) = 'E:\databases\maxdb\' THEN 'E:\databases\maxdb\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,18) = 'E:\databases\misc\' THEN 'E:\databases\misc\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,16) = 'E:\logs\plxprtl\' THEN 'E:\logs\plxprtl\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,14) = 'E:\logs\plaid\' THEN 'E:\logs\plaid\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,14) = 'E:\logs\maxdb\' THEN 'E:\logs\maxdb\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,13) = 'E:\logs\misc\' THEN 'E:\logs\misc\'
				ELSE SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,3)
			END
		WHEN @@SERVERNAME = 'co-db-017' THEN
			CASE
				WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,24) = 'E:\Databases\Sharepoint\' THEN 'E:\Databases\Sharepoint\'
				WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,21) = 'E:\Databases\archmgr\' THEN 'E:\Databases\archmgr\'
				WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,19) = 'E:\Logs\Sharepoint\' THEN 'E:\Logs\Sharepoint\'
				WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,19) = 'E:\Databases\misc2\' THEN 'E:\Databases\misc2\'
				WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,16) = 'E:\Logs\archmgr\' THEN 'E:\Logs\archmgr\'
				WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,14) = 'E:\Logs\misc2\' THEN 'E:\Logs\misc2\'
				ELSE SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,3)
			END
		WHEN @@SERVERNAME = 'co-db-020' THEN
			CASE
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,22) = 'E:\databases\gsf2repl\' THEN 'E:\databases\gsf2repl\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,20) = 'E:\logs\gsf2repllog\' THEN 'E:\logs\gsf2repllog\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,18) = 'E:\databases\repl\' THEN 'E:\databases\repl\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,13) = 'E:\logs\repl\' THEN 'E:\logs\repl\'
				ELSE SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,3)
			END
		WHEN @@SERVERNAME = 'co-db-032' THEN
			CASE
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,20) = 'F:\databases\tempdb\' THEN 'F:\databases\tempdb\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,18) = 'F:\logs\TempDBLog\' THEN 'F:\logs\TempDBLog\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,18) = 'F:\databases\ssis\' THEN 'F:\databases\ssis\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,13) = 'F:\logs\ssis\' THEN 'F:\logs\ssis\'
				ELSE SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,3)
			END
		WHEN @@SERVERNAME = 'co-db-034' THEN
			CASE
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,24) = 'E:\SQLbackup\sqlbackups\' THEN 'E:\SQLbackup\sqlbackups\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,21) = 'E:\databases\archive\' THEN 'E:\databases\archive\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,20) = 'E:\databases\tempdb\' THEN 'E:\databases\tempdb\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,19) = 'E:\databases\maxdb\' THEN 'E:\databases\maxdb\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,19) = 'E:\databases\plaid\' THEN 'E:\databases\plaid\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,16) = 'E:\logs\archive\' THEN 'E:\logs\archive\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,15) = 'E:\logs\tempdb\' THEN 'E:\logs\tempdb\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,14) = 'E:\logs\plaid\' THEN 'E:\logs\plaid\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,14) = 'E:\logs\maxdb\' THEN 'E:\logs\maxdb\'
				ELSE SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,3)
			END
		WHEN @@SERVERNAME = 'co-db-038' THEN
			CASE
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,24) = 'E:\Databases\slqrptdata\' THEN 'E:\Databases\slqrptdata\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,23) = 'E:\Databases\as400data\' THEN 'E:\Databases\as400data\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,21) = 'E:\TEMPDB\sqlrpttemp\' THEN 'E:\TEMPDB\sqlrpttemp\'
	            WHEN SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,18) = 'E:\Logs\sqlrptlog\' THEN 'E:\Logs\sqlrptlog\'
				ELSE SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,3)
			END
		ELSE SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,3)
	END AS [drive],
	'' AS [Datastore],
	'' AS [VM_Format],
	SUBSTRING([Message],28,CHARINDEX(' ',[Message],28)-28) AS [Occurrences],
	SUBSTRING([Message],CHARINDEX('on file [',[Message])+9,CHARINDEX('] in database',[Message],CHARINDEX('on file [',[Message])+9)-CHARINDEX('on file [',[Message])-9) AS [file],
	SUBSTRING([Message],CHARINDEX('in database [',[Message])+13,CHARINDEX('] ',[Message],CHARINDEX('in database [',[Message])+13)-CHARINDEX('in database [',[Message])-13) AS [database],
	SUBSTRING([Message],CHARINDEX('The OS file handle is ',[Message])+21,CHARINDEX('.',[Message],CHARINDEX('The OS file handle is ',[Message])+21)-CHARINDEX('The OS file handle is ',[Message])-21) AS [OS_file_handle],
	SUBSTRING([Message],CHARINDEX('The offset of the latest long I/O is: ',[Message])+37,LEN([Message])-CHARINDEX('The offset of the latest long I/O is: ',[Message])-36) AS [offset_of_the_latest_long_I/O],
	[ProcessInfo],
    [Message]
FROM
   #Errors
WHERE 
	[Message] LIKE 'SQL Server has enc%requests taking longer than%'
	AND [LogDate] > @start
ORDER BY 
	[LogDate] ASC;

IF OBJECT_ID('tempdb..#Errors','U') IS NOT NULL
	DROP TABLE #Errors;