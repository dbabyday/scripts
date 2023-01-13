-- MSDB JOB HISTORY MAX ROW RETENTION


/* 
-------------------------------------------
--// DISABLE MAX ROW SETTINGS          //--
-------------------------------------------

EXECUTE msdb.dbo.sp_set_sqlagent_properties 
			@jobhistory_max_rows=-1, 
			@jobhistory_max_rows_per_job=-1;
GO
--*/


-------------------------------------------
--// Get the Max Row Settings          //--
-------------------------------------------

DECLARE 
	@jobhistory_max_rows         INT,
	@jobhistory_max_rows_per_job INT;

EXECUTE master.dbo.xp_instance_regread 
			N'HKEY_LOCAL_MACHINE',
            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
            N'JobHistoryMaxRows',
            @jobhistory_max_rows OUTPUT,
            N'no_output';

EXECUTE master.dbo.xp_instance_regread 
			N'HKEY_LOCAL_MACHINE',
            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
            N'JobHistoryMaxRowsPerJob',
            @jobhistory_max_rows_per_job OUTPUT,
            N'no_output';

SELECT 
	[server]                      = @@SERVERNAME,
	[jobhistory_max_rows]         = @jobhistory_max_rows,
	[jobhistory_max_rows_per_job] = @jobhistory_max_rows_per_job;


