/**************************************************************************************
*
* Author:  James Lutsey
* Date:    2017-03-31
* Purpose: Find indexes that do not follow naming standard.
*          You can choose to select or execute the rename commands using @action (line 14)
* 
**************************************************************************************/

-- select 'USE '+ quotename(name) + ';' from sys.databases order by name


-- user input
DECLARE @action            INT = 2;  -- 1 = select all indexes
                                     -- 2 = select only indexes that need to be renamed
                                     -- 3 = execute rename commands

-- other variables
DECLARE @currentIndexName  NVARCHAR(128),
        @isPrimaryKey      BIT,
        @errorMessage      VARCHAR(MAX),
        @renameCommand     NVARCHAR(MAX),
        @schemaName        NVARCHAR(128),
        @standardIndexName NVARCHAR(MAX),
        @tableName         NVARCHAR(128);

-- table variable to store index names and commands
DECLARE  @tblIndexNames TABLE
(
    [TableName]         NVARCHAR(257),
    [CurrentIndexName]  NVARCHAR(128),
    [StandardIndexName] NVARCHAR(MAX),
    [RenameCommand]     NVARCHAR(MAX)
);

-- used to loop through indexes for analysis and building rename commands.
DECLARE curIndexes CURSOR LOCAL FAST_FORWARD FOR
    SELECT     [t].[name],
               SCHEMA_NAME([t].[schema_id]),
               [i].[name],
               [i].[is_primary_key]
    FROM       [sys].[tables] AS [t]
    INNER JOIN [sys].[indexes] AS [i] ON [t].[object_id] = [i].[object_id]
    WHERE      [i].[type] != 0
               AND [t].[name] != 'sysdiagrams';

SET NOCOUNT ON;


------------------------------------------------------------------------
--// VERIFY USER INPUT                                              //--
------------------------------------------------------------------------

IF @action > 3
BEGIN
    SET @errorMessage = 'You have selected an usupported value for @action.' + CHAR(10) + 
                        'Setting NOEXEC ON - the script will compile but will not execute.';
    RAISERROR(@errorMessage,16,1);
    SET NOEXEC ON;
END


------------------------------------------------------------------------
--// LOOP THROUGH THE INDEXES                                       //--
------------------------------------------------------------------------

OPEN curIndexes;
    FETCH NEXT FROM curIndexes INTO @tableName,@schemaName,@currentIndexName,@isPrimaryKey;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- build the name to follow standard naming convention
        IF @isPrimaryKey = 1
            SET @standardIndexName = N'PK_' + @tableName;
        ELSE
        BEGIN
            SET @standardIndexName = N'IX_' + @tableName;

            -- add column names to index name
            SELECT     @standardIndexName += N'_' + [col].[name]
            FROM       [sys].[indexes] AS [ind]
            INNER JOIN [sys].[index_columns] As [ic] ON ind.object_id = ic.object_id 
	                   AND ind.index_id = ic.index_id 
            INNER JOIN sys.columns col 
	                   ON ic.object_id = col.object_id 
	                   AND ic.column_id = col.column_id 
            INNER JOIN sys.tables t 
	                   ON ind.object_id = t.object_id      
            WHERE      [t].[name] = @tableName
                       AND [ind].[name] = @currentIndexName
                       AND [ic].[is_included_column] = 0
                       AND [ind].[is_primary_key] = 0
            ORDER BY   [ic].[index_column_id];
        END

        -- build the rename command
        IF @currentIndexName = @standardIndexName
            SET @renameCommand = N'-- current index name meets standard: ' + @currentIndexName;
        ELSE
        BEGIN
            IF LEN(@standardIndexName) <= 128
            BEGIN
                SET @renameCommand = N'USE ' + QUOTENAME(DB_NAME()) + N'; ' + CHAR(10) + 
                                     N'EXECUTE sp_rename @objname = N''[' + @schemaName + N'].[' + @tableName + N'].[' + @currentIndexName + N']'', ' + CHAR(10) + 
                                     N'                  @newname = N''' + @standardIndexName + N''', ' + CHAR(10) +
                                     N'                  @objtype = N''INDEX'';' + CHAR(10);

                -- if user indcated, excute the command
                IF @action = 3 
                BEGIN
                    EXECUTE(@renameCommand);
                    PRINT @renameCommand;
                END
            END
            ELSE
                SET @renameCommand = N'-- **STANDARD NAME IS TOO LONG** - ' + CAST(LEN(@standardIndexName) AS VARCHAR(10)) + ' characters';
        END

        SET @tableName = @schemaName + N'.' + @tableName;

        -- if user indicated a select option, enter this index info into the temp table
        IF @action != 3
            INSERT INTO @tblIndexNames ([TableName],[CurrentIndexName],[StandardIndexName],[RenameCommand])
            VALUES (@tableName,@currentIndexName,@standardIndexName,@renameCommand);

        FETCH NEXT FROM curIndexes INTO @tableName,@schemaName,@currentIndexName,@isPrimaryKey;
    END
CLOSE curIndexes;
DEALLOCATE curIndexes;


------------------------------------------------------------------------
--// DISPLAY RESULTS (IF A SELECT OPTION WAS INDICATED)             //--
------------------------------------------------------------------------

IF @action = 1
    SELECT   * 
    FROM     @tblIndexNames 
    ORDER BY [StandardIndexName];
ELSE IF @action = 2
    SELECT   * 
    FROM     @tblIndexNames 
    WHERE    [CurrentIndexName] != [StandardIndexName] 
    ORDER BY [StandardIndexName];
ELSE IF @action = 3
    WAITFOR DELAY '00:00:00'; -- do nothing, this option was handled above
ELSE
BEGIN
    SET NOEXEC OFF;
    PRINT '';
    PRINT 'You have reached the end of the script - setting NOEXEC OFF so it will attempt to execute on the next run.';
END      