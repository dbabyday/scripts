/**********************************************************************************************************
* 
* MAINTENANCE_AutogrowEvents.sql
* 
* Author: James Lutsey
* Date: 03/30/2016
* 
* Purpose: Gets autogrow events that have happened in the given time range.
*          Also creates a query to get the specific events' info for the file.
* 
* Notes: 
* 
**********************************************************************************************************/

SET NOCOUNT ON;

DECLARE
	@path        NVARCHAR(260),
	@hours       INT,
	@start       DATETIME,
	@startUTC    DATETIME,
	@end         DATETIME,
	@endUTC      DATETIME,
	@Database    NVARCHAR(128);

SET @hours = 25; -- 25 = day, 73 = weekend, 169 = week

SET @start = DATEADD(HOUR,-1 * @hours,GETDATE());
SET @end   = GETDATE(); -- default end time is now


------------------------------------------------------------------------------------------
--// OPTIONAL: SET SPECIFIC START AND END TIMES                                       //--
------------------------------------------------------------------------------------------

--/* 

-- run on local-time server to get utc date/time
-- paste result into @startUTC and/or @endUTC
-- SELECT DATEADD(MINUTE,DATEDIFF(MINUTE,GETDATE(),GETUTCDATE()),'');

SET @startUTC = '2017-10-05 13:00:00.000'; --<----<---- PASTE THE RESULTS HERE <----<----
SET @start = DATEADD(MINUTE,DATEDIFF(MINUTE,GETUTCDATE(),GETDATE()),@startUTC);

--SET @endUTC = ''; 
--SET @end   = DATEADD(MINUTE,DATEDIFF(MINUTE,GETUTCDATE(),GETDATE()),@endUTC);

--*/


------------------------------------------------------------------------------------------
--// GET THE VALUES                                                                   //--
------------------------------------------------------------------------------------------

-- get the path to the trace files
SELECT @path = REVERSE(SUBSTRING(REVERSE([path]),CHARINDEX('\', REVERSE([path])), 260)) + N'log.trc'
FROM   sys.traces
WHERE  is_default = 1;


------------------------------------------------------------------------------------------
--// GET THE FILE INFO                                                                //--
------------------------------------------------------------------------------------------

IF (OBJECT_ID('tempdb..#FileInfo') IS NOT NULL)
	DROP TABLE #FileInfo;

CREATE TABLE #FileInfo
(
	[DatabaseID]		INT,
	[name]				SYSNAME,
	[size]				BIGINT,
	[growth]			BIGINT,
	[max_size]			BIGINT
);

DECLARE curDatabases CURSOR FAST_FORWARD FOR
	SELECT name 
	FROM master.sys.databases
	WHERE state = 0; -- online

OPEN curDatabases;
	FETCH NEXT FROM curDatabases INTO @Database;

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		EXECUTE
		(N'
			INSERT INTO #FileInfo
			(
				[DatabaseID],
				[name],
				[size],
				[growth],
				[max_size]
			)
			SELECT
				DB_ID(''' + @Database + '''),
				[name],
				CAST(ROUND([size],0) AS INT),
				CAST(ROUND([growth],0) AS INT),
				CAST(ROUND([max_size],0) AS INT)
			FROM
				[' + @Database + N'].sys.database_files'
		);
    
		FETCH NEXT FROM curDatabases INTO @Database;
	END
CLOSE curDatabases;
DEALLOCATE curDatabases;


------------------------------------------------------------------------------------------
--// GET AND DISPLAY THE INFO GROUPED BY FILE                                         //--
------------------------------------------------------------------------------------------

-- get the autogrow events and their related info
SELECT 
	[TimeRange_Start] = @start,
	[TimeRange_End] = @end,
    [ServerName] = @@SERVERNAME,
    t.[DatabaseName],
    t.[FileName],
    [EventName] = 
		CASE t.EventClass 
			WHEN 92 THEN 'Data File Auto Grow'
			WHEN 93 THEN 'Log File Auto Grow'
	    END,
	[Count] = COUNT(*),
	[GrowthSetting(MB)] = CAST(ROUND(f.growth / 128.0,0) AS INT),
	[TotalGrowthAmt(MB)] = CAST(ROUND(COUNT(*) * f.growth / 128.0,0) AS INT),
	[SizeBefore(MB)] = CAST(ROUND((f.size - (COUNT(*) * f.growth)) / 128.0,0) AS INT),
	[SizeNow(MB)] = CAST(ROUND(f.size / 128.0,0) AS INT),
	[MaxSize(MB)] = CAST(ROUND(f.max_size / 128.0,0) AS INT),
	[FirstAutogrow] = MIN(t.StartTime),
	[LastAutogrow] = MAX(t.StartTime),
	[GetSpecificEvents] = 
'SELECT ' + 
    '[DatabaseName], ' + 
    '[FileName], ' + 
    '[EventName] = ' + 
		'CASE [EventClass] ' + 
			'WHEN 92 THEN ''Data File Auto Grow'' ' + 
			'WHEN 93 THEN ''Log File Auto Grow'' ' + 
			'WHEN 94 THEN ''Data File Auto Shrink'' ' + 
			'WHEN 95 THEN ''Log File Auto Shrink'' ' + 
	    'END, ' + 
	'[StartTime], ' + 
	'[EndTime], ' + 
	'[ApplicationName], ' + 
	'[LoginName] ' + 
'FROM ' + 
	'sys.fn_trace_gettable(''' + @path + ''', DEFAULT) ' + 
'WHERE ' + 
	'[FileName] = ''' + [FileName] + ''' ' + 
'ORDER BY ' + 
	'[StartTime]'
FROM 
	sys.fn_trace_gettable(@path, DEFAULT) AS t
JOIN
	#FileInfo AS f
	ON t.DatabaseID = f.DatabaseID AND t.FileName = f.name
WHERE
    t.EventClass IN (92,93)
	AND t.StartTime >= @start
	AND t.StartTime <= @end
GROUP BY
	t.DatabaseName,
	t.[FileName],
	t.EventClass,
	f.size,
	f.growth,
	f.max_size
ORDER BY
	t.DatabaseName,
	t.[FileName];
	

------------------------------------------------------------------------------------------
--// CLEAN UP                                                                         //--
------------------------------------------------------------------------------------------

IF (OBJECT_ID('tempdb..#FileInfo') IS NOT NULL)
	DROP TABLE #FileInfo;