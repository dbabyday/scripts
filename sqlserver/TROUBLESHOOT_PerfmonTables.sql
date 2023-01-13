USE [PerfMonDB];
GO
SELECT COUNT(DISTINCT CounterDateTime) FROM dbo.CounterData;
SELECT DISTINCT MachineName FROM dbo.CounterDetails;
SELECT * FROM dbo.DisplayToID;
