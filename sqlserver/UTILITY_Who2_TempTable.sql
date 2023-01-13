DECLARE
       @who TABLE (
       [SPID]        INT,
       [status]      VARCHAR(1000) NULL,
       [LOGIN]       SYSNAME NULL,
       [hostname]    SYSNAME NULL,
       [blkby]       SYSNAME NULL,
       [dbname]      SYSNAME NULL,
       [command]     VARCHAR(1000) NULL,
       [cputime]     INT NULL,
       [diskio]      INT NULL,
       [lastbatch]   VARCHAR(1000) NULL,
       [programname] VARCHAR(1000) NULL,
       [spid2]       INT,
       [requestid]   INT NULL
       );

DECLARE @buffer TABLE ([SPID] INT NULL, [EventType] NVARCHAR(30) NULL, [Parameters] SMALLINT NULL, [EventInfo] NVARCHAR(4000) NULL);

INSERT INTO @who
EXEC [sp_who2];

DECLARE
    @spid   VARCHAR(50)
    
DECLARE run_cursor CURSOR FOR
       SELECT spid
       FROM   @who
       WHERE  [spid] > 50
                 AND [LOGIN] <> SYSTEM_USER

OPEN run_cursor
FETCH NEXT FROM run_cursor INTO @spid

WHILE @@FETCH_STATUS = 0
    BEGIN
              BEGIN TRY     
                     INSERT INTO @buffer ([EventType], [Parameters], [EventInfo])
                     EXEC('DBCC INPUTBUFFER(' + @spid + ') WITH NO_INFOMSGS')

                     UPDATE @buffer
                     SET [SPID] = @spid
                     WHERE [SPID] IS null
              END TRY
        BEGIN CATCH
                     --do nothing
              END CATCH     
        FETCH NEXT FROM run_cursor INTO @spid

    END

CLOSE run_cursor
DEALLOCATE run_cursor 

SELECT  w.SPID,
        w.status,
        w.LOGIN,
        w.hostname,
        w.blkby,
        w.dbname,
        w.command,
        w.cputime,
        w.diskio,
        w.lastbatch,
        w.programname,
              --b.EventType,
              b.EventInfo
FROM    @who w 
       LEFT JOIN @buffer b ON b.SPID = w.SPID
WHERE w.[spid] > 50
              --AND [LOGIN] <> SYSTEM_USER
              --AND w.programname <> 'Replication Distribution Agent'
              --AND w.blkby <> '  .'
			  --and dbname in ('Contour_DEV','Contour_QA')
order by dbname,login

