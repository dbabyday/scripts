/*********************************************************
* 
* Get the most recent test connection results
* 
*********************************************************/

IF @@SERVERNAME != 'CO-DB-042'
BEGIN
    RAISERROR('Wrong server - setting NOEXEC ON',16,1);
    SET NOEXEC ON;
END

-- servers not reachable
SELECT [ServerName],
       CASE [Result]
           WHEN 0 THEN 'failed'
           WHEN 1 THEN 'passed'
       END AS [Result],
       [TestTime] 
FROM   [CentralAdmin].[dbo].[ServerTestConnection]
WHERE  [Category] = 1
       AND Result = 0;

-- servers reachable
SELECT COUNT(*)      AS [ServersPassed],
       MIN(TestTime) AS [TestsStarted],
       MAX(TestTime) AS [TestsEnded]
FROM   [CentralAdmin].[dbo].[ServerTestConnection]
WHERE  [Category] = 1
       AND Result = 1;