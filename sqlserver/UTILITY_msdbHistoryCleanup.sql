/**************************************************************************
* 
* msdb History Cleanup
* 
* Author: James Lutsey
* Date: 11/03/2015
* 
* Purpose: Deletes backup and restore history, job history, and 
*          maintenance plan history older than a set date. This is the  
*          t-sql executed by the history cleanup task maintenance plan.
* 
* Notes: Use the queries in the commented block to see the age of msdb history.
*        Set the days before current time (row 23) to be the oldest date to keep.
* 
***************************************************************************/

/*

DECLARE @dt DATETIME 
      , @msg as nvarchar(max)
      , @i   as int = -138;
      
while @i <= -14
begin
    SELECT @dt = DATEADD(DAY, @i, GETDATE());

    set @msg = convert(nchar(19),getdate(),120) + N' | EXECUTE msdb.dbo.sp_delete_backuphistory  @oldest_date = N''' + CONVERT(nchar(19),@dt,120) + N''';'; raiserror(@msg,0,1) with nowait; 
    EXECUTE msdb.dbo.sp_delete_backuphistory  @oldest_date = @dt;
    set @msg = convert(nchar(19),getdate(),120) + N' | EXECUTE msdb.dbo.sp_purge_jobhistory  @oldest_date = N''' + CONVERT(nchar(19),@dt,120) + N''';'; raiserror(@msg,0,1) with nowait; 
    EXECUTE msdb.dbo.sp_purge_jobhistory      @oldest_date = @dt;
    set @msg = convert(nchar(19),getdate(),120) + N' | EXECUTE msdb.dbo.sp_maintplan_delete_log  @oldest_date = N''' + CONVERT(nchar(19),@dt,120) + N''';'; raiserror(@msg,0,1) with nowait; 
   EXECUTE msdb.dbo.sp_maintplan_delete_log  @oldest_time = @dt;

    set @i = @i + 1;
end
GO

--*/
--/*

SELECT 'OldestBackup' AS [Category],MAX(datediff(day, backup_start_date, GETDATE())) AS [DaysAgo]
FROM   [msdb].[dbo].[backupset]
UNION ALL
SELECT 'OldestJob' AS [Category],MAX(DATEDIFF(DAY, CAST(STUFF(STUFF(CAST([run_date] AS VARCHAR),7,0,'-'),5,0,'-') + ' ' + STUFF(STUFF(REPLACE(STR([run_time],6,0),' ','0'),5,0,':'),3,0,':') AS DATETIME), GETDATE())) AS [DaysAgo]
FROM   [msdb].[dbo].[sysjobhistory]
UNION ALL
SELECT 'OldestMaintenancePlan' AS [Category],DATEDIFF(DAY,[start_time],GETDATE()) AS [DaysAgo]
FROM   [msdb].[dbo].[sysmaintplan_log];

--*/