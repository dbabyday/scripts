DECLARE
    @spid   VARCHAR(50)
    
DECLARE
       @who1 TABLE (
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

DECLARE
       @who2 TABLE (
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

DECLARE @buffer1 TABLE ([SPID] INT NULL, [EventType] NVARCHAR(30) NULL, [Parameters] SMALLINT NULL, [EventInfo] NVARCHAR(4000) NULL);
DECLARE @buffer2 TABLE ([SPID] INT NULL, [EventType] NVARCHAR(30) NULL, [Parameters] SMALLINT NULL, [EventInfo] NVARCHAR(4000) NULL);

DECLARE run_cursor1 CURSOR FOR
       SELECT spid
       FROM   @who1
       WHERE  [spid] > 50
                 AND [LOGIN] <> SYSTEM_USER

DECLARE run_cursor2 CURSOR FOR
       SELECT spid
       FROM   @who1
       WHERE  [spid] > 50
                 AND [LOGIN] <> SYSTEM_USER

INSERT INTO @who1
EXEC [sp_who2];

OPEN run_cursor1
FETCH NEXT FROM run_cursor1 INTO @spid

WHILE @@FETCH_STATUS = 0
    BEGIN
              BEGIN TRY     
                     INSERT INTO @buffer1 ([EventType], [Parameters], [EventInfo])
                     EXEC('DBCC INPUTBUFFER(' + @spid + ') WITH NO_INFOMSGS')

                     UPDATE @buffer1
                     SET [SPID] = @spid
                     WHERE [SPID] IS null
              END TRY
        BEGIN CATCH
                     --do nothing
              END CATCH     
        FETCH NEXT FROM run_cursor1 INTO @spid

    END

CLOSE run_cursor1
DEALLOCATE run_cursor1 

WAITFOR DELAY '00:00:01';

INSERT INTO @who2
EXEC [sp_who2];

SELECT  w2.SPID,
        w2.cputime - w1.cputime AS CpuChange,
        w2.status,
        w2.LOGIN,
        w2.hostname,
        w2.blkby,
        w2.dbname,
        w2.command,
        w2.cputime,
        w2.diskio,
        w2.lastbatch,
        w2.programname,
              --b.EventType,
              b.EventInfo
FROM    @who1 w1
JOIN    @who2 w2 ON w1.SPID = w2.SPID
       LEFT JOIN @buffer1 b ON b.SPID = w1.SPID

WHERE w2.[spid] > 50
              --AND [LOGIN] <> SYSTEM_USER
              --AND w.programname <> 'Replication Distribution Agent'
              --AND w.blkby <> '  .'
ORDER BY 2 DESC;


/*
Operational_Reporting_PROD.dbo.usp_ControlChartMonitorData_Select;1

GSF2_AMER_PROD.dbo.usp_UnitStatusInquiry_Select;1
GSF2_AMER_PROD.dbo.usp_SmtWorkOrderEfficiencyUnitsData_Select;1
GSF2_AMER_PROD.dbo.usp_CustomDataCollectionDataCollectedByMultipleQuestionHeaderIdAndSourceId_Select;1
GSF2_AMER_PROD.dbo.usp_CustomDataCollectionByWorkOrderRequiredAtPti_Select;1

N'usp_SpiceBinomialPopulation_Select',
N'usp_DefectFixMultiLevelByUnit_Select',
N'usp_SmtWorkOrderEfficiencyUnitsData_Select'


N'usp_MachineByID_Select',
N'usp_LicensePlateInventory_Insert',
N'usp_LicensePlateInventory_Insert',
N'usp_SmtWorkOrderEfficiencyUnitsData_Select'

GSF2_AMER_PROD.dbo.usp_DefectFixMultiLevelByUnit_Select;1


*/