/********************************************************************
* 
* Refresh Sms_PRODFIX
* 
* Enter the backup path\file - line 13
* 
********************************************************************/

-- change the execution context so all ownership is by 'sa'
USE [master];
EXECUTE AS LOGIN = N'sa';  -- SELECT [name] FROM [sys].[server_principals] WHERE [principal_id] = 1;
GO



------------------------------------------
--// RESTORE DATABASE                 //--
------------------------------------------

RESTORE DATABASE [Sms_PRODFIX] 
FROM  DISK = N'' -- \\NA\databackup\Neen_SQL_Backups\CO-DB-041\SMS2008\FULL\CO-DB-041_SMS2008_FULL_20170605_141748.bak
WITH  FILE = 1,  
      MOVE N'SMS2008'     TO N'F:\Databases\Sms_PRODFIX.mdf',  
      MOVE N'SMS2008_log' TO N'G:\Logs\Sms_PRODFIX_log.ldf',  
      REPLACE,  
      STATS = 5;
GO

-- change the logical file names
ALTER DATABASE [Sms_PRODFIX] MODIFY FILE ( NAME = N'SMS2008', NEWNAME = Sms_PRODFIX );
ALTER DATABASE [Sms_PRODFIX] MODIFY FILE ( NAME = N'SMS2008_log', NEWNAME = Sms_PRODFIX_log );
GO



------------------------------------------
--// REMOVE OLD PERMISSIONS           //--
------------------------------------------

USE [Sms_PRODFIX];

DECLARE @schema NVARCHAR(128),
        @sql    NVARCHAR(MAX),
        @user   NVARCHAR(128);

DECLARE curSchemas CURSOR LOCAL FAST_FORWARD FOR
    SELECT [name]
    FROM   [sys].[schemas]
    WHERE  USER_NAME([principal_id]) NOT IN ('public',
                                             'dbo',
                                             'guest',
                                             'INFORMATION_SCHEMA',
                                             'sys',
                                             'db_owner',
                                             'db_accessadmin',
                                             'db_securityadmin',
                                             'db_ddladmin',
                                             'db_backupoperator',
                                             'db_datareader',
                                             'db_datawriter',
                                             'db_denydatareader',
                                             'db_denydatawriter');

DECLARE curUsers CURSOR LOCAL FAST_FORWARD FOR
    SELECT [name]
    FROM   [sys].[database_principals]
    WHERE  [name] NOT IN ('public',
                          'dbo',
                          'guest',
                          'INFORMATION_SCHEMA',
                          'sys',
                          'db_owner',
                          'db_accessadmin',
                          'db_securityadmin',
                          'db_ddladmin',
                          'db_backupoperator',
                          'db_datareader',
                          'db_datawriter',
                          'db_denydatareader',
                          'db_denydatawriter');

-- change schema owners so they don't conflict with dropping users
OPEN curSchemas;
    FETCH NEXT FROM curSchemas INTO @schema;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = N'ALTER AUTHORIZATION ON SCHEMA::[' + @schema + N'] TO [dbo];';
        EXECUTE(@sql);

        FETCH NEXT FROM curSchemas INTO @schema;
    END
CLOSE curSchemas;
DEALLOCATE curSchemas;

-- drop users
OPEN curUsers;
    FETCH NEXT FROM curUsers INTO @user;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = N'DROP USER [' + @user + N'];';
        EXECUTE(@sql);

        FETCH NEXT FROM curUsers INTO @user;
    END
CLOSE curUsers;
DEALLOCATE curUsers;

GO



------------------------------------------
--// NEW PERMISSIONS                  //--
------------------------------------------

CREATE USER [NA\Guadalajara-MX Dev Team] FOR LOGIN [NA\Guadalajara-MX Dev Team];
ALTER ROLE [db_owner] ADD MEMBER [NA\Guadalajara-MX Dev Team];

GO



------------------------------------------
--// UPDATE ENVIRONMENT SPECIFIC DATA //--
------------------------------------------





-- change the execution context back to me
USE [master];
REVERT;


