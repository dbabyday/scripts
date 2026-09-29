DROP TABLE IF EXISTS #james_deadlocks;
CREATE TABLE #james_deadlocks (
	database_name sysname NOT NULL,
	deadlocks bigint NULL,
	start_date datetime NULL,
	end_date datetime NULL
);



IF OBJECT_ID('tempdb..#JamesLock') IS NOT NULL
        DROP PROCEDURE #JamesLock;
GO

CREATE PROCEDURE
    #JamesLock
(
    @DatabaseName sysname = NULL,
    @StartDate datetime = NULL,
    @EndDate datetime = NULL,
    @ObjectName nvarchar(1024) = NULL,
    @StoredProcName nvarchar(1024) = NULL,
    @AppName sysname = NULL,
    @HostName sysname = NULL,
    @LoginName sysname = NULL,
    @EventSessionName sysname = N'system_health',
    @TargetSessionType sysname = NULL,
    @VictimsOnly bit = 0,
    @DeadlockType nvarchar(20) = NULL,
    @TargetDatabaseName sysname = NULL,      
    @TargetSchemaName sysname = NULL,        
    @TargetTableName sysname = NULL,         
    @TargetColumnName sysname = NULL,       
    @TargetTimestampColumnName sysname = NULL,
    @Debug bit = 0,
    @Help bit = 0,
    @Version varchar(30) = NULL OUTPUT,
    @VersionDate datetime = NULL OUTPUT,
    @VersionCheckMode bit = 0,
    @OutputDatabaseName sysname = NULL,
    @OutputSchemaName sysname = N'dbo',      /*ditto as below*/
    @OutputTableName sysname = N'BlitzLock', /*put a standard here no need to check later in the script*/
    @ExportToExcel bit = 0
)
WITH RECOMPILE
AS
BEGIN
    SET STATISTICS XML OFF;
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


    /*Declare local variables used in the procudure*/
    DECLARE
        @DatabaseId int =
            DB_ID(@DatabaseName),
        @ProductVersion nvarchar(128) =
            CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(128)),
        @ProductVersionMajor float =
            SUBSTRING
            (
                CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(128)),
                1,
                CHARINDEX('.', CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(128))) + 1
            ),
        @ProductVersionMinor int =
            PARSENAME
            (
                CONVERT
                (
                    varchar(32),
                    CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(128))
                ),
                2
            ),
        @ObjectFullName nvarchar(MAX) = N'',
        @Azure bit =
            CASE
                WHEN
                (
                    SELECT
                        CONVERT
                        (
                            integer,
                            SERVERPROPERTY('EngineEdition')
                        )
                ) = 5
                THEN 1
                ELSE 0
            END,
        @MI bit =
            CASE
                WHEN
                (
                    SELECT
                        CONVERT
                        (
                            integer,
                            SERVERPROPERTY('EngineEdition')
                        )
                ) = 8
                THEN 1
                ELSE 0
            END,
        @RDS bit =
            CASE
                WHEN LEFT(CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS varchar(8000)), 8) <> 'EC2AMAZ-'
                AND  LEFT(CAST(SERVERPROPERTY('MachineName') AS varchar(8000)), 8) <> 'EC2AMAZ-'
                AND  DB_ID('rdsadmin') IS NULL
                THEN 0
                ELSE 1
            END,
        @d varchar(40) = '',
        @StringToExecute nvarchar(4000) = N'',
        @StringToExecuteParams nvarchar(500) = N'',
        @r sysname = NULL,
        @OutputTableFindings nvarchar(100) = N'[BlitzLockFindings]',
        @DeadlockCount int = 0,
        @ServerName sysname = @@SERVERNAME,
        @OutputDatabaseCheck bit = -1,
        @SessionId int = 0,
        @TargetSessionId int = 0,
        @FileName nvarchar(4000) = N'',
        @inputbuf_bom nvarchar(1) = CONVERT(nvarchar(1), 0x0a00, 0),
        @deadlock_result nvarchar(MAX) = N'',
        @StartDateOriginal datetime = @StartDate,
        @EndDateOriginal datetime = @EndDate,
        @StartDateUTC datetime,
        @EndDateUTC datetime,
        @extract_sql nvarchar(MAX),
        @validation_sql nvarchar(MAX),
        @xe bit,
        @xd bit;

    /*Temporary objects used in the procedure*/
    DECLARE
        @sysAssObjId AS table
    (
        database_id int,
        partition_id bigint,
        schema_name sysname,
        table_name sysname
    );

    CREATE TABLE
        #x
    (
        x xml NOT NULL
            DEFAULT N'<x>x</x>'
    );

    CREATE TABLE
        #deadlock_data
    (
        deadlock_xml xml NOT NULL
            DEFAULT N'<x>x</x>'
    );

    CREATE TABLE
        #t
    (
        id int NOT NULL
    );

    CREATE TABLE
        #deadlock_findings
    (
        id int IDENTITY PRIMARY KEY,
        check_id int NOT NULL,
        database_name nvarchar(256),
        object_name nvarchar(1000),
        finding_group nvarchar(100),
        finding nvarchar(4000),
        sort_order bigint
    );









    /*Set these to some sane defaults if NULLs are passed in*/
    /*Normally I'd hate this, but we RECOMPILE everything*/

    SELECT
        @StartDate =
            CASE
                WHEN @StartDate IS NULL
                THEN
                    DATEADD
                    (
                        MINUTE,
                        DATEDIFF
                        (
                            MINUTE,
                            SYSDATETIME(),
                            GETUTCDATE()
                        ),
                        DATEADD
                        (
                            DAY,
                            -7,
                            SYSDATETIME()
                        )
                    )
                ELSE
                    DATEADD
                    (
                        MINUTE,
                        DATEDIFF
                        (
                            MINUTE,
                            SYSDATETIME(),
                            GETUTCDATE()
                        ),
                        @StartDate
                    )
            END,
        @EndDate =
            CASE
                WHEN @EndDate IS NULL
                THEN
                    DATEADD
                    (
                        MINUTE,
                        DATEDIFF
                        (
                            MINUTE,
                            SYSDATETIME(),
                            GETUTCDATE()
                        ),
                        SYSDATETIME()
                    )
                ELSE
                    DATEADD
                    (
                        MINUTE,
                        DATEDIFF
                        (
                            MINUTE,
                            SYSDATETIME(),
                            GETUTCDATE()
                        ),
                        @EndDate
                    )
            END;

-- SELECT
--             @StartDateOriginal = @StartDate,
--             @EndDateOriginal = @EndDate;


    SELECT
        @StartDateUTC = @StartDate,
        @EndDateUTC = @EndDate;

    IF
    (
            @MI = 1
        AND @EventSessionName = N'system_health'
        AND @TargetSessionType IS NULL
    )
    BEGIN
        SET
            @TargetSessionType = N'ring_buffer';
    END;

    IF  ISNULL(@TargetDatabaseName, DB_NAME()) IS NOT NULL
    AND ISNULL(@TargetSchemaName, N'dbo') IS NOT NULL
    AND @TargetTableName IS NOT NULL
    AND @TargetColumnName IS NOT NULL
    BEGIN
        SET @TargetSessionType = N'table';
    END;

    /* Add this after the existing parameter validations */
    IF @TargetSessionType = N'table'
    BEGIN     
        IF @TargetDatabaseName IS NULL
        BEGIN
            SET @TargetDatabaseName = DB_NAME();
        END;

        IF @TargetSchemaName IS NULL
        BEGIN
            SET @TargetSchemaName = N'dbo';
        END;

        IF @TargetTableName IS NULL
        OR @TargetColumnName IS NULL
        BEGIN
            RAISERROR(N'
            When using a table as a source, you must specify @TargetTableName, and @TargetColumnName.
            When @TargetDatabaseName or @TargetSchemaName is NULL, they default to DB_NAME() AND dbo',
            11, 1) WITH NOWAIT;
            RETURN;
        END;
   
        /* Check if target database exists */
        IF NOT EXISTS
        (
            SELECT
                1/0
            FROM sys.databases AS d
            WHERE d.name = @TargetDatabaseName
        )
        BEGIN
            RAISERROR(N'The specified @TargetDatabaseName %s does not exist.', 11, 1, @TargetDatabaseName) WITH NOWAIT;
            RETURN;
        END;
   
        /* Use dynamic SQL to validate schema, table, and column existence */
        SET @validation_sql = N'
        IF NOT EXISTS
        (
            SELECT
                1/0
            FROM ' + QUOTENAME(@TargetDatabaseName) + N'.sys.schemas AS s
            WHERE s.name = @schema
        )
        BEGIN
            RAISERROR(N''The specified @TargetSchemaName %s does not exist in database %s.'', 11, 1, @schema, @database) WITH NOWAIT;
            RETURN;
        END;
   
        IF NOT EXISTS
        (
            SELECT
                1/0
            FROM ' + QUOTENAME(@TargetDatabaseName) + N'.sys.tables AS t
            JOIN ' + QUOTENAME(@TargetDatabaseName) + N'.sys.schemas AS s
              ON t.schema_id = s.schema_id
            WHERE t.name = @table
            AND   s.name = @schema
        )
        BEGIN
            RAISERROR(N''The specified @TargetTableName %s does not exist in schema %s in database %s.'', 11, 1, @table, @schema, @database) WITH NOWAIT;
            RETURN;
        END;
   
        IF NOT EXISTS
        (
            SELECT
                1/0
            FROM ' + QUOTENAME(@TargetDatabaseName) + N'.sys.columns AS c
            JOIN ' + QUOTENAME(@TargetDatabaseName) + N'.sys.tables AS t
              ON c.object_id = t.object_id
            JOIN ' + QUOTENAME(@TargetDatabaseName) + N'.sys.schemas AS s
              ON t.schema_id = s.schema_id
            WHERE c.name = @column
            AND   t.name = @table
            AND   s.name = @schema
        )
        BEGIN
            RAISERROR(N''The specified @TargetColumnName %s does not exist in table %s.%s in database %s.'', 11, 1, @column, @schema, @table, @database) WITH NOWAIT;
            RETURN;
        END;
   
        /* Validate column is XML type */
        IF NOT EXISTS
        (
            SELECT
                1/0
            FROM ' + QUOTENAME(@TargetDatabaseName) + N'.sys.columns AS c
            JOIN ' + QUOTENAME(@TargetDatabaseName) + N'.sys.types AS ty
              ON c.user_type_id = ty.user_type_id
            JOIN ' + QUOTENAME(@TargetDatabaseName) + N'.sys.tables AS t
              ON c.object_id = t.object_id
            JOIN ' + QUOTENAME(@TargetDatabaseName) + N'.sys.schemas AS s
              ON t.schema_id = s.schema_id
            WHERE c.name = @column
            AND   t.name = @table
            AND   s.name = @schema
            AND   ty.name = N''xml''
        )
        BEGIN
            RAISERROR(N''The specified @TargetColumnName %s must be of XML data type.'', 11, 1, @column) WITH NOWAIT;
            RETURN;
        END;';
   
        /* Validate timestamp_column if specified */
        IF @TargetTimestampColumnName IS NOT NULL
        BEGIN
            SET @validation_sql = @validation_sql + N'
        IF NOT EXISTS
        (
            SELECT
                1/0
            FROM ' + QUOTENAME(@TargetDatabaseName) + N'.sys.columns AS c
            JOIN ' + QUOTENAME(@TargetDatabaseName) + N'.sys.tables AS t
              ON c.object_id = t.object_id
            JOIN ' + QUOTENAME(@TargetDatabaseName) + N'.sys.schemas AS s
              ON t.schema_id = s.schema_id
            WHERE c.name = @timestamp_column
            AND   t.name = @table
            AND   s.name = @schema
        )
        BEGIN
            RAISERROR(N''The specified @TargetTimestampColumnName %s does not exist in table %s.%s in database %s.'', 11, 1, @timestamp_column, @schema, @table, @database) WITH NOWAIT;
            RETURN;
        END;
   
        /* Validate timestamp column is datetime type */
        IF NOT EXISTS
        (
            SELECT
                1/0
            FROM ' + QUOTENAME(@TargetDatabaseName) + N'.sys.columns AS c
            JOIN ' + QUOTENAME(@TargetDatabaseName) + N'.sys.types AS ty
              ON c.user_type_id = ty.user_type_id
            JOIN ' + QUOTENAME(@TargetDatabaseName) + N'.sys.tables AS t
              ON c.object_id = t.object_id
            JOIN ' + QUOTENAME(@TargetDatabaseName) + N'.sys.schemas AS s
              ON t.schema_id = s.schema_id
            WHERE c.name = @timestamp_column
            AND   t.name = @table
            AND   s.name = @schema
            AND   ty.name LIKE ''%date%''
        )
        BEGIN
            RAISERROR(N''The specified @TargetTimestampColumnName %s must be of datetime data type.'', 11, 1, @timestamp_column) WITH NOWAIT;
            RETURN;
        END;';
        END;
   
        IF @Debug = 1 BEGIN PRINT @validation_sql; END;
       
        EXECUTE sys.sp_executesql
            @validation_sql,
          N'
            @database sysname,
            @schema sysname,
            @table sysname,
            @column sysname,
            @timestamp_column sysname
          ',
            @TargetDatabaseName,
            @TargetSchemaName,
            @TargetTableName,
            @TargetColumnName,
            @TargetTimestampColumnName;
    END;


    IF @Azure = 0
    AND LOWER(@TargetSessionType) <> N'table'
    BEGIN
        IF NOT EXISTS
        (
            SELECT
                1/0
            FROM sys.server_event_sessions AS ses
            JOIN sys.dm_xe_sessions AS dxs
              ON dxs.name = ses.name
            WHERE ses.name = @EventSessionName
            AND   dxs.create_time IS NOT NULL
        )
        BEGIN
            RAISERROR('A session with the name %s does not exist or is not currently active.', 11, 1, @EventSessionName) WITH NOWAIT;
            RETURN;
        END;
    END;

    IF @Azure = 1
    AND LOWER(@TargetSessionType) <> N'table'
    BEGIN
        IF NOT EXISTS
        (
            SELECT
                1/0
            FROM sys.database_event_sessions AS ses
            JOIN sys.dm_xe_database_sessions AS dxs
              ON dxs.name = ses.name
            WHERE ses.name = @EventSessionName
            AND   dxs.create_time IS NOT NULL
        )
        BEGIN
            RAISERROR('A session with the name %s does not exist or is not currently active.', 11, 1, @EventSessionName) WITH NOWAIT;
            RETURN;
        END;
    END;

    IF @OutputDatabaseName IS NOT NULL
    BEGIN /*IF databaseName is set, do some sanity checks and put [] around def.*/
        SET @d = CONVERT(varchar(40), GETDATE(), 109);
        RAISERROR('@OutputDatabaseName set to %s, checking validity at %s', 0, 1, @OutputDatabaseName, @d) WITH NOWAIT;

        IF NOT EXISTS
        (
            SELECT
                1/0
            FROM sys.databases AS d
            WHERE d.name = @OutputDatabaseName
        ) /*If database is invalid raiserror and set bitcheck*/
        BEGIN
            RAISERROR('Database Name (%s) for output of table is invalid please, Output to Table will not be performed', 0, 1, @OutputDatabaseName) WITH NOWAIT;
            SET @OutputDatabaseCheck = -1; /* -1 invalid/false, 0 = good/true */
        END;
        ELSE
        BEGIN
            SET @OutputDatabaseCheck = 0;

            SELECT
                @StringToExecute =
                    N'SELECT @r = o.name FROM ' +
                    @OutputDatabaseName +
                    N'.sys.objects AS o WHERE o.type_desc = N''USER_TABLE'' AND o.name = ' +
                    QUOTENAME
                    (
                        @OutputTableName,
                        N''''
                    ) +
                    N' AND o.schema_id = SCHEMA_ID(' +
                    QUOTENAME
                    (
                        @OutputSchemaName,
                        N''''
                    ) +
                    N');',
                @StringToExecuteParams =
                    N'@r sysname OUTPUT';

            IF @Debug = 1 BEGIN PRINT @StringToExecute; END;
            EXECUTE sys.sp_executesql
                @StringToExecute,
                @StringToExecuteParams,
                @r OUTPUT;

            IF @Debug = 1
            BEGIN
                RAISERROR('@r is set to: %s for schema name %s  and table name %s', 0, 1, @r, @OutputSchemaName, @OutputTableName) WITH NOWAIT;
            END;

            /*protection spells*/
            SELECT
                @ObjectFullName =
                    QUOTENAME(@OutputDatabaseName) +
                    N'.' +
                    QUOTENAME(@OutputSchemaName) +
                    N'.' +
                    QUOTENAME(@OutputTableName),
                @OutputDatabaseName =
                    QUOTENAME(@OutputDatabaseName),
                @OutputTableName =
                    QUOTENAME(@OutputTableName),
                @OutputSchemaName =
                    QUOTENAME(@OutputSchemaName);

            IF (@r IS NOT NULL) /*if it is not null, there is a table, so check for newly added columns*/
            BEGIN
                /* If the table doesn't have the new spid column, add it. See Github #3101. */
                SET @StringToExecute =
                        N'IF NOT EXISTS (SELECT 1/0 FROM ' +
                        @OutputDatabaseName +
                        N'.sys.all_columns AS o WHERE o.object_id = (OBJECT_ID(''' +
                        @ObjectFullName +
                        N''')) AND o.name = N''spid'')
                        /*Add spid column*/
                        ALTER TABLE ' +
                        @ObjectFullName +
                        N' ADD spid smallint NULL;';

                IF @Debug = 1 BEGIN PRINT @StringToExecute; END;
                EXECUTE sys.sp_executesql
                    @StringToExecute;

                /* If the table doesn't have the new wait_resource column, add it. See Github #3101. */
                SET @StringToExecute =
                        N'IF NOT EXISTS (SELECT 1/0 FROM ' +
                        @OutputDatabaseName +
                        N'.sys.all_columns AS o WHERE o.object_id = (OBJECT_ID(''' +
                        @ObjectFullName +
                        N''')) AND o.name = N''wait_resource'')
                        /*Add wait_resource column*/
                        ALTER TABLE ' +
                        @ObjectFullName +
                        N' ADD wait_resource nvarchar(MAX) NULL;';

                IF @Debug = 1 BEGIN PRINT @StringToExecute; END;
                EXECUTE sys.sp_executesql
                    @StringToExecute;

                /* If the table doesn't have the new client option column, add it. See Github #3101. */
                SET @StringToExecute =
                        N'IF NOT EXISTS (SELECT 1/0 FROM ' +
                        @OutputDatabaseName +
                        N'.sys.all_columns AS o WHERE o.object_id = (OBJECT_ID(''' +
                        @ObjectFullName +
                        N''')) AND o.name = N''client_option_1'')
                        /*Add wait_resource column*/
                        ALTER TABLE ' +
                        @ObjectFullName +
                        N' ADD client_option_1 varchar(500) NULL;';

                IF @Debug = 1 BEGIN PRINT @StringToExecute; END;
                EXECUTE sys.sp_executesql
                    @StringToExecute;

                /* If the table doesn't have the new client option column, add it. See Github #3101. */
                SET @StringToExecute =
                        N'IF NOT EXISTS (SELECT 1/0 FROM ' +
                        @OutputDatabaseName +
                        N'.sys.all_columns AS o WHERE o.object_id = (OBJECT_ID(''' +
                        @ObjectFullName +
                        N''')) AND o.name = N''client_option_2'')
                        /*Add wait_resource column*/
                        ALTER TABLE ' +
                        @ObjectFullName +
                        N' ADD client_option_2 varchar(500) NULL;';

                IF @Debug = 1 BEGIN PRINT @StringToExecute; END;
                EXECUTE sys.sp_executesql
                    @StringToExecute;

                /* If the table doesn't have the new lock mode column, add it. See Github #3101. */
                SET @StringToExecute =
                        N'IF NOT EXISTS (SELECT 1/0 FROM ' +
                        @OutputDatabaseName +
                        N'.sys.all_columns AS o WHERE o.object_id = (OBJECT_ID(''' +
                        @ObjectFullName +
                        N''')) AND o.name = N''lock_mode'')
                        /*Add wait_resource column*/
                        ALTER TABLE ' +
                        @ObjectFullName +
                        N' ADD lock_mode nvarchar(256) NULL;';

                IF @Debug = 1 BEGIN PRINT @StringToExecute; END;
                EXECUTE sys.sp_executesql
                    @StringToExecute;

                /* If the table doesn't have the new status column, add it. See Github #3101. */
                SET @StringToExecute =
                        N'IF NOT EXISTS (SELECT 1/0 FROM ' +
                        @OutputDatabaseName +
                        N'.sys.all_columns AS o WHERE o.object_id = (OBJECT_ID(''' +
                        @ObjectFullName +
                        N''')) AND o.name = N''status'')
                        /*Add wait_resource column*/
                        ALTER TABLE ' +
                        @ObjectFullName +
                        N' ADD status nvarchar(256) NULL;';

                IF @Debug = 1 BEGIN PRINT @StringToExecute; END;
                EXECUTE sys.sp_executesql
                    @StringToExecute;
            END;
            ELSE /* end if @r is not null. if it is null there is no table, create it from above execution */
            BEGIN
                SELECT
                    @StringToExecute =
                        N'USE ' +
                        @OutputDatabaseName +
                        N';
                        CREATE TABLE ' +
                        @OutputSchemaName +
                        N'.' +
                        @OutputTableName +
                        N'  (
                                ServerName nvarchar(256),
                                deadlock_type nvarchar(256),
                                event_date datetime,
                                database_name nvarchar(256),
                                spid smallint,
                                deadlock_group nvarchar(256),
                                query xml,
                                object_names xml,
                                isolation_level nvarchar(256),
                                owner_mode nvarchar(256),
                                waiter_mode nvarchar(256),
                                lock_mode nvarchar(256),
                                transaction_count bigint,
                                client_option_1 varchar(500),
                                client_option_2 varchar(500),
                                login_name nvarchar(256),
                                host_name nvarchar(256),
                                client_app nvarchar(1024),
                                wait_time bigint,
                                wait_resource nvarchar(max),
                                priority smallint,
                                log_used bigint,
                                last_tran_started datetime,
                                last_batch_started datetime,
                                last_batch_completed datetime,
                                transaction_name nvarchar(256),
                                status nvarchar(256),
                                owner_waiter_type nvarchar(256),
                                owner_activity nvarchar(256),
                                owner_waiter_activity nvarchar(256),
                                owner_merging nvarchar(256),
                                owner_spilling nvarchar(256),
                                owner_waiting_to_close nvarchar(256),
                                waiter_waiter_type nvarchar(256),
                                waiter_owner_activity nvarchar(256),
                                waiter_waiter_activity nvarchar(256),
                                waiter_merging nvarchar(256),
                                waiter_spilling nvarchar(256),
                                waiter_waiting_to_close nvarchar(256),
                                deadlock_graph xml
                            )';

                IF @Debug = 1 BEGIN PRINT @StringToExecute; END;
                EXECUTE sys.sp_executesql
                    @StringToExecute;

                /*table created.*/
                SELECT
                    @StringToExecute =
                        N'SELECT @r = o.name FROM ' +
                        @OutputDatabaseName +
                        N'.sys.objects AS o
                          WHERE o.type_desc = N''USER_TABLE''
                          AND o.name = N''BlitzLockFindings''',
                    @StringToExecuteParams =
                        N'@r sysname OUTPUT';

                IF @Debug = 1 BEGIN PRINT @StringToExecute; END;
                EXECUTE sys.sp_executesql
                    @StringToExecute,
                    @StringToExecuteParams,
                    @r OUTPUT;

                IF (@r IS NULL) /*if table does not exist*/
                BEGIN
                    SELECT
                        @OutputTableFindings =
                            QUOTENAME(N'BlitzLockFindings'),
                        @StringToExecute =
                            N'USE ' +
                            @OutputDatabaseName +
                            N';
                            CREATE TABLE ' +
                            @OutputSchemaName +
                            N'.' +
                            @OutputTableFindings +
                            N' (
                                   ServerName nvarchar(256),
                                   check_id INT,
                                   database_name nvarchar(256),
                                   object_name nvarchar(1000),
                                   finding_group nvarchar(100),
                                   finding nvarchar(4000)
                               );';

                    IF @Debug = 1 BEGIN PRINT @StringToExecute; END;
                    EXECUTE sys.sp_executesql
                        @StringToExecute;
                END;
            END;

            /*create synonym for deadlockfindings.*/
            IF EXISTS
            (
                SELECT
                    1/0
                FROM sys.objects AS o
                WHERE o.name = N'DeadlockFindings'
                AND   o.type_desc = N'SYNONYM'
            )
            BEGIN
                RAISERROR('Found synonym DeadlockFindings, dropping', 0, 1) WITH NOWAIT;
                DROP SYNONYM DeadlockFindings;
            END;

            RAISERROR('Creating synonym DeadlockFindings', 0, 1) WITH NOWAIT;
            SET @StringToExecute =
                    N'CREATE SYNONYM DeadlockFindings FOR ' +
                    @OutputDatabaseName +
                    N'.' +
                    @OutputSchemaName +
                    N'.' +
                    @OutputTableFindings;

            IF @Debug = 1 BEGIN PRINT @StringToExecute; END;
            EXECUTE sys.sp_executesql
                @StringToExecute;

            /*create synonym for deadlock table.*/
            IF EXISTS
            (
                SELECT
                    1/0
                FROM sys.objects AS o
                WHERE o.name = N'DeadLockTbl'
                AND   o.type_desc = N'SYNONYM'
            )
            BEGIN
                RAISERROR('Found synonym DeadLockTbl, dropping', 0, 1) WITH NOWAIT;
                DROP SYNONYM DeadLockTbl;
            END;

            RAISERROR('Creating synonym DeadLockTbl', 0, 1) WITH NOWAIT;
            SET @StringToExecute =
                    N'CREATE SYNONYM DeadLockTbl FOR ' +
                    @OutputDatabaseName +
                    N'.' +
                    @OutputSchemaName +
                    N'.' +
                    @OutputTableName;

            IF @Debug = 1 BEGIN PRINT @StringToExecute; END;
            EXECUTE sys.sp_executesql
                @StringToExecute;
        END;
    END;

    /* WITH ROWCOUNT doesn't work on Amazon RDS - see: https://github.com/BrentOzarULTD/SQL-Server-First-Responder-Kit/issues/2037 */
    IF @RDS = 0
    BEGIN;
        BEGIN TRY;
        RAISERROR('@RDS = 0, updating #t with high row and page counts', 0, 1) WITH NOWAIT;
            UPDATE STATISTICS
                #t
            WITH
                ROWCOUNT  = 9223372036854775807,
                PAGECOUNT = 9223372036854775807;
        END TRY
        BEGIN CATCH;
            /* Misleading error returned, if run without permissions to update statistics the error returned is "Cannot find object".
                    Catching specific error, and returning message with better info. If any other error is returned, then throw as normal */
            IF (ERROR_NUMBER() = 1088)
            BEGIN;
                SET @d = CONVERT(varchar(40), GETDATE(), 109);
                RAISERROR('Cannot run UPDATE STATISTICS on a #temp table without db_owner or sysadmin permissions', 0, 1) WITH NOWAIT;
            END;
            ELSE
            BEGIN;
                THROW;
            END;
        END CATCH;
    END;

    IF @DeadlockType IS NOT NULL
    BEGIN
        SELECT
            @DeadlockType =
                CASE
                    WHEN LOWER(@DeadlockType) LIKE 'regular%'
                    THEN N'Regular Deadlock'
                    WHEN LOWER(@DeadlockType) LIKE N'parallel%'
                    THEN N'Parallel Deadlock'
                    ELSE NULL
                END;
    END;

    /*If @TargetSessionType, we need to figure out if it's ring buffer or event file*/
    /*Azure has differently named views, so  we need to separate. Thanks, Azure.*/

    IF
    (
            @Azure = 0
        AND @TargetSessionType IS NULL
    )
    BEGIN
    RAISERROR('@TargetSessionType is NULL, assigning for non-Azure instance', 0, 1) WITH NOWAIT;

        SELECT TOP (1)
            @TargetSessionType = t.target_name
        FROM sys.dm_xe_sessions AS s
        JOIN sys.dm_xe_session_targets AS t
          ON s.address = t.event_session_address
        WHERE s.name = @EventSessionName
        AND   t.target_name IN (N'event_file', N'ring_buffer')
        ORDER BY t.target_name
        OPTION(RECOMPILE);

    RAISERROR('@TargetSessionType assigned as %s for non-Azure', 0, 1, @TargetSessionType) WITH NOWAIT;
    END;

    IF
    (
            @Azure = 1
        AND @TargetSessionType IS NULL
        AND LOWER(@TargetSessionType) <> N'table'
    )
    BEGIN
    RAISERROR('@TargetSessionType is NULL, assigning for Azure instance', 0, 1) WITH NOWAIT;

        SELECT TOP (1)
            @TargetSessionType = t.target_name
        FROM sys.dm_xe_database_sessions AS s
        JOIN sys.dm_xe_database_session_targets AS t
          ON s.address = t.event_session_address
        WHERE s.name = @EventSessionName
        AND   t.target_name IN (N'event_file', N'ring_buffer')
        ORDER BY t.target_name
        OPTION(RECOMPILE);

    RAISERROR('@TargetSessionType assigned as %s for Azure', 0, 1, @TargetSessionType) WITH NOWAIT;
    END;


    /*The system health stuff gets handled different from user extended events.*/
    /*These next sections deal with user events, dependent on target.*/

    /*If ring buffers*/
    IF
    (
           @TargetSessionType LIKE N'ring%'
       AND @EventSessionName NOT LIKE N'system_health%'
    )
    BEGIN
        IF @Azure = 0
        BEGIN
            SET @d = CONVERT(varchar(40), GETDATE(), 109);
            RAISERROR('@TargetSessionType is ring_buffer, inserting XML for non-Azure at %s', 0, 1, @d) WITH NOWAIT;

            INSERT
                #x WITH(TABLOCKX)
            (
                x
            )
            SELECT
                x = TRY_CAST(t.target_data AS xml)
            FROM sys.dm_xe_session_targets AS t
            JOIN sys.dm_xe_sessions AS s
              ON s.address = t.event_session_address
            WHERE s.name = @EventSessionName
            AND   t.target_name = N'ring_buffer'
            OPTION(RECOMPILE);

            SET @d = CONVERT(varchar(40), GETDATE(), 109);
            RAISERROR('Finished at %s', 0, 1, @d) WITH NOWAIT;
        END;

        IF @Azure = 1
        BEGIN
            SET @d = CONVERT(varchar(40), GETDATE(), 109);
            RAISERROR('@TargetSessionType is ring_buffer, inserting XML for Azure at %s', 0, 1, @d) WITH NOWAIT;

            INSERT
                #x WITH(TABLOCKX)
            (
                x
            )
            SELECT
                x = TRY_CAST(t.target_data AS xml)
            FROM sys.dm_xe_database_session_targets AS t
            JOIN sys.dm_xe_database_sessions AS s
              ON s.address = t.event_session_address
            WHERE s.name = @EventSessionName
            AND   t.target_name = N'ring_buffer'
            OPTION(RECOMPILE);

            SET @d = CONVERT(varchar(40), GETDATE(), 109);
            RAISERROR('Finished at %s', 0, 1, @d) WITH NOWAIT;
        END;
    END;


    /*If event file*/
    IF
    (
           @TargetSessionType LIKE N'event%'
       AND @EventSessionName NOT LIKE N'system_health%'
    )
    BEGIN
        IF @Azure = 0
        BEGIN
            RAISERROR('@TargetSessionType is event_file, assigning XML for non-Azure', 0, 1) WITH NOWAIT;

            SELECT
                @SessionId = t.event_session_id,
                @TargetSessionId = t.target_id
            FROM sys.server_event_session_targets AS t
            JOIN sys.server_event_sessions AS s
              ON s.event_session_id = t.event_session_id
            WHERE t.name = @TargetSessionType
            AND   s.name = @EventSessionName
            OPTION(RECOMPILE);

            /*We get the file name automatically, here*/
            RAISERROR('Assigning @FileName...', 0, 1) WITH NOWAIT;
            SELECT
                @FileName =
                    CASE
                        WHEN f.file_name LIKE N'%.xel'
                        THEN REPLACE(f.file_name, N'.xel', N'*.xel')
                        ELSE f.file_name + N'*.xel'
                    END
            FROM
            (
                SELECT
                    file_name =
                        CONVERT(nvarchar(4000), f.value)
                FROM sys.server_event_session_fields AS f
                WHERE f.event_session_id = @SessionId
                AND   f.object_id = @TargetSessionId
                AND   f.name = N'filename'
            ) AS f
            OPTION(RECOMPILE);
        END;

        IF @Azure = 1
        BEGIN
            RAISERROR('@TargetSessionType is event_file, assigning XML for Azure', 0, 1) WITH NOWAIT;
            SELECT
                @SessionId =
                    t.event_session_address,
                @TargetSessionId =
                    t.target_name
            FROM sys.dm_xe_database_session_targets t
            JOIN sys.dm_xe_database_sessions s
              ON s.address = t.event_session_address
            WHERE t.target_name = @TargetSessionType
            AND   s.name = @EventSessionName
            OPTION(RECOMPILE);

            /*We get the file name automatically, here*/
            RAISERROR('Assigning @FileName...', 0, 1) WITH NOWAIT;
            SELECT
                @FileName =
                    CASE
                        WHEN f.file_name LIKE N'%.xel'
                        THEN REPLACE(f.file_name, N'.xel', N'*.xel')
                        ELSE f.file_name + N'*.xel'
                    END
            FROM
            (
                SELECT
                    file_name =
                        CONVERT(nvarchar(4000), f.value)
                FROM sys.server_event_session_fields AS f
                WHERE f.event_session_id = @SessionId
                AND   f.object_id = @TargetSessionId
                AND   f.name = N'filename'
            ) AS f
            OPTION(RECOMPILE);
        END;

        SET @d = CONVERT(varchar(40), GETDATE(), 109);
        RAISERROR('Reading for event_file %s', 0, 1, @FileName) WITH NOWAIT;

        INSERT
            #x WITH(TABLOCKX)
        (
            x
        )
        SELECT
            x = TRY_CAST(f.event_data AS xml)
        FROM sys.fn_xe_file_target_read_file(@FileName, NULL, NULL, NULL) AS f
        LEFT JOIN #t AS t
          ON 1 = 1
        OPTION(RECOMPILE);

        SET @d = CONVERT(varchar(40), GETDATE(), 109);
        RAISERROR('Finished at %s', 0, 1, @d) WITH NOWAIT;
    END;

    /*The XML is parsed differently if it comes from the event file or ring buffer*/

    /*If ring buffers*/
    IF
    (
           @TargetSessionType LIKE N'ring%'
       AND @EventSessionName NOT LIKE N'system_health%'
    )
    BEGIN
        SET @d = CONVERT(varchar(40), GETDATE(), 109);
        RAISERROR('Inserting to #deadlock_data for ring buffer data', 0, 1) WITH NOWAIT;

        INSERT
            #deadlock_data WITH(TABLOCKX)
        (
            deadlock_xml
        )
        SELECT
            deadlock_xml =
                e.x.query(N'.')
        FROM #x AS x
        LEFT JOIN #t AS t
          ON 1 = 1
        CROSS APPLY x.x.nodes('/RingBufferTarget/event') AS e(x)
        WHERE
          (
              e.x.exist('@name[ .= "xml_deadlock_report"]') = 1
           OR e.x.exist('@name[ .= "database_xml_deadlock_report"]') = 1
           OR e.x.exist('@name[ .= "xml_deadlock_report_filtered"]') = 1
          )
        AND   e.x.exist('@timestamp[. >= sql:variable("@StartDate") and .< sql:variable("@EndDate")]') = 1
        OPTION(RECOMPILE);

        SET @d = CONVERT(varchar(40), GETDATE(), 109);
        RAISERROR('Finished at %s', 0, 1, @d) WITH NOWAIT;
    END;

    /*If event file*/
    IF
    (
           @TargetSessionType LIKE N'event_file%'
       AND @EventSessionName NOT LIKE N'system_health%'
    )
    BEGIN
        SET @d = CONVERT(varchar(40), GETDATE(), 109);
        RAISERROR('Inserting to #deadlock_data for event file data', 0, 1) WITH NOWAIT;

        IF @Debug = 1 BEGIN SET STATISTICS XML ON; END;

        INSERT
            #deadlock_data WITH(TABLOCKX)
        (
            deadlock_xml
        )
        SELECT
            deadlock_xml =
                e.x.query('.')
        FROM #x AS x
        LEFT JOIN #t AS t
          ON 1 = 1
        CROSS APPLY x.x.nodes('/event') AS e(x)
        WHERE
          (
              e.x.exist('@name[ .= "xml_deadlock_report"]') = 1
           OR e.x.exist('@name[ .= "database_xml_deadlock_report"]') = 1
           OR e.x.exist('@name[ .= "xml_deadlock_report_filtered"]') = 1
          )
        AND   e.x.exist('@timestamp[. >= sql:variable("@StartDate") and .< sql:variable("@EndDate")]') = 1
        OPTION(RECOMPILE);

        IF @Debug = 1 BEGIN SET STATISTICS XML OFF; END;

        SET @d = CONVERT(varchar(40), GETDATE(), 109);
        RAISERROR('Finished at %s', 0, 1, @d) WITH NOWAIT;
    END;

    /*This section deals with event file*/
    IF
    (
           @TargetSessionType LIKE N'event%'
       AND @EventSessionName LIKE N'system_health%'
    )
    BEGIN
        SET @d = CONVERT(varchar(40), GETDATE(), 109);
        RAISERROR('Grab the initial set of xml to parse at %s', 0, 1, @d) WITH NOWAIT;

        IF @Debug = 1 BEGIN SET STATISTICS XML ON; END;

        SELECT
            xml.deadlock_xml
        INTO #xml
        FROM
        (
            SELECT
                deadlock_xml =
                    TRY_CAST(fx.event_data AS xml)
            FROM sys.fn_xe_file_target_read_file(N'system_health*.xel', NULL, NULL, NULL) AS fx
            LEFT JOIN #t AS t
              ON 1 = 1
            WHERE fx.object_name = N'xml_deadlock_report'
        ) AS xml
        CROSS APPLY xml.deadlock_xml.nodes('/event') AS e(x)
        WHERE 1 = 1
        AND   e.x.exist('@timestamp[. >= sql:variable("@StartDate") and .< sql:variable("@EndDate")]') = 1
        OPTION(RECOMPILE);

        INSERT
            #deadlock_data WITH(TABLOCKX)
        SELECT
            deadlock_xml =
                xml.deadlock_xml
        FROM #xml AS xml
        LEFT JOIN #t AS t
          ON 1 = 1
        WHERE xml.deadlock_xml IS NOT NULL
        OPTION(RECOMPILE);

        IF @Debug = 1 BEGIN SET STATISTICS XML OFF; END;

        SET @d = CONVERT(varchar(40), GETDATE(), 109);
        RAISERROR('Finished at %s', 0, 1, @d) WITH NOWAIT;
    END;

    /* If table target */
    IF LOWER(@TargetSessionType) = N'table'
    BEGIN
        SET @d = CONVERT(varchar(40), GETDATE(), 109);
        RAISERROR('Inserting to #deadlock_data from table source %s', 0, 1, @d) WITH NOWAIT;
   
        /*
        First, we need to heck the XML structure.
        Depending on the data source, the XML could
        contain either the /event or /deadlock nodes.
        When the /event nodes are not present, there
        is no @name attribute to evaluate.
        */

        SELECT
            @extract_sql = N'
        SELECT TOP (1)
            @xe = xe.e.exist(''.''),
            @xd = xd.e.exist(''.'')
        FROM ' +
        QUOTENAME(@TargetDatabaseName) +
        N'.' +
        QUOTENAME(@TargetSchemaName) +
        N'.' +
        QUOTENAME(@TargetTableName) +
        N' AS x
        OUTER APPLY x.' +
        QUOTENAME(@TargetColumnName) +
        N'.nodes(''/event'') AS xe(e)
        OUTER APPLY x.' +
        QUOTENAME(@TargetColumnName) +
        N'.nodes(''/deadlock'') AS xd(e) 
        OPTION(RECOMPILE);
        ';

        IF @Debug = 1 BEGIN PRINT @extract_sql; END;

        EXECUTE sys.sp_executesql
            @extract_sql,
          N'
            @xe bit OUTPUT,
            @xd bit OUTPUT
           ',
           @xe OUTPUT,
           @xd OUTPUT;


        /* Build dynamic SQL to extract the XML  */  
        IF  @xe = 1
        AND @xd IS NULL
        BEGIN
            SET @extract_sql = N'
        SELECT
            deadlock_xml = ' +
            QUOTENAME(@TargetColumnName) +
            N'
        FROM ' +
        QUOTENAME(@TargetDatabaseName) +
        N'.' +
        QUOTENAME(@TargetSchemaName) +
        N'.' +
        QUOTENAME(@TargetTableName) +
        N' AS x
        LEFT JOIN #t AS t
          ON 1 = 1
        CROSS APPLY x.' +
        QUOTENAME(@TargetColumnName) +
        N'.nodes(''/event'') AS e(x)
        WHERE
          (
              e.x.exist(''@name[ .= "xml_deadlock_report"]'') = 1
           OR e.x.exist(''@name[ .= "database_xml_deadlock_report"]'') = 1
           OR e.x.exist(''@name[ .= "xml_deadlock_report_filtered"]'') = 1
          )';
        END;

        IF  @xe IS NULL
        AND @xd = 1
        BEGIN
            SET @extract_sql = N'
        SELECT
            deadlock_xml = ' +
            QUOTENAME(@TargetColumnName) +
            N'
        FROM ' +
        QUOTENAME(@TargetDatabaseName) +
        N'.' +
        QUOTENAME(@TargetSchemaName) +
        N'.' +
        QUOTENAME(@TargetTableName) +
        N' AS x
        LEFT JOIN #t AS t
          ON 1 = 1
        CROSS APPLY x.' +
        QUOTENAME(@TargetColumnName) +
        N'.nodes(''/deadlock'') AS e(x)
        WHERE 1 = 1';
        END;
       
        /* Add timestamp filtering if specified */
        IF @TargetTimestampColumnName IS NOT NULL
        BEGIN
            SET @extract_sql = @extract_sql + N'
        AND x.' + QUOTENAME(@TargetTimestampColumnName) + N' >= @StartDate
        AND x.' + QUOTENAME(@TargetTimestampColumnName) + N'  < @EndDate';
        END;
                   
        /* If no timestamp column but date filtering is needed, handle XML-based filtering when possible */
        IF  @TargetTimestampColumnName IS NULL
        AND @xe = 1
        AND @xd IS NULL
            BEGIN
                SET @extract_sql = @extract_sql + N'
        AND e.x.exist(''@timestamp[. >= sql:variable("@StartDate") and . < sql:variable("@EndDate")]'') = 1';
        END;

		/*Woof*/
		IF  @TargetTimestampColumnName IS NULL
        AND @xe IS NULL
        AND @xd = 1
            BEGIN
                SET @extract_sql = @extract_sql + N'
        AND e.x.exist(''(/deadlock/process-list/process/@lasttranstarted)[. >= sql:variable("@StartDate") and . < sql:variable("@EndDate")]'') = 1';
        END;

        SET @extract_sql += N'
        OPTION(RECOMPILE);
        ';
       
        IF @Debug = 1 BEGIN PRINT @extract_sql; END;
       
        /* Execute the dynamic SQL */
        INSERT
            #deadlock_data
        WITH
            (TABLOCKX)
        (
            deadlock_xml
        )
        EXECUTE sys.sp_executesql
            @extract_sql,
          N'
            @StartDate datetime,
            @EndDate datetime
           ',
            @StartDate,
            @EndDate;
       
        SET @d = CONVERT(varchar(40), GETDATE(), 109);
        RAISERROR('Finished at %s', 0, 1, @d) WITH NOWAIT;
    END;

        /*Parse process and input buffer xml*/
        SET @d = CONVERT(varchar(40), GETDATE(), 109);
        RAISERROR('Initial Parse process and input buffer xml %s', 0, 1, @d) WITH NOWAIT;

        SELECT
            d1.deadlock_xml,
            event_date = d1.deadlock_xml.value('(event/@timestamp)[1]', 'datetime2'),
            victim_id = d1.deadlock_xml.value('(//deadlock/victim-list/victimProcess/@id)[1]', 'nvarchar(256)'),
            is_parallel = d1.deadlock_xml.exist('//deadlock/resource-list/exchangeEvent'),
            is_parallel_batch = d1.deadlock_xml.exist('//deadlock/resource-list/SyncPoint'),
            deadlock_graph = d1.deadlock_xml.query('/event/data/value/deadlock')
        INTO #dd
        FROM #deadlock_data AS d1
        LEFT JOIN #t AS t
          ON 1 = 1
		WHERE @xe = 1
		OR    LOWER(@TargetSessionType) <> N'table'

		UNION ALL

        SELECT
            d1.deadlock_xml,
            event_date = d1.deadlock_xml.value('(/deadlock/process-list/process/@lasttranstarted)[1]', 'datetime2'),
            victim_id = d1.deadlock_xml.value('(/deadlock/victim-list/victimProcess/@id)[1]', 'nvarchar(256)'),
            is_parallel = d1.deadlock_xml.exist('/deadlock/resource-list/exchangeEvent'),
            is_parallel_batch = d1.deadlock_xml.exist('/deadlock/resource-list/SyncPoint'),
            deadlock_graph = d1.deadlock_xml.query('.')
        FROM #deadlock_data AS d1
        LEFT JOIN #t AS t
          ON 1 = 1
		WHERE @xd = 1
        OPTION(RECOMPILE);

        SET @d = CONVERT(varchar(40), GETDATE(), 109);
        RAISERROR('Finished at %s', 0, 1, @d) WITH NOWAIT;

        SET @d = CONVERT(varchar(40), GETDATE(), 109);
        RAISERROR('Final Parse process and input buffer xml %s', 0, 1, @d) WITH NOWAIT;

        SELECT
            q.event_date,
            q.victim_id,
            is_parallel =
                CONVERT(bit, q.is_parallel),
            q.deadlock_graph,
            q.id,
            q.spid,
            q.database_id,
            database_name =
                ISNULL
                (
                    DB_NAME(q.database_id),
                    N'UNKNOWN'
                ),
            q.current_database_name,
            q.priority,
            q.log_used,
            q.wait_resource,
            q.wait_time,
            q.transaction_name,
            q.last_tran_started,
            q.last_batch_started,
            q.last_batch_completed,
            q.lock_mode,
            q.status,
            q.transaction_count,
            q.client_app,
            q.host_name,
            q.login_name,
            q.isolation_level,
            client_option_1 =
                SUBSTRING
                (
                    CASE WHEN q.clientoption1 & 1 = 1 THEN ', DISABLE_DEF_CNST_CHECK' ELSE '' END +
                    CASE WHEN q.clientoption1 & 2 = 2 THEN ', IMPLICIT_TRANSACTIONS' ELSE '' END +
                    CASE WHEN q.clientoption1 & 4 = 4 THEN ', CURSOR_CLOSE_ON_COMMIT' ELSE '' END +
                    CASE WHEN q.clientoption1 & 8 = 8 THEN ', ANSI_WARNINGS' ELSE '' END +
                    CASE WHEN q.clientoption1 & 16 = 16 THEN ', ANSI_PADDING' ELSE '' END +
                    CASE WHEN q.clientoption1 & 32 = 32 THEN ', ANSI_NULLS' ELSE '' END +
                    CASE WHEN q.clientoption1 & 64 = 64 THEN ', ARITHABORT' ELSE '' END +
                    CASE WHEN q.clientoption1 & 128 = 128 THEN ', ARITHIGNORE' ELSE '' END +
                    CASE WHEN q.clientoption1 & 256 = 256 THEN ', QUOTED_IDENTIFIER' ELSE '' END +
                    CASE WHEN q.clientoption1 & 512 = 512 THEN ', NOCOUNT' ELSE '' END +
                    CASE WHEN q.clientoption1 & 1024 = 1024 THEN ', ANSI_NULL_DFLT_ON' ELSE '' END +
                    CASE WHEN q.clientoption1 & 2048 = 2048 THEN ', ANSI_NULL_DFLT_OFF' ELSE '' END +
                    CASE WHEN q.clientoption1 & 4096 = 4096 THEN ', CONCAT_NULL_YIELDS_NULL' ELSE '' END +
                    CASE WHEN q.clientoption1 & 8192 = 8192 THEN ', NUMERIC_ROUNDABORT' ELSE '' END +
                    CASE WHEN q.clientoption1 & 16384 = 16384 THEN ', XACT_ABORT' ELSE '' END,
                    3,
                    500
                ),
            client_option_2 =
                SUBSTRING
                (
                    CASE WHEN q.clientoption2 & 1024 = 1024 THEN ', DB CHAINING' ELSE '' END +
                    CASE WHEN q.clientoption2 & 2048 = 2048 THEN ', NUMERIC ROUNDABORT' ELSE '' END +
                    CASE WHEN q.clientoption2 & 4096 = 4096 THEN ', ARITHABORT' ELSE '' END +
                    CASE WHEN q.clientoption2 & 8192 = 8192 THEN ', ANSI PADDING' ELSE '' END +
                    CASE WHEN q.clientoption2 & 16384 = 16384 THEN ', ANSI NULL DEFAULT' ELSE '' END +
                    CASE WHEN q.clientoption2 & 65536 = 65536 THEN ', CONCAT NULL YIELDS NULL' ELSE '' END +
                    CASE WHEN q.clientoption2 & 131072 = 131072 THEN ', RECURSIVE TRIGGERS' ELSE '' END +
                    CASE WHEN q.clientoption2 & 1048576 = 1048576 THEN ', DEFAULT TO LOCAL CURSOR' ELSE '' END +
                    CASE WHEN q.clientoption2 & 8388608 = 8388608 THEN ', QUOTED IDENTIFIER' ELSE '' END +
                    CASE WHEN q.clientoption2 & 16777216 = 16777216 THEN ', AUTO CREATE STATISTICS' ELSE '' END +
                    CASE WHEN q.clientoption2 & 33554432 = 33554432 THEN ', CURSOR CLOSE ON COMMIT' ELSE '' END +
                    CASE WHEN q.clientoption2 & 67108864 = 67108864 THEN ', ANSI NULLS' ELSE '' END +
                    CASE WHEN q.clientoption2 & 268435456 = 268435456 THEN ', ANSI WARNINGS' ELSE '' END +
                    CASE WHEN q.clientoption2 & 536870912 = 536870912 THEN ', FULL TEXT ENABLED' ELSE '' END +
                    CASE WHEN q.clientoption2 & 1073741824 = 1073741824 THEN ', AUTO UPDATE STATISTICS' ELSE '' END +
                    CASE WHEN q.clientoption2 & 1469283328 = 1469283328 THEN ', ALL SETTABLE OPTIONS' ELSE '' END,
                    3,
                    500
                ),
            q.process_xml
        INTO #deadlock_process
        FROM
        (
            SELECT
                dd.deadlock_xml,
                event_date =
                    DATEADD
                    (
                        MINUTE,
                        DATEDIFF
                        (
                            MINUTE,
                            GETUTCDATE(),
                            SYSDATETIME()
                        ),
                        dd.event_date
                    ),
                dd.victim_id,
                is_parallel =
                    CONVERT(tinyint, dd.is_parallel) +
                    CONVERT(tinyint, dd.is_parallel_batch),
                dd.deadlock_graph,
                id = ca.dp.value('@id', 'nvarchar(256)'),
                spid = ca.dp.value('@spid', 'smallint'),
                database_id = ca.dp.value('@currentdb', 'bigint'),
                current_database_name = ca.dp.value('@currentdbname', 'nvarchar(256)'),
                priority = ca.dp.value('@priority', 'smallint'),
                log_used = ca.dp.value('@logused', 'bigint'),
                wait_resource = ca.dp.value('@waitresource', 'nvarchar(256)'),
                wait_time = ca.dp.value('@waittime', 'bigint'),
                transaction_name = ca.dp.value('@transactionname', 'nvarchar(256)'),
                last_tran_started = ca.dp.value('@lasttranstarted', 'datetime'),
                last_batch_started = ca.dp.value('@lastbatchstarted', 'datetime'),
                last_batch_completed = ca.dp.value('@lastbatchcompleted', 'datetime'),
                lock_mode = ca.dp.value('@lockMode', 'nvarchar(256)'),
                status = ca.dp.value('@status', 'nvarchar(256)'),
                transaction_count = ca.dp.value('@trancount', 'bigint'),
                client_app = ca.dp.value('@clientapp', 'nvarchar(1024)'),
                host_name = ca.dp.value('@hostname', 'nvarchar(256)'),
                login_name = ca.dp.value('@loginname', 'nvarchar(256)'),
                isolation_level = ca.dp.value('@isolationlevel', 'nvarchar(256)'),
                clientoption1 = ca.dp.value('@clientoption1', 'bigint'),
                clientoption2 = ca.dp.value('@clientoption2', 'bigint'),
                process_xml = ISNULL(ca.dp.query(N'.'), N'')
            FROM #dd AS dd
            CROSS APPLY dd.deadlock_xml.nodes('//deadlock/process-list/process') AS ca(dp)
            WHERE (ca.dp.exist('@currentdb[. = sql:variable("@DatabaseId")]') = 1 OR @DatabaseName IS NULL)
            AND   (ca.dp.exist('@clientapp[. = sql:variable("@AppName")]') = 1 OR @AppName IS NULL)
            AND   (ca.dp.exist('@hostname[. = sql:variable("@HostName")]') = 1 OR @HostName IS NULL)
            AND   (ca.dp.exist('@loginname[. = sql:variable("@LoginName")]') = 1 OR @LoginName IS NULL)
        ) AS q
        LEFT JOIN #t AS t
          ON 1 = 1
        OPTION(RECOMPILE);













        /*
        First, revert these back since we already converted the event data to local time,
        and searches will break if we use the times converted over to UTC for the event data
        */
        SELECT
            @StartDate = @StartDateOriginal,
            @EndDate = @EndDateOriginal;







INSERT INTO #james_deadlocks (
      database_name
    , deadlocks
    , start_date
    , end_date
)
SELECT
    dp.database_name
    , COUNT_BIG(DISTINCT dp.event_date) AS deadlocks
    , @StartDate AS start_date
    , @EndDAte AS end_date
FROM #deadlock_process AS dp
WHERE 1 = 1
    AND (dp.event_date >= @StartDate OR @StartDate IS NULL)
    AND (dp.event_date < @EndDate OR @EndDate IS NULL)
GROUP BY dp.database_name
ORDER BY
      COUNT_BIG(DISTINCT dp.event_date) DESC
    , dp.database_name
OPTION(RECOMPILE);









    END; /*Final End*/
GO




-- Declare variables for the loop
DECLARE
          @CurrentDate datetime
        , @StopDate datetime;

-- Initialize: Start N days ago at midnight
SET @CurrentDate = CAST(FLOOR(CAST(DATEADD(DAY, -30, GETDATE()) AS float)) AS datetime);

-- Initialize: Stop at midnight today
SET @StopDate = CAST(FLOOR(CAST(GETDATE() AS float)) AS datetime);

-- Loop through the N-day range
WHILE @CurrentDate < @StopDate
BEGIN
    DECLARE @NextDay datetime = DATEADD(DAY, 1, @CurrentDate);

    -- Execute the stored procedure for the 1-day span
    EXEC #JamesLock 
        @StartDate = @CurrentDate, 
        @EndDate = @NextDay;

    -- Increment the date by 1 day for the next iteration
    SET @CurrentDate = @NextDay;
END







SELECT
          SUM(deadlocks) AS sum_deadlocks
        , DATENAME(weekday, start_date) AS weekday_name
        , start_date
        , end_date
FROM
        #james_deadlocks
GROUP BY
          start_date
        , end_date
ORDER BY
        start_date DESC;


SELECT
          database_name
        , deadlocks
        , DATENAME(weekday, start_date) AS weekday_name
        , start_date
        , end_date
FROM
        #james_deadlocks
ORDER BY
          database_name
        , start_date DESC;








