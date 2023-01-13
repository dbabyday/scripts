-- SEARCH ALL DATABASES FOR TABLES WITH A SPECIFIED COLUMN NAME


-- user input
DECLARE @colName NVARCHAR(128) = N'';

-- other variables
DECLARE @db  NVARCHAR(128) = N'',
        @sql NVARCHAR(MAX) = N'';

-- cursor to loop through all online databases
DECLARE curDBs CURSOR LOCAL FAST_FORWARD FOR
    SELECT [name] FROM [sys].[databases] WHERE [state] = 0;

-- temp table to store results from each database
IF OBJECT_ID(N'tempdb..#MyTables',N'U') IS NOT NULL DROP TABLE #MyTables;
CREATE TABLE #MyTables
(
    [server_name]   NVARCHAR(128) NOT NULL,
    [database_name] NVARCHAR(128) NOT NULL,
    [table_name]    NVARCHAR(128) NOT NULL
);

-- check each database for tables with the column name
OPEN curDBs;
    FETCH NEXT FROM curDBs INTO @db;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = N'USE [' + @db + N'];
INSERT INTO #MyTables([server_name],[database_name],[table_name])
SELECT      @@SERVERNAME, 
            DB_NAME(),
            OBJECT_NAME([object_id])
FROM        sys.columns
WHERE       LOWER([name]) = LOWER(''' + @colName + ''');'

        EXECUTE(@sql);

        FETCH NEXT FROM curDBs INTO @db;
    END
CLOSE curDBs;
DEALLOCATE curDBs;

-- display results
SELECT * FROM #MyTables;

-- clean up
IF OBJECT_ID(N'tempdb..#MyTables',N'U') IS NOT NULL DROP TABLE #MyTables;

