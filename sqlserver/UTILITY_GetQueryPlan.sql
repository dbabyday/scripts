-- get query_plan

USE [Operational_Reporting_PROD];  
GO

SELECT OBJECT_NAME([objectid]),* 
FROM   [sys].[dm_exec_cached_plans] AS [cp] 
CROSS  APPLY [sys].[dm_exec_query_plan]([cp].[plan_handle])
WHERE  OBJECT_NAME([objectid]) = 'usp_ControlChartMonitorData_Select';  
GO