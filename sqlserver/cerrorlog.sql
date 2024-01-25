/**********************************************************************************************************
* 
* TROUBLESHOOT_ReadErrorLog.sql
* 
* Author: James Lutsey
* Date: 05/31/2016
* Update: 11/02/2016 - find specific errorlog files incase a number is skipped
* 
* Purpose: Get the messages from the ERRORLOGs. This script will store the messages from all the ERRORLOGs
*          on file in a temp table, #Errors. You can adjust the filtering criteria in the query at the 
*          end of the script.
* 
**********************************************************************************************************/
--/*
SET NOCOUNT ON;

DECLARE 
	-- USER INPUT
	@startTime    DATETIME2(3) = dateadd(minute,-60,getdate()), -- '2023-06-30 14:29:19',  -- SELECT CONVERT(NCHAR(19),DATEADD(HOUR,-1,GETDATE()),120);

	-- other variables
	@directory       NVARCHAR(4000),
	@earliestLogDate DATETIME2(3),
	@i               INT             = 0,
	@sql             NVARCHAR(100),
	@subdirectory    NVARCHAR(128);

-- used to get the ERRORLOG location
DECLARE @tblLocation TABLE
(
    [ID]          INT IDENTITY(1,1) PRIMARY KEY,
    [LogDate]     DATETIME2(3),
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
    [LogDate]     DATETIME2(3),
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

SELECT 
	[LogDate],
	[ProcessInfo],
    [Message]
FROM
   #Errors
WHERE 1=1
     AND [LogDate] > dateadd(minute,-60,getdate()) -- '2023-06-30 14:29:19'
	-- AND [LogDate] < '2016-05-28 00:10:00.000'
	 AND [ProcessInfo] NOT IN ('Backup') --,'Logon')
	 --AND [Message] NOT LIKE 'Configuration option%'
	 --AND [Message] NOT LIKE 'FILESTREAM: effective%'
	 --AND [Message] NOT LIKE 'This instance of SQL Server has been%'
	 --AND [Message] NOT LIKE 'DBCC TRACE%'
	 --AND [Message] NOT LIKE 'CHECK DB for database%'
	 --AND [Message] NOT LIKE 'Starting up database%'
	 --AND [Message] NOT LIKE 'The database%is marked RESTORING%'
	 --AND [Message] NOT LIKE '%This is an informational message only%'
	 --AND [Message] NOT LIKE 'DBCC CHECKDB%'
	-- AND [Message] NOT LIKE 'Configuration option ''show advanced options'' changed%'
	 --AND [Message] LIKE '%starting up%master%' 
ORDER BY 
	[LogDate] DESC;
	--[LogDate] ASC;
	--[ProcessInfo], [LogDate];

-- DROP TABLE #Errors;
