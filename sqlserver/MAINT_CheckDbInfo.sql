/**********************************************************************************************************
* 
* MAINTENANCE_CheckDbInfo.sql
* 
* Author: James Lutsey
* Date: 12/18/2016
* 
* Purpose: Get CHECKDB info from the ERRORLOGs.
* 
* Displays:
*     1. CHECKDB's with errors in the timeframe
*     2. Databases without a CHECKDB in the timeframe
*     3. All CHECKDB's in the timeframe
* 
**********************************************************************************************************/
--/*
SET NOCOUNT ON;

DECLARE 
	-- USER INPUT
	@hours  INT           = 170, -- 26 = day, 170 = week (plus a couple of hours), 0 = all history in the logs
	@db     NVARCHAR(128) = N'', -- enter the database name you want to check; leave blank to check all

	-- other variables
	@startTime       DATETIME2(3),
	@directory       NVARCHAR(4000),
	@earliestLogDate DATETIME2(3),
	@i               INT             = 0,
	@sql             NVARCHAR(100),
	@subdirectory    NVARCHAR(128);

-- used to get the ERRORLOG location
DECLARE @tblLocation TABLE
(
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

IF @hours = 0
	SET @startTime = N'0001-01-01T00:00:00.000';
ELSE
	SET @startTime = DATEADD(HOUR,-1 * @hours,GETDATE());

-- used to get the messages from the ERRORLOG's
IF OBJECT_ID('tempdb..#Errors','U') IS NOT NULL	DROP TABLE #Errors;
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

----------------------------------------------------------------------
--// CHECKDB's with errors in the timeframe                       //--
----------------------------------------------------------------------

SELECT 
	[Server] =          @@SERVERNAME,

	[Database] =        CASE
							WHEN CHARINDEX(N', ',LEFT([Message],CHARINDEX(N') ',[Message]))) = 0 
							THEN    SUBSTRING
									(
										[Message],
										CHARINDEX(N'DBCC CHECKDB (',[Message]) + 14,
										CHARINDEX(N') ',[Message]) - CHARINDEX(N'DBCC CHECKDB (',[Message]) - 14
									)
							ELSE    SUBSTRING
									(
										[Message],
										CHARINDEX(N'DBCC CHECKDB (',[Message]) + 14,
										CHARINDEX(N', ',[Message]) - CHARINDEX(N'DBCC CHECKDB (',[Message]) - 14
									)
						END,

	[ErrorsFound] =     CAST
						(    
							SUBSTRING
							(
								[Message],
								CHARINDEX(N' found ',[Message]) + 7,
								CHARINDEX(N' errors and repaired ',[Message]) - CHARINDEX(N' found ',[Message]) - 7
							) 
						AS INT),

	[ErrorRepaired] =   CAST
						(    
							SUBSTRING
							(
								[Message],
								CHARINDEX(N' errors and repaired ',[Message]) + 21,
								CHARINDEX(N' errors. Elapsed time: ',[Message]) - CHARINDEX(N' errors and repaired ',[Message]) - 21
							) 
						AS INT),

	[LogDate]

	--,[Message]
FROM
	#Errors
WHERE 
	[Message] LIKE '%DBCC CHECKDB%'
	AND [LogDate] > @startTime
	AND	CASE
			WHEN CHARINDEX(N', ',LEFT([Message],CHARINDEX(N') ',[Message]))) = 0 
			THEN    UPPER
					(
						SUBSTRING
						(
							[Message],
							CHARINDEX(N'DBCC CHECKDB (',[Message]) + 14,
							CHARINDEX(N') ',[Message]) - CHARINDEX(N'DBCC CHECKDB (',[Message]) - 14
						)
					)
			ELSE    UPPER
					(
						SUBSTRING
						(
							[Message],
							CHARINDEX(N'DBCC CHECKDB (',[Message]) + 14,
							CHARINDEX(N', ',[Message]) - CHARINDEX(N'DBCC CHECKDB (',[Message]) - 14
						)
					)
		END LIKE N'%' + UPPER(@db) + N'%'
	AND 
	(
		CAST
		(    
			SUBSTRING
			(
				[Message],
				CHARINDEX(N' found ',[Message]) + 7,
				CHARINDEX(N' errors and repaired ',[Message]) - CHARINDEX(N' found ',[Message]) - 7
			) 
		AS INT) > 0 
		OR
		CAST
		(    
			SUBSTRING
			(
				[Message],
				CHARINDEX(N' errors and repaired ',[Message]) + 21,
				CHARINDEX(N' errors. Elapsed time: ',[Message]) - CHARINDEX(N' errors and repaired ',[Message]) - 21
			) 
		AS INT) > 0
	)
ORDER BY 
	/*[Database]*/ 2,
	[LogDate] DESC;


----------------------------------------------------------------------
--// Databases without a CHECKDB in the timeframe                 //--
----------------------------------------------------------------------

SELECT 
	[Server] =      @@SERVERNAME,
	[Database] =    name,
	[Description] =	CASE @hours
						WHEN 0 THEN 'No CHECKDB in the log history.'
						ELSE 'No CHECKDB in the past ' + CAST(@hours AS VARCHAR(10)) + ' hours.'
					END
FROM
	sys.databases
WHERE
	name LIKE N'%' + UPPER(@db) + N'%'
	AND name NOT IN (	SELECT DISTINCT
						    CASE
							    WHEN CHARINDEX(N', ',LEFT([Message],CHARINDEX(N') ',[Message]))) = 0 
							    THEN    SUBSTRING
									    (
										    [Message],
										    CHARINDEX(N'DBCC CHECKDB (',[Message]) + 14,
										    CHARINDEX(N') ',[Message]) - CHARINDEX(N'DBCC CHECKDB (',[Message]) - 14
									    )
							    ELSE    SUBSTRING
									    (
										    [Message],
										    CHARINDEX(N'DBCC CHECKDB (',[Message]) + 14,
										    CHARINDEX(N', ',[Message]) - CHARINDEX(N'DBCC CHECKDB (',[Message]) - 14
									    )
						    END AS [Database]
					    FROM 
						    #Errors
					    WHERE
					    	[Message] LIKE '%DBCC CHECKDB%'
				    		AND [LogDate] > @startTime
				    )
ORDER BY 
	name;


----------------------------------------------------------------------
--// All CHECKDB's in the timeframe                               //--
----------------------------------------------------------------------

SELECT 
	[Server] =          @@SERVERNAME,

	[Database] =        CASE
							WHEN CHARINDEX(N', ',LEFT([Message],CHARINDEX(N') ',[Message]))) = 0 
							THEN    SUBSTRING
									(
										[Message],
										CHARINDEX(N'DBCC CHECKDB (',[Message]) + 14,
										CHARINDEX(N') ',[Message]) - CHARINDEX(N'DBCC CHECKDB (',[Message]) - 14
									)
							ELSE    SUBSTRING
									(
										[Message],
										CHARINDEX(N'DBCC CHECKDB (',[Message]) + 14,
										CHARINDEX(N', ',[Message]) - CHARINDEX(N'DBCC CHECKDB (',[Message]) - 14
									)
						END,

	[ErrorsFound] =     CAST
						(    
							SUBSTRING
							(
								[Message],
								CHARINDEX(N' found ',[Message]) + 7,
								CHARINDEX(N' errors and repaired ',[Message]) - CHARINDEX(N' found ',[Message]) - 7
							) 
						AS INT),

	[ErrorRepaired] =   CAST
						(    
							SUBSTRING
							(
								[Message],
								CHARINDEX(N' errors and repaired ',[Message]) + 21,
								CHARINDEX(N' errors. Elapsed time: ',[Message]) - CHARINDEX(N' errors and repaired ',[Message]) - 21
							) 
						AS INT),

	[LogDate]

	--,[Message]
FROM
	#Errors
WHERE 
	[Message] LIKE '%DBCC CHECKDB%'
	AND [LogDate] > @startTime
	AND	CASE
			WHEN CHARINDEX(N', ',LEFT([Message],CHARINDEX(N') ',[Message]))) = 0 
			THEN    UPPER
					(
						SUBSTRING
						(
							[Message],
							CHARINDEX(N'DBCC CHECKDB (',[Message]) + 14,
							CHARINDEX(N') ',[Message]) - CHARINDEX(N'DBCC CHECKDB (',[Message]) - 14
						)
					)
			ELSE    UPPER
					(
						SUBSTRING
						(
							[Message],
							CHARINDEX(N'DBCC CHECKDB (',[Message]) + 14,
							CHARINDEX(N', ',[Message]) - CHARINDEX(N'DBCC CHECKDB (',[Message]) - 14
						)
					)
		END LIKE N'%' + UPPER(@db) + N'%'
ORDER BY 
	/*[Database]*/ 2,
	[LogDate] DESC;


IF OBJECT_ID('tempdb..#Errors','U') IS NOT NULL
	DROP TABLE #Errors;



