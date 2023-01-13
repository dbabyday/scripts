-- find all tables on the instance without a primary key

DECLARE @db  NVARCHAR(128),
        @sql NVARCHAR(MAX);

DECLARE curDBs CURSOR LOCAL FAST_FORWARD FOR
    SELECT [name] 
    FROM   [sys].[databases] 
    WHERE  [state] = 0 
           AND [is_read_only] = 0
           AND [name] NOT IN ('master','model','msdb','tempdb','distribution','CentralAdmin','PDU');

IF OBJECT_ID('tempdb.dbo.#NoPK','U') IS NOT NULL DROP TABLE #NoPK;
CREATE TABLE #NoPK 
(
    [ServerName]   NVARCHAR(128),
    [DatabaseName] NVARCHAR(128),
    [TableName]    NVARCHAR(257)
);

OPEN curDBs;
    FETCH NEXT FROM curDBs INTO @db;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = N'
USE [' + @db + N'];
INSERT INTO #NoPK ([ServerName],[DatabaseName],[TableName])
SELECT          @@SERVERNAME,
                ''' + @db + N''', 
                SCHEMA_NAME([t].[schema_id]) + N''.'' + [t].[name]
FROM            [sys].[tables] AS [t]
LEFT OUTER JOIN ( SELECT [object_id] 
                  FROM [sys].[indexes] 
                  WHERE [is_primary_key] = 1 ) AS [pk] 
                ON [t].[object_id] = [pk].[object_id]
WHERE           [pk].[object_id] IS NULL
                --AND [t].[name] = '''';
';

            EXECUTE(@sql);
        FETCH NEXT FROM curDBs INTO @db;
    END
CLOSE curDBs;
DEALLOCATE curDBs;

SELECT   * 
FROM     #NoPK
ORDER BY [DatabaseName],
         [TableName];



IF OBJECT_ID('tempdb.dbo.#NoPK','U') IS NOT NULL DROP TABLE #NoPK;