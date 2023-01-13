/*********************************************************************************************************************
* 
* TROUBLESHOOT_ProcExecutionTime.sql
* 
* Author: James Lutsey
* Date:   2018-05-31
* 
* Purpose: Get the average execution time (total_elapsed_time) that a stored procedure is CURRENTLY experiencing.
* 
* Notes: - Enter the object id, or the schema and procedure names.
*        - You can change the units of the result with @Unit (default is miliseconds).
*        - You can change the time interval this script uses to collect stats with @WaitforDelay (default is 30 seconds).
* 
* Date        Name                  Description of change
* ----------  --------------------  ---------------------------------------------------------------------------------
* 
* 
*********************************************************************************************************************/


--  SELECT N'USE [' + name + N'];' FROM sys.databases ORDER BY name;

--  SELECT * FROM sys.dm_exec_procedure_stats WHERE object_id = 1814870128;

USE [GSF2_AMER_PROD];

----------------------------------------------
--// USER INPUT                           //--
----------------------------------------------

DECLARE @ObjectId      AS INT           = 0,    --|\      ( enter either @ObjectId, or the schema and procedure names )
        @SchemaName    AS NVARCHAR(128) = N'dbo',  --| >-->  select p.object_id, s.name, p.name from sys.procedures p join sys.schemas s on s.schema_id = p.schema_id order by s.name, p.name;
        @ProcedureName AS NVARCHAR(128) = N'usp_LicensePlateInventoryInfoPostSmtTableType_Select',  --|/      
        @Unit          AS NVARCHAR(128) = N'seconds', -- microseconds, miliseconds, seconds, minutes
        @WaitforDelay  AS CHAR(8)       = '00:00:30';

-- other variables
DECLARE @Conversion          AS DECIMAL(9,1),
        @ExecutionCount1     AS BIGINT,
        @ExecutionCount2     AS BIGINT,
        @msg                 AS NVARCHAR(MAX),
        @time1               AS DATETIME2(3),
        @time2               AS DATETIME2(3),
        @TotalElapsedTime1   AS BIGINT,
        @TotalElapsedTime2   AS BIGINT,
        @TotalPhysicalReads1 AS BIGINT,
        @TotalPhysicalReads2 AS BIGINT,
        @TotalLogicalReads1  AS BIGINT,
        @TotalLogicalReads2  AS BIGINT,
        @TotalLogicalWrites1 AS BIGINT,
        @TotalLogicalWrites2 AS BIGINT,
        @TotalWorkerTime1    AS BIGINT,
        @TotalWorkerTime2    AS BIGINT;



----------------------------------------------
--// VALIDTATE USER INPUT                 //--
----------------------------------------------

-- if user supplied the procedure name, get the object_id
IF @SchemaName <> N'' AND @ProcedureName <> N''
BEGIN
    IF EXISTS(SELECT 1 FROM sys.objects WHERE SCHEMA_NAME(schema_id) = @SchemaName AND name = @ProcedureName)
    BEGIN
        SELECT @ObjectId = object_id
        FROM   sys.objects
        WHERE  schema_id = SCHEMA_ID(@SchemaName)
               AND name = @ProcedureName;
    END;
    ELSE
    BEGIN
        SET @msg = N'[' + DB_NAME() + N'].[' + @SchemaName + N'].[' + @ProcedureName + N'] does not exist.';
        RAISERROR(@msg,16,1) WITH NOWAIT;
        SET NOEXEC ON;
    END;
END;
ELSE -- check if the user entered a valid value for @ObjectId
BEGIN
    IF OBJECT_NAME(@ObjectId) IS NULL
    BEGIN
        SET @msg = CAST(@ObjectId AS NVARCHAR(20)) + N' is not a valid object_id.' + NCHAR(0x000D) + NCHAR(0x000A) + 
                   N'You must enter either a valid object id or schema name and procedure name.';
        RAISERROR(@msg,16,1) WITH NOWAIT;
        SET NOEXEC ON;
    END;
END;

-- set the conversion rate for the units requested by the user
IF      @Unit = N'microseconds' SET @Conversion = 1.0;
ELSE IF @Unit = N'miliseconds'  SET @Conversion = 1000.0;
ELSE IF @Unit = N'seconds'      SET @Conversion = 1000000.0;
ELSE IF @Unit = N'minutes'      SET @Conversion = 60000000.0;
ELSE
BEGIN
    SET @msg = N'"' + @Unit + N'" is not a valid value for @Unit. Please enter microseconds, miliseconds, seconds, or minutes.';
    RAISERROR(@msg,16,1) WITH NOWAIT;
    SET NOEXEC ON;
END;



----------------------------------------------
--// GET THE INFO                         //--
----------------------------------------------

SELECT @ExecutionCount1 = SUM(execution_count),
       @TotalElapsedTime1 = SUM(total_elapsed_time),
       @TotalWorkerTime1 = SUM(total_worker_time),
       @TotalPhysicalReads1 = SUM(total_physical_reads),
       @TotalLogicalReads1 = SUM(total_logical_reads),
       @TotalLogicalWrites1 = SUM(total_logical_writes),
       @time1 = GETDATE()
FROM   sys.dm_exec_procedure_stats
WHERE  object_id = @ObjectId;

WAITFOR DELAY @WaitforDelay;

SELECT @ExecutionCount2 = SUM(execution_count),
       @TotalElapsedTime2 = SUM(total_elapsed_time),
       @TotalWorkerTime2 = SUM(total_worker_time),
       @TotalPhysicalReads2 = SUM(total_physical_reads),
       @TotalLogicalReads2 = SUM(total_logical_reads),
       @TotalLogicalWrites2 = SUM(total_logical_writes),
       @time2 = GETDATE()
FROM   sys.dm_exec_procedure_stats
WHERE  object_id = @ObjectId;



----------------------------------------------
--// DISPLAY THE RESULT                   //--
----------------------------------------------

IF @ExecutionCount2 <> @ExecutionCount1
BEGIN
    SELECT @Unit                                                                                                                                         AS Unit,
           CAST(CAST((@TotalElapsedTime2 - @TotalElapsedTime1) AS DECIMAL(20,1)) / (@ExecutionCount2 - @ExecutionCount1) / @Conversion AS DECIMAL(20,2)) AS AvgElapsedTime,
           CAST(CAST((@TotalWorkerTime2  - @TotalWorkerTime1) AS DECIMAL(20,1))  / (@ExecutionCount2 - @ExecutionCount1) / @Conversion AS DECIMAL(20,2)) AS AvgWorkerTime,
           CAST(ROUND(CAST((@ExecutionCount2 - @ExecutionCount1) AS DECIMAL(20,1)) / DATEDIFF(MILLISECOND,@time1,@time2) * 60000,0) AS INT)              AS AvgExecPerMinute,
           CAST(ROUND(CAST((@TotalPhysicalReads2  - @TotalPhysicalReads1) AS DECIMAL(20,1))  / (@ExecutionCount2 - @ExecutionCount1),0) AS INT)          AS AvgPhysicalReads,
           CAST(ROUND(CAST((@TotalLogicalReads2  - @TotalLogicalReads1) AS DECIMAL(20,1))  / (@ExecutionCount2 - @ExecutionCount1),0) AS INT)            AS AvgLogicalReads,
           CAST(ROUND(CAST((@TotalLogicalWrites2  - @TotalLogicalWrites1) AS DECIMAL(20,1))  / (@ExecutionCount2 - @ExecutionCount1),0) AS INT)          AS AvgLogicalWrites,
           cached_time
    FROM   sys.dm_exec_procedure_stats
    WHERE  object_id = @ObjectId;
END;
ELSE
BEGIN
    RAISERROR(N'There were no executions in the timeframe this query executed. Consider increasing the WAITFOR DELAY time.',0,1) WITH NOWAIT;
END;



----------------------------------------------
--// RESET                                //--
----------------------------------------------

SET NOEXEC OFF;

