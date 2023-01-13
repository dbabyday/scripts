-- get rowcounts

--  SELECT 'USE ' + QUOTENAME([name]) + ';' FROM [sys].[databases] ORDER BY [name];



SELECT     [s].[name]      AS [SchemaName],
           [t].[name]      AS [TableName],
           SUM([p].[rows]) AS [rows]
FROM       [sys].[tables]     AS [t]
INNER JOIN [sys].[schemas]    AS [s] ON [s].[schema_id] = [t].[schema_id]
INNER JOIN [sys].[partitions] AS [p] ON [p].[object_id] = [t].[object_id]
INNER JOIN [sys].[indexes]    AS [i] ON [i].[object_id] = [t].[object_id] AND [i].[index_id] = [p].[index_id]
WHERE      [i].[index_id] < 2
           --AND [s].[name] = N''
           --AND [t].[name] = N''
GROUP BY   [s].[name],
           [t].[name]
ORDER BY   [s].[name],
           [t].[name];