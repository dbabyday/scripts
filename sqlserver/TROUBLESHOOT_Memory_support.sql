-- SQL Server Memory
-- http://www.sqlservercentral.com/articles/Memory/134032/?utm_source=SSC&utm_medium=pubemail
-- https://simplesqlserver.com/2013/08/13/sys-dm_os_perfomance_counters-demystified/



/**********************************************************************************************************
* 
* Page Life Expectancy (PLE)
* 
*     Want > 300 seconds
*     quick drops, slow increases okay
*     remaining low ---> may need to add RAM
* 
**********************************************************************************************************/

--  SQL Server: Buffer Manager - Page Life Expectancy

SELECT [cntr_value]
FROM   [sys].[dm_os_performance_counters]
WHERE  [object_name] LIKE '%Buffer Manager%'
       AND [counter_name] = 'Page life expectancy';



/**********************************************************************************************************
* 
* Available MBytes
* 
*     Want > 500 MB
* 
**********************************************************************************************************/

--  Memory: Available MBytes



/**********************************************************************************************************
* 
* Buffer Cache Hit Ratio
* 
*     Want high in OLTP servers – around 90-95%
*     If consistently below 90% ---> may need to add RAM
* 
**********************************************************************************************************/

--  SQL Server: Buffer Manager: Buffer Cache Hit Ratio

SELECT [cntr_value]
FROM   [sys].[dm_os_performance_counters]
WHERE  [object_name] LIKE '%Buffer Manager%'
       AND [counter_name] = 'Buffer cache hit ratio';



/**********************************************************************************************************
* 
* Target & Total Server Memory
* 
*     Should be close to the same
*     If not: 1. Doesn't need that much memory allocated
*             2. External memory pressure may be limiting SQL Server's
* 
**********************************************************************************************************/

--  SQL Server: Memory Manager – Total Server Memory
--  SQL Server: Memory Manager – Target Server Memory

SELECT [cntr_value]
FROM   [sys].[dm_os_performance_counters]
WHERE  [object_name] LIKE '%Memory Manager%'
       AND [counter_name] IN ('Total Server Memory (KB)','Target Server Memory (KB)');


/**********************************************************************************************************
* 
* Memory Grants Pending
* 
*     total number of SQL processes waiting for a workspace memory grant
*     Want < 1
*     
*     Memory grants pending could be due to bad queries, missing indexes, 
*     sorts or hashes.  To investigate this, you can query the sys.dm_exec_query_memory_grants view, 
*     which will show which queries (if any) that require a memory grant to execute.
*     
*     If not due to above, increase memory
* 
**********************************************************************************************************/

--  SQL Server: Memory Manager – Memory Grant Pending

SELECT [cntr_value]
FROM   [sys].[dm_os_performance_counters]
WHERE  [object_name] LIKE '%Memory Manager%'
       AND [counter_name] = 'Memory Grants Pending';



/**********************************************************************************************************
* 
* Pages/sec (Hard Page Faults)
* 
*     the number of pages read from or written to disk
*     Want  below 50, and closer to 0
*     
*     high Pages/sec value can happen while doing database backups or restores, 
*     importing or exporting data, or by reading a file mapped in memory
*     
*     If the values are consistently higher that your baseline value, you should consider adding more RAM
* 
**********************************************************************************************************/

--  Memory: Pages/sec



/**********************************************************************************************************
* 
* Batch Request & Compilations
* 
*     Batch Requests/sec - number of incoming queries
*     Compliations/sec - number of new executions plans SQL had to build
*     
*     If Compilations/sec is 25% or higher relative to Batch Requests/sec, SQL Server 
*     is putting execution plans in the cache, but never actually reusing them.  Memory 
*     is being used up to cache query execution plans that will never be used again – instead of caching data.
*     
*     A high Compilation/sec value (like over 100) indicates there are a lot of Ad-Hoc (one-hit-wonder) 
*     queries being run.  You can enable the “optimize for ad hoc” setting if this is the case, and 
*     this will put the execution plan in the buffer, but only after the second time it has been used.
* 
**********************************************************************************************************/

--  SQL Server: SQL Statistics – Batch Request/Sec
--  SQL Server: SQL Statistics - Compilations/Sec

SELECT [cntr_value]
FROM sys.dm_os_performance_counters
WHERE [object_name] LIKE '%SQL Statistics%'
AND [counter_name] = 'Batch Requests/sec';

SELECT [cntr_value]
FROM sys.dm_os_performance_counters
WHERE [object_name] LIKE '%SQL Statistics%'
AND [counter_name] = 'SQL Compilations/sec';

SELECT ROUND ( 100.0 *
               (SELECT [cntr_value] FROM [sys].[dm_os_performance_counters] WHERE [object_name] LIKE '%SQL Statistics%' AND [counter_name] = 'SQL Compilations/sec') /
               (SELECT [cntr_value] FROM [sys].[dm_os_performance_counters] WHERE [object_name] LIKE '%SQL Statistics%' AND [counter_name] = 'Batch Requests/sec')
               ,2 ) as [Ratio];
















