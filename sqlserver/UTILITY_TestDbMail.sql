

EXECUTE [msdb].[dbo].[sp_send_dbmail] @profile_name = 'SQL Notifier',  -- select name from msdb.dbo.sysmail_profile;
                                      @recipients   = 'james.lutsey@plexus.com',
                                      @subject      = 'test',
                                      @body         = 'hi';

