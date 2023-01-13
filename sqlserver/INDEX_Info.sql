
--  SELECT 'USE ' + QUOTENAME([name]) + ';' FROM [sys].[databases] ORDER BY [name];



WITH index_pages ([used_pages], [pages], [object_id], [index_id], [index_type], [index_name])
AS
(
    SELECT     [s].[used_page_count],
               CASE
                   WHEN ([s].[index_id] < 2) THEN ([s].[in_row_data_page_count] + [s].[lob_used_page_count] + [s].[row_overflow_used_page_count])
                   ELSE [s].[lob_used_page_count] + [s].[row_overflow_used_page_count]
               END,
               [s].[object_id],
               [i].[index_id],
               [i].[type_desc],
               [i].[name]
    FROM       [sys].[dm_db_partition_stats] AS [s]
    INNER JOIN [sys].[indexes]               AS [i] ON [s].[object_id] = [i].[object_id]
                                                       AND [s].[index_id] = [i].[index_id]
)
SELECT DISTINCT DB_NAME()                                        AS [database_name],
                SCHEMA_NAME([o].[schema_id])                     AS [table_schema],
                [o].[name]                                       AS [table_name],
                [ip].[object_id],
                [ip].[index_name],
                [ip].[index_type],
                [ip].[index_id],
                (   CASE 
                        WHEN [ip].[used_pages] > [ip].[pages] THEN CASE 
                                                                       WHEN [ip].[index_id] < 2 THEN [ip].[pages]
                                                                       ELSE ([ip].[used_pages] - [ip].[pages]) 
                                                                   END 
                        ELSE 0 
                    END
                ) / 128                                          AS [index_size_mb],
                CAST([ps].[avg_fragmentation_in_percent] AS INT) AS [avg_fragmentation_in_percent]
FROM            index_pages     AS [ip]
INNER JOIN      [sys].[objects] AS [o]  ON [o].[object_id] = [ip].[object_id]
INNER JOIN      [sys].[dm_db_index_physical_stats] (DB_ID(), NULL, NULL, NULL, NULL) AS [ps] ON [ps].[object_id] = [o].[object_id]
                                                                                                AND [ps].[index_id] = [ip].[index_id]
--WHERE           [o].[name] = '' -- table
--WHERE           [ip].[index_name] = ''
ORDER BY        SCHEMA_NAME([o].[schema_id]),[o].[name],[ip].[index_name]; -- schema, table, index
                --8 DESC; -- ave frag in percent


