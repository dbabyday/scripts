/**********************************************************************
* 
* SERVER_LogDriveSizingForEmergencies.sql
* 
* Author: James Lutsey
* Date:   2017-12-21
* 
* Purpose: Calculate the needed space for log files to grow for 3 days 
*          in case of emergency.
* 
**********************************************************************/

SET NOCOUNT ON;

DECLARE @advanced     AS BIT,
        @capacity     AS BIGINT,
        @driveLetter  AS CHAR(1),
        @driveNameOut AS INT,
        @fileSizeSum  AS BIGINT,
        @freespace    AS BIGINT,
        @fso          AS INT,
        @logDrive     AS CHAR(1),
        @logDriveQty  AS INT,
        @ole          AS BIT,
        @result       AS INT,
        @spaceForLogFiles AS BIGINT,
        @spaceUsedOther AS BIGINT,
        @start        AS DATETIME2(3),
        @threeDaysSpace AS BIGINT,
        @threeDaysSpace_check AS BIGINT,
        @totalSizeOut AS VARCHAR(20);

IF OBJECT_ID(N'tempdb..#DriveInfo',N'U') IS NOT NULL DROP TABLE #DriveInfo;
CREATE TABLE #DriveInfo
(
    Drive          CHAR(1) NOT NULL PRIMARY KEY, 
    FreeSpace_MB   BIGINT  NOT NULL,
    Capacity_Bytes BIGINT  NULL
);

DECLARE curDrives CURSOR LOCAL FAST_FORWARD FOR
    SELECT Drive
    FROM #DriveInfo;


------------------------------------------------------------------------------------------
--// FIND THE LOG DRIVE                                                               //--
------------------------------------------------------------------------------------------

SELECT @logDriveQty = COUNT(*) 
FROM   (   SELECT LEFT(physical_name,1) AS [letter]
           FROM sys.master_files 
           WHERE DB_NAME(database_id) NOT IN ('master','model','msdb','tempdb') 
                 AND TYPE = 1
           GROUP BY LEFT(physical_name,1)
        ) AS [LogDrive];

IF @logDriveQty > 1
BEGIN
    RAISERROR('Log files are on multiple drives...more detailed analysis will need to be done',16,1) WITH NOWAIT;
    SET NOEXEC ON;
END;

SELECT   @logDrive = LEFT(physical_name,1),
         @fileSizeSum = CAST(ROUND(SUM(size) / 128.0 / 1024, 0) AS BIGINT)
FROM     sys.master_files 
WHERE    DB_NAME(database_id) NOT IN ('master','model','msdb','tempdb') 
         AND TYPE = 1
GROUP BY LEFT(physical_name,1);



------------------------------------------------------------------------------------------
--// GET THE DRIVE SIZE                                                               //--
------------------------------------------------------------------------------------------

-- get ole automation procedures configuration
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
        EXECUTE master.dbo.sp_configure @configname  = 'show advanced options',
                                              @configvalue = 1;
        RECONFIGURE WITH OVERRIDE;
    END;
    
    EXECUTE master.dbo.sp_configure @configname  = 'Ole Automation Procedures',
                                          @configvalue = 1;
    RECONFIGURE WITH OVERRIDE;
END;

-- get drives and free space
INSERT #DriveInfo ([Drive],[FreeSpace_MB]) 
EXECUTE master.dbo.xp_fixeddrives;

EXECUTE @result = sp_OACreate 'Scripting.FileSystemObject', @fso OUT; 
IF (@result <> 0) 
BEGIN
    EXECUTE sp_OAGetErrorInfo @fso;
    SET NOEXEC ON;
END;

OPEN curDrives;
    FETCH NEXT FROM curDrives INTO @driveLetter;

    WHILE @@FETCH_STATUS=0
    BEGIN
        EXECUTE @result = sp_OAMethod @fso,'GetDrive', @driveNameOut OUT, @driveLetter;
        IF @result <> 0 
        BEGIN
            EXECUTE sp_OAGetErrorInfo @fso;
            SET NOEXEC ON;
        END;
            
        EXECUTE @result = sp_OAGetProperty @driveNameOut, 'TotalSize', @totalSizeOut OUT;
        IF @result <> 0 
        BEGIN
            EXECUTE sp_OAGetErrorInfo @driveNameOut; 
            SET NOEXEC ON;
        END;
  
        UPDATE #DriveInfo 
        SET    Capacity_Bytes = CAST(@totalSizeOut AS BIGINT)
        WHERE  Drive = @driveLetter; 

        FETCH NEXT FROM curDrives INTO @driveLetter;
    END
CLOSE curDrives;
DEALLOCATE curDrives;

EXECUTE @result = sp_OADestroy @fso; 
IF @result <> 0 
BEGIN
    EXECUTE sp_OAGetErrorInfo @fso;
    SET NOEXEC ON;
END;

SELECT @capacity  = CAST(ROUND(Capacity_Bytes / 1024.0 / 1024.0 / 1024.0, 0) AS BIGINT),
       @freespace = CAST(ROUND(FreeSpace_MB / 1024.0, 0) AS INT)
FROM   #DriveInfo
WHERE  Drive = @logDrive;



------------------------------------------------------------------------------------------
--// GET THE AMOUNT OF SPACE NEEDED BASED ON LOG BACKUP SIZES                         //--
------------------------------------------------------------------------------------------

-- check the backup history for th largest 3 days span; increment by 1 hour to check all ranges
SELECT @start = MIN(backup_start_date)
FROM   msdb.dbo.backupset;

SET @threeDaysSpace = 0;

WHILE DATEADD(DAY,3,@start) <= GETDATE()
BEGIN
    --                                                   bytes           kb        mb       gb 
    SELECT     @threeDaysSpace_check = CAST(ROUND(SUM(s.backup_size) / 1024.0 / 1024.0 / 1024.0, 0) AS BIGINT)
    FROM       msdb.dbo.backupset s
    WHERE      s.backup_start_date >= @start
               AND s.backup_start_date < DATEADD(DAY,3,@start)
               AND s.[type] = 'L';    

    IF @threeDaysSpace_check > @threeDaysSpace
        SET @threeDaysSpace = @threeDaysSpace_check;

    -- print the sizes for all the time ranges checked
    --PRINT CONVERT(NCHAR(19),@start,120) + N' - ' + CONVERT(NCHAR(19),DATEADD(DAY,3,@start),120) + N' | ' + CAST(@threeDaysSpace_check AS NVARCHAR(20)) + N' GB';
    
    SET @start = DATEADD(HOUR,1,@start);
END;
    

------------------------------------------------------------------------------------------
--// CALCULATIONS AND DISPLAY                                                         //--
------------------------------------------------------------------------------------------

SET @spaceUsedOther   = @capacity - @fileSizeSum - @freespace;
SET @spaceForLogFiles = @fileSizeSum + @freespace;

SELECT @@SERVERNAME    AS [ServerName],
       @logDrive       AS [LogDrive],
       @capacity       AS [Capacity_GB],
       @threeDaysSpace AS [ThreeDaysSpace_GB],
       @freespace      AS [FreeSpace_GB],
       @spaceUsedOther AS [OtherStuff_GB],
       CASE
           WHEN @threeDaysSpace <= @spaceForLogFiles THEN 'None - the drive has enough capacity for 3 days of log growth.'
           WHEN (@threeDaysSpace > @spaceForLogFiles) AND (@threeDaysSpace <= @capacity) THEN 'Free up space and/or grow drive.'
           WHEN @threeDaysSpace > @capacity THEN 'Grow the drive.'
           ELSE 'Something happened that I didn''t count for...'
       END             AS [Action]



------------------------------------------------------------------------------------------
--// CLEAN UP                                                                         //--
------------------------------------------------------------------------------------------

SET NOEXEC OFF;
IF OBJECT_ID(N'tempdb..#DriveInfo',N'U') IS NOT NULL DROP TABLE #DriveInfo;

