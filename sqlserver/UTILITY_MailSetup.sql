--DECLARE @mail_profile_current VARCHAR(MAX),
--@mail_account_current VARCHAR(MAX)

--SELECT @mail_profile_current = name FROM msdb.dbo.sysmail_profile  -- 
--SELECT @mail_account_current = name FROM msdb.dbo.sysmail_account  -- 

--SELECT * FROM msdb.dbo.sysmail_profile;
--SELECT * FROM msdb.dbo.sysmail_account;
--select * from msdb.dbo.sysmail_server;

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
-- CREATE  OPERATOR
---------------------------------------------------------------------------------------------
PRINT  '---------------------------------------------------------------------------------------------'
PRINT  '-- CREATE  OPERATOR'
PRINT  '---------------------------------------------------------------------------------------------'
-- SELECT * FROM msdb.dbo.sysoperators
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
SELECT @mail_test_email_address       = 'james.lutsey@plexus.com'
--SELECT @mail_test_email_address   = 'IT.MSSQL.Admins@plexus.com'
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



