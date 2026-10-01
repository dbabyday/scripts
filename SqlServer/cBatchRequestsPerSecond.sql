/*

https://github.com/dbabyday
Warranty: The software is provided "AS IS", without warranty of any kind

Name: cBatchRequestsPerSecond.sql
Description: See Batch Requests/sec

*/


USE master;


DECLARE @v1 BIGINT, @delay SMALLINT = 2, @time DATETIME;
SELECT @time = DATEADD(SECOND, @delay, '00:00:00');


SELECT @v1 = cntr_value 
FROM   sys.dm_os_performance_counters
WHERE  counter_name = 'Batch Requests/sec';


WAITFOR DELAY @time;


SELECT
	  @@SERVERNAME AS ServerName
	, SYSDATETIMEOFFSET() AS EntryTime
	, cntr_value
	, (cntr_value - @v1)/@delay AS BatchRequestsPerSec_Now
FROM
	sys.dm_os_performance_counters
WHERE
	counter_name='Batch Requests/sec';



/* Reference */
SELECT '0 - 1,000' as BatchRequestsPerSec, 'easy to handle with commodity hardware' AS Difficulty
UNION ALL
SELECT '1,000 - 5,000' as BatchRequestsPerSec, 'one bad change to a query can knock over a commodity server' AS Difficulty
UNION ALL
SELECT '5,000 - 25,000' as BatchRequestsPerSec, 'if you are growing, you should be making a scale-out or caching plan' AS Difficulty
UNION ALL
SELECT 'Over 25,000' as BatchRequestsPerSec, 'doable, but needs attention' AS Difficulty;


