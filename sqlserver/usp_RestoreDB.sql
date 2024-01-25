use CentralAdmin;
go
CREATE OR ALTER PROCEDURE dbo.usp_RestoreDB
	  @dbName                VARCHAR(128)  = ''
	, @pointInTime           DATETIME      = ''
	, @path                  NVARCHAR(512) = ''
	, @replace               CHAR(1)       = 'N'
	, @newDataFileLocation   VARCHAR(255)  = ''
	, @newLogFileLocation    VARCHAR(255)  = ''
	, @newFilestreamLocation VARCHAR(255)  = ''
	, @newFulltextLocation   VARCHAR(255)  = ''
	, @newDBName             VARCHAR(128)  = ''
	, @selectBackupInfo      CHAR(1)       = 'N'
	, @help                  VARCHAR(25)   = ''
	, @getVersion            BIT           = 0
AS

SET NOCOUNT ON;

-- if null is passed to a parameter, reset it to the default value
IF @dbName                IS NULL SET @dbName                = '';
IF @pointInTime           IS NULL SET @pointInTime           = '';
IF @path                  IS NULL SET @path                  = '';
IF @replace               IS NULL SET @replace               = '';
IF @newDataFileLocation   IS NULL SET @newDataFileLocation   = '';
IF @newLogFileLocation    IS NULL SET @newLogFileLocation    = '';
IF @newFilestreamLocation IS NULL SET @newFilestreamLocation = '';
IF @newFulltextLocation   IS NULL SET @newFulltextLocation   = '';
IF @newDBName             IS NULL SET @newDBName             = '';
IF @selectBackupInfo      IS NULL SET @selectBackupInfo      = '';
IF @help                  IS NULL SET @help                  = '';
IF @getVersion            IS NULL SET @getVersion            = 0;

DECLARE 
	  @append_2            CHAR(1)
	, @backupCommand       VARCHAR(MAX)
	, @backupIdFull        INT
	, @backupIdDiff        INT
	, @backupStartDate     DATETIME
	, @cmd                 VARCHAR(1000)
	, @databaseBackupLSN   NUMERIC(25,0)
	, @depth               INT
	, @depthChange         INT
	, @depthPrevious       INT
	, @diffApplicable      CHAR(1)
	, @dtString            VARCHAR(25)
	, @errorMessage        VARCHAR(MAX)
	, @file                VARCHAR(255)
	, @firstFullTime       DATETIME
	, @firstLSN            NUMERIC(25,0)
	, @folder              NVARCHAR(512)
	, @id                  INT
	, @lastLSN             NUMERIC(25,0)
	, @lastTrnTime         DATETIME
	, @logicalName         VARCHAR(128)
	, @lsn                 NUMERIC(25,0)
	, @message             VARCHAR(MAX)
	, @moveDataFile        CHAR(1)
	, @moveFilestreamFile  CHAR(1)
	, @moveFulltextFile    CHAR(1)
	, @moveLogFile         CHAR(1)
	, @pathLog             NVARCHAR(512)
	, @pathPossible        NVARCHAR(512)
	, @pathRootEnd         INT
	, @pathStart           INT
	, @physicalName        VARCHAR(255)
	, @physicalNameTrimmed VARCHAR(128)
	, @pointInTimeUser     CHAR(1)
	, @recoveryModel       INT
	, @server              VARCHAR(128)
	, @stopatAdded         BIT
	, @subdirectory        NVARCHAR(512)
	, @tailFile            VARCHAR(255)
	, @type                TINYINT
	, @useTail             CHAR(1)
	, @version             VARCHAR(10);

SET @version = '1.4';  -- SET VERSION HERE -------------------------------------------
	
DECLARE @tb_directoryTree TABLE
(
	  [ID]           INT IDENTITY(1,1) PRIMARY KEY
	, [Subdirectory] NVARCHAR(512)
	, [Depth]        INT
	, [IsFile]       BIT
	, [PhysicalName] NVARCHAR(512)
);

DECLARE @tb_databaseFileList TABLE
(
	  [ID]           INT IDENTITY(1,1) PRIMARY KEY
	, [LogicalName]  VARCHAR(128)
	, [PhysicalName] VARCHAR(255)
	, [Type]         TINYINT -- 0 = Rows, 1 = Log, 2 = FILESTREAM, 4 = Full-text
);

DECLARE @tb_backupInfo TABLE
(
	  [BackupID]               INT IDENTITY(1,1) NOT NULL PRIMARY KEY
	, [NameOfFile]             NVARCHAR(256)
	, [BackupName]             NVARCHAR(128)
	, [BackupDescription]      NVARCHAR(255)
	, [BackupType]             SMALLINT
	, [ExpirationDate]         DATETIME
	, [Compressed]             TINYINT
	, [Position]               SMALLINT
	, [DeviceType]             TINYINT
	, [UserName]               NVARCHAR(128)
	, [ServerName]             NVARCHAR(128)
	, [DatabaseName]           NVARCHAR(128)
	, [DatabaseVersion]        INT
	, [DatabaseCreationDate]   DATETIME
	, [BackupSize]             NUMERIC(20,0)
	, [FirstLSN]               NUMERIC(25,0)
	, [LastLSN]                NUMERIC(25,0)
	, [CheckpointLSN]          NUMERIC(25,0)
	, [DatabaseBackupLSN]      NUMERIC(25,0)
	, [BackupStartDate]        DATETIME
	, [BackupFinishDate]       DATETIME
	, [SortOrder]              SMALLINT
	, [CodePage]               SMALLINT
	, [UnicodeLocaleId]        INT
	, [UnicodeComparisonStyle] INT
	, [CompatibilityLevel]     TINYINT
	, [SoftwareVendorId]       INT
	, [SoftwareVersionMajor]   INT
	, [SoftwareVersionMinor]   INT
	, [SoftwareVersionBuild]   INT
	, [MachineName]            NVARCHAR(128)
	, [Flags]                  INT
	, [BindingID]              UNIQUEIDENTIFIER
	, [RecoveryForkID]         UNIQUEIDENTIFIER
	, [Collation]              NVARCHAR (128)
	, [FamilyGUID]             UNIQUEIDENTIFIER
	, [HasBulkLoggedData]      BIT
	, [IsSnapshot]             BIT
	, [IsReadOnly]             BIT
	, [IsSingleUser]           BIT
	, [HasBackupChecksums]     BIT
	, [IsDamaged]              BIT
	, [BeginsLogChain]         BIT
	, [HasIncompleteMetaData]  BIT
	, [IsForceOffline]         BIT
	, [IsCopyOnly]             BIT
	, [FirstRecoveryForkId]    UNIQUEIDENTIFIER
	, [ForkPointLSN]           NUMERIC(25,0)
	, [RecoveryModel]          NVARCHAR(60)
	, [DifferentialBaseLSN]    NUMERIC(25, 0)
	, [DifferentialBaseGUID]   UNIQUEIDENTIFIER
	, [BackupTypeDescription]  NVARCHAR (60)
	, [BackupSetGUID]          UNIQUEIDENTIFIER
	, [CompressedBackupSize]   BIGINT
	, [Containment]            TINYINT
	, [KeyAlgorithm]           NVARCHAR(32)
	, [EncryptorThumbprint]    VARBINARY(20)
	, [EncryptorType]          NVARCHAR(32)
);


------------------------------------------------------------------------------------------
--// CHECK/SET INITIAL INFO                                                           //--
------------------------------------------------------------------------------------------

-- return the version if requested
IF @getVersion = 1 
BEGIN
	SELECT @version AS 'version';
	RETURN;
END

-- return help info if requested
IF (@help != '') AND (UPPER(@help) != 'N') AND (UPPER(@help) != 'NO')
BEGIN
	SET @message = '
/**********************************************************************************************************
* 
* usp_RestoreDB v' + @version + '
* 
* Author: James Lutsey
* Date: 05/10/2016
* 
* Purpose: Print the restore commands for a database
* 
* Notes: 
*     1. REQUIRED: You must enter a database name
*     2. OPTIONAL: You may enter a point in time. If not entered, the commands for the last backup time will be printed.
*     3. OPTIONAL: You may enter the path of the backup folder. If not entered, the location of the Ola backup commands will be used.
*     4. OPTIONAL: To use the ''WITH REPLACE'' command, change @replace to ''Y''
*     5. OPTIONAL: If you are moving the database, enter the new locations for the data and log files 
*     6. OPTIONAL: Set @newDBName to give the restored database a new name 
*
* Troubleshooting:
*     1. If no files are found, verify the folder path, and that the SQL Server service account has access
*     2. MOVE arguments will only be printed if running on the source server (needs to find files from sys.master_files)
*     3. Does not work on CO-DB-010 & CO-DB-017
*     4. Get the version: EXECUTE [CentralAdmin].[dbo].[usp_RestoreDB] @getVersion = 1;
* 
* Version History:
*     1.1 - 07/05/2016 - Added check for log backups to correct error if no log backups exist 
*     1.2 - 07/06/2016 - Added option to select backup info (@selectBackupInfo = ''Y'')
*     1.3 - 08/05/2016 - Added conditional statements to handle null values for parameters
*     1.4 - 08/22/2016 - Changed method of connecting log & diff backups to full backup to use DatabaseBackupLSN instead of CheckpointLSN
* 
**********************************************************************************************************/


------------------------------------------------------------------------------------------
--// COMMAND                                                                          //--
------------------------------------------------------------------------------------------

EXECUTE	CentralAdmin.dbo.usp_RestoreDB  --@help = ''Y''
			@dbName = ''''
			--,@pointInTime = ''''
			--,@path = ''''
			--,@replace = ''N''
			--,@newDataFileLocation = ''''
			--,@newLogFileLocation = ''''
			--,@newFilestreamLocation = ''''
			--,@newFulltextLocation = ''''
			--,@newDBName = ''''';

	PRINT @message;	
	RETURN;
END

-- make sure user entered a database
IF (@dbName = '')
BEGIN
	SET @errorMessage = 'You must enter a database name';
	RAISERROR(@errorMessage,16,1) WITH NOWAIT;
	RETURN;
END

-- make sure @replace is 'N' or 'Y'
SET @replace = UPPER(@replace);
IF @replace != 'Y' AND @replace != 'N'
BEGIN
	SET @errorMessage = 'Wrong value for @replace.' + CHAR(13) + CHAR(10);
	SET @errorMessage = '@replace must have a value of ''N'' or ''Y''. The default value is ''N''.';
	RAISERROR(@errorMessage,16,1) WITH NOWAIT;
	RETURN;
END

-- set some initial values
SET    @depthPrevious = 1; -- this will be used to determine the file paths
SELECT @server = @@SERVERNAME;
SELECT @recoveryModel = recovery_model FROM master.sys.databases;  -- 1 = FULL, 2 = BULK_LOGGED, 3 = SIMPLE
SET    @useTail = 'N';  -- this will be set to 'Y' if a log tail backup is taken in the point in time decisions section
SET    @stopatAdded = 0; -- this is used to ensure the correct restore log command includes the stopat argument

-- if user did not specify a point in time, set @pointInTime to now and set the point in time flag to 'N'
IF (@pointInTime = '')
BEGIN
	SELECT @pointInTime = GETDATE();
	SET @pointInTimeUser = 'N';
END
ELSE
	SET @pointInTimeUser = 'Y';

-- set the flags to show if the user entered new locations
IF (@newDataFileLocation = '') SET @moveDataFile = 'N';
ELSE SET @moveDataFile = 'Y';

IF (@newLogFileLocation = '') SET @moveLogFile = 'N';
ELSE SET @moveLogFile = 'Y';

IF (@newFilestreamLocation = '') SET @moveFilestreamFile = 'N';
ELSE SET @moveFilestreamFile = 'Y';

IF (@newFulltextLocation = '') SET @moveFulltextFile = 'N';
ELSE SET @moveFulltextFile = 'Y';


-- set the restored database's name
IF (@newDBName = '')
BEGIN
	SET @newDBName = @dbName;
	SET @append_2 = 'N';
END
ELSE
	SET @append_2 = 'Y';

-- get the database files
INSERT INTO @tb_databaseFileList ([LogicalName], [PhysicalName], [Type])
SELECT [name], [physical_name], [type] FROM [master].[sys].[master_files] WHERE [database_id] = DB_ID(@dbName);

--select * from @tb_databaseFileList


------------------------------------------------------------------------------------------
--// GET PATH TO BACKUP FOLDERS                                                      //--
------------------------------------------------------------------------------------------

-- if path(s) not explicitly set, find the path used by Ola backup commands
IF (@path = '')
BEGIN
	-- root path
	SELECT TOP 1 @backupCommand = [Command] FROM [CentralAdmin].[dbo].[CommandLog] WHERE [Command] LIKE 'BACKUP DATABASE %' AND [Command] LIKE '%' + @server +'%' ORDER BY StartTime DESC;
	SET @pathStart = CHARINDEX('= N''', @backupCommand) + 4;
	SET @pathRootEnd = CHARINDEX('\' + @server + '\', @backupCommand);
	SET @path = SUBSTRING(@backupCommand, @pathStart, @pathRootEnd - @pathStart);
	SET @path = @path + '\' + @@SERVERNAME + '\' + @dbName;
END

--select @backupCommand, @path;


------------------------------------------------------------------------------------------
--// GET LIST OF BACKUP FILES                                                         //--
------------------------------------------------------------------------------------------

 -- initialize variables used to build the correct file path
SET @pathPossible = @path;
SET @depthPrevious = 0;

-- get the files and folders
INSERT INTO @tb_directoryTree ([Subdirectory], [Depth], [IsFile])
EXEC master.sys.xp_dirtree @path,2,1;

-- loop through all the entries and build their full physical names
DECLARE curPhysicalNames CURSOR LOCAL FAST_FORWARD FOR
	SELECT [ID], [Subdirectory], [Depth] FROM @tb_directoryTree;

OPEN curPhysicalNames;
	FETCH NEXT FROM curPhysicalNames INTO @id, @subdirectory, @depth;

	WHILE @@FETCH_STATUS = 0
	BEGIN 
		SET @depthChange = @depth - @depthPrevious;

		IF @depthChange = 1
		BEGIN
			SET @path = @pathPossible;
			SET @pathPossible = @path + '\' + @subdirectory;
		END

		IF @depthChange < 0
		BEGIN
			WHILE @depthChange < 0
			BEGIN
				SET @path = LEFT(@path,LEN(@path) - CHARINDEX('\',REVERSE(@path)));
				SET @depthChange = @depthChange + 1;
			END
		
			SET @pathPossible = @path + '\' + @subdirectory;
		END

		UPDATE @tb_directoryTree
		SET [PhysicalName] = @path + '\' + [Subdirectory]
		WHERE [ID] = @id;

		SET @depthPrevious = @depth;

		FETCH NEXT FROM curPhysicalNames INTO @id, @subdirectory, @depth;
	END
CLOSE curPhysicalNames;
DEALLOCATE curPhysicalNames;

-- uncomment to see a list of all the backup files
--select * from @tb_directoryTree;


------------------------------------------------------------------------------------------
--// GET BACKUP INFORMATION                                                           //--
------------------------------------------------------------------------------------------

-- loop through all the backup files
DECLARE cur_getBackupInfo CURSOR FAST_FORWARD FOR
	SELECT [PhysicalName] 
	FROM @tb_directoryTree
	WHERE [IsFile] = 1 AND RIGHT([PhysicalName],3) IN ('bak','trn');

OPEN cur_getBackupInfo;
FETCH NEXT FROM cur_getBackupInfo INTO @file;

WHILE (@@FETCH_STATUS = 0)
BEGIN
	-- use RESTORE HEADERONLY to get info about the backup
	SET @cmd = 'RESTORE HEADERONLY FROM DISK = ''' + @file + '''';

	-- check the instance version
	IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),1) = '9'
	BEGIN
		INSERT INTO @tb_backupInfo
		(
			[BackupName],
			[BackupDescription],
			[BackupType],
			[ExpirationDate],
			[Compressed],
			[Position],
			[DeviceType],
			[UserName],
			[ServerName],
			[DatabaseName],
			[DatabaseVersion],
			[DatabaseCreationDate],
			[BackupSize],
			[FirstLSN],
			[LastLSN],
			[CheckpointLSN],
			[DatabaseBackupLSN],
			[BackupStartDate],
			[BackupFinishDate],
			[SortOrder],
			[CodePage],
			[UnicodeLocaleId],
			[UnicodeComparisonStyle],
			[CompatibilityLevel],
			[SoftwareVendorId],
			[SoftwareVersionMajor],
			[SoftwareVersionMinor],
			[SoftwareVersionBuild],
			[MachineName],
			[Flags],
			[BindingID],
			[RecoveryForkID],
			[Collation],
			[FamilyGUID],
			[HasBulkLoggedData],
			[IsSnapshot],
			[IsReadOnly],
			[IsSingleUser],
			[HasBackupChecksums],
			[IsDamaged],
			[BeginsLogChain],
			[HasIncompleteMetaData],
			[IsForceOffline],
			[IsCopyOnly],
			[FirstRecoveryForkId],
			[ForkPointLSN],
			[RecoveryModel],
			[DifferentialBaseLSN],
			[DifferentialBaseGUID],
			[BackupTypeDescription],
			[BackupSetGUID]
		)
		EXECUTE (@cmd);

		UPDATE @tb_backupInfo
		SET [NameOfFile] = @file
		WHERE [BackupID] = (SELECT MAX([BackupID]) FROM @tb_backupInfo);
	END
	ELSE IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),2) = '10'
	BEGIN
		INSERT INTO @tb_backupInfo
		(
			[BackupName],
			[BackupDescription],
			[BackupType],
			[ExpirationDate],
			[Compressed],
			[Position],
			[DeviceType],
			[UserName],
			[ServerName],
			[DatabaseName],
			[DatabaseVersion],
			[DatabaseCreationDate],
			[BackupSize],
			[FirstLSN],
			[LastLSN],
			[CheckpointLSN],
			[DatabaseBackupLSN],
			[BackupStartDate],
			[BackupFinishDate],
			[SortOrder],
			[CodePage],
			[UnicodeLocaleId],
			[UnicodeComparisonStyle],
			[CompatibilityLevel],
			[SoftwareVendorId],
			[SoftwareVersionMajor],
			[SoftwareVersionMinor],
			[SoftwareVersionBuild],
			[MachineName],
			[Flags],
			[BindingID],
			[RecoveryForkID],
			[Collation],
			[FamilyGUID],
			[HasBulkLoggedData],
			[IsSnapshot],
			[IsReadOnly],
			[IsSingleUser],
			[HasBackupChecksums],
			[IsDamaged],
			[BeginsLogChain],
			[HasIncompleteMetaData],
			[IsForceOffline],
			[IsCopyOnly],
			[FirstRecoveryForkId],
			[ForkPointLSN],
			[RecoveryModel],
			[DifferentialBaseLSN],
			[DifferentialBaseGUID],
			[BackupTypeDescription],
			[BackupSetGUID],
			[CompressedBackupSize]
		)
		EXECUTE (@cmd);

		UPDATE @tb_backupInfo
		SET [NameOfFile] = @file
		WHERE [BackupID] = (SELECT MAX([BackupID]) FROM @tb_backupInfo);
	END
	ELSE IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),2) = '11'
	BEGIN
		INSERT INTO @tb_backupInfo
		(
			[BackupName],
			[BackupDescription],
			[BackupType],
			[ExpirationDate],
			[Compressed],
			[Position],
			[DeviceType],
			[UserName],
			[ServerName],
			[DatabaseName],
			[DatabaseVersion],
			[DatabaseCreationDate],
			[BackupSize],
			[FirstLSN],
			[LastLSN],
			[CheckpointLSN],
			[DatabaseBackupLSN],
			[BackupStartDate],
			[BackupFinishDate],
			[SortOrder],
			[CodePage],
			[UnicodeLocaleId],
			[UnicodeComparisonStyle],
			[CompatibilityLevel],
			[SoftwareVendorId],
			[SoftwareVersionMajor],
			[SoftwareVersionMinor],
			[SoftwareVersionBuild],
			[MachineName],
			[Flags],
			[BindingID],
			[RecoveryForkID],
			[Collation],
			[FamilyGUID],
			[HasBulkLoggedData],
			[IsSnapshot],
			[IsReadOnly],
			[IsSingleUser],
			[HasBackupChecksums],
			[IsDamaged],
			[BeginsLogChain],
			[HasIncompleteMetaData],
			[IsForceOffline],
			[IsCopyOnly],
			[FirstRecoveryForkId],
			[ForkPointLSN],
			[RecoveryModel],
			[DifferentialBaseLSN],
			[DifferentialBaseGUID],
			[BackupTypeDescription],
			[BackupSetGUID],
			[CompressedBackupSize],
			[Containment]
		)
		EXECUTE (@cmd);

		UPDATE @tb_backupInfo
		SET [NameOfFile] = @file
		WHERE [BackupID] = (SELECT MAX([BackupID]) FROM @tb_backupInfo);
	END
	ELSE IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),2) IN ('12','13')
	BEGIN
		INSERT INTO @tb_backupInfo
		(
			[BackupName],
			[BackupDescription],
			[BackupType],
			[ExpirationDate],
			[Compressed],
			[Position],
			[DeviceType],
			[UserName],
			[ServerName],
			[DatabaseName],
			[DatabaseVersion],
			[DatabaseCreationDate],
			[BackupSize],
			[FirstLSN],
			[LastLSN],
			[CheckpointLSN],
			[DatabaseBackupLSN],
			[BackupStartDate],
			[BackupFinishDate],
			[SortOrder],
			[CodePage],
			[UnicodeLocaleId],
			[UnicodeComparisonStyle],
			[CompatibilityLevel],
			[SoftwareVendorId],
			[SoftwareVersionMajor],
			[SoftwareVersionMinor],
			[SoftwareVersionBuild],
			[MachineName],
			[Flags],
			[BindingID],
			[RecoveryForkID],
			[Collation],
			[FamilyGUID],
			[HasBulkLoggedData],
			[IsSnapshot],
			[IsReadOnly],
			[IsSingleUser],
			[HasBackupChecksums],
			[IsDamaged],
			[BeginsLogChain],
			[HasIncompleteMetaData],
			[IsForceOffline],
			[IsCopyOnly],
			[FirstRecoveryForkId],
			[ForkPointLSN],
			[RecoveryModel],
			[DifferentialBaseLSN],
			[DifferentialBaseGUID],
			[BackupTypeDescription],
			[BackupSetGUID],
			[CompressedBackupSize],
			[Containment],
			[KeyAlgorithm],
			[EncryptorThumbprint],
			[EncryptorType]
		)
		EXECUTE (@cmd);

		UPDATE @tb_backupInfo
		SET [NameOfFile] = @file
		WHERE [BackupID] = (SELECT MAX([BackupID]) FROM @tb_backupInfo);
	END

	FETCH NEXT FROM cur_getBackupInfo INTO @file;
END

CLOSE cur_getBackupInfo;
DEALLOCATE cur_getBackupInfo;

--uncomment this select statement to see all the info for the backup files
--SELECT * FROM @tb_backupInfo ORDER BY [BackupStartDate];

-- check for a full backup
SELECT TOP 1 @firstFullTime = [BackupStartDate]
FROM @tb_backupInfo 
WHERE[BackupType] = 1
ORDER BY [FirstLSN] ASC;

IF (@firstFulltime IS NULL)
BEGIN
	SET @errorMessage = 'There is no full backup in the indicated folder.';
	RAISERROR(@errorMessage,16,1) WITH NOWAIT;
	RETURN
END

-- check if full backup exists before the point in time
IF (@pointInTimeUser = 'Y' AND @pointInTime < @firstFullTime)
BEGIN
	SET @errorMessage = 'Invalid @pointInTime - must be a value greater than a full backup time. The oldest full backup time is ''' + CONVERT(VARCHAR, @firstFullTime, 120) + CHAR(13) + CHAR(10);
	SET @errorMessage = @errorMessage + 'Use format: yyyy-mm-dd hh:mm:ss.mmm' + CHAR(13) + CHAR(10);
	SET @errorMessage = @errorMessage + 'Example: ''2016-01-05 00:34:58.000''' + CHAR(13) + CHAR(10);
	SET @errorMessage = @errorMessage + 'Example: ''2015-11-28 21:06:00.967''';
	RAISERROR(@errorMessage,16,1) WITH NOWAIT;
	RETURN
END



------------------------------------------------------------------------------------------
--// GET THE IDs OF THE FULL (AND DIFF) BACKUPS TO USE                                //--
------------------------------------------------------------------------------------------
SELECT TOP 1 @backupIdFull = [BackupID], @databaseBackupLSN = [CheckpointLSN], @firstLSN = [FirstLSN], @lastLsn = [LastLSN]
FROM @tb_backupInfo
WHERE [BackupType] = 1 AND [BackupStartDate] <= @pointInTime
ORDER BY [FirstLSN] DESC, [BackupStartDate] DESC


-- check if there is a diff backup between the full backup and recovery time
IF EXISTS(SELECT * FROM @tb_backupInfo WHERE [DatabaseBackupLSN] = @databaseBackupLSN AND [BackupType] = 5 AND [BackupStartDate] <= @pointInTime)
BEGIN
	
	SET @diffApplicable = 'Y';

	SELECT TOP 1 @backupIdDiff = [BackupID], /*@databaseBackupLSN = [DatabaseBackupLSN],*/ @firstLSN = [FirstLSN], @lastLsn = [LastLSN]
	FROM @tb_backupInfo
	WHERE [DatabaseBackupLSN] = @databaseBackupLSN AND [BackupType] = 5 AND [BackupStartDate] <= @pointInTime
	ORDER BY [FirstLSN] DESC, [BackupStartDate] DESC
END



------------------------------------------------------------------------------------------
--// DETERMINE IF A LOG TAIL BACKUP IS NEEDED                                         //--
------------------------------------------------------------------------------------------

IF (@pointInTimeUser = 'Y')
BEGIN
	-- get the time of the last log backup
	SELECT TOP 1 @lastTrnTime = [BackupStartDate]
	FROM @tb_backupInfo 
	WHERE[BackupType] = 2
	ORDER BY [BackupStartDate] DESC;
	
	-- if @pointInTime is greater than the last log backup, or if there is no log backups, then backup the tail of the log 
	IF (@pointInTime > @lastTrnTime) OR (@lastTrnTime IS NULL)
		SET @useTail = 'Y';
END

-- take a tail backup if needed
IF (@useTail = 'Y')
BEGIN
	-- get the folder of the most recent log backup
	SELECT TOP 1 @pathLog = LEFT([NameOfFile],LEN([NameOfFile]) - CHARINDEX('\',REVERSE([NameOfFile])))
	FROM @tb_backupInfo
	WHERE [BackupType] = 2
	ORDER BY [BackupStartDate] DESC;

	-- get the current time to use for the file name
	SET @dtString = CONVERT(VARCHAR, GETDATE(), 120);
	SET @dtString = REPLACE(@dtString, '-', '');
	SET @dtString = REPLACE(@dtString, ' ', '_');
	SET @dtString = REPLACE(@dtString, ':', '');

	-- take a log tail backup
	SET @tailFile = @pathLog + '\' + @server + '_' + @dbName + '_TAIL_' + @dtString + '.trn';
	SET @cmd = 'BACKUP LOG [' + @dbName + '] TO DISK = N''' + @tailFile + ''' WITH NO_CHECKSUM, COMPRESSION, NO_TRUNCATE';
	PRINT '/* -- TAKING A LOG TAIL BACKUP --';
	EXEC (@cmd);
	PRINT '*/';
	PRINT '';

	-- use RESTORE HEADERONLY to get info about the backup
	SET @cmd = 'RESTORE HEADERONLY FROM DISK = ''' + @tailFile + '''';

	-- check the instance version and insert the backup info
	IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),1) = '9'
	BEGIN
		INSERT INTO @tb_backupInfo
		(
			[BackupName],
			[BackupDescription],
			[BackupType],
			[ExpirationDate],
			[Compressed],
			[Position],
			[DeviceType],
			[UserName],
			[ServerName],
			[DatabaseName],
			[DatabaseVersion],
			[DatabaseCreationDate],
			[BackupSize],
			[FirstLSN],
			[LastLSN],
			[CheckpointLSN],
			[DatabaseBackupLSN],
			[BackupStartDate],
			[BackupFinishDate],
			[SortOrder],
			[CodePage],
			[UnicodeLocaleId],
			[UnicodeComparisonStyle],
			[CompatibilityLevel],
			[SoftwareVendorId],
			[SoftwareVersionMajor],
			[SoftwareVersionMinor],
			[SoftwareVersionBuild],
			[MachineName],
			[Flags],
			[BindingID],
			[RecoveryForkID],
			[Collation],
			[FamilyGUID],
			[HasBulkLoggedData],
			[IsSnapshot],
			[IsReadOnly],
			[IsSingleUser],
			[HasBackupChecksums],
			[IsDamaged],
			[BeginsLogChain],
			[HasIncompleteMetaData],
			[IsForceOffline],
			[IsCopyOnly],
			[FirstRecoveryForkId],
			[ForkPointLSN],
			[RecoveryModel],
			[DifferentialBaseLSN],
			[DifferentialBaseGUID],
			[BackupTypeDescription],
			[BackupSetGUID]
		)
		EXECUTE (@cmd);

		UPDATE @tb_backupInfo
		SET [NameOfFile] = @tailFile
		WHERE [BackupID] = (SELECT MAX([BackupID]) FROM @tb_backupInfo);
	END
	ELSE IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),2) = '10'
	BEGIN
		INSERT INTO @tb_backupInfo
		(
			[BackupName],
			[BackupDescription],
			[BackupType],
			[ExpirationDate],
			[Compressed],
			[Position],
			[DeviceType],
			[UserName],
			[ServerName],
			[DatabaseName],
			[DatabaseVersion],
			[DatabaseCreationDate],
			[BackupSize],
			[FirstLSN],
			[LastLSN],
			[CheckpointLSN],
			[DatabaseBackupLSN],
			[BackupStartDate],
			[BackupFinishDate],
			[SortOrder],
			[CodePage],
			[UnicodeLocaleId],
			[UnicodeComparisonStyle],
			[CompatibilityLevel],
			[SoftwareVendorId],
			[SoftwareVersionMajor],
			[SoftwareVersionMinor],
			[SoftwareVersionBuild],
			[MachineName],
			[Flags],
			[BindingID],
			[RecoveryForkID],
			[Collation],
			[FamilyGUID],
			[HasBulkLoggedData],
			[IsSnapshot],
			[IsReadOnly],
			[IsSingleUser],
			[HasBackupChecksums],
			[IsDamaged],
			[BeginsLogChain],
			[HasIncompleteMetaData],
			[IsForceOffline],
			[IsCopyOnly],
			[FirstRecoveryForkId],
			[ForkPointLSN],
			[RecoveryModel],
			[DifferentialBaseLSN],
			[DifferentialBaseGUID],
			[BackupTypeDescription],
			[BackupSetGUID],
			[CompressedBackupSize]
		)
		EXECUTE (@cmd);

		UPDATE @tb_backupInfo
		SET [NameOfFile] = @tailFile
		WHERE [BackupID] = (SELECT MAX([BackupID]) FROM @tb_backupInfo);
	END
	ELSE IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),2) = '11'
	BEGIN
		INSERT INTO @tb_backupInfo
		(
			[BackupName],
			[BackupDescription],
			[BackupType],
			[ExpirationDate],
			[Compressed],
			[Position],
			[DeviceType],
			[UserName],
			[ServerName],
			[DatabaseName],
			[DatabaseVersion],
			[DatabaseCreationDate],
			[BackupSize],
			[FirstLSN],
			[LastLSN],
			[CheckpointLSN],
			[DatabaseBackupLSN],
			[BackupStartDate],
			[BackupFinishDate],
			[SortOrder],
			[CodePage],
			[UnicodeLocaleId],
			[UnicodeComparisonStyle],
			[CompatibilityLevel],
			[SoftwareVendorId],
			[SoftwareVersionMajor],
			[SoftwareVersionMinor],
			[SoftwareVersionBuild],
			[MachineName],
			[Flags],
			[BindingID],
			[RecoveryForkID],
			[Collation],
			[FamilyGUID],
			[HasBulkLoggedData],
			[IsSnapshot],
			[IsReadOnly],
			[IsSingleUser],
			[HasBackupChecksums],
			[IsDamaged],
			[BeginsLogChain],
			[HasIncompleteMetaData],
			[IsForceOffline],
			[IsCopyOnly],
			[FirstRecoveryForkId],
			[ForkPointLSN],
			[RecoveryModel],
			[DifferentialBaseLSN],
			[DifferentialBaseGUID],
			[BackupTypeDescription],
			[BackupSetGUID],
			[CompressedBackupSize],
			[Containment]
		)
		EXECUTE (@cmd);

		UPDATE @tb_backupInfo
		SET [NameOfFile] = @tailFile
		WHERE [BackupID] = (SELECT MAX([BackupID]) FROM @tb_backupInfo);
	END
	ELSE IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),2) = '12'
	BEGIN
		INSERT INTO @tb_backupInfo
		(
			[BackupName],
			[BackupDescription],
			[BackupType],
			[ExpirationDate],
			[Compressed],
			[Position],
			[DeviceType],
			[UserName],
			[ServerName],
			[DatabaseName],
			[DatabaseVersion],
			[DatabaseCreationDate],
			[BackupSize],
			[FirstLSN],
			[LastLSN],
			[CheckpointLSN],
			[DatabaseBackupLSN],
			[BackupStartDate],
			[BackupFinishDate],
			[SortOrder],
			[CodePage],
			[UnicodeLocaleId],
			[UnicodeComparisonStyle],
			[CompatibilityLevel],
			[SoftwareVendorId],
			[SoftwareVersionMajor],
			[SoftwareVersionMinor],
			[SoftwareVersionBuild],
			[MachineName],
			[Flags],
			[BindingID],
			[RecoveryForkID],
			[Collation],
			[FamilyGUID],
			[HasBulkLoggedData],
			[IsSnapshot],
			[IsReadOnly],
			[IsSingleUser],
			[HasBackupChecksums],
			[IsDamaged],
			[BeginsLogChain],
			[HasIncompleteMetaData],
			[IsForceOffline],
			[IsCopyOnly],
			[FirstRecoveryForkId],
			[ForkPointLSN],
			[RecoveryModel],
			[DifferentialBaseLSN],
			[DifferentialBaseGUID],
			[BackupTypeDescription],
			[BackupSetGUID],
			[CompressedBackupSize],
			[Containment],
			[KeyAlgorithm],
			[EncryptorThumbprint],
			[EncryptorType]
		)
		EXECUTE (@cmd);

		UPDATE @tb_backupInfo
		SET [NameOfFile] = @tailFile
		WHERE [BackupID] = (SELECT MAX([BackupID]) FROM @tb_backupInfo);
	END
END

------------------------------------------------------------------------------------------
--// FULL BACKUP RESTORE COMMAND                                                      //--
------------------------------------------------------------------------------------------

SELECT @cmd = 'RESTORE DATABASE [' + @newDBName + '] FROM DISK = ''' + [NameOfFile] + ''' WITH NORECOVERY'
FROM @tb_backupInfo
WHERE [BackupID] = @backupIdFull;

-- check if user wants to use replace to overwrite existing database
IF (@replace = 'Y')
BEGIN
	-- caution message
	SET @errorMessage = 'CAUTION: using WITH REPLACE can delete an existing datbase and overwrite files.' + CHAR(13) + CHAR(10);
	SET @errorMessage = @errorMessage + 'For more information, go to: https://msdn.microsoft.com/en-us/library/ms186858.aspx';
	RAISERROR(@errorMessage,16,1) WITH NOWAIT;

	-- add replace command
	SET @cmd = @cmd + ', REPLACE';
END

-- add MOVE arguments for any files that new locations specified
DECLARE cur_MoveFileArguments CURSOR FAST_FORWARD FOR
	SELECT [LogicalName], [PhysicalName], [Type]
	FROM @tb_databaseFileList;

OPEN cur_MoveFileArguments;
FETCH NEXT FROM cur_MoveFileArguments INTO @logicalName, @physicalName, @type;

WHILE (@@FETCH_STATUS = 0)
BEGIN
	-- trim the physical name so it is just the file name and extension
	SET @physicalNameTrimmed = REVERSE(LEFT(REVERSE(@physicalName), CHARINDEX('\', REVERSE(@physicalName)) - 1));

	-- keep the same folder location if appending '_2' to the file's name, but not moving the file's location
	IF (@append_2 = 'Y')
	BEGIN
		IF ((@type = 0) AND (@moveDataFile = 'N'))
			SET @newDataFileLocation = LEFT(@physicalName, LEN(@physicalName) - LEN(@physicalNameTrimmed) - 1);
		IF ((@type = 1) AND (@moveLogFile = 'N'))
			SET @newLogFileLocation = LEFT(@physicalName, LEN(@physicalName) - LEN(@physicalNameTrimmed) - 1);
		IF ((@type = 2) AND (@moveFilestreamFile = 'N'))
			SET @newFilestreamLocation = LEFT(@physicalName, LEN(@physicalName) - LEN(@physicalNameTrimmed) - 1);
		IF ((@type = 4) AND (@moveFulltextFile = 'N'))
			SET @newFulltextLocation = LEFT(@physicalName, LEN(@physicalName) - LEN(@physicalNameTrimmed) - 1);
		
		-- append '_2' to the physical names if indicated		
		SET @physicalNameTrimmed = STUFF(@physicalNameTrimmed, CHARINDEX('.', @physicalNameTrimmed), 0, '_2');
	END
	
	-- add move command to @cmd
	IF ((@type = 0) AND ((@moveDataFile = 'Y') OR (@append_2 = 'Y')))
		SET @cmd = @cmd + ',' + CHAR(13) + CHAR(10) + '    MOVE ''' + @logicalName + ''' TO ''' + @newDataFileLocation + '\' + @physicalNameTrimmed + '''';
	ELSE IF ((@type = 1) AND ((@moveLogFile = 'Y') OR (@append_2 = 'Y')))
		SET @cmd = @cmd + ',' + CHAR(13) + CHAR(10) + '    MOVE ''' + @logicalName + ''' TO ''' + @newLogFileLocation + '\' + @physicalNameTrimmed + '''';
	ELSE IF ((@type = 2) AND ((@moveFilestreamFile = 'Y') OR (@append_2 = 'Y')))
		SET @cmd = @cmd + ',' + CHAR(13) + CHAR(10) + '    MOVE ''' + @logicalName + ''' TO ''' + @newFilestreamLocation + '\' + @physicalNameTrimmed + '''';
	ELSE IF ((@type = 4) AND ((@moveFulltextFile = 'Y') OR (@append_2 = 'Y')))
		SET @cmd = @cmd + ',' + CHAR(13) + CHAR(10) + '    MOVE ''' + @logicalName + ''' TO ''' + @newFulltextLocation + '\' + @physicalNameTrimmed + '''';

	FETCH NEXT FROM cur_MoveFileArguments INTO @logicalName, @physicalName, @type;
END

CLOSE cur_MoveFileArguments;
DEALLOCATE cur_MoveFileArguments;

-- if you entered a new location, but are not running this on the source server, the MOVE arguments will not be printed
IF NOT EXISTS(SELECT * FROM @tb_databaseFileList) AND (@newDataFileLocation != '' OR @newLogFileLocation != '' OR @newFilestreamLocation != '' OR @newFulltextLocation != '')
BEGIN
	SET @errorMessage = 'No MOVE arguments printed.' + CHAR(13) + CHAR(10);
	SET @errorMessage = @errorMessage + 'You entered a new location for the file(s), but are not running this on the source server, so file information is not avaialbe.' + CHAR(13) + CHAR(10);
	SET @errorMessage = @errorMessage + 'You will have to manually enter the MOVE arguments to the RESTORE DATABASE command for the full backup.';
	RAISERROR(@errorMessage,16,1);
END

SET @cmd = @cmd + ';';

PRINT @cmd;



------------------------------------------------------------------------------------------
--// DIFFERENTIAL BACKUP RESTORE COMMAND                                              //--
------------------------------------------------------------------------------------------

-- check to make sure there is a diff backup
IF (@diffApplicable = 'Y')
BEGIN
	SELECT @cmd = 'RESTORE DATABASE [' + @newDBName + '] FROM DISK = ''' + [NameOfFile] + ''' WITH NORECOVERY;'
	FROM @tb_backupInfo
	WHERE [BackupId] = @backupIdDiff;

	PRINT @cmd;
END



------------------------------------------------------------------------------------------
--// LOG BACKUP RESTORE COMMANDS                                                      //--
------------------------------------------------------------------------------------------

-- check if there are log backups after the full/diff we are using
IF (EXISTS(SELECT 1 FROM @tb_backupInfo WHERE [BackupType] = 2 AND [DatabaseBackupLSN] = @databaseBackupLSN))
BEGIN
	-- verify the log chain is not broken between the full/diff and the first log backup
	IF (EXISTS(SELECT [BackupID] FROM @tb_backupInfo WHERE [BackupType] = 2 AND [DatabaseBackupLSN] = @databaseBackupLSN AND [FirstLSN] <= @lastLSN))
	BEGIN
		-- find the first log backup to use
		SELECT TOP 1
			@cmd = 'RESTORE LOG [' + @newDBName + '] FROM DISK = ''' + [NameOfFile] + ''' WITH NORECOVERY;', 
			@lsn = [LastLSN], 
			@backupStartDate = [BackupStartDate], 
			@firstLSN = [FirstLSN]
		FROM 
			@tb_backupInfo
		WHERE 
			[BackupType] = 2 
			AND [DatabaseBackupLSN] = @databaseBackupLSN
			AND [FirstLSN] <= @lastLSN
		ORDER BY 
			[BackupStartDate] DESC;

		-- check if this log backup used contains the stopat time
		IF (@backupStartDate >= @pointInTime) AND (@pointInTimeUser = 'Y')
		BEGIN
			-- insert the STOPAT argument
			SET @cmd = STUFF(@cmd,CHARINDEX(';',@cmd),0,', STOPAT = ''' + CONVERT(VARCHAR, @pointInTime, 120) + '''');
		
			-- mark that the STOPAT argument was added
			SET @stopatAdded = 1;
		END

		PRINT @cmd;

		-- get the remaining needed log backups
		WHILE @stopatAdded = 0
		BEGIN
			-- verify the log chain is not broken between log backups
			IF EXISTS(SELECT [BackupID] FROM @tb_backupInfo WHERE [FirstLSN] = @lsn AND [BackupType] = 2)
			BEGIN
				-- get the next log backup
				SELECT TOP 1
					@cmd = 'RESTORE LOG [' + @newDBName + '] FROM DISK = ''' + [NameOfFile] + ''' WITH NORECOVERY;',
					@lsn = [LastLSN],
					@backupStartDate = [BackupStartDate]
				FROM 
					@tb_backupInfo 
				WHERE 
					[BackupType] = 2 
					AND [FirstLSN] = @lsn
				ORDER BY
					[BackupStartDate] DESC;

				-- check if this log backup used contains the stopat time
				IF (@backupStartDate >= @pointInTime) AND (@pointInTimeUser = 'Y')
				BEGIN
					-- insert the STOPAT argument
					SET @cmd = STUFF(@cmd,CHARINDEX(';',@cmd),0,', STOPAT = ''' + CONVERT(VARCHAR, @pointInTime, 120) + '''');
		
					-- mark that the STOPAT argument was added
					SET @stopatAdded = 1;
				END

				PRINT @cmd;
			END
			ELSE
			BEGIN
				IF @pointInTimeUser = 'N'
					SET @stopatAdded = 1;
				ELSE IF @pointInTimeUser = 'Y'
				BEGIN
					SELECT * FROM @tb_backupInfo ORDER BY [LastLSN];

					SET @errorMessage = 'The LSN chain is broken. Unable to backup to the specified point in time.' + CHAR(13) + CHAR(10);
					SET @errorMessage = @errorMessage + 'The details of the backup files have been selected in the Results tab for you to review.';
					RAISERROR(@errorMessage,16,1);
					RETURN;
				END
			END
		END
	END
	ELSE
	BEGIN 
		SELECT * FROM @tb_backupInfo ORDER BY [LastLSN];

		SET @errorMessage = 'The LSN chain is broken. Unable to backup to the specified point in time.' + CHAR(13) + CHAR(10);
		SET @errorMessage = @errorMessage + 'The details of the backup files have been selected in the Results tab for you to review.';
		RAISERROR(@errorMessage,16,1);
		RETURN;
	END
END


------------------------------------------------------------------------------------------
--// PUT THE DATABASE IN A USEABLE STATE                                             //--
------------------------------------------------------------------------------------------

PRINT 'RESTORE DATABASE [' + @newDBName + '] WITH RECOVERY;';



------------------------------------------------------------------------------------------
--// SELECT THE BACKUP FILE DETAILS TO REVIEW                                        //--
------------------------------------------------------------------------------------------

IF UPPER(@selectBackupInfo) != 'N'
	SELECT * FROM @tb_backupInfo ORDER BY [LastLSN],[BackupStartDate];




GO