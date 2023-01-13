/**********************************************************************************************************
* 
* TRIGGER_LoginInfo.sql
* 
* Author: James Lutsey
* Date: 01/08/2016
* 
* Purpose: Creates a logon trigger and a table in CentralAdmin to log the info.
* 
* Note: To avoid a bad trigger not allowing logons due to the log table not existing for the insert, this 
*       trigger checks for the existance of the LogonInfo table before attempting the insert.
* 
**********************************************************************************************************/

USE [CentralAdmin];     -- select name from master.sys.databases where name = 'CentralAdmin'
GO

--IF (OBJECT_ID('LogonInfo') IS NOT NULL)   -- select TABLE_NAME from CentralAdmin.INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'LogonInfo'
--	DROP TABLE LogonInfo;

CREATE TABLE LogonInfo
(
	LogonTime	DATETIME,
	LoginName	VARCHAR(50),
	ClientHost	VARCHAR(50),
	LoginType	VARCHAR(50)
);
GO

--  SELECT * FROM CentralAdmin..LogonInfo ORDER BY LogonTime DESC
--  SELECT DISTINCT LoginName FROM CentralAdmin..LogonInfo ORDER BY LoginName

USE [master];
GO

--IF EXISTS (SELECT * FROM sys.server_triggers WHERE [type] = 'TR' AND [name] = 'LogonInfoTrigger')
--	DROP TRIGGER LogonInfoTrigger ON ALL SERVER;

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE TRIGGER LogonInfoTrigger
ON ALL SERVER WITH EXECUTE AS 'NA\srvcmsqlprod.neen'   -- select name from syslogins
FOR LOGON
AS
BEGIN

	IF (OBJECT_ID('CentralAdmin..LogonInfo') IS NOT NULL)
	BEGIN
		DECLARE 
			@LogonTriggerData xml,
			@EventTime datetime,
			@LoginName varchar(50),
			@HostName varchar(50),
			@LoginType varchar(50);
	
		SET @LogonTriggerData = eventdata();

		SET @EventTime = @LogonTriggerData.value('(/EVENT_INSTANCE/PostTime)[1]', 'datetime');
		SET @LoginName = @LogonTriggerData.value('(/EVENT_INSTANCE/LoginName)[1]', 'varchar(50)');
		SET @HostName = @LogonTriggerData.value('(/EVENT_INSTANCE/ClientHost)[1]', 'varchar(50)');
		SET @LoginType = @LogonTriggerData.value('(/EVENT_INSTANCE/LoginType)[1]', 'varchar(50)');

		IF @LoginName <> 'NA\srvcmsqlprod.neen'
		BEGIN
			INSERT INTO CentralAdmin..LogonInfo (LogonTime, LoginName, ClientHost, LoginType)
			VALUES (@EventTime, @LoginName, @HostName, @LoginType);
		END
	END

END

GO

