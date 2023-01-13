USE [msdb];

DECLARE @myJobName      NVARCHAR(128),
        @myDescription  NVARCHAR(512),
        @myOperator     NVARCHAR(128),
        @myOwner        NVARCHAR(128),
        @myScheduleName NVARCHAR(128),
        @myServer       NVARCHAR(128);



------------------------------------------------
--// USER INPUT                             //--
------------------------------------------------

SELECT @myJobName      = N'DBA - Backup Compliance',
       @myDescription  = N'Checks database backups for compliance. Emails an alert if out of compliance.',
       @myScheduleName = N'DBA - Backup Compliance - Every 5 Minutes',
       @myServer       = @@SERVERNAME;

-- NOTE: you must enter @step_name in each sp_add_jobstep



------------------------------------------------
--// GET CONFIGURATION VALUES               //--
------------------------------------------------

SELECT TOP(1) @myOperator = [name]
FROM   [msdb].[dbo].[sysoperators]
WHERE  [email_address] = 'IT.MSSQL.Admins@plexus.com';

SELECT @myOwner = [name]
FROM   [sys].[server_principals]
WHERE  [principal_id] = 1;



------------------------------------------------
--// CREATE THE JOB                         //--
------------------------------------------------

IF EXISTS(SELECT 1 FROM [msdb].[dbo].[sysjobs] WHERE [name] = @myJobName)
    EXECUTE [msdb].[dbo].[sp_delete_job] @job_name = @myJobName, @delete_unused_schedule = 1;


EXECUTE [msdb].[dbo].[sp_add_job] @job_name                   = @myJobName, 
                                  @enabled                    = 1, 
                                  @notify_level_eventlog      = 0, 
                                  @notify_level_email         = 2, 
                                  @notify_level_netsend       = 2, 
                                  @notify_level_page          = 2, 
                                  @delete_level               = 0,
                                  --@notify_email_operator_name = @myOperator,
                                  @description                = @myDescription, 
                                  @category_name              = N'[Uncategorized (Local)]', 
                                  @owner_login_name           = @myOwner;

EXECUTE [msdb].[dbo].[sp_add_jobserver] @job_name    = @myJobName, 
                                        @server_name = @myServer;

EXECUTE [msdb].[dbo].[sp_add_jobstep] @job_name             = @myJobName, 
                                      @step_name            = N'Check Backups and Alert if Necessary', 
                                      @step_id              = 1, 
                                      @cmdexec_success_code = 0, 
                                      @on_success_action    = 1, -- 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_success_step_id
                                      @on_fail_action       = 2, -- 1 = Quit with success, 2 = Quit with failure, 3 = Go to next step, 4 = Go to step on_fail_step_id
                                      @retry_attempts       = 0, 
                                      @retry_interval       = 0, -- minutes
                                      @os_run_priority      = 0, 
                                      @database_name        = N'master', 
                                      @flags                = 0,
                                      @subsystem            = N'TSQL', 
                                      @command              = N'
SET NOCOUNT ON;

USE CentralAdmin;

DECLARE @emailBody          NVARCHAR(MAX),
        @emailImportance    VARCHAR(6),
        @emailProfile       NVARCHAR(128),
        @emailRecipients    NVARCHAR(MAX) = N''james.lutsey@plexus.com'', -- IT.MSSQL.Admins@plexus.com
        @emailSubject       NVARCHAR(255);


IF OBJECT_ID(N''tempdb..#MissingBackups'',N''U'') IS NOT NULL DROP TABLE #MissingBackups;
CREATE TABLE #MissingBackups
(
    [ComplianceType]    VARCHAR(8)   NOT NULL,
    [Server]            SYSNAME      NOT NULL,
    [DatabaseName]      SYSNAME      NOT NULL,
    [RecoveryModel]     NVARCHAR(60) NULL,
    [CreateDate]        DATETIME2(3) NULL,
    [FullBackup]        DATETIME2(3) NULL,
    [DiffBackup]        DATETIME2(3) NULL,
    [LogBackup]         DATETIME2(3) NULL,
    [CurrentServerTime] DATETIME2(3) NULL,
    [Status]            VARCHAR(9)   NOT NULL DEFAULT ''recent''
);

IF OBJECT_ID(N''tempdb..#EmailBody'',N''U'') IS NOT NULL DROP TABLE #EmailBody;
CREATE TABLE #EmailBody
(
  [ID]        INT IDENTITY(1,1) NOT NULL,
  [EmailText] VARCHAR(MAX)      NOT NULL
);

-- get the mail profile
SELECT @emailProfile = [name]
FROM   [msdb].[dbo].[sysmail_profile]
WHERE  LOWER([name]) LIKE ''sql%notifier''

-- get databases with backups out of compliance
INSERT INTO #MissingBackups ([ComplianceType],[Server],[DatabaseName],[RecoveryModel],[CreateDate],[FullBackup],[DiffBackup],[LogBackup],[CurrentServerTime])
EXECUTE     CentralAdmin.dbo.usp_BackupsOutOfCompliance;



------------------------------------------------------------
--// SET THE STATUS FOR THE RECORDS                     //--
------------------------------------------------------------

-- flag records that are new 
UPDATE          [m]
SET             [m].[Status] = ''new''
FROM            #MissingBackups             AS [m]
LEFT OUTER JOIN [dbo].[MissingBackupAlerts] AS [a] ON [a].[ComplianceType] = [m].[ComplianceType]
                                                      AND [a].[DatabaseName] = [m].[DatabaseName]
WHERE           [a].[DatabaseName] IS NULL;

-- flag records that have not had an alert sent in the past 4 hours
UPDATE          [m]
SET             [m].[Status] = ''old''
FROM            #MissingBackups             AS [m]
LEFT OUTER JOIN [dbo].[MissingBackupAlerts] AS [a] ON [a].[ComplianceType] = [m].[ComplianceType]
                                                      AND [a].[DatabaseName] = [m].[DatabaseName]
WHERE           [a].[AlertSent] < DATEADD(HOUR,-4,[m].[CurrentServerTime]);

-- get the records that were out of compliance, and are now back in compliance
INSERT INTO #MissingBackups([ComplianceType],[Server],[DatabaseName],[Status])
SELECT          [a].[ComplianceType],
                @@SERVERNAME,
                [a].[DatabaseName],
                ''compliant''
FROM            [dbo].[MissingBackupAlerts] AS [a]
LEFT OUTER JOIN #MissingBackups             AS [m] ON [a].[ComplianceType] = [m].[ComplianceType]
                                                      AND [a].[DatabaseName] = [m].[DatabaseName]
WHERE           [m].[DatabaseName] IS NULL;



------------------------------------------------------------
--// EMAIL THE NOTIFICATIONS                            //--
------------------------------------------------------------

-- only send an email if there are new alerts, or if something changed in the past 4 hours
IF EXISTS(SELECT 1 FROM #MissingBackups WHERE [Status] <> ''recent'')
BEGIN
    -- set the email subject
    IF EXISTS(SELECT 1 FROM #MissingBackups WHERE [Status] = ''new'')
    BEGIN
        SET @emailSubject = N''Database Backups Out of Compliance'';
        SET @emailImportance = ''HIGH'';
    END;
    ELSE IF EXISTS(SELECT 1 FROM #MissingBackups WHERE [Status] = ''old'')
    BEGIN
        SET @emailSubject = N''Database Backups Remain Out of Compliance'';
        SET @emailImportance = ''HIGH'';
    END;
    ELSE IF EXISTS(SELECT 1 FROM #MissingBackups WHERE [Status] = ''compliant'')
    BEGIN
        SET @emailSubject = N''Database Backups Are Back In Compliance'';
        SET @emailImportance = ''NORMAL'';
    END;

    -- css formatting for email body
    INSERT INTO #EmailBody ( [EmailText] )
    SELECT N''<html>''                                     + NCHAR(0x000D) + NCHAR(0x000A) +
           N''<head>''                                     + NCHAR(0x000D) + NCHAR(0x000A) +
           N''<style type="text/css">''                    + NCHAR(0x000D) + NCHAR(0x000A) +
           N''div.a''                                      + NCHAR(0x000D) + NCHAR(0x000A) +
           N''{''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    font-family: verdana,arial,sans-serif;'' + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    display: block;''                        + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    font-size: 18px;''                       + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    margin-top: 1em;''                       + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    margin-bottom: 0em;''                    + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    margin-left: 0;''                        + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    margin-right: 0;''                       + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    font-weight: bold;''                     + NCHAR(0x000D) + NCHAR(0x000A) +
           N''}''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''div.b''                                      + NCHAR(0x000D) + NCHAR(0x000A) +
           N''{''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    font-family: verdana,arial,sans-serif;'' + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    display: block;''                        + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    font-size: 18px;''                       + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    margin-top: 1em;''                       + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    margin-bottom: 0.5em;''                    + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    margin-left: 0;''                        + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    margin-right: 0;''                       + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    font-weight: bold;''                     + NCHAR(0x000D) + NCHAR(0x000A) +
           N''}''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''div.c''                                      + NCHAR(0x000D) + NCHAR(0x000A) +
           N''{''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    font-family: verdana,arial,sans-serif;'' + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    display: block;''                        + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    font-size: 12px;''                       + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    color:#333333;''                         + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    margin-top: 0em;''                       + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    margin-bottom: 1em;''                    + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    margin-left: 0;''                        + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    margin-right: 0;''                       + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    font-weight: normal;''                   + NCHAR(0x000D) + NCHAR(0x000A) +
           N''}''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''div.d''                                      + NCHAR(0x000D) + NCHAR(0x000A) +
           N''{''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    font-family: verdana,arial,sans-serif;'' + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    display: block;''                        + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    font-size:11px;''                        + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    font-style:italic;''                     + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    color:#333333;''                         + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    margin-top: 2em;''                       + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    margin-bottom: 1em;''                    + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    margin-left: 0;''                        + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    margin-right: 0;''                       + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    font-weight: normal;''                   + NCHAR(0x000D) + NCHAR(0x000A) +
           N''}''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''table.gridtable''                            + NCHAR(0x000D) + NCHAR(0x000A) +
           N''{''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    font-family: verdana,arial,sans-serif;'' + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    font-size:11px;''                        + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    color:#333333;''                         + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    border-width: 1px;''                     + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    border-color: #666666;''                 + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    border-collapse: collapse;''             + NCHAR(0x000D) + NCHAR(0x000A) +
           N''}''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''table.gridtable th ''                        + NCHAR(0x000D) + NCHAR(0x000A) +
           N''{''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    border-width: 1px;''                     + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    padding: 8px;''                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    border-style: solid;''                   + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    border-color: #666666;''                 + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    background-color: #dedede;''             + NCHAR(0x000D) + NCHAR(0x000A) +
           N''}''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''table.gridtable td ''                        + NCHAR(0x000D) + NCHAR(0x000A) +
           N''{''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    border-width: 1px;''                     + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    padding: 8px;''                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    border-style: solid;''                   + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    border-color: #666666;''                 + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    background-color: #ffffff;''             + NCHAR(0x000D) + NCHAR(0x000A) +
           N''}''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''table.gridtable .category''                  + NCHAR(0x000D) + NCHAR(0x000A) +
           N''{''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    background-color:#dedede;''              + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    font-weight: bold;''                     + NCHAR(0x000D) + NCHAR(0x000A) +
           N''}''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''table.gridtable .red''                       + NCHAR(0x000D) + NCHAR(0x000A) +
           N''{''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    background-color:#ff0000;''              + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    color:#ffffff;''                         + NCHAR(0x000D) + NCHAR(0x000A) +
           N''}''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''table.gridtable .yellow''                    + NCHAR(0x000D) + NCHAR(0x000A) +
           N''{''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    background-color:#ffff00;''              + NCHAR(0x000D) + NCHAR(0x000A) +
           N''}''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''table.gridtable .green''                     + NCHAR(0x000D) + NCHAR(0x000A) +
           N''{''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    background-color:#80ff00;''              + NCHAR(0x000D) + NCHAR(0x000A) +
           N''}''                                          + NCHAR(0x000D) + NCHAR(0x000A) +
           N''</style>''                                   + NCHAR(0x000D) + NCHAR(0x000A) +
           N''</head>''                                    + NCHAR(0x000D) + NCHAR(0x000A) + NCHAR(0x000D) + NCHAR(0x000A) +
           N''<body>''; 

    INSERT INTO #EmailBody ( [EmailText] )
    SELECT N''<div class="a">Database Backup Compliance</div>''                                             + NCHAR(0x000D) + NCHAR(0x000A) +
           N''<div class="c">''                                                                             + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    &nbsp;&nbsp;&nbsp;&nbsp;&#8226;&nbsp;<b>Full</b> - once per week<br>''                    + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    &nbsp;&nbsp;&nbsp;&nbsp;&#8226;&nbsp;<b>Differential</b> - once per day<br>''             + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    &nbsp;&nbsp;&nbsp;&nbsp;&#8226;&nbsp;<b>Transaction Log</b> - every fifteen minutes<br>'' + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    &nbsp;&nbsp;&nbsp;&nbsp;&#8226;&nbsp;<b>Full (system db)</b> - once per day<br>''         + NCHAR(0x000D) + NCHAR(0x000A) +
           N''</div>'';

    -- new databases out of compliance
    IF EXISTS(SELECT 1 FROM #MissingBackups WHERE [Status] = ''new'')
    BEGIN
        INSERT INTO #EmailBody ( [EmailText] )
        SELECT N''<div class="b">Out of Compliance (New):</div>''    + NCHAR(0x000D) + NCHAR(0x000A) +
               N''<table border="1" class="gridtable">'' + NCHAR(0x000D) + NCHAR(0x000A) +
               N''    <tr>''                             + NCHAR(0x000D) + NCHAR(0x000A) +
               N''        <th>ComplianceType</th>''      + NCHAR(0x000D) + NCHAR(0x000A) +
               N''        <th>Server</th>''              + NCHAR(0x000D) + NCHAR(0x000A) +
               N''        <th>DatabaseName</th>''        + NCHAR(0x000D) + NCHAR(0x000A) +
               N''        <th>RecoveryModel</th>''       + NCHAR(0x000D) + NCHAR(0x000A) +
               N''        <th>CreateDate</th>''          + NCHAR(0x000D) + NCHAR(0x000A) +
               N''        <th>FullBackup</th>''          + NCHAR(0x000D) + NCHAR(0x000A) +
               N''        <th>DiffBackup</th>''          + NCHAR(0x000D) + NCHAR(0x000A) +
               N''        <th>LogBackup</th>''           + NCHAR(0x000D) + NCHAR(0x000A) +
               N''        <th>CurrentServerTime</th>''   + NCHAR(0x000D) + NCHAR(0x000A) +
               N''    </tr>'';

        INSERT INTO #EmailBody ( [EmailText] )
        SELECT   N''    <tr>'' + CHAR(10) +
                 N''        <td align = "right">'' + [ComplianceType] + ''</td>''                           + NCHAR(0x000D) + NCHAR(0x000A) +
                 N''        <td align = "right">'' + [Server] + ''</td>''                                   + NCHAR(0x000D) + NCHAR(0x000A) +
                 N''        <td align = "right">'' + [DatabaseName] + ''</td>''                             + NCHAR(0x000D) + NCHAR(0x000A) +
                 N''        <td align = "right">'' + [RecoveryModel] + ''</td>''                            + NCHAR(0x000D) + NCHAR(0x000A) +
                 N''        <td align = "right">'' + CONVERT(NCHAR(19),[CreateDate],120) + ''</td>''        + NCHAR(0x000D) + NCHAR(0x000A) +
                 CASE [ComplianceType]
                     WHEN ''1 - Full'' THEN N''        <td align = "right" class = "yellow">'' + CONVERT(NCHAR(19),[FullBackup],120) + ''</td>''
                     ELSE                 N''        <td align = "right">                 '' + CONVERT(NCHAR(19),[FullBackup],120) + ''</td>''
                 END                                                                                    + NCHAR(0x000D) + NCHAR(0x000A) +
                 CASE [ComplianceType]
                     WHEN ''2 - Diff'' THEN N''        <td align = "right" class = "yellow">'' + CONVERT(NCHAR(19),[DiffBackup],120) + ''</td>''
                     ELSE                 N''        <td align = "right">''                  + CONVERT(NCHAR(19),[DiffBackup],120) + ''</td>''
                 END                                                                                    + NCHAR(0x000D) + NCHAR(0x000A) +
                 CASE [ComplianceType]
                     WHEN ''3 - Log''  THEN N''        <td align = "right" class = "yellow">'' + CONVERT(NCHAR(19),[LogBackup],120) + ''</td>''
                     ELSE                 N''        <td align = "right">''                  + CONVERT(NCHAR(19),[LogBackup],120) + ''</td>''
                 END                                                                                    + NCHAR(0x000D) + NCHAR(0x000A) +
                 N''        <td align = "right">'' + CONVERT(NCHAR(19),[CurrentServerTime],120) + ''</td>'' + NCHAR(0x000D) + NCHAR(0x000A) +
                 N''    </tr>''
        FROM     #MissingBackups
        WHERE    [Status] = ''new''
        ORDER BY [ComplianceType],
                 [DatabaseName];

        INSERT INTO #EmailBody ( [EmailText] )
        SELECT N''</table>'';
    END;

    -- databases still out of compliance
    IF EXISTS(SELECT 1 FROM #MissingBackups WHERE [Status] IN (''recent'',''old''))
    BEGIN
        INSERT INTO #EmailBody ( [EmailText] )
        SELECT N''<div class="b">Still Out of Compliance:</div>''    + NCHAR(0x000D) + NCHAR(0x000A) +
               N''<table border="1" class="gridtable">'' + NCHAR(0x000D) + NCHAR(0x000A) +
               N''    <tr>''                             + NCHAR(0x000D) + NCHAR(0x000A) +
               N''        <th>ComplianceType</th>''      + NCHAR(0x000D) + NCHAR(0x000A) +
               N''        <th>Server</th>''              + NCHAR(0x000D) + NCHAR(0x000A) +
               N''        <th>DatabaseName</th>''        + NCHAR(0x000D) + NCHAR(0x000A) +
               N''        <th>RecoveryModel</th>''       + NCHAR(0x000D) + NCHAR(0x000A) +
               N''        <th>CreateDate</th>''          + NCHAR(0x000D) + NCHAR(0x000A) +
               N''        <th>FullBackup</th>''          + NCHAR(0x000D) + NCHAR(0x000A) +
               N''        <th>DiffBackup</th>''          + NCHAR(0x000D) + NCHAR(0x000A) +
               N''        <th>LogBackup</th>''           + NCHAR(0x000D) + NCHAR(0x000A) +
               N''        <th>CurrentServerTime</th>''   + NCHAR(0x000D) + NCHAR(0x000A) +
               N''    </tr>'';

        INSERT INTO #EmailBody ( [EmailText] )
        SELECT   N''    <tr>'' + CHAR(10) +
                 N''        <td align = "right">'' + [ComplianceType] + ''</td>''                           + NCHAR(0x000D) + NCHAR(0x000A) +
                 N''        <td align = "right">'' + [Server] + ''</td>''                                   + NCHAR(0x000D) + NCHAR(0x000A) +
                 N''        <td align = "right">'' + [DatabaseName] + ''</td>''                             + NCHAR(0x000D) + NCHAR(0x000A) +
                 N''        <td align = "right">'' + [RecoveryModel] + ''</td>''                            + NCHAR(0x000D) + NCHAR(0x000A) +
                 N''        <td align = "right">'' + CONVERT(NCHAR(19),[CreateDate],120) + ''</td>''        + NCHAR(0x000D) + NCHAR(0x000A) +
                 CASE [ComplianceType]
                     WHEN ''1 - Full'' THEN N''        <td align = "right" class = "yellow">'' + CONVERT(NCHAR(19),[FullBackup],120) + ''</td>''
                     ELSE                 N''        <td align = "right">                 '' + CONVERT(NCHAR(19),[FullBackup],120) + ''</td>''
                 END                                                                                    + NCHAR(0x000D) + NCHAR(0x000A) +
                 CASE [ComplianceType]
                     WHEN ''2 - Diff'' THEN N''        <td align = "right" class = "yellow">'' + CONVERT(NCHAR(19),[DiffBackup],120) + ''</td>''
                     ELSE                 N''        <td align = "right">''                  + CONVERT(NCHAR(19),[DiffBackup],120) + ''</td>''
                 END                                                                                    + NCHAR(0x000D) + NCHAR(0x000A) +
                 CASE [ComplianceType]
                     WHEN ''3 - Log''  THEN N''        <td align = "right" class = "yellow">'' + CONVERT(NCHAR(19),[LogBackup],120) + ''</td>''
                     ELSE                 N''        <td align = "right">''                  + CONVERT(NCHAR(19),[LogBackup],120) + ''</td>''
                 END                                                                                    + NCHAR(0x000D) + NCHAR(0x000A) +
                 N''        <td align = "right">'' + CONVERT(NCHAR(19),[CurrentServerTime],120) + ''</td>'' + NCHAR(0x000D) + NCHAR(0x000A) +
                 N''    </tr>''
        FROM     #MissingBackups
        WHERE    [Status] IN (''recent'',''old'')
        ORDER BY [ComplianceType],
                 [DatabaseName];

        INSERT INTO #EmailBody ( [EmailText] )
        SELECT N''</table>'';
    END;

    -- databases still out of compliance
    IF EXISTS(SELECT 1 FROM #MissingBackups WHERE [Status] = ''compliant'')
    BEGIN
        INSERT INTO #EmailBody ( [EmailText] )
        SELECT N''<div class="b">Back In Compliance:</div>''         + NCHAR(0x000D) + NCHAR(0x000A) +
               N''<table border="1" class="gridtable">'' + NCHAR(0x000D) + NCHAR(0x000A) +
               N''    <tr>''                             + NCHAR(0x000D) + NCHAR(0x000A) +
               N''        <th>Server</th>''              + NCHAR(0x000D) + NCHAR(0x000A) +
               N''        <th>DatabaseName</th>''        + NCHAR(0x000D) + NCHAR(0x000A) +
               N''    </tr>'';

        INSERT INTO #EmailBody ( [EmailText] )
        SELECT   N''    <tr>'' + CHAR(10) +
                 N''        <td align = "right">'' + [Server] + ''</td>''                                   + NCHAR(0x000D) + NCHAR(0x000A) +
                 N''        <td align = "right">'' + [DatabaseName] + ''</td>''                             + NCHAR(0x000D) + NCHAR(0x000A) +
                 N''    </tr>''
        FROM     #MissingBackups
        WHERE    [Status] = ''compliant''
        ORDER BY [ComplianceType],
                 [DatabaseName];

        INSERT INTO #EmailBody ( [EmailText] )
        SELECT N''</table>'';
    END;

    INSERT INTO #EmailBody ( [EmailText] )
    SELECT N''<div class="d">''                                                                               + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    This job, [DBA - Backup Compliance], runs every 5 minutes to check for backup compliance, but will only email an alert if a status changes or database backups are still out of compliance four hours after the last alert was sent. It checks for:<br>''                                       + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    &nbsp;&nbsp;&nbsp;&nbsp;&#8226;&nbsp;User databases without a full backup in the last 7 days<br>''                    + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    &nbsp;&nbsp;&nbsp;&nbsp;&#8226;&nbsp;User databases without a full or differential backup in the last 24 hours<br>''             + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    &nbsp;&nbsp;&nbsp;&nbsp;&#8226;&nbsp;User databases in full recovery model without a transaction log backup in the last 20 minutes<br>'' + NCHAR(0x000D) + NCHAR(0x000A) +
           N''    &nbsp;&nbsp;&nbsp;&nbsp;&#8226;&nbsp;System databases without a full backup in the last 24 hours<br>''         + NCHAR(0x000D) + NCHAR(0x000A) +
           N''</div>''                                                                              + NCHAR(0x000D) + NCHAR(0x000A) +
           N''</body>'';

    -- put the email text into one variable
    SELECT   @emailBody = COALESCE(@emailBody, '''') + NCHAR(0x000D) + NCHAR(0x000A) + [EmailText] 
    FROM     #EmailBody 
    ORDER BY [ID];   

    -- send the email
    EXECUTE [msdb].[dbo].[sp_send_dbmail] @profile_name = @emailProfile,
                                          @recipients   = @emailRecipients,
                                          @subject      = @emailSubject,
                                          @body         = @emailBody,
                                          @importance   = @emailImportance,
                                          @body_format  = ''HTML'';
    --PRINT @emailBody;
END;



------------------------------------------------------------
--// UPDATE THE PERSISTANT ALERT TABLE                  //--
------------------------------------------------------------

-- add the new ones                                                      --
INSERT INTO [dbo].[MissingBackupAlerts] ([ComplianceType],[DatabaseName],[AlertSent])
SELECT [ComplianceType],
       [DatabaseName],
       [CurrentServerTime]
FROM   #MissingBackups
WHERE  [Status] = ''new'';

-- update the ones that are still here
UPDATE     [a]
SET        [a].[AlertSent] = [m].[CurrentServerTime]
FROM       #MissingBackups             AS [m]
INNER JOIN [dbo].[MissingBackupAlerts] AS [a] ON [m].[ComplianceType] = [a].[ComplianceType]
                                                 AND [m].[DatabaseName] = [a].[DatabaseName]
WHERE      [m].[Status] IN (''recent'',''old'');

-- delete the ones that are now compliant
DELETE     [a] 
FROM       [dbo].[MissingBackupAlerts] AS [a]
INNER JOIN #MissingBackups             AS [m] ON [m].[ComplianceType] = [a].[ComplianceType]
                                                 AND [m].[DatabaseName] = [a].[DatabaseName]
WHERE      [m].[Status] = ''compliant'';



------------------------------------------------------------
--// CLEAN UP                                           //--
------------------------------------------------------------

IF OBJECT_ID(N''tempdb..#MissingBackups'',N''U'') IS NOT NULL DROP TABLE #MissingBackups;
IF OBJECT_ID(N''tempdb..#EmailBody'',N''U'') IS NOT NULL DROP TABLE #EmailBody;



--  SELECT * FROM CentralAdmin.[dbo].[MissingBackupAlerts];
  DELETE FROM CentralAdmin.[dbo].[MissingBackupAlerts];
--  UPDATE CentralAdmin.[dbo].[MissingBackupAlerts] SET alertsent = ''2018-01-25 06:55:36.460'';

';

EXECUTE [msdb].[dbo].[sp_update_job] @job_name                     = @myJobName, 
                                     @start_step_id                = 1;



------------------------------------------------
--// CREATE THE SCHEDULE                    //--
------------------------------------------------

EXECUTE [msdb].[dbo].[sp_add_jobschedule] @job_name               = @myJobName, 
                                          @name                   = @myScheduleName, 
                                          @enabled                = 1, 
                                          @freq_type              = 4, -- 1 = Once, 4 = Daily, 8 = Weekly, 16 = Monthly, 32 = Monthly, relative to frequency_interval, 64 = Run when the SQL Server Agent service starts, 128 = Run when teh computer is idle
                                          @freq_interval          = 1, 
                                          @freq_subday_type       = 4, -- 1 = At specified time, 4 = Minutes, 8 = Hours
                                          @freq_subday_interval   = 5, 
                                          @freq_relative_interval = 0, -- 1 = First, 2 = Second, 4 = Third, 8 = Fourth, 16 = Last
                                          @freq_recurrence_factor = 1, -- Number of weeks or months between the scheduled execution of the job
                                          @active_start_date      = 20170101, 
                                          @active_end_date        = 99991231, 
                                          @active_start_time      = 0, 
                                          @active_end_time        = 235959;


