/*********************************************************************************************************************
* 
* CONFIGURATION_DefaultDirectories.sql
* 
* Author: James Lutsey
* Date:   2018-05-14
* 
* Purpose: Get the default directories for backups, data files, and log files. 
*          Uncomment the xp_regwrite commands to set locatins.
* 
* Date        Name                  Description of change
* ----------  --------------------  ---------------------------------------------------------------------------------
* 
* 
*********************************************************************************************************************/



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

---- Set Default Locations
--EXEC master..xp_regwrite @rootkey    = 'HKEY_LOCAL_MACHINE', 
--                         @key        = @myKey, 
--                         @value_name = 'BackupDirectory', 
--                         @type       = 'REG_SZ', 
--                         @value      = 'F:\Backups';

--EXEC master..xp_regwrite @rootkey    = 'HKEY_LOCAL_MACHINE', 
--                         @key        = @myKey, 
--                         @value_name = 'DefaultData', 
--                         @type       = 'REG_SZ', 
--                         @value      = 'E:\Databases';

--EXEC master..xp_regwrite @rootkey    = 'HKEY_LOCAL_MACHINE', 
--                         @key        = @myKey, 
--                         @value_name = 'DefaultLog', 
--                         @type       = 'REG_SZ', 
--                         @value      = 'F:\Logs';

-- Get Default Locations
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
