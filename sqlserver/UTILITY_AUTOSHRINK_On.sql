/**********************************************************************************************************
* 
* MAINTENANCE_AutoshrinkOn.sql
* 
* Author: James Lutsey
* Date: 03/30/2016
* 
* Purpose: Gets autogrow and autoshrink events that have happened in the given time range for all databaes
*          that have is_auto_shrink_on = 1.
* 
* Notes: 
*     1. Time range is calculated based on seconds before now. This to accomodate for different computer
*        times in different regions when running this script on multiple servers. 
*     2. Default time range is the past 1 year (31536000 seconds)
*     3. Run the commented script on a local server, and paste the results after that section
* 
**********************************************************************************************************/

SET NOCOUNT ON;

-- run this commented out query to find all databases that have auto shrink on
/*

SELECT @@SERVERNAME, name
FROM sys.databases
WHERE is_auto_shrink_on = 1;

*/

SET NOCOUNT ON;

DECLARE 
	@path      NVARCHAR(260),
	@secondsBeforeNowStart INT,
	@startTime DATETIME;
	
SET @secondsBeforeNowStart = 86400; -- default: one day = 86400

-- run this commented out script on a local-time server and paste the results below
/* 

DECLARE @dt1 DATETIME;
SET @dt1 = '2015-01-01T00:00:00';
SELECT '
SET @secondsBeforeNowStart = ' + CAST(DATEDIFF(SECOND,@dt1,GETDATE()) AS VARCHAR(35)) + ';';

*/
-- paste result here:



-- calculate start time
SET @startTime = DATEADD(SECOND,-1 * @secondsBeforeNowStart,GETDATE());

-- get the path to the trace files
SELECT @path = REVERSE(SUBSTRING(REVERSE([path]),CHARINDEX('\', REVERSE([path])), 260)) + N'log.trc'
FROM   sys.traces
WHERE  is_default = 1;


SELECT 
    [ServerName] = @@SERVERNAME,
    t.[DatabaseName],
    t.[FileName],
    [EventName] = 
		CASE t.EventClass 
			WHEN 92 THEN 'Data File Auto Grow'
			WHEN 93 THEN 'Log File Auto Grow'
			WHEN 94 THEN 'Data File Auto Shrink'
			WHEN 95 THEN 'Log File Auto Shrink'
	    END,
	[GrowthSetting(MB)] = f.growth / 128,
	[SizeNow(MB)] = f.size / 128,
	[MaxSize(MB)] = f.max_size / 128,
	t.[StartTime],
	t.[EndTime],
	t.[ApplicationName],
	t.[LoginName]
FROM 
	sys.fn_trace_gettable(@path, DEFAULT) AS t
JOIN
	sys.master_files AS f
	ON t.DatabaseID = f.database_id AND t.FileName = f.name
JOIN
	sys.databases AS d
	ON f.database_id = d.database_id
WHERE
    t.EventClass IN (92,93,94,95)
	AND d.is_auto_shrink_on = 1
	AND t.StartTime > @startTime
ORDER BY 
	t.StartTime;

