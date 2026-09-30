USE master;
GO
CREATE OR ALTER PROCEDURE dbo.sp_cColumns
	  @tblName nvarchar(257)
AS

	DECLARE
		  @objId int
		, @db sysname = db_name()
		, @sqlString nvarchar(4000)
		, @schemaName sysname;



	/* temp table to hold objects we will use in the cursor
	   in case there are multple schemas that have the same table name */
	CREATE TABLE #schemas (schema_name sysname, object_id int);

	SET @sqlString = N'
USE [' + @db + N'];
IF @tblName LIKE ''_%._%''
BEGIN
	INSERT INTO #schemas /*dbo.sp_cColumns*/ (schema_name, object_id)
	SELECT object_schema_name(object_id), object_id
	FROM   sys.tables
	WHERE  object_id = OBJECT_ID(@tblName);
END
ELSE
BEGIN
	INSERT INTO #schemas /*dbo.sp_cColumns*/ (schema_name, object_id)
	SELECT object_schema_name(object_id), object_id
	FROM   sys.tables
	WHERE  name = @tblName;
END;';

	EXECUTE sp_executesql
		  @sqlString
		, N'@tblName nvarchar(257)'
		, @tblName=@tblName;





	/* query to get column info */
	SET @sqlString = N'
USE [' + @db + N'];
SELECT /*dbo.sp_cColumns*/
	  c.TABLE_CATALOG AS DatabaseName
	, c.TABLE_SCHEMA AS SchemaName
	, c.TABLE_NAME AS TableName
	, c.COLUMN_NAME AS ColumnName
	, CASE
		WHEN c.DATA_TYPE IN ( N''binary'', N''varbinary''                    ) THEN ( CASE c.CHARACTER_OCTET_LENGTH   WHEN -1 THEN CONCAT(c.DATA_TYPE, N''(max)'') ELSE CONCAT( c.DATA_TYPE, N''('', c.CHARACTER_OCTET_LENGTH  , N'')'' ) END )
		WHEN c.DATA_TYPE IN ( N''char'', N''varchar'', N''nchar'', N''nvarchar'' ) THEN ( CASE c.CHARACTER_MAXIMUM_LENGTH WHEN -1 THEN CONCAT(c.DATA_TYPE, N''(max)'') ELSE CONCAT( c.DATA_TYPE, N''('', c.CHARACTER_MAXIMUM_LENGTH, N'')'' ) END )
		WHEN c.DATA_TYPE IN ( N''datetime2'', N''datetimeoffset''            ) THEN CONCAT( c.DATA_TYPE, N''('', c.DATETIME_PRECISION, N'')'' )
		WHEN c.DATA_TYPE IN ( N''decimal'', N''numeric''                     ) THEN CONCAT( c.DATA_TYPE, N''('', c.NUMERIC_PRECISION , N'','', c.NUMERIC_SCALE, N'')'' )
		ELSE c.DATA_TYPE
	  END AS DataType
	, CASE c.IS_NULLABLE
		WHEN ''NO''  THEN ''not null''
		WHEN ''YES'' THEN     ''null''
		END AS IsNullable
	, COLUMNPROPERTY(object_id(TABLE_SCHEMA+''.''+TABLE_NAME), COLUMN_NAME, ''IsIdentity'') AS IsIdentity
	, cc.definition AS ComputedColumn
	, c.COLUMN_DEFAULT AS ColumnDefault
	, c.ORDINAL_POSITION AS OrdinalPosition
FROM
	INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN
	sys.computed_columns cc ON
		cc.object_id=OBJECT_ID(c.TABLE_SCHEMA+N''.''+c.TABLE_NAME)
		AND cc.name=c.COLUMN_NAME
WHERE
	c.TABLE_SCHEMA=OBJECT_SCHEMA_NAME(@objId)
	AND c.TABLE_NAME=OBJECT_NAME(@objId)
ORDER BY
	c.COLUMN_NAME;

SELECT 
	  OBJECT_SCHEMA_NAME(i.object_id) + ''.'' + OBJECT_NAME(i.object_id) AS TableName
	, i.name AS IndexName
	, c.name AS PK_Column
	, ic.key_ordinal AS ColumnOrder
FROM
	sys.indexes AS i
INNER JOIN
	sys.index_columns AS ic ON 
		i.object_id = ic.object_id 
		AND i.index_id = ic.index_id
INNER JOIN
	sys.columns AS c ON
		ic.object_id = c.object_id 
		AND ic.column_id = c.column_id
WHERE
	i.is_primary_key = 1
	AND i.object_id = @objId
ORDER BY
	ic.key_ordinal;

';



	/* run the query for each object_id
	   in case there are multple schemas that have the same table name */
	DECLARE cur_Tables CURSOR LOCAL FAST_FORWARD FOR
		SELECT   schema_name, object_id
		FROM     #schemas
		ORDER BY schema_name;

	OPEN cur_Tables;
		FETCH NEXT FROM cur_Tables INTO @schemaName, @objId;

		WHILE @@fetch_status = 0
		BEGIN
			EXECUTE sp_executesql
				  @sqlString
				, N'@objId int'
				, @objId=@objId;

			FETCH NEXT FROM cur_Tables INTO @schemaName, @objId;
		END;
	CLOSE cur_Tables;
	DEALLOCATE cur_Tables;




	/* clean up */
	DROP TABLE IF EXISTS #schemas;
GO