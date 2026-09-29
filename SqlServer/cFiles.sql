/**********************************************************************************************************

cFiles.sql

Author: dbabyday
Date: 02/26/2016

Purpose: Shows the size, space used, space free, percent free, and autogrowth setting of files and 
		 the drive it is on. Also shows the sum of file sizes for each drive.

Note: You can filter the resutls in the select query (starting on line 228).

Date        Name        Description
----------  ----------  ----------------------------------------------------------------------------------
2024-11-06  dbabyday    Added option to display results in KB, MB, GB (default), or TB by changing @DisplayUnits

**********************************************************************************************************/


DECLARE @DisplayUnits VARCHAR(2) = 'GB';  /* KB, MB, GB, TB */


DECLARE 
	  @advanced     BIT
	, @Command      NVARCHAR(MAX)
	, @Database     NVARCHAR(260)
	, @DriveLetter  CHAR(1)
	, @DriveNameOut INT
	, @FSO          INT 
	, @ole          BIT
	, @Result       INT
	, @TotalSizeOut VARCHAR(20)
	, @ConversionValueFromBytes DECIMAL(19,3)
	, @ConversionValueFromPages DECIMAL(19,3);



/* set the size conversion value based on the desired units */
IF @DisplayUnits = 'KB' 
	SET @ConversionValueFromBytes = 1024.0;
ELSE IF @DisplayUnits = 'MB'
	SET @ConversionValueFromBytes = 1024.0 * 1024.0;
ELSE IF @DisplayUnits = 'GB'
	SET @ConversionValueFromBytes = 1024.0 * 1024.0 * 1024.0;
ELSE IF @DisplayUnits = 'TB'
	SET @ConversionValueFromBytes = 1024.0 * 1024.0 * 1024.0 * 1024.0;
/* set the value for units that report in 8K pages */
SET @ConversionValueFromPages = @ConversionValueFromBytes / 1024.0 / 8.0;



DROP TABLE IF EXISTS #FileInfo;
DROP TABLE IF EXISTS #DriveInfo;

CREATE TABLE #FileInfo
(
	  ID                INT IDENTITY(1,1) PRIMARY KEY
	, [Database]        NVARCHAR(260)
	, name              SYSNAME
	, type_desc         NVARCHAR(120)
	, size              INT
	, Used_Pages        INT
	, is_percent_growth BIT
	, growth            INT
	, max_size          INT
	, physical_name     NVARCHAR(520)
	, DriveLetter AS LEFT(physical_name,1)
	, Drive AS LEFT(physical_name,3)
);

CREATE TABLE #DriveInfo
(
	  Drive        CHAR(1) PRIMARY KEY
	, FreeSpace_MB BIGINT
	, Capacity     BIGINT
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
		EXECUTE master.dbo.sp_configure
			  @configname  = 'show advanced options'
			, @configvalue = 1;
		RECONFIGURE WITH OVERRIDE;
	END;

	EXECUTE master.dbo.sp_configure
		  @configname  = 'Ole Automation Procedures'
		, @configvalue = 1;
	RECONFIGURE WITH OVERRIDE;
END;



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
				  [Database]
				, name
				, type_desc
				, size
				, Used_Pages
				, is_percent_growth
				, growth
				, max_size
				, physical_name
			)
			SELECT
				  DB_NAME()
				, name
				, type_desc
				, size
				, FILEPROPERTY(name, ''SpaceUsed'')
				, is_percent_growth
				, growth
				, max_size
				, physical_name
			FROM
				sys.database_files'
		);
	
		FETCH NEXT FROM curDatabases INTO @Database;
	END
CLOSE curDatabases;
DEALLOCATE curDatabases;



------------------------------------------------------------------------------------------
--// GET DRIVE SPACE INFO                                                             //--
------------------------------------------------------------------------------------------

INSERT #DriveInfo (Drive,FreeSpace_MB) 
EXEC master.dbo.xp_fixeddrives;

EXEC @Result = sp_OACreate 'Scripting.FileSystemObject', @FSO OUT; 
				   
IF @Result <> 0 
	EXEC sp_OAGetErrorInfo @FSO;

DECLARE curDrives CURSOR LOCAL FAST_FORWARD FOR
	SELECT Drive
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
		SET Capacity = CAST(@TotalSizeOut AS BIGINT)
		WHERE Drive = @DriveLetter; 

		FETCH NEXT FROM curDrives INTO @DriveLetter;
	END
CLOSE curDrives;
DEALLOCATE curDrives;

EXEC @Result = sp_OADestroy @FSO; 

IF @Result <> 0 
	EXEC sp_OAGetErrorInfo @FSO;





------------------------------------------------------------------------------------------
--// DISPLAY FILE INFO                                                                //--
------------------------------------------------------------------------------------------

SELECT
	  f.[Database]
	, f.name
	, f.physical_name
	, f.type_desc
	, CAST(ROUND(f.size * 1.0  / @ConversionValueFromPages, 0) AS INT) AS Size
	, CAST(ROUND(f.Used_Pages * 1.0 / @ConversionValueFromPages, 0) AS INT) AS Used
	, CAST(ROUND((f.size - f.Used_Pages) * 1.0 / @ConversionValueFromPages, 0) AS INT) AS Free
	, CASE 
		WHEN f.size <> 0 THEN CAST(ROUND((f.size - f.Used_Pages) * 1.0 / f.size * 100, 1) AS DECIMAL(6,1))
		ELSE 0.0
	  END AS [% free]
	, CASE
		WHEN f.is_percent_growth=0 AND f.growth>0 THEN CAST(ROUND(f.growth * 1.0 / @ConversionValueFromPages, 1) AS DECIMAL(19,1))
		ELSE NULL
	  END AS AutogrowFixed
	, CASE
		WHEN f.is_percent_growth=1 AND f.growth>0 THEN f.growth
		ELSE NULL
	  END AS AutogrowPercent
	, CASE f.max_size
		WHEN -1 THEN -1
		WHEN 0 THEN 0
		ELSE CAST(ROUND(f.max_size * 1.0 / @ConversionValueFromPages, 1) AS DECIMAL(19,1))
	  END AS max_size
	, f.Drive
	, CAST(ROUND(d.Capacity * 1.0 / @ConversionValueFromBytes, 0) AS INT) AS DriveCapacity
	, CAST(ROUND((d.Capacity * 1.0 - (d.FreeSpace_MB * 1024.0 * 1024.0)) / @ConversionValueFromBytes, 0) AS INT) AS DriveUsed
	, CAST(ROUND(d.FreeSpace_MB * 1024.0 * 1024.0 / @ConversionValueFromBytes, 0) AS INT) AS DriveFree
	, CAST(ROUND((d.FreeSpace_MB * 1024.0 * 1024.0) / d.Capacity * 100, 1) AS DECIMAL(6,1)) AS [% DriveFree]
	, @DisplayUnits AS DisplayUnits
FROM 
	#FileInfo AS f
INNER JOIN
	#DriveInfo AS d ON f.DriveLetter = d.Drive
WHERE
	f.type_desc <> 'FILESTREAM'
	--AND f.[Database] = 'Pricing'
	--AND f.type_desc = 'LOG'
	--AND d.Drive = 'G'
	--AND f.name = 'UnitSetup'
ORDER BY 
	  f.[Database], f.name;
	--[% Free];
	--f.Drive, f.[Database], f.name;
	--f.size;

/*
use master;
ALTER DATABASE [BizTalk_General] MODIFY FILE ( NAME = N'BizTalk_General_log', SIZE=100GB, FILEGROWTH=2048MB, MAXSIZE = UNLIMITED );
ALTER DATABASE [BizTalk_General] MODIFY FILE ( NAME = N'BizTalk_General', FILEGROWTH=2048MB );

use BizTalk_General;
dbcc shrinkfile(BizTalk_General_log,50000);

*/





------------------------------------------------------------------------------------------
--// DISPLAY FILE SIZE SUMS FOR EACH DRIVE                                            //--
------------------------------------------------------------------------------------------

SELECT
	  f.Drive
	, CAST(ROUND(SUM(f.size) * 1.0 / @ConversionValueFromPages, 0) AS INT) AS Sum_FileSizes
	, CAST(ROUND(SUM(f.Used_Pages) * 1.0 / @ConversionValueFromPages, 0) AS INT) AS Sum_FilesUsed
	, CAST(ROUND(SUM(f.size - f.Used_Pages) * 1.0 / @ConversionValueFromPages, 0) AS INT) AS Sum_FilesFree
	, CAST(ROUND(SUM(f.size - f.Used_Pages) * 1.0 / SUM(f.size) * 100, 1) AS DECIMAL(6,1)) AS [% FilesFree]
	, CAST(ROUND(d.Capacity * 1.0 / @ConversionValueFromBytes, 0) AS INT) AS DriveCapacity
	, CAST(ROUND((d.Capacity * 1.0 - (d.FreeSpace_MB * 1024.0 * 1024.0)) / @ConversionValueFromBytes, 0) AS INT) AS DriveUsed
	, CAST(ROUND(d.FreeSpace_MB * 1024.0 * 1024.0 / @ConversionValueFromBytes, 0) AS INT) AS DriveFree
	, CAST(ROUND((d.FreeSpace_MB * 1024.0 * 1024.0) / d.Capacity * 100, 1) AS DECIMAL(6,1)) AS [% DriveFree]
FROM
	#FileInfo AS f
INNER JOIN
	#DriveInfo AS d ON f.DriveLetter=d.Drive
GROUP BY
	  f.Drive
	, d.Capacity
	, d.FreeSpace_MB
ORDER BY
	f.Drive;






------------------------------------------------------------------------------------------
--// CLEAN UP                                                                         //--
------------------------------------------------------------------------------------------

IF @ole = 0
BEGIN
	EXECUTE master.dbo.sp_configure
		  @configname  = 'Ole Automation Procedures'
		, @configvalue = 0;
	RECONFIGURE WITH OVERRIDE;

	IF @advanced = 0
	BEGIN
		EXECUTE master.dbo.sp_configure
			  @configname  = 'show advanced options'
			, @configvalue = 0;
		RECONFIGURE WITH OVERRIDE;
	END;
END;

DROP TABLE IF EXISTS #FileInfo;
DROP TABLE IF EXISTS #DriveInfo;


