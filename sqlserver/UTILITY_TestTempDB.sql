IF OBJECT_ID('tempdb..#TestTempDB','U') IS NOT NULL DROP TABLE #TestTempDB;
CREATE TABLE #TestTempDB
(
	[server_name]      NVARCHAR(128) NOT NULL,
	[name]             NVARCHAR(128) NOT NULL,
	[state_desc]       NVARCHAR(60)  NOT NULL,
	[user_access_desc] NVARCHAR(60)  NOT NULL
);

INSERT INTO #TestTempDB ([server_name],[name],[state_desc],[user_access_desc])
SELECT      CAST(@@SERVERNAME AS NVARCHAR(128)),
            [name],
            [state_desc],
			[user_access_desc]
FROM        [sys].[databases];

SELECT * 
FROM   #TestTempDB 
WHERE  [state_desc] != N'ONLINE'
       OR [user_access_desc] != N'MULTI_USER';

SELECT * 
FROM   #TestTempDB;

IF OBJECT_ID('tempdb..#TestTempDB','U') IS NOT NULL DROP TABLE #TestTempDB;