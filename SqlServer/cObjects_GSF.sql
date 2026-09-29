

/* user input */
DECLARE @objectName NVARCHAR(128) = N'vw_Family';




/* other variables */
DECLARE
	  @dbName NVARCHAR(128)
	, @sqlStmt NVARCHAR(4000);




/* verify connection */
IF @@SERVERNAME NOT IN (N'ACC-SQL-PD-001', N'GCC-SQL-PD-023\OLTP01', N'XIA-SQL-PD-011\OLTP01')
BEGIN
	RAISERROR(N'This script is designed to only look in GSF transactional databases on ACC-SQL-PD-001, GCC-SQL-PD-023\OLTP01, and XIA-SQL-PD-011\OLTP01. Check your connection or use cObjects.sql.',16,1);
	RETURN;
END;






SELECT @dbName =
	CASE @@SERVERNAME
		WHEN N'ACC-SQL-PD-001' THEN N'GSF2_APAC_PROD'
		WHEN N'GCC-SQL-PD-023\OLTP01' THEN N'GSF2_AMER_PROD'
		WHEN N'XIA-SQL-PD-011\OLTP01' THEN N'GSF2_XIAM_PROD'
	END;

SET @sqlStmt = N'
SELECT   @@servername AS ServerName,
         ''' + @dbName + N''' AS DbName,
         SCHEMA_NAME(o.schema_id) AS SchemaName,
         o.name AS ObjectName,
	 o.type_desc,
         o.create_date,
         o.modify_date,
	 m.definition,
         CAST(''<A><![CDATA['' + m.definition + '']]></A>'' AS XML) AS xml_wrapper_for_long_text
FROM     ' + @dbName + N'.sys.objects     AS o
JOIN     ' + @dbName + N'.sys.sql_modules AS m ON o.object_id = m.object_id
WHERE    o.name = @objectName
ORDER BY o.type_desc,SCHEMA_NAME(o.schema_id),
         o.name';


EXECUTE sp_executesql
	  @sqlStmt
	, N'@objectName NVARCHAR(128)'
	, @objectName=@objectName;

