/**************************************************************************************
* 
* TRACE_Template.sql
* 
* Purpose: Create & run a server-side trace 
* 
* Notes: Enter @fileName, @finishTime, @login (blank will capture all logins), @maxFileSize
*        Additional filtering can be set at line 105
* 
**************************************************************************************/

DECLARE @fileName    NVARCHAR(128) = N'F:\Traces\Trace',
        @finishTime  DATETIME2(0)  = '2017-05-01 00:00:00',
        @maxfilesize BIGINT        = 1024,

        -- other variables
        @on          INT           = 1,
        @rc          INT,
        @traceId     INT;

-- append date and time to filename
SET @fileName += N'_' + REPLACE(CAST(CAST(GETDATE() AS DATE) AS NVARCHAR(20)),'-','') + N'_' + right('000000' + replace(convert(varchar(20),getdate(),120),':',''),6);

-- create trace
EXECUTE @rc = master.dbo.sp_trace_create @traceId OUTPUT, 0, @fileName, @maxfilesize, @finishTime; 
IF (@rc != 0)
BEGIN
	RAISERROR('Error with the sp_trace_create - setting NOEXEC ON',16,1);
	SET NOEXEC ON;
END

----------------------------------
--// Set the events           //--
----------------------------------

-- 	RPC:Completed
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 10, 15, @on -- EndTime
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 10,  8, @on -- HostName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 10,  1, @on -- TextData
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 10, 10, @on -- ApplicationName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 10, 11, @on -- LoginName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 10, 35, @on -- DatabaseName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 10, 12, @on -- SPID
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 10, 13, @on -- Duration
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 10,  6, @on -- NTUserName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 10, 14, @on -- StartTime

-- 	SQL:StmtStarting
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 40,  8, @on -- HostName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 40,  1, @on -- TextData
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 40,  6, @on -- NTUserName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 40, 10, @on -- ApplicationName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 40, 14, @on -- StartTime
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 40, 11, @on -- LoginName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 40, 35, @on -- DatabaseName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 40, 12, @on -- SPID


----------------------------------
--// Set the Filters          //--
----------------------------------

/*                                                   |           |         | 0 - =        |                                                          
                                                     |           |         | 1 - <>       |                                                          
                                                     |           |         | 2 - >        |                                                          
                                                     |           |         | 3 - <        |                                                          
                                                     |           |         | 4 - >=       |                                                          
                                                     |           |         | 5 - <=       |                                                          
                                                     |           | 0 - AND | 6 - LIKE     |                                                          
                                            @traceid | @columnid | 1 - OR  | 7 - NOT LIKE | @value                                                    
                                            -------- | --------- | ------- | ------------ | -------------------------------------------------------*/       
EXECUTE [master].[dbo].[sp_trace_setfilter] @traceId,  10,         0,        7,             N'SQL Server Profiler%'; -- AND ApplicationName NOT LIKE


----------------------------------
--// Set the trace status     //--
----------------------------------

EXECUTE sp_trace_setstatus @traceId, 1


----------------------------------
--// Display Info For User    //--
----------------------------------

-- display trace id and file name
SELECT [TraceID]  = @traceId,
	   [FileName] = @fileName + N'.trc';

-- commands for the trace
SELECT N'Get Trace Info:', N'SELECT * FROM [sys].[traces];'
UNION ALL
SELECT N'Stop Trace:',     N'EXECUTE [master].[dbo].[sp_trace_setstatus] ' + @traceId + N', 0;'
UNION ALL
SELECT N'Close Trace:',    N'EXECUTE [master].[dbo].[sp_trace_setstatus] ' + @traceId + N', 2;'
UNION ALL
SELECT N'Get Results:',    N'SELECT * FROM ::fn_trace_gettable(''' + @fileName + N'.trc'', default);'




-- get ready for the next attempt
SET NOEXEC OFF;
