/*********************************************************************************************************************
* 
* FILES_GrowFileIncrementally.sql
* 
* Author: James Lutsey
* Date: 07/22/2016
* 
* Purpose: Grow file incrementally to avoid long waits from locking
*
* Note: Enter the database name, file name, and increment amount (default is 2 GB)
* 
* Date        Name                  Description of change
* ----------  --------------------  ---------------------------------------------------------------------------------
* 2018-07-26  James Lutsey          Add loop to automate continuous executions until target size is reached
* 
* 
*********************************************************************************************************************/

SET NOCOUNT ON;

	

------------------------------------------------------------------------------------------
--// USE INPUT                                                                        //--
------------------------------------------------------------------------------------------

DECLARE @database   NVARCHAR(128) = 'TrendDSM', -- select db_name(database_id), name from sys.master_files order by 1,2
        @file       NVARCHAR(128) = 'TrendDSM',
        @sizeTarget INT          = 118784,  -- MB final size of file
        @increment  INT          = 2048, 
    
        -- variables NOT initialized by user
        @msg         NVARCHAR(MAX),
        @filegrowth  INT,
        @size        INT,
        @sizeCurrent INT,
        @sql         NVARCHAR(MAX);

-- verify user input
IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE name = @database)
BEGIN
    SET @msg = 'The database [' + @database + '] does not exist.';
    RAISERROR(@msg,16,1);
    RETURN;
END;

IF NOT EXISTS(SELECT 1 FROM sys.master_files WHERE DB_NAME(database_id) = @database AND name = @file)
BEGIN
    SET @msg = 'The file [' + @file + '] does not exist for database [' + @database + '].';
    RAISERROR(@msg,16,1);
    RETURN;
END;

IF @sizeTarget = 0
BEGIN
    RAISERROR('You did not set @sizeTarget.',16,1);
    RETURN;
END;

	

------------------------------------------------------------------------------------------
--// POPULATE #FileSizes WITH STANDARD FILE AND GROWTH SIZES                          //--
------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#FileSizes') IS NOT NULL DROP TABLE #FileSizes;
CREATE TABLE #FileSizes
(
    [SizeMB]   INT PRIMARY KEY,
    [GrowthMB] INT
);

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

EXECUTE sys.sp_executesql @statement = @sql;


------------------------------------------------------------------------------------------
--// GET THE SIZE AND FILEGROWTH                                                      //--
------------------------------------------------------------------------------------------

-- starting
SELECT @msg = CONVERT(NCHAR(19),GETDATE(),120) + N' | Starting | Target: ' + CAST(@sizeTarget AS NVARCHAR(11)) + N' MB';
RAISERROR(@msg,0,1) WITH NOWAIT;

-- get the current size
SELECT @sizeCurrent = CAST(ROUND(size / 128.0, 0) AS INT) FROM sys.master_files WHERE database_id = DB_ID(@database) AND name = @file;

-- increase @size by the increment chosen
SET @size = @sizeCurrent + @increment;

-- make @size a standard size and set @filegrowth
SELECT TOP 1 @size = SizeMB,
             @filegrowth = GrowthMB
FROM         #FileSizes 
WHERE        SizeMB <= @size 
ORDER BY     SizeMB DESC;

-- display the initial file settings
SELECT @msg = CONVERT(NCHAR(19),GETDATE(),120) + 
              N' | DB: ' + DB_NAME(database_id) + 
              N' | File: ' + name + 
              N' | Size: ' + CAST(CAST(ROUND(size / 128.0, 0) AS INT) AS NVARCHAR(11)) + N' MB' +
              N' | Filegrowth: ' + CASE
                                       WHEN is_percent_growth = 0 THEN CAST(CAST(ROUND(growth / 128.0, 0) AS INT) AS NVARCHAR(11)) + N' MB'
                                       WHEN is_percent_growth = 1 THEN CAST(growth AS NVARCHAR(11)) + N' %'
                                   END +
              N' | Maxsize: ' +  CASE 
                                     WHEN max_size > 0 THEN CAST(CAST(ROUND(max_size / 128.0, 0) AS INT) AS NVARCHAR(11)) + N' MB'
                                     ELSE CAST(max_size AS NVARCHAR(11))
                                 END
FROM   sys.master_files
WHERE  DB_NAME(database_id) = @database
       AND name = @file;
RAISERROR(@msg,0,1) WITH NOWAIT;


------------------------------------------------------------------------------------------
--// BUILD AND RUN THE COMMAND                                                        //--
------------------------------------------------------------------------------------------

WHILE @size <= @sizeTarget
BEGIN
    -- build and execute the command
    SET @sql = N'ALTER DATABASE [' + @database + N'] MODIFY FILE ( NAME = N''' + @file + N''', SIZE = ' + CAST(@size AS VARCHAR(20)) + N'MB, FILEGROWTH = ' + CAST(@filegrowth AS VARCHAR(20)) + N'MB );';
    EXECUTE sys.sp_executesql @statement = @sql;
    
    -- display the new size
    SELECT @msg = CONVERT(NCHAR(19),GETDATE(),120) + 
                  N' | DB: ' + DB_NAME(database_id) + 
                  N' | File: ' + name + 
                  N' | Size (MB): ' + CAST(CAST(ROUND(size / 128.0, 0) AS INT) AS NVARCHAR(11)) + N' MB' +
                  N' | Filegrowth: ' + CASE
                                           WHEN is_percent_growth = 0 THEN CAST(CAST(ROUND(growth / 128.0, 0) AS INT) AS NVARCHAR(11)) + N' MB'
                                           WHEN is_percent_growth = 1 THEN CAST(growth AS NVARCHAR(11)) + N' %'
                                       END +
                  N' | Maxsize: ' +  CASE 
                                         WHEN max_size > 0 THEN CAST(CAST(ROUND(max_size / 128.0, 0) AS INT) AS NVARCHAR(11)) + N' MB'
                                         ELSE CAST(max_size AS NVARCHAR(11))
                                     END
    FROM   sys.master_files
    WHERE  DB_NAME(database_id) = @database
           AND name = @file;
    RAISERROR(@msg,0,1) WITH NOWAIT;
    
    -- get the current size
    SELECT @sizeCurrent = CAST(ROUND(size / 128.0, 0) AS INT) FROM sys.master_files WHERE database_id = DB_ID(@database) AND name = @file;
    
    -- increase @size by the increment chosen
    SET @size = @sizeCurrent + @increment;
    
    -- make @size a standard size and set @filegrowth
    SELECT TOP 1 @size = SizeMB,
                 @filegrowth = GrowthMB
    FROM         #FileSizes 
    WHERE        SizeMB <= @size 
    ORDER BY     SizeMB DESC;
END;

-- make sure the final size equals the target
IF @sizeCurrent < @sizeTarget
BEGIN
    -- build and execute the command
    SET @sql = N'ALTER DATABASE [' + @database + N'] MODIFY FILE ( NAME = N''' + @file + N''', SIZE = ' + CAST(@sizeTarget AS VARCHAR(20)) + N'MB, FILEGROWTH = ' + CAST(@filegrowth AS VARCHAR(20)) + N'MB );';
    EXECUTE sys.sp_executesql @statement = @sql;
    
    -- display the new size
    SELECT @msg = CONVERT(NCHAR(19),GETDATE(),120) + 
                  N' | DB: ' + DB_NAME(database_id) + 
                  N' | File: ' + name + 
                  N' | Size: ' + CAST(CAST(ROUND(size / 128.0, 0) AS INT) AS NVARCHAR(11)) + N' MB' +
                  N' | Filegrowth: ' + CASE
                                           WHEN is_percent_growth = 0 THEN CAST(CAST(ROUND(growth / 128.0, 0) AS INT) AS NVARCHAR(11)) + N' MB'
                                           WHEN is_percent_growth = 1 THEN CAST(growth AS NVARCHAR(11)) + N' %'
                                       END +
                  N' | Maxsize: ' +  CASE 
                                         WHEN max_size > 0 THEN CAST(CAST(ROUND(max_size / 128.0, 0) AS INT) AS NVARCHAR(11)) + N' MB'
                                         ELSE CAST(max_size AS NVARCHAR(11))
                                     END
    FROM   sys.master_files
    WHERE  DB_NAME(database_id) = @database
           AND name = @file;
    RAISERROR(@msg,0,1) WITH NOWAIT;
END;

    
-- finished
SELECT @msg = CONVERT(NCHAR(19),GETDATE(),120) + N' | Finished';
RAISERROR(@msg,0,1) WITH NOWAIT;



------------------------------------------------------------------------------------------
--// CLEAN UP                                                                         //--
------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#FileSizes') IS NOT NULL
	DROP TABLE #FileSizes;

