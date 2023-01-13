--All memory and assigned memory
SELECT
       physical_memory_kb/1024 AS [Physical Memory (MB)]
       , committed_kb/1024 AS [Committed Memory (MB)]
FROM sys.dm_os_sys_info;

--Buckets
SELECT
    object_name,
    counter_name,
    instance_name,
    cntr_value / 1024 AS [Memory Size (MB)]
FROM sys.dm_os_performance_counters
WHERE dm_os_performance_counters.object_name = 'SQLServer:Memory Manager'
AND counter_name IN ('Connection Memory (KB)'
,'Database Cache Memory (KB)'
,'Free Memory (KB)'
,'Granted Workspace Memory (KB)'
,'Lock Memory (KB)')
UNION
SELECT
    object_name,
    counter_name,
    instance_name,
    cntr_value * 8 / 1024
FROM sys.dm_os_performance_counters
WHERE dm_os_performance_counters.object_name LIKE '%Plan Cache%'
AND counter_name = 'Cache Pages'
AND instance_name = '_Total'
UNION
SELECT
    object_name,
    counter_name,
    instance_name,
    cntr_value / 1024
FROM sys.dm_os_performance_counters
WHERE dm_os_performance_counters.object_name = 'SQLServer:Memory Manager'
AND counter_name = 'Total Server Memory (KB)';

--dbcc memorystatus
                   
--Clerks                       
SELECT SUM(pages_kb) / 1024,
       type,
       name
FROM sys.dm_os_memory_clerks
GROUP BY type,
         name
HAVING SUM(pages_kb) / 1024 > 0
ORDER BY SUM(pages_kb) / 1024 DESC;                  
