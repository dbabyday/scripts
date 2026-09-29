

--USE CentralAdmin;
--GO

--DECLARE @ServiceName SYSNAME;
--SELECT @ServiceName = CASE WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer' ELSE 'MSSQL$' + @@SERVICENAME END;

--DROP TABLE IF EXISTS dbo.PerfmonCounters;
--CREATE TABLE dbo.PerfmonCounters (
--	  ID INT IDENTITY(1, 1)
--	, object_name NVARCHAR(128) NOT NULL
--	, counter_name NVARCHAR(128) NOT NULL
--	, instance_name NVARCHAR(128) NULL

--	, CONSTRAINT PK_PerfmonCounters PRIMARY KEY CLUSTERED (ID)
--);

--/* Add our default Perfmon counters */
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Access Methods','Forwarded Records/sec', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Access Methods','Page compression attempts/sec', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Access Methods','Page Splits/sec', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Access Methods','Skipped Ghosted Records/sec', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Access Methods','Table Lock Escalations/sec', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Access Methods','Worktables Created/sec', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Availability Group','Active Hadr Threads','_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Availability Replica','Bytes Received from Replica/sec','_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Availability Replica','Bytes Sent to Replica/sec','_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Availability Replica','Bytes Sent to Transport/sec','_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Availability Replica','Flow Control Time (ms/sec)','_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Availability Replica','Flow Control/sec','_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Availability Replica','Resent Messages/sec','_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Availability Replica','Sends to Replica/sec','_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Buffer Manager','Page life expectancy', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Buffer Manager','Page reads/sec', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Buffer Manager','Page writes/sec', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Buffer Manager','Readahead pages/sec', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Buffer Manager','Target pages', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Buffer Manager','Total pages', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Databases','', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Buffer Manager','Active Transactions','_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Database Replica','Database Flow Control Delay', '_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Database Replica','Database Flow Controls/sec', '_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Database Replica','Group Commit Time', '_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Database Replica','Group Commits/Sec', '_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Database Replica','Log Apply Pending Queue', '_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Database Replica','Log Apply Ready Queue', '_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Database Replica','Log Compression Cache misses/sec', '_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Database Replica','Log remaining for undo', '_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Database Replica','Log Send Queue', '_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Database Replica','Recovery Queue', '_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Database Replica','Redo blocked/sec', '_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Database Replica','Redo Bytes Remaining', '_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Database Replica','Redone Bytes/sec', '_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Databases','Log Bytes Flushed/sec', '_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Databases','Log Growths', '_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Databases','Log Pool LogWriter Pushes/sec', '_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Databases','Log Shrinks', '_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Databases','Transactions/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Databases','Write Transactions/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Databases','XTP Memory Used (KB)',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Exec Statistics','Distributed Query', 'Execs in progress');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Exec Statistics','DTC calls', 'Execs in progress');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Exec Statistics','Extended Procedures', 'Execs in progress');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Exec Statistics','OLEDB calls', 'Execs in progress');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':General Statistics','Active Temp Tables', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':General Statistics','Logins/sec', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':General Statistics','Logouts/sec', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':General Statistics','Mars Deadlocks', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':General Statistics','Processes blocked', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Locks','Number of Deadlocks/sec', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Memory Manager','Memory Grants Pending', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':SQL Errors','Errors/sec', '_Total');
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':SQL Statistics','Batch Requests/sec', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':SQL Statistics','Forced Parameterizations/sec', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':SQL Statistics','Guided plan executions/sec', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':SQL Statistics','SQL Attention rate', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':SQL Statistics','SQL Compilations/sec', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':SQL Statistics','SQL Re-Compilations/sec', NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Workload Group Stats','Query optimizations/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Workload Group Stats','Suboptimal plans/sec',NULL);
--/* Below counters added by Jefferson Elias */
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Access Methods','Worktables From Cache Base',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Access Methods','Worktables From Cache Ratio',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Buffer Manager','Database pages',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Buffer Manager','Free pages',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Buffer Manager','Stolen pages',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Memory Manager','Granted Workspace Memory (KB)',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Memory Manager','Maximum Workspace Memory (KB)',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Memory Manager','Target Server Memory (KB)',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Memory Manager','Total Server Memory (KB)',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Buffer Manager','Buffer cache hit ratio',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Buffer Manager','Buffer cache hit ratio base',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Buffer Manager','Checkpoint pages/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Buffer Manager','Free list stalls/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Buffer Manager','Lazy writes/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':SQL Statistics','Auto-Param Attempts/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':SQL Statistics','Failed Auto-Params/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':SQL Statistics','Safe Auto-Params/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':SQL Statistics','Unsafe Auto-Params/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Access Methods','Workfiles Created/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':General Statistics','User Connections',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Latches','Average Latch Wait Time (ms)',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Latches','Average Latch Wait Time Base',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Latches','Latch Waits/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Latches','Total Latch Wait Time (ms)',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Locks','Average Wait Time (ms)',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Locks','Average Wait Time Base',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Locks','Lock Requests/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Locks','Lock Timeouts/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Locks','Lock Wait Time (ms)',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Locks','Lock Waits/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Transactions','Longest Transaction Running Time',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Access Methods','Full Scans/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Access Methods','Index Searches/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Buffer Manager','Page lookups/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES (@ServiceName + ':Cursor Manager by Type','Active cursors',NULL);
--/* Below counters are for In-Memory OLTP (Hekaton), which have a different naming convention.
--        And yes, they actually hard-coded the version numbers into the counters, and SQL 2019 still says 2017, oddly.
--        For why, see: https://connect.microsoft.com/SQLServer/feedback/details/817216/xtp-perfmon-counters-should-appear-under-sql-server-perfmon-counter-group
--*/
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2014 XTP Cursors','Expired rows removed/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2014 XTP Cursors','Expired rows touched/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2014 XTP Garbage Collection','Rows processed/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2014 XTP IO Governor','Io Issued/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2014 XTP Phantom Processor','Phantom expired rows touched/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2014 XTP Phantom Processor','Phantom rows touched/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2014 XTP Transaction Log','Log bytes written/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2014 XTP Transaction Log','Log records written/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2014 XTP Transactions','Transactions aborted by user/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2014 XTP Transactions','Transactions aborted/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2014 XTP Transactions','Transactions created/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2016 XTP Cursors','Expired rows removed/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2016 XTP Cursors','Expired rows touched/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2016 XTP Garbage Collection','Rows processed/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2016 XTP IO Governor','Io Issued/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2016 XTP Phantom Processor','Phantom expired rows touched/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2016 XTP Phantom Processor','Phantom rows touched/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2016 XTP Transaction Log','Log bytes written/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2016 XTP Transaction Log','Log records written/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2016 XTP Transactions','Transactions aborted by user/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2016 XTP Transactions','Transactions aborted/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2016 XTP Transactions','Transactions created/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2017 XTP Cursors','Expired rows removed/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2017 XTP Cursors','Expired rows touched/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2017 XTP Garbage Collection','Rows processed/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2017 XTP IO Governor','Io Issued/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2017 XTP Phantom Processor','Phantom expired rows touched/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2017 XTP Phantom Processor','Phantom rows touched/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2017 XTP Transaction Log','Log bytes written/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2017 XTP Transaction Log','Log records written/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2017 XTP Transactions','Transactions aborted by user/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2017 XTP Transactions','Transactions aborted/sec',NULL);
--INSERT INTO dbo.PerfmonCounters (object_name,counter_name,instance_name) VALUES ('SQL Server 2017 XTP Transactions','Transactions created/sec',NULL);









DECLARE @SampleSeconds INT = 10;


DROP TABLE IF EXISTS #PerfmonStats;
CREATE TABLE #PerfmonStats (
	  ID INT IDENTITY(1, 1) PRIMARY KEY CLUSTERED
	, Pass TINYINT NOT NULL
	, SampleTime DATETIMEOFFSET NOT NULL
	, object_name NVARCHAR(128) NOT NULL
	, counter_name NVARCHAR(128) NOT NULL
	, instance_name NVARCHAR(128) NULL
	, cntr_value BIGINT NULL
	, value_delta BIGINT NULL
	, value_per_second DECIMAL(18,2) NULL
);


/* get first set of data */
INSERT INTO
	#PerfmonStats (
		  Pass
		, SampleTime
		, object_name
		, counter_name
		, instance_name
		, cntr_value
	)
SELECT
	  1 AS Pass
	, SYSDATETIMEOFFSET() AS SampleTime
	, RTRIM(dmv.object_name)
	, RTRIM(dmv.counter_name)
	, RTRIM(dmv.instance_name)
	, dmv.cntr_value
FROM
	dbo.PerfmonCounters counters
INNER JOIN
	sys.dm_os_performance_counters dmv ON
		counters.counter_name COLLATE SQL_Latin1_General_CP1_CI_AS = RTRIM(dmv.counter_name) COLLATE SQL_Latin1_General_CP1_CI_AS
		AND counters.object_name COLLATE SQL_Latin1_General_CP1_CI_AS = RTRIM(dmv.object_name) COLLATE SQL_Latin1_General_CP1_CI_AS
		AND (
			counters.instance_name IS NULL
			OR counters.instance_name COLLATE SQL_Latin1_General_CP1_CI_AS = RTRIM(dmv.instance_name) COLLATE SQL_Latin1_General_CP1_CI_AS
		);






/* Wait for the indicated sample duration */
DECLARE @Delay DATETIME;
SELECT @Delay = DATEADD(SECOND, @SampleSeconds, CONVERT(DATETIME, 0));
WAITFOR DELAY @SampleSeconds;






/* get second set of data */
INSERT INTO
	#PerfmonStats (
		  Pass
		, SampleTime
		, object_name
		, counter_name
		, instance_name
		, cntr_value
	)
SELECT
	  2 AS Pass
	, SYSDATETIMEOFFSET() AS SampleTime
	, RTRIM(dmv.object_name)
	, RTRIM(dmv.counter_name)
	, RTRIM(dmv.instance_name)
	, dmv.cntr_value
FROM
	dbo.PerfmonCounters counters
INNER JOIN
	sys.dm_os_performance_counters dmv ON
		counters.counter_name COLLATE SQL_Latin1_General_CP1_CI_AS = RTRIM(dmv.counter_name) COLLATE SQL_Latin1_General_CP1_CI_AS
		AND counters.object_name COLLATE SQL_Latin1_General_CP1_CI_AS = RTRIM(dmv.object_name) COLLATE SQL_Latin1_General_CP1_CI_AS
		AND (
			counters.instance_name IS NULL
			OR counters.instance_name COLLATE SQL_Latin1_General_CP1_CI_AS = RTRIM(dmv.instance_name) COLLATE SQL_Latin1_General_CP1_CI_AS
		);




/* update the deltas */
UPDATE
	pNow
SET
	  value_delta = pNow.cntr_value - pFirst.cntr_value
	, value_per_second = ((1.0 * pNow.cntr_value - pFirst.cntr_value) / DATEDIFF(ss, pFirst.SampleTime, pNow.SampleTime))
FROM
	#PerfmonStats pNow
INNER JOIN
	#PerfmonStats pFirst ON
		pFirst.object_name = pNow.object_name
		AND pFirst.counter_name = pNow.counter_name
		AND (
			pFirst.instance_name = pNow.instance_name
			OR (
				pFirst.instance_name IS NULL
				AND pNow.instance_name IS NULL
			)
		)
		AND pNow.ID > pFirst.ID
WHERE
	DATEDIFF(ss, pFirst.SampleTime, pNow.SampleTime) > 0;



SELECT
	*
FROM
	#PerfmonStats
WHERE
	Pass=2
ORDER BY
	  object_name
	, counter_name
	, instance_name;





/* clean up */
DROP TABLE IF EXISTS #PerfmonStats;
