/**********************************************************************************************************
* 
* FILES_Info_NoDrives.sql
* 
* Author: James Lutsey
* Date: 02/14/2017
* 
* Purpose: Shows the size, space used, space free, percent free, and autogrowth setting of files.
* 
* Notes: 
*     - Does not show any info on drive space, so Ole Automation Procedures does not have to be turned on.
*     - You can filter the resutls in the select query (starting on line 149).
* 
**********************************************************************************************************/

SET NOCOUNT ON;

DECLARE @Database NVARCHAR(260);

IF (OBJECT_ID('tempdb..#FileInfo') IS NOT NULL)
	DROP TABLE #FileInfo;

CREATE TABLE #FileInfo
(
    [ID]                INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [Database]          NVARCHAR(260)     NOT NULL,
    [name]              SYSNAME           NOT NULL,
    [type_desc]         NVARCHAR(120)     NOT NULL,
    [size]              INT               NOT NULL,
    [Used_Pages]        INT               NOT NULL,
    [is_percent_growth] BIT               NOT NULL,
    [growth]            INT               NOT NULL,
    [max_size]          INT               NOT NULL,
    [physical_name]     NVARCHAR(520)     NOT NULL
);



------------------------------------------------------------------------------------------
--// GET FILE INFO                                                                    //--
------------------------------------------------------------------------------------------

DECLARE curDatabases CURSOR LOCAL FAST_FORWARD FOR
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
--// DISPLAY FILE INFO                                                                //--
------------------------------------------------------------------------------------------

SELECT
	/*1*/ [f].[Database],
	/*2*/ [File] = [f].[name],
	/*3*/ [f].[type_desc],
	/*4*/ [Size_MB] =	CASE
							WHEN LEN(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 8
								THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),9,0,','),6,0,','))
							WHEN LEN(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 5 
								THEN REVERSE(STUFF(REVERSE(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),6,0,','))
							ELSE CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))
						END,
	/*5*/ [Used_MB] =	CASE
							WHEN LEN(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 8 
								THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),9,0,','),6,0,','))
							WHEN LEN(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 5
								THEN REVERSE(STUFF(REVERSE(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),6,0,','))
							ELSE CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))
						END,
	/*6*/ [Free_MB] =	CASE
							WHEN LEN(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))) > 8 
								THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))),9,0,','),6,0,','))
							WHEN LEN(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))) > 5
								THEN REVERSE(STUFF(REVERSE(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))),6,0,','))
							ELSE CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))
						END,
	/*7*/ [% free] =	CASE 
							WHEN [f].[size] != 0 THEN CAST((CAST(([f].[size] - [f].[Used_Pages]) AS DECIMAL(10,1)) / CAST([f].[size] AS DECIMAL(10,1)) * 100) AS DECIMAL(4,1))
							ELSE 0.0
						END,
	/*8*/ [Autogrowth] =	CASE [f].[is_percent_growth]
								WHEN 0 THEN CAST(([f].[growth] / 128) AS VARCHAR(10)) + ' MB'
								WHEN 1 THEN CAST([f].[growth] AS VARCHAR(3)) + ' %'
							END,
	/*9*/ [max_size] =	CASE [f].[max_size]
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
    /*10*/ [Drive] = LEFT([f].[physical_name],3),
	/*11*/ [usp_FileGrowth @where] = 'sqlservername = ''''' + @@SERVERNAME + ''''' AND databasename = ''''' + [f].[Database] +''''' AND DatabaseFileName = ''''' + [f].[name] + ''''''
FROM 
	#FileInfo AS [f]
WHERE [f].[type_desc] <> 'FILESTREAM' 
	--AND /*File <10% free*/ CAST((CAST(([f].[size] - [f].[Used_Pages]) AS DECIMAL(10,1)) / CAST([f].[size] AS DECIMAL(10,1)) * 100) AS DECIMAL(4,1)) <= 10
	--AND [f].[type_desc] = 'LOG'
	--AND [f].[Database] = ''
	--AND [f].[name] = ''
ORDER BY 
    1, 2;  -- Database, File
    --7;  -- File_PctFree;
    
/*

ALTER DATABASE [] MODIFY FILE ( NAME = N'', SIZE = MB, FILEGROWTH = MB );



*/
------------------------------------------------------------------------------------------
--// CLEAN UP                                                                         //--
------------------------------------------------------------------------------------------

DROP TABLE #FileInfo;



