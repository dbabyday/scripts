USE MaxDb;

-- table compression
SELECT     s.name AS SchemaName
         , t.name AS TableName
         , p.partition_number
         , p.data_compression_desc
FROM       sys.partitions AS p
INNER JOIN sys.tables     AS t ON t.object_id = p.object_id
INNER JOIN sys.schemas    AS s ON s.schema_id = t.schema_id
WHERE      p.index_id IN (0,1)
ORDER BY   s.name
         , t.name;

-- index compression
SELECT     t.name AS TableName
         , i.name AS IndexName  
         , p.partition_number
         , p.data_compression_desc
FROM       sys.partitions AS p
INNER JOIN sys.tables     AS t ON t.object_id = p.object_id
INNER JOIN sys.indexes    AS i ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.schemas    AS s ON s.schema_id = t.schema_id
WHERE      p.index_id > 1
ORDER BY   s.name
         , t.name
         , i.name;

