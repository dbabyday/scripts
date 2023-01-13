/************************************************************************************************
* 
* INDEX_RebuildProgress.sql
* 
* Original Script from: Lee Hart
* Additions & Updates by: James Lutsey
* Date: 12/28/2015
* 
* Purpose: Estimate the time remaining for online index rebuild
* 
* Notes:
*     1. Enter index name (line 21)
*     2. Enter start time (line 22)
* 
************************************************************************************************/

-- SELECT 'USE ' + QUOTENAME([name]) + ';' FROM [sys].[databases] ORDER BY [name];

USE [SummitCloud_Scrubs];

DECLARE 
    @indexName  VARCHAR(128) = 'PK__Executio__43CDD13120C1E124',
    @startTime  DATETIME = '2017-05-27 05:44:27';

-- PASTE HERE:

------------------------------------------------------------------------------------------------------------------
--  DISPLAY INFO ON INDEX
------------------------------------------------------------------------------------------------------------------

SELECT  
    SCHEMA_NAME(o.SCHEMA_ID) + '.' + o.name                    AS ObjectName ,
    i.name                                                     AS IndexName ,
    --i.type_desc                                                AS IndexType ,
    --p.data_compression_desc                                    AS CompressionLvl ,
    --LEFT(list, ISNULL(splitter - 1, LEN(list)))                AS IndexColumns ,
    --SUBSTRING(list, indCol.splitter + 1, 1000)                 AS IncludedColumns ,
    p.rows                                                     AS RowCnt ,
    CAST(p.rows / ( MAX(pp.rows) * 1.0 ) AS DECIMAL(15, 5))    AS PctReindexed 
FROM    
    sys.indexes i
JOIN 
    sys.objects o
    ON i.object_id = o.object_id
INNER JOIN 
    sys.partitions AS p
    ON p.object_id = o.object_id
    AND p.index_id = i.index_id
INNER JOIN 
    sys.partitions AS pp
    ON pp.object_id = o.object_id
    AND pp.index_id = i.index_id
CROSS APPLY 
    ( 
        SELECT
            NULLIF(CHARINDEX('|', indexCols.list), 0) splitter ,
            list
        FROM
            (
                SELECT
                    CAST
                        (( 
                            SELECT
                                CASE
                                    WHEN sc.is_included_column = 1 AND sc.ColPos = 1 THEN '|'
                                    ELSE ''
                                END
                                + CASE
                                    WHEN sc.ColPos > 1 THEN ', '
                                    ELSE ''
                                END 
                                + name
                            FROM     
                                ( 
                                    SELECT
                                        sc.is_included_column ,
                                        index_column_id ,
										name ,
                                        ROW_NUMBER() OVER ( PARTITION BY sc.is_included_column ORDER BY sc.index_column_id ) ColPos
                                    FROM
                                        sys.index_columns sc
                                    JOIN 
                                        sys.columns c 
                                        ON sc.object_id = c.object_id
                                        AND sc.column_id = c.column_id
                                    WHERE
                                        sc.index_id = i.index_id
                                        AND sc.object_id = i.object_id
                                ) sc
                            ORDER BY 
                                sc.is_included_column ,
                                ColPos FOR XML PATH('') ,
                                TYPE
                        ) AS varchar(MAX)) list
            ) indexCols
    ) indCol
WHERE
    i.name = @indexName
GROUP BY 
    o.schema_id ,
    o.name ,
    i.name ,
    i.type_desc ,
    p.data_compression_desc ,
    p.rows ,
    i.index_id ,
    indCol.list ,
    indCol.splitter
ORDER BY 
    1 ,
    i.index_id;


------------------------------------------------------------------------------------------------------------------
--  CALCULATE THE EXTIMATED TIME REMAINING AND ESTIMATED FINISH TIME
------------------------------------------------------------------------------------------------------------------

--DECLARE 
--    @selectedValue         decimal(15,5),
--    @now                   datetime,
--    @ellapsedSeconds       int,
--    @remainingSecondsTotal int,
--    @remainingSeconds      int,
--    @remainingMinutes      int,
--    @remainingHours        int,
--    @remainingTime         varchar(8),
--    @finishTime            varchar(8);

--DECLARE @pctDone TABLE
--(
--    ID    int              IDENTITY    PRIMARY KEY,
--    Value decimal(15,5)
--)

--INSERT INTO @pctDone ([Value])
--SELECT
--    CAST(p.rows / ( MAX(pp.rows) * 1.0 ) AS decimal(15, 5))    AS PctReindexed 
--FROM    
--    sys.indexes i
--JOIN 
--    sys.objects o
--    ON i.object_id = o.object_id
--INNER JOIN 
--    sys.partitions AS p
--    ON p.object_id = o.object_id
--    AND p.index_id = i.index_id
--INNER JOIN 
--    sys.partitions AS pp
--    ON pp.object_id = o.object_id
--    AND pp.index_id = i.index_id
--CROSS APPLY 
--    ( 
--        SELECT
--            NULLIF(CHARINDEX('|', indexCols.list), 0) splitter ,
--            list
--        FROM
--            (
--                SELECT
--                    CAST
--                        (( 
--                            SELECT
--                                CASE
--                                    WHEN sc.is_included_column = 1 AND sc.ColPos = 1 THEN '|'
--                                    ELSE ''
--                                END
--                                + CASE
--                                    WHEN sc.ColPos > 1 THEN ', '
--                                    ELSE ''
--                                END 
--                                + name
--                            FROM     
--                                ( 
--                                    SELECT
--                                        sc.is_included_column ,
--                                        index_column_id ,
--										name ,
--                                        ROW_NUMBER() OVER ( PARTITION BY sc.is_included_column ORDER BY sc.index_column_id ) ColPos
--                                    FROM
--                                        sys.index_columns sc
--                                    JOIN 
--                                        sys.columns c 
--                                        ON sc.object_id = c.object_id
--                                        AND sc.column_id = c.column_id
--                                    WHERE
--                                        sc.index_id = i.index_id
--                                        AND sc.object_id = i.object_id
--                                ) sc
--                            ORDER BY 
--                                sc.is_included_column ,
--                                ColPos FOR XML PATH('') ,
--                                TYPE
--                        ) AS varchar(MAX)) list
--            ) indexCols
--    ) indCol
--WHERE
--    i.name = @indexName
--GROUP BY 
--    o.schema_id ,
--    o.name ,
--    i.name ,
--    i.type_desc ,
--    p.data_compression_desc ,
--    p.rows ,
--    i.index_id ,
--    indCol.list ,
--    indCol.splitter;

---- select the value that is less than 1.00000
--SELECT TOP 1 @selectedValue = Value
--FROM  @pctDone
--ORDER BY Value ASC

---- calculate the time elapsed in seconds
--SET @now = GETDATE();
--SET @ellapsedSeconds =  DATEDIFF(SECOND,@startTime,@now);

---- calculate the remaining time in seconds
--SET @remainingSecondsTotal = (@ellapsedSeconds / @selectedValue) - @ellapsedSeconds;
--SET @remainingSeconds = @remainingSecondsTotal;

---- calcualte hours, minutes, and seconds from total seconds
--IF (@remainingSeconds >= 3600)
--BEGIN
--    SET @remainingHours = @remainingSeconds / 3600;
--    SET @remainingSeconds = @remainingSeconds - (@remainingHours * 3600);
--END 
--ELSE SET @remainingHours = 0;

--IF (@remainingSeconds >= 60)
--BEGIN
--    SET @remainingMinutes = @remainingSeconds / 60;
--    SET @remainingSeconds = @remainingSeconds - (@remainingMinutes * 60);
--END
--ELSE SET @remainingMinutes = 0;

---- format the values: '00:00:00'
--SET @remainingTime = RIGHT('00' + CAST(@remainingHours AS varchar(2)),2) + ':' + RIGHT('00' + CAST(@remainingMinutes AS varchar(2)),2) + ':' + RIGHT('00' + CAST(@remainingSeconds AS varchar(2)),2);

---- add reamining seconds to @now
--SET @finishTime = CONVERT(varchar, DATEADD(SECOND, @remainingSecondsTotal, @now) ,108);


------------------------------------------------------------------------------------------------------------------
--  DISPLAY THE RESULTS
------------------------------------------------------------------------------------------------------------------

--SELECT CAST(ROUND(@selectedValue*100,1) AS DECIMAL(10,1)) AS [PercentDone],
--       @remainingTime                                     AS [EstimatedRemainingTime],
--       @finishTime                                        AS [EstimatedFinishTime];

--GO


------------------------------------------------------------------------------------------------------------------
--  DISPLAY INFO ABOUT LOGSPACE 
------------------------------------------------------------------------------------------------------------------

DECLARE @tblLogSpace TABLE
(
	[DatabaseName]     NVARCHAR(128),
	[LogSize_MB]       DECIMAL(15,6),
	[LogSpaceUsed_Pct] DECIMAL(10,6),
	[Status]           INT
);

INSERT INTO @tblLogSpace
EXECUTE('DBCC SQLPERF(LOGSPACE)');

SELECT
	[DatabaseName],
	CAST(ROUND([LogSize_MB],0) AS INT) AS [LogSize_MB],
	CAST(ROUND([LogSpaceUsed_Pct],0) AS INT) AS [LogSpaceUsed_Pct]
FROM 
	@tblLogSpace
WHERE
	[DatabaseName] = DB_NAME();