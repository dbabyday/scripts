/*


    Original script by Paul Nielsen www.SQLServerBible.com March 13, 2008
    Modified by Shaun J. Stuart www.shaunjstuart.com February 27, 2013
    Modified by James Lutsey 2017-04-24


*/

SET NOCOUNT ON;

DECLARE @minCompression      FLOAT         = 0.0,
        @schemaName          NVARCHAR(128),
        @tableName           NVARCHAR(128),
        @indexId             INT,
        @partitionNumber     INT,
        @dataCompressionDesc NVARCHAR(60);

-- used to get the estimate info
DECLARE @tblEstimate TABLE
(
    [object_name]                                    NVARCHAR(128),
    [schema_name]                                    NVARCHAR(128),
    [index_id]                                       INT,
    [partition_number]                               INT,
    [size_with_current_compression_setting]          BIGINT,
    [size_with_requested_compression_setting]        BIGINT,
    [sample_size_with_current_compression_setting]   BIGINT,
    [sample_size_with_requested_compression_setting] BIGINT
);

-- store all the info to compare
DECLARE @tblCompare TABLE
(
    [SchemaName]          NVARCHAR(128),
    [TableName]           NVARCHAR(128),
    [IndexId]             INT,
    [IndexName]           NVARCHAR(128),
    [IndexType]           NVARCHAR(60),
    [PartitionNumber]     INT,
    [DataCompressionDesc] NVARCHAR(60),
    [None_Size]           INT,
    [Row_Size]            INT,
    [Page_Size]           INT,
    [Suggested]           NVARCHAR(60),
    [Command]             NVARCHAR(MAX)
);

-- cursor to loop through all the indexes
DECLARE curIndexes CURSOR LOCAL FAST_FORWARD FOR
    SELECT [SchemaName],
           [TableName],
           [IndexId],
           [PartitionNumber],
           [DataCompressionDesc]
    FROM   @tblCompare;

-- get the current info
INSERT INTO @tblCompare ([SchemaName],[TableName],[IndexId],[IndexName],[IndexType],[PartitionNumber],[DataCompressionDesc])
SELECT     [s].[name],
           [o].[name],
           [i].[index_id],
           [i].[name],
           [i].[type_desc],
           [p].[partition_number],
           [p].[data_compression_desc]
FROM       [sys].[schemas] AS [s]
INNER JOIN [sys].[objects] AS [o] ON [s].[schema_id] = [o].[schema_id]
INNER JOIN [sys].[indexes] AS [i] ON [o].[object_id] = [i].[object_id]
INNER JOIN [sys].[partitions] AS [p] ON [i].[object_id] = [p].[object_id]
                                     AND [i].[index_id] = [p].[index_id]
WHERE      [o].[type] = 'U';

-- get the compression estimates
OPEN curIndexes;
    FETCH NEXT FROM curIndexes INTO @schemaName,@tableName,@indexId,@partitionNumber,@dataCompressionDesc;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @dataCompressionDesc = 'NONE'
        BEGIN
            -- estimate row compression
            INSERT INTO @tblEstimate ([object_name],[schema_name],[index_id],[partition_number],[size_with_current_compression_setting],[size_with_requested_compression_setting],[sample_size_with_current_compression_setting],[sample_size_with_requested_compression_setting])
            EXECUTE sp_estimate_data_compression_savings @schema_name      = @schemaName,
                                                         @object_name      = @tableName,
                                                         @index_id         = NULL,
                                                         @partition_number = NULL,
                                                         @data_compression = 'ROW';
            
            UPDATE     @tblCompare
            SET        [None_Size] = [e].[size_with_current_compression_setting],
                       [Row_Size] = [e].[size_with_requested_compression_setting]
            FROM       @tblCompare AS [c]
            INNER JOIN @tblEstimate AS [e] ON [e].[schema_name] = [c].[SchemaName]
                                           AND [e].[object_name] = [c].[TableName]
                                           AND [e].[index_id] = [c].[IndexId]
                                           AND [e].[partition_number] = [c].[PartitionNumber];

            DELETE FROM @tblEstimate;
            
            -- estimate page compression
            INSERT INTO @tblEstimate ([object_name],[schema_name],[index_id],[partition_number],[size_with_current_compression_setting],[size_with_requested_compression_setting],[sample_size_with_current_compression_setting],[sample_size_with_requested_compression_setting])
            EXECUTE sp_estimate_data_compression_savings @schema_name      = @schemaName,
                                                         @object_name      = @tableName,
                                                         @index_id         = NULL,
                                                         @partition_number = NULL,
                                                         @data_compression = 'PAGE';
            
            UPDATE     @tblCompare
            SET        [Page_Size] = [e].[size_with_requested_compression_setting]
            FROM       @tblCompare AS [c]
            INNER JOIN @tblEstimate AS [e] ON [e].[schema_name] = [c].[SchemaName]
                                           AND [e].[object_name] = [c].[TableName]
                                           AND [e].[index_id] = [c].[IndexId]
                                           AND [e].[partition_number] = [c].[PartitionNumber];

            DELETE FROM @tblEstimate;
        END
        ELSE IF @dataCompressionDesc = 'ROW'
        BEGIN
            -- estimate none compression
            INSERT INTO @tblEstimate ([object_name],[schema_name],[index_id],[partition_number],[size_with_current_compression_setting],[size_with_requested_compression_setting],[sample_size_with_current_compression_setting],[sample_size_with_requested_compression_setting])
            EXECUTE sp_estimate_data_compression_savings @schema_name      = @schemaName,
                                                         @object_name      = @tableName,
                                                         @index_id         = NULL,
                                                         @partition_number = NULL,
                                                         @data_compression = 'NONE';
            
            UPDATE     @tblCompare
            SET        [Row_Size] = [e].[size_with_current_compression_setting],
                       [None_Size] = [e].[size_with_requested_compression_setting]
            FROM       @tblCompare AS [c]
            INNER JOIN @tblEstimate AS [e] ON [e].[schema_name] = [c].[SchemaName]
                                           AND [e].[object_name] = [c].[TableName]
                                           AND [e].[index_id] = [c].[IndexId]
                                           AND [e].[partition_number] = [c].[PartitionNumber];

            DELETE FROM @tblEstimate;
            
            -- estimate page compression
            INSERT INTO @tblEstimate ([object_name],[schema_name],[index_id],[partition_number],[size_with_current_compression_setting],[size_with_requested_compression_setting],[sample_size_with_current_compression_setting],[sample_size_with_requested_compression_setting])
            EXECUTE sp_estimate_data_compression_savings @schema_name      = @schemaName,
                                                         @object_name      = @tableName,
                                                         @index_id         = NULL,
                                                         @partition_number = NULL,
                                                         @data_compression = 'PAGE';
            
            UPDATE     @tblCompare
            SET        [Page_Size] = [e].[size_with_requested_compression_setting]
            FROM       @tblCompare AS [c]
            INNER JOIN @tblEstimate AS [e] ON [e].[schema_name] = [c].[SchemaName]
                                           AND [e].[object_name] = [c].[TableName]
                                           AND [e].[index_id] = [c].[IndexId]
                                           AND [e].[partition_number] = [c].[PartitionNumber];

            DELETE FROM @tblEstimate;
        END
        ELSE IF @dataCompressionDesc = 'PAGE'
        BEGIN
            -- estimate none compression
            INSERT INTO @tblEstimate ([object_name],[schema_name],[index_id],[partition_number],[size_with_current_compression_setting],[size_with_requested_compression_setting],[sample_size_with_current_compression_setting],[sample_size_with_requested_compression_setting])
            EXECUTE sp_estimate_data_compression_savings @schema_name      = @schemaName,
                                                         @object_name      = @tableName,
                                                         @index_id         = NULL,
                                                         @partition_number = NULL,
                                                         @data_compression = 'NONE';
            
            UPDATE     @tblCompare
            SET        [Page_Size] = [e].[size_with_current_compression_setting],
                       [None_Size] = [e].[size_with_requested_compression_setting]
            FROM       @tblCompare AS [c]
            INNER JOIN @tblEstimate AS [e] ON [e].[schema_name] = [c].[SchemaName]
                                           AND [e].[object_name] = [c].[TableName]
                                           AND [e].[index_id] = [c].[IndexId]
                                           AND [e].[partition_number] = [c].[PartitionNumber];

            DELETE FROM @tblEstimate;
            
            -- estimate row compression
            INSERT INTO @tblEstimate ([object_name],[schema_name],[index_id],[partition_number],[size_with_current_compression_setting],[size_with_requested_compression_setting],[sample_size_with_current_compression_setting],[sample_size_with_requested_compression_setting])
            EXECUTE sp_estimate_data_compression_savings @schema_name      = @schemaName,
                                                         @object_name      = @tableName,
                                                         @index_id         = NULL,
                                                         @partition_number = NULL,
                                                         @data_compression = 'ROW';
            
            UPDATE     @tblCompare
            SET        [Row_Size] = [e].[size_with_requested_compression_setting]
            FROM       @tblCompare AS [c]
            INNER JOIN @tblEstimate AS [e] ON [e].[schema_name] = [c].[SchemaName]
                                           AND [e].[object_name] = [c].[TableName]
                                           AND [e].[index_id] = [c].[IndexId]
                                           AND [e].[partition_number] = [c].[PartitionNumber];

            DELETE FROM @tblEstimate;
        END

        FETCH NEXT FROM curIndexes INTO @schemaName,@tableName,@indexId,@partitionNumber,@dataCompressionDesc;
    END
CLOSE curIndexes;
DEALLOCATE curIndexes;

-- determine suggested compression
-- below minimum compression savings
UPDATE @tblCompare
SET    [Suggested] = 'NONE'
WHERE  [None_Size] > 0
       AND [Row_Size] < [Page_Size]
       AND (1 - (CAST([Row_Size] AS FLOAT) / [None_Size])) < @minCompression;
       
UPDATE @tblCompare
SET    [Suggested] = 'NONE'
WHERE  [None_Size] > 0
       AND [Page_Size] <= [Row_Size]
       AND (1 - (CAST([Page_Size] AS FLOAT) / [None_Size])) < @minCompression;

-- empty objects
UPDATE @tblCompare
SET    [Suggested] = 'NONE'
WHERE  [None_Size] = 0;

-- best compression with row
UPDATE @tblCompare
SET    [Suggested] = 'ROW'
WHERE  [None_Size] > 0
       AND [Row_Size] < [Page_Size]
       AND (1 - (CAST([Row_Size] AS FLOAT) / [None_Size])) >= @minCompression;

-- best compression with page
UPDATE @tblCompare
SET    [Suggested] = 'PAGE'
WHERE  [None_Size] > 0
       AND [Page_Size] <= [Row_Size]
       AND (1 - (CAST([Page_Size] AS FLOAT) / [None_Size])) >= @minCompression;

-- create the commands
UPDATE @tblCompare
SET    [Command] = N'-- compression is currently at the suggested type'
WHERE  [DataCompressionDesc] = [Suggested];

UPDATE @tblCompare
SET    [Command] = N'ALTER TABLE ' + QUOTENAME([SchemaName]) + N'.' + QUOTENAME([TableName]) + N' REBUILD WITH (DATA_COMPRESSION = NONE, ONLINE = ON, SORT_IN_TEMPDB = ON);'
WHERE  [DataCompressionDesc] != [Suggested]
       AND [Suggested] = 'NONE'
       AND [IndexType] IN ('HEAP','CLUSTERED');
       
UPDATE @tblCompare
SET    [Command] = N'ALTER INDEX ' + QUOTENAME([IndexName]) + N' ON ' + QUOTENAME([SchemaName]) + N'.' + QUOTENAME([TableName]) + N' REBUILD WITH (DATA_COMPRESSION = NONE, ONLINE = ON, SORT_IN_TEMPDB = ON);'
WHERE  [DataCompressionDesc] != [Suggested]
       AND [Suggested] = 'NONE'
       AND [IndexType] = 'NONCLUSTERED';
       
UPDATE @tblCompare
SET    [Command] = N'ALTER TABLE ' + QUOTENAME([SchemaName]) + N'.' + QUOTENAME([TableName]) + N' REBUILD WITH (DATA_COMPRESSION = ROW, ONLINE = ON, SORT_IN_TEMPDB = ON);'
WHERE  [DataCompressionDesc] != [Suggested]
       AND [Suggested] = 'ROW'
       AND [IndexType] IN ('HEAP','CLUSTERED');
       
UPDATE @tblCompare
SET    [Command] = N'ALTER INDEX ' + QUOTENAME([IndexName]) + N' ON ' + QUOTENAME([SchemaName]) + N'.' + QUOTENAME([TableName]) + N' REBUILD WITH (DATA_COMPRESSION = ROW, ONLINE = ON, SORT_IN_TEMPDB = ON);'
WHERE  [DataCompressionDesc] != [Suggested]
       AND [Suggested] = 'ROW'
       AND [IndexType] = 'NONCLUSTERED';
       
UPDATE @tblCompare
SET    [Command] = N'ALTER TABLE ' + QUOTENAME([SchemaName]) + N'.' + QUOTENAME([TableName]) + N' REBUILD WITH (DATA_COMPRESSION = PAGE, ONLINE = ON, SORT_IN_TEMPDB = ON);'
WHERE  [DataCompressionDesc] != [Suggested]
       AND [Suggested] = 'PAGE'
       AND [IndexType] IN ('HEAP','CLUSTERED');
       
UPDATE @tblCompare
SET    [Command] = N'ALTER INDEX ' + QUOTENAME([IndexName]) + N' ON ' + QUOTENAME([SchemaName]) + N'.' + QUOTENAME([TableName]) + N' REBUILD WITH (DATA_COMPRESSION = PAGE, ONLINE = ON, SORT_IN_TEMPDB = ON);'
WHERE  [DataCompressionDesc] != [Suggested]
       AND [Suggested] = 'PAGE'
       AND [IndexType] = 'NONCLUSTERED';


SELECT   * 
FROM     @tblCompare
WHERE    [Command] != '-- compression is currently at the suggested type'
ORDER BY [SchemaName],
         [TableName],
         [IndexType],
         [IndexName];