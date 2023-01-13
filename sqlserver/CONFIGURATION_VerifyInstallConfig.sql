
-------------------------------------------------------------------------------------------------------------------------------------------

SELECT session_id, net_transport, protocol_type, auth_scheme, client_net_address, encrypt_option FROM sys.dm_exec_connections;

-------------------------------------------------------------------------------------------------------------------------------------------

IF CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)),4) AS NUMERIC(4,2)) >= 10.5
    SELECT servicename, service_account, startup_type_desc, status_desc FROM sys.dm_server_services;

-------------------------------------------------------------------------------------------------------------------------------------------

DECLARE @myBackupDirectory VARCHAR(100),
        @myKey             VARCHAR(200),
        @instance          VARCHAR(128);

SELECT @instance = COALESCE(CAST((SERVERPROPERTY('InstanceName')) AS VARCHAR(128)), 'MSSQLSERVER');

SELECT @myKey = CASE WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)),3) = N'9.0'  THEN 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL.1\MSSQLServer'
                     WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)),4) = N'10.0' THEN 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL10.'    + @instance + '\MSSQLServer'
                     WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)),4) = N'10.5' THEN 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL10_50.' + @instance + '\MSSQLServer'
                     WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)),4) = N'11.0' THEN 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.'    + @instance + '\MSSQLServer'
                     WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)),4) = N'12.0' THEN 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL12.'    + @instance + '\MSSQLServer'
                     WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)),4) = N'13.0' THEN 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL14.'    + @instance + '\MSSQLServer'
                     WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)),4) = N'14.0' THEN ''
                     ELSE ''
                END;

EXEC master..xp_regread @rootkey         = 'HKEY_LOCAL_MACHINE', 
                        @key             = @myKey, 
                        @value_name      = 'BackupDirectory', 
                        @BackupDirectory = @myBackupDirectory OUTPUT 

SELECT @myBackupDirectory AS BackupDirectory;

-------------------------------------------------------------------------------------------------------------------------------------------

/*

DECLARE @myBackupDirectory VARCHAR(100),
        @myKey           VARCHAR(200);

SELECT @myKey = CASE WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)),4) = N'11.0' THEN 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQLServer'
                     WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)),4) = N'12.0' THEN 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQLServer'
                     ELSE ''
                END;

EXEC master..xp_regwrite @rootkey    = 'HKEY_LOCAL_MACHINE', 
                         @key        = @myKey, 
                         @value_name = 'BackupDirectory', 
                         @type       = 'REG_SZ', 
                         @value      = 'F:\Backups';

*/

