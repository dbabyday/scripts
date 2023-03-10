/***********************************************************************************************************************************************
* 
* Schedule the Disable & Enable BI Jobs to run before and after the maintenance outage.
* 
************************************************************************************************************************************************/


-- Maintenance Outage - Disable BI Jobs 
-- BeforeOutage
EXEC msdb.dbo.sp_update_schedule 
		@schedule_id=80, 
		@enabled=1, 
		@active_start_date=20160820
GO

-- Maintenance Outage - Enable BI Jobs
-- After Outage
EXEC msdb.dbo.sp_update_schedule 
		@schedule_id=113, 
		@enabled=1, 
		@active_start_date=20160820
GO
