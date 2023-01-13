

--  SELECT 'USE ' + QUOTENAME(name) + ';' FROM sys.databases ORDER BY name;




SELECT     fk.name AS fk_name,
           s1.name AS schema_name,
           t1.name AS table_name,
           c1.name AS column_name,
           s2.name AS referenced_schema,
           t2.name AS referenced_table,
           c2.name AS referenced_column,
           'ALTER TABLE [' + s1.name + '].[' + t1.name + '] DROP CONSTRAINT [' + fk.name + '];' AS drop_fk,
           'ALTER TABLE [' + s1.name + '].[' + t1.name + ']  WITH CHECK ADD CONSTRAINT [' + fk.name + '] FOREIGN KEY([' + c1.name + ']) REFERENCES [' + s2.name + '].[' + t2.name + '] ([' + c2.name + ']);' AS create_fk
FROM       sys.foreign_key_columns AS fkc
INNER JOIN sys.foreign_keys AS fk  ON fk.object_id  = fkc.constraint_object_id
INNER JOIN sys.tables  AS t1 ON t1.object_id = fkc.parent_object_id
INNER JOIN sys.schemas AS s1  ON t1.schema_id = s1.schema_id
INNER JOIN sys.columns AS c1 ON c1.column_id = fkc.parent_column_id AND c1.object_id = t1.object_id
INNER JOIN sys.tables  AS t2 ON t2.object_id = fkc.referenced_object_id
INNER JOIN sys.schemas AS s2  ON t2.schema_id = s2.schema_id
INNER JOIN sys.columns AS c2 ON c2.column_id = fkc.referenced_column_id AND c2.object_id = t2.object_id
--WHERE fk.name = N'FK_UniqueIdentifierGroupHeader_UniqueIdentifierGroupHierarchy_UniqueIdentifierGroupHeaderId'
ORDER BY   s1.name,
           t1.name,
           fk.name;

