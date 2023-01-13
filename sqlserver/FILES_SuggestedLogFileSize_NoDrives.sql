/**********************************************************************************************
* 
* FILES_SuggestedLogFileSize_NoDrives.sql
* 
* Author: James Lutsey
* Date: 2017-02-14
* 
* Purpose: Find log files that are less than twice the size of the largest index or at least 20% of data file size
* 
* Note: Does not show any info on drive space, so Ole Automation Procedures does not have to be turned on.
* 
**********************************************************************************************/

SET NOCOUNT ON;

DECLARE 
	@db           NVARCHAR(128),
	@filegrowth   INT,
    @size         INT,
    @sql          NVARCHAR(MAX),
	@Result       INT,
    @FSO          INT,
    @DriveLetter  CHAR(1),
    @DriveNameOut INT,
    @TotalSizeOut VARCHAR(20),
    @MB           NUMERIC = 1048576;

DECLARE curDBs CURSOR LOCAL FAST_FORWARD FOR
	SELECT [name] FROM sys.databases WHERE [state] = 0 AND [name] NOT IN ('master','model','msdb','tempdb');

-- temp table to hold info about each log file
IF OBJECT_ID('tempdb..#LogFiles','U') IS NOT NULL DROP TABLE #LogFiles;
CREATE TABLE #LogFiles
(
	[DatabaseName]        NVARCHAR(128) PRIMARY KEY,
	[DataFilesSize_MB]    INT,
	[LargestIndex_MB]     INT,
	[LogFileSize_MB]      INT,
	[SuggestedMinSize_MB] INT,
	[Drive]               CHAR(1),
	[GrowFile]            NVARCHAR(400)
);

-- temp table to hold the standard sizes and filegrowths
IF OBJECT_ID('tempdb..#FileSizes','U') IS NOT NULL DROP TABLE #FileSizes;
CREATE TABLE #FileSizes
(
    [SizeMB]   INT PRIMARY KEY,
    [GrowthMB] INT
);


------------------------------------------------------------------------------------------
--// POPULATE #FileSizes WITH STANDARD FILE AND GROWTH SIZES                          //--
------------------------------------------------------------------------------------------

SET @filegrowth = 4;
SET @size = 4;
SET @sql = N'INSERT INTO #FileSizes ([SizeMB], [GrowthMB])' + CHAR(13) + CHAR(10) + 'VALUES ';

WHILE @size < 1048576
BEGIN
    SET @sql = @sql + N'(' + CAST(@size AS NVARCHAR(7)) + N',' + CAST(@filegrowth AS NVARCHAR(7)) + '),';
    SET @size = @size + @filegrowth;
    
    IF (@size = 72) OR (@size = 144) OR (@size = 288) OR (@size = 576) OR (@size = 1152) OR (@size = 2304) OR (@size = 4608) OR (@size = 9216) OR (@size = 22528)
    BEGIN
        SET @filegrowth = @filegrowth * 2;
        SET @sql = @sql + CHAR(13) + CHAR(10) + '       ';
    END
END 

SET @sql = @sql + N'(' + CAST(@size AS NVARCHAR(7)) + N',' + CAST(@filegrowth AS NVARCHAR(7)) + ');'

EXECUTE(@sql);


------------------------------------------------------------------------------------------
--// POPULATE #LogFiles WITH INFO FOR EACH LOG FILE                                   //--
------------------------------------------------------------------------------------------

OPEN curDBs;
	FETCH NEXT FROM curDBs INTO @db;

	WHILE @@FETCH_STATUS = 0
	BEGIN
        EXECUTE('
USE [' + @db + '];

DECLARE
	@dataFilesSize_MB    INT,
	@largestIndex_MB     INT,
	@logFileSize_MB      INT,
	@logFileName         NVARCHAR(128),
	@growFileCmd         NVARCHAR(400),
	@selectedSize        INT,
	@selectedFilegrowth  INT,
	@selectedDrive       CHAR(1),
	@selectedFreeSpace   INT,
	@selectedCapacity    INT,
    @sizeChoice          INT;

SELECT @dataFilesSize_MB = SUM(CAST(ROUND([size] / 128.0, 0) AS INT))
FROM [sys].[database_files]
WHERE [type] = 0;

SELECT 
	@logFileSize_MB = CAST(ROUND([size] / 128.0, 0) AS INT),
	@logFileName    = [name],
	@selectedDrive  = LEFT([physical_name],1)
FROM [sys].[database_files]
WHERE [type] = 1;

SELECT TOP 1
	@largestIndex_MB = CAST(ROUND(SUM([a].[used_pages]) / 128.0,0) AS INT)
FROM 
	[sys].[indexes] AS [i]
JOIN 
	sys.partitions AS p 
	ON [p].[object_id] = [i].[object_id] 
	AND [p].[index_id] = [i].[index_id]
JOIN 
	[sys].[allocation_units] AS [a] 
	ON [a].[container_id] = [p].[partition_id]
GROUP BY 
	[i].[object_id],
	[i].[index_id],
	[i].[name]
ORDER BY
    1 DESC;
        
IF (@largestIndex_MB * 2) > @dataFilesSize_MB * 0.2
    -- if larger indexes, set size for twice largest index size
    SELECT @selectedSize = MIN([SizeMB]) FROM #FileSizes WHERE [SizeMB] >= (@largestIndex_MB * 2);
ELSE 
    -- if only small indexes, set size for 20% of data file size
    SELECT @selectedSize = MIN([SizeMB]) FROM #FileSizes WHERE [SizeMB] >= (@dataFilesSize_MB * 0.2);
    
IF @logFileSize_MB < @selectedSize
BEGIN
	SELECT @selectedFilegrowth = [GrowthMB] FROM #FileSizes WHERE [SizeMB] = @selectedSize;

	SET @growFileCmd = ''USE [master]; ALTER DATABASE '' + QUOTENAME(DB_NAME()) + '' MODIFY FILE ( NAME = N'''''' + @logFileName + '''''', ' + 
																								   'SIZE = '' + CAST(@selectedSize AS NVARCHAR(25)) + ''MB, ' +
																								   'FILEGROWTH = '' + CAST(@selectedFilegrowth AS NVARCHAR(25)) + '' );'';
END
ELSE
	SET @growFileCmd = ''-- size is okay for log file on ['' + DB_NAME() + '']'';

INSERT INTO #LogFiles ([DatabaseName],[DataFilesSize_MB],[LargestIndex_MB],[LogFileSize_MB],[SuggestedMinSize_MB],[Drive],[GrowFile])
VALUES (DB_NAME(),@dataFilesSize_MB,@largestIndex_MB,@logFileSize_MB,@selectedSize,@selectedDrive,@growFileCmd)
');

		FETCH NEXT FROM curDBs INTO @db;
	END
CLOSE curDBs;
DEALLOCATE curDBs;


------------------------------------------------------------------------------------------
--// DISPLAY RESUTLS                                                                  //--
------------------------------------------------------------------------------------------

SELECT * FROM #LogFiles;
--SELECT * FROM #LogFiles WHERE [GrowFile] = '-- there is not enough drive space to grow the file to the reccomended size';
--SELECT * FROM #LogFiles WHERE [GrowFile] NOT LIKE '--%';
--SELECT * FROM #LogFiles WHERE [GrowFile] LIKE '-- size is okay for log file on%';
--SELECT * FROM #LogFiles WHERE [GrowFile] NOT LIKE '-- size is okay for log file on%';

SELECT  
    SUM([LogFileSize_MB]) AS [SumCurrentLogFiles_MB],
    SUM(CASE
            WHEN [LogFileSize_MB] > [SuggestedMinSize_MB] THEN [LogFileSize_MB]
            ELSE [SuggestedMinSize_MB]
        END) AS [SumSuggestedLogFiles_MB],
    [Drive]
FROM 
    #LogFiles
GROUP BY
    [Drive];


------------------------------------------------------------------------------------------
--// CLEAN UP                                                                         //--
------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#LogFiles','U')  IS NOT NULL DROP TABLE #LogFiles;
IF OBJECT_ID('tempdb..#FileSizes','U') IS NOT NULL DROP TABLE #FileSizes;

