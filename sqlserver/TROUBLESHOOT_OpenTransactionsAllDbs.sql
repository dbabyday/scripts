/*********************************************************************************************************************
* 
* TROUBLESHOOT_OpenTransactionsAllDbs.sql
* 
* Author: James Lutsey
* Date:   2018-12-31
* 
* Safe for prod: YES
* 
* Purpose: Selects details of oldest open transaction from each database.
*          Also shows any blocking chains so you can see how if/how the open transactions are affecting other transactions.
* 
* Date        Name                  Description of change
* ----------  --------------------  ---------------------------------------------------------------------------------
* 
* 
*********************************************************************************************************************/




set nocount on;

declare @db                    as nvarchar(128)
      , @oldact_spid           as int
      , @oldact_uid            as int
      , @oldact_name           as varchar(128)
      , @oldact_recoveryunitid as int
      , @oldact_lsn            as varchar(128)
      , @oldact_starttime      as datetime2(3)
      , @oldact_sid            as varbinary(85)
      , @sql                   as nvarchar(max);

-- Create the temporary table to accept the results. 
if object_id(N'tempdb..#OpenTranStatus',N'U') is not null drop table #OpenTranStatus;
create table #OpenTranStatus 
(  
      property varchar(25)  
    , value    sql_variant   
);  

if object_id(N'tempdb..#AllOpenTrans',N'U') is not null drop table #AllOpenTrans;
create table #AllOpenTrans 
(  
      db                    nvarchar(128)
    , OLDACT_SPID           int
    , OLDACT_UID            int
    , OLDACT_NAME           varchar(128)
    , OLDACT_RECOVERYUNITID int
    , OLDACT_LSN            varchar(128)
    , OLDACT_STARTTIME      datetime2(3)
    , OLDACT_SID            varbinary(85)
);

-- cursor to loop through all databases
declare dbnames cursor local fast_forward for
    select name
    from   sys.databases
    where  state = 0;

open dbnames;
    fetch next from dbnames into @db;

    while @@fetch_status = 0
    begin
        -- Execute the command, putting the results in the table.  
        set @sql = N'use [' + @db + N'];'                                          + nchar(0x000D) + nchar(0x000A) +
                   N'insert into #OpenTranStatus'                                  + nchar(0x000D) + nchar(0x000A) +
                   N'execute(N''dbcc opentran with tableresults, no_infomsgs'');';
        
        execute sys.sp_executesql @stmt = @sql;
        
        -- if there are results add them to the cumulative table
        if exists(select 1 from #OpenTranStatus)
        begin
            select @oldact_spid           = cast(value as int)           from #OpenTranStatus where property = 'OLDACT_SPID';
            select @oldact_uid            = cast(value as int)           from #OpenTranStatus where property = 'OLDACT_UID';
            select @oldact_name           = cast(value as varchar(128))  from #OpenTranStatus where property = 'OLDACT_NAME';
            select @oldact_recoveryunitid = cast(value as int)           from #OpenTranStatus where property = 'OLDACT_RECOVERYUNITID';
            select @oldact_lsn            = cast(value as varchar(128))  from #OpenTranStatus where property = 'OLDACT_LSN';
            select @oldact_starttime      = cast(value as datetime2(3))  from #OpenTranStatus where property = 'OLDACT_STARTTIME';
            select @oldact_sid            = cast(value as varbinary(85)) from #OpenTranStatus where property = 'OLDACT_SID';
            
            insert into #AllOpenTrans (db, OLDACT_SPID, OLDACT_UID, OLDACT_NAME, OLDACT_RECOVERYUNITID, OLDACT_LSN, OLDACT_STARTTIME, OLDACT_SID)
            values (@db, @oldact_spid, @oldact_uid, @oldact_name, @oldact_recoveryunitid, @oldact_lsn, @oldact_starttime, @oldact_sid);
        
            truncate table #OpenTranStatus;
        end;

        fetch next from dbnames into @db;
    end;
close dbnames;
deallocate dbnames;

-- Display the results.  
select   t.db
       , s.session_id
       , t.OLDACT_NAME
       , t.OLDACT_STARTTIME
       , datediff(minute, OLDACT_STARTTIME, getdate()) as minutes_open
       , s.login_name
       , s.original_login_name
       , s.host_name
       , s.status
       , s.last_request_start_time
       , s.last_request_end_time
       --, t.*
       --, s.*
from     #AllOpenTrans        as t
join     sys.dm_exec_sessions as s on s.session_id = t.OLDACT_SPID
order by t.OLDACT_STARTTIME;

-- clean up
if object_id(N'tempdb..#OpenTranStatus',N'U') is not null drop table #OpenTranStatus;
if object_id(N'tempdb..#AllOpenTrans',N'U') is not null drop table #AllOpenTrans;

GO





/*********************************************************************************************************************

    TROUBLESHOOT_BlockingChain.sql

*********************************************************************************************************************/

DECLARE @spid       AS NVARCHAR(11),
        @blkSerries AS INT,
        @blkSpid    AS INT;

IF OBJECT_ID(N'tempdb..#SpWho2',N'U') IS NOT NULL DROP TABLE #SpWho2;
CREATE TABLE #SpWho2
(
    SPID        INT           NULL,
    Status      NVARCHAR(MAX) NULL,
    Login       NVARCHAR(128) NULL,
    HostName    NVARCHAR(128) NULL,
    BlkBy       NVARCHAR(128) NULL,
    DBName      NVARCHAR(128) NULL,
    Command     NVARCHAR(MAX) NULL,
    CPUTime     BIGINT        NULL,
    DiskIO      BIGINT        NULL,
    LastBatch   NVARCHAR(MAX) NULL,
    ProgramName NVARCHAR(MAX) NULL,
    SPID2       INT           NULL,
    REQUESTID   INT           NULL,
    is_selected BIT           NOT NULL DEFAULT (0)
);

IF OBJECT_ID(N'tempdb..#BlockingChains',N'U') IS NOT NULL DROP TABLE #BlockingChains;
CREATE TABLE #BlockingChains
(
    SPID        INT           NULL,
    Status      NVARCHAR(MAX) NULL,
    Login       NVARCHAR(128) NULL,
    HostName    NVARCHAR(128) NULL,
    BlkBy       NVARCHAR(128) NULL,
    DBName      NVARCHAR(128) NULL,
    Command     NVARCHAR(MAX) NULL,
    CPUTime     BIGINT        NULL,
    DiskIO      BIGINT        NULL,
    LastBatch   NVARCHAR(MAX) NULL,
    ProgramName NVARCHAR(MAX) NULL,
    SPID2       INT           NULL,
    REQUESTID   INT           NULL,
    BlkSerries  INT           NULL,
    BlkOrder    INT           NULL
);

IF OBJECT_ID(N'tempdb..#Buffer',N'U') IS NOT NULL DROP TABLE #Buffer;
CREATE TABLE #Buffer
(
    SPID         INT            NULL,
    EventType    NVARCHAR(30)   NULL,
    [Parameters] SMALLINT       NULL,
    EventInfo    NVARCHAR(4000) NULL
);

DECLARE Spids CURSOR LOCAL FAST_FORWARD FOR
    SELECT DISTINCT CAST(SPID AS NVARCHAR(11))
    FROM   #BlockingChains
    WHERE  SPID IS NOT NULL;

-- get sp_who2 info
INSERT INTO #SpWho2 ( SPID, Status, Login, HostName, BlkBy, DBName, Command, CPUTime, DiskIO, LastBatch, ProgramName, SPID2, REQUESTID )
EXECUTE sys.sp_who2;

-- 
SET @blkSerries = 1;

SELECT TOP(1) @spid = CAST(SPID AS NVARCHAR(11)),
              @blkSpid = BlkBy
FROM          #SpWho2 AS a 
WHERE         BlkBy <> N'  .' 
              AND NOT EXISTS(SELECT 1 FROM #SpWho2 AS b WHERE b.BlkBy = CAST(a.SPID AS NVARCHAR(128)))
              AND a.is_selected = 0;

WHILE @spid IS NOT NULL
BEGIN
    UPDATE #SpWho2
    SET    is_selected = 1
    WHERE  SPID = @spid;    
    
    WHILE EXISTS(SELECT 1 FROM #SpWho2 WHERE CAST(SPID AS NVARCHAR(11)) = @spid AND BlkBy <> '  .')
    BEGIN
        UPDATE #BlockingChains
        SET    BlkOrder = BlkOrder + 1
        WHERE  BlkSerries = @blkSerries;
        
        INSERT INTO #BlockingChains (SPID,Status,Login,HostName,BlkBy,DBName,Command,CPUTime,DiskIO,LastBatch,ProgramName,SPID2,REQUESTID,BlkSerries,BlkOrder)
        SELECT TOP(1) SPID,Status,Login,HostName,BlkBy,DBName,Command,CPUTime,DiskIO,LastBatch,ProgramName,SPID2,REQUESTID,@blkSerries,1
        FROM   #SpWho2
        WHERE  SPID = @spid;
        
        SELECT TOP(1) @spid = BlkBy
        FROM   #SpWho2
        WHERE  CAST(SPID AS NVARCHAR(11)) = @spid;
    END;

    UPDATE #BlockingChains
    SET    BlkOrder = BlkOrder + 1
    WHERE  BlkSerries = @blkSerries;
        
    INSERT INTO #BlockingChains (SPID,Status,Login,HostName,BlkBy,DBName,Command,CPUTime,DiskIO,LastBatch,ProgramName,SPID2,REQUESTID,BlkSerries,BlkOrder)
    SELECT TOP(1) SPID,Status,Login,HostName,BlkBy,DBName,Command,CPUTime,DiskIO,LastBatch,ProgramName,SPID2,REQUESTID,@blkSerries,1
    FROM   #SpWho2
    WHERE  SPID = @spid;

    INSERT INTO #BlockingChains (SPID,Status,Login,HostName,BlkBy,DBName,Command,CPUTime,DiskIO,LastBatch,ProgramName,SPID2,REQUESTID,BlkSerries,BlkOrder)
    VALUES(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@blkSerries,999999999);
    
    SET @blkSerries += 1;
    SET @spid        = NULL;

    SELECT TOP(1) @spid = SPID,
                  @blkSpid = BlkBy
    FROM          #SpWho2 AS a 
    WHERE         BlkBy <> N'  .' 
                  AND NOT EXISTS(SELECT 1 FROM #SpWho2 AS b WHERE b.BlkBy = CAST(a.SPID AS NVARCHAR(128)))
                  AND a.is_selected = 0;
END;

OPEN Spids;
    FETCH NEXT FROM Spids INTO @spid;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            INSERT INTO #Buffer (EventType,Parameters,EventInfo)
            EXECUTE(N'DBCC INPUTBUFFER(' + @spid + N');');

            UPDATE #Buffer
            SET    SPID = CAST(@spid AS INT)
            WHERE  SPID IS NULL;
        END TRY
        BEGIN CATCH
            WAITFOR DELAY '00:00:00'; -- do nothing
        END CATCH;

        FETCH NEXT FROM Spids INTO @spid;
    END;
CLOSE Spids;
DEALLOCATE Spids;

SELECT          c.SPID,
                c.BlkBy,
                c.Status,
                c.Login,
                c.HostName,
                c.DBName,
                c.Command,
                c.CPUTime,
                c.DiskIO,
                c.LastBatch,
                c.ProgramName,
                --c.SPID2,
                --c.REQUESTID,
                --c.BlkSerries,
                --c.BlkOrder,
                b.EventInfo
FROM            #BlockingChains AS c
LEFT OUTER JOIN #Buffer         AS b ON b.SPID = c.SPID
ORDER BY        c.BlkSerries,
                c.BlkOrder;

-- clean up
IF OBJECT_ID(N'tempdb..#SpWho2',N'U') IS NOT NULL DROP TABLE #SpWho2;
IF OBJECT_ID(N'tempdb..#BlockingChains',N'U') IS NOT NULL DROP TABLE #BlockingChains;
IF OBJECT_ID(N'tempdb..#Buffer',N'U') IS NOT NULL DROP TABLE #Buffer;

GO



