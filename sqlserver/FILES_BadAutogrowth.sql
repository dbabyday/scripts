

SELECT
	DB_NAME([f].[database_id]), 
	[f].[name], 
	[size_MB] = [f].[size] / 128, 
	CASE [f].[is_percent_growth]
		WHEN 0 THEN CAST(([f].[growth] / 128) AS VARCHAR(10)) + ' MB'
		WHEN 1 THEN CAST([f].[growth] AS VARCHAR(3)) + ' %'
	END AS [growth], 
	CASE 
		WHEN ([f].[size] / 128) <  72		THEN '4 MB'
		WHEN ([f].[size] / 128) <  144		THEN '8 MB'
		WHEN ([f].[size] / 128) <  288		THEN '16 MB'
		WHEN ([f].[size] / 128) <  1152		THEN '32 MB'
		WHEN ([f].[size] / 128) <  2304		THEN '64 MB'
		WHEN ([f].[size] / 128) <  2048		THEN '128 MB'
		WHEN ([f].[size] / 128) <  4608		THEN '256 MB'
		WHEN ([f].[size] / 128) <  9216		THEN '512 MB'
		WHEN ([f].[size] / 128) <  22528	THEN '1024 MB'
		WHEN ([f].[size] / 128) >= 22528	THEN '2048 MB'
	END AS [Desired Autogrowth],
	[Command To Change Autogrowth] = 
		CASE
			WHEN ([f].[is_percent_growth] = 1)                                   AND (([f].[size] / 128) <  72)    THEN 'ALTER DATABASE [' + DB_NAME([f].[database_id]) + '] MODIFY FILE ( NAME = N''' + [f].[name] + ''', FILEGROWTH = 4MB );'
			WHEN ([f].[is_percent_growth] = 1) AND (([f].[size] / 128) >=  72)   AND (([f].[size] / 128) <  144)   THEN 'ALTER DATABASE [' + DB_NAME([f].[database_id]) + '] MODIFY FILE ( NAME = N''' + [f].[name] + ''', FILEGROWTH = 8MB );'
			WHEN ([f].[is_percent_growth] = 1) AND (([f].[size] / 128) >=  144)  AND (([f].[size] / 128) <  288)   THEN 'ALTER DATABASE [' + DB_NAME([f].[database_id]) + '] MODIFY FILE ( NAME = N''' + [f].[name] + ''', FILEGROWTH = 16MB );'
			WHEN ([f].[is_percent_growth] = 1) AND (([f].[size] / 128) >=  288)  AND (([f].[size] / 128) <  576)   THEN 'ALTER DATABASE [' + DB_NAME([f].[database_id]) + '] MODIFY FILE ( NAME = N''' + [f].[name] + ''', FILEGROWTH = 32MB );'
			WHEN ([f].[is_percent_growth] = 1) AND (([f].[size] / 128) >=  576)  AND (([f].[size] / 128) <  1152)  THEN 'ALTER DATABASE [' + DB_NAME([f].[database_id]) + '] MODIFY FILE ( NAME = N''' + [f].[name] + ''', FILEGROWTH = 64MB );'
			WHEN ([f].[is_percent_growth] = 1) AND (([f].[size] / 128) >=  1152) AND (([f].[size] / 128) <  2304)  THEN 'ALTER DATABASE [' + DB_NAME([f].[database_id]) + '] MODIFY FILE ( NAME = N''' + [f].[name] + ''', FILEGROWTH = 128MB );'
			WHEN ([f].[is_percent_growth] = 1) AND (([f].[size] / 128) >=  2304) AND (([f].[size] / 128) <  4608)  THEN 'ALTER DATABASE [' + DB_NAME([f].[database_id]) + '] MODIFY FILE ( NAME = N''' + [f].[name] + ''', FILEGROWTH = 256MB );'
			WHEN ([f].[is_percent_growth] = 1) AND (([f].[size] / 128) >=  4608) AND (([f].[size] / 128) <  9216)  THEN 'ALTER DATABASE [' + DB_NAME([f].[database_id]) + '] MODIFY FILE ( NAME = N''' + [f].[name] + ''', FILEGROWTH = 512MB );'
			WHEN ([f].[is_percent_growth] = 1) AND (([f].[size] / 128) >=  9216) AND (([f].[size] / 128) <  22528) THEN 'ALTER DATABASE [' + DB_NAME([f].[database_id]) + '] MODIFY FILE ( NAME = N''' + [f].[name] + ''', FILEGROWTH = 1024MB );'
			WHEN ([f].[is_percent_growth] = 1) AND (([f].[size] / 128) >=  22528)                                  THEN 'ALTER DATABASE [' + DB_NAME([f].[database_id]) + '] MODIFY FILE ( NAME = N''' + [f].[name] + ''', FILEGROWTH = 2048MB );'
			
			WHEN ([f].[is_percent_growth] = 0)                                   AND (([f].[size] / 128) <  72)    AND (([f].[growth] / 128) != 4)    THEN 'ALTER DATABASE [' + DB_NAME([f].[database_id]) + '] MODIFY FILE ( NAME = N''' + [f].[name] + ''', FILEGROWTH = 4MB );'
			WHEN ([f].[is_percent_growth] = 0) AND (([f].[size] / 128) >= 72)    AND (([f].[size] / 128) <  144)   AND (([f].[growth] / 128) != 8)    THEN 'ALTER DATABASE [' + DB_NAME([f].[database_id]) + '] MODIFY FILE ( NAME = N''' + [f].[name] + ''', FILEGROWTH = 8MB );'
			WHEN ([f].[is_percent_growth] = 0) AND (([f].[size] / 128) >= 144)   AND (([f].[size] / 128) <  288)   AND (([f].[growth] / 128) != 16)   THEN 'ALTER DATABASE [' + DB_NAME([f].[database_id]) + '] MODIFY FILE ( NAME = N''' + [f].[name] + ''', FILEGROWTH = 16MB );'
			WHEN ([f].[is_percent_growth] = 0) AND (([f].[size] / 128) >= 288)   AND (([f].[size] / 128) <  576)   AND (([f].[growth] / 128) != 32)   THEN 'ALTER DATABASE [' + DB_NAME([f].[database_id]) + '] MODIFY FILE ( NAME = N''' + [f].[name] + ''', FILEGROWTH = 32MB );'
			WHEN ([f].[is_percent_growth] = 0) AND (([f].[size] / 128) >= 576)   AND (([f].[size] / 128) <  1152)  AND (([f].[growth] / 128) != 64)   THEN 'ALTER DATABASE [' + DB_NAME([f].[database_id]) + '] MODIFY FILE ( NAME = N''' + [f].[name] + ''', FILEGROWTH = 64MB );'
			WHEN ([f].[is_percent_growth] = 0) AND (([f].[size] / 128) >= 1152)  AND (([f].[size] / 128) <  2304)  AND (([f].[growth] / 128) != 128)  THEN 'ALTER DATABASE [' + DB_NAME([f].[database_id]) + '] MODIFY FILE ( NAME = N''' + [f].[name] + ''', FILEGROWTH = 128MB );'
			WHEN ([f].[is_percent_growth] = 0) AND (([f].[size] / 128) >= 2304)  AND (([f].[size] / 128) <  4608)  AND (([f].[growth] / 128) != 256)  THEN 'ALTER DATABASE [' + DB_NAME([f].[database_id]) + '] MODIFY FILE ( NAME = N''' + [f].[name] + ''', FILEGROWTH = 256MB );'
			WHEN ([f].[is_percent_growth] = 0) AND (([f].[size] / 128) >= 4608)  AND (([f].[size] / 128) <  9216)  AND (([f].[growth] / 128) != 512)  THEN 'ALTER DATABASE [' + DB_NAME([f].[database_id]) + '] MODIFY FILE ( NAME = N''' + [f].[name] + ''', FILEGROWTH = 512MB );'
			WHEN ([f].[is_percent_growth] = 0) AND (([f].[size] / 128) >= 9216)  AND (([f].[size] / 128) <  22528) AND (([f].[growth] / 128) != 1024) THEN 'ALTER DATABASE [' + DB_NAME([f].[database_id]) + '] MODIFY FILE ( NAME = N''' + [f].[name] + ''', FILEGROWTH = 1024MB );'
			WHEN ([f].[is_percent_growth] = 0) AND (([f].[size] / 128) >= 22528)                                   AND (([f].[growth] / 128) != 2048) THEN 'ALTER DATABASE [' + DB_NAME([f].[database_id]) + '] MODIFY FILE ( NAME = N''' + [f].[name] + ''', FILEGROWTH = 2048MB );'
			
			ELSE '-- Database [' + DB_NAME([f].[database_id]) + '], File [' + [f].[name] + '] has the standard autogrowth already set.'
		END
FROM 
	[sys].[master_files] AS [f]
INNER JOIN
	[sys].[databases] AS [d]
	ON [d].[database_id] = [f].[database_id]
WHERE
	DB_NAME([f].[database_id]) NOT IN ('tempdb', 'distribution')
	AND [f].type IN (0,1)
	AND [d].[state] = 0 -- database online
	AND [d].[is_read_only] = 0 -- read_write
	AND [f].state = 0 -- file online
	
	AND 
		CASE [f].[is_percent_growth]
			WHEN 0 THEN CAST(([f].[growth] / 128) AS VARCHAR(10)) + ' MB'
			WHEN 1 THEN CAST([f].[growth] AS VARCHAR(3)) + ' %'
		END
		!=
		CASE 
			WHEN ([f].[size] / 128) <  72		THEN '4 MB'
			WHEN ([f].[size] / 128) <  144		THEN '8 MB'
			WHEN ([f].[size] / 128) <  288		THEN '16 MB'
			WHEN ([f].[size] / 128) <  576		THEN '32 MB'
			WHEN ([f].[size] / 128) <  1152		THEN '64 MB'
			WHEN ([f].[size] / 128) <  2304		THEN '128 MB'
			WHEN ([f].[size] / 128) <  4608		THEN '256 MB'
			WHEN ([f].[size] / 128) <  9216		THEN '512 MB'
			WHEN ([f].[size] / 128) <  22528	THEN '1024 MB'
			WHEN ([f].[size] / 128) >= 22528	THEN '2048 MB'
		END

/*



*/