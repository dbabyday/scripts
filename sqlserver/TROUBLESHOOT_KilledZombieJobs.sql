DECLARE
       @cols  NVARCHAR(MAX),
       @pivot AS NVARCHAR(MAX);

CREATE TABLE [#data] (
       [job_name]     VARCHAR(100),
       [cancel_date]  VARCHAR(8),
       [cancel_count] INT
       );

INSERT INTO [#data]
SELECT [jobname],
          CONVERT(VARCHAR(8), [DateStopped], 112),
          COUNT(1)
FROM   [CentralAdmin].[ssis].[StoppedJobs]
WHERE  [DateStopped] > DATEADD(MONTH, -1, GETDATE())
GROUP BY [jobname],
              CONVERT(VARCHAR(8), [DateStopped], 112);

SELECT @cols = ISNULL(@cols+',', '')+QUOTENAME([cancel_date])
FROM (SELECT DISTINCT
                     CONVERT(VARCHAR(8), [DateStopped], 112) AS [cancel_date]
         FROM   [CentralAdmin].[ssis].[StoppedJobs]) AS [dateranges]
WHERE  [cancel_date] > DATEADD(MONTH, -1, GETDATE());

SET @pivot = 'select job_name, '+@cols+' from #data PIVOT(SUM(cancel_count) FOR cancel_date IN ('+@cols+')) AS pvtTable';

EXECUTE [sys].[sp_executesql]
              @command = @pivot;

DROP TABLE [#data];
