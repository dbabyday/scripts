/**********************************************************************************************************
* 
* TROUBLESHOOT_ReadAgentLog.sql
* 
* Author: James Lutsey
* Date: 05/31/2016
* 
* Purpose: Get the messages from the SQLAGENT logs. This script will store the messages from all the SQLAGENT
*          logs on file in a temp table, #AgentErrors. You can adjust the filtering criteria in the query 
*          at the end of the script.
* 
**********************************************************************************************************/
--/*
SET NOCOUNT ON;

DECLARE 
	@directory NVARCHAR(4000),
	@i         INT            = 0,
	@qty       INT,
	@sql       NVARCHAR(100);

-- used to get the ERRORLOG location
DECLARE @tblLocation TABLE
(
    [LogDate]     DATETIME,
    [ProcessInfo] VARCHAR(32), 
    [Message]     NVARCHAR(4000)
);

-- used to get the files in the SQLAGENT log directory
DECLARE @tblDirectoryTree TABLE
(
	[ID]           INT IDENTITY(1,1),
	[Subdirectory] NVARCHAR(512),
	[Depth]        INT,
	[IsFile]       BIT
);


-- used to get the messages from the SQLAGENT logs
IF OBJECT_ID('tempdb..#AgentErrors','U') IS NOT NULL
	DROP TABLE	#AgentErrors;

CREATE TABLE #AgentErrors 
(
	[ID]         INT IDENTITY(1,1),
    [LogDate]    DATETIME,
    [ErrorLevel] INT, 
    [Message]    NVARCHAR(4000)
);

-- get the message containing the SQLAGENT log file location from the error log
INSERT INTO @tblLocation
EXECUTE master.dbo.xp_readerrorlog 0, 1, N'Logging SQL Server messages in file';

-- get the SQLAGENT logs directory from the message
SELECT TOP 1 @directory = SUBSTRING([Message],CHARINDEX('''',[Message])+1,LEN([Message]) - CHARINDEX('\',REVERSE([Message])) - CHARINDEX('''',[Message]))
FROM @tblLocation;

-- get the files in the directory that contains the SQLAGENT logs
INSERT INTO @tblDirectoryTree
EXEC master.sys.xp_dirtree @directory, 1, 1;

-- get the quantity of SQLAGENT logs
SELECT @qty = COUNT(*) 
FROM @tblDirectoryTree
WHERE Subdirectory LIKE 'SQLAGENT%';

-- loop through each SQLAGENT log, adding the messages to the temp table
WHILE @i < @qty
BEGIN
	SET @sql = N'INSERT #AgentErrors ([LogDate], [ErrorLevel], [Message]) EXEC master.dbo.xp_readerrorlog ' + CAST(@i AS NVARCHAR(10)) + ', 2';
	EXECUTE (@sql);
	SET @i += 1;
END 
 
SET NOCOUNT OFF;
--*/



SELECT 
	[LogDate],
	[ErrorLevel],
    [Message]
FROM
   #AgentErrors
WHERE 1=1
	--AND LogDate > '2016-05-28 00:00:00.000'
	--AND LogDate < '2016-05-28 00:10:00.000'
	--AND [ErrorLevel] = 1   -- 1 = critical, 2 = warning, 3 = informational
	--AND [Message] NOT LIKE '%DBCC CHECKDB%'
ORDER BY 
	[LogDate] DESC;
	--[LogDate] ASC;
	--[ErrorLevel], [LogDate];

-- DROP TABLE #AgentErrors;





