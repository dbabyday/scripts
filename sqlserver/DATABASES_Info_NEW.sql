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
    row_id                            INT IDENTITY(1,1),
    dbname                            NVARCHAR(255),
    fileid                            INT,
    filegroup                         INT,
    totalextents                      INT,
    usedextents                       INT,
    name                              VARCHAR(255),
    filename                          VARCHAR(255) 
) 

DECLARE @tb_database_logsize_and_percent_used TABLE
(
    row_id                            INT IDENTITY(1,1),
    dbname                            NVARCHAR(255),
    log_size_mb                       DECIMAL(10,2),
    log_space_used_percent            DECIMAL(4,1),
    status                            INT
)

DECLARE @tb_results TABLE
(
    ID                  INT IDENTITY(1,1) PRIMARY KEY,
    Database_Id         INT,
    Database_Name       VARCHAR(128),
    File_Id             INT,
    File_Name           VARCHAR(128),
    File_TypeDesc       NVARCHAR(60),
    File_Size_MB        VARCHAR(10),
    File_SpaceUsed      VARCHAR(10),
    File_SpaceFree      VARCHAR(10),
    File_PctFree        VARCHAR(10),
    File_Autogrow       VARCHAR(25),
    File_MaxSize        VARCHAR(25),
    Drive               VARCHAR(3),
    Drive_Size_MB       INT,
    Drive_FreeSpace     INT,
    Drive_PctFree       DECIMAL(4,1)
)

-- autogrowth settings
--------------------------------------------------------------------------------------
INSERT INTO @tb_results (Database_Id, Database_Name, File_Id, File_Name, File_TypeDesc, File_Autogrow, File_MaxSize)
SELECT 
    database_id,
    DB_NAME(database_id),
    file_id,
    name,
    type_desc,
    CASE is_percent_growth
        WHEN 0 THEN CAST(growth * 8 / 1024 AS varchar(15)) + ' MB'
        WHEN 1 THEN CAST(growth AS varchar(15)) + ' %'
    END,
    CASE max_size
        WHEN 0 THEN 'no growth allowed'
        WHEN -1 THEN 'until disk is full'
        WHEN 268435456 THEN 'up to 2TB'
        ELSE CAST(max_size AS varchar(15)) + ' MB'
    END
FROM 
    sys.master_files
WHERE
    type_desc IN ('ROWS', 'LOG');


-- drive space info
--------------------------------------------------------------------------------------
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


-- loop through databases and load file stats table with information for each database
--------------------------------------------------------------------------------------
SET     @dbname = '';

WHILE @dbname IS NOT NULL
BEGIN
    SELECT  @dbname = MIN(Database_Name)
    FROM    @tb_results
    WHERE   Database_Name > @dbname

    IF @dbname IS NOT NULL
    BEGIN
        SELECT          @SQLCmd = 'USE [' + @dbname + ']; DBCC SHOWFILESTATS WITH NO_INFOMSGS'
        INSERT INTO     @tb_db_show_file_stats (fileid, filegroup, totalextents, usedextents, name, filename) EXEC sp_executesql @SQLCmd

        UPDATE  @tb_db_show_file_stats
        SET     dbname = @dbname
        WHERE   dbname IS NULL
    END
END


-- add log space info to the mix
--------------------------------------------------------------------------------------
INSERT INTO @tb_database_logsize_and_percent_used EXEC ('dbcc sqlperf(logspace) WITH NO_INFOMSGS')


-- add file and drive metrics to the results table
--------------------------------------------------------------------------------------
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

        SET @FileSize      = STR(SUM((@TotalExtents * 64.0) / 1024.0), 10, 1);
        SET @FileSpaceUsed = STR(SUM((@UsedExtents  * 64.0) / 1024.0), 10, 1);
        SET @FileSpaceFree = STR(SUM((@TotalExtents - @UsedExtents)  * 64.0 / 1024.0), 10, 1);
        SET @FilePctFree   = STR(SUM((((@TotalExtents - @UsedExtents)  * 64.0) / 1024.0 * 100.0 / ((@TotalExtents * 64.0) / 1024.0))), 10, 1);
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

        SET @FileSize      = STR(@LogSize, 10, 1);
        SET @FileSpaceUsed = STR(@LogSize * @LogUsedPct / 100, 10, 1);
        SET @FileSpaceFree = STR(@LogSize - (@LogSize * @LogUsedPct / 100), 10, 1);
        SET @FilePctFree   = STR(100 - @LogUsedPct, 10, 1);
        
    END

    -- get the drive metrics
    SELECT 
        @Drive          = LEFT(f.filename, 3),
        @DriveSize      = d.TotalSize,
        @DriveFreeSpace = d.FreeSpace
    FROM
        @tb_db_show_file_stats AS f
    JOIN
        @tb_drives AS d
        ON d.Drive = LEFT(f.filename, 1)
    WHERE
        dbname = @dbname
        AND fileid = @FileId;

    -- insert the file and drive metrics
    UPDATE @tb_results
    SET
        File_Size_MB    = @FileSize,
        File_SpaceUsed  = @FileSpaceUsed,
        File_SpaceFree  = @FileSpaceFree,
        File_PctFree    = @FilePctFree,
        Drive           = @Drive,
        Drive_Size_MB   = @DriveSize,
        Drive_FreeSpace = @DriveFreeSpace,
        Drive_PctFree   = CAST(CAST(@DriveFreeSpace AS NUMERIC) / CAST(@DriveSize AS NUMERIC) * 100 AS DECIMAL(4,1))
    WHERE
        ID = @SelectedId;

    SET @SelectedId = @SelectedId + 1;
END


-- display the resutls
--------------------------------------------------------------------------------------
SELECT
    Database_Name,
    File_Name,
    File_TypeDesc,
    File_Size_MB,
    File_SpaceUsed,
    File_SpaceFree,
    File_PctFree,
    File_Autogrow,
    File_MaxSize,
    Drive,
    Drive_Size_MB,
    Drive_FreeSpace,
    Drive_PctFree
FROM 
    @tb_results
ORDER BY
    File_PctFree ASC;
    --Drive_PctFree ASC;
