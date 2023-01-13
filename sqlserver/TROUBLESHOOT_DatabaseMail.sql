/*********************************************************************************
* 
* Troubleshooting Database Mail
* 
**********************************************************************************/

RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
SET NOEXEC ON; -- SET NOEXEC OFF;




--------------------------------------------------------------------------
--// TEST IF YOU CAN SEND MAIL                                        //--
--------------------------------------------------------------------------

DECLARE @profile SYSNAME;
SELECT  @profile = name FROM msdb.dbo.sysmail_profile WHERE LOWER(name) LIKE '%sql%notifier%';
EXECUTE msdb.dbo.sp_send_dbmail @profile_name = @profile,
                                @recipients   = 'james.lutsey@plexus.com', 
                                @subject      = N'Test', 
                                @body         = N'checking if dbmail works...';



--------------------------------------------------------------------------
--// determine if Database Mail is enabled                            //--
--------------------------------------------------------------------------

-- confirm that the value_in_use is set to 1
SELECT * FROM sys.configurations WHERE name IN ('Agent XPs','Database Mail XPs');



--------------------------------------------------------------------------
--// Review info about profiles and accounts                          //--
--------------------------------------------------------------------------

-- get info for profiles, accounts, and mail servers
SELECT * FROM msdb.dbo.sysmail_profile;
SELECT * FROM msdb.dbo.sysmail_account;
select * from msdb.dbo.sysmail_server;

-- check which profiles and accounts are associated
SELECT     p.profile_id,
           p.name AS [profile_name],
           a.account_id,
           a.name AS [account_name],
           pa.sequence_number
FROM       msdb.dbo.sysmail_profileaccount AS pa
FULL OUTER JOIN msdb.dbo.sysmail_profile AS p ON pa.profile_id = p.profile_id
FULL OUTER JOIN msdb.dbo.sysmail_account AS a ON a.account_id = pa.account_id;

-- associate account with profile
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp @profile_name    = '<mail_profile_name>',
                                               @account_name    = '<mail_account_name>',
                                               @sequence_number = 1;



--------------------------------------------------------------------------
--// determine if users are properly configured to send Database Mail //--
--------------------------------------------------------------------------

-- get all logins and msdb users that can send mail (sysadmin, msdb DatabaseMailUserRole, msdb db_owner)
SELECT   'LOGIN:    ' + lgn.name 
FROM     sys.server_role_members rm
JOIN     sys.server_principals lgn ON rm.member_principal_id = lgn.principal_id
WHERE    rm.role_principal_id = SUSER_ID('sysadmin')
UNION
SELECT   'MSDB USER:    ' + mp.name --AS 'database_user'
FROM     msdb.sys.database_role_members drm
JOIN     msdb.sys.database_principals rp ON (drm.role_principal_id = rp.principal_id)
JOIN     msdb.sys.database_principals mp ON (drm.member_principal_id = mp.principal_id)
WHERE    rp.name IN ('DatabaseMailUserRole','db_owner')
ORDER BY 1;

-- To add users to the DatabaseMailUserRole role, use the following statement:
USE msdb;
EXECUTE sp_addrolemember @rolename   = 'DatabaseMailUserRole', 
                         @membername = '<database user>';

-- principal must have access to a profile
EXEC msdb.dbo.sysmail_help_principalprofile_sp;

-- To grant user access to profile MSDB USER:
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp @profile_name   = 'SMS Notifier',
                                                 @principal_name = 'NA\srvcsmstst001.na',
                                                 @is_default = 1;

-- to remove user access to profile
--EXECUTE msdb.dbo.sysmail_delete_principalprofile_sp @profile_name   = '',
--                                                    @principal_name = '';



--------------------------------------------------------------------------
--// confirm that the Database Mail is started                        //--
--------------------------------------------------------------------------

EXEC msdb.dbo.sysmail_help_status_sp;

-- If the Database Mail activation is not started, execute the following statement to start it:
EXEC msdb.dbo.sysmail_start_sp;

-- check the status of the mail queue with the following statement:
EXEC msdb.dbo.sysmail_help_queue_sp @queue_type = 'mail';

-- If the mail queue state is not RECEIVES_OCCURRING, try stopping and then starting the queue
EXEC msdb.dbo.sysmail_stop_sp;
EXEC msdb.dbo.sysmail_start_sp;



--------------------------------------------------------------------------
--// determine if problems affect all, or some, accounts in a profile //--
--------------------------------------------------------------------------
        
-- determine which accounts are successful in sending mail
SELECT   sent_account_id, 
         sent_date 
FROM     msdb.dbo.sysmail_sentitems 
ORDER BY sent_date DESC;



--------------------------------------------------------------------------
--// check the messages for the items                                 //--
--------------------------------------------------------------------------

-- view the error messages returned by Database Mail
SELECT * FROM msdb.dbo.sysmail_event_log ORDER BY log_date DESC;
select * from msdb.dbo.sysmail_faileditems ORDER BY send_request_date DESC;

-- get info from all items
SELECT * FROM msdb.dbo.sysmail_allitems;

-- get messages from failed items
SELECT          p.name AS [profile],
                i.recipients,
                i.subject,
                i.send_request_user,
                a.name AS [account],
                s.servername,
                s.port,
                i.last_mod_date,
                l.description 
FROM            msdb.dbo.sysmail_faileditems as i  --msdb.dbo.sysmail_allitems as i
INNER JOIN      msdb.dbo.sysmail_event_log AS l ON i.mailitem_id = l.mailitem_id
INNER JOIN      msdb.dbo.sysmail_profile AS p ON i.profile_id = p.profile_id
FULL OUTER JOIN msdb.dbo.sysmail_account AS a ON i.sent_account_id = a.account_id
FULL OUTER JOIN msdb.dbo.sysmail_server AS s ON a.account_id = s.account_id;

