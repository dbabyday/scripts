-- remove max file limits on user databases


DECLARE @x NVARCHAR(MAX) = N'';

SELECT @x += 'ALTER DATABASE ' + QUOTENAME(DB_NAME([f].[database_id])) + ' MODIFY FILE ( NAME = N''' + [f].[name] + ''', MAXSIZE = UNLIMITED );' + CHAR(10)
FROM   [sys].[master_files] AS [f]
JOIN   [sys].[databases] AS [d] ON [f].[database_id] = [d].[database_id]
WHERE  [f].[max_size] NOT IN (-1,268435456)
       AND LEFT([f].[physical_name],1) != 'C'
	   AND DB_NAME([f].[database_id]) NOT IN ('master','model','msdb','tempdb')
       AND [f].[type] IN (0,1)
       AND [d].[is_read_only] = 0
       AND [d].[state] = 0
       AND [d].[user_access] = 0;

PRINT @x;
--EXECUTE(@x);

