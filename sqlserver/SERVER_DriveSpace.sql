SET NOCOUNT ON;

DECLARE 
    @Result       INT,
    @FSO          INT,
    @DriveLetter  CHAR(1),
    @DriveNameOut INT,
    @TotalSizeOut VARCHAR(20),
    @MB           NUMERIC; 

SET @MB = 1048576;

DECLARE @tb_drives TABLE 
(
    Drive       CHAR(1) PRIMARY KEY, 
    FreeSpace   INT     NULL,
    TotalSize   INT     NULL
) 

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

SELECT
    Drive, 
    TotalSize AS 'Capacity(MB)', 
	TotalSize - FreeSpace AS 'Used(MB)',
    FreeSpace AS 'Free(MB)',
    CAST(CAST(FreeSpace AS NUMERIC) / CAST(TotalSize AS NUMERIC) * 100 AS DECIMAL(4,1)) AS 'PercentFree'
FROM 
    @tb_drives
--WHERE 
--    CAST(CAST(FreeSpace AS NUMERIC) / CAST(TotalSize AS NUMERIC) * 100 AS DECIMAL(4,1)) < 10.0
--    AND [Drive] <> 'D'
ORDER BY 
    Drive 

GO