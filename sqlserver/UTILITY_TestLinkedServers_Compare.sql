
--------------------------------------------------------------------------
--// TEMP TABLES                                                      //--
--------------------------------------------------------------------------

IF OBJECT_ID(N'tempdb..#LinkedServerTests1',N'U') IS NOT NULL DROP TABLE #LinkedServerTests1;
CREATE TABLE #LinkedServerTests1
(
    [local_server]  SYSNAME        NOT NULL,
    [linked_server] SYSNAME        NOT NULL,
    [outcome]       BIT            NOT NULL CONSTRAINT [DF_LinkedServerTests1_outcome] DEFAULT 1,
    [message]       NVARCHAR(4000) NULL,
    [entry_time]    DATETIME       NOT NULL CONSTRAINT [DF_LinkedServerTests1_entry_time] DEFAULT GETDATE(),

    CONSTRAINT [PK_LinkedServerTests1] PRIMARY KEY CLUSTERED ([local_server],[linked_server])
);

IF OBJECT_ID(N'tempdb..#LinkedServerTests2',N'U') IS NOT NULL DROP TABLE #LinkedServerTests2;
CREATE TABLE #LinkedServerTests2
(
    [local_server]  SYSNAME        NOT NULL,
    [linked_server] SYSNAME        NOT NULL,
    [outcome]       BIT            NOT NULL CONSTRAINT [DF_LinkedServerTests2_outcome] DEFAULT 1,
    [message]       NVARCHAR(4000) NULL,
    [entry_time]    DATETIME       NOT NULL CONSTRAINT [DF_LinkedServerTests2_entry_time] DEFAULT GETDATE(),

    CONSTRAINT [PK_LinkedServerTests2] PRIMARY KEY CLUSTERED ([local_server],[linked_server])
);



--------------------------------------------------------------------------
--// COMMANDS TO INSERT VALUES INTO #LinkedServerTests1               //--
--------------------------------------------------------------------------

INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-003',N'CO-DB-010',1,N'',N'2018-02-05 14:46:48');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-003',N'CO-DB-034',1,N'',N'2018-02-05 14:46:48');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-003',N'CO-DB-037',1,N'',N'2018-02-05 14:47:12');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-003',N'CO-DB-057',0,N'Msg 18456, Level 14, State 1, Line 1
Login failed for user ''NT AUTHORITY\ANONYMOUS LOGON''.',N'2018-02-05 14:47:12');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-003',N'JDPD',1,N'',N'2018-02-05 14:46:48');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-003',N'JDPD_TERM',1,N'',N'2018-02-05 14:46:48');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-003',N'JDPY_TERM',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "OraOLEDB.Oracle" for linked server "JDPY_TERM".',N'2018-02-05 14:46:49');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-003',N'jdsd',1,N'',N'2018-02-05 14:47:10');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-003',N'jdsp',1,N'',N'2018-02-05 14:47:10');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-003',N'SLXP',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "OraOLEDB.Oracle" for linked server "SLXP".',N'2018-02-05 14:47:10');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-003',N'SLXPD',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "OraOLEDB.Oracle" for linked server "SLXPD".',N'2018-02-05 14:47:12');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-008',N'BT-pd-mssql.db.na.plexus.com',1,N'',N'2018-02-05 14:46:48');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-010',N'BIR',1,N'',N'2018-02-05 14:46:48');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-010',N'CO-DB-003',1,N'',N'2018-02-05 14:46:48');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-010',N'CO-DB-034',1,N'',N'2018-02-05 14:46:48');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-010',N'CO-DB-037',1,N'',N'2018-02-05 14:46:53');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-010',N'JDPD',1,N'',N'2018-02-05 14:46:48');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-010',N'JDPY2',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "OraOLEDB.Oracle" for linked server "JDPY2".',N'2018-02-05 14:46:49');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-010',N'JDTRN',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "OraOLEDB.Oracle" for linked server "JDTRN".',N'2018-02-05 14:46:48');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-010',N'SLXP',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "OraOLEDB.Oracle" for linked server "SLXP".',N'2018-02-05 14:46:48');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-017',N'CO-DB-020',1,N'',N'2018-02-05 14:46:49');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-034',N'ADSI',1,N'',N'2018-02-05 14:46:49');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-034',N'CO-DB-003',1,N'',N'2018-02-05 14:46:49');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-034',N'JDPD',1,N'',N'2018-02-05 14:46:49');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-034',N'MAXITARCHECK',1,N'',N'2018-02-05 14:46:49');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-037',N'CO-DB-003',1,N'',N'2018-02-05 14:46:49');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-037',N'CO-DB-034',1,N'',N'2018-02-05 14:46:49');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-037',N'CO-DB-039',1,N'',N'2018-02-05 14:46:49');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'co-db-037',N'JDPD',0,N'Msg 7403, Level 16, State 1, Line 1
The OLE DB provider "OraOLEDB.Oracle" has not been registered.',N'2018-02-05 14:46:49');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-038',N'CO-DB-037',1,N'',N'2018-02-05 14:46:49');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-038',N'CO-DB-039',1,N'',N'2018-02-05 14:46:49');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-057',N'SLXPD',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "OraOLEDB.Oracle" for linked server "SLXPD".',N'2018-02-05 14:46:49');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-145',N'CO-DB-974',1,N'',N'2018-02-05 14:46:49');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-926',N'BI',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "MSOLAP" for linked server "BI".',N'2018-02-05 14:46:49');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-932',N'JDPD',1,N'',N'2018-02-05 14:46:50');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-941',N'BT-qa-mssql.db.na.plexus.com',1,N'',N'2018-02-05 14:46:50');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-945',N'ADSI',1,N'',N'2018-02-05 14:46:50');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-945',N'ADSI2',1,N'',N'2018-02-05 14:46:50');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-945',N'CO-DB-946',1,N'',N'2018-02-05 14:46:52');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-945',N'CO-DB-958',1,N'',N'2018-02-05 14:46:52');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-945',N'JDPY',1,N'',N'2018-02-05 14:46:50');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-945',N'JDTRN',1,N'',N'2018-02-05 14:46:50');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-945',N'MaxDbLink',1,N'',N'2018-02-05 14:46:50');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-945',N'MAXITARCHECK',1,N'',N'2018-02-05 14:46:52');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-945',N'SLXDV',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "OraOLEDB.Oracle" for linked server "SLXDV".',N'2018-02-05 14:46:50');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-946',N'SLXDV',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "OraOLEDB.Oracle" for linked server "SLXDV".',N'2018-02-05 14:46:50');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-951',N'biztalkdev.db.na.plexus.com',0,N'Msg 53, Level 16, State 1, Line 0
Named Pipes Provider: Could not open a connection to SQL Server [53]. ',N'2018-02-05 14:46:51');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-953',N'BizTalkSqlQA.DB.NA.Plexus.com',0,N'Msg 53, Level 16, State 1, Line 0
Named Pipes Provider: Could not open a connection to SQL Server [53]. ',N'2018-02-05 14:46:51');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-955',N'MAXITARCHECK',1,N'',N'2018-02-05 14:46:52');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-955\TRAIN',N'MAXITARCHECK',1,N'',N'2018-02-05 14:46:52');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-956',N'MAXITARCHECK',1,N'',N'2018-02-05 14:46:52');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-957',N'CO-DB-978',0,N'Msg 53, Level 16, State 1, Line 0
Named Pipes Provider: Could not open a connection to SQL Server [53]. ',N'2018-02-05 14:46:52');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-957',N'JDPY',1,N'',N'2018-02-05 14:47:14');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-957',N'MAXITARCHECK',1,N'',N'2018-02-05 14:47:14');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-958',N'SLXDV',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "OraOLEDB.Oracle" for linked server "SLXDV".',N'2018-02-05 14:46:53');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-960',N'BT-test-mssql.db.na.plexus.com',1,N'',N'2018-02-05 14:46:55');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-961',N'BT-DEV-mssql.db.na.plexus.com',1,N'',N'2018-02-05 14:46:55');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-965',N'CO-DB-978',0,N'Msg 53, Level 16, State 1, Line 0
Named Pipes Provider: Could not open a connection to SQL Server [53]. ',N'2018-02-05 14:46:55');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-967',N'JDPY',0,N'Msg 7403, Level 16, State 1, Line 1
The OLE DB provider "OraOLEDB.Oracle" has not been registered.',N'2018-02-05 14:47:07');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-974',N'ADSI',1,N'',N'2018-02-05 14:47:20');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-974',N'co-db-945',1,N'',N'2018-02-05 14:47:20');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-974',N'CO-DB-982',0,N'Msg 53, Level 16, State 1, Line 0
Named Pipes Provider: Could not open a connection to SQL Server [53]. ',N'2018-02-05 14:47:07');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-974',N'co-db-992',1,N'',N'2018-02-05 14:47:07');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-974',N'JDPD',1,N'',N'2018-02-05 14:47:20');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-974',N'JDPY',1,N'',N'2018-02-05 14:47:07');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-974',N'JDTRN',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "OraOLEDB.Oracle" for linked server "JDTRN".',N'2018-02-05 14:47:07');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-974',N'maxdb',1,N'',N'2018-02-05 14:47:07');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-979',N'JDPY',1,N'',N'2018-02-05 14:47:10');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-981',N'CO-DB-982\DEV2008',0,N'Msg 65535, Level 16, State 1, Line 0
SQL Server Network Interfaces: Error Locating Server/Instance Specified [xFFFFFFFF]. ',N'2018-02-05 14:47:11');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-981',N'CO-DB-992',1,N'',N'2018-02-05 14:47:31');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-981',N'JDPY',1,N'',N'2018-02-05 14:47:11');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-981',N'MAX_PRIDE_HREMP',0,N'Msg 18456, Level 14, State 1, Line 1
Login failed for user ''MaxNewUserItarCheck''.',N'2018-02-05 14:47:11');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-981',N'MaxDbLinkLocal',1,N'',N'2018-02-05 14:47:11');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-981',N'MAXITARCHECK',0,N'Msg 18456, Level 14, State 1, Line 1
Login failed for user ''MaxNewUserItarCheckDev''.',N'2018-02-05 14:47:11');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'CO-DB-984',N'BizTalk-test-mssql.db.na.plexus.com',0,N'Msg 53, Level 16, State 1, Line 0
Named Pipes Provider: Could not open a connection to SQL Server [53]. ',N'2018-02-05 14:47:10');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'DCC-SQL-TS-005',N'CO-DB-020',1,N'',N'2018-02-05 14:47:12');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'GCC-SQL-PD-007',N'CO-DB-020',1,N'',N'2018-02-05 14:47:12');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-009',N'JDPD',1,N'',N'2018-02-05 14:47:19');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-009',N'LOGSHIPLINK_NAMP-DB-003_35862995',0,N'Msg 7411, Level 16, State 1, Line 1
Server ''LOGSHIPLINK_NAMP-DB-003_35862995'' is not configured for DATA ACCESS.',N'2018-02-05 14:47:19');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011',N'CO-DB-036',0,N'Msg 18456, Level 14, State 1, Line 1
Login failed for user ''NT AUTHORITY\ANONYMOUS LOGON''.',N'2018-02-05 14:47:21');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011',N'CO-DB-950',0,N'Msg 18456, Level 14, State 1, Line 1
Login failed for user ''NT AUTHORITY\ANONYMOUS LOGON''.',N'2018-02-05 14:47:21');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011',N'CRM',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "MSDASQL" for linked server "CRM".',N'2018-02-05 14:47:21');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011',N'GPL',1,N'',N'2018-02-05 14:47:21');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011',N'JNR',1,N'',N'2018-02-05 14:47:20');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011',N'JNR_CRM',1,N'',N'2018-02-05 14:47:21');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011',N'PHAT',1,N'',N'2018-02-05 14:47:20');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011',N'PURCHREQ',1,N'',N'2018-02-05 14:47:21');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011',N'SAGETGI',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "MSDASQL" for linked server "SAGETGI".',N'2018-02-05 14:47:21');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011',N'SLXPD',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "MSDASQL" for linked server "SLXPD".',N'2018-02-05 14:47:20');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011\SQLSERVER32',N'SAGE907',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "MSDASQL" for linked server "SAGE907".',N'2018-02-05 14:47:20');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011\SQLSERVER32',N'SAGE908',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "MSDASQL" for linked server "SAGE908".',N'2018-02-05 14:47:20');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011\SQLSERVER32',N'SAGE909',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "MSDASQL" for linked server "SAGE909".',N'2018-02-05 14:47:20');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011\SQLSERVER32',N'SAGE910',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "MSDASQL" for linked server "SAGE910".',N'2018-02-05 14:47:20');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011\SQLSERVER32',N'SAGE911',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "MSDASQL" for linked server "SAGE911".',N'2018-02-05 14:47:20');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011\SQLSERVER32',N'SAGE912',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "MSDASQL" for linked server "SAGE912".',N'2018-02-05 14:47:20');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011\SQLSERVER32',N'SAGE913',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "MSDASQL" for linked server "SAGE913".',N'2018-02-05 14:47:20');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011\SQLSERVER32',N'SAGE914',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "MSDASQL" for linked server "SAGE914".',N'2018-02-05 14:47:20');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011\SQLSERVER32',N'SAGE915',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "MSDASQL" for linked server "SAGE915".',N'2018-02-05 14:47:20');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011\SQLSERVER32',N'SAGE916',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "MSDASQL" for linked server "SAGE916".',N'2018-02-05 14:47:20');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011\SQLSERVER32',N'SAGE917',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "MSDASQL" for linked server "SAGE917".',N'2018-02-05 14:47:20');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-011\SQLSERVER32',N'SAGETGI',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "MSDASQL" for linked server "SAGETGI".',N'2018-02-05 14:47:20');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'NEEN-DB-012',N'ADSI',1,N'',N'2018-02-05 14:47:20');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'ORAD-AP-012',N'ORAD-DB-002',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "SQLNCLI10" for linked server "ORAD-DB-002".',N'2018-02-05 22:47:22');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'ORAD-DB-002',N'CO-DB-205.NA.PLEXUS.COM',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "SQLNCLI10" for linked server "CO-DB-205.NA.PLEXUS.COM".',N'2018-02-05 22:47:22');
INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N'ORAD-DB-002',N'ORAD-AP-012',0,N'Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "SQLNCLI10" for linked server "ORAD-AP-012".',N'2018-02-05 22:47:22');




--------------------------------------------------------------------------
--// COMMANDS TO INSERT VALUES INTO #LinkedServerTests2               //--
--------------------------------------------------------------------------





--------------------------------------------------------------------------
--// ANALYZE AND DISPLAY THE RESULTS                                  //--
--------------------------------------------------------------------------
/*
-- tests that succeeded in the first test, but failed in the second
SELECT 'New Failures' AS [new_failures],
       [b].[local_server],
       [b].[linked_server],
       [a].[outcome] AS [first_outcome],
       [a].[entry_time] AS [first_time],
       [b].[outcome]    AS [second_outcome],
       [b].[message]    AS [second_message],
       [b].[entry_time] AS [second_time]
FROM   #LinkedServerTests1 AS [a]
JOIN   #LinkedServerTests2 AS [b] ON [a].[local_server] = [b].[local_server]
                                     AND [a].[linked_server] = [b].[linked_server]
WHERE  [a].[outcome] = 1
       AND [b].[outcome] = 0;
       
-- linked servers that existed in the first test, but not in the second
SELECT          'Missing Linked Servers' AS [missing_linked_servers],*
FROM            #LinkedServerTests1 AS [a]
LEFT OUTER JOIN #LinkedServerTests2 AS [b] ON [a].[local_server] = [b].[local_server]
                                              AND [a].[linked_server] = [b].[linked_server]
WHERE           [b].[linked_server] IS NULL;

--SELECT * FROM #LinkedServerTests1;
--SELECT * FROM #LinkedServerTests2;
*/

--SELECT * FROM #LinkedServerTests1 WHERE outcome = 0;


SELECT * FROM #LinkedServerTests1 WHERE message LIKE 'Msg 53%';
SELECT * FROM #LinkedServerTests1 WHERE message LIKE '%Login failed for user ''NT AUTHORITY\ANONYMOUS LOGON''.';

SELECT * 
FROM   #LinkedServerTests1 
WHERE  outcome = 0 
       AND message NOT LIKE 'Msg 53%'
       AND message NOT LIKE '%MSDASQL%'
       AND message NOT LIKE '%Login failed for user ''NT AUTHORITY\ANONYMOUS LOGON''.';


--------------------------------------------------------------------------
--// CLEAN UP                                                         //--
--------------------------------------------------------------------------

--IF OBJECT_ID(N'tempdb..#LinkedServerTests1',N'U') IS NOT NULL DROP TABLE #LinkedServerTests1;
--IF OBJECT_ID(N'tempdb..#LinkedServerTests2',N'U') IS NOT NULL DROP TABLE #LinkedServerTests2;



