USE [tempdb];

SELECT
	DB_NAME() as 'Database',
	[df].[name] as 'File',
	CAST(ROUND([df].[size] / 128.0, 0) AS INT) AS 'CurrentSize_MB',
	CAST(ROUND([mf].[size] / 128.0, 0) AS INT) AS 'InitialSize_MB',
	CAST(ROUND(([df].[size] - [mf].[size]) / 128.0, 0) AS INT) AS 'Difference_MB'
FROM	
	[tempdb].[sys].[database_files] df
LEFT OUTER JOIN
	[sys].[master_files] mf
	ON [df].[name] = [mf].[name]
ORDER BY 
	[df].[name];

SELECT * FROM [tempdb].[sys].[database_files] ORDER BY [name];

