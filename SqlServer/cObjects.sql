/*
SELECT 'USE ' + QUOTENAME(name) + ';' FROM sys.databases ORDER BY name;
*/





SELECT   @@servername             AS ServerName,
         DB_NAME()                    AS DbName,
         SCHEMA_NAME(o.schema_id) AS SchemaName,
         o.name                   AS ObjectName,o.type_desc,
         o.create_date,
         o.modify_date,
	 m.definition,
         CAST('<A><![CDATA[' + m.definition + ']]></A>' AS XML) AS xml_wrapper_for_long_text
FROM     sys.objects     AS o
JOIN     sys.sql_modules AS m ON o.object_id = m.object_id
WHERE    o.name IN ('usp_CertificateOperationGroupDetail_Select','') -- select name from sys.objects order by name;
	-- m.definition like '%sql_expression_dependencies%'
ORDER BY o.type_desc,SCHEMA_NAME(o.schema_id),
         o.name;

