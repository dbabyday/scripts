SELECT
	  CONVERT(decimal(10,2),ROUND(available_physical_memory_kb / 1024.0 / 1024.0 ,2)) [Available GB]
	, CONVERT(decimal(10,2),ROUND(total_physical_memory_kb / 1024.0 / 1024.0 ,2)) [Installed GB]
	, CONVERT(decimal(10,2),ROUND(( total_physical_memory_kb - available_physical_memory_kb ) * 1.0 / total_physical_memory_kb,2)) [Percent Used]
FROM
	sys.dm_os_sys_memory;


SELECT
	CONVERT(decimal(10,2),ROUND(CAST([value_in_use] AS INT) / 1024.0,2)) [max server memory GB]
FROM
	sys.configurations
WHERE
	name = 'max server memory (MB)';
