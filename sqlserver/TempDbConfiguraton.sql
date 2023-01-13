/**********************************************************************************************************
* 
* TempDbConfiguration.sql
* 
* Author: James Lutsey
* Date:   2018-08-21
* 
* Purpose: Configure file sizes of TempDB.
* 
**********************************************************************************************************/

SET NOCOUNT ON;

USE tempdb;

DECLARE @advanced               AS BIT
      , @Command                AS NVARCHAR(MAX)
      , @Database               AS NVARCHAR(260)
      , @DriveLetter            AS CHAR(1)
      , @DriveNameOut           AS INT
      , @FSO                    AS INT
      , @ole                    AS BIT
      , @Result                 AS INT
      , @TotalSizeOut           AS VARCHAR(20)
      
      , @DataFileQty            AS INT
      , @DriveMb                AS DECIMAL(17,6)
      , @FileMbSum              AS DECIMAL(17,6)
      , @DriveFreeMb            AS BIGINT
      
      , @availableMB            AS DECIMAL(17,6)
      , @newSize                AS INT
      
      , @sql                    AS NVARCHAR(MAX)
      , @msg                    AS NVARCHAR(MAX)
      , @i                      AS INT
      , @name                   AS NVARCHAR(128)
      , @directory              AS NVARCHAR(128)
      , @physicalName           AS NVARCHAR(512);

IF OBJECT_ID('tempdb..#FileInfo') IS NOT NULL
    DROP TABLE #FileInfo;
IF OBJECT_ID('tempdb..#DriveInfo') IS NOT NULL
    DROP TABLE #DriveInfo;

CREATE TABLE #FileInfo
(
      ID                INT IDENTITY(1,1) PRIMARY KEY
    , DatabaseName      NVARCHAR(260)
    , name              SYSNAME
    , type_desc         NVARCHAR(120)
    , size              INT
    , Used_Pages        INT
    , is_percent_growth BIT
    , growth            INT
    , max_size          INT
    , physical_name     NVARCHAR(520)
);

CREATE TABLE #DriveInfo
(
      Drive        CHAR(1) PRIMARY KEY
    , FreeSpace_MB BIGINT
);



------------------------------------------------------------------------------------------
--// GET OLE AUTOMATION PROCEDURES CONFIGURATION                                      //--
------------------------------------------------------------------------------------------

SELECT @advanced = CAST(value AS BIT)
FROM   sys.configurations
WHERE  name = N'show advanced options';

SELECT @ole = CAST(value AS BIT)
FROM   sys.configurations
WHERE  name = N'Ole Automation Procedures';

IF @ole = 0
BEGIN
    IF @advanced = 0
    BEGIN
        EXECUTE sys.sp_configure @configname  = 'show advanced options',
                                        @configvalue = 1;
        RECONFIGURE WITH OVERRIDE;
    END;
    
    EXECUTE sys.sp_configure @configname  = 'Ole Automation Procedures',
                                    @configvalue = 1;
    RECONFIGURE WITH OVERRIDE;
END;



------------------------------------------------------------------------------------------
--// SET THE CORRECT NUMBER OF DATA FILES                                             //--
------------------------------------------------------------------------------------------

-- check if all files are in the same directory
IF (SELECT COUNT(1) FROM (SELECT LEFT(physical_name,CHARINDEX(N'\',REVERSE(physical_name))) AS letter FROM #FileInfo GROUP BY LEFT(physical_name,CHARINDEX(N'\',REVERSE(physical_name)))) AS drives) > 1
BEGIN
    RAISERROR(N'Tempdb files are in multiple directories. Move all tempdb files into the same directory and rerun this script.',16,1) WITH NOWAIT;
    SET NOEXEC ON;
END;

-- get the number of data files
SELECT @DataFileQty = CASE 
                          WHEN cpu_count <= 4 THEN 4
                          WHEN cpu_count > 4 AND cpu_count <= 8 THEN cpu_count
                          ELSE 8
                      END
FROM   sys.dm_os_sys_info;

-- if more data files exist than we want, remove the extras
WHILE (SELECT COUNT(1) FROM sys.database_files WHERE type = 0) > @DataFileQty
BEGIN
    -- create the command
    SELECT   TOP(1) @sql = N'USE tempdb;'                                        + NCHAR(0x000D) + NCHAR(0x000A) +
                           N'DBCC SHRINKFILE([' + name + N'], EMPTYFILE);'       + NCHAR(0x000D) + NCHAR(0x000A) +
                           N'USE master;'                                        + NCHAR(0x000D) + NCHAR(0x000A) +
                           N'ALTER DATABASE tempdb REMOVE FILE [' + name + N'];'
    FROM     sys.database_files
    WHERE    type = 0
    ORDER BY file_id DESC;

    -- log and execute the command
    SET @msg = N'-----------------------------------------------------------------------------------------------------------------' + NCHAR(0x000D) + NCHAR(0x000A) + CONVERT(NCHAR(19),GETDATE(),120) + NCHAR(0x000D) + NCHAR(0x000A) + @sql;
    RAISERROR(@msg,0,1) WITH NOWAIT;
    EXECUTE sys.sp_executesql @statement = @sql;
END;

-- if less data files exist than we want, add some more
SET @i = 1;
SELECT TOP(1) @directory = LEFT(physical_name,LEN(physical_name) - CHARINDEX(N'\',REVERSE(physical_name)) + 1) FROM sys.database_files;

WHILE (SELECT COUNT(1) FROM sys.database_files WHERE type = 0) < @DataFileQty
BEGIN
    SET @i += 1;
    SET @name = N'temp' + CAST(@i AS NVARCHAR(11));
    SET @physicalName = @directory + N'tempdb_mssql_' + CAST(@i AS NVARCHAR(11)) + N'.ndf';
    
    -- find a unique name/phyisical_name
    WHILE EXISTS(SELECT 1 FROM sys.database_files WHERE name = @name) OR EXISTS(SELECT 1 FROM sys.database_files WHERE physical_name = @physicalName)
    BEGIN
        SET @i += 1;
        SET @name = N'temp' + CAST(@i AS NVARCHAR(11));
        SET @physicalName = @directory + N'tempdb_mssql_' + CAST(@i AS NVARCHAR(11)) + N'.ndf';
    END;

    -- create, log, and execute the command
    SET @sql = N'ALTER DATABASE tempdb ADD FILE ( NAME = N''' + @name + N''', FILENAME = N''' + @physicalName + N''', SIZE = 1024MB, MAXSIZE = UNLIMITED, FILEGROWTH = 64 MB );';
    SET @msg = CONVERT(NCHAR(19),GETDATE(),120) + N' | ' + @sql;
    RAISERROR(@msg,0,1) WITH NOWAIT;
    EXECUTE sys.sp_executesql @statement = @sql;
END;


------------------------------------------------------------------------------------------
--// GET FILE INFO                                                                    //--
------------------------------------------------------------------------------------------

INSERT INTO #FileInfo
(
       DatabaseName
     , name
     , type_desc
     , size
     , Used_Pages
     , is_percent_growth
     , growth
     , max_size
     , physical_name
)
SELECT DB_NAME()
     , name
     , type_desc
     , size
     , FILEPROPERTY(name, 'SpaceUsed')
     , is_percent_growth
     , growth
     , max_size
     , physical_name
FROM   sys.database_files;



------------------------------------------------------------------------------------------
--// GET DRIVE SPACE INFO                                                             //--
------------------------------------------------------------------------------------------

INSERT #DriveInfo ([Drive],[FreeSpace_MB]) 
EXEC master.dbo.xp_fixeddrives;

SELECT TOP(1) @DriveLetter = LEFT(physical_name,1)
FROM          #FileInfo
GROUP BY      LEFT(physical_name,1);

EXECUTE @Result = sys.sp_OACreate 'Scripting.FileSystemObject'
                                , @FSO OUT; 
                   
IF @Result <> 0 
    EXECUTE sys.sp_OAGetErrorInfo @FSO;

EXECUTE @Result = sys.sp_OAMethod @FSO
                                , 'GetDrive'
                                , @DriveNameOut OUT
                                , @DriveLetter;

IF @Result <> 0 
    EXECUTE sys.sp_OAGetErrorInfo @FSO;
    
EXECUTE @Result = sys.sp_OAGetProperty @DriveNameOut
                                     , 'TotalSize'
                                     , @TotalSizeOut OUT;
             
IF @Result <> 0 
    EXECUTE sys.sp_OAGetErrorInfo @DriveNameOut; 

EXECUTE @Result = sys.sp_OADestroy @FSO; 

IF @Result <> 0 
    EXECUTE sys.sp_OAGetErrorInfo @FSO;



------------------------------------------------------------------------------------------
--// CALCULATE                                                                        //--
------------------------------------------------------------------------------------------

-- get the current metrics to figure out how much space is available to use
SET @DriveMb = CAST(@TotalSizeOut AS BIGINT) / 1048576.0;

SELECT @DriveFreeMb = FreeSpace_MB
FROM   #DriveInfo
WHERE  Drive = @DriveLetter;

SELECT @FileMbSum = SUM((size / 128.0) - (Used_Pages / 128.0))
FROM   #FileInfo;

-- do the math
SET @availableMB = (@FileMbSum + @DriveFreeMb) * 0.899;
SET @newSize     = CAST(FLOOR(@availableMB / (@DataFileQty + 1)) AS INT);



------------------------------------------------------------------------------------------
--// SHRINK ANY FILES ARE TOO LARGE                                                   //--
------------------------------------------------------------------------------------------

IF EXISTS(SELECT 1 FROM sys.database_files WHERE  size/128.0 > @newSize)
BEGIN
    -- create the commands
    SET @sql = N'';
    SELECT @sql += N'USE tempdb;'                         + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'DBCC SHRINKFILE([' + name + N'],0);' + NCHAR(0x000D) + NCHAR(0x000A)
    FROM   sys.database_files
    WHERE  size/128.0 > @newSize;

    -- log and execute the commands
    SET @msg = N'-----------------------------------------------------------------------------------------------------------------' + NCHAR(0x000D) + NCHAR(0x000A) + CONVERT(NCHAR(19),GETDATE(),120) + NCHAR(0x000D) + NCHAR(0x000A) + @sql;
    RAISERROR(@msg,0,1) WITH NOWAIT;
    EXECUTE sys.sp_executesql @statement = @sql;
END;



------------------------------------------------------------------------------------------
--// SET THE NEW CONFIGURATIONS                                                       //--
------------------------------------------------------------------------------------------

-- grow files that are too small
IF EXISTS(SELECT 1 FROM sys.database_files WHERE  size/128.0 < @newSize)
BEGIN
    -- create the commands
    SET @sql = N'';
    SELECT @sql += N'USE master;'                                                                                                        + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'ALTER DATABASE tempdb MODIFY FILE ( NAME = N''' + name + N''', SIZE = ' + CAST(@newSize AS NVARCHAR(11)) + N'MB );' + NCHAR(0x000D) + NCHAR(0x000A)
    FROM   sys.database_files
    WHERE  size/128.0 < @newSize;

    -- log and execute the commands
    SET @msg = N'-----------------------------------------------------------------------------------------------------------------' + NCHAR(0x000D) + NCHAR(0x000A) + CONVERT(NCHAR(19),GETDATE(),120) + NCHAR(0x000D) + NCHAR(0x000A) + @sql;
    RAISERROR(@msg,0,1) WITH NOWAIT;
    EXECUTE sys.sp_executesql @statement = @sql;
END;

-- set the growth and maxsize for all files
SET @sql = N'';
SELECT @sql += N'USE master;'                                                                                               + NCHAR(0x000D) + NCHAR(0x000A) +
               N'ALTER DATABASE tempdb MODIFY FILE ( NAME = N''' + name + N''', FILEGROWTH = 128MB, MAXSIZE = UNLIMITED );' + NCHAR(0x000D) + NCHAR(0x000A)
FROM   sys.database_files;

-- log and execute the commands
SET @msg = N'-----------------------------------------------------------------------------------------------------------------' + NCHAR(0x000D) + NCHAR(0x000A) + CONVERT(NCHAR(19),GETDATE(),120) + NCHAR(0x000D) + NCHAR(0x000A) + @sql;
RAISERROR(@msg,0,1) WITH NOWAIT;
EXECUTE sys.sp_executesql @statement = @sql;



------------------------------------------------------------------------------------------
--// CLEAN UP                                                                         //--
------------------------------------------------------------------------------------------

IF @ole = 0
BEGIN
    EXECUTE sys.sp_configure @configname  = 'Ole Automation Procedures',
                                          @configvalue = 0;
    RECONFIGURE WITH OVERRIDE;

    IF @advanced = 0
    BEGIN
        EXECUTE sys.sp_configure @configname  = 'show advanced options',
                                                @configvalue = 0;
        RECONFIGURE WITH OVERRIDE;
    END;
END;

DROP TABLE #FileInfo;
DROP TABLE #DriveInfo;

SET NOEXEC OFF;
