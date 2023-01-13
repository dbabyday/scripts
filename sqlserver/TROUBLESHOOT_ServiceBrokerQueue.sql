-- co-db-039  SERVICE BROKER
-- Restart Stream Insight Services on Cephub-Prod


USE [Operational_Reporting_PROD];


SELECT     [queues].[Name] AS [Name],
           [pt].[Rows]     AS [QRows]
FROM       [sys].[objects]    AS [o]
INNER JOIN [sys].[partitions] AS [pt]     ON [pt].[object_id] = [o].[object_id]
INNER JOIN [sys].[objects]    AS [queues] ON [o].[parent_object_id] = [queues].[object_id]
WHERE      [pt].[index_id] = 1;

