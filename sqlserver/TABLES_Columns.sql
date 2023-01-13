/*
    TABLES_Columns.sql
    Get Table Columns & Primary Key Columns
*/



/*
SELECT 'USE ' + QUOTENAME(name) + ';' FROM sys.databases ORDER BY name;
SELECT object_id, SCHEMA_NAME(schema_id), name FROM sys.tables ORDER BY 2,3;
*/

USE Label_Integration_PROD;

DECLARE @objId  AS INT = 123456789,
        @schema AS NVARCHAR(128) = N'dbo',
        @table  AS NVARCHAR(128) = N'labels';

IF @schema <> N'' AND @table <> N''
BEGIN
    SELECT @objId = t.object_id
    FROM   sys.tables  AS t
    JOIN   sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE  s.name = @schema
           AND t.name = @table;
END;

-- table columns
SELECT   DB_NAME()                AS DatabaseName,
         SCHEMA_NAME(o.schema_id) AS SchemaName,
         OBJECT_NAME(c.object_id) AS TableName,
         c.name                   AS ColumnName,
         t.name                   AS TypeName,
         c.max_length,
         c.precision,
         c.scale,
         c.is_identity,
         c.is_nullable
         --,c.*
         --,t.*
FROM     sys.columns AS c
JOIN     sys.types   AS t ON c.user_type_id = t.user_type_id
JOIN     sys.objects AS o ON c.object_id = o.object_id
WHERE    c.object_id = @objId
ORDER BY c.column_id;



-- primary key
SELECT     SCHEMA_NAME(t.schema_id) + N'.' + t.name AS TableName,
           i.name                                   AS PkName,
           c.name                                   AS ColumnName,
           ic.is_included_column,
           i.type_desc,
           i.is_unique,
           i.is_primary_key
FROM       sys.indexes       AS i 
INNER JOIN sys.index_columns AS ic ON ic.object_id = i.object_id AND i.index_id = ic.index_id 
INNER JOIN sys.columns       AS c  ON c.object_id = ic.object_id AND ic.column_id = c.column_id 
INNER JOIN sys.tables        AS t  ON t.object_id = i.object_id 
WHERE      t.object_id = @objId
           AND i.is_primary_key = 1
ORDER BY   ic.is_included_column,
           ic.index_column_id;
