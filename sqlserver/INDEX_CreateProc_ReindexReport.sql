/**********************************************************************************************************
* 
* INDEX_CreateProc_ReindexReport.sql
* 
* Source: https://ola.hallengren.com
* Modified for report instead of execution: James Lutsey
* Date: 01/04/2016
* 
* Purpose: Creates stored procedure to email a report for indexes that need to be reindexed and the commands 
*          to do it. It is based on Ola hallengren's SQL Server Index and Statistics Maintenance routine. 
* 
* Notes:
*     1. This script requires CentralAdmin database
*     2. Paramater options and additional info can be found at https://ola.hallengren.com
* 
**********************************************************************************************************/

USE [CentralAdmin]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF (OBJECT_ID('usp_IndexReport') IS NULL)
    EXECUTE('CREATE PROCEDURE [usp_IndexReport] AS ;');
GO

ALTER PROCEDURE [usp_IndexReport]
    @Email                           NVARCHAR(128),
    @Databases                       NVARCHAR(max) = 'ALL_DATABASES',
    @FragmentationLow                NVARCHAR(max) = NULL,
    @FragmentationMedium             NVARCHAR(max) = 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
    @FragmentationHigh               NVARCHAR(max) = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
    @FragmentationLevel1             INT = 5,
    @FragmentationLevel2             INT = 30,
    @PageCountLevel                  INT = 1000,
    @SortInTempdb                    NVARCHAR(max) = 'N',
    @MaxDOP                          INT = NULL,
    @FillFactor                      INT = NULL,
    @PadIndex                        NVARCHAR(max) = NULL,
    @LOBCompaction                   NVARCHAR(max) = 'Y',
    @UpdateStatistics                NVARCHAR(max) = NULL,
    @OnlyModifiedStatistics          NVARCHAR(max) = 'N',
    @StatisticsSample                INT = NULL,
    @StatisticsResample              NVARCHAR(max) = 'N',
    @PartitionLevel                  NVARCHAR(max) = 'Y',
    @MSShippedObjects                NVARCHAR(max) = 'N',
    @Indexes                         NVARCHAR(max) = NULL,
    @TimeLimit                       INT = NULL,
    @Delay                           INT = NULL,
    @WaitAtLowPriorityMaxDuration    INT = NULL,
    @WaitAtLowPriorityAbortAfterWait NVARCHAR(max) = NULL,
    @LockTimeout                     INT = NULL,
    @LogToTable                      NVARCHAR(max) = 'N'
AS
BEGIN

    SET NOCOUNT ON
    SET ARITHABORT ON
    SET NUMERIC_ROUNDABORT OFF

    DECLARE @StartMessage NVARCHAR(max)
    DECLARE @EndMessage NVARCHAR(max)
    DECLARE @DatabaseMessage NVARCHAR(max)
    DECLARE @ErrorMessage NVARCHAR(max)
    DECLARE @Version NUMERIC(18, 10)
    DECLARE @AmazonRDS BIT
    DECLARE @Cluster NVARCHAR(max)
    DECLARE @StartTime DATETIME
    DECLARE @CurrentDBID INT
    DECLARE @CurrentDatabaseID INT
    DECLARE @CurrentDatabaseName NVARCHAR(max)
    DECLARE @CurrentIsDatabaseAccessible BIT
    DECLARE @CurrentAvailabilityGroup NVARCHAR(max)
    DECLARE @CurrentAvailabilityGroupRole NVARCHAR(max)
    DECLARE @CurrentDatabaseMirroringRole NVARCHAR(max)
    DECLARE @CurrentCommand01 NVARCHAR(max)
    DECLARE @CurrentCommand02 NVARCHAR(max)
    DECLARE @CurrentCommand03 NVARCHAR(max)
    DECLARE @CurrentCommand04 NVARCHAR(max)
    DECLARE @CurrentCommand05 NVARCHAR(max)
    DECLARE @CurrentCommand06 NVARCHAR(max)
    DECLARE @CurrentCommand07 NVARCHAR(max)
    DECLARE @CurrentCommand08 NVARCHAR(max)
    DECLARE @CurrentCommand09 NVARCHAR(max)
    DECLARE @CurrentCommand10 NVARCHAR(max)
    DECLARE @CurrentCommand11 NVARCHAR(max)
    DECLARE @CurrentCommand12 NVARCHAR(max)
    DECLARE @CurrentCommand13 NVARCHAR(max)
    DECLARE @CurrentCommand14 NVARCHAR(max)
    DECLARE @CurrentCommandOutput13 INT
    DECLARE @CurrentCommandOutput14 INT
    DECLARE @CurrentCommandType13 NVARCHAR(max)
    DECLARE @CurrentCommandType14 NVARCHAR(max)
    DECLARE @CurrentIxID INT
    DECLARE @CurrentSchemaID INT
    DECLARE @CurrentSchemaName NVARCHAR(max)
    DECLARE @CurrentObjectID INT
    DECLARE @CurrentObjectName NVARCHAR(max)
    DECLARE @CurrentObjectType NVARCHAR(max)
    DECLARE @CurrentIsMemoryOptimized BIT
    DECLARE @CurrentIndexID INT
    DECLARE @CurrentIndexName NVARCHAR(max)
    DECLARE @CurrentIndexType INT
    DECLARE @CurrentStatisticsID INT
    DECLARE @CurrentStatisticsName NVARCHAR(max)
    DECLARE @CurrentPartitionID BIGINT
    DECLARE @CurrentPartitionNumber INT
    DECLARE @CurrentPartitionCount INT
    DECLARE @CurrentIsPartition BIT
    DECLARE @CurrentIndexExists BIT
    DECLARE @CurrentStatisticsExists BIT
    DECLARE @CurrentIsImageText BIT
    DECLARE @CurrentIsNewLOB BIT
    DECLARE @CurrentIsFileStream BIT
    DECLARE @CurrentIsColumnStore BIT
    DECLARE @CurrentAllowPageLocks BIT
    DECLARE @CurrentNoRecompute BIT
    DECLARE @CurrentStatisticsModified BIT
    DECLARE @CurrentOnReadOnlyFileGroup BIT
    DECLARE @CurrentFragmentationLevel FLOAT
    DECLARE @CurrentPageCount BIGINT
    DECLARE @CurrentFragmentationGroup NVARCHAR(max)
    DECLARE @CurrentAction NVARCHAR(max)
    DECLARE @CurrentMaxDOP INT
    DECLARE @CurrentUpdateStatistics NVARCHAR(max)
    DECLARE @CurrentComment NVARCHAR(max)
    DECLARE @CurrentExtendedInfo XML
    DECLARE @CurrentDelay DATETIME
    DECLARE @ColumnStore  VARCHAR(3)
    DECLARE @tmpDatabases TABLE
    (
        ID           INT IDENTITY,
        DatabaseName NVARCHAR(max),
        DatabaseType NVARCHAR(max),
        Selected     BIT,
        Completed    BIT,
        PRIMARY KEY(Selected, Completed, ID)
    )
    DECLARE @tmpIndexesStatistics TABLE
    (
        ID                INT IDENTITY,
        SchemaID          INT,
        SchemaName        NVARCHAR(max),
        ObjectID          INT,
        ObjectName        NVARCHAR(max),
        ObjectType        NVARCHAR(max),
        IsMemoryOptimized BIT,
        IndexID           INT,
        IndexName         NVARCHAR(max),
        IndexType         INT,
        StatisticsID      INT,
        StatisticsName    NVARCHAR(max),
        PartitionID       BIGINT,
        PartitionNumber   INT,
        PartitionCount    INT,
        Selected          BIT,
        Completed         BIT,
        PRIMARY KEY(Selected, Completed, ID)
    )
    DECLARE @SelectedDatabases TABLE
    (
        DatabaseName NVARCHAR(max),
        DatabaseType NVARCHAR(max),
        Selected     BIT
    )
    DECLARE @SelectedIndexes TABLE
    (
        DatabaseName NVARCHAR(max),
        SchemaName   NVARCHAR(max),
        ObjectName   NVARCHAR(max),
        IndexName    NVARCHAR(max),
        Selected     BIT
    )
    DECLARE @Actions TABLE
    (
        [Action] NVARCHAR(max)
    )
    DECLARE @IndexMetrics TABLE
    ( 
		ID                 INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
		DatabaseName       NVARCHAR(128),
		IndexName		   NVARCHAR(max),
		ObjectType         NVARCHAR(5),
		IndexType          NVARCHAR(24),
		ImageText          NVARCHAR(3),
		NewLOB             NVARCHAR(3),
		FileStream         NVARCHAR(3),
		ColumnStore        NVARCHAR(3),
		AllowPageLocks     NVARCHAR(3),
		PageCount          NVARCHAR(20),
		Size_MB            NVARCHAR(20),
		Fragmentation      NVARCHAR(50),  -- check this length
		AlterIndexCommand  NVARCHAR(max),
		UpdateStatsCommand NVARCHAR(max)
    )

    INSERT INTO @Actions
    (
        [Action]
    )
    VALUES
    (
        'INDEX_REBUILD_ONLINE'
    )
    INSERT INTO @Actions
    (
        [Action]
    )
    VALUES
    (
        'INDEX_REBUILD_OFFLINE'
    )
    INSERT INTO @Actions
    (
        [Action]
    )
    VALUES
    (
        'INDEX_REORGANIZE'
    )
    DECLARE @ActionsPreferred TABLE
        (
            FragmentationGroup NVARCHAR(max),
            [Priority]         INT,
            [Action]           NVARCHAR(max)
        )
    DECLARE @CurrentActionsAllowed TABLE
        (
            [Action] NVARCHAR(max)
        )
    DECLARE @Error INT
    DECLARE @ReturnCode INT

    SET @Error = 0
    SET @ReturnCode = 0
    SET @Version = CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(max)), CHARINDEX('.', CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(max))) - 1)
                        + '.'
                        + REPLACE(RIGHT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(max)), LEN(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(max))) - CHARINDEX('.', CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(max)))), '.', '') AS NUMERIC(18, 10))
    SET @AmazonRDS = CASE
                            WHEN DB_ID('rdsadmin') IS NOT NULL
                                AND SUSER_SNAME(0x01) = 'rdsa' THEN 1
                            ELSE 0
                        END
    ----------------------------------------------------------------------------------------------------
    --// Log initial information                                                                    //--
    ----------------------------------------------------------------------------------------------------

    SET @StartTime = CONVERT(DATETIME, CONVERT(NVARCHAR, GETDATE(), 120), 120)
    SET @StartMessage = 'Date and time: ' + CONVERT(NVARCHAR, @StartTime, 120) + CHAR(13) + CHAR(10)
    SET @StartMessage = @StartMessage + 'Server: ' + CAST(SERVERPROPERTY('ServerName') AS NVARCHAR) + CHAR(13)
                        + CHAR(10)
    SET @StartMessage = @StartMessage + 'Version: ' + CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR)
                        + CHAR(13) + CHAR(10)
    SET @StartMessage = @StartMessage + 'Edition: ' + CAST(SERVERPROPERTY('Edition') AS NVARCHAR) + CHAR(13)
                        + CHAR(10)
    SET @StartMessage = @StartMessage + 'Procedure: ' + QUOTENAME(DB_NAME(DB_ID())) + '.'
                        + (SELECT QUOTENAME(schemas.NAME)
                            FROM   sys.schemas schemas
                                    INNER JOIN sys.objects objects ON schemas.[schema_id] = objects.[schema_id]
                            WHERE  [object_id] = @@PROCID)
                        + '.' + QUOTENAME(OBJECT_NAME(@@PROCID)) + CHAR(13) + CHAR(10)
    SET @StartMessage = @StartMessage + 'Parameters: @Databases = '
                        + ISNULL('''' + REPLACE(@Databases, '''', '''''') + '''', 'NULL')
    SET @StartMessage = @StartMessage + ', @FragmentationLow = '
                        + ISNULL('''' + REPLACE(@FragmentationLow, '''', '''''') + '''', 'NULL')
    SET @StartMessage = @StartMessage + ', @FragmentationMedium = '
                        + ISNULL('''' + REPLACE(@FragmentationMedium, '''', '''''') + '''', 'NULL')
    SET @StartMessage = @StartMessage + ', @FragmentationHigh = '
                        + ISNULL('''' + REPLACE(@FragmentationHigh, '''', '''''') + '''', 'NULL')
    SET @StartMessage = @StartMessage + ', @FragmentationLevel1 = '
                        + ISNULL(CAST(@FragmentationLevel1 AS NVARCHAR), 'NULL')
    SET @StartMessage = @StartMessage + ', @FragmentationLevel2 = '
                        + ISNULL(CAST(@FragmentationLevel2 AS NVARCHAR), 'NULL')
    SET @StartMessage = @StartMessage + ', @PageCountLevel = '
                        + ISNULL(CAST(@PageCountLevel AS NVARCHAR), 'NULL')
    SET @StartMessage = @StartMessage + ', @SortInTempdb = '
                        + ISNULL('''' + REPLACE(@SortInTempdb, '''', '''''') + '''', 'NULL')
    SET @StartMessage = @StartMessage + ', @MaxDOP = ' + ISNULL(CAST(@MaxDOP AS NVARCHAR), 'NULL')
    SET @StartMessage = @StartMessage + ', @FillFactor = ' + ISNULL(CAST(@FillFactor AS NVARCHAR), 'NULL')
    SET @StartMessage = @StartMessage + ', @PadIndex = '
                        + ISNULL('''' + REPLACE(@PadIndex, '''', '''''') + '''', 'NULL')
    SET @StartMessage = @StartMessage + ', @LOBCompaction = '
                        + ISNULL('''' + REPLACE(@LOBCompaction, '''', '''''') + '''', 'NULL')
    SET @StartMessage = @StartMessage + ', @UpdateStatistics = '
                        + ISNULL('''' + REPLACE(@UpdateStatistics, '''', '''''') + '''', 'NULL')
    SET @StartMessage = @StartMessage + ', @OnlyModifiedStatistics = '
                        + ISNULL('''' + REPLACE(@OnlyModifiedStatistics, '''', '''''') + '''', 'NULL')
    SET @StartMessage = @StartMessage + ', @StatisticsSample = '
                        + ISNULL(CAST(@StatisticsSample AS NVARCHAR), 'NULL')
    SET @StartMessage = @StartMessage + ', @StatisticsResample = '
                        + ISNULL('''' + REPLACE(@StatisticsResample, '''', '''''') + '''', 'NULL')
    SET @StartMessage = @StartMessage + ', @PartitionLevel = '
                        + ISNULL('''' + REPLACE(@PartitionLevel, '''', '''''') + '''', 'NULL')
    SET @StartMessage = @StartMessage + ', @MSShippedObjects = '
                        + ISNULL('''' + REPLACE(@MSShippedObjects, '''', '''''') + '''', 'NULL')
    SET @StartMessage = @StartMessage + ', @Indexes = '
                        + ISNULL('''' + REPLACE(@Indexes, '''', '''''') + '''', 'NULL')
    SET @StartMessage = @StartMessage + ', @TimeLimit = ' + ISNULL(CAST(@TimeLimit AS NVARCHAR), 'NULL')
    SET @StartMessage = @StartMessage + ', @Delay = ' + ISNULL(CAST(@Delay AS NVARCHAR), 'NULL')
    SET @StartMessage = @StartMessage + ', @WaitAtLowPriorityMaxDuration = '
                        + ISNULL(CAST(@WaitAtLowPriorityMaxDuration AS NVARCHAR), 'NULL')
    SET @StartMessage = @StartMessage + ', @WaitAtLowPriorityAbortAfterWait = '
                        + ISNULL('''' + REPLACE(@WaitAtLowPriorityAbortAfterWait, '''', '''''') + '''', 'NULL')
    SET @StartMessage = @StartMessage + ', @LockTimeout = ' + ISNULL(CAST(@LockTimeout AS NVARCHAR), 'NULL')
    SET @StartMessage = @StartMessage + ', @LogToTable = '
                        + ISNULL('''' + REPLACE(@LogToTable, '''', '''''') + '''', 'NULL')
    SET @StartMessage = @StartMessage + 'Source: https://ola.hallengren.com' + CHAR(13) + CHAR(10)
    SET @StartMessage = REPLACE(@StartMessage, '%', '%%') + ' '

    RAISERROR(@StartMessage,10,1) WITH NOWAIT

    ----------------------------------------------------------------------------------------------------
    --// Check core requirements                                                                    //--
    ----------------------------------------------------------------------------------------------------

    IF NOT EXISTS (SELECT *
                    FROM   sys.objects objects
                            INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id]
                    WHERE  objects.[type] = 'P'
                            AND schemas.[name] = 'dbo'
                            AND objects.[name] = 'CommandExecute')
        BEGIN
            SET @ErrorMessage = 'The stored procedure CommandExecute is missing. Download https://ola.hallengren.com/scripts/CommandExecute.sql.'
                                + CHAR(13) + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF EXISTS (SELECT *
                FROM   sys.objects objects
                        INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id]
                WHERE  objects.[type] = 'P'
                        AND schemas.[name] = 'dbo'
                        AND objects.[name] = 'CommandExecute'
                        AND (OBJECT_DEFINITION(objects.[object_id]) NOT LIKE '%@LogToTable%'
                            OR OBJECT_DEFINITION(objects.[object_id]) LIKE '%LOCK_TIMEOUT%'))
        BEGIN
            SET @ErrorMessage = 'The stored procedure CommandExecute needs to be updated. Download https://ola.hallengren.com/scripts/CommandExecute.sql.'
                                + CHAR(13) + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @LogToTable = 'Y'
        AND NOT EXISTS (SELECT *
                        FROM   sys.objects objects
                                INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id]
                        WHERE  objects.[type] = 'U'
                                AND schemas.[name] = 'dbo'
                                AND objects.[name] = 'CommandLog')
        BEGIN
            SET @ErrorMessage = 'The table CommandLog is missing. Download https://ola.hallengren.com/scripts/CommandLog.sql.'
                                + CHAR(13) + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF SERVERPROPERTY('EngineEdition') = 5
        AND @Version < 12
        BEGIN
            SET @ErrorMessage = 'The stored procedure IndexOptimize is not supported on this version of Azure SQL Database.'
                                + CHAR(13) + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @Error <> 0
        BEGIN
            SET @ReturnCode = @Error

            GOTO Logging
        END

    ----------------------------------------------------------------------------------------------------
    --// Select databases                                                                           //--
    ----------------------------------------------------------------------------------------------------

    SET @Databases = REPLACE(@Databases, ', ', ',');

    WITH Databases1 (StartPosition, EndPosition, DatabaseItem)
            AS (SELECT 1                                                                                                   AS StartPosition,
                    ISNULL(NULLIF(CHARINDEX(',', @Databases, 1), 0), LEN(@Databases) + 1)                               AS EndPosition,
                    SUBSTRING(@Databases, 1, ISNULL(NULLIF(CHARINDEX(',', @Databases, 1), 0), LEN(@Databases) + 1) - 1) AS DatabaseItem
                WHERE  @Databases IS NOT NULL
                UNION ALL
                SELECT CAST(EndPosition AS INT) + 1                                                                                                                  AS StartPosition,
                    ISNULL(NULLIF(CHARINDEX(',', @Databases, EndPosition + 1), 0), LEN(@Databases) + 1)                                                           AS EndPosition,
                    SUBSTRING(@Databases, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(',', @Databases, EndPosition + 1), 0), LEN(@Databases) + 1) - EndPosition - 1) AS DatabaseItem
                FROM   Databases1
                WHERE  EndPosition < LEN(@Databases) + 1),
            Databases2 (DatabaseItem, Selected)
            AS (SELECT CASE
                        WHEN DatabaseItem LIKE '-%' THEN RIGHT(DatabaseItem, LEN(DatabaseItem) - 1)
                        ELSE DatabaseItem
                    END AS DatabaseItem,
                    CASE
                        WHEN DatabaseItem LIKE '-%' THEN 0
                        ELSE 1
                    END AS Selected
                FROM   Databases1),
            Databases3 (DatabaseItem, DatabaseType, Selected)
            AS (SELECT CASE
                        WHEN DatabaseItem IN('ALL_DATABASES', 'SYSTEM_DATABASES', 'USER_DATABASES') THEN '%'
                        ELSE DatabaseItem
                    END AS DatabaseItem,
                    CASE
                        WHEN DatabaseItem = 'SYSTEM_DATABASES' THEN 'S'
                        WHEN DatabaseItem = 'USER_DATABASES' THEN 'U'
                        ELSE NULL
                    END AS DatabaseType,
                    Selected
                FROM   Databases2),
            Databases4 (DatabaseName, DatabaseType, Selected)
            AS (SELECT CASE
                        WHEN LEFT(DatabaseItem, 1) = '['
                                AND RIGHT(DatabaseItem, 1) = ']' THEN PARSENAME(DatabaseItem, 1)
                        ELSE DatabaseItem
                    END AS DatabaseItem,
                    DatabaseType,
                    Selected
                FROM   Databases3)
    INSERT INTO @SelectedDatabases
    (
        DatabaseName,
        DatabaseType,
        Selected
    )
        SELECT DatabaseName,
                DatabaseType,
                Selected
        FROM   Databases4
        OPTION (MAXRECURSION 0)

    INSERT INTO @tmpDatabases
    (
        DatabaseName,
        DatabaseType,
        Selected,
        Completed
    )
        SELECT [name] AS DatabaseName,
                CASE
                    WHEN NAME IN('master', 'msdb', 'model') THEN 'S'
                    ELSE 'U'
                END    AS DatabaseType,
                0      AS Selected,
                0      AS Completed
        FROM   sys.databases
        WHERE  [name] <> 'tempdb'
                AND source_database_id IS NULL
        ORDER  BY [name] ASC

    UPDATE tmpDatabases
    SET    tmpDatabases.Selected = SelectedDatabases.Selected
    FROM   @tmpDatabases tmpDatabases
            INNER JOIN @SelectedDatabases SelectedDatabases ON tmpDatabases.DatabaseName LIKE REPLACE(SelectedDatabases.DatabaseName, '_', '[_]')
                                                            AND (tmpDatabases.DatabaseType = SelectedDatabases.DatabaseType
                                                                OR SelectedDatabases.DatabaseType IS NULL)
    WHERE  SelectedDatabases.Selected = 1

    UPDATE tmpDatabases
    SET    tmpDatabases.Selected = SelectedDatabases.Selected
    FROM   @tmpDatabases tmpDatabases
            INNER JOIN @SelectedDatabases SelectedDatabases ON tmpDatabases.DatabaseName LIKE REPLACE(SelectedDatabases.DatabaseName, '_', '[_]')
                                                            AND (tmpDatabases.DatabaseType = SelectedDatabases.DatabaseType
                                                                OR SelectedDatabases.DatabaseType IS NULL)
    WHERE  SelectedDatabases.Selected = 0

    IF @Databases IS NULL
        OR NOT EXISTS(SELECT *
                        FROM   @SelectedDatabases)
        OR EXISTS(SELECT *
                    FROM   @SelectedDatabases
                    WHERE  DatabaseName IS NULL
                            OR DatabaseName = '')
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @Databases is not supported.' + CHAR(13) + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END


    ----------------------------------------------------------------------------------------------------
    --// Select indexes                                                                             //--
    ----------------------------------------------------------------------------------------------------

    SET @Indexes = REPLACE(@Indexes, ', ', ',');

    WITH Indexes1 (StartPosition, EndPosition, IndexItem)
            AS (SELECT 1                                                                                             AS StartPosition,
                    ISNULL(NULLIF(CHARINDEX(',', @Indexes, 1), 0), LEN(@Indexes) + 1)                             AS EndPosition,
                    SUBSTRING(@Indexes, 1, ISNULL(NULLIF(CHARINDEX(',', @Indexes, 1), 0), LEN(@Indexes) + 1) - 1) AS IndexItem
                WHERE  @Indexes IS NOT NULL
                UNION ALL
                SELECT CAST(EndPosition AS INT) + 1                                                                                                            AS StartPosition,
                    ISNULL(NULLIF(CHARINDEX(',', @Indexes, EndPosition + 1), 0), LEN(@Indexes) + 1)                                                         AS EndPosition,
                    SUBSTRING(@Indexes, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(',', @Indexes, EndPosition + 1), 0), LEN(@Indexes) + 1) - EndPosition - 1) AS IndexItem
                FROM   Indexes1
                WHERE  EndPosition < LEN(@Indexes) + 1),
            Indexes2 (IndexItem, Selected)
            AS (SELECT CASE
                        WHEN IndexItem LIKE '-%' THEN RIGHT(IndexItem, LEN(IndexItem) - 1)
                        ELSE IndexItem
                    END AS IndexItem,
                    CASE
                        WHEN IndexItem LIKE '-%' THEN 0
                        ELSE 1
                    END AS Selected
                FROM   Indexes1),
            Indexes3 (IndexItem, Selected)
            AS (SELECT CASE
                        WHEN IndexItem = 'ALL_INDEXES' THEN '%.%.%.%'
                        ELSE IndexItem
                    END AS IndexItem,
                    Selected
                FROM   Indexes2),
            Indexes4 (DatabaseName, SchemaName, ObjectName, IndexName, Selected)
            AS (SELECT CASE
                        WHEN PARSENAME(IndexItem, 4) IS NULL THEN PARSENAME(IndexItem, 3)
                        ELSE PARSENAME(IndexItem, 4)
                    END AS DatabaseName,
                    CASE
                        WHEN PARSENAME(IndexItem, 4) IS NULL THEN PARSENAME(IndexItem, 2)
                        ELSE PARSENAME(IndexItem, 3)
                    END AS SchemaName,
                    CASE
                        WHEN PARSENAME(IndexItem, 4) IS NULL THEN PARSENAME(IndexItem, 1)
                        ELSE PARSENAME(IndexItem, 2)
                    END AS ObjectName,
                    CASE
                        WHEN PARSENAME(IndexItem, 4) IS NULL THEN '%'
                        ELSE PARSENAME(IndexItem, 1)
                    END AS IndexName,
                    Selected
                FROM   Indexes3)
    INSERT INTO @SelectedIndexes
    (
        DatabaseName,
        SchemaName,
        ObjectName,
        IndexName,
        Selected
    )
        SELECT DatabaseName,
                SchemaName,
                ObjectName,
                IndexName,
                Selected
        FROM   Indexes4
        OPTION (MAXRECURSION 0);


    ----------------------------------------------------------------------------------------------------
    --// Select actions                                                                             //--
    ----------------------------------------------------------------------------------------------------

    WITH FragmentationLow (StartPosition, EndPosition, [Action])
            AS (SELECT 1                                                                                                                        AS StartPosition,
                    ISNULL(NULLIF(CHARINDEX(',', @FragmentationLow, 1), 0), LEN(@FragmentationLow) + 1)                                      AS EndPosition,
                    SUBSTRING(@FragmentationLow, 1, ISNULL(NULLIF(CHARINDEX(',', @FragmentationLow, 1), 0), LEN(@FragmentationLow) + 1) - 1) AS [Action]
                WHERE  @FragmentationLow IS NOT NULL
                UNION ALL
                SELECT CAST(EndPosition AS INT) + 1                                                                                                                                       AS StartPosition,
                    ISNULL(NULLIF(CHARINDEX(',', @FragmentationLow, EndPosition + 1), 0), LEN(@FragmentationLow) + 1)                                                                  AS EndPosition,
                    SUBSTRING(@FragmentationLow, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(',', @FragmentationLow, EndPosition + 1), 0), LEN(@FragmentationLow) + 1) - EndPosition - 1) AS [Action]
                FROM   FragmentationLow
                WHERE  EndPosition < LEN(@FragmentationLow) + 1)
    INSERT INTO @ActionsPreferred
    (
        FragmentationGroup,
        [Priority],
        [Action]
    )
        SELECT 'Low'                               AS FragmentationGroup,
                ROW_NUMBER()
                    OVER(
                        ORDER BY StartPosition ASC) AS [Priority],
                [Action]
        FROM   FragmentationLow
        OPTION (MAXRECURSION 0);

    WITH FragmentationMedium (StartPosition, EndPosition, [Action])
            AS (SELECT 1                                                                                                                                 AS StartPosition,
                    ISNULL(NULLIF(CHARINDEX(',', @FragmentationMedium, 1), 0), LEN(@FragmentationMedium) + 1)                                         AS EndPosition,
                    SUBSTRING(@FragmentationMedium, 1, ISNULL(NULLIF(CHARINDEX(',', @FragmentationMedium, 1), 0), LEN(@FragmentationMedium) + 1) - 1) AS [Action]
                WHERE  @FragmentationMedium IS NOT NULL
                UNION ALL
                SELECT CAST(EndPosition AS INT) + 1                                                                                                                                                AS StartPosition,
                    ISNULL(NULLIF(CHARINDEX(',', @FragmentationMedium, EndPosition + 1), 0), LEN(@FragmentationMedium) + 1)                                                                     AS EndPosition,
                    SUBSTRING(@FragmentationMedium, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(',', @FragmentationMedium, EndPosition + 1), 0), LEN(@FragmentationMedium) + 1) - EndPosition - 1) AS [Action]
                FROM   FragmentationMedium
                WHERE  EndPosition < LEN(@FragmentationMedium) + 1)
    INSERT INTO @ActionsPreferred
    (
        FragmentationGroup,
        [Priority],
        [Action]
    )
        SELECT 'Medium'                            AS FragmentationGroup,
                ROW_NUMBER()
                    OVER(
                        ORDER BY StartPosition ASC) AS [Priority],
                [Action]
        FROM   FragmentationMedium
        OPTION (MAXRECURSION 0);

    WITH FragmentationHigh (StartPosition, EndPosition, [Action])
            AS (SELECT 1                                                                                                                           AS StartPosition,
                    ISNULL(NULLIF(CHARINDEX(',', @FragmentationHigh, 1), 0), LEN(@FragmentationHigh) + 1)                                       AS EndPosition,
                    SUBSTRING(@FragmentationHigh, 1, ISNULL(NULLIF(CHARINDEX(',', @FragmentationHigh, 1), 0), LEN(@FragmentationHigh) + 1) - 1) AS [Action]
                WHERE  @FragmentationHigh IS NOT NULL
                UNION ALL
                SELECT CAST(EndPosition AS INT) + 1                                                                                                                                          AS StartPosition,
                    ISNULL(NULLIF(CHARINDEX(',', @FragmentationHigh, EndPosition + 1), 0), LEN(@FragmentationHigh) + 1)                                                                   AS EndPosition,
                    SUBSTRING(@FragmentationHigh, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(',', @FragmentationHigh, EndPosition + 1), 0), LEN(@FragmentationHigh) + 1) - EndPosition - 1) AS [Action]
                FROM   FragmentationHigh
                WHERE  EndPosition < LEN(@FragmentationHigh) + 1)
    INSERT INTO @ActionsPreferred
    (
        FragmentationGroup,
        [Priority],
        [Action]
    )
        SELECT 'High'                              AS FragmentationGroup,
                ROW_NUMBER()
                    OVER(
                        ORDER BY StartPosition ASC) AS [Priority],
                [Action]
        FROM   FragmentationHigh
        OPTION (MAXRECURSION 0)

    ----------------------------------------------------------------------------------------------------
    --// Check input parameters                                                                     //--
    ----------------------------------------------------------------------------------------------------

    IF (@Email IS NULL)
    BEGIN
        SET @ErrorMessage = 'You must enter an email for the parameter @Email.' + CHAR(13)+CHAR(10) + ' ';
        RAISERROR(@ErrorMessage,16,1) WITH NOWAIT;
        SET @Error = @@ERROR;
    END

    IF EXISTS (SELECT [Action]
                FROM   @ActionsPreferred
                WHERE  FragmentationGroup = 'Low'
                        AND [Action] NOT IN(SELECT *
                                            FROM   @Actions))
        OR EXISTS(SELECT *
                    FROM   @ActionsPreferred
                    WHERE  FragmentationGroup = 'Low'
                    GROUP  BY [Action]
                    HAVING COUNT(*) > 1)
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @FragmentationLow is not supported.' + CHAR(13)
                                + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF EXISTS (SELECT [Action]
                FROM   @ActionsPreferred
                WHERE  FragmentationGroup = 'Medium'
                        AND [Action] NOT IN(SELECT *
                                            FROM   @Actions))
        OR EXISTS(SELECT *
                    FROM   @ActionsPreferred
                    WHERE  FragmentationGroup = 'Medium'
                    GROUP  BY [Action]
                    HAVING COUNT(*) > 1)
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @FragmentationMedium is not supported.' + CHAR(13)
                                + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF EXISTS (SELECT [Action]
                FROM   @ActionsPreferred
                WHERE  FragmentationGroup = 'High'
                        AND [Action] NOT IN(SELECT *
                                            FROM   @Actions))
        OR EXISTS(SELECT *
                    FROM   @ActionsPreferred
                    WHERE  FragmentationGroup = 'High'
                    GROUP  BY [Action]
                    HAVING COUNT(*) > 1)
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @FragmentationHigh is not supported.' + CHAR(13)
                                + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @FragmentationLevel1 <= 0
        OR @FragmentationLevel1 >= 100
        OR @FragmentationLevel1 >= @FragmentationLevel2
        OR @FragmentationLevel1 IS NULL
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @FragmentationLevel1 is not supported.' + CHAR(13)
                                + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @FragmentationLevel2 <= 0
        OR @FragmentationLevel2 >= 100
        OR @FragmentationLevel2 <= @FragmentationLevel1
        OR @FragmentationLevel2 IS NULL
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @FragmentationLevel2 is not supported.' + CHAR(13)
                                + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @PageCountLevel < 0
        OR @PageCountLevel IS NULL
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @PageCountLevel is not supported.' + CHAR(13) + CHAR(10)
                                + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @SortInTempdb NOT IN('Y', 'N')
        OR @SortInTempdb IS NULL
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @SortInTempdb is not supported.' + CHAR(13) + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @MaxDOP < 0
        OR @MaxDOP > 64
        OR (@MaxDOP > 1
            AND SERVERPROPERTY('EngineEdition') NOT IN (3, 5))
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @MaxDOP is not supported.' + CHAR(13) + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @FillFactor <= 0
        OR @FillFactor > 100
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @FillFactor is not supported.' + CHAR(13) + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @PadIndex NOT IN('Y', 'N')
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @PadIndex is not supported.' + CHAR(13) + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @LOBCompaction NOT IN('Y', 'N')
        OR @LOBCompaction IS NULL
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @LOBCompaction is not supported.' + CHAR(13) + CHAR(10)
                                + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @UpdateStatistics NOT IN('ALL', 'COLUMNS', 'INDEX')
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @UpdateStatistics is not supported.' + CHAR(13)
                                + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @OnlyModifiedStatistics NOT IN('Y', 'N')
        OR @OnlyModifiedStatistics IS NULL
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @OnlyModifiedStatistics is not supported.' + CHAR(13)
                                + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @StatisticsSample <= 0
        OR @StatisticsSample > 100
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @StatisticsSample is not supported.' + CHAR(13)
                                + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @StatisticsResample NOT IN('Y', 'N')
        OR @StatisticsResample IS NULL
        OR (@StatisticsResample = 'Y'
            AND @StatisticsSample IS NOT NULL)
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @StatisticsResample is not supported.' + CHAR(13)
                                + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @PartitionLevel NOT IN('Y', 'N')
        OR @PartitionLevel IS NULL
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @PartitionLevel is not supported.' + CHAR(13) + CHAR(10)
                                + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @MSShippedObjects NOT IN('Y', 'N')
        OR @MSShippedObjects IS NULL
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @MSShippedObjects is not supported.' + CHAR(13)
                                + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF EXISTS(SELECT *
                FROM   @SelectedIndexes
                WHERE  DatabaseName IS NULL
                        OR SchemaName IS NULL
                        OR ObjectName IS NULL
                        OR IndexName IS NULL)
        OR (@Indexes IS NOT NULL
            AND NOT EXISTS(SELECT *
                            FROM   @SelectedIndexes))
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @Indexes is not supported.' + CHAR(13) + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @TimeLimit < 0
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @TimeLimit is not supported.' + CHAR(13) + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @Delay < 0
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @Delay is not supported.' + CHAR(13) + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @WaitAtLowPriorityMaxDuration < 0
        OR (@WaitAtLowPriorityMaxDuration IS NOT NULL
            AND @Version < 12)
        OR (@WaitAtLowPriorityMaxDuration IS NOT NULL
            AND @WaitAtLowPriorityAbortAfterWait IS NULL)
        OR (@WaitAtLowPriorityMaxDuration IS NULL
            AND @WaitAtLowPriorityAbortAfterWait IS NOT NULL)
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @WaitAtLowPriorityMaxDuration is not supported.'
                                + CHAR(13) + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @WaitAtLowPriorityAbortAfterWait NOT IN('NONE', 'SELF', 'BLOCKERS')
        OR (@WaitAtLowPriorityAbortAfterWait IS NOT NULL
            AND @Version < 12)
        OR (@WaitAtLowPriorityAbortAfterWait IS NOT NULL
            AND @WaitAtLowPriorityMaxDuration IS NULL)
        OR (@WaitAtLowPriorityAbortAfterWait IS NULL
            AND @WaitAtLowPriorityMaxDuration IS NOT NULL)
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @WaitAtLowPriorityAbortAfterWait is not supported.'
                                + CHAR(13) + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @LockTimeout < 0
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @LockTimeout is not supported.' + CHAR(13) + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @LogToTable NOT IN('Y', 'N')
        OR @LogToTable IS NULL
        BEGIN
            SET @ErrorMessage = 'The value for the parameter @LogToTable is not supported.' + CHAR(13) + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @Error = @@ERROR
        END

    IF @Error <> 0
        BEGIN
            SET @ErrorMessage = 'The documentation is available at https://ola.hallengren.com/sql-server-index-and-statistics-maintenance.html.'
                                + CHAR(13) + CHAR(10) + ' '

            RAISERROR(@ErrorMessage,16,1) WITH NOWAIT

            SET @ReturnCode = @Error

            GOTO Logging
        END

    ----------------------------------------------------------------------------------------------------
    --// Check Availability Group cluster name                                                      //--
    ----------------------------------------------------------------------------------------------------

    IF @Version >= 11
        AND SERVERPROPERTY('EngineEdition') <> 5
        BEGIN
            SELECT @Cluster = cluster_name
            FROM   sys.dm_hadr_cluster
        END

    ----------------------------------------------------------------------------------------------------
    --// Execute commands                                                                           //--
    ----------------------------------------------------------------------------------------------------

    WHILE EXISTS (SELECT *
                  FROM @tmpDatabases
                  WHERE Selected = 1
                  AND Completed = 0)
    BEGIN
        SELECT TOP 1 @CurrentDBID = ID,
                        @CurrentDatabaseName = DatabaseName
        FROM   @tmpDatabases
        WHERE  Selected = 1
                AND Completed = 0
        ORDER  BY ID ASC

        SET @CurrentDatabaseID = DB_ID(@CurrentDatabaseName)

        IF DATABASEPROPERTYEX(@CurrentDatabaseName, 'Status') = 'ONLINE'
            AND SERVERPROPERTY('EngineEdition') <> 5
            BEGIN
                IF EXISTS (SELECT *
                            FROM   sys.database_recovery_status
                            WHERE  database_id = @CurrentDatabaseID
                                    AND database_guid IS NOT NULL)
                    BEGIN
                        SET @CurrentIsDatabaseAccessible = 1
                    END
                ELSE
                    BEGIN
                        SET @CurrentIsDatabaseAccessible = 0
                    END
            END

        IF @Version >= 11
            AND @Cluster IS NOT NULL
            BEGIN
                SELECT @CurrentAvailabilityGroup = availability_groups.NAME,
                        @CurrentAvailabilityGroupRole = dm_hadr_availability_replica_states.role_desc
                FROM   sys.databases databases
                        INNER JOIN sys.availability_databases_cluster availability_databases_cluster ON databases.group_database_id = availability_databases_cluster.group_database_id
                        INNER JOIN sys.availability_groups availability_groups ON availability_databases_cluster.group_id = availability_groups.group_id
                        INNER JOIN sys.dm_hadr_availability_replica_states dm_hadr_availability_replica_states ON availability_groups.group_id = dm_hadr_availability_replica_states.group_id
                                                                                                                AND databases.replica_id = dm_hadr_availability_replica_states.replica_id
                WHERE  databases.NAME = @CurrentDatabaseName
            END

        IF SERVERPROPERTY('EngineEdition') <> 5
            BEGIN
                SELECT @CurrentDatabaseMirroringRole = UPPER(mirroring_role_desc)
                FROM   sys.database_mirroring
                WHERE  database_id = @CurrentDatabaseID
            END

        -- Set database message
        SET @DatabaseMessage = 'Date and time: ' + CONVERT(NVARCHAR, GETDATE(), 120) + CHAR(13) + CHAR(10)
        SET @DatabaseMessage = @DatabaseMessage + 'Database: ' + QUOTENAME(@CurrentDatabaseName) + CHAR(13) + CHAR(10)
        SET @DatabaseMessage = @DatabaseMessage + 'Status: '
                                + CAST(DATABASEPROPERTYEX(@CurrentDatabaseName, 'Status') AS NVARCHAR) + CHAR(13)
                                + CHAR(10)
        SET @DatabaseMessage = @DatabaseMessage + 'Standby: ' + CASE WHEN DATABASEPROPERTYEX(@CurrentDatabaseName, 'IsInStandBy') = 1 THEN 'Yes' ELSE 'No' END + CHAR(13) + CHAR(10)
        SET @DatabaseMessage = @DatabaseMessage + 'Updateability: '
                                + CAST(DATABASEPROPERTYEX(@CurrentDatabaseName, 'Updateability') AS NVARCHAR)
                                + CHAR(13) + CHAR(10)
        SET @DatabaseMessage = @DatabaseMessage + 'User access: '
                                + CAST(DATABASEPROPERTYEX(@CurrentDatabaseName, 'UserAccess') AS NVARCHAR) + CHAR(13)
                                + CHAR(10)

        IF @CurrentIsDatabaseAccessible IS NOT NULL
            SET @DatabaseMessage = @DatabaseMessage + 'Is accessible: ' + CASE WHEN @CurrentIsDatabaseAccessible = 1 THEN 'Yes' ELSE 'No' END + CHAR(13) + CHAR(10)

        SET @DatabaseMessage = @DatabaseMessage + 'Recovery model: '
                                + CAST(DATABASEPROPERTYEX(@CurrentDatabaseName, 'Recovery') AS NVARCHAR) + CHAR(13)
                                + CHAR(10)

        IF @CurrentAvailabilityGroup IS NOT NULL
            SET @DatabaseMessage = @DatabaseMessage + 'Availability group: ' + @CurrentAvailabilityGroup + CHAR(13) + CHAR(10)

        IF @CurrentAvailabilityGroup IS NOT NULL
            SET @DatabaseMessage = @DatabaseMessage + 'Availability group role: ' + @CurrentAvailabilityGroupRole + CHAR(13)
                                    + CHAR(10)

        IF @CurrentDatabaseMirroringRole IS NOT NULL
            SET @DatabaseMessage = @DatabaseMessage + 'Database mirroring role: ' + @CurrentDatabaseMirroringRole + CHAR(13)
                                    + CHAR(10)

        SET @DatabaseMessage = REPLACE(@DatabaseMessage, '%', '%%') + ' '

        RAISERROR(@DatabaseMessage,10,1) WITH NOWAIT

        IF DATABASEPROPERTYEX(@CurrentDatabaseName, 'Status') = 'ONLINE'
            AND (@CurrentIsDatabaseAccessible = 1
                    OR @CurrentIsDatabaseAccessible IS NULL)
            AND DATABASEPROPERTYEX(@CurrentDatabaseName, 'Updateability') = 'READ_WRITE'
            BEGIN
                -- Select indexes in the current database
                IF (EXISTS(SELECT *
                            FROM   @ActionsPreferred)
                        OR @UpdateStatistics IS NOT NULL)
                    AND (GETDATE() < DATEADD(ss, @TimeLimit, @StartTime)
                            OR @TimeLimit IS NULL)
                    BEGIN
                        SET @CurrentCommand01 = 'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; SELECT SchemaID, SchemaName, ObjectID, ObjectName, ObjectType, IsMemoryOptimized, IndexID, IndexName, IndexType, StatisticsID, StatisticsName, PartitionID, PartitionNumber, PartitionCount, Selected, Completed FROM ('

                        IF EXISTS(SELECT *
                                    FROM   @ActionsPreferred)
                            OR @UpdateStatistics IN('ALL', 'INDEX')
                            BEGIN
                                SET @CurrentCommand01 = @CurrentCommand01
                                                        + 'SELECT schemas.[schema_id] AS SchemaID, schemas.[name] AS SchemaName, objects.[object_id] AS ObjectID, objects.[name] AS ObjectName, RTRIM(objects.[type]) AS ObjectType, '
                                                        + CASE WHEN @Version >= 12 THEN 'tables.is_memory_optimized' ELSE 'NULL' END
                                                        + ' AS IsMemoryOptimized, indexes.index_id AS IndexID, indexes.[name] AS IndexName, indexes.[type] AS IndexType, stats.stats_id AS StatisticsID, stats.name AS StatisticsName'

                                IF @PartitionLevel = 'Y'
                                    SET @CurrentCommand01 = @CurrentCommand01
                                                            + ', partitions.partition_id AS PartitionID, partitions.partition_number AS PartitionNumber, IndexPartitions.partition_count AS PartitionCount'

                                IF @PartitionLevel = 'N'
                                    SET @CurrentCommand01 = @CurrentCommand01
                                                            + ', NULL AS PartitionID, NULL AS PartitionNumber, NULL AS PartitionCount'

                                SET @CurrentCommand01 = @CurrentCommand01 + ', 0 AS Selected, 0 AS Completed FROM '
                                                        + QUOTENAME(@CurrentDatabaseName) + '.sys.indexes indexes INNER JOIN '
                                                        + QUOTENAME(@CurrentDatabaseName)
                                                        + '.sys.objects objects ON indexes.[object_id] = objects.[object_id] INNER JOIN '
                                                        + QUOTENAME(@CurrentDatabaseName)
                                                        + '.sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] LEFT OUTER JOIN '
                                                        + QUOTENAME(@CurrentDatabaseName)
                                                        + '.sys.tables tables ON objects.[object_id] = tables.[object_id] LEFT OUTER JOIN '
                                                        + QUOTENAME(@CurrentDatabaseName)
                                                        + '.sys.stats stats ON indexes.[object_id] = stats.[object_id] AND indexes.[index_id] = stats.[stats_id]'

                                IF @PartitionLevel = 'Y'
                                    SET @CurrentCommand01 = @CurrentCommand01 + ' LEFT OUTER JOIN ' + QUOTENAME(@CurrentDatabaseName)
                                                            + '.sys.partitions partitions ON indexes.[object_id] = partitions.[object_id] AND indexes.index_id = partitions.index_id LEFT OUTER JOIN (SELECT partitions.[object_id], partitions.index_id, COUNT(*) AS partition_count FROM '
                                                            + QUOTENAME(@CurrentDatabaseName)
                                                            + '.sys.partitions partitions GROUP BY partitions.[object_id], partitions.index_id) IndexPartitions ON partitions.[object_id] = IndexPartitions.[object_id] AND partitions.[index_id] = IndexPartitions.[index_id]'

                                IF @PartitionLevel = 'Y'
                                    SET @CurrentCommand01 = @CurrentCommand01 + ' LEFT OUTER JOIN ' + QUOTENAME(@CurrentDatabaseName)
                                                            + '.sys.dm_db_partition_stats dm_db_partition_stats ON indexes.[object_id] = dm_db_partition_stats.[object_id] AND indexes.[index_id] = dm_db_partition_stats.[index_id] AND partitions.partition_id = dm_db_partition_stats.partition_id'

                                IF @PartitionLevel = 'N'
                                    SET @CurrentCommand01 = @CurrentCommand01
                                                            + ' LEFT OUTER JOIN (SELECT dm_db_partition_stats.[object_id], dm_db_partition_stats.[index_id], SUM(dm_db_partition_stats.in_row_data_page_count) AS in_row_data_page_count FROM '
                                                            + QUOTENAME(@CurrentDatabaseName)
                                                            + '.sys.dm_db_partition_stats dm_db_partition_stats GROUP BY dm_db_partition_stats.[object_id], dm_db_partition_stats.[index_id]) dm_db_partition_stats ON indexes.[object_id] = dm_db_partition_stats.[object_id] AND indexes.[index_id] = dm_db_partition_stats.[index_id]'

                                SET @CurrentCommand01 = @CurrentCommand01 + ' WHERE objects.[type] IN(''U'',''V'')' + CASE WHEN @MSShippedObjects = 'N' THEN ' AND objects.is_ms_shipped = 0' ELSE '' END
                                                        + ' AND indexes.[type] IN(1,2,3,4,5,6,7) AND indexes.is_disabled = 0 AND indexes.is_hypothetical = 0'

                                IF (@UpdateStatistics NOT IN('ALL', 'INDEX')
                                        OR @UpdateStatistics IS NULL)
                                    AND @PageCountLevel > 0
                                    SET @CurrentCommand01 = @CurrentCommand01
                                                            + ' AND (dm_db_partition_stats.in_row_data_page_count >= @ParamPageCountLevel OR dm_db_partition_stats.in_row_data_page_count IS NULL)'

                                IF NOT EXISTS(SELECT *
                                                FROM   @ActionsPreferred)
                                    SET @CurrentCommand01 = @CurrentCommand01 + ' AND stats.stats_id IS NOT NULL'
                            END

                        IF (EXISTS(SELECT *
                                    FROM   @ActionsPreferred)
                            AND @UpdateStatistics = 'COLUMNS')
                            OR @UpdateStatistics = 'ALL'
                            SET @CurrentCommand01 = @CurrentCommand01 + ' UNION '

                        IF @UpdateStatistics IN('ALL', 'COLUMNS')
                            SET @CurrentCommand01 = @CurrentCommand01
                                                    + 'SELECT schemas.[schema_id] AS SchemaID, schemas.[name] AS SchemaName, objects.[object_id] AS ObjectID, objects.[name] AS ObjectName, RTRIM(objects.[type]) AS ObjectType, '
                                                    + CASE WHEN @Version >= 12 THEN 'tables.is_memory_optimized' ELSE 'NULL' END
                                                    + ' AS IsMemoryOptimized, NULL AS IndexID, NULL AS IndexName, NULL AS IndexType, stats.stats_id AS StatisticsID, stats.name AS StatisticsName, NULL AS PartitionID, NULL AS PartitionNumber, NULL AS PartitionCount, 0 AS Selected, 0 AS Completed FROM '
                                                    + QUOTENAME(@CurrentDatabaseName) + '.sys.stats stats INNER JOIN '
                                                    + QUOTENAME(@CurrentDatabaseName)
                                                    + '.sys.objects objects ON stats.[object_id] = objects.[object_id] INNER JOIN '
                                                    + QUOTENAME(@CurrentDatabaseName)
                                                    + '.sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] LEFT OUTER JOIN '
                                                    + QUOTENAME(@CurrentDatabaseName)
                                                    + '.sys.tables tables ON objects.[object_id] = tables.[object_id] WHERE objects.[type] IN(''U'',''V'')'
                                                    + CASE WHEN @MSShippedObjects = 'N' THEN ' AND objects.is_ms_shipped = 0' ELSE '' END + ' AND NOT EXISTS(SELECT * FROM ' + QUOTENAME(@CurrentDatabaseName)
                                                    + '.sys.indexes indexes WHERE indexes.[object_id] = stats.[object_id] AND indexes.index_id = stats.stats_id)'

                        SET @CurrentCommand01 = @CurrentCommand01 + ') IndexesStatistics ORDER BY SchemaName ASC, ObjectName ASC'

                        IF (EXISTS(SELECT *
                                    FROM   @ActionsPreferred)
                            AND @UpdateStatistics = 'COLUMNS')
                            OR @UpdateStatistics = 'ALL'
                            SET @CurrentCommand01 = @CurrentCommand01 + ', CASE WHEN IndexType IS NULL THEN 1 ELSE 0 END ASC'

                        IF EXISTS(SELECT *
                                    FROM   @ActionsPreferred)
                            OR @UpdateStatistics IN('ALL', 'INDEX')
                            SET @CurrentCommand01 = @CurrentCommand01 + ', IndexType ASC, IndexName ASC'

                        IF @UpdateStatistics IN('ALL', 'COLUMNS')
                            SET @CurrentCommand01 = @CurrentCommand01 + ', StatisticsName ASC'

                        IF @PartitionLevel = 'Y'
                            SET @CurrentCommand01 = @CurrentCommand01 + ', PartitionNumber ASC'

                        INSERT INTO @tmpIndexesStatistics
                        (
                            SchemaID,
                            SchemaName,
                            ObjectID,
                            ObjectName,
                            ObjectType,
                            IsMemoryOptimized,
                            IndexID,
                            IndexName,
                            IndexType,
                            StatisticsID,
                            StatisticsName,
                            PartitionID,
                            PartitionNumber,
                            PartitionCount,
                            Selected,
                            Completed
                        )
                        EXECUTE sp_executesql
                            @statement           = @CurrentCommand01,
                            @params              = N'@ParamPageCountLevel int',
                            @ParamPageCountLevel = @PageCountLevel

                        SET @Error = @@ERROR

                        IF @Error <> 0
                            BEGIN
                                SET @ReturnCode = @Error
                            END
                    END

                IF @Indexes IS NULL
                    BEGIN
                        UPDATE tmpIndexesStatistics
                        SET    tmpIndexesStatistics.Selected = 1
                        FROM   @tmpIndexesStatistics tmpIndexesStatistics
                    END
                ELSE
                    BEGIN
                        UPDATE tmpIndexesStatistics
                        SET    tmpIndexesStatistics.Selected = SelectedIndexes.Selected
                        FROM   @tmpIndexesStatistics tmpIndexesStatistics
                                INNER JOIN @SelectedIndexes SelectedIndexes ON @CurrentDatabaseName LIKE REPLACE(SelectedIndexes.DatabaseName, '_', '[_]')
                                                                            AND tmpIndexesStatistics.SchemaName LIKE REPLACE(SelectedIndexes.SchemaName, '_', '[_]')
                                                                            AND tmpIndexesStatistics.ObjectName LIKE REPLACE(SelectedIndexes.ObjectName, '_', '[_]')
                                                                            AND COALESCE(tmpIndexesStatistics.IndexName, tmpIndexesStatistics.StatisticsName) LIKE REPLACE(SelectedIndexes.IndexName, '_', '[_]')
                        WHERE  SelectedIndexes.Selected = 1

                        UPDATE tmpIndexesStatistics
                        SET    tmpIndexesStatistics.Selected = SelectedIndexes.Selected
                        FROM   @tmpIndexesStatistics tmpIndexesStatistics
                                INNER JOIN @SelectedIndexes SelectedIndexes ON @CurrentDatabaseName LIKE REPLACE(SelectedIndexes.DatabaseName, '_', '[_]')
                                                                            AND tmpIndexesStatistics.SchemaName LIKE REPLACE(SelectedIndexes.SchemaName, '_', '[_]')
                                                                            AND tmpIndexesStatistics.ObjectName LIKE REPLACE(SelectedIndexes.ObjectName, '_', '[_]')
                                                                            AND COALESCE(tmpIndexesStatistics.IndexName, tmpIndexesStatistics.StatisticsName) LIKE REPLACE(SelectedIndexes.IndexName, '_', '[_]')
                        WHERE  SelectedIndexes.Selected = 0
                    END

                WHILE EXISTS (SELECT *
                                FROM   @tmpIndexesStatistics
                                WHERE  Selected = 1
                                        AND Completed = 0
                                        AND (GETDATE() < DATEADD(ss, @TimeLimit, @StartTime)
                                            OR @TimeLimit IS NULL))
                    BEGIN
                        SELECT TOP 1 @CurrentIxID = ID,
                                        @CurrentSchemaID = SchemaID,
                                        @CurrentSchemaName = SchemaName,
                                        @CurrentObjectID = ObjectID,
                                        @CurrentObjectName = ObjectName,
                                        @CurrentObjectType = ObjectType,
                                        @CurrentIsMemoryOptimized = IsMemoryOptimized,
                                        @CurrentIndexID = IndexID,
                                        @CurrentIndexName = IndexName,
                                        @CurrentIndexType = IndexType,
                                        @CurrentStatisticsID = StatisticsID,
                                        @CurrentStatisticsName = StatisticsName,
                                        @CurrentPartitionID = PartitionID,
                                        @CurrentPartitionNumber = PartitionNumber,
                                        @CurrentPartitionCount = PartitionCount
                        FROM   @tmpIndexesStatistics
                        WHERE  Selected = 1
                                AND Completed = 0
                        ORDER  BY ID ASC

                        -- Is the index a partition?
                        IF @CurrentPartitionNumber IS NULL
                            OR @CurrentPartitionCount = 1
                            BEGIN
                                SET @CurrentIsPartition = 0
                            END
                        ELSE
                            BEGIN
                                SET @CurrentIsPartition = 1
                            END

                        -- Does the index exist?
                        IF @CurrentIndexID IS NOT NULL
                            AND EXISTS(SELECT *
                                        FROM   @ActionsPreferred)
                            BEGIN
                                SET @CurrentCommand02 = ''

                                IF @LockTimeout IS NOT NULL
                                    SET @CurrentCommand02 = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS NVARCHAR) + '; '

                                IF @CurrentIsPartition = 0
                                    SET @CurrentCommand02 = @CurrentCommand02 + 'IF EXISTS(SELECT * FROM ' + QUOTENAME(@CurrentDatabaseName)
                                                            + '.sys.indexes indexes INNER JOIN ' + QUOTENAME(@CurrentDatabaseName)
                                                            + '.sys.objects objects ON indexes.[object_id] = objects.[object_id] INNER JOIN '
                                                            + QUOTENAME(@CurrentDatabaseName)
                                                            + '.sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] IN(''U'',''V'')'
                                                            + CASE WHEN @MSShippedObjects = 'N' THEN ' AND objects.is_ms_shipped = 0' ELSE '' END
                                                            +
                                    ' AND indexes.[type] IN(1,2,3,4,5,6,7) AND indexes.is_disabled = 0 AND indexes.is_hypothetical = 0 AND schemas.[schema_id] = @ParamSchemaID AND schemas.[name] = @ParamSchemaName AND objects.[object_id] = @ParamObjectID AND objects.[name] = @ParamObjectName AND objects.[type] = @ParamObjectType AND indexes.index_id = @ParamIndexID AND indexes.[name] = @ParamIndexName AND indexes.[type] = @ParamIndexType) BEGIN SET @ParamIndexExists = 1 END'

                                IF @CurrentIsPartition = 1
                                    SET @CurrentCommand02 = @CurrentCommand02 + 'IF EXISTS(SELECT * FROM ' + QUOTENAME(@CurrentDatabaseName)
                                                            + '.sys.indexes indexes INNER JOIN ' + QUOTENAME(@CurrentDatabaseName)
                                                            + '.sys.objects objects ON indexes.[object_id] = objects.[object_id] INNER JOIN '
                                                            + QUOTENAME(@CurrentDatabaseName)
                                                            + '.sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] INNER JOIN '
                                                            + QUOTENAME(@CurrentDatabaseName)
                                                            + '.sys.partitions partitions ON indexes.[object_id] = partitions.[object_id] AND indexes.index_id = partitions.index_id WHERE objects.[type] IN(''U'',''V'')'
                                                            + CASE WHEN @MSShippedObjects = 'N' THEN ' AND objects.is_ms_shipped = 0' ELSE '' END
                                                            + ' AND indexes.[type] IN(1,2,3,4,5,6,7) AND indexes.is_disabled = 0 AND indexes.is_hypothetical = 0 AND schemas.[schema_id] = @ParamSchemaID AND schemas.[name] = @ParamSchemaName AND objects.[object_id] = @ParamObjectID AND objects.[name] = @ParamObjectName AND objects.[type] = @ParamObjectType AND indexes.index_id = @ParamIndexID AND indexes.[name] = @ParamIndexName AND indexes.[type] = @ParamIndexType AND partitions.partition_id = @ParamPartitionID AND partitions.partition_number = @ParamPartitionNumber) BEGIN SET @ParamIndexExists = 1 END'

		EXECUTE sp_executesql
			@statement            = @CurrentCommand02,
			@params               = N'@ParamSchemaID int, @ParamSchemaName sysname, @ParamObjectID int, @ParamObjectName sysname, @ParamObjectType sysname, @ParamIndexID int, @ParamIndexName sysname, @ParamIndexType int, @ParamPartitionID bigint, @ParamPartitionNumber int, @ParamIndexExists bit OUTPUT',
			@ParamSchemaID        = @CurrentSchemaID,
			@ParamSchemaName      = @CurrentSchemaName,
			@ParamObjectID        = @CurrentObjectID,
			@ParamObjectName      = @CurrentObjectName,
			@ParamObjectType      = @CurrentObjectType,
			@ParamIndexID         = @CurrentIndexID,
			@ParamIndexName       = @CurrentIndexName,
			@ParamIndexType       = @CurrentIndexType,
			@ParamPartitionID     = @CurrentPartitionID,
			@ParamPartitionNumber = @CurrentPartitionNumber,
			@ParamIndexExists     = @CurrentIndexExists OUTPUT

		SET @Error = @@ERROR

		IF @Error = 0
			AND @CurrentIndexExists IS NULL
			SET @CurrentIndexExists = 0

		IF @Error = 1222
			BEGIN
				SET @ErrorMessage = 'The index ' + QUOTENAME(@CurrentIndexName) + ' on the object '
									+ QUOTENAME(@CurrentDatabaseName) + '.' + QUOTENAME(@CurrentSchemaName) + '.'
									+ QUOTENAME(@CurrentObjectName)
									+ ' is locked. It could not be checked if the index exists.' + CHAR(13) + CHAR(10) + ' '
				SET @ErrorMessage = REPLACE(@ErrorMessage, '%', '%%')

				RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
			END

		IF @Error <> 0
			BEGIN
				SET @ReturnCode = @Error

				GOTO NoAction
			END

		IF @CurrentIndexExists = 0
			GOTO NoAction
		END

		-- Does the statistics exist?
		IF @CurrentStatisticsID IS NOT NULL
			AND @UpdateStatistics IS NOT NULL
			BEGIN
				SET @CurrentCommand03 = ''

				IF @LockTimeout IS NOT NULL
					SET @CurrentCommand03 = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS NVARCHAR) + '; '

				SET @CurrentCommand03 = @CurrentCommand03 + 'IF EXISTS(SELECT * FROM ' + QUOTENAME(@CurrentDatabaseName)
										+ '.sys.stats stats INNER JOIN ' + QUOTENAME(@CurrentDatabaseName)
										+ '.sys.objects objects ON stats.[object_id] = objects.[object_id] INNER JOIN '
										+ QUOTENAME(@CurrentDatabaseName)
										+ '.sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] IN(''U'',''V'')'
										+ CASE WHEN @MSShippedObjects = 'N' THEN ' AND objects.is_ms_shipped = 0' ELSE '' END
										+ ' AND schemas.[schema_id] = @ParamSchemaID AND schemas.[name] = @ParamSchemaName AND objects.[object_id] = @ParamObjectID AND objects.[name] = @ParamObjectName AND objects.[type] = @ParamObjectType AND stats.stats_id = @ParamStatisticsID AND stats.[name] = @ParamStatisticsName) BEGIN SET @ParamStatisticsExists = 1 END'

				EXECUTE sp_executesql
					@statement             = @CurrentCommand03,
					@params                = N'@ParamSchemaID int, @ParamSchemaName sysname, @ParamObjectID int, @ParamObjectName sysname, @ParamObjectType sysname, @ParamStatisticsID int, @ParamStatisticsName sysname, @ParamStatisticsExists bit OUTPUT',
					@ParamSchemaID         = @CurrentSchemaID,
					@ParamSchemaName       = @CurrentSchemaName,
					@ParamObjectID         = @CurrentObjectID,
					@ParamObjectName       = @CurrentObjectName,
					@ParamObjectType       = @CurrentObjectType,
					@ParamStatisticsID     = @CurrentStatisticsID,
					@ParamStatisticsName   = @CurrentStatisticsName,
					@ParamStatisticsExists = @CurrentStatisticsExists OUTPUT

				SET @Error = @@ERROR

				IF @Error = 0
					AND @CurrentStatisticsExists IS NULL
					SET @CurrentStatisticsExists = 0

				IF @Error = 1222
					BEGIN
						SET @ErrorMessage = 'The statistics ' + QUOTENAME(@CurrentStatisticsName) + ' on the object '
											+ QUOTENAME(@CurrentDatabaseName) + '.' + QUOTENAME(@CurrentSchemaName) + '.'
											+ QUOTENAME(@CurrentObjectName)
											+ ' is locked. It could not be checked if the statistics exists.' + CHAR(13) + CHAR(10)
											+ ' '
						SET @ErrorMessage = REPLACE(@ErrorMessage, '%', '%%')

						RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
					END

				IF @Error <> 0
					BEGIN
						SET @ReturnCode = @Error

						GOTO NoAction
					END

				IF @CurrentStatisticsExists = 0
					GOTO NoAction
			END

		-- Is one of the columns in the index an image, text or ntext data type?
		IF @CurrentIndexID IS NOT NULL
			AND @CurrentIndexType = 1
			AND EXISTS(SELECT *
						FROM   @ActionsPreferred)
			BEGIN
				SET @CurrentCommand04 = ''

				IF @LockTimeout IS NOT NULL
					SET @CurrentCommand04 = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS NVARCHAR) + '; '

				SET @CurrentCommand04 = @CurrentCommand04 + 'IF EXISTS(SELECT * FROM ' + QUOTENAME(@CurrentDatabaseName)
										+ '.sys.columns columns INNER JOIN ' + QUOTENAME(@CurrentDatabaseName)
										+ '.sys.types types ON columns.system_type_id = types.user_type_id WHERE columns.[object_id] = @ParamObjectID AND types.name IN(''image'',''text'',''ntext'')) BEGIN SET @ParamIsImageText = 1 END'

				EXECUTE sp_executesql
					@statement        = @CurrentCommand04,
					@params           = N'@ParamObjectID int, @ParamIndexID int, @ParamIsImageText bit OUTPUT',
					@ParamObjectID    = @CurrentObjectID,
					@ParamIndexID     = @CurrentIndexID,
					@ParamIsImageText = @CurrentIsImageText OUTPUT

				SET @Error = @@ERROR

				IF @Error = 0
					AND @CurrentIsImageText IS NULL
					SET @CurrentIsImageText = 0

				IF @Error = 1222
					BEGIN
						SET @ErrorMessage = 'The index ' + QUOTENAME(@CurrentIndexName) + ' on the object '
											+ QUOTENAME(@CurrentDatabaseName) + '.' + QUOTENAME(@CurrentSchemaName) + '.'
											+ QUOTENAME(@CurrentObjectName)
											+ ' is locked. It could not be checked if the index contains any image, text, or ntext data types.'
											+ CHAR(13) + CHAR(10) + ' '
						SET @ErrorMessage = REPLACE(@ErrorMessage, '%', '%%')

						RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
					END

				IF @Error <> 0
					BEGIN
						SET @ReturnCode = @Error

						GOTO NoAction
					END
			END

		-- Is one of the columns in the index an xml, varchar(max), nvarchar(max), varbinary(max) or large CLR data type?
		IF @CurrentIndexID IS NOT NULL
			AND @CurrentIndexType IN(1, 2)
			AND EXISTS(SELECT *
						FROM   @ActionsPreferred)
			BEGIN
				SET @CurrentCommand05 = ''

				IF @LockTimeout IS NOT NULL
					SET @CurrentCommand05 = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS NVARCHAR) + '; '

				IF @CurrentIndexType = 1
					SET @CurrentCommand05 = @CurrentCommand05 + 'IF EXISTS(SELECT * FROM ' + QUOTENAME(@CurrentDatabaseName)
											+ '.sys.columns columns INNER JOIN ' + QUOTENAME(@CurrentDatabaseName)
											+ '.sys.types types ON columns.system_type_id = types.user_type_id OR (columns.user_type_id = types.user_type_id AND types.is_assembly_type = 1) WHERE columns.[object_id] = @ParamObjectID AND (types.name IN(''xml'') OR (types.name IN(''varchar'',''nvarchar'',''varbinary'') AND columns.max_length = -1) OR (types.is_assembly_type = 1 AND columns.max_length = -1))) BEGIN SET @ParamIsNewLOB = 1 END'

				IF @CurrentIndexType = 2
					SET @CurrentCommand05 = @CurrentCommand05 + 'IF EXISTS(SELECT * FROM ' + QUOTENAME(@CurrentDatabaseName)
											+ '.sys.index_columns index_columns INNER JOIN ' + QUOTENAME(@CurrentDatabaseName)
											+ '.sys.columns columns ON index_columns.[object_id] = columns.[object_id] AND index_columns.column_id = columns.column_id INNER JOIN '
											+ QUOTENAME(@CurrentDatabaseName)
											+ '.sys.types types ON columns.system_type_id = types.user_type_id OR (columns.user_type_id = types.user_type_id AND types.is_assembly_type = 1) WHERE index_columns.[object_id] = @ParamObjectID AND index_columns.index_id = @ParamIndexID AND (types.[name] IN(''xml'') OR (types.[name] IN(''varchar'',''nvarchar'',''varbinary'') AND columns.max_length = -1) OR (types.is_assembly_type = 1 AND columns.max_length = -1))) BEGIN SET @ParamIsNewLOB = 1 END'

				EXECUTE sp_executesql
					@statement     = @CurrentCommand05,
					@params        = N'@ParamObjectID int, @ParamIndexID int, @ParamIsNewLOB bit OUTPUT',
					@ParamObjectID = @CurrentObjectID,
					@ParamIndexID  = @CurrentIndexID,
					@ParamIsNewLOB = @CurrentIsNewLOB OUTPUT

				SET @Error = @@ERROR

				IF @Error = 0
					AND @CurrentIsNewLOB IS NULL
					SET @CurrentIsNewLOB = 0

				IF @Error = 1222
					BEGIN
						SET @ErrorMessage = 'The index ' + QUOTENAME(@CurrentIndexName) + ' on the object '
											+ QUOTENAME(@CurrentDatabaseName) + '.' + QUOTENAME(@CurrentSchemaName) + '.'
											+ QUOTENAME(@CurrentObjectName)
											+ ' is locked. It could not be checked if the index contains any xml, varchar(max), nvarchar(max), varbinary(max), or large CLR data types.'
											+ CHAR(13) + CHAR(10) + ' '
						SET @ErrorMessage = REPLACE(@ErrorMessage, '%', '%%')

						RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
					END

				IF @Error <> 0
					BEGIN
						SET @ReturnCode = @Error

						GOTO NoAction
					END
			END

		-- Is one of the columns in the index a file stream column?
		IF @CurrentIndexID IS NOT NULL
			AND @CurrentIndexType = 1
			AND EXISTS(SELECT *
						FROM   @ActionsPreferred)
			BEGIN
				SET @CurrentCommand06 = ''

				IF @LockTimeout IS NOT NULL
					SET @CurrentCommand06 = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS NVARCHAR) + '; '

				SET @CurrentCommand06 = @CurrentCommand06 + 'IF EXISTS(SELECT * FROM ' + QUOTENAME(@CurrentDatabaseName)
										+ '.sys.columns columns WHERE columns.[object_id] = @ParamObjectID  AND columns.is_filestream = 1) BEGIN SET @ParamIsFileStream = 1 END'

				EXECUTE sp_executesql
					@statement         = @CurrentCommand06,
					@params            = N'@ParamObjectID int, @ParamIndexID int, @ParamIsFileStream bit OUTPUT',
					@ParamObjectID     = @CurrentObjectID,
					@ParamIndexID      = @CurrentIndexID,
					@ParamIsFileStream = @CurrentIsFileStream OUTPUT

				SET @Error = @@ERROR

				IF @Error = 0
					AND @CurrentIsFileStream IS NULL
					SET @CurrentIsFileStream = 0

				IF @Error = 1222
					BEGIN
						SET @ErrorMessage = 'The index ' + QUOTENAME(@CurrentIndexName) + ' on the object '
											+ QUOTENAME(@CurrentDatabaseName) + '.' + QUOTENAME(@CurrentSchemaName) + '.'
											+ QUOTENAME(@CurrentObjectName)
											+ ' is locked. It could not be checked if the index contains any file stream columns.'
											+ CHAR(13) + CHAR(10) + ' '
						SET @ErrorMessage = REPLACE(@ErrorMessage, '%', '%%')

						RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
					END

				IF @Error <> 0
					BEGIN
						SET @ReturnCode = @Error

						GOTO NoAction
					END
			END

		-- Is there a columnstore index on the table?
		IF @CurrentIndexID IS NOT NULL
			AND EXISTS(SELECT *
						FROM   @ActionsPreferred)
			AND @Version >= 11
			BEGIN
				SET @CurrentCommand07 = ''

				IF @LockTimeout IS NOT NULL
					SET @CurrentCommand07 = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS NVARCHAR) + '; '

				SET @CurrentCommand07 = @CurrentCommand07 + 'IF EXISTS(SELECT * FROM ' + QUOTENAME(@CurrentDatabaseName)
										+ '.sys.indexes indexes WHERE indexes.[object_id] = @ParamObjectID AND [type] IN(5,6)) BEGIN SET @ParamIsColumnStore = 1 END'

				EXECUTE sp_executesql
					@statement          = @CurrentCommand07,
					@params             = N'@ParamObjectID int, @ParamIsColumnStore bit OUTPUT',
					@ParamObjectID      = @CurrentObjectID,
					@ParamIsColumnStore = @CurrentIsColumnStore OUTPUT

				SET @Error = @@ERROR

				IF @Error = 0
					AND @CurrentIsColumnStore IS NULL
					SET @CurrentIsColumnStore = 0

				IF @Error = 1222
					BEGIN
						SET @ErrorMessage = 'The index ' + QUOTENAME(@CurrentIndexName) + ' on the object '
											+ QUOTENAME(@CurrentDatabaseName) + '.' + QUOTENAME(@CurrentSchemaName) + '.'
											+ QUOTENAME(@CurrentObjectName)
											+ ' is locked. It could not be checked if there is a columnstore index on the table.'
											+ CHAR(13) + CHAR(10) + ' '
						SET @ErrorMessage = REPLACE(@ErrorMessage, '%', '%%')

						RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
					END

				IF @Error <> 0
					BEGIN
						SET @ReturnCode = @Error

						GOTO NoAction
					END
			END

		-- Is Allow_Page_Locks set to On?
		IF @CurrentIndexID IS NOT NULL
			AND EXISTS(SELECT *
						FROM   @ActionsPreferred)
			BEGIN
				SET @CurrentCommand08 = ''

				IF @LockTimeout IS NOT NULL
					SET @CurrentCommand08 = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS NVARCHAR) + '; '

				SET @CurrentCommand08 = @CurrentCommand08 + 'IF EXISTS(SELECT * FROM ' + QUOTENAME(@CurrentDatabaseName)
										+ '.sys.indexes indexes WHERE indexes.[object_id] = @ParamObjectID AND indexes.[index_id] = @ParamIndexID AND indexes.[allow_page_locks] = 1) BEGIN SET @ParamAllowPageLocks = 1 END'

				EXECUTE sp_executesql
					@statement           = @CurrentCommand08,
					@params              = N'@ParamObjectID int, @ParamIndexID int, @ParamAllowPageLocks bit OUTPUT',
					@ParamObjectID       = @CurrentObjectID,
					@ParamIndexID        = @CurrentIndexID,
					@ParamAllowPageLocks = @CurrentAllowPageLocks OUTPUT

				SET @Error = @@ERROR

				IF @Error = 0
					AND @CurrentAllowPageLocks IS NULL
					SET @CurrentAllowPageLocks = 0

				IF @Error = 1222
					BEGIN
						SET @ErrorMessage = 'The index ' + QUOTENAME(@CurrentIndexName) + ' on the object '
											+ QUOTENAME(@CurrentDatabaseName) + '.' + QUOTENAME(@CurrentSchemaName) + '.'
											+ QUOTENAME(@CurrentObjectName)
											+ ' is locked. It could not be checked if page locking is enabled on the index.'
											+ CHAR(13) + CHAR(10) + ' '
						SET @ErrorMessage = REPLACE(@ErrorMessage, '%', '%%')

						RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
					END

				IF @Error <> 0
					BEGIN
						SET @ReturnCode = @Error

						GOTO NoAction
					END
			END

		-- Is No_Recompute set to On?
		IF @CurrentStatisticsID IS NOT NULL
			AND @UpdateStatistics IS NOT NULL
			BEGIN
				SET @CurrentCommand09 = ''

				IF @LockTimeout IS NOT NULL
					SET @CurrentCommand09 = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS NVARCHAR) + '; '

				SET @CurrentCommand09 = @CurrentCommand09 + 'IF EXISTS(SELECT * FROM ' + QUOTENAME(@CurrentDatabaseName)
										+ '.sys.stats stats WHERE stats.[object_id] = @ParamObjectID AND stats.[stats_id] = @ParamStatisticsID AND stats.[no_recompute] = 1) BEGIN SET @ParamNoRecompute = 1 END'

				EXECUTE sp_executesql
					@statement         = @CurrentCommand09,
					@params            = N'@ParamObjectID int, @ParamStatisticsID int, @ParamNoRecompute bit OUTPUT',
					@ParamObjectID     = @CurrentObjectID,
					@ParamStatisticsID = @CurrentStatisticsID,
					@ParamNoRecompute  = @CurrentNoRecompute OUTPUT

				SET @Error = @@ERROR

				IF @Error = 0
					AND @CurrentNoRecompute IS NULL
					SET @CurrentNoRecompute = 0

				IF @Error = 1222
					BEGIN
						SET @ErrorMessage = 'The statistics ' + QUOTENAME(@CurrentStatisticsName) + ' on the object '
											+ QUOTENAME(@CurrentDatabaseName) + '.' + QUOTENAME(@CurrentSchemaName) + '.'
											+ QUOTENAME(@CurrentObjectName)
											+ ' is locked. It could not be checked if automatic statistics update is enabled.'
											+ CHAR(13) + CHAR(10) + ' '
						SET @ErrorMessage = REPLACE(@ErrorMessage, '%', '%%')

						RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
					END

				IF @Error <> 0
					BEGIN
						SET @ReturnCode = @Error

						GOTO NoAction
					END
			END

		-- Has the data in the statistics been modified since the statistics was last updated?
		IF @CurrentStatisticsID IS NOT NULL
			AND @UpdateStatistics IS NOT NULL
			AND @OnlyModifiedStatistics = 'Y'
			BEGIN
				SET @CurrentCommand10 = ''

				IF @LockTimeout IS NOT NULL
					SET @CurrentCommand10 = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS NVARCHAR) + '; '

				IF (@Version >= 10.504000
					AND @Version < 11)
					OR @Version >= 11.03000
					BEGIN
						SET @CurrentCommand10 = @CurrentCommand10 + 'USE ' + QUOTENAME(@CurrentDatabaseName)
												+ '; IF EXISTS(SELECT * FROM sys.dm_db_stats_properties (@ParamObjectID, @ParamStatisticsID) WHERE modification_counter > 0) BEGIN SET @ParamStatisticsModified = 1 END'
					END
				ELSE
					BEGIN
						SET @CurrentCommand10 = @CurrentCommand10 + 'IF EXISTS(SELECT * FROM ' + QUOTENAME(@CurrentDatabaseName)
												+ '.sys.sysindexes sysindexes WHERE sysindexes.[id] = @ParamObjectID AND sysindexes.[indid] = @ParamStatisticsID AND sysindexes.[rowmodctr] <> 0) BEGIN SET @ParamStatisticsModified = 1 END'
					END

				EXECUTE sp_executesql
					@statement               = @CurrentCommand10,
					@params                  = N'@ParamObjectID int, @ParamStatisticsID int, @ParamStatisticsModified bit OUTPUT',
					@ParamObjectID           = @CurrentObjectID,
					@ParamStatisticsID       = @CurrentStatisticsID,
					@ParamStatisticsModified = @CurrentStatisticsModified OUTPUT

				SET @Error = @@ERROR

				IF @Error = 0
					AND @CurrentStatisticsModified IS NULL
					SET @CurrentStatisticsModified = 0

				IF @Error = 1222
					BEGIN
						SET @ErrorMessage = 'The statistics ' + QUOTENAME(@CurrentStatisticsName) + ' on the object '
											+ QUOTENAME(@CurrentDatabaseName) + '.' + QUOTENAME(@CurrentSchemaName) + '.'
											+ QUOTENAME(@CurrentObjectName)
											+ ' is locked. It could not be checked if any rows has been modified since the most recent statistics update.'
											+ CHAR(13) + CHAR(10) + ' '
						SET @ErrorMessage = REPLACE(@ErrorMessage, '%', '%%')

						RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
					END

				IF @Error <> 0
					BEGIN
						SET @ReturnCode = @Error

						GOTO NoAction
					END
			END

		-- Is the index on a read-only filegroup?
		IF @CurrentIndexID IS NOT NULL
			AND EXISTS(SELECT *
						FROM   @ActionsPreferred)
			BEGIN
				SET @CurrentCommand11 = ''

				IF @LockTimeout IS NOT NULL
					SET @CurrentCommand11 = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS NVARCHAR) + '; '

				SET @CurrentCommand11 = @CurrentCommand11
										+ 'IF EXISTS(SELECT * FROM (SELECT filegroups.data_space_id FROM '
										+ QUOTENAME(@CurrentDatabaseName) + '.sys.indexes indexes INNER JOIN '
										+ QUOTENAME(@CurrentDatabaseName)
										+ '.sys.destination_data_spaces destination_data_spaces ON indexes.data_space_id = destination_data_spaces.partition_scheme_id INNER JOIN '
										+ QUOTENAME(@CurrentDatabaseName)
										+ '.sys.filegroups filegroups ON destination_data_spaces.data_space_id = filegroups.data_space_id WHERE filegroups.is_read_only = 1 AND indexes.[object_id] = @ParamObjectID AND indexes.[index_id] = @ParamIndexID'

				IF @CurrentIsPartition = 1
					SET @CurrentCommand11 = @CurrentCommand11
											+ ' AND destination_data_spaces.destination_id = @ParamPartitionNumber'

				SET @CurrentCommand11 = @CurrentCommand11 + ' UNION SELECT filegroups.data_space_id FROM '
										+ QUOTENAME(@CurrentDatabaseName) + '.sys.indexes indexes INNER JOIN '
										+ QUOTENAME(@CurrentDatabaseName)
										+ '.sys.filegroups filegroups ON indexes.data_space_id = filegroups.data_space_id WHERE filegroups.is_read_only = 1 AND indexes.[object_id] = @ParamObjectID AND indexes.[index_id] = @ParamIndexID'

				IF @CurrentIndexType = 1
					SET @CurrentCommand11 = @CurrentCommand11 + ' UNION SELECT filegroups.data_space_id FROM '
											+ QUOTENAME(@CurrentDatabaseName) + '.sys.tables tables INNER JOIN '
											+ QUOTENAME(@CurrentDatabaseName)
											+ '.sys.filegroups filegroups ON tables.lob_data_space_id = filegroups.data_space_id WHERE filegroups.is_read_only = 1 AND tables.[object_id] = @ParamObjectID'

				SET @CurrentCommand11 = @CurrentCommand11
										+ ') ReadOnlyFileGroups) BEGIN SET @ParamOnReadOnlyFileGroup = 1 END'

				EXECUTE sp_executesql
					@statement                = @CurrentCommand11,
					@params                   = N'@ParamObjectID int, @ParamIndexID int, @ParamPartitionNumber int, @ParamOnReadOnlyFileGroup bit OUTPUT',
					@ParamObjectID            = @CurrentObjectID,
					@ParamIndexID             = @CurrentIndexID,
					@ParamPartitionNumber     = @CurrentPartitionNumber,
					@ParamOnReadOnlyFileGroup = @CurrentOnReadOnlyFileGroup OUTPUT

				SET @Error = @@ERROR

				IF @Error = 0
					AND @CurrentOnReadOnlyFileGroup IS NULL
					SET @CurrentOnReadOnlyFileGroup = 0

				IF @Error = 1222
					BEGIN
						SET @ErrorMessage = 'The index ' + QUOTENAME(@CurrentIndexName) + ' on the object '
											+ QUOTENAME(@CurrentDatabaseName) + '.' + QUOTENAME(@CurrentSchemaName) + '.'
											+ QUOTENAME(@CurrentObjectName)
											+ ' is locked. It could not be checked if the index is on a read-only filegroup.'
											+ CHAR(13) + CHAR(10) + ' '
						SET @ErrorMessage = REPLACE(@ErrorMessage, '%', '%%')

						RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
					END

				IF @Error <> 0
					BEGIN
						SET @ReturnCode = @Error

						GOTO NoAction
					END
			END

		-- Is the index fragmented?
		IF @CurrentIndexID IS NOT NULL
			AND @CurrentOnReadOnlyFileGroup = 0
			AND EXISTS(SELECT *
						FROM   @ActionsPreferred)
			AND (EXISTS(SELECT [Priority],
								[Action],
								COUNT(*)
						FROM   @ActionsPreferred
						GROUP  BY [Priority],
									[Action]
						HAVING COUNT(*) <> 3)
					OR @PageCountLevel > 0)
			BEGIN
				SET @CurrentCommand12 = ''

				IF @LockTimeout IS NOT NULL
					SET @CurrentCommand12 = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS NVARCHAR) + '; '

				SET @CurrentCommand12 = @CurrentCommand12
										+ 'SELECT @ParamFragmentationLevel = MAX(avg_fragmentation_in_percent), @ParamPageCount = SUM(page_count) FROM sys.dm_db_index_physical_stats(@ParamDatabaseID, @ParamObjectID, @ParamIndexID, @ParamPartitionNumber, ''LIMITED'') WHERE alloc_unit_type_desc = ''IN_ROW_DATA'' AND index_level = 0'

				EXECUTE sp_executesql
					@statement               = @CurrentCommand12,
					@params                  = N'@ParamDatabaseID int, @ParamObjectID int, @ParamIndexID int, @ParamPartitionNumber int, @ParamFragmentationLevel float OUTPUT, @ParamPageCount bigint OUTPUT',
					@ParamDatabaseID         = @CurrentDatabaseID,
					@ParamObjectID           = @CurrentObjectID,
					@ParamIndexID            = @CurrentIndexID,
					@ParamPartitionNumber    = @CurrentPartitionNumber,
					@ParamFragmentationLevel = @CurrentFragmentationLevel OUTPUT,
					@ParamPageCount          = @CurrentPageCount OUTPUT

				SET @Error = @@ERROR

				IF @Error = 1222
					BEGIN
						SET @ErrorMessage = 'The index ' + QUOTENAME(@CurrentIndexName) + ' on the object '
											+ QUOTENAME(@CurrentDatabaseName) + '.' + QUOTENAME(@CurrentSchemaName) + '.'
											+ QUOTENAME(@CurrentObjectName)
											+ ' is locked. The size and fragmentation of the index could not be checked.'
											+ CHAR(13) + CHAR(10) + ' '
						SET @ErrorMessage = REPLACE(@ErrorMessage, '%', '%%')

						RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
					END

				IF @Error <> 0
					BEGIN
						SET @ReturnCode = @Error

						GOTO NoAction
					END
			END

		-- Select fragmentation group
		IF @CurrentIndexID IS NOT NULL
			AND @CurrentOnReadOnlyFileGroup = 0
			AND EXISTS(SELECT *
						FROM   @ActionsPreferred)
			BEGIN
				SET @CurrentFragmentationGroup = CASE
														WHEN @CurrentFragmentationLevel >= @FragmentationLevel2 THEN 'High'
														WHEN @CurrentFragmentationLevel >= @FragmentationLevel1
															AND @CurrentFragmentationLevel < @FragmentationLevel2 THEN 'Medium'
														WHEN @CurrentFragmentationLevel < @FragmentationLevel1 THEN 'Low'
													END
			END

		-- Which actions are allowed?
		IF @CurrentIndexID IS NOT NULL
			AND EXISTS(SELECT *
						FROM   @ActionsPreferred)
			BEGIN
				IF @CurrentOnReadOnlyFileGroup = 0
					AND @CurrentIndexType IN (1, 2, 3, 4, 5)
					AND (@CurrentIsMemoryOptimized = 0
							OR @CurrentIsMemoryOptimized IS NULL)
					AND (@CurrentAllowPageLocks = 1
							OR @CurrentIndexType = 5)
					BEGIN
						INSERT INTO @CurrentActionsAllowed
						(
							[Action]
						)
						VALUES
						(
							'INDEX_REORGANIZE'
						)
					END

				IF @CurrentOnReadOnlyFileGroup = 0
					AND @CurrentIndexType IN (1, 2, 3, 4, 5)
					AND (@CurrentIsMemoryOptimized = 0
							OR @CurrentIsMemoryOptimized IS NULL)
					BEGIN
						INSERT INTO @CurrentActionsAllowed
						(
							[Action]
						)
						VALUES
						(
							'INDEX_REBUILD_OFFLINE'
						)
					END

				IF @CurrentOnReadOnlyFileGroup = 0
					AND (@CurrentIsMemoryOptimized = 0
							OR @CurrentIsMemoryOptimized IS NULL)
					AND (@CurrentIsPartition = 0
							OR @Version >= 12)
					AND ((@CurrentIndexType = 1
							AND @CurrentIsImageText = 0
							AND @CurrentIsNewLOB = 0)
							OR (@CurrentIndexType = 2
								AND @CurrentIsNewLOB = 0)
							OR (@CurrentIndexType = 1
								AND @CurrentIsImageText = 0
								AND @CurrentIsFileStream = 0
								AND @Version >= 11)
							OR (@CurrentIndexType = 2
								AND @Version >= 11))
					AND (@CurrentIsColumnStore = 0
							OR @Version < 11)
					AND SERVERPROPERTY('EngineEdition') IN (3, 5)
					BEGIN
						INSERT INTO @CurrentActionsAllowed
						(
							[Action]
						)
						VALUES
						(
							'INDEX_REBUILD_ONLINE'
						)
					END
			END

		-- Decide action
		IF @CurrentIndexID IS NOT NULL
			AND EXISTS(SELECT *
						FROM   @ActionsPreferred)
			AND (@CurrentPageCount >= @PageCountLevel
					OR @PageCountLevel = 0)
			BEGIN
				IF EXISTS(SELECT [Priority],
									[Action],
									COUNT(*)
							FROM   @ActionsPreferred
							GROUP  BY [Priority],
									[Action]
							HAVING COUNT(*) <> 3)
					BEGIN
						SELECT @CurrentAction = [Action]
						FROM   @ActionsPreferred
						WHERE  FragmentationGroup = @CurrentFragmentationGroup
								AND [Priority] = (SELECT MIN([Priority])
													FROM   @ActionsPreferred
													WHERE  FragmentationGroup = @CurrentFragmentationGroup
														AND [Action] IN
															(SELECT [Action]
																FROM   @CurrentActionsAllowed))
					END
				ELSE
					BEGIN
						SELECT @CurrentAction = [Action]
						FROM   @ActionsPreferred
						WHERE  [Priority] = (SELECT MIN([Priority])
												FROM   @ActionsPreferred
												WHERE  [Action] IN
													(SELECT [Action]
														FROM   @CurrentActionsAllowed))
					END
			END

		-- Workaround for limitation in SQL Server, http://support.microsoft.com/kb/2292737
		IF @CurrentIndexID IS NOT NULL
			BEGIN
				SET @CurrentMaxDOP = @MaxDOP

				IF @CurrentAction = 'INDEX_REBUILD_ONLINE'
					AND @CurrentAllowPageLocks = 0
					BEGIN
						SET @CurrentMaxDOP = 1
					END
			END

		-- Update statistics?
		IF @CurrentStatisticsID IS NOT NULL
			AND ((@UpdateStatistics = 'ALL'
					AND (@CurrentIndexType IN (1, 2, 3, 4, 7)
						OR @CurrentIndexID IS NULL))
					OR (@UpdateStatistics = 'INDEX'
						AND @CurrentIndexID IS NOT NULL
						AND @CurrentIndexType IN (1, 2, 3, 4, 7))
					OR (@UpdateStatistics = 'COLUMNS'
						AND @CurrentIndexID IS NULL))
			AND (@CurrentStatisticsModified = 1
					OR @OnlyModifiedStatistics = 'N'
					OR @CurrentIsMemoryOptimized = 1)
			AND ((@CurrentIsPartition = 0
					AND (@CurrentAction NOT IN('INDEX_REBUILD_ONLINE', 'INDEX_REBUILD_OFFLINE')
						OR @CurrentAction IS NULL))
					OR (@CurrentIsPartition = 1
						AND @CurrentPartitionNumber = @CurrentPartitionCount))
			BEGIN
				SET @CurrentUpdateStatistics = 'Y'
			END
		ELSE
			BEGIN
				SET @CurrentUpdateStatistics = 'N'
			END

		IF @CurrentIndexID IS NOT NULL
			AND (@CurrentPageCount IS NOT NULL
					OR @CurrentFragmentationLevel IS NOT NULL)
			BEGIN
				SET @CurrentExtendedInfo = (SELECT *
											FROM   (SELECT CAST(@CurrentPageCount AS NVARCHAR)          AS [PageCount],
															CAST(@CurrentFragmentationLevel AS NVARCHAR) AS Fragmentation) ExtendedInfo
											FOR XML AUTO, ELEMENTS)
			END

		IF @CurrentIndexID IS NOT NULL
			AND @CurrentAction IS NOT NULL
			AND (GETDATE() < DATEADD(ss, @TimeLimit, @StartTime)
					OR @TimeLimit IS NULL)
			BEGIN
				SET @CurrentCommandType13 = 'ALTER_INDEX'
				SET @CurrentCommand13 = ''

				IF @LockTimeout IS NOT NULL
					SET @CurrentCommand13 = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS NVARCHAR) + '; '

				SET @CurrentCommand13 = @CurrentCommand13 + 'ALTER INDEX ' + QUOTENAME(@CurrentIndexName) + ' ON '
										+ QUOTENAME(@CurrentDatabaseName) + '.' + QUOTENAME(@CurrentSchemaName) + '.'
										+ QUOTENAME(@CurrentObjectName)

				IF @CurrentAction IN('INDEX_REBUILD_ONLINE', 'INDEX_REBUILD_OFFLINE')
					BEGIN
						SET @CurrentCommand13 = @CurrentCommand13 + ' REBUILD'

						IF @CurrentIsPartition = 1
							SET @CurrentCommand13 = @CurrentCommand13 + ' PARTITION = ' + CAST(@CurrentPartitionNumber AS NVARCHAR)

						SET @CurrentCommand13 = @CurrentCommand13 + ' WITH ('

						IF @SortInTempdb = 'Y'
							AND @CurrentIndexType IN(1, 2, 3, 4)
							SET @CurrentCommand13 = @CurrentCommand13 + 'SORT_IN_TEMPDB = ON'

						IF @SortInTempdb = 'N'
							AND @CurrentIndexType IN(1, 2, 3, 4)
							SET @CurrentCommand13 = @CurrentCommand13 + 'SORT_IN_TEMPDB = OFF'

						IF @CurrentIndexType IN(1, 2, 3, 4)
							AND (@CurrentIsPartition = 0
									OR @Version >= 12)
							SET @CurrentCommand13 = @CurrentCommand13 + ', '

						IF @CurrentAction = 'INDEX_REBUILD_ONLINE'
							AND (@CurrentIsPartition = 0
									OR @Version >= 12)
							SET @CurrentCommand13 = @CurrentCommand13 + 'ONLINE = ON'

						IF @CurrentAction = 'INDEX_REBUILD_ONLINE'
							AND @WaitAtLowPriorityMaxDuration IS NOT NULL
							SET @CurrentCommand13 = @CurrentCommand13 + ' (WAIT_AT_LOW_PRIORITY (MAX_DURATION = '
													+ CAST(@WaitAtLowPriorityMaxDuration AS NVARCHAR) + ', ABORT_AFTER_WAIT = '
													+ UPPER(@WaitAtLowPriorityAbortAfterWait) + '))'

						IF @CurrentAction = 'INDEX_REBUILD_OFFLINE'
							AND (@CurrentIsPartition = 0
									OR @Version >= 12)
							SET @CurrentCommand13 = @CurrentCommand13 + 'ONLINE = OFF'

						IF @CurrentMaxDOP IS NOT NULL
							SET @CurrentCommand13 = @CurrentCommand13 + ', MAXDOP = ' + CAST(@CurrentMaxDOP AS NVARCHAR)

						IF @FillFactor IS NOT NULL
							AND @CurrentIsPartition = 0
							AND @CurrentIndexType IN(1, 2, 3, 4)
							SET @CurrentCommand13 = @CurrentCommand13 + ', FILLFACTOR = ' + CAST(@FillFactor AS NVARCHAR)

						IF @PadIndex = 'Y'
							AND @CurrentIsPartition = 0
							AND @CurrentIndexType IN(1, 2, 3, 4)
							SET @CurrentCommand13 = @CurrentCommand13 + ', PAD_INDEX = ON'

						IF @PadIndex = 'N'
							AND @CurrentIsPartition = 0
							AND @CurrentIndexType IN(1, 2, 3, 4)
							SET @CurrentCommand13 = @CurrentCommand13 + ', PAD_INDEX = OFF'

						SET @CurrentCommand13 = @CurrentCommand13 + ')'
					END

				IF @CurrentAction IN('INDEX_REORGANIZE')
					BEGIN
						SET @CurrentCommand13 = @CurrentCommand13 + ' REORGANIZE'

						IF @CurrentIsPartition = 1
							SET @CurrentCommand13 = @CurrentCommand13 + ' PARTITION = ' + CAST(@CurrentPartitionNumber AS NVARCHAR)

						SET @CurrentCommand13 = @CurrentCommand13 + ' WITH ('

						IF @LOBCompaction = 'Y'
							SET @CurrentCommand13 = @CurrentCommand13 + 'LOB_COMPACTION = ON'

						IF @LOBCompaction = 'N'
							SET @CurrentCommand13 = @CurrentCommand13 + 'LOB_COMPACTION = OFF'

						SET @CurrentCommand13 = @CurrentCommand13 + ')'
					END

				IF @Delay > 0
					BEGIN
						SET @CurrentDelay = DATEADD(ss, @Delay, '1900-01-01')

						WAITFOR DELAY @CurrentDelay
					END
			END

		IF @CurrentStatisticsID IS NOT NULL
			AND @CurrentUpdateStatistics = 'Y'
			AND (GETDATE() < DATEADD(ss, @TimeLimit, @StartTime)
					OR @TimeLimit IS NULL)
			BEGIN
				SET @CurrentCommandType14 = 'UPDATE_STATISTICS'
				SET @CurrentCommand14 = ''

				IF @LockTimeout IS NOT NULL
					SET @CurrentCommand14 = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS NVARCHAR) + '; '

				SET @CurrentCommand14 = @CurrentCommand14 + 'UPDATE STATISTICS ' + QUOTENAME(@CurrentDatabaseName) + '.'
										+ QUOTENAME(@CurrentSchemaName) + '.' + QUOTENAME(@CurrentObjectName) + ' '
										+ QUOTENAME(@CurrentStatisticsName)

				IF @StatisticsSample IS NOT NULL
					OR @StatisticsResample = 'Y'
					OR @CurrentNoRecompute = 1
					SET @CurrentCommand14 = @CurrentCommand14 + ' WITH'

				IF @StatisticsSample = 100
					SET @CurrentCommand14 = @CurrentCommand14 + ' FULLSCAN'

				IF @StatisticsSample IS NOT NULL
					AND @StatisticsSample <> 100
					AND (@CurrentIsMemoryOptimized = 0
							OR @CurrentIsMemoryOptimized IS NULL)
					SET @CurrentCommand14 = @CurrentCommand14 + ' SAMPLE ' + CAST(@StatisticsSample AS NVARCHAR) + ' PERCENT'

				IF @StatisticsResample = 'Y'
					OR (@CurrentIsMemoryOptimized = 1
						AND (@StatisticsSample <> 100
								OR @StatisticsSample IS NULL))
					SET @CurrentCommand14 = @CurrentCommand14 + ' RESAMPLE'

				IF (@StatisticsSample IS NOT NULL
						OR @StatisticsResample = 'Y'
						OR @CurrentIsMemoryOptimized = 1)
					AND @CurrentNoRecompute = 1
					SET @CurrentCommand14 = @CurrentCommand14 + ','

				IF @CurrentNoRecompute = 1
					SET @CurrentCommand14 = @CurrentCommand14 + ' NORECOMPUTE'

			END


		-- Insert the index metrics
		IF @Version >= 11
			SET @ColumnStore = CASE WHEN @CurrentIsColumnStore = 1 THEN 'Yes' WHEN @CurrentIsColumnStore = 0 THEN 'No' ELSE 'N/A' END;
		ELSE
			SET @ColumnStore = 'N/A';

		IF (@CurrentFragmentationLevel >= @FragmentationLevel1)
		BEGIN

			INSERT INTO @IndexMetrics(DatabaseName, IndexName, ObjectType, IndexType, ImageText, NewLOB, FileStream, ColumnStore, AllowPageLocks, PageCount, Size_MB, Fragmentation, AlterIndexCommand, UpdateStatsCommand)
			VALUES
			(
				@CurrentDatabaseName,
				@CurrentIndexName,
				CASE WHEN @CurrentObjectType = 'U' THEN 'Table' WHEN @CurrentObjectType = 'V' THEN 'View' ELSE 'N/A' END,
				CASE WHEN @CurrentIndexType = 1 THEN 'Clustered' WHEN @CurrentIndexType = 2 THEN 'NonClustered' WHEN @CurrentIndexType = 3 THEN 'XML' WHEN @CurrentIndexType = 4 THEN 'Spatial' WHEN @CurrentIndexType = 5 THEN 'Clustered Columnstore' WHEN @CurrentIndexType = 6 THEN 'NonClustered Columnstore' WHEN @CurrentIndexType = 7 THEN 'NonClustered Hash' ELSE 'N/A' END,
				CASE WHEN @CurrentIsImageText = 1 THEN 'Yes' WHEN @CurrentIsImageText = 0 THEN 'No' ELSE 'N/A' END,
				CASE WHEN @CurrentIsNewLOB = 1 THEN 'Yes' WHEN @CurrentIsNewLOB = 0 THEN 'No' ELSE 'N/A' END,
				CASE WHEN @CurrentIsFileStream = 1 THEN 'Yes' WHEN @CurrentIsFileStream = 0 THEN 'No' ELSE 'N/A' END,
				@ColumnStore,
				CASE WHEN @CurrentAllowPageLocks = 1 THEN 'Yes' WHEN @CurrentAllowPageLocks = 0 THEN 'No' ELSE 'N/A' END,
				ISNULL(CAST(@CurrentPageCount AS NVARCHAR), 'N/A'),
				ISNULL(CAST(@CurrentPageCount / 128 AS NVARCHAR), 'N/A'),
				ISNULL(CAST(@CurrentFragmentationLevel AS NVARCHAR), 'N/A'),
				@CurrentCommand13,
				@CurrentCommand14
			)

		END



		NOACTION:

		-- Update that the index is completed
		UPDATE @tmpIndexesStatistics
		SET    Completed = 1
		WHERE  Selected = 1
				AND Completed = 0
				AND ID = @CurrentIxID

		-- Clear variables
		SET @CurrentCommand02 = NULL
		SET @CurrentCommand03 = NULL
		SET @CurrentCommand04 = NULL
		SET @CurrentCommand05 = NULL
		SET @CurrentCommand06 = NULL
		SET @CurrentCommand07 = NULL
		SET @CurrentCommand08 = NULL
		SET @CurrentCommand09 = NULL
		SET @CurrentCommand10 = NULL
		SET @CurrentCommand11 = NULL
		SET @CurrentCommand12 = NULL
		SET @CurrentCommand13 = NULL
		SET @CurrentCommand14 = NULL
		SET @CurrentCommandOutput13 = NULL
		SET @CurrentCommandOutput14 = NULL
		SET @CurrentCommandType13 = NULL
		SET @CurrentCommandType14 = NULL
		SET @CurrentIxID = NULL
		SET @CurrentSchemaID = NULL
		SET @CurrentSchemaName = NULL
		SET @CurrentObjectID = NULL
		SET @CurrentObjectName = NULL
		SET @CurrentObjectType = NULL
		SET @CurrentIsMemoryOptimized = NULL
		SET @CurrentIndexID = NULL
		SET @CurrentIndexName = NULL
		SET @CurrentIndexType = NULL
		SET @CurrentStatisticsID = NULL
		SET @CurrentStatisticsName = NULL
		SET @CurrentPartitionID = NULL
		SET @CurrentPartitionNumber = NULL
		SET @CurrentPartitionCount = NULL
		SET @CurrentIsPartition = NULL
		SET @CurrentIndexExists = NULL
		SET @CurrentStatisticsExists = NULL
		SET @CurrentIsImageText = NULL
		SET @CurrentIsNewLOB = NULL
		SET @CurrentIsFileStream = NULL
		SET @CurrentIsColumnStore = NULL
		SET @CurrentAllowPageLocks = NULL
		SET @CurrentNoRecompute = NULL
		SET @CurrentStatisticsModified = NULL
		SET @CurrentOnReadOnlyFileGroup = NULL
		SET @CurrentFragmentationLevel = NULL
		SET @CurrentPageCount = NULL
		SET @CurrentFragmentationGroup = NULL
		SET @CurrentAction = NULL
		SET @CurrentMaxDOP = NULL
		SET @CurrentUpdateStatistics = NULL
		SET @CurrentComment = NULL
		SET @CurrentExtendedInfo = NULL

		DELETE FROM @CurrentActionsAllowed

		END

		END
		
		PRINT '';

--SELECT * FROM @IndexMetrics;

		-- Update that the database is completed
		UPDATE @tmpDatabases
		SET    Completed = 1
		WHERE  Selected = 1
				AND Completed = 0
				AND ID = @CurrentDBID

		-- Clear variables
		SET @CurrentDBID = NULL
		SET @CurrentDatabaseID = NULL
		SET @CurrentDatabaseName = NULL
		SET @CurrentIsDatabaseAccessible = NULL
		SET @CurrentAvailabilityGroup = NULL
		SET @CurrentAvailabilityGroupRole = NULL
		SET @CurrentDatabaseMirroringRole = NULL
		SET @CurrentCommand01 = NULL

		DELETE FROM @tmpIndexesStatistics;
--DELETE FROM @IndexMetrics;


	END


		----------------------------------------------------------------------------------------------------
		--// Email the report for the current database                                                  //--
		----------------------------------------------------------------------------------------------------
		
		DECLARE 
			@tableHTML NVARCHAR(MAX),
			@title     NVARCHAR(128),
			@server    NVARCHAR(128);

		SELECT @server = @@SERVERNAME;
		SELECT @title = N'Reindex Report: ' + @server;

		SET @tableHTML =	N'<table border="1">' +
							N'<tr><th>Server Name</th>' +
							N'<th>Database Name</th>' +
							N'<th>Index Name</th>' +
							N'<th>Object Type</th>' +
							N'<th>Index Type</th>' +
							N'<th>Image Text</th>' +
							N'<th>New LOB</th>' +
							N'<th>File Stream</th>' +
							N'<th>Column Store</th>' +
							N'<th>Allow Page Locks</th>' +
							N'<th>Page Count</th>' +
							N'<th>Size_MB</th>' +
							N'<th>Fragmentation</th>' +
							N'<th>AlterIndexCommand</th>' +
							N'<th>UpdateStatsCommand</th></tr>' +
							CAST( ( SELECT 
										td = @server, '',
										td = [DatabaseName], '',
										td = [IndexName], '',
										td = [ObjectType], '',
										td = [IndexType], '',
										td = [ImageText], '',
										td = [NewLOB], '',
										td = [FileStream], '',
										td = [ColumnStore], '',
										td = [AllowPageLocks], '',
										td = [PageCount], '',
										td = [Size_MB], '',
										td = [Fragmentation], '',
										td = [AlterIndexCommand], '',
										td = [UpdateStatsCommand], ''
				 					FROM
										@IndexMetrics
									ORDER BY [DatabaseName], CAST([Size_MB]  AS INT)
									FOR XML PATH('tr'), TYPE
								) AS NVARCHAR(MAX) ) +
							N'</table>' ;

		IF ((SELECT COUNT(*) FROM @IndexMetrics) = 0)
		BEGIN

			SET @tableHTML =	'<pre>No indexes meet the requirements specified by the index parameters for reindexing.

@FragmentationLevel1 = ' + CAST(@FragmentationLevel1 AS NVARCHAR(10)) + '
@FragmentationLevel2 = ' + CAST(@FragmentationLevel2 AS NVARCHAR(10)) + '
@PageCountLevel = ' + CAST(@PageCountLevel AS NVARCHAR(10)) + '</pre>'

		END

		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'SQL Notifier',
			@recipients = @Email,
			@subject = @title,
			@body = @tableHTML,
			@body_format = 'HTML' ;


    ----------------------------------------------------------------------------------------------------
    --// Display the metrics and commands                                                           //--
    ----------------------------------------------------------------------------------------------------

    --SELECT * FROM @IndexMetrics;

	
    ----------------------------------------------------------------------------------------------------
    --// Log completing information                                                                 //--
    ----------------------------------------------------------------------------------------------------

    LOGGING:

    SET @EndMessage = 'Date and time: ' + CONVERT(NVARCHAR, GETDATE(), 120)
    SET @EndMessage = REPLACE(@EndMessage, '%', '%%')

    RAISERROR(@EndMessage,10,1) WITH NOWAIT

    IF @ReturnCode <> 0
        BEGIN
            RETURN @ReturnCode
        END

----------------------------------------------------------------------------------------------------

END


GO


