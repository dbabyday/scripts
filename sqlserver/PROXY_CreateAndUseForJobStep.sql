-- Quotewin Accellion Job
-- Proxy


USE master;

CREATE CREDENTIAL cred_srvcintkiteworksrfq WITH IDENTITY = N'NA\srvcintkiteworksrfq',
                                                SECRET   = N'getFromCyberArk'; 

USE msdb;

EXECUTE msdb.dbo.sp_add_proxy @proxy_name      = N'proxy_srvcintkiteworksrfq',
                              @credential_name = N'cred_srvcintkiteworksrfq',
                              @enabled         = 1,
                              @description     = N'Proxy to execute as Windows account NA\srvcintkiteworksrfq';

EXECUTE msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name   = N'proxy_srvcintkiteworksrfq', 
                                             @subsystem_id = 3;

--EXEC msdb.dbo.sp_update_jobstep @job_name   = N'INT_Quotewin_Kiteworks_PD', 
--                                @step_id    = 1,
--                                @proxy_name = N'proxy_srvcktwrksrfqqaneen';




/*

    msdb.dbo.sp_grant_proxy_to_subsystem @subsystem_id values
    -------------------------------------------------------------
         2 - Microsoft ActiveX Script ** Depricated **
         3 - Operating System (CmdExec)
         4 - Replication Snapshot Agent
         5 - Replication Log Reader Agent
         6 - Replication Distribution Agent
         7 - Replication Merge Agent
         8 - Replication Queue Reader Agent
         9 - Analysis Services Query
        10 - Analysis Services Command
        11 - SSIS package execution
        12 - PowerShell Script

*/