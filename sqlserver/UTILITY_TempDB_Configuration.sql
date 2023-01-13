/**************************************************************************************
* 
* UTILITY_TempDB_Configure.sql
* 
* Author: James Lutsey
* Date: 08/24/2016
* 
* Purpose: Configure TempDB
* 
* Notes:
*     1. Enter file sizes and location
*     2. You can either PRINT or EXECUTE the sql commands
* 
**************************************************************************************/

DECLARE
	-- USER INPUT
	@dataFileSize   INT = 1024,
	@logFileSize    INT = 1024,
	@location       VARCHAR(128) = 'T:\TempDB\',  -- SELECT REPLACE(physical_name,'tempdb.mdf','') FROM tempdb.sys.database_files WHERE name = 'tempdev';
	@printOrExecute VARCHAR(7)   = 'PRINT', -- PRINT EXECUTE

	-- other variables
	@dataFileGrowth INT,
	@logFileGrowth  INT,
	@size           INT,
	@growth         INT,
	@sql1           VARCHAR(MAX) = '',
	@sql2           VARCHAR(MAX) = '';

SET NOCOUNT ON;

USE [master];
	

-----------------------------------------------------------------
--// VALIDATE USER INPUT                                     //--
-----------------------------------------------------------------

IF (UPPER(@printOrExecute) != 'PRINT') AND (UPPER(@printOrExecute) != 'EXECUTE')
BEGIN
	RAISERROR('@printOrExecute must be ''PRINT'' or ''EXECUTE''',16,1);
	RETURN;
END


-----------------------------------------------------------------
--// STANDARD FILE AND GROWTH SIZES                          //--
-----------------------------------------------------------------

-- temp table for standard size and growth settings
IF OBJECT_ID('tempdb..#FileSizes') IS NOT NULL DROP TABLE #FileSizes;
CREATE TABLE #FileSizes
(
    [SizeMB]   INT PRIMARY KEY,
    [GrowthMB] INT
);

SET @growth = 4;
SET @size = 4;
SET @sql1 = N'INSERT INTO #FileSizes ([SizeMB], [GrowthMB])' + CHAR(13) + CHAR(10) + 'VALUES ';

WHILE @size < 1048576
BEGIN
    SET @sql1 = @sql1 + N'(' + CAST(@size AS NVARCHAR(7)) + N',' + CAST(@growth AS NVARCHAR(7)) + '),';
    SET @size = @size + @growth;
    
    IF (@size = 72) OR (@size = 144) OR (@size = 288) OR (@size = 576) OR (@size = 1152) OR (@size = 2304) OR (@size = 4608) OR (@size = 9216) OR (@size = 22528)
    BEGIN
        SET @growth = @growth * 2;
        SET @sql1 = @sql1 + CHAR(13) + CHAR(10) + '       ';
    END
END 

SET @sql1 = @sql1 + N'(' + CAST(@size AS NVARCHAR(7)) + N',' + CAST(@growth AS NVARCHAR(7)) + ');'

EXECUTE(@sql1);

-- get the growth value that corresponds to the indicated size
SELECT TOP 1 @dataFileGrowth = [GrowthMB] FROM #FileSizes WHERE [SizeMB] <= @dataFileSize ORDER BY [SizeMB] DESC;
SELECT TOP 1 @logFileGrowth  = [GrowthMB] FROM #FileSizes WHERE [SizeMB] <= @logFileSize  ORDER BY [SizeMB] DESC;


-----------------------------------------------------------------
--// BUILD THE TEMPDB COMMAND                                //--
-----------------------------------------------------------------

-- tempdev
IF (SELECT [size]/128 FROM [sys].[master_files] WHERE [name] = 'tempdev') < @dataFileSize
BEGIN
	SET @sql2 += 'ALTER DATABASE [tempdb] MODIFY FILE (NAME = N''tempdev'', SIZE = ' + CAST(@dataFileSize AS VARCHAR(10)) + 'MB, MAXSIZE = UNLIMITED, FILEGROWTH = ' + CAST(@dataFileGrowth AS VARCHAR(10)) + 'MB );' + CHAR(13)+CHAR(10);
	SET @sql2 += 'PRINT ''tempdb .mdf Expanded to SIZE = ' + CAST(@dataFileSize AS VARCHAR(10)) + 'MB, MAXSIZE = UNLIMITED, FILEGROWTH = ' + CAST(@dataFileGrowth AS VARCHAR(10)) + 'MB'';' + CHAR(13)+CHAR(10);
	SET @sql2 += CHAR(13)+CHAR(10);
END
ELSE
BEGIN
	SET @sql2 += 'PRINT ''tempdb .mdf is already >= ' + CAST(@dataFileSize AS VARCHAR(10)) + ' MB'';' + CHAR(13)+CHAR(10);
	SET @sql2 += CHAR(13)+CHAR(10);
END

-- templog
IF (SELECT [size]/128 FROM [sys].[master_files] WHERE [name] = 'templog') < @logFileSize
BEGIN
	SET @sql2 += 'ALTER DATABASE [tempdb] MODIFY FILE (NAME = N''templog'', SIZE = ' + CAST(@logFileSize AS VARCHAR(10)) + 'MB, MAXSIZE = UNLIMITED, FILEGROWTH = ' + CAST(@logFileGrowth AS VARCHAR(10)) + 'MB );' + CHAR(13)+CHAR(10);
	SET @sql2 += 'PRINT ''tempdb .ldf Expanded to SIZE = ' + CAST(@logFileSize AS VARCHAR(10)) + 'MB, MAXSIZE = UNLIMITED, FILEGROWTH = ' + CAST(@logFileGrowth AS VARCHAR(10)) + 'MB'';' + CHAR(13)+CHAR(10);
	SET @sql2 += CHAR(13)+CHAR(10);
END
ELSE
BEGIN
	SET @sql2 += 'PRINT ''tempdb .ldf is already >= ' + CAST(@logFileSize AS VARCHAR(10)) + ' MB'';' + CHAR(13)+CHAR(10);
	SET @sql2 += CHAR(13)+CHAR(10);
END

-- add data files
IF (SELECT COUNT(*) FROM [sys].[master_files] WHERE DB_NAME([database_id]) = 'tempdb' AND type = 0) = 1
BEGIN
	SET @sql2 += 'ALTER DATABASE [tempdb] ADD FILE ( NAME = N''tempdev2'', FILENAME = N''' + @location + 'tempdb2.ndf'', SIZE = ' + CAST(@dataFileSize AS VARCHAR(10)) + 'MB, MAXSIZE = UNLIMITED, FILEGROWTH = ' + CAST(@dataFileGrowth AS VARCHAR(10)) + 'MB );' + CHAR(13)+CHAR(10);
	SET @sql2 += 'ALTER DATABASE [tempdb] ADD FILE ( NAME = N''tempdev3'', FILENAME = N''' + @location + 'tempdb3.ndf'', SIZE = ' + CAST(@dataFileSize AS VARCHAR(10)) + 'MB, MAXSIZE = UNLIMITED, FILEGROWTH = ' + CAST(@dataFileGrowth AS VARCHAR(10)) + 'MB );' + CHAR(13)+CHAR(10);
	SET @sql2 += 'ALTER DATABASE [tempdb] ADD FILE ( NAME = N''tempdev4'', FILENAME = N''' + @location + 'tempdb4.ndf'', SIZE = ' + CAST(@dataFileSize AS VARCHAR(10)) + 'MB, MAXSIZE = UNLIMITED, FILEGROWTH = ' + CAST(@dataFileGrowth AS VARCHAR(10)) + 'MB );' + CHAR(13)+CHAR(10);
	
	SET @sql2 += 'PRINT ''tempdb2.ndf, tempdb3.ndf, and tempdb4.ndf added to tempdb: SIZE = ' + CAST(@dataFileSize AS VARCHAR(10)) + 'MB, MAXSIZE = UNLIMITED, FILEGROWTH = ' + CAST(@dataFileGrowth AS VARCHAR(10)) + 'MB'';' + CHAR(13)+CHAR(10);
	SET @sql2 += CHAR(13)+CHAR(10);
END
ELSE
BEGIN
	SET @sql2 += 'PRINT ''did NOT add additional files to tempdb, it already has multiple data files'';' + CHAR(13)+CHAR(10);
	SET @sql2 += CHAR(13)+CHAR(10);
END

IF @location != (SELECT TOP 1 REPLACE(physical_name,'tempdb.mdf','') FROM tempdb.sys.database_files WHERE name = 'tempdev')
BEGIN
	SELECT @sql2 += 'PRINT ''***** CHANGING LOCATION OF tempdb.mdf FROM ' + [physical_name] + ' TO ' + @location + 'tempdb.mdf *****'';' + CHAR(13)+CHAR(10)
	FROM [sys].[master_files]
	WHERE [name] = 'tempdev';
	
	SET @sql2 += 'ALTER DATABASE [tempdb] MODIFY FILE ( NAME = ''tempdev'', FILENAME = N''' + @location + 'tempdb.mdf'' );' + CHAR(13)+CHAR(10);
	SET @sql2 += CHAR(13)+CHAR(10);
END

IF @location != (SELECT TOP 1 REPLACE(physical_name,'templog.ldf','') FROM tempdb.sys.database_files WHERE name = 'templog')
BEGIN
	SELECT @sql2 += 'PRINT ''***** CHANGING LOCATION OF templog.ldf FROM ' + [physical_name] + ' TO ' + @location + 'templog.ldf *****'';' + CHAR(13)+CHAR(10)
	FROM [sys].[master_files]
	WHERE [name] = 'templog';
	
	SET @sql2 += 'ALTER DATABASE [tempdb] MODIFY FILE ( NAME = ''templog'', FILENAME = N''' + @location + 'templog.ldf'' );' + CHAR(13)+CHAR(10);
	SET @sql2 += CHAR(13)+CHAR(10);
END

IF UPPER(@printOrExecute) = 'PRINT' 
	PRINT @sql2
ELSE IF UPPER(@printOrExecute) = 'EXECUTE'
	EXECUTE(@sql2);


-----------------------------------------------------------------
--// CLEAN UP                                                //--
-----------------------------------------------------------------

IF OBJECT_ID('tempdb..#FileSizes') IS NOT NULL DROP TABLE #FileSizes;