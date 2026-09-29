			SELECT 
    cpu_count AS [Logical CPU Count], 
	hyperthread_ratio AS Hyperthread_Ratio,
    cpu_count/hyperthread_ratio AS Physical_CPU_Count,
    physical_memory_kb/1024.0/1024.0 AS Physical_Memory_in_GB,  -- physical_memory_in_bytes/1048576  
    sqlserver_start_time, 
	affinity_type_desc 
FROM sys.dm_os_sys_info
