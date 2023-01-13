/**************************************************************************************
*
* Author: James Lutsey
* Date: 02/24/2016
* 
* Purpose: Caclulates average file growth for all files on a drive. 
* 
* Notes: 1. Connect and run on Central Admin server
*        2. Enter the server and drive 
*
* Date        Person            Change
* ----------  ----------------  -------------------------------------------------------
* 2017-10-06  James Lutsey      Expanded calculations for increasing file sizes, build
*                               the sql commands, check the drive space and make
*                               reccomendations if drive needs to be grown, display
*                               history to review for "fast" growing files.
*
* 2018-01-24  James Lutsey      Check if chosen size equals current size --> do not add grow command
* 
**************************************************************************************/

IF LOWER(@@SERVERNAME) <> 'gcc-sql-pd-001'
BEGIN
    RAISERROR('Wrong server - connect to gcc-sql-pd-001',16,1);
    RETURN;
END

USE [CentralAdmin];

-- USER INPUT
DECLARE @server VARCHAR(128) = 'CO-DB-078',
        @drive  CHAR(1)      = 'F';

-- OTHER VARIABLES
DECLARE @aveDailyGrowth   DECIMAL(25,1),
	    @database         VARCHAR(128),
    	@driveAction      NVARCHAR(500),
        @driveAvailable   INT,
        @driveCapacity    INT,
        @driveFilesSpace  INT,
        @driveFreeSpace   INT,
        @driveSelectedSize INT,
        @file			  VARCHAR(128),
        @fileSizesGrowth  INT,
        @fileSizesSize    INT,
        @sql NVARCHAR(MAX),
        @fileType         NVARCHAR(60),
	    @firstDate		DATETIME,
	    @firstUsed		DECIMAL(37,13),
        @growth         INT = 4,
        @increase       INT,
        @lastDate		DATETIME,
	    @lastSize		DECIMAL(37,13),
	    @lastUsed		DECIMAL(37,13),
        @message        VARCHAR(500),
        @nl              NVARCHAR(10) = CHAR(13) + CHAR(10),
        @projectedSize5  INT,
        @projectedSize6  INT,
        @totalIncrease   INT,
        @totalSize6      INT,
        @chosenSize     INT,
        @chosenGrowth   INT,
        @sqlGrowFile            NVARCHAR(500);


------------------------------------------------------------------------------------------
--// VALIDATE USER INPUTS                                                             //--
------------------------------------------------------------------------------------------

-- check if the user entered a server
IF @server = ''
BEGIN
    SET @message = 'You must enter a server. (line 39)';
    RAISERROR(@message,16,1);
    RETURN;
END

-- check if the user entered a drive
IF @drive = ''
BEGIN
    SET @message = 'You must enter a drive. (line 40)';
    RAISERROR(@message,16,1);
    RETURN;
END

-- check if the server is here
IF (NOT EXISTS(SELECT [SqlServerName] FROM [CentralAdmin].[dbo].[DatabaseSpaceUsedhistory] WHERE [SqlServerName] = @server))
BEGIN
    SET @message = 'Invalid server.' + CHAR(13) + CHAR(10);
    SET @message = @message + 'The specified server, [' + @server + '], is not in this table. (line 39)';
    RAISERROR(@message,16,1);
    RETURN;
END

-- check if the drive is here
IF (NOT EXISTS(SELECT [FilePath] FROM [CentralAdmin].[dbo].[DatabaseSpaceUsedhistory] WHERE [SqlServerName] = @server AND LEFT([FilePath],1) = @drive))
BEGIN
    SET @message = 'Invalid drive.' + CHAR(13) + CHAR(10);
    SET @message = @message + 'The specified drive, ''' + @server + ''', for this server is not in this table. (line 40)';
    RAISERROR(@message,16,1);
    RETURN;
END


------------------------------------------------------------------------------------------
--// CREATE TEMP TABLES                                                               //--
------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#DriveInfo',N'U') IS NOT NULL DROP TABLE #DriveInfo;
CREATE TABLE #DriveInfo
(
    [Drive]			CHAR(1) PRIMARY KEY, 
    [FreeSpace_MB]	BIGINT,
    [Capacity_MB]	BIGINT
);

IF OBJECT_ID('tempdb..#DriveSizes',N'U') IS NOT NULL DROP TABLE #DriveSizes;
CREATE TABLE #DriveSizes
(
    [GB] INT NOT NULL PRIMARY KEY
);

IF OBJECT_ID('tempdb..#FileInfo',N'U') IS NOT NULL DROP TABLE #FileInfo;
CREATE TABLE #FileInfo
(
    [ID]				INT IDENTITY(1,1) PRIMARY KEY,
    [Server]			VARCHAR(256),
    [Database]			VARCHAR(255),
    [File]				VARCHAR(256),
    [Drive]             VARCHAR(3),
    [TypeDesc]          NVARCHAR(60),
    [EntryDate]			DATETIME,
    [Size_MB]			DECIMAL(37,13),
    [Used_MB]           DECIMAL(37,13),
    [AveDailyGrowth]    DECIMAL(37,13)
);

IF OBJECT_ID('tempdb..#FileSizes',N'U') IS NOT NULL DROP TABLE #FileSizes;
CREATE TABLE #FileSizes
(
    [SizeMB]   INT PRIMARY KEY,
    [GrowthMB] INT
);

IF OBJECT_ID('tempdb..#GrowthInfo',N'U') IS NOT NULL DROP TABLE #GrowthInfo;
CREATE TABLE #GrowthInfo
(
    [ID]                    INT IDENTITY(1,1) PRIMARY KEY,
    [Server]                VARCHAR(256),
    [Drive]                 CHAR(1),
    [Database]              VARCHAR(255),
    [File]                  VARCHAR(256),
    [TypeDesc]              NVARCHAR(60),
    [Size_MB]               DECIMAL(25,1),
    [Used_MB]               DECIMAL(25,1),
    [AveDailyGrowth_MB]     DECIMAL(25,1),
    [6_Months_MB_projected] INT,
    [6_Months_MB_choice]    INT,
    [Increase_MB]           INT,
    [GrowFileCommand]           NVARCHAR(500)
);


------------------------------------------------------------------------------------------
--// CURSORS                                                                          //--
------------------------------------------------------------------------------------------

DECLARE curFileHistories CURSOR LOCAL FAST_FORWARD FOR
    SELECT [Database],
           [File]
    FROM   #GrowthInfo
    WHERE  [Increase_MB] > 915 -- more than 5 mb per day
           OR [AveDailyGrowth_MB] > ([Size_MB] * 100 / 183); -- will more than double in size in 6 months

DECLARE curFiles CURSOR FAST_FORWARD FOR
    SELECT DISTINCT [DatabaseName], [DatabaseFileName], [FileType]
    FROM            [CentralAdmin].[dbo].[DatabaseSpaceUsed]
    WHERE           [SqlServerName] = @server AND LEFT([FilePath],1) = @drive;


------------------------------------------------------------------------------------------
--// POPULATE #FileSizes & #DriveSizes WITH STANDARD SIZES                            //--
------------------------------------------------------------------------------------------

-- #FileSizes
SET @fileSizesGrowth = 4;
SET @fileSizesSize = 4;
SET @sql = N'INSERT INTO #FileSizes ([SizeMB], [GrowthMB])' + CHAR(13) + CHAR(10) + 'VALUES ';

WHILE @fileSizesSize < 1048576 -- 1048576 MB = 1 TB
BEGIN
    SET @sql = @sql + N'(' + CAST(@fileSizesSize AS NVARCHAR(7)) + N',' + CAST(@fileSizesGrowth AS NVARCHAR(7)) + '),';
    SET @fileSizesSize = @fileSizesSize + @fileSizesGrowth;
    
    IF @fileSizesSize IN (32, 64, 128, 256, 512, 1024, 2048, 4096, 8192)
    BEGIN
        SET @fileSizesGrowth = @fileSizesGrowth * 2;
        SET @sql = @sql + CHAR(13) + CHAR(10) + '       ';
    END
END 

SET @sql = @sql + N'(' + CAST(@fileSizesSize AS NVARCHAR(7)) + N',' + CAST(@fileSizesGrowth AS NVARCHAR(7)) + ');'

EXECUTE(@sql);

-- #DriveSizes
INSERT INTO #DriveSizes ([GB]) VALUES (25),(50),(75),(100),(150),(200),(250),(300),(350),(400),(500),(600),(700),(800),(900),(1000),
                                      (1100),(1200),(1300),(1400),(1500),(1600),(1700),(1800),(1900),(2000),
                                      (2100),(2200),(2300),(2400),(2500),(2600),(2700),(2800),(2900),(3000),
                                      (3100),(3200),(3300),(3400),(3500),(3600),(3700),(3800),(3900),(4000),
                                      (4100),(4200),(4300),(4400),(4500),(4600),(4700),(4800),(4900),(5000);



------------------------------------------------------------------------------------------
--// GET THE FILE INFO                                                                //--
------------------------------------------------------------------------------------------

INSERT INTO #FileInfo ([Server], [Database], [File], [Drive], [TypeDesc], [EntryDate], [Size_MB], [Used_MB])
SELECT 
    [SqlServerName],
    [DatabaseName],
    [DatabaseFileName],
    LEFT([DriveLetter],1),
    [FileType],
    [EntryDate],
    [FileSizeMb],
    [FileSpaceUsedMb]
FROM   
    [CentralAdmin].[dbo].[DatabaseSpaceUsedhistory]
WHERE 
    [SqlServerName] = @server 
    AND LEFT([FilePath],1) = @drive
UNION
SELECT 
    [SqlServerName],
    [DatabaseName],
    [DatabaseFileName],
    LEFT([DriveLetter],1),
    [FileType],
    [EntryDate],
    [FileSizeMb],
    [FileSpaceUsedMb]
FROM   
    [CentralAdmin].[dbo].[DatabaseSpaceUsed]
WHERE 
    [SqlServerName] = @server 
    AND LEFT([FilePath],1) = @drive
ORDER BY  
    [EntryDate] DESC



------------------------------------------------------------------------------------------
--// CALCULATE THE AVERAGE DAILY GROWTH FOR THE TIMESPAN OF THE RECORDS               //--
------------------------------------------------------------------------------------------

OPEN curFiles;
    FETCH NEXT FROM curFiles INTO @database, @file, @fileType;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- get the first date and used size
        SELECT TOP 1 @firstDate = [EntryDate],
                     @firstUsed = [Used_MB]
        FROM         #FileInfo
        WHERE        [Database] = @database
                     AND [File] = @file
        ORDER BY     [EntryDate] ASC;

        -- get the last date and used size
        SELECT TOP 1 @lastDate = [EntryDate],
                     @lastUsed = [Used_MB],
                     @lastSize = [Size_MB]
        FROM         #FileInfo
        WHERE        [Database] = @database
                     AND [File] = @file
        ORDER BY     [EntryDate] DESC;

        -- do the math
        SET @aveDailyGrowth = ROUND((@firstUsed - @lastUsed) / DATEDIFF(SECOND, @lastDate, @firstDate) * 86400, 1);
        
        -- used size + daily growth for 180 days + 10% free space
        SET @projectedSize5 = (@lastUsed + @aveDailyGrowth * 152) / 0.9;
        SET @projectedSize6 = (@lastUsed + @aveDailyGrowth * 183) / 0.9;

        -- choose the bigger one
        IF @projectedSize6 >= @lastSize 
        BEGIN 
            -- choose the largest standard size between the 3-6 month sizes
            IF EXISTS(SELECT [SizeMB] FROM #FileSizes WHERE [SizeMB] >= @projectedSize5 AND [SizeMB] <= @projectedSize6)
                SELECT TOP 1 @chosenSize = [SizeMB], @chosenGrowth = [GrowthMB]
                FROM #FileSizes
                WHERE [SizeMB] <= @projectedSize6
                ORDER BY [SizeMB] DESC;
            ELSE  -- no standard size between the 3-6 month sizes, so use the next standard size greater than the 6 month size
                SELECT TOP 1 @chosenSize = [SizeMB], @chosenGrowth = [GrowthMB]
                FROM #FileSizes
                WHERE [SizeMB] > @projectedSize6
                ORDER BY [SizeMB] ASC;

            
            IF @chosenSize <> @lastSize
            BEGIN
                SET @increase = CAST(ROUND(@projectedSize6 - @lastSize,0) AS INT);
                SET @sqlGrowFile = N'ALTER DATABASE [' + @database + N'] MODIFY FILE ( NAME = N''' + @file + N''', SIZE = ' + CAST(@chosenSize AS NVARCHAR(10)) + N'MB, FILEGROWTH = ' + CAST(@chosenGrowth AS NVARCHAR(10)) + N'MB );';
            END;
            ELSE
            BEGIN
                SET @increase = 0;
                SET @sqlGrowFile = N'-- The file is equal to the chosen size';
            END;
        END;
        ELSE 
        BEGIN
            SET @chosenSize = @lastSize;
            SET @increase = 0;
            SET @sqlGrowFile = N'-- The file is large enough for 6 months of growth';
        END;

        INSERT INTO #GrowthInfo ([Server], [Drive], [Database], [File], [TypeDesc], [Size_MB], [Used_MB], [AveDailyGrowth_MB], [6_Months_MB_projected], [6_Months_MB_choice], [Increase_MB], [GrowFileCommand])
        VALUES (@server, @drive, @database, @file, @fileType, CAST(ROUND(@lastSize,1) AS DECIMAL(25,1)), CAST(ROUND(@lastUsed,1) AS DECIMAL(25,1)), @aveDailyGrowth, @projectedSize6, @chosenSize, @increase, @sqlGrowFile);

        FETCH NEXT FROM curFiles INTO @database, @file, @fileType;
    END
CLOSE curFiles;
DEALLOCATE curFiles;



------------------------------------------------------------------------------------------
--// DRIVE CALCULATIONS                                                               //--
------------------------------------------------------------------------------------------

SELECT @totalIncrease   = SUM([Increase_MB]),
       @totalSize6      = SUM([6_Months_MB_choice]),
       @driveFilesSpace = SUM([Size_MB])
FROM   #GrowthInfo;

SELECT @driveCapacity  = CAST(ROUND([total_size],0) AS INT),
       @driveFreeSpace = CAST(ROUND([free_space],0) AS INT)
FROM   [dbo].[SqlServerDriveSpaceused]
WHERE  [SqlServerName] = @server
       AND [drive_name] = @drive;

SET @driveAvailable = @driveFilesSpace + @driveFreeSpace;

IF @totalIncrease = 0
BEGIN
    SET @driveAction = N'0 - Nothing...all files have enough room for 6 months';
    SET @sql = N'';
END;
ELSE IF @totalSize6 <= (@driveAvailable - (@driveCapacity * 0.1))
BEGIN
    SET @driveAction = N'1 - Grow files...the drive is large enough for 6 months of growth.';
    SET @sql = N'IF UPPER(@@SERVERNAME) != N''' + UPPER(@server) + N''''     + @nl +
               N'BEGIN'                                               + @nl +
               N'    RAISERROR(N''Wrong server.'',16,1) WITH NOWAIT;' + @nl +
               N'    SET NOEXEC ON;'                                  + @nl +
               N'END;'                                                + @nl + @nl +
               N'USE [master];'                                       + @nl + @nl;
    SELECT @sql += [GrowFileCommand] + @nl
    FROM   #GrowthInfo
    WHERE  [Increase_MB] != 0;
END;
ELSE IF @totalSize6 <= @driveAvailable
BEGIN
    SET @driveAction = N'2 - Grow files, then grow drive...enough room, but will be low on free space.';
    SET @sql = N'IF UPPER(@@SERVERNAME) != N''' + UPPER(@server) + N''''     + @nl +
               N'BEGIN'                                               + @nl +
               N'    RAISERROR(N''Wrong server.'',16,1) WITH NOWAIT;' + @nl +
               N'    SET NOEXEC ON;'                                  + @nl +
               N'END;'                                                + @nl + @nl +
               N'USE [master];'                                       + @nl + @nl;
    SELECT @sql += [GrowFileCommand] + @nl
    FROM   #GrowthInfo
    WHERE  [Increase_MB] != 0;
END;
ELSE
BEGIN
    SET @driveAction = N'3 - Grow drive, then grow files...not enough room.';
    SET @sql = N'';
END;


------------------------------------------------------------------------------------------
--// DISPLAY THE RESULTS                                                              //--
------------------------------------------------------------------------------------------

-- results for drive
SELECT [Server] = [SqlServerName],
       [Drive]  = [drive_name] + N':\',
       [Capacity] = CAST(CAST(ROUND([total_size] / 1024.0, 0) AS INT) AS NVARCHAR(10)) + N' GB',
       [FreeSpace] = CAST(CAST(ROUND([free_space] / 1024.0,2) AS DECIMAL(25,2)) AS NVARCHAR(25)) + N' GB',
       [TotalIncrease] = CAST(CAST(ROUND(@totalIncrease / 1024.0, 2) AS DECIMAL(25,2)) AS NVARCHAR(25)) + N' GB',
       [Action] = @driveAction,
       [SqlGrowFiles] = @sql
FROM   [dbo].[SqlServerDriveSpaceused]
WHERE  [SqlServerName] = @server
       AND [drive_name] = @drive;

-- info to be entered in the change request
IF LEFT(@driveAction,1) IN (N'2',N'3')
BEGIN
    SELECT TOP 1 @driveSelectedSize = [GB]
    FROM         #DriveSizes
    WHERE        [GB] > ((@totalSize6 + @driveCapacity - @driveAvailable) / 1024.0 / 0.9)
    ORDER BY     [GB];
    
    SELECT [CHG Field] = N'Affected CI', 
           [Entry]     = N'MSSQLSERVER@' + UPPER(@server)
    UNION ALL
    SELECT [CHG Field] = N'Short description', 
           [Entry]     = N'Grow Database Server Drive - ' + UPPER(@server) + N' ' + UPPER(@drive) + N':\'
    UNION ALL
    SELECT [CHG Field] = N'Description', 
           [Entry]     = LOWER(@server) + N' - ' + UPPER(@drive) + 
                         N':\ - Add ' + CAST(@driveSelectedSize - CAST(ROUND(@driveCapacity / 1024.0, 0) AS INT) AS NVARCHAR(10)) + 
                         N' GB......(currently at ' + CAST(CAST(ROUND(@driveCapacity / 1024.0, 0) AS INT) AS NVARCHAR(10)) + 
                         N' GB, target is ' + CAST(@driveSelectedSize AS NVARCHAR(10)) + N' GB)';
END;

-- results for each file
SELECT   [Server],
         [Drive],
         [Database],
         [File],
         [TypeDesc],
         [Size_MB],
         [Used_MB],
         [AveDailyGrowth_MB],
         [6_Months_MB_projected],
         [6_Months_MB_choice],
         [Increase_MB],
         [GrowFileCommand]
FROM     #GrowthInfo
ORDER BY [TypeDesc] DESC,
         [Database],
         [File];

-- show growth history for files with large increases
OPEN curFileHistories;
    FETCH NEXT FROM curFileHistories INTO @database, @file;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXECUTE [CentralAdmin].[dbo].[usp_FileGrowth] @server   = @server,
                                                      @database = @database,
                                                      @file     = @file,
                                                      @action   = 2;
        
        FETCH NEXT FROM curFileHistories INTO @database, @file;
    END;
CLOSE curFileHistories;
DEALLOCATE curFileHistories;


------------------------------------------------------------------------------------------
--// CLEAN UP                                                                         //--
------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#DriveInfo',N'U')  IS NOT NULL DROP TABLE #DriveInfo;
IF OBJECT_ID('tempdb..#DriveSizes',N'U') IS NOT NULL DROP TABLE #DriveSizes;
IF OBJECT_ID('tempdb..#FileInfo',N'U')   IS NOT NULL DROP TABLE #FileInfo;
IF OBJECT_ID('tempdb..#FileSizes',N'U')  IS NOT NULL DROP TABLE #FileSizes;
IF OBJECT_ID('tempdb..#GrowthInfo',N'U') IS NOT NULL DROP TABLE #GrowthInfo;

