--DECLARE @mail_profile_current VARCHAR(MAX),
--@mail_account_current VARCHAR(MAX)

--SELECT @mail_profile_current = name FROM msdb.dbo.sysmail_profile
--SELECT @mail_account_current = name FROM msdb.dbo.sysmail_account

--SELECT * FROM msdb.dbo.sysmail_profile
--SELECT * FROM msdb.dbo.sysmail_account

----------------------------------
---- Test that you can send emails
----------------------------------
--EXEC    msdb.dbo.sp_send_dbmail 
--            @profile_name   = @mail_profile_current,
--            @recipients     = 'james.lutsey@plexus.com',
--            @body           = 'tester'



USE msdb
GO
SET NOCOUNT ON

---------------------------------------------------------------------------------------------
-- CREATE SQL ADMIN OPERATOR
---------------------------------------------------------------------------------------------
PRINT  '---------------------------------------------------------------------------------------------'
PRINT  '-- CREATE SQL ADMIN OPERATOR'
PRINT  '---------------------------------------------------------------------------------------------'
IF  (EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = N'SQL Admins'))
BEGIN
        PRINT 'SQL Admins already exists as an operator'
END
ELSE

        EXEC msdb.dbo.sp_add_operator 
              @name                      = N'SQL Admins', 
                @enabled                        = 1, 
                @weekday_pager_start_time       = 0, 
                @weekday_pager_end_time         = 235959, 
                @saturday_pager_start_time      = 0, 
                @saturday_pager_end_time        = 235959, 
                @sunday_pager_start_time        = 0, 
                @sunday_pager_end_time          = 235959, 
                @pager_days                     = 127, 
                @email_address                  = N'IT.MSSQL.Admins@plexus.com', 
                @pager_address                  = N'IT.MSSQL.Admins@plexus.com' 

PRINT  ''
PRINT  ''
PRINT  '---------------------------------------------------------------------------------------------'
PRINT  '-- Review Size Of System Databases'
PRINT  '---------------------------------------------------------------------------------------------'
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                                      SIZE SYSTEM DATABASES
-- Alters the size of the system database (msdb, model, master, tempdb)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- msdb
------------------------------------------------------------------------------------
IF (SELECT size FROM sys.master_files WHERE name = 'MSDBData') < 12800
BEGIN
       ALTER DATABASE msdb MODIFY FILE (NAME = MSDBData,       SIZE = 100MB, FILEGROWTH = 0)
       PRINT 'msdb .mdf Expanded to 100 mb''s and AUTOGROWTH Disabled'
END

IF (SELECT size FROM sys.master_files WHERE name = 'MSDBLog') < 3840
BEGIN
       ALTER DATABASE msdb MODIFY FILE (NAME = MSDBLog,        SIZE = 30MB, FILEGROWTH = 0)
       PRINT 'msdb .ldf Expanded to 30 mb''s and AUTOGROWTH Disabled'
END

------------------------------------------------------------------------------------
-- model
------------------------------------------------------------------------------------
IF (SELECT size FROM sys.master_files WHERE name = 'modeldev') < 256
BEGIN
       ALTER DATABASE model MODIFY FILE (NAME = modeldev,      SIZE = 2MB, FILEGROWTH = 0)
       PRINT 'model .mdf Expanded to 2 mb''s and AUTOGROWTH Disabled'
END

IF (SELECT size FROM sys.master_files WHERE name = 'modellog') < 256
BEGIN
       ALTER DATABASE model MODIFY FILE (NAME = modellog,      SIZE = 2MB, FILEGROWTH = 0)
       PRINT 'model .ldf Expanded to 2 mb''s and AUTOGROWTH Disabled'
END

------------------------------------------------------------------------------------
-- master
------------------------------------------------------------------------------------
IF (SELECT size FROM sys.master_files WHERE name = 'master') < 12800
BEGIN
       ALTER DATABASE master MODIFY FILE (NAME = master,       SIZE = 100MB, FILEGROWTH = 0)
       PRINT 'master .mdf Expanded to 100 mb''s and AUTOGROWTH Disabled'
END

IF (SELECT size FROM sys.master_files WHERE name = 'mastlog') < 3840
BEGIN
       ALTER DATABASE master MODIFY FILE (NAME = mastlog,      SIZE = 30MB, FILEGROWTH = 0)
       PRINT 'master .ldf Expanded to 30 mb''s and AUTOGROWTH Disabled'
END

------------------------------------------------------------------------------------
-- tempdb resize files
------------------------------------------------------------------------------------
IF (SELECT size FROM sys.master_files WHERE name = 'tempdev') < 128000
BEGIN
       ALTER DATABASE tempdb MODIFY FILE (NAME = tempdev,      SIZE = 1000MB, FILEGROWTH = 0)
       PRINT 'tempdb .mdf Expanded to 1000 mb''s and AUTOGROWTH Disabled'
END

IF (SELECT size FROM sys.master_files WHERE name = 'templog') < 64000
BEGIN
       ALTER DATABASE tempdb MODIFY FILE (NAME = templog,      SIZE = 500MB, FILEGROWTH = 0)
       PRINT 'tempdb .ldf Expanded to 500 mb''s and AUTOGROWTH Disabled'
END


------------------------------------------------------------------------------------
-- tempdb set auto grow and add additional data files
------------------------------------------------------------------------------------
USE [master]
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'tempdev', MAXSIZE = 3000MB , FILEGROWTH = 250MB)
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'templog', MAXSIZE = 3000MB, FILEGROWTH = 256MB)
GO

DECLARE @FilePath VARCHAR(MAX), @SqlCmd VARCHAR(MAX)
SELECT @FilePath = REPLACE(physical_name, 'tempdb.mdf', '') FROM tempdb.sys.database_files WHERE type_desc = 'ROWS'
SET           @SqlCmd = 
'
ALTER DATABASE [tempdb] ADD FILE ( NAME = N''tempdev2'', FILENAME = N''' + @FilePath + 'tempdb2.ndf'' , SIZE = 1000MB, MAXSIZE = 3000MB, FILEGROWTH = 250MB)
ALTER DATABASE [tempdb] ADD FILE ( NAME = N''tempdev3'', FILENAME = N''' + @FilePath + 'tempdb3.ndf'' , SIZE = 1000MB, MAXSIZE = 3000MB, FILEGROWTH = 250MB)
ALTER DATABASE [tempdb] ADD FILE ( NAME = N''tempdev4'', FILENAME = N''' + @FilePath + 'tempdb4.ndf'' , SIZE = 1000MB, MAXSIZE = 3000MB, FILEGROWTH = 250MB)
'
------------------------------------------------------------------------------------
-- add additonal data files to tempdb
------------------------------------------------------------------------------------
EXEC (@SqlCmd)

------------------------------------------------------------------------------------
-- switch model recover model to simple
------------------------------------------------------------------------------------
ALTER DATABASE model SET RECOVERY simple

------------------------------------------------------------------------------------
-- set up database mail
------------------------------------------------------------------------------------
USE master

PRINT ''
PRINT ''
PRINT '------------------------------------------------------------------------'
PRINT '-- SETTING UP DATABASE MAIL'
PRINT '------------------------------------------------------------------------'
---------------------------------------------------------------------------------------------
-- Enable DB_mail
---------------------------------------------------------------------------------------------
EXECUTE sp_configure 'show advanced options', 1 
RECONFIGURE WITH OVERRIDE

EXECUTE sp_configure 'Database Mail XPs', 1;
RECONFIGURE WITH OVERRIDE

EXECUTE sp_configure 'Agent XPs', '1';
RECONFIGURE WITH OVERRIDE

EXECUTE sp_configure 'show advanced options', 0
RECONFIGURE WITH OVERRIDE

/*
------------------------------------------------------------------------------------------------------------------------------------------------------
START: DBMail Setup
--------------------
You will need to Replace some variables values to adjust to your environment.

Database Mail Simple Configuration Template.
--------------------------------------------------------------------------------
This creates a Database Mail profile, an SMTP account and associates the account 
to the profile. msdb.dbo.sysmail_add_principalprofile is also used to to grant 
access to the new profile for users who are not members of sysadmin.
------------------------------------------------------------------------------------------------------------------------------------------------------
*/
-- profile variables
--------------------
DECLARE @mail_profile_name               VARCHAR(128)
DECLARE @mail_profile_description        VARCHAR(300)

-- account variables
--------------------
DECLARE @mail_account_name               VARCHAR(128)
DECLARE @mail_account_description        VARCHAR(300) 
DECLARE @mail_email_address              NVARCHAR(100)
DECLARE @mail_display_name               NVARCHAR(128)
DECLARE @mail_smtp_server_name           NVARCHAR(128)
DECLARE @mail_port_number                INT

-- db_mail variables
--------------------
DECLARE @mail_test_email_address    VARCHAR(100)
DECLARE @mail_subject               VARCHAR(100)
DECLARE @mail_body                  VARCHAR(200)
DECLARE @error_message            VARCHAR(300)

-- setting up variables to define the mail account
--------------------------------------------------------------------------------------
SELECT @mail_account_name         = UPPER(REPLACE(@@SERVERNAME, '\','$'))
SELECT @mail_account_description  = UPPER(@@SERVERNAME) + '''s Mail Account For Administrative E-mail.'
SELECT @mail_email_address        = UPPER(REPLACE(@@SERVERNAME, '\','$')) + '@plexus.com'
SELECT @mail_display_name         = UPPER(@@SERVERNAME)
SELECT @mail_smtp_server_name     = 'intranet-smtp.plexus.com'
SELECT @mail_port_number          = 25

-- mail profile name. replace with the name for your profile
-------------------------------------------------------------------------------------------------
SELECT @mail_profile_name         = 'SQL Notifier'
SELECT @mail_profile_description  = 'Profile for sending Automated DBA Notifications'

-- setting up variables to define the mail message
--------------------------------------------------------------------------------------
--SELECT @mail_test_email_address       = 'james.lutsey@plexus.com'
SELECT @mail_test_email_address   = 'IT.MSSQL.Admins@plexus.com'
SELECT @mail_subject             = 'Testing Email Account'
SELECT @mail_body                = 'Testing Email Account'

----------------------------------------------------------------------------------------------------                   
-- Verify the specified account and profile do not already exist.
----------------------------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM msdb.dbo.sysmail_profile WHERE name = @mail_profile_name)
BEGIN
       EXECUTE msdb.dbo.sysmail_delete_profile_sp
                     @profile_name  = @mail_profile_name,
                     @force_delete  = 0;
       PRINT 'Deleting Previous Mail Profile [' + @mail_profile_name + ']'
END;

IF EXISTS (SELECT * FROM msdb.dbo.sysmail_account WHERE name = @mail_account_name)
BEGIN
       EXECUTE msdb.dbo.sysmail_delete_account_sp @account_name = @mail_account_name
       PRINT 'Deleting Previous Mail Account [' + @mail_account_name + ']'
END;

----------------------------------------------------------------------------------------------------                   
-- Clean up any additional profiles
----------------------------------------------------------------------------------------------------
WHILE EXISTS (SELECT name FROM msdb.dbo.sysmail_profile WHERE LEN(name) > 0)
BEGIN
       DECLARE @mail_profile_current VARCHAR(MAX)
       SELECT @mail_profile_current = MAX(name) FROM msdb.dbo.sysmail_profile

       EXECUTE msdb.dbo.sysmail_delete_profile_sp
                     @profile_name  = @mail_profile_current,
                     @force_delete  = 0;
       PRINT 'Deleting Previous Mail Profile [' + @mail_profile_current + ']'
END;

----------------------------------------------------------------------------------------------------                   
-- Clean up any additional accounts
----------------------------------------------------------------------------------------------------
WHILE EXISTS (SELECT name FROM msdb.dbo.sysmail_account WHERE LEN(name) > 0)
BEGIN
       DECLARE @mail_account_current VARCHAR(MAX)
       SELECT @mail_account_current = MAX(name) FROM msdb.dbo.sysmail_account

       EXECUTE msdb.dbo.sysmail_delete_account_sp @account_name = @mail_account_current
       PRINT 'Deleting Previous Mail Account [' + @mail_account_current + ']'
END;

----------------------------------------------------------------------------------------------------
-- Start a transaction before adding the account and the profile
----------------------------------------------------------------------------------------------------
BEGIN TRANSACTION ;

DECLARE @result INT

------------------
-- Add the account
------------------
EXECUTE @result = msdb.dbo.sysmail_add_account_sp
                     @account_name           = @mail_account_name,
                     @description            = @mail_account_description,
                     @email_address          = @mail_email_address,
                     @display_name           = @mail_display_name,
                     @mailserver_name        = @mail_smtp_server_name,
                     @port                   = @mail_port_number

IF @result <> 0
BEGIN
       SET @error_message       = 'Failed To Create The Specified Database Mail Account ['+ @mail_account_name +'].'
       RAISERROR(@error_message, 16, 1) ;
    GOTO done;
END

------------------
-- Add the profile
------------------
EXECUTE @result = msdb.dbo.sysmail_add_profile_sp
                     @profile_name           = @mail_profile_name, 
                     @description            = @mail_profile_description

IF @result <> 0
BEGIN
    SET @error_message           = 'Failed To Create The Specified Database Mail Profile ['+ @mail_profile_name +'].'
       RAISERROR(@error_message, 16, 1) ;
       ROLLBACK TRANSACTION;
    GOTO done;
END;

------------------------------------------------------------------------------
-- Associate the account with the profile.
------------------------------------------------------------------------------
EXECUTE @result = msdb.dbo.sysmail_add_profileaccount_sp
                     @profile_name           = @mail_profile_name,
                     @account_name           = @mail_account_name,
                     @sequence_number        = 1;

IF @result <> 0
BEGIN   
       SET @error_message       = 'Failed To Associate The Speficied Profile [' + @mail_profile_name + '] With The Specified Account ['+ @mail_account_name +'].'  
       RAISERROR(@error_message, 16, 1) ;       
ROLLBACK TRANSACTION;
GOTO done;
END;

COMMIT TRANSACTION

done:

IF NOT EXISTS ( SELECT profile_id FROM msdb.dbo.sysmail_principalprofile WHERE [profile_id] in (SELECT profile_id FROM msdb.dbo.sysmail_profile WHERE name =  @mail_profile_name))

       EXECUTE msdb.dbo.sysmail_add_principalprofile_sp  
                     @principal_name         = 'public',
                     @profile_name           = @mail_profile_name,
                     @is_default             = 1;


EXECUTE msdb.dbo.sysmail_start_sp ;

--------------------------------
-- Test that you can send emails
--------------------------------
EXEC    msdb.dbo.sp_send_dbmail 
              @profile_name   = @mail_profile_name,
              @recipients     = @mail_test_email_address,
              @subject        = @mail_subject,
              @body           = @mail_body

-----------------------------------------------------------------------------------------------
-- enables the failsafe operator and assigns it an operator
-----------------------------------------------------------------------------------------------
USE [msdb]

EXEC master.dbo.sp_MSsetalertinfo       @failsafeoperator       = N'SQL Admins', 
                                                                    @notificationmethod     = 3

-----------------------------------------------------------------------------------------------
-- enables sql agent mail profile and assigns it a profile
-----------------------------------------------------------------------------------------------
USE [msdb]

EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1

EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'UseDatabaseMail', N'REG_DWORD', 1

EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'DatabaseMailProfile', N'REG_SZ', @mail_profile_name
GO


PRINT ''
PRINT ''
PRINT '------------------------------------------------------------------------'
PRINT '-- SETTING MAXIMUM MEMORY SETTING FOR SQL SERVER'
PRINT '------------------------------------------------------------------------'
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- fail safe on setting max server memory, defaults to 85% of available memory
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
EXEC sys.sp_configure N'show advanced options', N'1'  
GO
RECONFIGURE WITH OVERRIDE
GO

DECLARE       @sql_server_memory   DECIMAL(10,0),
              @sql_memory_ratio    DECIMAL(10,2)

SET           @sql_memory_ratio    = 0.85

DECLARE @tb_sql_memory_value TABLE (sql_server_memory_in_mb   DECIMAL(10,0))

IF CAST(SERVERPROPERTY('productversion') AS VARCHAR) LIKE '11%' OR CAST(SERVERPROPERTY('productversion') AS VARCHAR) LIKE '12%'
BEGIN
       -- SQL 2012 query
       INSERT INTO @tb_sql_memory_value EXEC ('SELECT CAST(ROUND(physical_memory_kb / 1024.0, 0)  * ' + @sql_memory_ratio + ' AS INT) FROM sys.dm_os_sys_info')
END
ELSE
BEGIN
       -- SQL 2005\2008\2008 R2
       INSERT INTO @tb_sql_memory_value EXEC ('SELECT CAST ((physical_memory_in_bytes * ' + @sql_memory_ratio + ') / 1024 /1024 as INT) FROM sys.dm_os_sys_info')
END
       -- set the value
       SELECT @sql_server_memory = sql_server_memory_in_mb FROM @tb_sql_memory_value

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- change memory usage to 85% of the installed memory for the SQL server
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
PRINT  ''
PRINT  '*** ----------------------------------------------------------------------------------------- ***'
PRINT @@SERVERNAME + ' SQL Maximum Memory (MB) Has Been Changed To ' + CAST(@sql_server_memory AS VARCHAR(20)) + ' mb'
PRINT  '*** ----------------------------------------------------------------------------------------- ***'
PRINT  ''
       
EXEC master.sys.sp_configure N'max server memory (MB)', @sql_server_memory
GO
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'show advanced options', N'0'  
GO
RECONFIGURE WITH OVERRIDE
GO

PRINT ''
PRINT ''
PRINT '------------------------------------------------------------------------'
PRINT '-- SET MAX DEGREE OF PARALLELISM SQL SERVER'
PRINT '------------------------------------------------------------------------'
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- parallelism setting
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
EXEC sys.sp_configure N'show advanced options', N'1'  
GO
RECONFIGURE WITH OVERRIDE
GO

DECLARE       @sql_server_cpu_cnt  INT
SELECT        @sql_server_cpu_cnt  = (CAST( cpu_count AS INT) - 1) FROM sys.dm_os_sys_info

IF     @sql_server_cpu_cnt < 1
BEGIN
       PRINT  ''
       PRINT  '*** ----------------------------------------------------------------------------------------- ***'
       PRINT 'Server Has Only One CPU, No CHANGE on Max Degree Of Parallelism'
       PRINT  '*** ----------------------------------------------------------------------------------------- ***'
       PRINT  ''

END
ELSE
BEGIN
       PRINT  ''
       PRINT  '*** ----------------------------------------------------------------------------------------- ***'
       PRINT  @@SERVERNAME + ' "Max Degree Of Parallelism" Has Been Changed To ' + CAST(@sql_server_cpu_cnt AS VARCHAR(10))
       PRINT  '*** ----------------------------------------------------------------------------------------- ***'
       PRINT  ''

       EXEC master.sys.sp_configure 'max degree of parallelism', @sql_server_cpu_cnt

       RECONFIGURE WITH OVERRIDE
END

EXEC master.sys.sp_configure N'show advanced options', N'0'  
GO
RECONFIGURE WITH OVERRIDE
GO



