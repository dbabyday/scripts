/**********************************************************************************************************
* 
* FILES_Info.sql
* 
* Author: James Lutsey
* Date: 02/26/2016
* 
* Purpose: Shows the size, space used, space free, percent free, and autogrowth setting of files and 
*          the drive it is on. Also shows the sum of file sizes for each drive.
* 
* Note: You can filter the resutls in the select query (starting on line 228).
* 
**********************************************************************************************************/

SET NOCOUNT ON;

DECLARE 
    @advanced     BIT,
    @Command      NVARCHAR(MAX),
    @Database     NVARCHAR(260),
    @DriveLetter  CHAR(1),
    @DriveNameOut INT,
    @FSO          INT, 
    @ole          BIT,
    @Result       INT,
    @TotalSizeOut VARCHAR(20);

IF (OBJECT_ID('tempdb..#FileInfo') IS NOT NULL)
    DROP TABLE #FileInfo;
IF (OBJECT_ID('tempdb..#DriveInfo') IS NOT NULL)
    DROP TABLE #DriveInfo;

CREATE TABLE #FileInfo
(
    [ID]                INT IDENTITY(1,1) PRIMARY KEY,
    [Database]          NVARCHAR(260),
    [name]              SYSNAME,
    [type_desc]         NVARCHAR(120),
    [size]              INT,
    [Used_Pages]        INT,
    [is_percent_growth] BIT,
    [growth]            INT,
    [max_size]          INT,
    [physical_name]     NVARCHAR(520)
);

CREATE TABLE #DriveInfo
(
    [Drive]            CHAR(1) PRIMARY KEY, 
    [FreeSpace_MB]    BIGINT,
    [Capacity_MB]    BIGINT
);



------------------------------------------------------------------------------------------
--// GET OLE AUTOMATION PROCEDURES CONFIGURATION                                      //--
------------------------------------------------------------------------------------------

SELECT @advanced = CAST([value] AS BIT)
FROM   [sys].[configurations]
WHERE  [name] = N'show advanced options';

SELECT @ole = CAST([value] AS BIT)
FROM   [sys].[configurations]
WHERE  [name] = N'Ole Automation Procedures';

IF @ole = 0
BEGIN
    IF @advanced = 0
    BEGIN
        EXECUTE [master].[dbo].[sp_configure] @configname  = 'show advanced options',
                                              @configvalue = 1;
        RECONFIGURE WITH OVERRIDE;
    END;
    
    EXECUTE [master].[dbo].[sp_configure] @configname  = 'Ole Automation Procedures',
                                          @configvalue = 1;
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
--// DISPLAY FILE INFO                                                                //--
------------------------------------------------------------------------------------------

SELECT
    /*1*/ [f].[Database],
    /*2*/ [File] = [f].[name],
    /*3*/ f.physical_name,
    /*4*/ [f].[type_desc],
    /*5*/ [Size_MB] =    CASE
                            WHEN LEN(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 8
                                THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),9,0,','),6,0,','))
                            WHEN LEN(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 5 
                                THEN REVERSE(STUFF(REVERSE(CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),6,0,','))
                            ELSE CAST(CAST(([f].[size] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))
                        END,
    /*6*/ [Used_MB] =    CASE
                            WHEN LEN(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 8 
                                THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),9,0,','),6,0,','))
                            WHEN LEN(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))) > 5
                                THEN REVERSE(STUFF(REVERSE(CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))),6,0,','))
                            ELSE CAST(CAST(([f].[Used_Pages] / 128.0) AS DECIMAL(10,1)) AS VARCHAR(27))
                        END,
    /*7*/ [Free_MB] =    CASE
                            WHEN LEN(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))) > 8 
                                THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))),9,0,','),6,0,','))
                            WHEN LEN(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))) > 5
                                THEN REVERSE(STUFF(REVERSE(CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))),6,0,','))
                            ELSE CAST(CAST((([f].[size] / 128.0) - ([f].[Used_Pages] / 128.0)) AS DECIMAL(10,1)) AS VARCHAR(27))
                        END,
    /*8*/ [% free] =    CASE 
                            WHEN [f].[size] != 0 THEN CAST((CAST(([f].[size] - [f].[Used_Pages]) AS DECIMAL(10,1)) / CAST([f].[size] AS DECIMAL(10,1)) * 100) AS DECIMAL(4,1))
                            ELSE 0.0
                        END,
    /*9*/ [Autogrowth] =    CASE [f].[is_percent_growth]
                                WHEN 0 THEN CAST(([f].[growth] / 128) AS VARCHAR(10)) + ' MB'
                                WHEN 1 THEN CAST([f].[growth] AS VARCHAR(3)) + ' %'
                            END,
    /*10*/ [max_size] =   CASE [f].[max_size]
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
    /*11*/ [Drive] =    LEFT([f].[physical_name],3),
    /*12*/ [Capacity_MB] =    CASE
                                WHEN LEN(CAST([d].[Capacity_MB] AS VARCHAR(27))) > 6 
                                    THEN REVERSE(STUFF(STUFF(REVERSE(CAST([d].[Capacity_MB] AS VARCHAR(27))),7,0,','),4,0,','))
                                WHEN LEN(CAST([d].[Capacity_MB] AS VARCHAR(27))) > 3 
                                    THEN REVERSE(STUFF(REVERSE(CAST([d].[Capacity_MB] AS VARCHAR(27))),4,0,','))
                                ELSE CAST([d].[Capacity_MB] AS VARCHAR(27))
                            END,
    /*13*/ [Used_MB] =    CASE
                            WHEN LEN(CAST(([d].[Capacity_MB] - [d].[FreeSpace_MB]) AS VARCHAR(27))) > 6 
                                THEN REVERSE(STUFF(STUFF(REVERSE(CAST(([d].[Capacity_MB] - [d].[FreeSpace_MB]) AS VARCHAR(27))),7,0,','),4,0,','))
                            WHEN LEN(CAST(([d].[Capacity_MB] - [d].[FreeSpace_MB]) AS VARCHAR(27))) > 3
                                THEN REVERSE(STUFF(REVERSE(CAST(([d].[Capacity_MB] - [d].[FreeSpace_MB]) AS VARCHAR(27))),4,0,','))
                            ELSE CAST(([d].[Capacity_MB] - [d].[FreeSpace_MB]) AS VARCHAR(27))
                        END,
    /*14*/ [FreeSpace_MB] =    CASE
                                WHEN LEN(CAST([d].[FreeSpace_MB] AS VARCHAR(27))) > 6 
                                    THEN REVERSE(STUFF(STUFF(REVERSE(CAST([d].[FreeSpace_MB] AS VARCHAR(27))),7,0,','),4,0,','))
                                WHEN LEN(CAST([d].[FreeSpace_MB] AS VARCHAR(27))) > 3
                                    THEN REVERSE(STUFF(REVERSE(CAST([d].[FreeSpace_MB] AS VARCHAR(27))),4,0,','))
                                ELSE CAST([d].[FreeSpace_MB] AS VARCHAR(27))
                            END,
    /*15*/ [% Free] = CAST(([d].[FreeSpace_MB] / (1.0 * [d].[Capacity_MB]) * 100) AS DECIMAL(4,1)),
    /*16*/ [usp_FileGrowth @where] = 'sqlservername = ''''' + @@SERVERNAME + ''''' AND databasename = ''''' + [f].[Database] +''''' AND DatabaseFileName = ''''' + [f].[name] + ''''''
FROM 
    #FileInfo AS [f]
INNER JOIN
    #DriveInfo AS [d]
    ON LEFT([f].[physical_name],1) = [d].[Drive]
WHERE [f].[type_desc] != 'FILESTREAM' 
    --AND /*File <10% free*/ CAST((CAST(([f].[size] - [f].[Used_Pages]) AS DECIMAL(10,1)) / CAST([f].[size] AS DECIMAL(10,1)) * 100) AS DECIMAL(4,1)) <= 10
    --AND [f].[type_desc] = 'LOG'
    --AND [d].[Drive] = 'G'
    --AND [f].[Database] = 'SSISDB'
    --AND [f].[name] IN ('Siplace_Explorer_4701A_Data','Siplace_Explorer_4701A_Log','Siplace_Explorer_4701B_Data','Siplace_Explorer_4701B_Log','Siplace_Explorer_4701C_Data','Siplace_Explorer_4701C_Log','Siplace_Explorer_4701D_Data','Siplace_Explorer_4701D_Log','Siplace_Explorer_4701E_Data','Siplace_Explorer_4701E_Log','Siplace_Explorer_4701F_Data','Siplace_Explorer_4701F_Log','Siplace_Explorer_4701G_Data','Siplace_Explorer_4701G_Log','Siplace_Explorer_Factory_Data','Siplace_Explorer_Factory_Log')
ORDER BY 
    1, 2;  -- Database, File
    --8;  -- File_PctFree;
    --15; -- Drive_PctFree;
    --11, 1, 2  -- Drive, Database_Name, [File_Name];
    --f.size
/*

ALTER DATABASE [Label_Integration_QA] MODIFY FILE ( NAME = N'Label_Integation', MAXSIZE = UNLIMITED );



*/
------------------------------------------------------------------------------------------
--// DISPLAY FILE SIZE SUMS FOR EACH DRIVE                                            //--
------------------------------------------------------------------------------------------

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



------------------------------------------------------------------------------------------
--// CLEAN UP                                                                         //--
------------------------------------------------------------------------------------------

IF @ole = 0
BEGIN
    EXECUTE [master].[dbo].[sp_configure] @configname  = 'Ole Automation Procedures',
                                          @configvalue = 0;
    RECONFIGURE WITH OVERRIDE;

    IF @advanced = 0
    BEGIN
        EXECUTE [master].[dbo].[sp_configure] @configname  = 'show advanced options',
                                                @configvalue = 0;
        RECONFIGURE WITH OVERRIDE;
    END;
END;

DROP TABLE #FileInfo;
DROP TABLE #DriveInfo;


