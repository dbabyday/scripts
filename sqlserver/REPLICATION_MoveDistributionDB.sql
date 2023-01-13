/***************************************************************************************
* 
* REPLICATION_MoveDistributionDB.sql
* 
* Author: Valerij Urban
* Source: http://www.sqlservercentral.com/articles/Replication/117265/
* Date:   2014-11-20
* 
* Date        Name                  Change
* ----------  --------------------  ------------------------------------------------
* 2018-02-17  James Lutsey          Formatting, SQLCMD Mode, Examples for Max/Plaid
* 
***************************************************************************************/



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 1. CREATE NEW DISTRIBUTION DATABASE                                                          //--
--//    We need to add the publisher values on a new distributor instance.                        //--
------------------------------------------------------------------------------------------------------

:CONNECT GCC-SQL-PD-007

-- install server as distributor
USE master;
EXECUTE sp_adddistributor @distributor    = N'gcc-sql-pd-007', 
                          @password       = N'<Distributor Password,sysname,SameAsOldDistributorPassword>', 
                          @from_scripting = 1;

-- Adding the agent profiles - SCRIPT FROM OLD DISTRIBUTION PROPERTIES
DECLARE @config_id INT;
EXECUTE sp_add_agent_profile @profile_id = @config_id OUTPUT, @profile_name = N'DCE 10', @agent_type = 3, @profile_type  = 1, @description = N'';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-BcpBatchSize', @parameter_value = N'2147473647';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-CommitBatchSize', @parameter_value = N'1000';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-CommitBatchThreshold', @parameter_value = N'10000';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-HistoryVerboseLevel', @parameter_value = N'1';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-KeepAliveMessageInterval', @parameter_value = N'300';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-LoginTimeout', @parameter_value = N'15';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-MaxBcpThreads', @parameter_value = N'1';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-MaxDeliveredTransactions', @parameter_value = N'0';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-PollingInterval', @parameter_value = N'5';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-QueryTimeout', @parameter_value = N'1800';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-SkipErrors', @parameter_value = N'2601:2627:20598';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-TransactionsPerHistory', @parameter_value = N'100';

EXECUTE sp_add_agent_profile @profile_id = @config_id OUTPUT, @profile_name = N'GsfTransferSkipDuplicateKey', @agent_type = 3, @profile_type  = 1, @description = N'skipping 2601 (Cannot insert duplicate key row in object ''%.*ls'' with unique index ''%.*ls''.) and 2627 (Violation of %ls constraint ''%.*ls''. Cannot insert duplicate key in object ''%.*ls''.)';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-BcpBatchSize', @parameter_value = N'2147473647';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-CommitBatchSize', @parameter_value = N'100';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-CommitBatchThreshold', @parameter_value = N'1000';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-HistoryVerboseLevel', @parameter_value = N'1';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-KeepAliveMessageInterval', @parameter_value = N'300';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-LoginTimeout', @parameter_value = N'15';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-MaxBcpThreads', @parameter_value = N'1';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-MaxDeliveredTransactions', @parameter_value = N'0';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-PollingInterval', @parameter_value = N'5';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-QueryTimeout', @parameter_value = N'1800';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-SkipErrors', @parameter_value = N'2601:2627';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-TransactionsPerHistory', @parameter_value = N'100';

EXECUTE sp_add_agent_profile @profile_id = @config_id OUTPUT, @profile_name = N'IncreaseQueryTimeout', @agent_type = 3, @profile_type  = 1, @description = N'';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-BcpBatchSize', @parameter_value = N'2147473647';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-CommitBatchSize', @parameter_value = N'1000';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-CommitBatchThreshold', @parameter_value = N'1000';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-HistoryVerboseLevel', @parameter_value = N'1';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-KeepAliveMessageInterval', @parameter_value = N'300';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-LoginTimeout', @parameter_value = N'15';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-MaxBcpThreads', @parameter_value = N'1';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-MaxDeliveredTransactions', @parameter_value = N'0';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-PollingInterval', @parameter_value = N'5';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-QueryTimeout', @parameter_value = N'7200';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-SkipErrors', @parameter_value = N'2601:2627:20598';
EXECUTE sp_change_agent_parameter @profile_id = @config_id, @parameter_name = N'-TransactionsPerHistory', @parameter_value = N'100';

-- Updating the agent profile defaults - SCRIPT FROM OLD DISTRIBUTION PROPERTIES
EXECUTE sp_MSupdate_agenttype_default @profile_id = 1;
EXECUTE sp_MSupdate_agenttype_default @profile_id = 2;
EXECUTE sp_MSupdate_agenttype_default @profile_id = 4;
EXECUTE sp_MSupdate_agenttype_default @profile_id = 6;
EXECUTE sp_MSupdate_agenttype_default @profile_id = 11;


--sql code to create a new distribution db on a new distributor instance:
EXECUTE sp_adddistributiondb @database          = N'distribution',
                             @data_folder       = N'F:\Databases', 
                             @data_file_size    = 96,
                             @log_folder        = N'G:\Logs',
                             @log_file_size     = 32, 
                             @min_distretention = 0, 
                             @max_distretention = 168,
                             @history_retention = 72, 
                             @security_mode     = 1;

GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/


-- create the distributor replication jobs - SCRIPT FROM OLD DISTRIBUTOR
------ Script Date: Replication agents checkup ------
begin transaction 
  DECLARE @JobID BINARY(16)
  DECLARE @ReturnCode INT
  SELECT @ReturnCode = 0
if (select count(*) from msdb.dbo.syscategories where name = N'REPL-Checkup') < 1 
  execute msdb.dbo.sp_add_category N'REPL-Checkup'

select @JobID = job_id from msdb.dbo.sysjobs where (name = N'Replication agents checkup')
if (@JobID is NULL)
BEGIN
  execute @ReturnCode = msdb.dbo.sp_add_job @job_id = @JobID OUTPUT, @job_name = N'Replication agents checkup', @enabled = 1, @description = N'Detects replication agents that are not logging history actively.', @start_step_id = 1, @category_name = N'REPL-Checkup', @owner_login_name = N'sa', @notify_level_eventlog = 2, @notify_level_email = 0, @notify_level_netsend = 0, @notify_level_page = 0, @delete_level = 0
  if (@@ERROR <> 0 OR @ReturnCode <> 0) goto QuitWithRollback

  execute @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @JobID, @step_id = 1, @step_name = N'Run agent.', @subsystem = N'TSQL', @command = N'sys.sp_replication_agent_checkup @heartbeat_interval = 10', @cmdexec_success_code = 0, @on_success_action = 1, @on_success_step_id = 0, @on_fail_action = 2, @on_fail_step_id = 0, @database_name = N'master', @retry_attempts = 0, @retry_interval = 0, @os_run_priority = 0, @flags = 0
  if (@@ERROR <> 0 OR @ReturnCode <> 0) goto QuitWithRollback

  execute @ReturnCode = msdb.dbo.sp_update_job @job_id = @JobID, @start_step_id = 1
  if (@@ERROR <> 0 OR @ReturnCode <> 0) goto QuitWithRollback

  execute @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id = @JobID, @name = N'Replication agent schedule.', @enabled = 1, @freq_type = 4, @freq_interval = 1, @freq_subday_type = 4, @freq_subday_interval = 10, @freq_relative_interval = 1, @freq_recurrence_factor = 0, @active_start_date = 20100410, @active_end_date = 99991231, @active_start_time = 0, @active_end_time = 235959
  if (@@ERROR <> 0 OR @ReturnCode <> 0) goto QuitWithRollback

  execute @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @JobID, @server_name = N'gcc-sql-pd-007'
  if (@@ERROR <> 0 OR @ReturnCode <> 0) goto QuitWithRollback

END

commit transaction 
goto EndSave 
QuitWithRollback: 
  if (@@TRANCOUNT > 0) rollback transaction 
EndSave:
GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------ Script Date: Reinitialize subscriptions having data validation failures ------
begin transaction 
  DECLARE @JobID BINARY(16)
  DECLARE @ReturnCode INT
  SELECT @ReturnCode = 0
if (select count(*) from msdb.dbo.syscategories where name = N'REPL-Alert Response') < 1 
  execute msdb.dbo.sp_add_category N'REPL-Alert Response'

select @JobID = job_id from msdb.dbo.sysjobs where (name = N'Reinitialize subscriptions having data validation failures')
if (@JobID is NULL)
BEGIN
  execute @ReturnCode = msdb.dbo.sp_add_job @job_id = @JobID OUTPUT, @job_name = N'Reinitialize subscriptions having data validation failures', @enabled = 1, @description = N'Reinitializes all subscriptions that have data validation failures.', @start_step_id = 1, @category_name = N'REPL-Alert Response', @owner_login_name = N'sa', @notify_level_eventlog = 0, @notify_level_email = 0, @notify_level_netsend = 0, @notify_level_page = 0, @delete_level = 0
  if (@@ERROR <> 0 OR @ReturnCode <> 0) goto QuitWithRollback

  execute @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @JobID, @step_id = 1, @step_name = N'Run agent.', @subsystem = N'TSQL', @command = N'exec sys.sp_MSreinit_failed_subscriptions @failure_level = 1', @cmdexec_success_code = 0, @on_success_action = 1, @on_success_step_id = 0, @on_fail_action = 2, @on_fail_step_id = 0, @server = N'gcc-sql-pd-007', @database_name = N'master', @retry_attempts = 0, @retry_interval = 0, @os_run_priority = 0, @flags = 0
  if (@@ERROR <> 0 OR @ReturnCode <> 0) goto QuitWithRollback

  execute @ReturnCode = msdb.dbo.sp_update_job @job_id = @JobID, @start_step_id = 1
  if (@@ERROR <> 0 OR @ReturnCode <> 0) goto QuitWithRollback

  execute @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @JobID, @server_name = N'gcc-sql-pd-007'
  if (@@ERROR <> 0 OR @ReturnCode <> 0) goto QuitWithRollback

END

commit transaction 
goto EndSave 
QuitWithRollback: 
  if (@@TRANCOUNT > 0) rollback transaction 
EndSave:
GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 2. ADD THE PUBLISHER                                                                         //--
--//    We need to add the publisher values on a new distributor instance.                        //--
------------------------------------------------------------------------------------------------------

:CONNECT GCC-SQL-PD-007

USE [master];

--sql code to add a publisher to a new distribution db on a new distributor instance:
EXECUTE sp_adddistpublisher @publisher         = N'CO-DB-034',
                            @distribution_db   = N'distribution',
                            @security_mode     = 1,
                            @working_directory = N'\\gcc-sql-pd-007\ReplicationSnapshot',
                            @thirdparty_flag   = 0,
                            @publisher_type    = N'MSSQLSERVER';
GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 3. LINKED SERVERS                                                                            //--
--//    Create the missing linked servers on the new distributor.                                 //--
------------------------------------------------------------------------------------------------------

:CONNECT GCC-SQL-PD-007

USE [master];

-- sql code to create linked server and access data from the old distributor
EXECUTE [master].[dbo].[sp_addlinkedserver] @server     = 'CO-DB-020',
                                            @srvproduct = N'SQL Server';

-- create the code to create missing linked servers that exist on the old distrubtor, but not on the new distributor
SELECT          [s].[name],
N'
USE [master];
GO

IF NOT EXISTS(SELECT [name] FROM [sys].[servers] WHERE [server_id] != 0 AND [name] = N''' + [s].[name] + N''')
BEGIN
    EXECUTE [master].[dbo].[sp_addlinkedserver] @server     = N''' + [s].[name] + N''', 
                                                @srvproduct = N''' + [s].[product] + N''';
    
    EXECUTE [master].[dbo].[sp_addlinkedsrvlogin] @rmtsrvname  = N''' + [s].[name] + N''',
                                                  @useself     = '''  + CASE [l].[uses_self_credential] WHEN 1 THEN N'TRUE' ELSE N'FALSE' END + N''',
                                                  @locallogin  = '    + CASE [l].[uses_self_credential] WHEN 1 THEN N'NULL' ELSE COALESCE(N'''' + [p].[name] + '''',N'NULL') END + N',
                                                  @rmtuser     = '    + CASE WHEN [l].[remote_name] IS NULL THEN N'NULL' ELSE N'''' + [l].[remote_name] + '''' END + N',
                                                  @rmtpassword = '    + CASE WHEN [l].[remote_name] IS NULL THEN N'NULL;' ELSE N'''SuperSecretPassword;  --<---- Enter the password here''' END + N'
END

EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''collation compatible'',              @optvalue = ''' + CASE [s].[is_collation_compatible] WHEN 0 THEN N'FALSE' ELSE N'TRUE' END + N''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''collation name'',                    @optvalue = ' + COALESCE(N'''' + [s].[collation_name] + N'''',N'NULL') + N';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''connect timeout'',                   @optvalue = ''' + CAST([s].[connect_timeout] AS NVARCHAR(10)) + ''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''data access'',                       @optvalue = ''' + CASE [s].[is_data_access_enabled] WHEN 0 THEN N'FALSE' ELSE N'TRUE' END + N''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''dist'',                              @optvalue = ''' + CASE [s].[is_distributor] WHEN 0 THEN N'FALSE' ELSE N'TRUE' END + N''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''lazy schema validation'',            @optvalue = ''' + CASE [s].[lazy_schema_validation] WHEN 0 THEN N'FALSE' ELSE N'TRUE' END + N''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''pub'',                               @optvalue = ''' + CASE [s].[is_publisher] WHEN 0 THEN N'FALSE' ELSE N'TRUE' END + N''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''query timeout'',                     @optvalue = ''' + CAST([s].[query_timeout] AS NVARCHAR(10)) + ''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''rpc'',                               @optvalue = ''' + CASE [s].[is_remote_login_enabled] WHEN 0 THEN N'FALSE' ELSE N'TRUE' END + N''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''rpc out'',                           @optvalue = ''' + CASE [s].[is_rpc_out_enabled] WHEN 0 THEN N'FALSE' ELSE N'TRUE' END + N''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''sub'',                               @optvalue = ''' + CASE [s].[is_subscriber] WHEN 0 THEN N'FALSE' ELSE N'TRUE' END + N''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''use remote collation'',              @optvalue = ''' + CASE [s].[uses_remote_collation] WHEN 0 THEN N'FALSE' ELSE N'TRUE' END + N''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''remote proc transaction promotion'', @optvalue = ''' + CASE [s].[is_remote_proc_transaction_promotion_enabled] WHEN 0 THEN N'FALSE' ELSE N'TRUE' END + N''';

GO
'
FROM            [CO-DB-020].[master].[sys].[servers] AS [s]
LEFT OUTER JOIN [CO-DB-020].[master].[sys].[linked_logins] AS [l] ON [l].[server_id] = [s].[server_id]
LEFT OUTER JOIN [CO-DB-020].[master].[sys].[server_principals] AS [p] ON [p].[principal_id] = [l].[local_principal_id]
WHERE           [s].[name] NOT IN (SELECT [name] FROM [sys].[servers])
ORDER BY        [s].[name];


-- paste here and run the dynamic sql created above to create the linked servers you need




GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 3 CHECK PROFILES                                                                             //--
--//   Make sure msdb.dbo.MSagent_profiles are matching between distributors.                     //--
------------------------------------------------------------------------------------------------------

:CONNECT GCC-SQL-PD-007

USE [master];

-- retrieve all different profiles from the old distributor
SELECT * FROM [CO-DB-020].[msdb].[dbo].[MSagent_profiles]
EXCEPT
SELECT * FROM [msdb].[dbo].[MSagent_profiles];

GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 4. SET SYNC WITH BACKUP OPTION                                                               //--
------------------------------------------------------------------------------------------------------

:CONNECT CO-DB-020

USE [master];

EXECUTE sp_replicationdboption @dbname  = N'distribution', 
                               @optname = N'sync with backup', 
                               @value   = true;
GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 5.1 LOG READER AGENT PERMISSIONS                                                             //--
------------------------------------------------------------------------------------------------------

-- log reader agent: sysadmin on distributor
:CONNECT GCC-SQL-PD-007

USE [master];
-- CTASK044734
IF NOT EXISTS(SELECT 1 FROM [sys].[server_principals] WHERE [name] = N'NA\msaGCCSQLPD007G$')
    CREATE LOGIN [NA\msaGCCSQLPD007G$] FROM WINDOWS WITH DEFAULT_DATABASE = [master];
ALTER SERVER ROLE [sysadmin] ADD MEMBER [NA\msaGCCSQLPD007G$];

GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



-- log reader agent: db_owner on publication database
:CONNECT CO-DB-034

USE [master];
-- CTASK044734
IF NOT EXISTS(SELECT 1 FROM [sys].[server_principals] WHERE [name] = N'NA\msaGCCSQLPD007G$')
    CREATE LOGIN [NA\msaGCCSQLPD007G$] FROM WINDOWS WITH DEFAULT_DATABASE = [master];

USE [MaxDB]; 
-- CTASK044734
IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N'NA\msaGCCSQLPD007G$')
    CREATE USER [NA\msaGCCSQLPD007G$] FOR LOGIN [NA\msaGCCSQLPD007G$];
EXECUTE sys.sp_addrolemember @rolename   = N'db_owner', 
                             @membername = N'NA\msaGCCSQLPD007G$';

USE [PLAID];
-- CTASK044734
IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N'NA\msaGCCSQLPD007G$')
    CREATE USER [NA\msaGCCSQLPD007G$] FOR LOGIN [NA\msaGCCSQLPD007G$];
EXECUTE sys.sp_addrolemember @rolename   = N'db_owner', 
                             @membername = N'NA\msaGCCSQLPD007G$';

GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 5.2 SNAPSHOT AGENT PERMISSIONS                                                               //--
--//         - NOTE: apply distribution database permissions after restore                        //--
------------------------------------------------------------------------------------------------------

-- log reader agent: read/write on snapshot share
/*
    NA\msaGCCSQLPD007G$ 
    \\gcc-sql-pd-007\ReplicationSnapshot
*/

-- snapshot agent: db_owner on publication database
:CONNECT CO-DB-034

USE [master];
IF NOT EXISTS(SELECT 1 FROM [sys].[server_principals] WHERE [name] = N'NA\msaGCCSQLPD007G$')
    CREATE LOGIN [NA\msaGCCSQLPD007G$] FROM WINDOWS WITH DEFAULT_DATABASE = [master];

USE [MaxDB];
IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N'NA\msaGCCSQLPD007G$')
    CREATE USER [NA\msaGCCSQLPD007G$] FOR LOGIN [NA\msaGCCSQLPD007G$];
EXECUTE sys.sp_addrolemember @rolename   = N'db_owner', 
                             @membername = N'NA\msaGCCSQLPD007G$';

USE [PLAID];
IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N'NA\msaGCCSQLPD007G$')
    CREATE USER [NA\msaGCCSQLPD007G$] FOR LOGIN [NA\msaGCCSQLPD007G$];
EXECUTE sys.sp_addrolemember @rolename   = N'db_owner', 
                             @membername = N'NA\msaGCCSQLPD007G$';

GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 5.3 DISTRIBUTION AGENT PULL SUBSCRIPTIONS PERMISSIONS                                        //--
--//         - NOTE: apply distribution database permissions after restore                        //--
------------------------------------------------------------------------------------------------------

-- distribution agent pull subscriptions: read on snapshot share
/*
    NA\srvcmsqlprod.neen 
    \\gcc-sql-pd-007\ReplicationSnapshot
*/

-- distribution agent pull subscriptions: db_owner on subscriber database
:CONNECT CO-DB-037

USE [master];
IF NOT EXISTS(SELECT 1 FROM [master].[sys].[server_principals] WHERE [name] = 'NA\srvcmsqlprod.neen')
    CREATE LOGIN [NA\srvcmsqlprod.neen] FROM WINDOWS WITH DEFAULT_DATABASE = [master];

USE [MaxDB];
IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = 'NA\srvcmsqlprod.neen')
    CREATE USER [NA\srvcmsqlprod.neen] FOR LOGIN [NA\srvcmsqlprod.neen];
EXECUTE sys.sp_addrolemember @rolename   = N'db_owner', 
                             @membername = N'NA\srvcmsqlprod.neen';

USE [MaxDB];
IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = 'NA\srvcmsqlprod.neen')
    CREATE USER [NA\srvcmsqlprod.neen] FOR LOGIN [NA\srvcmsqlprod.neen];
EXECUTE sys.sp_addrolemember @rolename   = N'db_owner', 
                             @membername = N'NA\srvcmsqlprod.neen';

GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



:CONNECT CO-DB-003
USE [master];
IF NOT EXISTS(SELECT 1 FROM [master].[sys].[server_principals] WHERE [name] = 'NA\srvcmsqlprod.neen')
    CREATE LOGIN [NA\srvcmsqlprod.neen] FROM WINDOWS WITH DEFAULT_DATABASE = [master];

USE [Pride];
IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = 'NA\srvcmsqlprod.neen')
    CREATE USER [NA\srvcmsqlprod.neen] FOR LOGIN [NA\srvcmsqlprod.neen];
ALTER ROLE [db_owner] ADD MEMBER [NA\srvcmsqlprod.neen];

GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



/**************************************************************************************************************************************************
* 
*  END OF PRE-WORK | THE NEXT STEP WILL STOP REPLICATION, IMPACTING PRODUCITON!
*
**************************************************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 7. STOP/DISABLE REPLICATION JOBS                                                             //--
--//    Stop and disable the replication jobs on the old distributor and pull subscribers.        //--
------------------------------------------------------------------------------------------------------

:CONNECT CO-DB-020

-- disable replication jobs
SELECT   name,
         N'EXECUTE msdb.dbo.sp_update_job @job_name = N''' + name + N''', @enabled = 0;'
FROM     msdb.dbo.sysjobs
ORDER BY name;

-- paste sp_update_job commands here to execute:



-- stop replication jobs that are running
SELECT          [j].[name],
                'EXECUTE msdb.dbo.sp_stop_job @job_name = N''' + [j].[name] + N''';'
FROM            [msdb].[dbo].[sysjobactivity] AS [ja] 
INNER JOIN      [msdb].[dbo].[sysjobs] AS [j] ON [ja].[job_id] = [j].[job_id]
LEFT OUTER JOIN [master].[dbo].[sysprocesses] AS [p] ON [master].[dbo].[fn_varbintohexstr](CONVERT(varbinary(16), [j].[job_id])) = SUBSTRING(REPLACE([program_name], 'SQLAgent - TSQL JobStep (Job ', ''), 1, 34)
WHERE           [ja].[session_id] = (SELECT TOP(1) [session_id] FROM [msdb].[dbo].[syssessions] ORDER BY [agent_start_date] DESC)
                AND [ja].[start_execution_date] IS NOT NULL
                AND [ja].[stop_execution_date] IS NULL
ORDER BY        [j].[name];

-- paste sp_stop_job commands here to run:



-- verify the jobs are not running

-- check pending commnads: wait for pending commands to reach 0 before stopping subscription jobs
EXECUTE distribution.dbo.usp_PendingCommands;

GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



:CONNECT CO-DB-037

-- disable replication jobs
SELECT   name,
         N'EXECUTE msdb.dbo.sp_update_job @job_name = N''' + name + N''', @enabled = 0;'
FROM     msdb.dbo.sysjobs
ORDER BY name;

-- paste sp_update_job commands here to execute:



-- stop replication jobs that are running
SELECT          [j].[name],
                'EXECUTE msdb.dbo.sp_stop_job @job_name = N''' + [j].[name] + N''';'
FROM            [msdb].[dbo].[sysjobactivity] AS [ja] 
INNER JOIN      [msdb].[dbo].[sysjobs] AS [j] ON [ja].[job_id] = [j].[job_id]
LEFT OUTER JOIN [master].[dbo].[sysprocesses] AS [p] ON [master].[dbo].[fn_varbintohexstr](CONVERT(varbinary(16), [j].[job_id])) = SUBSTRING(REPLACE([program_name], 'SQLAgent - TSQL JobStep (Job ', ''), 1, 34)
WHERE           [ja].[session_id] = (SELECT TOP(1) [session_id] FROM [msdb].[dbo].[syssessions] ORDER BY [agent_start_date] DESC)
                AND [ja].[start_execution_date] IS NOT NULL
                AND [ja].[stop_execution_date] IS NULL
ORDER BY        [j].[name];

-- paste sp_stop_job commands here to run:



-- verify the jobs are not running

GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



:CONNECT CO-DB-003

-- disable replication jobs
SELECT   name,
         N'EXECUTE msdb.dbo.sp_update_job @job_name = N''' + name + N''', @enabled = 0;'
FROM     msdb.dbo.sysjobs
ORDER BY name;

-- paste sp_update_job commands here to execute:



-- stop replication jobs that are running
SELECT          [j].[name],
                'EXECUTE msdb.dbo.sp_stop_job @job_name = N''' + [j].[name] + N''';'
FROM            [msdb].[dbo].[sysjobactivity] AS [ja] 
INNER JOIN      [msdb].[dbo].[sysjobs] AS [j] ON [ja].[job_id] = [j].[job_id]
LEFT OUTER JOIN [master].[dbo].[sysprocesses] AS [p] ON [master].[dbo].[fn_varbintohexstr](CONVERT(varbinary(16), [j].[job_id])) = SUBSTRING(REPLACE([program_name], 'SQLAgent - TSQL JobStep (Job ', ''), 1, 34)
WHERE           [ja].[session_id] = (SELECT TOP(1) [session_id] FROM [msdb].[dbo].[syssessions] ORDER BY [agent_start_date] DESC)
                AND [ja].[start_execution_date] IS NOT NULL
                AND [ja].[stop_execution_date] IS NULL
ORDER BY        [j].[name];

-- paste sp_stop_job commands here to run:



-- verify the jobs are not running

GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 8. BACKUP DISTRIBUTION DB                                                                    //--
--//    We always need a backup.                                                                  //--
------------------------------------------------------------------------------------------------------

:CONNECT CO-DB-020

-- backup old distribution db:
BACKUP DATABASE [distribution]
TO     DISK = N'\\na\databackup\Neen_SQL_Backups\CO-DB-020\distribution\FULL_COPY_ONLY\CO-DB-020_distribution_FULL_COPY_ONLY_CTASK044734.bak'
WITH   COPY_ONLY,
       CHECKSUM,
       STATS = 5;

RESTORE VERIFYONLY FROM DISK = N'\\na\databackup\Neen_SQL_Backups\CO-DB-020\distribution\FULL_COPY_ONLY\CO-DB-020_distribution_FULL_COPY_ONLY_CTASK044734.bak';

GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 9. RESTORE DISTRIBUTION DB ON THE NEW DISTRIBUTOR INSTANCE                                   //--
--//    Now we need to restore the old distribution database on the new instance.                 //--
------------------------------------------------------------------------------------------------------

:CONNECT GCC-SQL-PD-007

USE [master];

-- set db to single user mode
ALTER DATABASE [distribution] SET single_user WITH ROLLBACK IMMEDIATE;

-- restore distribution database on new distributor
RESTORE DATABASE [distribution]
FROM    DISK = N'\\na\databackup\Neen_SQL_Backups\CO-DB-020\distribution\FULL_COPY_ONLY\CO-DB-020_distribution_FULL_COPY_ONLY_CTASK044734.bak'
WITH    REPLACE,
        KEEP_REPLICATION,
        MOVE N'distribution'     TO N'F:\Databases\distribution.mdf',
        MOVE N'distribution_log' TO N'G:\Logs\distribution_log.ldf',
        STATS = 5;

ALTER AUTHORIZATION ON DATABASE::[distribution] TO [sa];

GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



-- snapshot agent permissions: db_owner on distribtuion database
:CONNECT GCC-SQL-PD-007
USE [master];
IF NOT EXISTS(SELECT 1 FROM [sys].[server_principals] WHERE [name] = N'NA\msaGCCSQLPD007G$')
    CREATE LOGIN [NA\msaGCCSQLPD007G$] FROM WINDOWS WITH DEFAULT_DATABASE = [master];

USE [distribution];
IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N'NA\msaGCCSQLPD007G$')
    CREATE USER [NA\msaGCCSQLPD007G$] FOR LOGIN [NA\msaGCCSQLPD007G$];
ALTER ROLE [db_owner] ADD MEMBER [NA\msaGCCSQLPD007G$];

-- distribution agent pull subscription permissions: db_owner on distribution database
USE [master];
IF NOT EXISTS(SELECT 1 FROM [master].[sys].[server_principals] WHERE [name] = 'NA\srvcmsqlprod.neen')
    CREATE LOGIN [NA\srvcmsqlprod.neen] FROM WINDOWS WITH DEFAULT_DATABASE = [master];

USE [distribution];
IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = 'NA\srvcmsqlprod.neen')
    CREATE USER [NA\srvcmsqlprod.neen] FOR LOGIN [NA\srvcmsqlprod.neen];
ALTER ROLE [db_owner] ADD MEMBER [NA\srvcmsqlprod.neen];

GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 10. UPDATE PUBLISHER AND SUBSCRIBER IDS                                                      //--
--//     Change the publisher_id and subscriber_id in:                                            //--
--//         - [MSpublisher_databases]                                                            //--
--//         - [MSpublications]                                                                   //--
--//         - [MSdistribution_agents]                                                            //--
--//         - [MSsubscriptions]                                                                  //--
------------------------------------------------------------------------------------------------------

:CONNECT GCC-SQL-PD-007

USE [distribution];

DECLARE @publisherId    AS INT,
        @subscriberId_1 AS INT,
        @subscriberId_2 AS INT;

SELECT @publisherId    = [server_id] FROM [sys].[servers] WHERE [name] = N'CO-DB-034';
SELECT @subscriberId_1 = [server_id] FROM [sys].[servers] WHERE [name] = N'CO-DB-037';
SELECT @subscriberId_2 = [server_id] FROM [sys].[servers] WHERE [name] = N'CO-DB-003';

UPDATE [distribution].[dbo].[MSpublisher_databases]
SET    [publisher_id] = @publisherId;

UPDATE [distribution].[dbo].[MSpublications]
SET    [publisher_id] = @publisherId;

UPDATE [distribution].[dbo].[MSdistribution_agents]
SET    [publisher_id] = @publisherId;

UPDATE [distribution].[dbo].[MSdistribution_agents]
SET    [subscriber_id] = @subscriberId_1
WHERE  [name] IN (N'CO-DB-034-MaxDb-pub_Maxdb-CO-DB-037-30',
                  N'CO-DB-034-PLAID-pub_Plaid-CO-DB-037-31');

UPDATE [distribution].[dbo].[MSdistribution_agents]
SET    [subscriber_id] = @subscriberId_2
WHERE  [name] = N'CO-DB-034-PLAID-pub_PlaidToPride-CO-DB-003-36';

UPDATE [distribution].[dbo].[MSsubscriptions]
SET    [publisher_id] = @publisherId;

-- do not update virtual subscribers with -1 and -2 id's
UPDATE [distribution].[dbo].[MSsubscriptions]
SET    [subscriber_id] = @subscriberId_1
WHERE  [subscriber_db] IN (N'MAXDB', N'PLAID');

UPDATE [distribution].[dbo].[MSsubscriptions]
SET    [subscriber_id] = @subscriberId_2
WHERE  [subscriber_db] = N'Pride';


-- verify the id values match
SELECT          [pdb].[publisher_db],
                [pdb].[publisher_id],
                [s].[server_id],
                [s].[name] 
FROM            [distribution].[dbo].[MSpublisher_databases] AS [pdb]
LEFT OUTER JOIN [sys].[servers]                              AS [s]   ON [pdb].[publisher_id] = [s].[server_id];
--SELECT * FROM sys.servers;

SELECT          [pub].[publication],
                [pub].[publisher_id],
                [s].[server_id],
                [s].[name] 
FROM            [distribution].[dbo].[MSpublications] AS [pub]
LEFT OUTER JOIN [sys].[servers]                       AS [s]   ON [pub].[publisher_id] = [s].[server_id];

SELECT          [ms].[publication_id],
                [ms].[article_id],
                [pub].[name]          AS [pubServer],
                [pub].[server_id]     AS [pubServerId],
                [ms].[publisher_id]   AS [msPublisherId],
                [sub].[name]          AS [subServer],
                [sub].[server_id]     AS [subServerId],
                [ms].[subscriber_id]  AS [msSubscriberId]
FROM            [distribution].[dbo].[MSsubscriptions] AS [ms]
LEFT OUTER JOIN [sys].[servers]                        AS [pub] ON [pub].[server_id] = [ms].[publisher_id]
LEFT OUTER JOIN [sys].[servers]                        AS [sub] ON [sub].[server_id] = [ms].[subscriber_id]
ORDER BY        [sub].[name],
                [ms].[subscriber_id];

GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 11. SCRIPT OUT LOG READER/SNAPSHOT JOBS                                                      //--
--//     * Update the distributor in the step code *                                              //--
------------------------------------------------------------------------------------------------------

:CONNECT GCC-SQL-PD-007

-- Script out log reader/snapshot jobs from old distributor. Paste and execute them here as DISABLED.



GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 12. SCRIPT OUT PUSH SUBSCRIPTION JOBS                                                        //--
--//     We need to change the publisher_id in the restored distribution db                       //--
------------------------------------------------------------------------------------------------------

:CONNECT GCC-SQL-PD-007

USE [msdb];

-- Script out push subscription jobs from old distributor. Paste and execute them here as DISABLED.
-- ** NONE **



GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 13. ALTER PULL SUBSCRIBERS REPLICATION JOBS                                                  //--
--//     We need to update the jobs to set new distributor name.                                  //--
------------------------------------------------------------------------------------------------------

:CONNECT CO-DB-037

USE [msdb];

--SELECT name FROM msdb.dbo.sysjobs ORDER BY name;

--update replication jobs properties with new distributor name:
EXEC [msdb].[dbo].[sp_update_jobstep] @job_name  = N'co-db-034-MaxDb-pub_MaxDb-co-db-037-MaxDB-6948F061-05D6-4384-8CC1-34FBE5443FEC', 
                                      @step_id   = 1 ,
                                      @command   = N'-Publisher CO-DB-034 -PublisherDB [MaxDb] -Publication [pub_MaxDb] -Distributor [GCC-SQL-PD-007] -SubscriptionType 1 -Subscriber [CO-DB-037] -SubscriberSecurityMode 1 -SubscriberDB [MaxDB]  -Continuous';
                                                   
EXEC [msdb].[dbo].[sp_update_jobstep] @job_name  = N'co-db-034-plaid-pub_plaid-co-db-037-PLAID-CAF2E92B-44E7-4E7E-81DE-EF5BADDE1C99', 
                                      @step_id   = 1 ,
                                      @command   = N'-Publisher CO-DB-034 -PublisherDB [PLAID] -Publication [pub_Plaid] -Distributor [GCC-SQL-PD-007] -SubscriptionType 1 -Subscriber [CO-DB-037] -SubscriberSecurityMode 1 -SubscriberDB [PLAID] -SkipErrors 20598:2601:2627 -Continuous';
                                                   
GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



:CONNECT CO-DB-003

USE [msdb];

--SELECT name FROM msdb.dbo.sysjobs ORDER BY name;

--update replication jobs properties with new distributor name:
EXEC [msdb].[dbo].[sp_update_jobstep] @job_name  = N'CO-DB-034-PLAID-pub_PlaidToPride-co-db-003-Pride-C26209FA-CF7C-4980-8AA8-A24EC764EACF', 
                                      @step_id   = 1 ,
                                      @command   = N'-Publisher CO-DB-034 -PublisherDB [PLAID] -Publication [pub_PlaidToPride] -Distributor [GCC-SQL-PD-007] -SubscriptionType 1 -Subscriber [CO-DB-003] -SubscriberSecurityMode 1 -SubscriberDB [Pride] -Continuous';
                                                   
GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 14. ALTER THE DISTRIBUTOR NAME ON PULL SUBSCRIBERS                                           //--
--//     We need to update the subscription properties to set new distributor name.               //--
------------------------------------------------------------------------------------------------------

:CONNECT CO-DB-037

-- execute sp to update pull subscription's properties
USE [MaxDB];
EXEC sys.sp_change_subscription_properties  @publisher    = N'CO-DB-034',
                                            @publisher_db = N'MaxDb',
                                            @publication  = N'pub_MaxDb',
                                            @property     = N'distributor',
                                            @value        = N'GCC-SQL-PD-007';

USE [PLAID];
EXEC sys.sp_change_subscription_properties  @publisher    = N'CO-DB-034',
                                            @publisher_db = N'PLAID',
                                            @publication  = N'pub_Plaid',
                                            @property     = N'distributor',
                                            @value        = N'GCC-SQL-PD-007';
GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



:CONNECT CO-DB-003

-- execute sp to update pull subscription's properties
USE [Pride];
EXEC sys.sp_change_subscription_properties  @publisher    = N'CO-DB-034',
                                            @publisher_db = N'PLAID',
                                            @publication  = N'pub_PlaidToPride',
                                            @property     = N'distributor',
                                            @value        = N'GCC-SQL-PD-007';

GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 15. UPDATE LOG READER AGENT ENTRIES                                                          //--
--//     We need to update values to ensure the replication monitor is working.                   //--
------------------------------------------------------------------------------------------------------

:CONNECT GCC-SQL-PD-007

USE [distribution];

-- check if job names match agent names
SELECT name FROM msdb.dbo.sysjobs ORDER BY name;
SELECT name FROM distribution.dbo.MSlogreader_agents ORDER BY name;
SELECT name FROM distribution.dbo.MSsnapshot_agents ORDER BY name;

-- if needed, change the jobs names to match agent names
EXECUTE msdb.dbo.sp_update_job @job_name = N'',
                               @new_name = N'CO-DB-034-MaxDb-13';
                               
EXECUTE msdb.dbo.sp_update_job @job_name = N'',
                               @new_name = N'CO-DB-034-PLAID-14';

EXECUTE msdb.dbo.sp_update_job @job_name = N'',
                               @new_name = N'CO-DB-034-MaxDb-pub_MaxDb-13';
                               
EXECUTE msdb.dbo.sp_update_job @job_name = N'',
                               @new_name = N'CO-DB-034-PLAID-pub_Plaid-14';
                               
EXECUTE msdb.dbo.sp_update_job @job_name = N'',
                               @new_name = N'CO-DB-034-PLAID-pub_PlaidToPride-15';

-- update MSlogreader_agents id's
UPDATE          lra
SET             lra.job_id = CAST(job.job_id AS BINARY(16)),
                lra.job_step_uid = step.step_uid,
                lra.publisher_id = (SELECT s.server_id FROM sys.servers AS s WHERE name = N'CO-DB-034')
FROM            distribution.dbo.MSlogreader_agents AS lra
LEFT OUTER JOIN msdb.dbo.sysjobs                    AS job  ON lra.name = job.name
LEFT OUTER JOIN msdb.dbo.sysjobsteps                AS step ON job.job_id = step.job_id
WHERE           step.step_id = 2;

-- verify id's match
SELECT          lra.name,
                lra.job_id                     AS [lraJobId],
                CAST(job.job_id AS BINARY(16)) AS [jobJobId],
                lra.job_step_uid               AS [lraStepUid],
                step.step_uid                  AS [stepStepUid],
                lra.publisher_id               AS [lraPublisherId],
                (SELECT s.server_id FROM sys.servers AS s WHERE name = N'CO-DB-034') AS [servPublisherId]
FROM            distribution.dbo.MSlogreader_agents AS lra
LEFT OUTER JOIN msdb.dbo.sysjobs                    AS job  ON lra.name = job.name
LEFT OUTER JOIN msdb.dbo.sysjobsteps                AS step ON job.job_id = step.job_id
WHERE           step.step_id = 2
                --AND ( lra.job_id <> CAST(job.job_id AS BINARY(16)) OR lra.job_step_uid <> step.step_uid)
ORDER BY        lra.name;


-- update MSsnapshot_agents id's
UPDATE          snap
SET             snap.job_id = CAST(job.job_id AS BINARY(16)),
                snap.job_step_uid = step.step_uid,
                snap.publisher_id = (SELECT s.server_id FROM sys.servers AS s WHERE name = N'CO-DB-034')
FROM            distribution.dbo.MSsnapshot_agents AS snap
LEFT OUTER JOIN msdb.dbo.sysjobs                   AS job  ON snap.name = job.name
LEFT OUTER JOIN msdb.dbo.sysjobsteps               AS step ON job.job_id = step.job_id
WHERE           step.step_id = 2;

-- verify id's match
SELECT          snap.name,
                snap.job_id                    AS [snapJobId],
                CAST(job.job_id AS BINARY(16)) AS [jobJobId],
                snap.job_step_uid              AS [snapStepUid],
                step.step_uid                  AS [stepStepUid],
                snap.publisher_id              AS [snapPublisherId],
                (SELECT s.server_id FROM sys.servers AS s WHERE name = N'CO-DB-034') AS [servPublisherId]
FROM            distribution.dbo.MSsnapshot_agents AS snap
LEFT OUTER JOIN msdb.dbo.sysjobs                   AS job  ON snap.name = job.name
LEFT OUTER JOIN msdb.dbo.sysjobsteps               AS step ON job.job_id = step.job_id
WHERE           step.step_id = 2
                --AND ( snap.job_id <> CAST(job.job_id AS BINARY(16)) OR snap.job_step_uid <> step.step_uid)
ORDER BY        snap.name;

GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 16. CHANGE DISTRIBUTOR NAME                                                                  //--
--//     We need to change the name on the publisher.                                             //--
------------------------------------------------------------------------------------------------------

:CONNECT CO-DB-034

-- sql commands to assign  a new distributor name on a publisher
USE [master];
EXECUTE sys.sp_setnetname @server  = N'repl_distributor', 
                          @netname = N'GCC-SQL-PD-007';
GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 17. ENABLE SUBSCRIBER JOBS                                                                   //--
--//     We need to enable the jobs one-by-one and resolve permission issues if they exist.       //--
------------------------------------------------------------------------------------------------------

:CONNECT GCC-SQL-PD-007

-- check that the publications show up
EXECUTE distribution.dbo.usp_PendingCommands;
GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



:CONNECT CO-DB-037

USE [msdb];

SELECT   name,
         'EXECUTE [msdb].[dbo].[sp_update_job] @job_name = N''' + name + N''', @enabled = 1;' + NCHAR(0x000D) + NCHAR(0x000A) + 
         'EXECUTE [msdb].[dbo].[sp_start_job]  @job_name = N''' + name + N''';' + NCHAR(0x000D) + NCHAR(0x000A) + NCHAR(0x000D) + NCHAR(0x000A)
FROM     msdb.dbo.sysjobs
ORDER BY name;

-- paste commands here to execute:






-- verify that jobs are running
SELECT          [j].[name]
FROM            [msdb].[dbo].[sysjobactivity] AS [ja] 
INNER JOIN      [msdb].[dbo].[sysjobs] AS [j] ON [ja].[job_id] = [j].[job_id]
LEFT OUTER JOIN [master].[dbo].[sysprocesses] AS [p] ON [master].[dbo].[fn_varbintohexstr](CONVERT(varbinary(16), [j].[job_id])) = SUBSTRING(REPLACE([program_name], 'SQLAgent - TSQL JobStep (Job ', ''), 1, 34)
WHERE           [ja].[session_id] = (SELECT TOP(1) [session_id] FROM [msdb].[dbo].[syssessions] ORDER BY [agent_start_date] DESC)
                AND [ja].[start_execution_date] IS NOT NULL
                AND [ja].[stop_execution_date] IS NULL
ORDER BY        [j].[name];


GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



:CONNECT CO-DB-003

USE [msdb];

SELECT   name,
         'EXECUTE [msdb].[dbo].[sp_update_job] @job_name = N''' + name + N''', @enabled = 1;' + NCHAR(0x000D) + NCHAR(0x000A) + 
         'EXECUTE [msdb].[dbo].[sp_start_job]  @job_name = N''' + name + N''';' + NCHAR(0x000D) + NCHAR(0x000A) + NCHAR(0x000D) + NCHAR(0x000A)
FROM     msdb.dbo.sysjobs
ORDER BY name;

-- paste commands here to execute:






-- verify that jobs are running
SELECT          [j].[name]
FROM            [msdb].[dbo].[sysjobactivity] AS [ja] 
INNER JOIN      [msdb].[dbo].[sysjobs] AS [j] ON [ja].[job_id] = [j].[job_id]
LEFT OUTER JOIN [master].[dbo].[sysprocesses] AS [p] ON [master].[dbo].[fn_varbintohexstr](CONVERT(varbinary(16), [j].[job_id])) = SUBSTRING(REPLACE([program_name], 'SQLAgent - TSQL JobStep (Job ', ''), 1, 34)
WHERE           [ja].[session_id] = (SELECT TOP(1) [session_id] FROM [msdb].[dbo].[syssessions] ORDER BY [agent_start_date] DESC)
                AND [ja].[start_execution_date] IS NOT NULL
                AND [ja].[stop_execution_date] IS NULL
ORDER BY        [j].[name];


GO




/**************************************************************************************************************************************************
* 
*  POINT OF NO RETURN! Once Log-reader agent is started
*
**************************************************************************************************************************************************/



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 18. ENABLE LOG-READER AGENT JOBS                                                             //--
--//     We need to enable the jobs and resolve permission issues if they exist.                  //--
------------------------------------------------------------------------------------------------------

:CONNECT GCC-SQL-PD-007

-- check pending commnads (there should be pending commands before log reader agent starts)
EXECUTE distribution.dbo.usp_PendingCommands;

-- script out the commands to enable and start the jobs
USE [msdb];

SELECT   name,
         'EXECUTE [msdb].[dbo].[sp_update_job] @job_name = N''' + name + N''', @enabled = 1;' + NCHAR(0x000D) + NCHAR(0x000A) + 
         'EXECUTE [msdb].[dbo].[sp_start_job]  @job_name = N''' + name + N''';' + NCHAR(0x000D) + NCHAR(0x000A) + NCHAR(0x000D) + NCHAR(0x000A)
FROM     msdb.dbo.sysjobs
ORDER BY name;

-- paste commands here to execute:
-- don't need to start the snapshot jobs





-- verify that jobs are running
SELECT          [j].[name]
FROM            [msdb].[dbo].[sysjobactivity] AS [ja] 
INNER JOIN      [msdb].[dbo].[sysjobs] AS [j] ON [ja].[job_id] = [j].[job_id]
LEFT OUTER JOIN [master].[dbo].[sysprocesses] AS [p] ON [master].[dbo].[fn_varbintohexstr](CONVERT(varbinary(16), [j].[job_id])) = SUBSTRING(REPLACE([program_name], 'SQLAgent - TSQL JobStep (Job ', ''), 1, 34)
WHERE           [ja].[session_id] = (SELECT TOP(1) [session_id] FROM [msdb].[dbo].[syssessions] ORDER BY [agent_start_date] DESC)
                AND [ja].[start_execution_date] IS NOT NULL
                AND [ja].[stop_execution_date] IS NULL
ORDER BY        [j].[name];

-- check pending commnads: should go down now that all jobs are running
EXECUTE distribution.dbo.usp_PendingCommands;

GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 19. ADD DISTRIBUTION DB TO BACKUP SCHEDULE.                                                  //--
--//     Now you need to add the distribution db to the backup routine and do regular db backups. //--
------------------------------------------------------------------------------------------------------

-- Run a full backup verify backup schedules are set

GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 20. DELETE DISABLED REPLICATION JOBS ON THE OLD DISTRIBUTOR                                  //--
--//     If there are no errors, delete the replication jobs on the old distributor               //--
------------------------------------------------------------------------------------------------------

:CONNECT CO-DB-020

-- delete replication sql jobs on old distributor
USE [msdb];

SELECT [name],
       N'EXECUTE [msdb].[dbo].[sp_delete_job] @job_name = N''' + [name] + N''';' + NCHAR(0x000D) + NCHAR(0x000A)
FROM   [msdb].[dbo].[sysjobs]
WHERE  [name] LIKE N'CO-DB-034%';

-- paste the commands here to execute:




GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 21. DROP THE OLD PUBLISHER                                                                   //--
--//     We need to drop the publisher on the old distributor server.                             //--
------------------------------------------------------------------------------------------------------

:CONNECT CO-DB-020

-- remove publisher info on the old distributor
USE [master];

EXECUTE sp_dropdistpublisher @publisher          = N'CO-DB-034',
                             @no_checks          = 1,
                             @ignore_distributor = 0;
GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 22. VERIFY TRANSACTIONAL REPLICATION ACTIVITY.                                               //--
--//     Open replication monitor to verify replication                                           //--
------------------------------------------------------------------------------------------------------

-- There should be no errors or red alerts shown in replication monitor if all above steps are done properly with correct variables values.
-- Replication jobs can be in running or not running states.



-- update the job, step, and server ids if needed

:CONNECT GCC-SQL-PD-007

SELECT name FROM msdb.dbo.sysjobs ORDER BY name;
SELECT agent_name FROM distribution.dbo.MSreplication_monitordata ORDER BY agent_name;

-- MSreplication_monitordata
SELECT          mon.agent_name,
                mon.job_id          AS [monJobId],
                job.job_id          AS [jobJobId],
                mon.publisher_srvid AS [monPublisherId],
                (SELECT s.server_id FROM sys.servers AS s WHERE name = N'CO-DB-034') AS [servPublisherId]
FROM            distribution.dbo.MSreplication_monitordata AS mon
LEFT OUTER JOIN msdb.dbo.sysjobs                           AS job  ON mon.agent_name = job.name
--WHERE           job.job_id IS NOT NULL
--                --AND (mon.job_id <> job.job_id OR mon.publisher_srvid <> (SELECT s.server_id FROM sys.servers AS s WHERE name = N'CO-DB-034'))
ORDER BY        mon.agent_name;

--UPDATE          mon
--SET             mon.job_id = job.job_id,
--                mon.publisher_srvid = (SELECT s.server_id FROM sys.servers AS s WHERE name = N'CO-DB-034')
--FROM            distribution.dbo.MSreplication_monitordata AS mon
--LEFT OUTER JOIN msdb.dbo.sysjobs                           AS job  ON mon.agent_name = job.name
--WHERE           job.job_id IS NOT NULL;

--DELETE FROM distribution.dbo.MSreplication_monitordata
--WHERE agent_name = 'CO-DB-034-MaxDb-pub_Maxdb-CO-DB-010-41';


SELECT * FROM distribution.dbo.MSpublications;
SELECT * FROM distribution.[dbo].[MSreplication_monitordata];
--DELETE FROM distribution.[dbo].[MSreplication_monitordata] WHERE agent_name = 'CO-DB-034-MaxDb-pub_Maxdb-CO-DB-010-41'

GO



/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/



------------------------------------------------------------------------------------------------------
--// 23. REMOVED LINKED SERVER                                                                    //--
--//     We no longer need the linked server to the old distributor                               //--
------------------------------------------------------------------------------------------------------

:CONNECT GCC-SQL-PD-007

EXECUTE sys.sp_dropserver @server = N'CO-DB-020';

GO






