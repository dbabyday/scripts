SET NOCOUNT ON;

DECLARE 
    @Command		NVARCHAR(MAX),
	@Database		NVARCHAR(260),
	@DriveLetter	CHAR(1),
	@DriveNameOut	INT,
	@FSO			INT, 
	@Result			INT,
    @TotalSizeOut	VARCHAR(20);

IF (OBJECT_ID('tempdb..#FileInfo') IS NOT NULL)
	DROP TABLE #FileInfo;

CREATE TABLE #FileInfo
(
	[ID]				INT IDENTITY(1,1) PRIMARY KEY,
	[Database]			NVARCHAR(260),
	[name]				SYSNAME,
	[type_desc]			NVARCHAR(120),
	[size]				INT,
	[Used_Pages]		INT,
	[is_percent_growth]	BIT,
	[growth]			INT,
	[max_size]			INT,
	[physical_name]		NVARCHAR(520)
);



------------------------------------------------------------------------------------------
--// GET FILE INFO                                                                    //--
------------------------------------------------------------------------------------------

DECLARE curDatabases CURSOR FAST_FORWARD FOR
	SELECT name 
	FROM master.sys.databases
	WHERE state = 0; -- online

OPEN curDatabases;
	FETCH NEXT FROM curDatabases INTO @Database;

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		EXECUTE
		('
			USE [' + @Database + '];
			INSERT INTO #FileInfo
			(
				[Database],
				[name],
				[type_desc],
				[size],
				[Used_Pages],
				[is_percent_growth],
				[growth],
				[max_size],
				[physical_name]
			)
			SELECT
				DB_NAME(),
				[name],
				[type_desc],
				[size],
				FILEPROPERTY([name], ''SpaceUsed''),
				[is_percent_growth],
				[growth],
				[max_size],
				[physical_name]
			FROM
				sys.database_files'
		);
    
		FETCH NEXT FROM curDatabases INTO @Database;
	END
CLOSE curDatabases;
DEALLOCATE curDatabases;



------------------------------------------------------------------------------------------
--// DISPLAY FILE INFO - master, model, msdb                                          //--
------------------------------------------------------------------------------------------

SELECT
	/*1*/ @@SERVERNAME AS [server],
	/*2*/ [f].[Database],
	/*3*/ [File] = [f].[name],
	/*4*/ [f].[type_desc],
	/*5*/ [Size_MB] =	CASE
							WHEN LEN(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 8
								THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),9,0,','),6,0,','))
							WHEN LEN(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 5 
								THEN REVERSE(STUFF(REVERSE(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),6,0,','))
							ELSE CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))
						END,
	/*6*/ [Used_MB] =	CASE
							WHEN LEN(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 8 
								THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),9,0,','),6,0,','))
							WHEN LEN(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 5
								THEN REVERSE(STUFF(REVERSE(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),6,0,','))
							ELSE CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))
						END,
	/*7*/ [Free_MB] =	CASE
							WHEN LEN(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))) > 8 
								THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))),9,0,','),6,0,','))
							WHEN LEN(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))) > 5
								THEN REVERSE(STUFF(REVERSE(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))),6,0,','))
							ELSE CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))
						END,
	/*8*/ [% free] =	CASE 
							WHEN [f].[size] != 0 THEN CAST((CAST(([f].[size] - [f].[Used_Pages]) AS DECIMAL(10,1)) / CAST([f].[size] AS DECIMAL(10,1)) * 100) AS DECIMAL(4,1))
							ELSE 0.0
						END,
	/*9*/ [Autogrowth] =	CASE [f].[is_percent_growth]
								WHEN 0 THEN CAST(([f].[growth] / 128) AS VARCHAR(10)) + ' MB'
								WHEN 1 THEN CAST([f].[growth] AS VARCHAR(3)) + ' %'
							END,
	/*10*/ [max_size] =	CASE [f].[max_size]
							WHEN 0 THEN 'No Growth'
							WHEN -1 THEN 'No Max'
							WHEN 268435456 THEN '2 TB'
							ELSE
								CASE
									WHEN LEN(CAST(CAST((max_size / 128) AS VARCHAR(10)) AS VARCHAR(27))) > 6
										THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST((max_size / 128) AS VARCHAR(10)) AS VARCHAR(27))),7,0,','),4,0,','))
									WHEN LEN(CAST(CAST((max_size / 128) AS VARCHAR(10)) AS VARCHAR(27))) > 3
										THEN REVERSE(STUFF(REVERSE(CAST(CAST((max_size / 128) AS VARCHAR(10)) AS VARCHAR(27))),4,0,','))
									ELSE CAST(CAST((max_size / 128) AS VARCHAR(10)) AS VARCHAR(27))
								END 
						END,
	/*11*/ [Drive] =	LEFT([f].[physical_name],3),
	/*12*/ [usp_FileGrowth @where] = 'sqlservername = ''''' + @@SERVERNAME + ''''' AND databasename = ''''' + [f].[Database] +''''' AND DatabaseFileName = ''''' + [f].[name] + ''''''
FROM 
	#FileInfo AS [f]
WHERE 
	[f].[type_desc] != 'FILESTREAM' 
	AND [f].[Database] IN ('master','model','msdb')
	--AND /*File <10% free*/ CAST((CAST(([f].[size] - [f].[Used_Pages]) AS DECIMAL(10,1)) / CAST([f].[size] AS DECIMAL(10,1)) * 100) AS DECIMAL(4,1)) <= 10
ORDER BY 
	4 desc,2,3;
    --2,3;  -- Database, File



------------------------------------------------------------------------------------------
--// DISPLAY FILE INFO - tempdb                                                       //--
------------------------------------------------------------------------------------------

SELECT
	/*1*/ @@SERVERNAME AS [server],
	/*2*/ [f].[Database],
	/*3*/ [File] = [f].[name],
	/*4*/ [f].[type_desc],
	/*5*/ [Size_MB] =	CASE
							WHEN LEN(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 8
								THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),9,0,','),6,0,','))
							WHEN LEN(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 5 
								THEN REVERSE(STUFF(REVERSE(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),6,0,','))
							ELSE CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))
						END,
	/*6*/ [Used_MB] =	CASE
							WHEN LEN(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 8 
								THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),9,0,','),6,0,','))
							WHEN LEN(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 5
								THEN REVERSE(STUFF(REVERSE(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),6,0,','))
							ELSE CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))
						END,
	/*7*/ [Free_MB] =	CASE
							WHEN LEN(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))) > 8 
								THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))),9,0,','),6,0,','))
							WHEN LEN(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))) > 5
								THEN REVERSE(STUFF(REVERSE(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))),6,0,','))
							ELSE CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))
						END,
	/*8*/ [% free] =	CASE 
							WHEN [f].[size] != 0 THEN CAST((CAST(([f].[size] - [f].[Used_Pages]) AS DECIMAL(10,1)) / CAST([f].[size] AS DECIMAL(10,1)) * 100) AS DECIMAL(4,1))
							ELSE 0.0
						END,
	/*9*/ [Autogrowth] =	CASE [f].[is_percent_growth]
								WHEN 0 THEN CAST(([f].[growth] / 128) AS VARCHAR(10)) + ' MB'
								WHEN 1 THEN CAST([f].[growth] AS VARCHAR(3)) + ' %'
							END,
	/*10*/ [max_size] =	CASE [f].[max_size]
							WHEN 0 THEN 'No Growth'
							WHEN -1 THEN 'No Max'
							WHEN 268435456 THEN '2 TB'
							ELSE
								CASE
									WHEN LEN(CAST(CAST((max_size / 128) AS VARCHAR(10)) AS VARCHAR(27))) > 6
										THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST((max_size / 128) AS VARCHAR(10)) AS VARCHAR(27))),7,0,','),4,0,','))
									WHEN LEN(CAST(CAST((max_size / 128) AS VARCHAR(10)) AS VARCHAR(27))) > 3
										THEN REVERSE(STUFF(REVERSE(CAST(CAST((max_size / 128) AS VARCHAR(10)) AS VARCHAR(27))),4,0,','))
									ELSE CAST(CAST((max_size / 128) AS VARCHAR(10)) AS VARCHAR(27))
								END 
						END,
	/*11*/ [Drive] =	LEFT([f].[physical_name],3),
	/*12*/ [usp_FileGrowth @where] = 'sqlservername = ''''' + @@SERVERNAME + ''''' AND databasename = ''''' + [f].[Database] +''''' AND DatabaseFileName = ''''' + [f].[name] + ''''''
FROM 
	#FileInfo AS [f]
WHERE 
	[f].[type_desc] != 'FILESTREAM' 
	AND [f].[Database] = 'tempdb'
	--AND /*File <10% free*/ CAST((CAST(([f].[size] - [f].[Used_Pages]) AS DECIMAL(10,1)) / CAST([f].[size] AS DECIMAL(10,1)) * 100) AS DECIMAL(4,1)) <= 10
ORDER BY 
	4 desc,2,3;
    --2,3;  -- Database, File



------------------------------------------------------------------------------------------
--// DISPLAY FILE INFO - user databases - data files                                  //--
------------------------------------------------------------------------------------------

SELECT
	/*1*/ @@SERVERNAME AS [server],
	/*2*/ [f].[Database],
	/*3*/ [File] = [f].[name],
	/*4*/ [f].[type_desc],
	/*5*/ [Size_MB] =	CASE
							WHEN LEN(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 8
								THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),9,0,','),6,0,','))
							WHEN LEN(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 5 
								THEN REVERSE(STUFF(REVERSE(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),6,0,','))
							ELSE CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))
						END,
	/*6*/ [Used_MB] =	CASE
							WHEN LEN(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 8 
								THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),9,0,','),6,0,','))
							WHEN LEN(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 5
								THEN REVERSE(STUFF(REVERSE(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),6,0,','))
							ELSE CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))
						END,
	/*7*/ [Free_MB] =	CASE
							WHEN LEN(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))) > 8 
								THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))),9,0,','),6,0,','))
							WHEN LEN(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))) > 5
								THEN REVERSE(STUFF(REVERSE(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))),6,0,','))
							ELSE CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))
						END,
	/*8*/ [% free] =	CASE 
							WHEN [f].[size] != 0 THEN CAST((CAST(([f].[size] - [f].[Used_Pages]) AS DECIMAL(10,1)) / CAST([f].[size] AS DECIMAL(10,1)) * 100) AS DECIMAL(4,1))
							ELSE 0.0
						END,
	/*9*/ [Autogrowth] =	CASE [f].[is_percent_growth]
								WHEN 0 THEN CAST(([f].[growth] / 128) AS VARCHAR(10)) + ' MB'
								WHEN 1 THEN CAST([f].[growth] AS VARCHAR(3)) + ' %'
							END,
	/*10*/ [max_size] =	CASE [f].[max_size]
							WHEN 0 THEN 'No Growth'
							WHEN -1 THEN 'No Max'
							WHEN 268435456 THEN '2 TB'
							ELSE
								CASE
									WHEN LEN(CAST(CAST((max_size / 128) AS VARCHAR(10)) AS VARCHAR(27))) > 6
										THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST((max_size / 128) AS VARCHAR(10)) AS VARCHAR(27))),7,0,','),4,0,','))
									WHEN LEN(CAST(CAST((max_size / 128) AS VARCHAR(10)) AS VARCHAR(27))) > 3
										THEN REVERSE(STUFF(REVERSE(CAST(CAST((max_size / 128) AS VARCHAR(10)) AS VARCHAR(27))),4,0,','))
									ELSE CAST(CAST((max_size / 128) AS VARCHAR(10)) AS VARCHAR(27))
								END 
						END,
	/*11*/ [Drive] =	LEFT([f].[physical_name],3),
	/*12*/ [usp_FileGrowth @where] = 'sqlservername = ''''' + @@SERVERNAME + ''''' AND databasename = ''''' + [f].[Database] +''''' AND DatabaseFileName = ''''' + [f].[name] + ''''''
FROM 
	#FileInfo AS [f]
WHERE 
	[f].[type_desc] != 'FILESTREAM' 
	AND [f].[Database] NOT IN ('master','model','msdb','tempdb')
	AND [f].[type_desc] = 'ROWS'
	--AND /*File <10% free*/ CAST((CAST(([f].[size] - [f].[Used_Pages]) AS DECIMAL(10,1)) / CAST([f].[size] AS DECIMAL(10,1)) * 100) AS DECIMAL(4,1)) <= 10
ORDER BY 
	4 desc,2,3;
    --2,3;  -- Database, File



------------------------------------------------------------------------------------------
--// DISPLAY FILE INFO - user databases - log files                                   //--
------------------------------------------------------------------------------------------

SELECT
	/*1*/ @@SERVERNAME AS [server],
	/*2*/ [f].[Database],
	/*3*/ [File] = [f].[name],
	/*4*/ [f].[type_desc],
	/*5*/ [Size_MB] =	CASE
							WHEN LEN(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 8
								THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),9,0,','),6,0,','))
							WHEN LEN(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 5 
								THEN REVERSE(STUFF(REVERSE(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),6,0,','))
							ELSE CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))
						END,
	/*6*/ [Used_MB] =	CASE
							WHEN LEN(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 8 
								THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),9,0,','),6,0,','))
							WHEN LEN(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 5
								THEN REVERSE(STUFF(REVERSE(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),6,0,','))
							ELSE CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))
						END,
	/*7*/ [Free_MB] =	CASE
							WHEN LEN(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))) > 8 
								THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))),9,0,','),6,0,','))
							WHEN LEN(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))) > 5
								THEN REVERSE(STUFF(REVERSE(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))),6,0,','))
							ELSE CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))
						END,
	/*8*/ [% free] =	CASE 
							WHEN [f].[size] != 0 THEN CAST((CAST(([f].[size] - [f].[Used_Pages]) AS DECIMAL(10,1)) / CAST([f].[size] AS DECIMAL(10,1)) * 100) AS DECIMAL(4,1))
							ELSE 0.0
						END,
	/*9*/ [Autogrowth] =	CASE [f].[is_percent_growth]
								WHEN 0 THEN CAST(([f].[growth] / 128) AS VARCHAR(10)) + ' MB'
								WHEN 1 THEN CAST([f].[growth] AS VARCHAR(3)) + ' %'
							END,
	/*10*/ [max_size] =	CASE [f].[max_size]
							WHEN 0 THEN 'No Growth'
							WHEN -1 THEN 'No Max'
							WHEN 268435456 THEN '2 TB'
							ELSE
								CASE
									WHEN LEN(CAST(CAST((max_size / 128) AS VARCHAR(10)) AS VARCHAR(27))) > 6
										THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST((max_size / 128) AS VARCHAR(10)) AS VARCHAR(27))),7,0,','),4,0,','))
									WHEN LEN(CAST(CAST((max_size / 128) AS VARCHAR(10)) AS VARCHAR(27))) > 3
										THEN REVERSE(STUFF(REVERSE(CAST(CAST((max_size / 128) AS VARCHAR(10)) AS VARCHAR(27))),4,0,','))
									ELSE CAST(CAST((max_size / 128) AS VARCHAR(10)) AS VARCHAR(27))
								END 
						END,
	/*11*/ [Drive] =	LEFT([f].[physical_name],3),
	/*12*/ [usp_FileGrowth @where] = 'sqlservername = ''''' + @@SERVERNAME + ''''' AND databasename = ''''' + [f].[Database] +''''' AND DatabaseFileName = ''''' + [f].[name] + ''''''
FROM 
	#FileInfo AS [f]
WHERE 
	[f].[type_desc] != 'FILESTREAM' 
	AND [f].[Database] NOT IN ('master','model','msdb','tempdb')
	AND [f].[type_desc] = 'LOG'
	--AND /*File <10% free*/ CAST((CAST(([f].[size] - [f].[Used_Pages]) AS DECIMAL(10,1)) / CAST([f].[size] AS DECIMAL(10,1)) * 100) AS DECIMAL(4,1)) <= 10
ORDER BY 
	4 desc,2,3;
    --2,3;  -- Database, File


------------------------------------------------------------------------------------------
--// CLEAN UP                                                                         //--
------------------------------------------------------------------------------------------

DROP TABLE #FileInfo;



