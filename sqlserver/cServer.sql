SELECT SERVERPROPERTY('ServerName')     AS ServerName, 
       SERVERPROPERTY('ProductVersion') AS ProductVersion, 
       CASE
           WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(25)),4) = '15.0' THEN 'SQL Server 2019'
           WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(25)),4) = '14.0' THEN 'SQL Server 2017'
           WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(25)),4) = '13.0' THEN 'SQL Server 2016'
           WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(25)),4) = '12.0' THEN 'SQL Server 2014'
           WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(25)),4) = '11.0' THEN 'SQL Server 2012'
           WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(25)),4) = '10.5' THEN 'SQL Server 2008 R2'
           WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(25)),4) = '10.0' THEN 'SQL Server 2008'
           WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(25)),3) = '9.0'  THEN 'SQL Server 2005'
           ELSE 'Unknown'
       END                              AS VersionDescription,
       SERVERPROPERTY('ProductLevel')   AS ProductLevel
     , SERVERPROPERTY('Edition')        AS Edition
	 , CASE SERVERPROPERTY('IsIntegratedSecurityOnly')   
           WHEN 1 THEN 'Windows Authentication'   
           WHEN 0 THEN 'Windows and SQL Server Authentication'   
       END as AuthenticationMode ;

-- service accounts
SELECT * FROM sys.dm_server_services ORDER BY servicename;

-- encrypted connections
SELECT * FROM sys.dm_exec_connections ORDER BY session_id;

DECLARE
       @who TABLE (
       [SPID]        INT,
       [status]      VARCHAR(1000) NULL,
       [LOGIN]       SYSNAME NULL,
       [hostname]    SYSNAME NULL,
       [blkby]       SYSNAME NULL,
       [dbname]      SYSNAME NULL,
       [command]     VARCHAR(1000) NULL,
       [cputime]     INT NULL,
       [diskio]      INT NULL,
       [lastbatch]   VARCHAR(1000) NULL,
       [programname] VARCHAR(1000) NULL,
       [spid2]       INT,
       [requestid]   INT NULL
       );

DECLARE @buffer TABLE ([SPID] INT NULL, [EventType] NVARCHAR(30) NULL, [Parameters] SMALLINT NULL, [EventInfo] NVARCHAR(4000) NULL);

INSERT INTO @who
EXEC [sp_who2];

DECLARE
    @spid   VARCHAR(50)
    
DECLARE run_cursor CURSOR FOR
       SELECT spid
       FROM   @who
       WHERE  [spid] > 50
                 AND [LOGIN] <> SYSTEM_USER

OPEN run_cursor
FETCH NEXT FROM run_cursor INTO @spid

WHILE @@FETCH_STATUS = 0
    BEGIN
              BEGIN TRY     
                     INSERT INTO @buffer ([EventType], [Parameters], [EventInfo])
                     EXEC('DBCC INPUTBUFFER(' + @spid + ') WITH NO_INFOMSGS')

                     UPDATE @buffer
                     SET [SPID] = @spid
                     WHERE [SPID] IS null
              END TRY
        BEGIN CATCH
                     --do nothing
              END CATCH     
        FETCH NEXT FROM run_cursor INTO @spid

    END

CLOSE run_cursor
DEALLOCATE run_cursor 

SELECT  w.SPID,
        w.status,
        w.LOGIN,
        w.hostname,
        w.blkby,
        w.dbname,
        w.command,
        w.cputime,
        w.diskio,
        w.programname,
              --b.EventType,
              b.EventInfo
FROM    @who w 
       LEFT JOIN @buffer b ON b.SPID = w.SPID
WHERE w.[spid] > 50
ORDER BY w.SPID;



SELECT   [name],
         CASE 
             WHEN [state] = 0 THEN LOWER([state_desc])
             ELSE UPPER([state_desc])
         END AS [state_desc],
         CASE
             WHEN [user_access] = 0 THEN LOWER([user_access_desc])
             ELSE UPPER([user_access_desc])
         END AS [user_access_desc],
         [recovery_model_desc],
         [is_auto_close_on],
         [is_auto_shrink_on],
         CASE 
            WHEN [database_id] <= 4 THEN 'system'
            ELSE 'user'
         END AS [type],
         SUSER_SNAME([owner_sid]) AS [database_owner]
FROM     [sys].[databases]
ORDER BY [type],
         [name];

GO


-- Get the default directories for backups, data files, and log files. 
DECLARE @myBackupDirectory VARCHAR(100),
        @myDataDirectory   VARCHAR(100),
        @myLogDirectory    VARCHAR(100),
        @myKey             VARCHAR(200),
        @instance          VARCHAR(128);

SELECT @instance = COALESCE(CAST((SERVERPROPERTY('InstanceName')) AS VARCHAR(128)), 'MSSQLSERVER');

SELECT @myKey = CASE WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)),3) = N'9.0'  THEN 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL.1\MSSQLServer'
                     WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)),4) = N'10.0' THEN 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL10.'    + @instance + '\MSSQLServer'
                     WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)),4) = N'10.5' THEN 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL10_50.' + @instance + '\MSSQLServer'
                     WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)),4) = N'11.0' THEN 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.'    + @instance + '\MSSQLServer'
                     WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)),4) = N'12.0' THEN 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL12.'    + @instance + '\MSSQLServer'
                     WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)),4) = N'13.0' THEN 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL13.'    + @instance + '\MSSQLServer'
                     WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)),4) = N'14.0' THEN 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL14.'    + @instance + '\MSSQLServer'
                     ELSE ''
                END;

EXEC master..xp_regread @rootkey         = 'HKEY_LOCAL_MACHINE', 
                        @key             = @myKey, 
                        @value_name      = 'BackupDirectory', 
                        @BackupDirectory = @myBackupDirectory OUTPUT 

EXEC master..xp_regread @rootkey         = 'HKEY_LOCAL_MACHINE', 
                        @key             = @myKey, 
                        @value_name      = 'DefaultData', 
                        @BackupDirectory = @myDataDirectory OUTPUT 

EXEC master..xp_regread @rootkey         = 'HKEY_LOCAL_MACHINE', 
                        @key             = @myKey, 
                        @value_name      = 'DefaultLog', 
                        @BackupDirectory = @myLogDirectory OUTPUT 

SELECT @myBackupDirectory AS BackupDirectory,
       @myDataDirectory   AS DataDirectory,
       @myLogDirectory    AS LogDirectory;

GO


