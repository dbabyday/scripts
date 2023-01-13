/*****************************************************************************************
* 
* UTILITY_RestoreCompleteNotification.sql
* 
* Author:  James Lutsey
* Date:    2017-10-25
* Purpose: Send email when database restore is complete.
* 
*****************************************************************************************/


--------------------------------------
--// USER INPUT                   //--
--------------------------------------

DECLARE @database AS SYSNAME = N'PLXPORTAL_TestMove';  -- select [name],[state_desc] from sys.databases order by [name];



--------------------------------------
--// GET TO WORK                  //--
--------------------------------------

-- other variables
DECLARE @emailBody AS NVARCHAR(MAX),
        @msg       AS NVARCHAR(MAX),
        @state     AS INT;

SET @emailBody = QUOTENAME(@@SERVERNAME) + N'.' + QUOTENAME(@database) + N' restore is complete.';

-- get state
SELECT @state = [state]
FROM   [sys].[databases]
WHERE  [name] = @database;

SET @msg = CONVERT(NVARCHAR(19),GETDATE(),120) + N' - state = ' + CAST(@state AS NVARCHAR(5)); 
RAISERROR(@msg,0,1) WITH NOWAIT;

-- periodically check state until it changes
WHILE @state = 1  -- restoring
BEGIN
    WAITFOR DELAY '00:00:10';

    SELECT @state = [state]
    FROM   [sys].[databases]
    WHERE  [name] = @database;

    SET @msg = CONVERT(NVARCHAR(19),GETDATE(),120) + N' - state = ' + CAST(@state AS NVARCHAR(5)); 
    RAISERROR(@msg,0,1) WITH NOWAIT;
END;

-- send notification
EXECUTE [msdb].[dbo].[sp_send_dbmail] @recipients = 'james.lutsey@plexus.com' ,
                                      @subject    = N'Restore Complete' ,
                                      @body       = @emailBody;

