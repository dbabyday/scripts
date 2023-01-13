-- find stored procedures

DECLARE 
	@obj NVARCHAR(128),
	@db  NVARCHAR(261),
	@sql NVARCHAR(MAX);

DECLARE @tblObjects TABLE
(
	[name] nvarchar(261)
);

DECLARE curDB CURSOR LOCAL FAST_FORWARD FOR
	SELECT [name] FROM [sys].[databases] WHERE [name] LIKE '%PROD%' AND [is_read_only] = 0 ORDER BY [name];
	--SELECT [name] FROM [sys].[databases] WHERE [name] NOT IN ('master','model','msdb','tempdb','CentralAmdin','PDU') AND [is_read_only] = 0 ORDER BY [name];

DECLARE curObjects CURSOR LOCAL FAST_FORWARD FAST_FORWARD FOR
	SELECT [name] FROM @tblObjects;

IF OBJECT_ID('tempdb..#WhereIsIt','U') IS NOT NULL DROP TABLE #WhereIsIt;
CREATE TABLE #WhereIsIt
(
	[object] NVARCHAR(261),
	[db]     NVARCHAR(128),
	[exists] VARCHAR(3)
);

INSERT INTO @tblObjects ([name])
VALUES  ('udv_MDMS_CapacityLoading_V2'),
        ('udv_MDMS_DownTimeRecords'),
        ('udv_MDMS_FPY'),
        ('udv_MDMS_LineEff'),
        ('udv_MDMS_RunningSchedule'),
        ('V_TransactionLog');

OPEN curDB;
	FETCH NEXT FROM curDB INTO @db;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		OPEN curObjects;
			FETCH NEXT FROM curObjects INTO @obj;

			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @sql =  N'USE [' + @db + N'];' + CHAR(13) + CHAR(10) +
							N'IF EXISTS(SELECT 1 FROM sys.views WHERE name = ''' + @obj + ''')' + CHAR(13) + CHAR(10) +
							N'    INSERT INTO #WhereIsIt ([object],[db],[exists]) VALUES (''' + @obj + N''',''' + @db + N''',''yes'');' + CHAR(13) + CHAR(10) +
							N'ELSE' + CHAR(13) + CHAR(10) +
							N'    INSERT INTO #WhereIsIt ([object],[db],[exists]) VALUES (''' + @obj + N''',''' + @db + N''',''no'');';

				--PRINT @sql
				EXECUTE(@sql);

				FETCH NEXT FROM curObjects INTO @obj;
			END
		CLOSE curObjects;

		FETCH NEXT FROM curDB INTO @db;
	END
CLOSE curDB;
DEALLOCATE curDB;
DEALLOCATE curObjects;

SELECT * 
FROM #WhereIsIt
WHERE [exists] = 'yes'
ORDER BY [object],[db];

SELECT [object],[exists],COUNT(*)
FROM #WhereIsIt
GROUP BY [object],[exists]
ORDER BY [object],[exists];

SELECT * 
FROM #WhereIsIt
ORDER BY [object],[db];


-- IF OBJECT_ID('tempdb..#WhereIsIt','U') IS NOT NULL DROP TABLE #WhereIsIt;
