/*
    https://blogs.msdn.microsoft.com/craigfr/2008/10/30/what-is-the-difference-between-sys-dm_db_index_usage_stats-and-sys-dm_db_index_operational_stats/
        sys.dm_db_index_operational_stats 
            - tells us how often the indexes are actually used during the execution of plans (contributing to server performance)
        sys.dm_db_index_usage_stats 
            - tells us the proportion of query plans that were executed that use various indexes
            - concluding how many of the executed query plans might be affected if we drop an index
        Note: the presence of an index could change a query plan for the better (sys.dm_db_index_usage_stats) even though the index itself is not used (sys.dm_db_index_operational_stats) when the plan is executed
            

*/

-- select 'USE [' + name + '];' from sys.databases order by name;



DECLARE @dbid INT;
SET @dbid = DB_ID();

--select object_name(object_id),* from sys.indexes order by name;
--select * from sys.dm_db_index_usage_stats;


SELECT DB_NAME([u].[database_id])   AS [DbName],
       OBJECT_NAME([u].[object_id]) AS [TableName],
       [i].[name]                   AS [IndexName],
       CASE
           WHEN [u].[user_seeks] + [u].[user_scans] + [u].[user_lookups] = 0 
           THEN 'Indexes not being used at all'
           
           WHEN [u].[user_scans] > [u].[user_seeks]
           THEN 'Inefficient (scan>seeks)'

           ELSE ''
       END AS [UseType],
       --[u].[user_seeks] + [u].[user_scans] + [u].[user_lookups] AS [total_uses],
       [u].[user_seeks],u.system_seeks,
       [u].[user_scans],u.system_scans,
       [u].[user_lookups],u.system_lookups,
       u.user_updates,u.system_updates
FROM   sys.dm_db_index_usage_stats [u]
JOIN   sys.indexes [i] 
       ON [i].[object_id] = [u].[object_id]
       AND [i].[index_id] = [u].[index_id]
WHERE  [u].[database_id] = @dbid
--       AND [u].[object_id] = OBJECT_ID('tbl_AMLType');
order by 2,3

SELECT o.name AS [Table_Name], x.name AS [Index_Name],
       i.partition_number AS [Partition],
       i.index_id AS [Index_ID], x.type_desc AS [Index_Type],

       --i.range_scan_count,
       --i.singleton_lookup_count

       i.leaf_insert_count,
       i.leaf_delete_count,
       i.leaf_update_count,
       i.leaf_ghost_count,
       i.range_scan_count,
       i.singleton_lookup_count

       --i.range_scan_count * 100.0 /
       --    (i.range_scan_count + i.leaf_insert_count
       --     + i.leaf_delete_count + i.leaf_update_count
       --     + i.leaf_page_merge_count + i.singleton_lookup_count
       --    ) AS [Percent_Scan]
FROM sys.dm_db_index_operational_stats (db_id(), NULL, NULL, NULL) i
JOIN sys.objects o ON o.object_id = i.object_id
JOIN sys.indexes x ON x.object_id = i.object_id AND x.index_id = i.index_id
WHERE (i.range_scan_count + i.leaf_insert_count
       + i.leaf_delete_count + leaf_update_count
       + i.leaf_page_merge_count + i.singleton_lookup_count) != 0
AND objectproperty(i.object_id,'IsUserTable') = 1

order by 1,2

--ORDER BY [Percent_Scan] DESC

--select * from sys.dm_db_index_usage_stats;
--select * from sys.dm_db_index_operational_stats(db_id(),null,null,null);

