/*
    TROUBLESHOOT_ServerConnections.sql

    View entries in CentralAdmin.dbo.ServerConnections sectioned by job runs
*/

USE CentralAdmin;

-- user input
DECLARE @start AS DATETIME = N'2018-05-15 12:20:00.000',
        @end   AS DATETIME = N'2018-05-15 13:20:00.000',
        @split AS INT      = 5;


DECLARE @entryTime AS DATETIME = @start;

WHILE @entryTime <= @end
BEGIN
    SELECT   * 
    FROM     dbo.ServerConnections
    WHERE    EntryDate >= @entryTime
             AND EntryDate < DATEADD(MINUTE,@split,@entryTime)
    ORDER BY EntryDate,
             SPID;

    SET @entryTime = DATEADD(MINUTE,@split,@entryTime);
END;
