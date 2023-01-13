-- drop all tables in a database

USE [];  -- select name from sys.databases order by name;
GO

DECLARE @sql NVARCHAR(MAX) = '';

-- commands to drop all foreign keys in the database
SELECT @sql += 'ALTER TABLE [' + DB_NAME() + N'].[' + [s].[name] + N'].[' + OBJECT_NAME([f].[parent_object_id]) + N'] DROP CONSTRAINT [' + [f].[name] + N'];' + CHAR(13) + CHAR(10)
FROM [sys].[foreign_keys] AS [f]
INNER JOIN [sys].[schemas] AS [s] ON [f].[schema_id] = [s].[schema_id];

SET @sql += CHAR(13) + CHAR(10);

-- commands to drop all tables in the database
SELECT @sql += N'DROP TABLE [' + DB_NAME() + N'].[' + [s].[name] + N'].[' + [t].[name] + N'];' + CHAR(13) + CHAR(10)
FROM [sys].[tables] AS [t]
INNER JOIN [sys].[schemas] AS [s] ON [t].[schema_id] = [s].[schema_id];

SELECT @sql;
--BEGIN TRANSACTION;
--EXECUTE(@sql);

-- ROLLBACK TRANSACTION;
-- COMMIT TRANSACTION;