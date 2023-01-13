SET NOCOUNT ON;

DECLARE @tblTables TABLE 
(
    [SchemaName] VARCHAR(100),
    [TableName] VARCHAR(100)
);

DECLARE @sql        NVARCHAR(MAX),
        @drop       NVARCHAR(MAX),
        @query      NVARCHAR(MAX),
        @filter     NVARCHAR(MAX),
        @primarykey NVARCHAR(MAX),
        @table      NVARCHAR(50),
        @schema     NVARCHAR(50),
        @msg        NVARCHAR(MAX);
    
DECLARE curTables CURSOR LOCAL FAST_FORWARD FOR
    SELECT [SchemaName],[TableName]
    FROM   @tblTables;

-- populate 
INSERT INTO @tblTables ( [SchemaName], [TableName] )
SELECT          [s].[name],
                [t].[name]
FROM            [gsf2_amer_prod].[sys].[tables]     AS [t]
INNER JOIN      [gsf2_amer_prod].[sys].[schemas]    AS [s] ON [s].[schema_id] = [t].[schema_id]
LEFT OUTER JOIN [gsf2_amer_prod].[sys].[indexes]    AS [i] ON [t].[object_id] = [i].[object_id]
INNER JOIN      [gsf2_amer_prod].[sys].[partitions] AS [p] ON [i].[object_id] = [p].[object_id] AND [i].[index_id] = [p].[index_id]
WHERE           [i].[index_id] = 1
                AND [s].[name] = 'UnitSetup' 
                AND [t].[name] = 'WorkOrderHeader'
GROUP BY        [s].[name],
                [t].[name]
HAVING          SUM([p].[rows]) BETWEEN 1 AND 10000000 
ORDER BY        [s].[name],
                [t].[name];

OPEN curTables;
FETCH NEXT FROM curTables INTO @schema, @table;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @msg = CONVERT(NCHAR(19),GETDATE(),120) + N' | Updating ' +  @schema + N'.' + @table; 
        RAISERROR(@msg,0,1) WITH NOWAIT;

        SET @query = N'SELECT * FROM [GSF2_AMER_PROD].' + QUOTENAME(@schema) + N'.'  + QUOTENAME(@table) + ';' --' WHERE DateEffectiveIn > ''20180314''';

        SET @drop = N'IF OBJECT_ID(''tempdb..##' +  @schema + @table + N'Update'') IS NOT NULL' + NCHAR(0x000D) + NCHAR(0x000A) +
                    N'    DROP TABLE [##' +  @schema + @table + N'Update];';
    
        --PRINT ' ...Drop temp table'
        EXEC sp_executesql @drop

        SET @sql = N'SELECT * INTO [##' +  @schema + @table + N'Update] FROM OPENQUERY([co-db-051\OLTP01], ''' +  REPLACE(@query,'''','''''') + N''');'

        --PRINT ' ...Create temp table'
        EXEC sp_executesql @sql

        /* do not touch */
        SELECT     @primarykey = COL_NAME([ic].[object_id], [ic].[column_id])
        FROM       [sys].[indexes] AS [i]
        INNER JOIN [sys].[index_columns] AS [ic] ON [i].[object_id] = [ic].[object_id] AND [i].[index_id] = [ic].[index_id]
        WHERE      OBJECT_NAME([ic].[object_id]) = @table
                   AND [i].[is_primary_key] = 1;
        
        SET @sql = N'';

        IF @primarykey IS NULL
        BEGIN
            SET @msg = CONVERT(NCHAR(19),GETDATE(),120) + N' | PK violation ... skipping ' +  @schema + '.' + @table; 
            RAISERROR(@msg,0,1) WITH NOWAIT;
        END
        ELSE
        BEGIN
            SELECT     @sql = @sql + N'['  + [b].[name] + N'] = [src].['  + [b].[name] + N'],' + NCHAR(0x000D) + NCHAR(0x000A)
            FROM       sysobjects AS a
            INNER JOIN syscolumns AS b ON a.ID = b.ID
            INNER JOIN systypes   AS c ON b.xtype = c.xusertype
            WHERE      a.type = 'U'
                       AND a.name = @table
                       AND b.name <> @primarykey
                       AND b.xusertype NOT IN (241, 189)
                       AND b.colstat <> 1 -- we dont want the identity column
            ORDER BY   a.name,
                                    b.colid,
                                    b.name; 

                     SET @SQL = N'UPDATE [dst] SET ' + @sql

                     SET @sql = SUBSTRING(@sql,1,LEN(@sql) - 2) + CHAR(10)
                     SELECT @sql = @sql + N'FROM ' + QUOTENAME(@schema) + N'.'  + QUOTENAME(@table) + N' AS [dst]' + CHAR(10)
                     SELECT @sql = @sql + N'    JOIN [##' +  @schema + @table + N'Update] AS [src] ON [dst].'  + QUOTENAME(@primarykey) + N' = [src].'  + QUOTENAME(@primarykey) + CHAR(10)

                     SET @sql = @sql + N'WHERE [dst].'  + QUOTENAME(@primarykey) + N' = [src].'  + QUOTENAME(@primarykey) + CHAR(10)
                     --SET @sql = @sql + N'     AND [dst].'  + QUOTENAME(@filter) + N' <> [src].'  + QUOTENAME(@filter) + ';'

                     --PRINT @sql

                     EXEC sp_executesql @sql;

                     --PRINT ' ...' + CAST(@@rowcount AS varchar(100)) + ' rows updated'
                     --EXEC sp_executesql @drop
                     --PRINT  @schema + '.' + @table + ' complete'
                     --PRINT ''
              END
        
              SET @sql = N'';
              SET @query  = N'';
              SET @drop = N'';
              SET @primarykey = N'';
        FETCH NEXT FROM curTables INTO @schema,@table

    END

CLOSE curTables
DEALLOCATE curTables 
PRINT '';
PRINT 'Complete';
