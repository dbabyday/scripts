/**********************************************************************************************************
* 
* UTILITY_RestoreDB.sql
* 
* Author: James Lutsey
* Date: 05/10/2016
* 
* Purpose: Print the restore commands for a database
* 
* Notes: 
*     1. REQUIRED: You must enter a database name (line 77)
*     2. OPTIONAL: You may enter a point in time (line 78). If not entered, the commands for the last backup time will be printed.
*     3. OPTIONAL: You may enter the path(s) of the backup folders (lines 79-81). If not entered, the location of the Ola backup commands will be used.
*     4. OPTIONAL: To use the 'WITH REPLACE' command, change @replace (line 82) to 'Y'
*     5. OPTIONAL: If you are moving the database, enter the new locations for the data and log files (lines 83-86) 
*     6. OPTIONAL: Set @dbNameRestore (line 87) to give the restored database a new name 
*
* Troubleshooting:
*     1. If no files are found, verify the folder paths, and that the SQL Server service account has access
*     2. MOVE arguments will only be printed if running on the source server (needs to find files from sys.master_files)
*     3. Does not work on CO-DB-010 & CO-DB-017
* 
**********************************************************************************************************/

DECLARE 
	  @append_2              CHAR(1)
	, @backupCommand         VARCHAR(MAX)
	, @backupFile            VARCHAR(500)
	, @backupFinishDate      DATETIME
	, @backupIdFull          INT
	, @backupIdDiff          INT
	, @backupIdTrn           INT
	, @checkpiontLsn         NUMERIC(25,0)
	, @cmd                   VARCHAR(1000)
	, @configVal             INT
	, @dataFileName          VARCHAR(128)
	, @dbName                VARCHAR(128)
	, @dbNameRestore         VARCHAR(128)
	, @diffApplicable        CHAR(1)
	, @dtString              VARCHAR(25)
	, @errorMessage          VARCHAR(MAX)
	, @file                  VARCHAR(255)
	, @firstFullTime         DATETIME
	, @firstLSN              NUMERIC(25,0)
	, @lastLsnBeforeLogs     NUMERIC(25,0)
	, @lastTrnTime           DATETIME
	, @logFileName           VARCHAR(128)
	, @logicalName           VARCHAR(128)
	, @lsn                   NUMERIC(25,0)
	, @moveDataFile          CHAR(1)
	, @moveFilestreamFile    CHAR(1)
	, @moveFulltextFile      CHAR(1)
	, @moveLogFile           CHAR(1)
	, @newDataFileLocation   VARCHAR(255)
	, @newFilestreamLocation VARCHAR(255)
	, @newFulltextLocation   VARCHAR(255)
	, @newLogFileLocation    VARCHAR(255)
	, @pathDiff              VARCHAR(MAX)
	, @pathFull              VARCHAR(MAX)
	, @pathLog               VARCHAR(MAX)
	, @pathRoot              VARCHAR(MAX)
	, @pathRootEnd           INT
	, @pathStart             INT
	, @physicalName          VARCHAR(255)
	, @physicalNameTrimmed   VARCHAR(128)
	, @pointInTime           DATETIME
	, @pointInTimeUser       CHAR(1)
	, @recoveryModel         INT
	, @replace               CHAR(1)
	, @server                VARCHAR(128)
	, @stopatAdded           BIT
	, @tailFile              VARCHAR(255)
	, @type                  TINYINT
	, @useTail               CHAR(1)
	, @xpCmdshellConfig      INT;
	
SET @dbName      = ''; -- REQUIRED - select name, recovery_model_desc from master.sys.databases order by 1
SET @pointInTime = ''; -- yyyy-mm-dd hh:mm:ss.mmm - '2016-01-21 14:36:16.000', '2015-11-03 00:03:04.427' | OPTIONAL - if not set, it use most recent backup time 
SET @pathFull    = ''; -- OPTIONAL - if not set here, it will use the location of the backup job commands
SET @pathDiff    = ''; -- OPTIONAL - if not set here, it will use the location of the backup job commands
SET @pathLog     = ''; -- OPTIONAL - if not set here, it will use the location of the backup job commands
SET @replace     = 'N'; -- SET 'Y' if you want to replace the existing database | CAUTION: this can delete an existing database and overwrite exitsting files
SET @newDataFileLocation   = ''; ---------------| 
SET @newLogFileLocation    = '';              --| OPTIONAL - if restoring to a new location, enter the new location for the data, log, FILESTREAM, and/or Full-Text file(s)
SET @newFilestreamLocation = '';              --|     select db_name(database_id) as 'db', name, physical_name, type_desc from master.sys.master_files order by 1,4,2
SET @newFulltextLocation   = ''; ---------------|
SET @dbNameRestore         = ''; -- OPTIONAL - enter a new name here if you want to change the database name. (It will also append '_2' to the files' physical_names)

DECLARE @tb_backupFileList TABLE (
	[ID]         INT IDENTITY(1,1) PRIMARY KEY,
	[BackupFile] VARCHAR(255)
);

DECLARE @tb_databaseFileList TABLE (
	[ID] 				INT IDENTITY(1,1) PRIMARY KEY,
	[LogicalName]		VARCHAR(128),
	[PhysicalName]		VARCHAR(255),
	[Type]				TINYINT -- 0 = Rows, 1 = Log, 2 = FILESTREAM, 4 = Full-text
);

DECLARE @tb_backupInfo_2005 TABLE (
	  [BackupID]               INT IDENTITY(1,1) NOT NULL PRIMARY KEY
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
);

DECLARE @tb_backupInfo_2008 TABLE (
	  [BackupID]               INT IDENTITY(1,1) NOT NULL PRIMARY KEY
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
);

DECLARE @tb_backupInfo_2012 TABLE (
	  [BackupID]               INT IDENTITY(1,1) NOT NULL PRIMARY KEY
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
);

DECLARE @tb_backupInfo_2014_2016 TABLE (
	  [BackupID]               INT IDENTITY(1,1) NOT NULL PRIMARY KEY
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

DECLARE @tb_backupInfo TABLE (
	  [BackupID]               INT NOT NULL PRIMARY KEY
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

-- comment out the processing messages before the commands are printed
PRINT '/*';

-- make sure user entered a database
IF (@dbName = '')
BEGIN
	SET @errorMessage = 'You must enter a database name (line 77)';
	RAISERROR(@errorMessage,16,1) WITH NOWAIT;
	RETURN;
END

-- set some initial values
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
IF (@dbNameRestore = '')
BEGIN
	SET @dbNameRestore = @dbName;
	SET @append_2 = 'N';
END
ELSE
	SET @append_2 = 'Y';

-- get the database files
INSERT INTO @tb_databaseFileList ([LogicalName], [PhysicalName], [Type])
SELECT [name], [physical_name], [type] FROM [master].[sys].[master_files] WHERE [database_id] = DB_ID(@dbName);

--select * from @tb_databaseFileList


------------------------------------------------------------------------------------------
--// GET PATHS TO BACKUP FOLDERS                                                      //--
------------------------------------------------------------------------------------------

-- if path(s) not explicitly set, find the path used by Ola backup commands
IF (@pathFull = '' OR @pathDiff = '' OR @pathLog = '')
BEGIN
	-- root path
	SELECT @backupCommand = [Command] FROM [CentralAdmin].[dbo].[CommandLog] WHERE [Command] LIKE 'BACKUP DATABASE %' AND [Command] LIKE '%' + @server +'%';
	SELECT @pathStart = CHARINDEX('= N''', @backupCommand) + 4;
	SELECT @pathRootEnd = CHARINDEX('\' + @server + '\', @backupCommand);
	SELECT @pathRoot = SUBSTRING(@backupCommand, @pathStart, @pathRootEnd - @pathStart);
	SET @pathRoot = @pathRoot + '\' + @@SERVERNAME + '\' + @dbName;

	-- if blank, set full, diff, and/or log paths 
	IF (@pathFull = '')
		SET @pathFull = @pathRoot + '\FULL\';
	IF (@pathDiff = '')
		SET @pathDiff = @pathRoot + '\DIFF\';
	IF (@pathLog = '')
		SET @pathLog = @pathRoot + '\LOG\';
END

--select @backupCommand, @pathRoot, @pathFull, @pathDiff,  @pathLog;


------------------------------------------------------------------------------------------
--// GET LIST OF BACKUP FILES                                                         //--
------------------------------------------------------------------------------------------

-- check if xp_cmdshell is disabled
SELECT @xpCmdshellConfig = CONVERT(INT, ISNULL(value, value_in_use))
FROM  sys.configurations
WHERE  name = 'xp_cmdshell';

-- if disabled, temporarily enable xp_cmdshell
IF @xpCmdshellConfig = 0
BEGIN
	EXEC sp_configure 'show advanced options', 1;
	RECONFIGURE;
	EXEC sp_configure 'xp_cmdshell', 1;
	RECONFIGURE;
END

-- get the backup files
SET @cmd = 'DIR /s /b /O D ' + @pathFull;
INSERT INTO @tb_backupFileList([BackupFile]) EXEC master.sys.xp_cmdshell @cmd;
SET @cmd = 'DIR /s /b /O D ' + @pathDiff;
INSERT INTO @tb_backupFileList([BackupFile]) EXEC master.sys.xp_cmdshell @cmd;
SET @cmd = 'DIR /s /b /O D ' + @pathLog;
INSERT INTO @tb_backupFileList([BackupFile]) EXEC master.sys.xp_cmdshell @cmd;

-- if xp_cmdshell was origianally disabled, disable it again
IF @xpCmdshellConfig = 0
BEGIN
	EXEC sp_configure 'show advanced options', 1;
	RECONFIGURE;
	EXEC sp_configure 'xp_cmdshell', 0;
	RECONFIGURE;
END

-- remove entries that are not our backup files
DELETE FROM @tb_backupFileList
WHERE 
	RIGHT([BackupFile],4) NOT IN ('.bak', '.trn')
	OR [BackupFile] IS NULL; 

-- uncomment to see a list of all the backup files
--select * from @tb_backupFileList;


------------------------------------------------------------------------------------------
--// GET BACKUP INFORMATION                                                           //--
------------------------------------------------------------------------------------------

-- loop through all the backup files
DECLARE cur_getBackupInfo CURSOR FAST_FORWARD FOR
	SELECT [BackupFile] 
	FROM @tb_backupFileList;

OPEN cur_getBackupInfo;
FETCH NEXT FROM cur_getBackupInfo INTO @file;

WHILE (@@FETCH_STATUS = 0)
BEGIN
	-- use RESTORE HEADERONLY to get info about the backup
	SET @cmd = 'RESTORE HEADERONLY FROM DISK = ''' + @file + '''';

	-- check the instance version
	IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),1) = '9'
	BEGIN
		INSERT INTO @tb_backupInfo_2005
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

		INSERT INTO @tb_BackupInfo
		( 
			[BackupID],
			[NameOfFile],
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
		SELECT
			[BackupID],
			@file,
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
		FROM 
			@tb_backupInfo_2005
		WHERE 
			[BackupId] = (SELECT @@IDENTITY);
	END
	ELSE IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),2) = '10'
	BEGIN
		INSERT INTO @tb_backupInfo_2008
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

		INSERT INTO @tb_BackupInfo
		( 
			[BackupID],
			[NameOfFile],
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
		SELECT
			[BackupID],
			@file,
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
		FROM 
			@tb_backupInfo_2008
		WHERE 
			[BackupId] = (SELECT @@IDENTITY);
	END
	ELSE IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),2) = '11'
	BEGIN
		INSERT INTO @tb_backupInfo_2012
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

		INSERT INTO @tb_BackupInfo
		( 
			[BackupID],
			[NameOfFile],
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
		SELECT
			[BackupID],
			@file,
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
		FROM 
			@tb_backupInfo_2012
		WHERE 
			[BackupId] = (SELECT @@IDENTITY);
	END
	ELSE IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),2) IN ('12','13')
	BEGIN
		INSERT INTO @tb_backupInfo_2014_2016
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

		INSERT INTO @tb_BackupInfo
		( 
			[BackupID],
			[NameOfFile],
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
		SELECT
			[BackupID],
			@file,
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
		FROM 
			@tb_backupInfo_2014_2016
		WHERE 
			[BackupId] = (SELECT @@IDENTITY);
	END

	FETCH NEXT FROM cur_getBackupInfo INTO @file;
END

CLOSE cur_getBackupInfo;
DEALLOCATE cur_getBackupInfo;

--uncomment this select statement to see all the info for the backup files
--SELECT * FROM @tb_backupInfo ORDER BY [LastLSN];

-- check for a full backup
SELECT TOP 1 @firstFullTime = [BackupFinishDate]
FROM @tb_backupInfo 
WHERE[BackupType] = 1
ORDER BY [LastLSN] ASC;

IF (@firstFulltime IS NULL)
BEGIN
	SET @errorMessage = 'There is no full backup in the indicated folder.';
	RAISERROR(@errorMessage,16,1) WITH NOWAIT;
	RETURN
END

-- check if full backup exists before the point in time
IF (@pointInTimeUser = 'Y' AND @pointInTime < @firstFullTime)
BEGIN
	SET @errorMessage = 'Invalid @pointInTime (line 78) - must be a value greater than a full backup time. The oldest full backup time is ''' + CONVERT(VARCHAR, @firstFullTime, 120) + CHAR(13) + CHAR(10);
	SET @errorMessage = @errorMessage + 'Use format: yyyy-mm-dd hh:mm:ss.mmm' + CHAR(13) + CHAR(10);
	SET @errorMessage = @errorMessage + 'Example: ''2016-01-05 00:34:58.000''' + CHAR(13) + CHAR(10);
	SET @errorMessage = @errorMessage + 'Example: ''2015-11-28 21:06:00.967''';
	RAISERROR(@errorMessage,16,1) WITH NOWAIT;
	RETURN
END



------------------------------------------------------------------------------------------
--// GET THE IDs OF THE FULL (AND DIFF) BACKUPS TO USE                                //--
------------------------------------------------------------------------------------------
SELECT TOP 1 @backupIdFull = [BackupID], @checkpiontLsn = [CheckpointLSN]
FROM @tb_backupInfo
WHERE [BackupType] = 1 AND [BackupFinishDate] <= @pointInTime
ORDER BY [LastLSN] DESC

SELECT TOP 1 @backupIdDiff = [BackupID]
FROM @tb_backupInfo
WHERE [DatabaseBackupLSN] = @checkpiontLsn AND [BackupType] = 5 AND [BackupFinishDate] <= @pointInTime
ORDER BY [LastLSN] DESC

-- get the LastLSN for the start of the log backups
IF (@backupIdDiff IS NULL)
BEGIN
	SELECT @lastLsnBeforeLogs = [LastLSN] FROM @tb_backupInfo WHERE [BackupID] = @backupIdFull;
	SET @diffApplicable = 'N';
END
ELSE
BEGIN
	SELECT @lastLsnBeforeLogs = [LastLSN], @checkpiontLsn = [CheckpointLSN] FROM @tb_backupInfo WHERE [BackupID] = @backupIdDiff;
	SET @diffApplicable = 'Y';
END



------------------------------------------------------------------------------------------
--// DETERMINE IF A LOG TAIL BACKUP IS NEEDED                                         //--
------------------------------------------------------------------------------------------

IF (@pointInTimeUser = 'Y')
BEGIN
	-- check for log backup files
	IF (NOT EXISTS(SELECT * FROM @tb_backupInfo WHERE [BackupType] = 2))
	BEGIN -- no log backups...
		-- check recovery model; if full, take a tail backup
		IF (@recoveryModel = 1)
			SET @useTail = 'Y';
	END
	ELSE
	BEGIN -- there are log backups...
		-- get the time of the last log backup
		SELECT TOP 1 @lastTrnTime = [BackupFinishDate]
		FROM @tb_backupInfo 
		WHERE[BackupType] = 2
		ORDER BY [BackupFinishDate] DESC;
		
		-- if @pointInTime is greater than the last log backup, backup the tail of the log 
		IF ((@lastTrnTime IS NULL) OR (@pointInTime > @lastTrnTime))
			SET @useTail = 'Y';
	END
END

------------------------------------------------------------------------------------------
--// FULL BACKUP RESTORE COMMAND                                                      //--
------------------------------------------------------------------------------------------

SELECT @cmd = 'RESTORE DATABASE [' + @dbNameRestore + '] FROM DISK = ''' + [NameOfFile] + ''' WITH NORECOVERY'
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

-- end commenting out of the processing messages before the commands are printed
PRINT '*/';

PRINT '';
PRINT @cmd;



------------------------------------------------------------------------------------------
--// DIFFERENTIAL BACKUP RESTORE COMMAND                                              //--
------------------------------------------------------------------------------------------

-- check to make sure there is a diff backup
IF (@diffApplicable = 'Y')
BEGIN
	SELECT @cmd = 'RESTORE DATABASE [' + @dbNameRestore + '] FROM DISK = ''' + [NameOfFile] + ''' WITH NORECOVERY;'
	FROM @tb_backupInfo
	WHERE [BackupId] = @backupIdDiff;

	PRINT @cmd;
END



------------------------------------------------------------------------------------------
--// LOG BACKUP RESTORE COMMANDS                                                      //--
------------------------------------------------------------------------------------------

-- find the first log backup to use
IF (EXISTS(SELECT [BackupID] FROM @tb_backupInfo WHERE [BackupType] = 2 AND [LastLSN] > @lastLsnBeforeLogs))
BEGIN
	SELECT TOP 1 @backupIdTrn = [BackupID], @lsn = [LastLSN], @backupFinishDate = [BackupFinishDate], @firstLSN = [FirstLSN]
	FROM @tb_backupInfo
	WHERE [LastLSN] > @lastLsnBeforeLogs AND [BackupType] = 2
	ORDER BY [LastLSN] ASC, [BackupStartDate] ASC;

	-- check if LSN chain is broken between the full/diff to the first log backup
	IF @firstLSN > @lastLsnBeforeLogs
	BEGIN 
		SELECT * FROM @tb_backupInfo ORDER BY [LastLSN];

		SET @errorMessage = 'The LSN chain is broken. Unable to backup to the specified point in time.' + CHAR(13) + CHAR(10);
		SET @errorMessage = @errorMessage + 'The details of the backup files have been selected in the Results tab for you to review.';
		RAISERROR(@errorMessage,16,1);
		RETURN;
	END

	SELECT @cmd = 'RESTORE LOG [' + @dbNameRestore + '] FROM DISK = ''' + [NameOfFile] + ''' WITH NORECOVERY;'
	FROM @tb_backupInfo
	WHERE [BackupID] = @backupIdTrn;

	-- check if this first log backup used contains the stopat time
	IF @backupFinishDate >= @pointInTime
	BEGIN
		-- insert the STOPAT argument
		SET @cmd = STUFF(@cmd,CHARINDEX(';',@cmd),0,', STOPAT = ''' + CONVERT(VARCHAR, @pointInTime, 120) + '''');
		
		-- mark that the STOPAT argument was added
		SET @stopatAdded = 1;
	END

	PRINT @cmd;
END

-- find the next log backups in the needed time-range
WHILE ((SELECT TOP 1 [BackupFinishDate] FROM @tb_backupInfo WHERE [BackupType] = 2 AND [FirstLSN] = @lsn ORDER BY [LastLSN] DESC, [BackupFinishDate] DESC) < @pointInTime) AND (@stopatAdded = 0)
BEGIN
	IF (EXISTS(SELECT [BackupID] FROM @tb_backupInfo WHERE [BackupType] = 2 AND [FirstLSN] = @lsn))
	BEGIN
		SELECT TOP 1
			@cmd = 'RESTORE LOG [' + @dbNameRestore + '] FROM DISK = ''' + [NameOfFile] + ''' WITH NORECOVERY;',
			@lsn = [LastLSN]
		FROM 
			@tb_backupInfo 
		WHERE 
			[BackupType] = 2 
			AND [FirstLSN] = @lsn
		ORDER BY
			[LastLSN] DESC,
			[BackupFinishDate] DESC;

		PRINT @cmd;
	END
	ELSE
	BEGIN -- LSN chain is broken...
		SELECT * FROM @tb_backupInfo ORDER BY [LastLSN];

		SET @errorMessage = 'The LSN chain is broken. Unable to backup to the specified point in time.' + CHAR(13) + CHAR(10);
		SET @errorMessage = @errorMessage + 'The details of the backup files have been selected in the Results tab for you to review.';
		RAISERROR(@errorMessage,16,1);
		RETURN;
	END
END

-- find the log to use for STOPAT point in time, if the argument has not already been added
IF (EXISTS(SELECT [BackupID] FROM @tb_backupInfo WHERE [BackupType] = 2 AND [FirstLSN] = @lsn AND [BackupFinishDate] >= @pointInTime)) AND (@stopatAdded = 0)
BEGIN
		SELECT TOP 1 @cmd = 'RESTORE LOG [' + @dbNameRestore + '] FROM DISK = ''' + [NameOfFile] + ''' WITH NORECOVERY, STOPAT = ''' + CONVERT(VARCHAR, @pointInTime, 120) + ''';'
		FROM @tb_backupInfo 
		WHERE [BackupType] = 2 AND [FirstLSN] = @lsn AND [BackupFinishDate] >= @pointInTime
		ORDER BY [BackupFinishDate] ASC;

		PRINT @cmd;
END

-- use the log tail backup if indicated
SET @dtString = CONVERT(VARCHAR, GETDATE(), 120);
SET @dtString = REPLACE(@dtString, '-', '');
SET @dtString = REPLACE(@dtString, ' ', '_');
SET @dtString = REPLACE(@dtString, ':', '');

IF (@useTail = 'Y')
BEGIN
	-- take a log tail backup
	PRINT '/*';
	SET @tailFile = @pathRoot + '\' + @server + '_' + @dbName + '_TAIL_' + @dtString + '.trn';
	SET @cmd = 'BACKUP LOG [' + @dbName + '] TO DISK = N''' + @tailFile + ''' WITH NO_CHECKSUM, COMPRESSION, NO_TRUNCATE';
	EXEC (@cmd);
	PRINT '*/';

	-- restore command for log tail backup
	PRINT 'RESTORE LOG [' + @dbNameRestore + '] FROM DISK = N''' + @tailFile + ''' WITH NORECOVERY, STOPAT = ''' + CONVERT(VARCHAR, @pointInTime, 120) + ''';';
END



------------------------------------------------------------------------------------------
--// PUT THE DATABASE IN A USEABLE STATE                                             //--
------------------------------------------------------------------------------------------

PRINT 'RESTORE DATABASE [' + @dbNameRestore + '] WITH RECOVERY;';



------------------------------------------------------------------------------------------
--// SELECT THE BACKUP FILE DETAILS TO REVIEW                                        //--
------------------------------------------------------------------------------------------

--PRINT '/*';
--SELECT * FROM @tb_backupInfo ORDER BY [LastLSN];
--PRINT '*/';


