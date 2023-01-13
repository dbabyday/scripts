/*********************************************************************************************************************
* 
* TROUBLESHOOT_FindSlowProcs.sql
* 
* Author: James Lutsey
* Date:   2018-11-01
* 
* Purpose: Gets procedure execution stats sorted according high ratio of last value to average value in each category
* 
* Date        Name                  Description of change
* ----------  --------------------  ---------------------------------------------------------------------------------
* 
* 
*********************************************************************************************************************/



---------------------------------------
--// USER INPUT                    //--
---------------------------------------

DECLARE @includeReplicationProcs AS BIT           = 0    -- 0 = no (default), 1 = yes
      , @dbName                  AS NVARCHAR(128) = N''  -- leave blank to select all
      , @schemaName              AS NVARCHAR(128) = N''  -- leave blank to select all
      , @procName                AS NVARCHAR(128) = N''; -- leave blank to select all




---------------------------------------
--// DECLARATIONS                  //--
---------------------------------------

-- other variables
DECLARE @databaseId   AS INT
      , @databaseName AS NVARCHAR(128)
      , @sql          AS NVARCHAR(MAX) = N'';

-- temp table to hold stats from all databases
IF OBJECT_ID(N'tempdb..#AllProcedures',N'U') IS NOT NULL DROP TABLE #AllProcedures;
CREATE TABLE #AllProcedures
(
      id            INT NOT NULL IDENTITY(1,1)
    , database_id   INT NOT NULL
    , object_id     INT NOT NULL
    , database_name NVARCHAR(128) NOT NULL
    , schema_name   NVARCHAR(128) NOT NULL
    , object_name   NVARCHAR(128) NOT NULL

    , CONSTRAINT PK_AllProcedures PRIMARY KEY (id)
);

-- cursor to gather stats from all databases
IF @dbName = N''
    DECLARE Databases CURSOR LOCAL FAST_FORWARD FOR 
        SELECT database_id
             , name
        FROM   sys.databases
        WHERE  state = 0;
ELSE
    DECLARE Databases CURSOR LOCAL FAST_FORWARD FOR 
        SELECT database_id
             , name
        FROM   sys.databases
        WHERE  state = 0
               AND name = @dbName;
    




---------------------------------------
--// GATHER INFO                   //--
---------------------------------------

-- get all the procedure names from all databases...we'll use this to join on the sys.dm_exec_procedure_stats so we can record the names with the stats
OPEN Databases;
    FETCH NEXT FROM Databases INTO @databaseId, @databaseName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = N'INSERT INTO #AllProcedures (database_id, object_id, database_name, schema_name, object_name)' + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'SELECT DISTINCT e.database_id'                                                                + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'              , p.object_id'                                                                  + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'              , N''' + @databaseName + N''''                                                  + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'              , s.name'                                                                       + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'              , p.name'                                                                       + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'FROM            sys.dm_exec_procedure_stats AS e'                                             + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'INNER JOIN      [' + @databaseName + N'].sys.procedures AS p ON p.object_id = e.object_id'    + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'INNER JOIN      [' + @databaseName + N'].sys.schemas AS s ON s.schema_id = p.schema_id'       + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'WHERE           e.database_id = ' + CAST(@databaseId AS NVARCHAR(10));
        IF @includeReplicationProcs = 0
            SET @sql += NCHAR(0x000D) + NCHAR(0x000A) +
                        N'                AND p.name NOT LIKE N''sp\_MSins\_%'' ESCAPE ''\''' + NCHAR(0x000D) + NCHAR(0x000A) +
                        N'                AND p.name NOT LIKE N''sp\_MSdel\_%'' ESCAPE ''\''' + NCHAR(0x000D) + NCHAR(0x000A) +
                        N'                AND p.name NOT LIKE N''sp\_MSupd\_%'' ESCAPE ''\''';
        IF @schemaName <> N''
            SET @sql += NCHAR(0x000D) + NCHAR(0x000A) +
                        N'                AND s.name = N''' + @schemaName + N''''
        IF @procName <> N''
            SET @sql += NCHAR(0x000D) + NCHAR(0x000A) +
                        N'                AND p.name = N''' + @procName + N''''
        SET @sql += N';';
        
        EXECUTE sys.sp_executesql @stmt = @sql;

        FETCH NEXT FROM Databases INTO @databaseId, @databaseName;
    END;
CLOSE Databases;
DEALLOCATE Databases;




---------------------------------------
--// DISPLAY INFO                  //--
---------------------------------------

-- elapsed_time
SELECT     a.database_name
         , a.schema_name
         , a.object_name
         , e.last_execution_time
         , e.execution_count
         , e.last_elapsed_time
         , CAST(e.total_elapsed_time AS DECIMAL(22,1)) / e.execution_count                         AS ave_elapsed_time
         , e.last_elapsed_time / (CAST(e.total_elapsed_time AS DECIMAL(22,1)) / e.execution_count) AS ratio_elapsed_time
FROM       sys.dm_exec_procedure_stats AS e
INNER JOIN #AllProcedures              AS a ON a.database_id = e.database_id AND a.object_id = e.object_id
WHERE      e.total_elapsed_time <> 0
ORDER BY   e.last_elapsed_time / (CAST(e.total_elapsed_time AS DECIMAL(22,1)) / e.execution_count) DESC;

-- worker_time
SELECT     a.database_name
         , a.schema_name
         , a.object_name
         , e.last_execution_time
         , e.execution_count
         , e.last_worker_time
         , CAST(e.total_worker_time AS DECIMAL(22,1)) / e.execution_count                         AS ave_worker_time
         , e.last_worker_time / (CAST(e.total_worker_time AS DECIMAL(22,1)) / e.execution_count) AS ratio_worker_time
FROM       sys.dm_exec_procedure_stats AS e
INNER JOIN #AllProcedures              AS a ON a.database_id = e.database_id AND a.object_id = e.object_id
WHERE      e.total_worker_time <> 0
ORDER BY   e.last_worker_time / (CAST(e.total_worker_time AS DECIMAL(22,1)) / e.execution_count) DESC;

-- physical_read
SELECT     a.database_name
         , a.schema_name
         , a.object_name
         , e.last_execution_time
         , e.execution_count
         , e.last_physical_reads
         , CAST(e.total_physical_reads AS DECIMAL(22,1)) / e.execution_count                         AS ave_physical_reads
         , e.last_physical_reads / (CAST(e.total_physical_reads AS DECIMAL(22,1)) / e.execution_count) AS ratio_physical_reads
FROM       sys.dm_exec_procedure_stats AS e
INNER JOIN #AllProcedures              AS a ON a.database_id = e.database_id AND a.object_id = e.object_id
WHERE      e.total_physical_reads <> 0
ORDER BY   e.last_physical_reads / (CAST(e.total_physical_reads AS DECIMAL(22,1)) / e.execution_count) DESC;

-- logical_reads
SELECT     a.database_name
         , a.schema_name
         , a.object_name
         , e.last_execution_time
         , e.execution_count
         , e.last_logical_reads
         , CAST(e.total_logical_reads AS DECIMAL(22,1)) / e.execution_count                         AS ave_logical_reads
         , e.last_logical_reads / (CAST(e.total_logical_reads AS DECIMAL(22,1)) / e.execution_count) AS ratio_logical_reads
FROM       sys.dm_exec_procedure_stats AS e
INNER JOIN #AllProcedures              AS a ON a.database_id = e.database_id AND a.object_id = e.object_id
WHERE      e.total_logical_reads <> 0
ORDER BY   e.last_logical_reads / (CAST(e.total_logical_reads AS DECIMAL(22,1)) / e.execution_count) DESC;

-- logical_writes
SELECT     a.database_name
         , a.schema_name
         , a.object_name
         , e.last_execution_time
         , e.execution_count
         , e.last_logical_writes
         , CAST(e.total_logical_writes AS DECIMAL(22,1)) / e.execution_count                         AS ave_logical_writes
         , e.last_logical_writes / (CAST(e.total_logical_writes AS DECIMAL(22,1)) / e.execution_count) AS ratio_logical_writes
FROM       sys.dm_exec_procedure_stats AS e
INNER JOIN #AllProcedures              AS a ON a.database_id = e.database_id AND a.object_id = e.object_id
WHERE      e.total_logical_writes <> 0
ORDER BY   e.last_logical_writes / (CAST(e.total_logical_writes AS DECIMAL(22,1)) / e.execution_count) DESC;




---------------------------------------
--// CLEAN UP                      //--
---------------------------------------

IF OBJECT_ID(N'tempdb..#AllProcedures',N'U') IS NOT NULL DROP TABLE #AllProcedures;
