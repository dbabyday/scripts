/* sp_help_revlogin script 
** Generated Feb 25 2015 10:56AM on CO-DB-981 */
 
 
-- Login: ##MS_PolicyTsqlExecutionLogin##
CREATE LOGIN [##MS_PolicyTsqlExecutionLogin##] WITH PASSWORD = 0x01008D22A249DF5EF3B79ED321563A1DCCDC9CFC5FF954DD2D0F HASHED, SID = 0x8F651FE8547A4644A0C06CA83723A876, DEFAULT_DATABASE = [master], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF; ALTER LOGIN [##MS_PolicyTsqlExecutionLogin##] DISABLE
 
-- Login: NT AUTHORITY\SYSTEM
CREATE LOGIN [NT AUTHORITY\SYSTEM] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NT SERVICE\MSSQLSERVER
CREATE LOGIN [NT SERVICE\MSSQLSERVER] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\tim.boesken.admin
CREATE LOGIN [NA\tim.boesken.admin] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NT SERVICE\SQLSERVERAGENT
CREATE LOGIN [NT SERVICE\SQLSERVERAGENT] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcmsqldev.neen
CREATE LOGIN [NA\srvcmsqldev.neen] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US Site MSSQL Administrators in NA
CREATE LOGIN [NA\Neenah-US Site MSSQL Administrators in NA] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\BI Report Tester Authorized Users
CREATE LOGIN [AP\BI Report Tester Authorized Users] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\BI Report Writer Authorized Users
CREATE LOGIN [AP\BI Report Writer Authorized Users] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Neenah-US GSF Analysts in AP
CREATE LOGIN [AP\Neenah-US GSF Analysts in AP] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Neenah-US GSF Developers in AP
CREATE LOGIN [AP\Neenah-US GSF Developers in AP] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Neenah-US GSF Testers in AP
CREATE LOGIN [AP\Neenah-US GSF Testers in AP] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Neenah-US GSF Users in AP
CREATE LOGIN [AP\Neenah-US GSF Users in AP] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EU\Neenah-US GSF Users in EU
CREATE LOGIN [EU\Neenah-US GSF Users in EU] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\BI Report Tester Authorized Users
CREATE LOGIN [NA\BI Report Tester Authorized Users] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\BI Report Writer Authorized Users
CREATE LOGIN [NA\BI Report Writer Authorized Users] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\BI Reporting_xxx_BAE_Systems_Operations
CREATE LOGIN [NA\BI Reporting_xxx_BAE_Systems_Operations] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\BI Reports DEV ITAR Authorized Users
CREATE LOGIN [NA\BI Reports DEV ITAR Authorized Users] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\BI Reports DEV ITAR nonAuthorized Users
CREATE LOGIN [NA\BI Reports DEV ITAR nonAuthorized Users] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\ITAR Authorized Service Accounts
CREATE LOGIN [NA\ITAR Authorized Service Accounts] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\ITAR Authorized Users
CREATE LOGIN [NA\ITAR Authorized Users] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\ITAR Authorized Users in NA
CREATE LOGIN [NA\ITAR Authorized Users in NA] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\MES_Report_Designers
CREATE LOGIN [NA\MES_Report_Designers] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\MES_Report_Users_Dev
CREATE LOGIN [NA\MES_Report_Users_Dev] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US Business Intelligence Dev Team
CREATE LOGIN [NA\Neenah-US Business Intelligence Dev Team] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US GSF Analysts in NA
CREATE LOGIN [NA\Neenah-US GSF Analysts in NA] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US GSF AzMan Administrators
CREATE LOGIN [NA\Neenah-US GSF AzMan Administrators] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US GSF Developers in NA
CREATE LOGIN [NA\Neenah-US GSF Developers in NA] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US GSF Testers in NA
CREATE LOGIN [NA\Neenah-US GSF Testers in NA] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US GSF Users in NA
CREATE LOGIN [NA\Neenah-US GSF Users in NA] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US SQL Test Engineering Services users in Neenah-US
CREATE LOGIN [NA\Neenah-US SQL Test Engineering Services users in Neenah-US] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Reporting GSF_Ext_Access
CREATE LOGIN [NA\Reporting GSF_Ext_Access] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\sqldatafix.neen
CREATE LOGIN [NA\sqldatafix.neen] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcBaeRprtsDev.neen
CREATE LOGIN [NA\srvcBaeRprtsDev.neen] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcdevetl.na
CREATE LOGIN [NA\srvcdevetl.na] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcGSFAgileMax.dev
CREATE LOGIN [NA\srvcGSFAgileMax.dev] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcGSFApp.dev
CREATE LOGIN [NA\srvcGSFApp.dev] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcGSFBatch.dev
CREATE LOGIN [NA\srvcGSFBatch.dev] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcGSFETL.dev
CREATE LOGIN [NA\srvcGSFETL.dev] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcgsfitar.na
CREATE LOGIN [NA\srvcgsfitar.na] FROM WINDOWS WITH DEFAULT_DATABASE = [master]; DENY CONNECT SQL TO [NA\srvcgsfitar.na]
 
-- Login: NA\srvcGSFStuffer605.De
CREATE LOGIN [NA\srvcGSFStuffer605.De] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcisdevitar.neen
CREATE LOGIN [NA\srvcisdevitar.neen] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcmes.neen
CREATE LOGIN [NA\srvcmes.neen] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcmsql.neen
CREATE LOGIN [NA\srvcmsql.neen] FROM WINDOWS WITH DEFAULT_DATABASE = [master]; ALTER LOGIN [NA\srvcmsql.neen] DISABLE
 
-- Login: NA\srvcsqlexecacct
CREATE LOGIN [NA\srvcsqlexecacct] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvctdci.neen
CREATE LOGIN [NA\srvctdci.neen] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Reporting GSF_Ext_ITAR_Access
CREATE LOGIN [NA\Reporting GSF_Ext_ITAR_Access] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\SRVCWSS3
CREATE LOGIN [NA\SRVCWSS3] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: BUILTIN\Administrators
CREATE LOGIN [BUILTIN\Administrators] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\CO-WEB-968$
CREATE LOGIN [NA\CO-WEB-968$] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\CO-WEB-973$
CREATE LOGIN [NA\CO-WEB-973$] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: ProclarityAdmin
CREATE LOGIN [ProclarityAdmin] WITH PASSWORD = 0x01006BD1640DC5199BC146ECEBAC918FBA60166AB944AD743081 HASHED, SID = 0x3F9E0658193B6744B1B1B7606EA1C8BF, DEFAULT_DATABASE = [master], CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF
 
-- Login: NA\srvcwss3_dev.neen
CREATE LOGIN [NA\srvcwss3_dev.neen] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcgsfwss.na
CREATE LOGIN [NA\srvcgsfwss.na] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\TG_IT
CREATE LOGIN [NA\TG_IT] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcppsmon_dev.neen
CREATE LOGIN [NA\srvcppsmon_dev.neen] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Tim.Boesken
CREATE LOGIN [NA\Tim.Boesken] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US Informational Worker Team
CREATE LOGIN [NA\Neenah-US Informational Worker Team] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Penang-MY Site MSSQL Administrators in AP
CREATE LOGIN [AP\Penang-MY Site MSSQL Administrators in AP] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Penang-MY GSF L9 Developer
CREATE LOGIN [AP\Penang-MY GSF L9 Developer] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US GSF L9 Developer
CREATE LOGIN [NA\Neenah-US GSF L9 Developer] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Penang-MY GSF L0 View Only
CREATE LOGIN [AP\Penang-MY GSF L0 View Only] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US GSF L0 View Only
CREATE LOGIN [NA\Neenah-US GSF L0 View Only] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Penang-MY GSF L10 Analyst
CREATE LOGIN [AP\Penang-MY GSF L10 Analyst] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US GSF L10 Analyst
CREATE LOGIN [NA\Neenah-US GSF L10 Analyst] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AgileInterface_DEV
CREATE LOGIN [AgileInterface_DEV] WITH PASSWORD = 0x0100E8569BB868255E40C563BE4CAA5FB472A493CA5BB3E152AC HASHED, SID = 0x2B1D0CED14CD3049A21624681E904B13, DEFAULT_DATABASE = [master], CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF
 
-- Login: NA\srvcdatacapdev.neen
CREATE LOGIN [NA\srvcdatacapdev.neen] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EU\BI Report Tester Authorized Users
CREATE LOGIN [EU\BI Report Tester Authorized Users] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcGSFWSS.Dev
CREATE LOGIN [NA\srvcGSFWSS.Dev] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US TorqueDriver DB Programmers
CREATE LOGIN [NA\Neenah-US TorqueDriver DB Programmers] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\GRP IT WI Development
CREATE LOGIN [NA\GRP IT WI Development] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US GSF L1 Line Personnel
CREATE LOGIN [NA\Neenah-US GSF L1 Line Personnel] FROM WINDOWS WITH DEFAULT_DATABASE = [master]; REVOKE CONNECT SQL TO [NA\Neenah-US GSF L1 Line Personnel]
 
-- Login: NA\Neenah-US GSF L2 Supervisor
CREATE LOGIN [NA\Neenah-US GSF L2 Supervisor] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US GSF L3 Technician
CREATE LOGIN [NA\Neenah-US GSF L3 Technician] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US GSF L4 Supervisor & Technician
CREATE LOGIN [NA\Neenah-US GSF L4 Supervisor & Technician] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US GSF L5 Engineer
CREATE LOGIN [NA\Neenah-US GSF L5 Engineer] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US GSF L6 Super User
CREATE LOGIN [NA\Neenah-US GSF L6 Super User] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US GSF L7 Site Admin
CREATE LOGIN [NA\Neenah-US GSF L7 Site Admin] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US GSF L8 IT_BSG Admin
CREATE LOGIN [NA\Neenah-US GSF L8 IT_BSG Admin] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Penang-MY GSF L1 Line Personnel
CREATE LOGIN [AP\Penang-MY GSF L1 Line Personnel] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Penang-MY GSF L2 Supervisor
CREATE LOGIN [AP\Penang-MY GSF L2 Supervisor] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Penang-MY GSF L3 Technician
CREATE LOGIN [AP\Penang-MY GSF L3 Technician] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Penang-MY GSF L4 Supervisor & Technician
CREATE LOGIN [AP\Penang-MY GSF L4 Supervisor & Technician] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Penang-MY GSF L5 Engineer
CREATE LOGIN [AP\Penang-MY GSF L5 Engineer] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Penang-MY GSF L6 Super User
CREATE LOGIN [AP\Penang-MY GSF L6 Super User] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Penang-MY GSF L7 Site Admin
CREATE LOGIN [AP\Penang-MY GSF L7 Site Admin] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Penang-MY GSF L8 IT_BSG Admin
CREATE LOGIN [AP\Penang-MY GSF L8 IT_BSG Admin] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EXT\Neenah-us GSF Developers Users in EXT
CREATE LOGIN [EXT\Neenah-us GSF Developers Users in EXT] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US Sharepoint Administrators
CREATE LOGIN [NA\Neenah-US Sharepoint Administrators] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US Sharepoint Administrators in Neenah-US
CREATE LOGIN [NA\Neenah-US Sharepoint Administrators in Neenah-US] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\phil.schultz.admin
CREATE LOGIN [NA\phil.schultz.admin] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US GSF Developers
CREATE LOGIN [NA\Neenah-US GSF Developers] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US Application Test Users
CREATE LOGIN [NA\Neenah-US Application Test Users] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US SQL GSM Users in Appleton-US
CREATE LOGIN [NA\Neenah-US SQL GSM Users in Appleton-US] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US SQL Test Engineering users in Neenah-US
CREATE LOGIN [NA\Neenah-US SQL Test Engineering users in Neenah-US] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US GSF Analysts
CREATE LOGIN [NA\Neenah-US GSF Analysts] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US Biztalk Administrators Dev in NA
CREATE LOGIN [NA\Neenah-US Biztalk Administrators Dev in NA] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US Site Biztalk SSO Administrators Dev
CREATE LOGIN [NA\Neenah-US Site Biztalk SSO Administrators Dev] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US Biztalk Administrators Dev
CREATE LOGIN [NA\Neenah-US Biztalk Administrators Dev] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcbiztalkdev.na
CREATE LOGIN [NA\srvcbiztalkdev.na] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\srvcgsfapp.dev
CREATE LOGIN [AP\srvcgsfapp.dev] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: MaxInterface_DEV
CREATE LOGIN [MaxInterface_DEV] WITH PASSWORD = 0x010011998DC66AD898F6FB4B3BE6B9E049196A517E971A54FA97 HASHED, SID = 0x6039D5BBAD25F541A6021B1732805604, DEFAULT_DATABASE = [master], CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF
 
-- Login: NA\srvcMaxDev.na
CREATE LOGIN [NA\srvcMaxDev.na] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US Business Intelligence Dev Consultants ITAR Users NA
CREATE LOGIN [NA\Neenah-US Business Intelligence Dev Consultants ITAR Users NA] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US Business Intelligence Dev Consultants Users NA
CREATE LOGIN [NA\Neenah-US Business Intelligence Dev Consultants Users NA] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EXT\SSL Access to co-ap-939 for BizTalk
CREATE LOGIN [EXT\SSL Access to co-ap-939 for BizTalk] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: na\srvcssodev.na
CREATE LOGIN [na\srvcssodev.na] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: biztalk360
CREATE LOGIN [biztalk360] WITH PASSWORD = 0x01003D3290FD2EEBB0F556DDC969466CD0F5C48CAEB0FCD43E38 HASHED, SID = 0x0F9247E24B91CF4A81C1FC413F8411F8, DEFAULT_DATABASE = [master], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF
 
-- Login: ##MS_PolicyEventProcessingLogin##
CREATE LOGIN [##MS_PolicyEventProcessingLogin##] WITH PASSWORD = 0x0100C33D08FDF84A2E9D36078892D56709332B64C9ED6994AE16 HASHED, SID = 0xEB51FAA949C2AB4382C664A3ADD066A0, DEFAULT_DATABASE = [master], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF; ALTER LOGIN [##MS_PolicyEventProcessingLogin##] DISABLE
 
-- Login: NA\Neenah-US GSF L11 Inspection Only
CREATE LOGIN [NA\Neenah-US GSF L11 Inspection Only] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcwss3_intsp_dv.na
CREATE LOGIN [NA\srvcwss3_intsp_dv.na] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EXT\Neenah-US GSF L11 Inspection Only
CREATE LOGIN [EXT\Neenah-US GSF L11 Inspection Only] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcbiztalktst.na
CREATE LOGIN [NA\srvcbiztalktst.na] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcars_dv.na
CREATE LOGIN [NA\srvcars_dv.na] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcneenopsdev.na
CREATE LOGIN [NA\srvcneenopsdev.na] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcATEFilesTST.neen
CREATE LOGIN [NA\srvcATEFilesTST.neen] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Brian.Struebing
CREATE LOGIN [NA\Brian.Struebing] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: StufferInterface_DEV
CREATE LOGIN [StufferInterface_DEV] WITH PASSWORD = 0x01001EB843E4822B71A4FC8635C593F5930C5FEC242717E33987 HASHED, SID = 0xD6DAF6FE7142D44196D253220805BD85, DEFAULT_DATABASE = [master], CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF
 
-- Login: NA\srvcwss3SpBuildDV.na
CREATE LOGIN [NA\srvcwss3SpBuildDV.na] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\patrick.konkle.admin
CREATE LOGIN [NA\patrick.konkle.admin] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: na\srvcwss3_cp_dev.neen
CREATE LOGIN [na\srvcwss3_cp_dev.neen] FROM WINDOWS WITH DEFAULT_DATABASE = [xcAdmin]
 
-- Login: AP\Xiamen-CN GSF L8 IT_BSG Admin
CREATE LOGIN [AP\Xiamen-CN GSF L8 IT_BSG Admin] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\srvcsql.penadb508
CREATE LOGIN [AP\srvcsql.penadb508] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EU\Oradea-RO CAM_UserORA Users in Oradea-RO
CREATE LOGIN [EU\Oradea-RO CAM_UserORA Users in Oradea-RO] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Neenah-US Citrix CAM Users In Penang-MY
CREATE LOGIN [AP\Neenah-US Citrix CAM Users In Penang-MY] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Xiamen-CN GSF L10 Analyst
CREATE LOGIN [AP\Xiamen-CN GSF L10 Analyst] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\suresh.koritala
CREATE LOGIN [AP\suresh.koritala] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\jeff.gonnering
CREATE LOGIN [NA\jeff.gonnering] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EU\Neenah-US GSF L0 View Only
CREATE LOGIN [EU\Neenah-US GSF L0 View Only] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EU\Neenah-US GSF L1 Line Personnel
CREATE LOGIN [EU\Neenah-US GSF L1 Line Personnel] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EU\Neenah-US GSF L2 Supervisor
CREATE LOGIN [EU\Neenah-US GSF L2 Supervisor] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EU\Neenah-US GSF L3 Technician
CREATE LOGIN [EU\Neenah-US GSF L3 Technician] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EU\Neenah-US GSF L4 Supervisor & Technician
CREATE LOGIN [EU\Neenah-US GSF L4 Supervisor & Technician] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EU\Neenah-US GSF L5 Engineer
CREATE LOGIN [EU\Neenah-US GSF L5 Engineer] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EU\Neenah-US GSF L6 Super User
CREATE LOGIN [EU\Neenah-US GSF L6 Super User] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EU\Neenah-US GSF L7 Site Admin
CREATE LOGIN [EU\Neenah-US GSF L7 Site Admin] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EU\Neenah-US GSF L8 IT_BSG Admin
CREATE LOGIN [EU\Neenah-US GSF L8 IT_BSG Admin] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EU\Neenah-US GSF L9 Developer
CREATE LOGIN [EU\Neenah-US GSF L9 Developer] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EU\Neenah-US GSF L10 Analyst
CREATE LOGIN [EU\Neenah-US GSF L10 Analyst] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EU\Neenah-US GSF L11 Inspection Only
CREATE LOGIN [EU\Neenah-US GSF L11 Inspection Only] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Xiamen-CN GSF L1 Line Personnel
CREATE LOGIN [AP\Xiamen-CN GSF L1 Line Personnel] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Xiamen-CN GSF L2 Supervisor
CREATE LOGIN [AP\Xiamen-CN GSF L2 Supervisor] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Xiamen-CN GSF L3 Technician
CREATE LOGIN [AP\Xiamen-CN GSF L3 Technician] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Xiamen-CN GSF L4 Supervisor & Technician
CREATE LOGIN [AP\Xiamen-CN GSF L4 Supervisor & Technician] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Xiamen-CN GSF L5 Engineer
CREATE LOGIN [AP\Xiamen-CN GSF L5 Engineer] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Xiamen-CN GSF L6 Super User
CREATE LOGIN [AP\Xiamen-CN GSF L6 Super User] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Xiamen-CN GSF L7 Site Admin
CREATE LOGIN [AP\Xiamen-CN GSF L7 Site Admin] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcPrideDevApps
CREATE LOGIN [NA\srvcPrideDevApps] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srcdclink
CREATE LOGIN [NA\srcdclink] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\chin-yen.sin
CREATE LOGIN [AP\chin-yen.sin] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\kb.teow
CREATE LOGIN [AP\kb.teow] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US Business Intelligence Dev Team Non-ITAR Users in NA
CREATE LOGIN [NA\Neenah-US Business Intelligence Dev Team Non-ITAR Users in NA] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcusracctdev.na
CREATE LOGIN [NA\srvcusracctdev.na] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Domain Users
CREATE LOGIN [NA\Domain Users] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Domain Users
CREATE LOGIN [AP\Domain Users] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US EA Web Apps - Dev Admins Users in NA
CREATE LOGIN [NA\Neenah-US EA Web Apps - Dev Admins Users in NA] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\larry.kubier
CREATE LOGIN [NA\larry.kubier] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\stevenbh.ooi
CREATE LOGIN [AP\stevenbh.ooi] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\Neenah-US Systems Integration Development Users in Neenah-US
CREATE LOGIN [NA\Neenah-US Systems Integration Development Users in Neenah-US] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: edi
CREATE LOGIN [edi] WITH PASSWORD = 0x01006B23378C160BF41D85BC94A3084180B20EB9B14A593B1AFB HASHED, SID = 0xE75533E347AB40419677BA7F0451FC8A, DEFAULT_DATABASE = [master], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF
 
-- Login: aro
CREATE LOGIN [aro] WITH PASSWORD = 0x0100F6406E3338894828406D78C95BA440830F37EA8094CFB04F HASHED, SID = 0xB527E70E353E2D478063B0449E8456F1, DEFAULT_DATABASE = [master], CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF
 
-- Login: EU\srvcoradweb001.orad
CREATE LOGIN [EU\srvcoradweb001.orad] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EU\abi.orad
CREATE LOGIN [EU\abi.orad] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Penang-MY GSF T0 View Only
CREATE LOGIN [AP\Penang-MY GSF T0 View Only] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Penang-MY GSF T1 Line Personnel
CREATE LOGIN [AP\Penang-MY GSF T1 Line Personnel] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Penang-MY GSF T2 Supervisor
CREATE LOGIN [AP\Penang-MY GSF T2 Supervisor] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Penang-MY GSF T3 Technician
CREATE LOGIN [AP\Penang-MY GSF T3 Technician] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Penang-MY GSF T4 Supervisor & Technician
CREATE LOGIN [AP\Penang-MY GSF T4 Supervisor & Technician] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: AP\Penang-MY GSF T5 Engineer
CREATE LOGIN [AP\Penang-MY GSF T5 Engineer] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\lee.hart
CREATE LOGIN [NA\lee.hart] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: ap\srvcapp.pena.dev
CREATE LOGIN [ap\srvcapp.pena.dev] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\patrick.konkle
CREATE LOGIN [NA\patrick.konkle] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EU\Domain Users
CREATE LOGIN [EU\Domain Users] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\scott.lamers.admin
CREATE LOGIN [NA\scott.lamers.admin] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcNOPoApproval.dev
CREATE LOGIN [NA\srvcNOPoApproval.dev] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: EU\Neenah-US CitrixXA MAX QA Users in EMEA
CREATE LOGIN [EU\Neenah-US CitrixXA MAX QA Users in EMEA] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\james.lutsey.admin
CREATE LOGIN [NA\james.lutsey.admin] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcNOUtils&Train.na
CREATE LOGIN [NA\srvcNOUtils&Train.na] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NA\srvcESD.neen
CREATE LOGIN [NA\srvcESD.neen] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
