-- Object Info

--  SELECT 'USE ' + QUOTENAME(name) + ';' FROM sys.databases ORDER BY name;



SELECT   @@servername             AS ServerName,
         DB_NAME()                    AS DbName,
         SCHEMA_NAME(o.schema_id) AS SchemaName,
         o.name                   AS ObjectName,o.type_desc,
         o.create_date,
         o.modify_date,
         --CAST(   '<A><![CDATA[' + 
                 REPLACE(REPLACE(REPLACE(REPLACE(m.definition,N'CREATE PROCEDURE',N'ALTER PROCEDURE'),N'CREATE FUNCTION',N'ALTER FUNCTION'),N'CREATE VIEW',N'ALTER VIEW'),N'CREATE  PROCEDURE',N'ALTER PROCEDURE') + NCHAR(0x000D) + NCHAR(0x000A) + N'GO'
                 --+ ']]></A>' AS XML) AS definition
FROM     sys.objects     AS o
JOIN     sys.sql_modules AS m ON o.object_id = m.object_id
--WHERE    o.name IN ('','') -- select name from sys.objects order by name;
ORDER BY o.type_desc,SCHEMA_NAME(o.schema_id),
         o.name;

