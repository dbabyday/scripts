/**********************************************************************************************************
* 
* FILES_Info.sql
* 
* Original Script: Lee Hart
* Modified By: James Lutsey
* Date: 01/12/2016
* 
* Purpose: Shows the size, space used, space free, percent free, and autogrowth setting of files and 
*          the drive it is on.
* 
* Note: You can filter the resutls in the final query (starting on line 305).
* 
**********************************************************************************************************/

SET NOCOUNT ON

DECLARE 
    @SQLCmd             NVARCHAR(4000),
    @Result             INT,
    @FSO                INT,
    @DriveLetter        CHAR(1),
    @DriveNameOut       INT,
    @TotalSizeOut       VARCHAR(20), 
    @MB                 NUMERIC,
    @dbname             VARCHAR(128),
    @SelectedId         INT,
    @MaxId              INT,
    @TotalExtents       INT,
    @UsedExtents        INT,
    @FileId             INT,
    @FileTypeDesc       NVARCHAR(60),
    @LogSize            DECIMAL(10,2),
    @LogUsedPct         DECIMAL(4,1),
    @FileSize           VARCHAR(10),
    @FileSpaceUsed      VARCHAR(10),
    @FileSpaceFree      VARCHAR(10),
    @FilePctFree        VARCHAR(10),
    @Drive              VARCHAR(3),
    @DriveSize          INT,
    @DriveFreeSpace     INT;

SET @MB = 1048576;

DECLARE @tb_drives TABLE 
(
    Drive       CHAR(1) PRIMARY KEY, 
    FreeSpace   INT     NULL,
    TotalSize   INT     NULL
)

DECLARE @tb_db_show_file_stats TABLE
(
    row_id          INT IDENTITY(1,1),
    dbname          NVARCHAR(255),
    fileid          INT,
    filegroup       INT,
    totalextents    INT,
    usedextents     INT,
    name            VARCHAR(255),
    filename        VARCHAR(255) 
) 

DECLARE @tb_database_logsize_and_percent_used TABLE
(
    row_id                      INT IDENTITY(1,1),
    dbname                      NVARCHAR(255),
    log_size_mb                 DECIMAL(10,2),
    log_space_used_percent      DECIMAL(4,1),
    status                      INT
)

DECLARE @tb_results TABLE
(
    ID                  INT IDENTITY(1,1) PRIMARY KEY,
    Database_Id         INT,
    Database_Name       VARCHAR(128),
    File_Id             INT,
    [File_Name]         VARCHAR(128),
    File_TypeDesc       NVARCHAR(60),
    File_Size_MB        VARCHAR(10),
    File_Used_MB        VARCHAR(10),
    File_Free_MB        VARCHAR(10),
    File_PctFree        VARCHAR(10),
    File_Autogrow       VARCHAR(25),
    File_MaxSize        VARCHAR(25),
    Drive               CHAR(3),
    Drive_Size_MB       INT,
    Drive_Used_MB       INT,
    Drive_Free_MB       INT,
    Drive_PctFree       DECIMAL(4,1)
)


------------------------------------------------------------------------------------------
--// ADD AUTOGROWTH SETTINGS TO RESULTS TABLE                                         //--
------------------------------------------------------------------------------------------
INSERT INTO @tb_results (Database_Id, Database_Name, File_Id, [File_Name], File_TypeDesc, File_Autogrow, File_MaxSize, Drive)
SELECT 
    f.database_id,
    DB_NAME(f.database_id),
    f.file_id,
    f.name,
    f.type_desc,
    CASE f.is_percent_growth
        WHEN 0 THEN CAST(f.growth * 8 / 1024 AS VARCHAR(15)) + ' MB'
        WHEN 1 THEN CAST(f.growth AS VARCHAR(15)) + ' %'
    END,
    CASE f.max_size
        WHEN 0 THEN 'no growth allowed'
        WHEN -1 THEN 'until disk is full'
        WHEN 268435456 THEN 'up to 2TB'
        ELSE CAST((f.max_size * 8 / 1024) AS VARCHAR(15)) + ' MB'
    END,
    LEFT(f.physical_name, 1) + ':\'
FROM 
    master.sys.master_files AS f
JOIN
    master.sys.databases AS d
	ON d.database_id = f.database_id
WHERE
    d.state = 0  -- 0 = ONLINE
    AND type_desc IN ('ROWS', 'LOG');


------------------------------------------------------------------------------------------
--// GET DRIVE SPACE INFO                                                             //--
------------------------------------------------------------------------------------------
INSERT @tb_drives(Drive,FreeSpace) 
EXEC master.dbo.xp_fixeddrives 

EXEC @Result = sp_OACreate
                    'Scripting.FileSystemObject',
                    @FSO OUT 
                   
IF @Result <> 0 
    EXEC sp_OAGetErrorInfo @FSO

DECLARE dcur CURSOR LOCAL FAST_FORWARD
FOR SELECT Drive FROM @tb_drives ORDER by Drive

OPEN dcur 
FETCH NEXT FROM dcur INTO @DriveLetter

WHILE @@FETCH_STATUS=0
BEGIN

    EXEC @Result = sp_OAMethod @FSO,'GetDrive', @DriveNameOut OUT, @DriveLetter

    IF @Result <> 0 
        EXEC sp_OAGetErrorInfo @FSO 
            
    EXEC @Result = sp_OAGetProperty
                        @DriveNameOut,
                        'TotalSize', 
                        @TotalSizeOut OUT 
                     
    IF @Result <> 0 
        EXEC sp_OAGetErrorInfo @DriveNameOut 
            
    UPDATE @tb_drives 
        SET TotalSize = @TotalSizeOut / @MB 
        WHERE Drive = @DriveLetter 

    FETCH NEXT FROM dcur INTO @DriveLetter

END

CLOSE dcur
DEALLOCATE dcur

EXEC @Result = sp_OADestroy @FSO 

IF @Result <> 0 
    EXEC sp_OAGetErrorInfo @FSO


------------------------------------------------------------------------------------------
--// GET DATA FILE INFO                                                               //--
------------------------------------------------------------------------------------------
SET     @dbname = '';

WHILE @dbname IS NOT NULL
BEGIN
    SELECT  @dbname = MIN(Database_Name)
    FROM    @tb_results
    WHERE   Database_Name > @dbname

    IF @dbname IS NOT NULL
    BEGIN
        SELECT @SQLCmd = 'USE [' + @dbname + ']; DBCC SHOWFILESTATS WITH NO_INFOMSGS'
        INSERT INTO @tb_db_show_file_stats (fileid, filegroup, totalextents, usedextents, name, filename) EXEC sp_executesql @SQLCmd

        UPDATE  @tb_db_show_file_stats
        SET     dbname = @dbname
        WHERE   dbname IS NULL
    END
END


------------------------------------------------------------------------------------------
--// GET LOG SPACE INFO                                                               //--
------------------------------------------------------------------------------------------
INSERT INTO @tb_database_logsize_and_percent_used EXEC ('dbcc sqlperf(logspace) WITH NO_INFOMSGS')


------------------------------------------------------------------------------------------
--// ADD FILE AND DRIVE METRICS TO THE RESULTS TABLE                                  //--
------------------------------------------------------------------------------------------
SET @SelectedId = 1;
SELECT @MaxId = MAX(ID) FROM @tb_results;

WHILE @SelectedId <= @MaxId
BEGIN
    
    SELECT 
        @dbname       = Database_Name,
        @FileId       = File_Id,
        @FileTypeDesc = File_TypeDesc
    FROM 
        @tb_results 
    WHERE 
        ID = @SelectedId;

    -- get the data file metrics
    IF (@FileTypeDesc = 'ROWS')
    BEGIN

        SELECT 
            @TotalExtents = totalextents,
            @UsedExtents  = usedextents
        FROM
            @tb_db_show_file_stats
        WHERE
            dbname = @dbname
            AND fileid = @FileId;

        SET @FileSize       = STR(SUM((@TotalExtents * 64.0) / 1024.0), 10, 1);
        SET @FileSpaceUsed  = STR(SUM((@UsedExtents  * 64.0) / 1024.0), 10, 1);
        SET @FileSpaceFree  = STR(SUM((@TotalExtents - @UsedExtents)  * 64.0 / 1024.0), 10, 1);
        SET @FilePctFree    = STR(SUM((((@TotalExtents - @UsedExtents)  * 64.0) / 1024.0 * 100.0 / ((@TotalExtents * 64.0) / 1024.0))), 10, 1);
    END
    -- get the log file metrics
    ELSE IF (@FileTypeDesc = 'LOG')
    BEGIN

        SELECT
            @LogSize = log_size_mb,
            @LogUsedPct = log_space_used_percent
        FROM
            @tb_database_logsize_and_percent_used
        WHERE
            dbname = @dbname;

        SET @FileSize       = STR(@LogSize, 10, 1);
        SET @FileSpaceUsed  = STR(@LogSize * @LogUsedPct / 100, 10, 1);
        SET @FileSpaceFree  = STR(@LogSize - (@LogSize * @LogUsedPct / 100), 10, 1);
        SET @FilePctFree    = STR(100 - @LogUsedPct, 10, 1);
        
    END

    -- get the drive metrics
    SELECT 
        @DriveSize      = d.TotalSize,
        @DriveFreeSpace = d.FreeSpace
    FROM
        @tb_results AS r
    JOIN
        @tb_drives AS d
        ON d.Drive = LEFT(r.Drive, 1)
    WHERE
        r.ID = @SelectedId

    -- insert the file and drive metrics
    UPDATE @tb_results
    SET
        File_Size_MB    = @FileSize,
        File_Used_MB    = @FileSpaceUsed,
        File_Free_MB    = @FileSpaceFree,
        File_PctFree    = @FilePctFree,
        Drive_Size_MB   = @DriveSize,
        Drive_Used_MB   = @DriveSize - @DriveFreeSpace,
        Drive_Free_MB   = @DriveFreeSpace,
        Drive_PctFree   = CAST(CAST(@DriveFreeSpace AS NUMERIC) / CAST(@DriveSize AS NUMERIC) * 100 AS DECIMAL(4,1))
    WHERE
        ID = @SelectedId;

    SET @SelectedId = @SelectedId + 1;
END


------------------------------------------------------------------------------------------
--// DISPLAY THE RESULTS                                                              //--
------------------------------------------------------------------------------------------
SELECT
    Database_Name,
    [File_Name],
    File_TypeDesc,
    File_Size_MB,
    File_Used_MB,
    File_Free_MB,
    File_PctFree,
    File_Autogrow,
    File_MaxSize,
    Drive,
    Drive_Size_MB,
    Drive_Used_MB,
    Drive_Free_MB,
    Drive_PctFree,
	'sqlservername = ''''' + @@SERVERNAME + ''''' AND databasename = ''''' + Database_Name +''''' AND DatabaseFileName = ''''' + [File_Name] + '''''' AS 'FILES_Growth.sql WHERE'
FROM 
    @tb_results
--WHERE
--    CAST(File_PctFree AS DECIMAL(5,2)) <= 10
	--AND
	--File_TypeDesc = 'LOG'
	--AND
	--Drive = 'C:\'
	--AND
	--Database_Name = ''
ORDER BY 
    Database_Name, [File_Name];
    --File_PctFree;
    --Drive_PctFree;
    --Drive, Database_Name, [File_Name];
