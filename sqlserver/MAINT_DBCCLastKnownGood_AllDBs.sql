DECLARE 
	@dbname VARCHAR(256);

-- table to store the DBCC DBINFO results for each database
CREATE TABLE #dbinfo
(
	[Server]       VARCHAR(256),
	[Database]     VARCHAR(256),
	[ParentObject] VARCHAR(255),
	[Object]       VARCHAR(255),
	[Field]        VARCHAR(255),
	[Value]        VARCHAR(255)
);

-- loop through each database
DECLARE curDatabases CURSOR FAST_FORWARD FOR
	SELECT name 
	FROM sys.databases
	WHERE state = 0-- AND is_read_only = 0;--name NOT IN ('master', 'model', 'msdb', 'tempdb');
OPEN curDatabases;
	FETCH NEXT FROM curDatabases INTO @dbname;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF 
		(
			    @@SERVERNAME != 'CO-DB-017'
			AND @@SERVERNAME != 'CO-DB-038'
			AND @@SERVERNAME != 'CO-DB-048'
			AND @@SERVERNAME != 'CO-DB-062'
			AND @@SERVERNAME != 'CO-DB-948'
			AND @@SERVERNAME != 'CO-DB-949'
			AND @@SERVERNAME != 'CO-DB-981'
			AND @@SERVERNAME != 'CO-DB-993'
			AND @@SERVERNAME != 'DR1-DB-001'
			AND @@SERVERNAME != 'KELS-DB-003'
		)
		BEGIN
			-- get the DBCC DBINFO for the database...put results in temp table
			INSERT INTO #dbinfo ([ParentObject], [Object], [Field], [Value])
			EXECUTE ('DBCC DBINFO (' + @dbname + ') WITH TABLERESULTS, NO_INFOMSGS');

			-- add the servername and database name to the record
			UPDATE #dbinfo
			SET [Server] = @@SERVERNAME,
				[Database] = @dbname
			WHERE [Server] IS NULL;
		END
		
		FETCH NEXT FROM curDatabases INTO @dbname;
	END
CLOSE curDatabases;
DEALLOCATE curDatabases;

-- display the results
SELECT 
	[Server],
	[Database],
	CASE [Value] 
		WHEN '1900-01-01 00:00:00.000' THEN 'never'
		ELSE SUBSTRING([Value],6,2) + '/' + SUBSTRING([Value],9,2) + '/' + LEFT([Value],4) 
	END AS 'LastKnownGood'
FROM
	#dbinfo
WHERE
    Field = 'dbi_dbccLastKnownGood'
	AND CAST(REPLACE([Value],' ','T')AS datetime) < DATEADD(DAY,-7,GETDATE())
ORDER BY 
	[Server], 
	[Database];

-- clean up
DROP TABLE #dbinfo;