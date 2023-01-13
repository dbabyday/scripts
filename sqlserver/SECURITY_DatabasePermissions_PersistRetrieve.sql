SET NOCOUNT ON;

-----------------------------------------------
--// EXECUTE/SELECT THE PERMISSIONS        //--
-----------------------------------------------

USE [<Database Name,NVARCHAR(128),RefreshDatabase>];

-- USER INPUT
DECLARE @action AS NVARCHAR(20) = N'PRINT'; -- PRINT, SELECT, EXECUTE

-- other variables
DECLARE @db         AS NVARCHAR(128) = DB_NAME(),
        @definition AS NVARCHAR(709),
        @msg        AS NVARCHAR(MAX),
        @sql        AS NVARCHAR(MAX) = N'';

-- execute the permissions
IF @action = N'EXECUTE'
BEGIN
    SELECT   @sql += [Definition] + NCHAR(0x000D) + NCHAR(0x000A)
    FROM     [CentralAdmin].[persist].[DatabasePermissions]
    WHERE    [DatabaseName] = @db
    ORDER BY [Id];

    EXECUTE [sys].[sp_executesql] @sql;

    SET @msg = CONVERT(NCHAR(19),GETDATE(),120) + N' | The following script was executed' + NCHAR(0x000D) + NCHAR(0x000A) +
               N'------------------------------------------------------------' + NCHAR(0x000D) + NCHAR(0x000A) + NCHAR(0x000D) + NCHAR(0x000A) +
               @sql;
    RAISERROR(@msg,0,1) WITH NOWAIT;
END;

-- print the permissions
IF @action IN (N'PRINT')
BEGIN
    DECLARE curPermissions CURSOR LOCAL FAST_FORWARD FOR
        SELECT   [Definition]
        FROM     [CentralAdmin].[persist].[DatabasePermissions]
        WHERE    [DatabaseName] = @db
        ORDER BY [Id];

    OPEN curPermissions;
        FETCH NEXT FROM curPermissions INTO @definition;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            RAISERROR(@definition,0,1) WITH NOWAIT;
            FETCH NEXT FROM curPermissions INTO @definition;
        END;
    CLOSE curPermissions;
    DEALLOCATE curPermissions;
END;

-- select the permissions
IF @action = N'SELECT'
BEGIN
    SELECT   * 
    FROM     [CentralAdmin].[persist].[DatabasePermissions]
    WHERE    [DatabaseName] = @db
    ORDER BY [Id];
END;
