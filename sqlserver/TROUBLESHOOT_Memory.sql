/***************************************************************************************
* 
* TROUBLESHOOT_Memory.sql
* 
* Date: 2017-07-05
* Author: James Lutsey
* 
* Purpose: Get a snapshot of SQL Server memory metrics
* 
* Date        Name              Description
* ----------  ----------------  -------------------------------------------------------
* 2018-07-20  James Lutsey      Added physical memory and max memory configuration
* 
***************************************************************************************/

DECLARE @batchRequestsPerSecond_1   BIGINT,
        @batchRequestsPerSecond_2   BIGINT,
        @bufferCacheHitRatio        BIGINT,
        @bufferCacheHitRatioBase    BIGINT,
        @maxServerMemoryMb          BIGINT,
        @memoryGrantsPending        BIGINT,
        @pageLifeExpectancy         BIGINT,
        @physicalMemory             DECIMAL(12,1),
        @sql                        NVARCHAR(MAX),
        @sqlCompliationsPerSecond_1 BIGINT,
        @sqlCompliationsPerSecond_2 BIGINT,
        @targetServerMemoryKb       BIGINT,
        @time_1                     DATETIME2(3),
        @time_2                     DATETIME2(3),
        @totalServerMemoryKb        BIGINT;
        
-- get the first vaule for counters based on time
SELECT @batchRequestsPerSecond_1   = [cntr_value] FROM [sys].[dm_os_performance_counters] WHERE [object_name] LIKE '%SQL Statistics%' AND [counter_name] = 'Batch Requests/sec';
SELECT @SqlCompliationsPerSecond_1 = [cntr_value] FROM [sys].[dm_os_performance_counters] WHERE [object_name] LIKE '%SQL Statistics%' AND [counter_name] = 'SQL Compilations/sec';
SELECT @time_1                     = GETDATE();

-- wait a while for counters based on time
WAITFOR DELAY '00:01:00';

-- get the values
SELECT @bufferCacheHitRatio        = [cntr_value] FROM [sys].[dm_os_performance_counters] WHERE [object_name] LIKE '%Buffer Manager%' AND [counter_name] = 'Buffer cache hit ratio';
SELECT @bufferCacheHitRatioBase    = [cntr_value] FROM [sys].[dm_os_performance_counters] WHERE [object_name] LIKE '%Buffer Manager%' AND [counter_name] = 'Buffer cache hit ratio base';
SELECT @pageLifeExpectancy         = [cntr_value] FROM [sys].[dm_os_performance_counters] WHERE [object_name] LIKE '%Buffer Manager%' AND [counter_name] = 'Page life expectancy';
SELECT @batchRequestsPerSecond_2   = [cntr_value] FROM [sys].[dm_os_performance_counters] WHERE [object_name] LIKE '%SQL Statistics%' AND [counter_name] = 'Batch Requests/sec';
SELECT @sqlCompliationsPerSecond_2 = [cntr_value] FROM [sys].[dm_os_performance_counters] WHERE [object_name] LIKE '%SQL Statistics%' AND [counter_name] = 'SQL Compilations/sec';
SELECT @memoryGrantsPending        = [cntr_value] FROM [sys].[dm_os_performance_counters] WHERE [object_name] LIKE '%Memory Manager%' AND [counter_name] = 'Memory Grants Pending';
SELECT @targetServerMemoryKb       = [cntr_value] FROM [sys].[dm_os_performance_counters] WHERE [object_name] LIKE '%Memory Manager%' AND [counter_name] = 'Target Server Memory (KB)';
SELECT @totalServerMemoryKb        = [cntr_value] FROM [sys].[dm_os_performance_counters] WHERE [object_name] LIKE '%Memory Manager%' AND [counter_name] = 'Total Server Memory (KB)';
SELECT @maxServerMemoryMb          = CAST([value_in_use] AS BIGINT) FROM [sys].[configurations] WHERE [name] = 'max server memory (MB)';
SELECT @time_2                     = GETDATE();

-- get the server's physical memory
IF CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(25)),4) AS DECIMAL(5,1)) >= 11.0 -- 2012+
    SET @sql = N'SELECT @physicalMemoryOUT = CAST(ROUND(physical_memory_kb/1024.0/1024,1) AS DECIMAL(12,1)) FROM sys.dm_os_sys_info;';
ELSE -- 2005, 2008, 2008R2
    SET @sql = N'SELECT @physicalMemoryOUT = CAST(ROUND(physical_memory_in_bytes/1024.0/1024/1024,1) AS DECIMAL(12,1)) FROM sys.dm_os_sys_info;';
EXECUTE sys.sp_executesql @sql
                        , N'@physicalMemoryOUT DECIMAL(12,1) OUTPUT'
                        , @physicalMemoryOUT = @physicalMemory OUTPUT;

--/*
-- calculate and display
SELECT 'Server' AS [object_name],
       'Physical Memory' AS [counter_name],
       CAST(@physicalMemory AS VARCHAR(12)) + ' GB' AS [value],
       '> Max Server Memory' AS [guideline]
UNION ALL
SELECT 'sys.configurations' AS [object_name],
       'Max Server Memory' AS [counter_name],
       CAST(CAST(ROUND(@maxServerMemoryMb / 1024.0,1) AS DECIMAL(12,1)) AS VARCHAR(12)) + ' GB' AS [value],
       '< Physical Memory' AS [guideline]
UNION ALL
SELECT 'SQLServer:Memory Manager' AS [object_name],
       'Target Server Memory' AS [counter_name],
       CAST(CAST(ROUND(@targetServerMemoryKb / 1024.0 / 1024.0,1) AS DECIMAL(9,1)) AS VARCHAR(12)) + ' GB' AS [value],
       'About the same as Max Server Memory' AS [guideline]
UNION ALL
SELECT 'SQLServer:Memory Manager' AS [object_name],
       'Total Server Memory' AS [counter_name],
       CAST(CAST(ROUND(@totalServerMemoryKb / 1024.0 / 1024.0,1) AS DECIMAL(9,1)) AS VARCHAR(12)) + ' GB' AS [value],
       'About the same as Target' AS [guideline]
UNION ALL
SELECT 'SQLServer:Memory Manager' AS [object_name],
       'Memory Grants Pending' AS [counter_name],
       CAST(@memoryGrantsPending AS VARCHAR(20)) AS [value],
       '0' AS [guideline]
UNION ALL
SELECT 'SQLServer:Buffer Manager' AS [object_name],
       'Page life expectancy' AS [counter_name],
       CAST(@pageLifeExpectancy AS VARCHAR(20)) + ' seconds' AS [value],
       '> ' + CAST(CAST(ROUND(@maxServerMemoryMb / 1024.0 / 4 * 300,0) AS INT) AS VARCHAR(21)) + ' seconds (max memory / 4 * 300)' AS [guideline]
UNION ALL
SELECT 'SQLServer:SQL Statistics' AS [object_name],
       'SQL Compilations / Batch Req' AS [counter_name],
       CASE
           WHEN @batchRequestsPerSecond_2 <> @batchRequestsPerSecond_1
           THEN CAST(CAST(ROUND(100.0 * ( (1.0 * @sqlCompliationsPerSecond_2 - @sqlCompliationsPerSecond_1)  / DATEDIFF(SECOND,@time_1,@time_2) ) / ( (1.0 * @batchRequestsPerSecond_2 - @batchRequestsPerSecond_1) / DATEDIFF(SECOND,@time_1,@time_2) ),1) AS DECIMAL(5,1)) AS VARCHAR(12)) + '%'
           ELSE 'no batch requests'
       END AS [value],
       '< 25%' AS [guideline]
UNION ALL
SELECT 'SQLServer:SQL Statistics' AS [object_name],
       'SQL Compilations/sec' AS [counter_name],
       CAST(CAST((1.0 * @sqlCompliationsPerSecond_2 - @sqlCompliationsPerSecond_1)  / DATEDIFF(SECOND,@time_1,@time_2) AS DECIMAL(20,1)) AS VARCHAR(21)) AS [value],
       '< 100 (big number indicates lots of ad-hoc queries)' AS [guideline]
UNION ALL
SELECT 'SQLServer:SQL Statistics' AS [object_name],
       'Batch Requests/sec' AS [counter_name],
       CAST(CAST((1.0 * @batchRequestsPerSecond_2 - @batchRequestsPerSecond_1) / DATEDIFF(SECOND,@time_1,@time_2) AS DECIMAL(20,1)) AS VARCHAR(21)) AS [value],
       '> 4x Compliations' AS [guideline]
UNION ALL
SELECT 'SQLServer:Buffer Manager' AS [object_name],
       'Buffer cache hit ratio' AS [counter_name],
       CAST(CAST(ROUND(100.0 * @bufferCacheHitRatio / @bufferCacheHitRatioBase,2) AS DECIMAL(5,2)) AS VARCHAR(12)) + '%' AS [value],
       'OLTP: > 90%' AS [guideline]
--*/

/*
SELECT [object_name],
       [counter_name],
       [cntr_value],
       CASE [cntr_type]
           WHEN 65792      THEN 'Stands By Itself'
           WHEN 272696576  THEN 'Per-second...calculate with 2 values separated by a waitfor'
           WHEN 537003264  THEN 'Value that needs to be divided by its base'
           WHEN 1073874176 THEN 'Stands By Itself'
           WHEN 1073939712 THEN 'Base to divide value by'
           ELSE 'Unaccounted For Type'
       END AS [cntr_type]
FROM   [sys].[dm_os_performance_counters];
--*/


