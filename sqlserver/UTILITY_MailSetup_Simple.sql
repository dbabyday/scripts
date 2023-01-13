

DECLARE @mailAccountName         NVARCHAR(128) = N'SMS Notification',
        @mailAccountDesc         NVARCHAR(128) = N'Mail account for SMS email',
        @mailAccountEmailAddress NVARCHAR(128) = N'SMS.Notification@plexus.com',
        @mailAccountDisplayName  NVARCHAR(128) = N'SMS Notification',
        @mailAccountSmtpServer   NVARCHAR(128) = N'intranet-smtp.plexus.com',
        @mailAccountPort         INT           = 25,
        @emailBody               NVARCHAR(MAX) = N'',
        @emailRecipients         VARCHAR(MAX)  = 'james.lutsey@plexus.com',
        @mailProfileName         NVARCHAR(128) = N'SMS Notifier',
        @mailProfileDesc         NVARCHAR(256) = N'Profile for SMS email',
        @msg                     NVARCHAR(MAX) = N'';

-- add the account
IF NOT EXISTS(SELECT 1 FROM [msdb].[dbo].[sysmail_account] WHERE [name] = @mailAccountName)
BEGIN
    EXECUTE [msdb].[dbo].[sysmail_add_account_sp] @account_name    = @mailAccountName,
                                                  @description     = @mailAccountDesc,
                                                  @email_address   = @mailAccountEmailAddress,
                                                  @display_name    = @mailAccountDisplayName,
                                                  @mailserver_name = @mailAccountSmtpServer,
                                                  @port            = @mailAccountPort;
    
    SET @msg = CONVERT(NVARCHAR(19),GETDATE(),120) + N' - Mail account [' + @mailAccountName + N'] created.';
    RAISERROR(@msg,0,1) WITH NOWAIT;
END
ELSE
BEGIN
    SET @msg = CONVERT(NVARCHAR(19),GETDATE(),120) + N' - Mail account [' + @mailAccountName + N'] already exists.';
    RAISERROR(@msg,0,1) WITH NOWAIT;
END

-- add the profile
IF NOT EXISTS(SELECT 1 FROM [msdb].[dbo].[sysmail_profile] WHERE [name] = @mailProfileName)
BEGIN
    EXECUTE [msdb].[dbo].[sysmail_add_profile_sp] @profile_name = @mailProfileName,
                                                  @description  = @mailProfileDesc;
    
    SET @msg = CONVERT(NVARCHAR(19),GETDATE(),120) + N' - Mail profile [' + @mailProfileName + N'] created.';
    RAISERROR(@msg,0,1) WITH NOWAIT;
END
ELSE
BEGIN
    SET @msg = CONVERT(NVARCHAR(19),GETDATE(),120) + N' - Mail profile [' + @mailProfileName + N'] already exists.';
    RAISERROR(@msg,0,1) WITH NOWAIT;
END

-- assicate the account with the profile
IF NOT EXISTS(   SELECT          1
                 FROM            [msdb].[dbo].[sysmail_profileaccount] AS [pa]
                 FULL OUTER JOIN [msdb].[dbo].[sysmail_profile] AS [p] ON [pa].[profile_id] = [p].[profile_id]
                 FULL OUTER JOIN [msdb].[dbo].[sysmail_account] [a] ON [a].[account_id] = [pa].[account_id]
                 WHERE           [p].[name] = @mailProfileName
                                 AND [a].[name] = @mailAccountName
             )
BEGIN
    EXECUTE [msdb].[dbo].[sysmail_add_profileaccount_sp] @profile_name    = @mailProfileName,
                                                         @account_name    = @mailAccountName,
                                                         @sequence_number = 1;
    
    SET @msg = CONVERT(NVARCHAR(19),GETDATE(),120) + N' - Mail profile [' + @mailProfileName + N'] associated with mail account [' + @mailAccountName + N'].';
    RAISERROR(@msg,0,1) WITH NOWAIT;
END
BEGIN
    SET @msg = CONVERT(NVARCHAR(19),GETDATE(),120) + N' - Mail profile [' + @mailProfileName + N'] is already associated with mail account [' + @mailAccountName + N'].';
    RAISERROR(@msg,0,1) WITH NOWAIT;
END

-- test ability to send email
SET @emailBody = N'Testing mail sent with profile [' + @mailProfileName + N'], from SQL Server [' + @@SERVERNAME + N'].';

EXECUTE [msdb].[dbo].[sp_send_dbmail] @profile_name = @mailProfileName,
                                      @recipients   = @emailRecipients,
                                      @subject      = N'Test',
                                      @body         = @emailBody;

SET @msg = CONVERT(NVARCHAR(19),GETDATE(),120) + N' - Test email sent to ' + @emailRecipients + N', using profile [' + @mailProfileName + N'].';
RAISERROR(@msg,0,1) WITH NOWAIT;

