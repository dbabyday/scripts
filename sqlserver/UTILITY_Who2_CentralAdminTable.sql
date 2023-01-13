/*************************************************************************************
* 
* Put sp_who2 results into a table to allow review/save
* 
*************************************************************************************/


USE [CentralAdmin];
GO

DECLARE @LastID INT;

-- create the table if it does not already exist
IF OBJECT_ID(N'CentralAdmin.dbo.Who2', N'U') IS NULL
	CREATE TABLE [CentralAdmin].[dbo].[Who2]
	(
		[ID]             INT IDENTITY(1,1),
		[SPID]           INT,
		[Status]         VARCHAR(MAX),
		[Login]          VARCHAR(MAX),
		[HostName]       VARCHAR(MAX),
		[BlkBy]          VARCHAR(MAX),
		[DBName]         VARCHAR(MAX),
		[Command]        VARCHAR(MAX),
		[CPUTime]        INT,
		[DiskIO]         INT,
		[LastBatch]      VARCHAR(MAX),
		[ProgramName]    VARCHAR(MAX),
		[SPID_1]         INT,
		[REQUESTID]      INT,
		[EntryDate]      DATETIME
	);

-- get the last ID so we will be able to update the the correct EntryDates
SELECT @LastID = COALESCE(MAX([ID]),0) FROM [CentralAdmin].[dbo].[Who2];

-- insert current sp_who2 results
INSERT INTO [CentralAdmin].[dbo].[Who2] ([SPID],[Status],[Login],[HostName],[BlkBy],[DBName],[Command],[CPUTime],[DiskIO],[LastBatch],[ProgramName],[SPID_1],[REQUESTID]) EXEC sp_who2;
UPDATE [CentralAdmin].[dbo].[Who2] SET [EntryDate] = GETDATE() WHERE [ID] > @LastID;

-- query the results
SELECT *
FROM   [CentralAdmin].[dbo].[Who2]
--WHERE
--	SPID > 50
--	AND EntryDate > '2016-08-09'
--	 AND Login = ''
--	 AND HostName != @@SERVERNAME 
--ORDER BY 



/* -- CLEAN-UP --

DELETE FROM [CentralAdmin].[dbo].[Who2]
WHERE [EntryDate] < '2016-08-09';

*/