/**************************************************************************************
* 
* TRACE_Errors.sql
* 
* Purpose: Create & run a server-side trace to capture errors
* 
* Notes: Enter @fileName, @finishTime, @login (blank will capture all logins), @maxFileSize
*        Additional filtering can be set at line 105
* 
**************************************************************************************/

DECLARE @fileName    NVARCHAR(128) = N'E:\Traces\Trace',
        @finishTime  DATETIME2     = '2017-06-12 12:00:00',
        @login       NVARCHAR(128) = N'',
        @maxFileSize BIGINT        = 1024, -- MB

        -- other variables
        @on          INT           = 1,
        @rc          INT,
        @traceId     INT;

-- append date and time to filename
SET @fileName += N'_' + REPLACE(CAST(CAST(GETDATE() AS DATE) AS NVARCHAR(20)),'-','') + N'_' + right('000000' + replace(convert(varchar(20),getdate(),120),':',''),6);

-- create trace
EXECUTE @rc = [master].[dbo].[sp_trace_create] @traceId OUTPUT, 0, @fileName, @maxFileSize, @finishTime; 
IF (@rc != 0)
BEGIN
	RAISERROR('Error with the sp_trace_create - setting NOEXEC ON',16,1);
	SET NOEXEC ON; -- set noexec off;
END

----------------------------------
--// SET THE EVENTS           //--
----------------------------------

--Audit Login
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  14,  1, @on; -- TextData
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  14,  6, @on; -- NTUserName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  14,  8, @on; -- HostName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  14, 10, @on; -- ApplicationName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  14, 11, @on; -- LoginName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  14, 12, @on; -- SPID
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  14, 14, @on; -- StartTime
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  14, 35, @on; -- DatabaseName

-- Audit Logout
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  15,  6, @on; -- NTUserName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  15,  8, @on; -- HostName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  15, 10, @on; -- ApplicationName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  15, 11, @on; -- LoginName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  15, 12, @on; -- SPID
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  15, 13, @on; -- Duration
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  15, 14, @on; -- StartTime
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  15, 15, @on; -- EndTime
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  15, 35, @on; -- DatabaseName

-- ExistingConnection
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  17,  1, @on; -- TextData
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  17,  6, @on; -- NTUserName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  17,  8, @on; -- HostName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  17, 10, @on; -- ApplicationName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  17, 11, @on; -- LoginName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  17, 12, @on; -- SPID
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  17, 13, @on; -- Duration
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  17, 14, @on; -- StartTime
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  17, 15, @on; -- EndTime
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  17, 35, @on; -- DatabaseName

-- EventLog
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  21,  1, @on; -- TextData
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  21,  8, @on; -- HostName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  21, 10, @on; -- ApplicationName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  21, 11, @on; -- LoginName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  21, 12, @on; -- SPID
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  21, 14, @on; -- StartTime
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  21, 20, @on; -- Severity
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  21, 26, @on; -- ServerName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  21, 31, @on; -- Error
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  21, 35, @on; -- DatabaseName

-- ErrorLog
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  22,  1, @on; -- TextData
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  22,  8, @on; -- HostName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  22, 10, @on; -- ApplicationName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  22, 11, @on; -- LoginName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  22, 12, @on; -- SPID
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  22, 14, @on; -- StartTime
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  22, 20, @on; -- Severity
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  22, 26, @on; -- ServerName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  22, 31, @on; -- Error
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  22, 35, @on; -- DatabaseName

-- Exception
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  33,  1, @on; -- TextData
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  33,  8, @on; -- HostName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  33, 10, @on; -- ApplicationName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  33, 11, @on; -- LoginName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  33, 12, @on; -- SPID
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  33, 14, @on; -- StartTime
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  33, 20, @on; -- Severity
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  33, 26, @on; -- ServerName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  33, 30, @on; -- State
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  33, 31, @on; -- Error
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId,  33, 35, @on; -- DatabaseName

-- User Error Message
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 162,  1, @on; -- TextData
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 162,  8, @on; -- HostName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 162, 10, @on; -- ApplicationName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 162, 11, @on; -- LoginName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 162, 12, @on; -- SPID
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 162, 14, @on; -- StartTime
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 162, 20, @on; -- Severity
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 162, 26, @on; -- ServerName
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 162, 30, @on; -- State
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 162, 31, @on; -- Error
EXECUTE [master].[dbo].[sp_trace_setevent] @traceId, 162, 35, @on; -- DatabaseName


----------------------------------
--// SET THE FILTERS          //--
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
EXECUTE [master].[dbo].[sp_trace_setfilter] @traceId,  31,         0,        1,             5701; -- AND Error <> (Changed database context to ...)
EXECUTE [master].[dbo].[sp_trace_setfilter] @traceId,  31,         0,        1,             5703; -- AND Error <> (Changed language setting to ...)

IF @login != N''
    EXECUTE [master].[dbo].[sp_trace_setfilter] @traceId,  11,     0,        0,             @login; -- AND LoginName LIKE 

----------------------------------
--// START THE TRACE          //--
----------------------------------

EXECUTE [master].[dbo].[sp_trace_setstatus] @traceId, 1;


----------------------------------
--// DISPLAY INFO FOR USER    //--
----------------------------------

-- display trace id and file name
SELECT N'Trace ID:',       CAST(@traceId AS NVARCHAR(10))
UNION ALL
SELECT N'File Name:',      @fileName + N'.trc'
UNION ALL
SELECT N'Get Trace Info:', N'SELECT * FROM [sys].[traces];'
UNION ALL
SELECT N'Stop Trace:',     N'EXECUTE [master].[dbo].[sp_trace_setstatus] ' + CAST(@traceId AS NVARCHAR(10)) + N', 0;'
UNION ALL
SELECT N'Close Trace:',    N'EXECUTE [master].[dbo].[sp_trace_setstatus] ' + CAST(@traceId AS NVARCHAR(10)) + N', 2;'
UNION ALL
SELECT N'Get Results:',    N'SELECT * FROM ::fn_trace_gettable(''' + @fileName + N'.trc'', default);'


----------------------------------
--// RESET IF NEEDED          //--
----------------------------------

SET NOEXEC OFF;
