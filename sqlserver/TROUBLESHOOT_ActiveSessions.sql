/*
    TROUBLESHOOT_ActiveSessions.sql

    View entries in CentralAdmin.dbo.ServerConnections sectioned by job runs
*/

USE CentralAdmin;

-- user input
DECLARE @start AS DATETIME = N'2022-04-28 13:58:00.000',
        @end   AS DATETIME = N'2022-04-28 14:02:00.000',
        @split AS INT      = 1;


DECLARE @entryTime AS DATETIME = @start;

WHILE @entryTime <= @end
BEGIN
    SELECT   * 
    FROM     dbo.ActiveSessions
    WHERE    EntryDate >= @entryTime
             AND EntryDate < DATEADD(MINUTE,@split,@entryTime)
    ORDER BY EntryDate,
             SessionID;

    SET @entryTime = DATEADD(MINUTE,@split,@entryTime);
END;
