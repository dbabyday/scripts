USE CentralAdmin;
GO

IF OBJECT_ID('dbo.usp_FilesInfo','P') IS NULL
	EXEC('CREATE PROCEDURE dbo.usp_FilesInfo AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.usp_FilesInfo
	@WHERE_PercentFree NVARCHAR(25)  = N'',
	@WHERE_type_desc   NVARCHAR(50)  = N'',
	@WHERE_Drive       NCHAR(1)      = N'',
	@WHERE_Database    NVARCHAR(128) = N'',
	@WHERE_File        NVARCHAR(128) = N'',
	@WHERE_Custom      NVARCHAR(MAX) = N'',
	@ORDERBY           NVARCHAR(100) = N'1,2',
	@DisplayResults    NVARCHAR(6)   = N'BOTH',
	@help              VARCHAR(25)   = '',
	@getVersion        BIT           = 0,
	@version           VARCHAR(10)    = '1.0' OUTPUT
AS

SET NOCOUNT ON;

DECLARE 
    @Command		NVARCHAR(MAX),
	@Database		NVARCHAR(260),
	@DriveLetter	CHAR(1),
	@DriveNameOut	INT,
	@FSO			INT, 
	@Message        VARCHAR(MAX),
	@Result			INT,
    @TotalSizeOut	VARCHAR(20),
	@WhereOrderBy   NVARCHAR(MAX);
	--@version        VARCHAR(10);

--SET @version = '1.0';



------------------------------------------------------------------------------------------
--// HELP INFO                                                                        //--
------------------------------------------------------------------------------------------

-- return the version if requested
IF @getVersion = 1 
BEGIN
	--SELECT @version AS 'version';
	RETURN;
END

-- return help info if requested
IF (@help != '') AND (UPPER(@help) != 'N') AND (UPPER(@help) != 'NO')
BEGIN
	SET @Message = '
/**********************************************************************************************************
* 
* usp_FilesInfo ' + @version + '
* 
* Author: James Lutsey
* Date: 02/26/2016
* 
* Purpose: Shows the size, space used, space free, percent free, and autogrowth setting of files and 
*          the drive it is on. Also shows the sum of file sizes for each drive.
* 
* Note: 
*     1. You can filter the resutls by entering values for the @WHERE... and @ORDERBY variables.
*     2. FILESTREAM	files are not included.
*     3. Get the version: EXECUTE [CentralAdmin].[dbo].[usp_FilesInfo] @getVersion = 1;
* 
**********************************************************************************************************/


------------------------------------------------------------------------------------------
--// COMMAND                                                                          //--
------------------------------------------------------------------------------------------

EXECUTE CentralAdmin.dbo.usp_FilesInfo  -- @help = ''Y''
	@WHERE_PercentFree = N''<= 10'', -- '''', ''<= 10'', ''> 50''
	@WHERE_type_desc   = N'''', -- ''LOG'' ''ROWS''
	@WHERE_Drive       = N'''', -- ''C'', ''F'', ''G''
	@WHERE_Database    = N'''', -- ''myDatabaseName''
	@WHERE_File        = N'''', -- ''myFileName''

	-- @WHERE_Custom      = N''WHERE ...'',
	
	@ORDERBY           = N''1,2'', -- default is ''Database,File''

	@DisplayResults    = N''BOTH''; -- ''BOTH'', ''FILES'', ''DRIVES''



/*
ORDER BY columns
	 1 - Database
	 2 - File
	 3 - type_desc
	 4 - Size_MB
	 5 - Used_MB
	 6 - Free_MB
	 7 - % Free
	 8 - Autogrowth
	 9 - max_size
	10 - Drive
	11 - DriveCapacity
	12 - DriveUsed
	13 - DriveFree
	14 - % DriveFree
	15 - usp_FileGrowth @where
*/';

	PRINT @Message;
	RETURN;
END


------------------------------------------------------------------------------------------
--// TEMP TABLES                                                                      //--
------------------------------------------------------------------------------------------

IF (OBJECT_ID('tempdb..#FileInfo') IS NOT NULL)
	DROP TABLE #FileInfo;
IF (OBJECT_ID('tempdb..#DriveInfo') IS NOT NULL)
	DROP TABLE #DriveInfo;

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

CREATE TABLE #DriveInfo
(
    [Drive]			CHAR(1) PRIMARY KEY, 
    [FreeSpace_MB]	BIGINT,
    [Capacity_MB]	BIGINT
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
		SET @Command =N'
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
    sys.database_files';

		EXEC sp_executesql @stmt = @Command;
    
		FETCH NEXT FROM curDatabases INTO @Database;
	END
CLOSE curDatabases;
DEALLOCATE curDatabases;



------------------------------------------------------------------------------------------
--// GET DRIVE SPACE INFO                                                             //--
------------------------------------------------------------------------------------------

INSERT #DriveInfo ([Drive],[FreeSpace_MB]) 
EXEC master.dbo.xp_fixeddrives;

EXEC @Result = sp_OACreate 'Scripting.FileSystemObject', @FSO OUT; 
                   
IF @Result <> 0 
    EXEC sp_OAGetErrorInfo @FSO;

DECLARE curDrives CURSOR LOCAL FAST_FORWARD FOR
	SELECT [Drive] 
	FROM #DriveInfo;

OPEN curDrives;
	FETCH NEXT FROM curDrives INTO @DriveLetter;

	WHILE @@FETCH_STATUS=0
	BEGIN
		EXEC @Result = sp_OAMethod @FSO,'GetDrive', @DriveNameOut OUT, @DriveLetter;

		IF @Result <> 0 
			EXEC sp_OAGetErrorInfo @FSO;
            
		EXEC @Result = sp_OAGetProperty @DriveNameOut, 'TotalSize', @TotalSizeOut OUT;
                     
		IF @Result <> 0 
			EXEC sp_OAGetErrorInfo @DriveNameOut; 
  
		UPDATE #DriveInfo 
		SET [Capacity_MB] = CAST(@TotalSizeOut AS BIGINT) / 1048576 
		WHERE [Drive] = @DriveLetter; 

		FETCH NEXT FROM curDrives INTO @DriveLetter;
	END
CLOSE curDrives;
DEALLOCATE curDrives;

EXEC @Result = sp_OADestroy @FSO; 

IF @Result <> 0 
    EXEC sp_OAGetErrorInfo @FSO;



------------------------------------------------------------------------------------------
--// BUILD THE WHERE AND ORDER BY ARUGUMENT FROM USER INPUTS                          //--
------------------------------------------------------------------------------------------

SET @WhereOrderBy = N'WHERE' + CHAR(13) + CHAR(10) + N'    [f].[type_desc] != ''FILESTREAM''' + CHAR(13) + CHAR(10);

-- if user entered a custom argument, use it
IF @WHERE_Custom != N''
	SET @WhereOrderBy = @WHERE_Custom + CHAR(13) + CHAR(10);
-- if not, add all the inputs they specified for WHERE
ELSE
BEGIN
	IF @WHERE_PercentFree != N''
		SET @WhereOrderBy = @WhereOrderBy + N'    AND CAST((CAST(([f].[size] - [f].[Used_Pages]) AS DECIMAL(10,1)) / CAST([f].[size] AS DECIMAL(10,1)) * 100) AS DECIMAL(4,1)) ' + @WHERE_PercentFree + CHAR(13) + CHAR(10);
	IF @WHERE_type_desc != N''
		SET @WhereOrderBy = @WhereOrderBy + N'    AND [f].[type_desc] = ''' + @WHERE_type_desc + N'''' + CHAR(13) + CHAR(10);
	IF @WHERE_Drive != N''
		SET @WhereOrderBy = @WhereOrderBy + N'    AND [d].[Drive] = '''     + @WHERE_Drive     + N'''' + CHAR(13) + CHAR(10);
	IF @WHERE_Database != N''
		SET @WhereOrderBy = @WhereOrderBy + N'    AND [f].[Database] = '''  + @WHERE_Database  + N'''' + CHAR(13) + CHAR(10);
	IF @WHERE_File != N''
		SET @WhereOrderBy = @WhereOrderBy + N'    AND [f].[name] = '''      + @WHERE_File      + N'''' + CHAR(13) + CHAR(10);
END

-- add the order by columns
IF @ORDERBY != N''
	SET @WhereOrderBy = @WhereOrderBy + N'ORDER BY' + CHAR(13) + CHAR(10) + N'    ' + @ORDERBY;



------------------------------------------------------------------------------------------
--// DISPLAY FILE INFO                                                                //--
------------------------------------------------------------------------------------------

IF (UPPER(@DisplayResults) = N'BOTH') OR (UPPER(@DisplayResults) = N'FILES')
BEGIN
	EXECUTE('
SELECT
	[f].[Database],
	[File] = [f].[name],
	[f].[type_desc],
	[Size_MB] = [f].[size] / 128,
	[Used_MB] = CAST([f].[Used_Pages] / 128.0 AS DECIMAL(10,1)),
	[Free_MB] = CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)),
	[% free] = 
		CASE 
			WHEN [f].[size] != 0 THEN CAST((CAST(([f].[size] - [f].[Used_Pages]) AS DECIMAL(10,1)) / CAST([f].[size] AS DECIMAL(10,1)) * 100) AS DECIMAL(4,1))
			ELSE 0.0
		END,
	[Autogrowth] = 
		CASE [f].[is_percent_growth]
			WHEN 0 THEN CAST(([f].[growth] / 128) AS VARCHAR(10)) + '' MB''
			WHEN 1 THEN CAST([f].[growth] AS VARCHAR(3)) + '' %''
		END,
    [max_size] = 
		CASE [f].[max_size]
			WHEN 0 THEN 0
			WHEN -1 THEN -1
			ELSE max_size / 128
		END,
	[Drive] = 
		LEFT([f].[physical_name],3),
	[DriveCapacity] = [d].[Capacity_MB],
	[DriveUsed] = [d].[Capacity_MB] - [d].[FreeSpace_MB],
	[DriveFree] = [d].[FreeSpace_MB],
	[% DriveFree] = CAST(([d].[FreeSpace_MB] / (1.0 * [d].[Capacity_MB]) * 100) AS DECIMAL(4,1)),
	[usp_FileGrowth @where] = 
		''sqlservername = '''''''''' + @@SERVERNAME + '''''''''' AND databasename = '''''''''' + [f].[Database] + '''''''''' AND DatabaseFileName = '''''''''' + [f].[name] + ''''''''''''
FROM 
	#FileInfo AS [f]
INNER JOIN
	#DriveInfo AS [d]
	ON LEFT([f].[physical_name],1) = [d].[Drive]
' + @WhereOrderBy);

END



------------------------------------------------------------------------------------------
--// DISPLAY FILE SIZE SUMS FOR EACH DRIVE                                            //--
------------------------------------------------------------------------------------------

IF (UPPER(@DisplayResults) = N'BOTH') OR (UPPER(@DisplayResults) = N'DRIVES')
BEGIN
	SELECT
		[Drive] = 
			LEFT([f].[physical_name],3),
		[Sum_FileSizes_MB] = 
			CASE
				WHEN LEN(CAST(SUM(CAST(([f].[size] / 128.0) AS DECIMAL(10,1))) AS VARCHAR(27))) > 8
					THEN REVERSE(STUFF(STUFF(REVERSE(CAST(SUM(CAST(([f].[size] / 128.0) AS DECIMAL(10,1))) AS VARCHAR(27))),9,0,','),6,0,','))
				WHEN LEN(CAST(SUM(CAST(([f].[size] / 128.0) AS DECIMAL(10,1))) AS VARCHAR(27))) > 5
					THEN REVERSE(STUFF(REVERSE(CAST(SUM(CAST(([f].[size] / 128.0) AS DECIMAL(10,1))) AS VARCHAR(27))),6,0,','))
				ELSE CAST(SUM(CAST(([f].[size] / 128.0) AS DECIMAL(10,1))) AS VARCHAR(27))
			END,
		[Sum_FilesUsed_MB] = 
			CASE
				WHEN LEN(CAST(SUM(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1))) AS VARCHAR(27))) > 8
					THEN REVERSE(STUFF(STUFF(REVERSE(CAST(SUM(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1))) AS VARCHAR(27))),9,0,','),6,0,','))
				WHEN LEN(CAST(SUM(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1))) AS VARCHAR(27))) > 5
					THEN REVERSE(STUFF(REVERSE(CAST(SUM(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1))) AS VARCHAR(27))),6,0,','))
				ELSE CAST(SUM(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1))) AS VARCHAR(27))
			END,
		[Sum_FilesFree_MB] = 
			CASE
				WHEN LEN(CAST(SUM(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1))) AS VARCHAR(27))) > 8
					THEN REVERSE(STUFF(STUFF(REVERSE(CAST(SUM(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1))) AS VARCHAR(27))),9,0,','),6,0,','))
				WHEN LEN(CAST(SUM(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1))) AS VARCHAR(27))) > 5
					THEN REVERSE(STUFF(REVERSE(CAST(SUM(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1))) AS VARCHAR(27))),6,0,','))
				ELSE CAST(SUM(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1))) AS VARCHAR(27))
			END,
		[% FilesFree] = 
			CAST((CAST(SUM(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1))) AS DECIMAL(10,1)) / 
				CAST(SUM(CAST(([f].[size] / 128.0) AS DECIMAL(10,1))) AS DECIMAL(10,1)) * 100) AS DECIMAL(4,1)),
		[DriveCapacity_MB] = 
			CASE
				WHEN LEN(CAST([d].[Capacity_MB] AS VARCHAR(27))) > 6
					THEN REVERSE(STUFF(STUFF(REVERSE(CAST([d].[Capacity_MB] AS VARCHAR(27))),7,0,','),4,0,','))
				WHEN LEN(CAST([d].[Capacity_MB] AS VARCHAR(27))) > 3
					THEN REVERSE(STUFF(REVERSE(CAST([d].[Capacity_MB] AS VARCHAR(27))),4,0,','))
				ELSE CAST([d].[Capacity_MB] AS VARCHAR(27))
			END,
		[DriveUsed_MB] = 
			CASE
				WHEN LEN(CAST([d].[Capacity_MB] - [d].[FreeSpace_MB] AS VARCHAR(27))) > 6
					THEN REVERSE(STUFF(STUFF(REVERSE(CAST([d].[Capacity_MB] - [d].[FreeSpace_MB] AS VARCHAR(27))),7,0,','),4,0,','))
				WHEN LEN(CAST([d].[Capacity_MB] - [d].[FreeSpace_MB] AS VARCHAR(27))) > 3
					THEN REVERSE(STUFF(REVERSE(CAST([d].[Capacity_MB] - [d].[FreeSpace_MB] AS VARCHAR(27))),4,0,','))
				ELSE CAST([d].[Capacity_MB] - [d].[FreeSpace_MB] AS VARCHAR(27))
			END,
		[DriveFree_MB] = 
			CASE
				WHEN LEN(CAST([d].[FreeSpace_MB] AS VARCHAR(27))) > 6
					THEN REVERSE(STUFF(STUFF(REVERSE(CAST([d].[FreeSpace_MB] AS VARCHAR(27))),7,0,','),4,0,','))
				WHEN LEN(CAST([d].[FreeSpace_MB] AS VARCHAR(27))) > 3
					THEN REVERSE(STUFF(REVERSE(CAST([d].[FreeSpace_MB] AS VARCHAR(27))),4,0,','))
				ELSE CAST([d].[FreeSpace_MB] AS VARCHAR(27))
			END,
		[% DriveFree] = 
			CAST(([d].[FreeSpace_MB] / (1.0 * [d].[Capacity_MB]) * 100) AS DECIMAL(4,1))
	FROM
		#FileInfo AS [f]
	INNER JOIN
		#DriveInfo AS [d]
		ON LEFT([f].[physical_name],1) = [d].[Drive]
	GROUP BY
		LEFT([f].[physical_name],3),
		[d].[Capacity_MB],
		[d].[FreeSpace_MB]
END



------------------------------------------------------------------------------------------
--// CLEAN UP                                                                         //--
------------------------------------------------------------------------------------------

DROP TABLE #FileInfo;
DROP TABLE #DriveInfo;



