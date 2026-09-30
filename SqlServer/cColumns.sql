/*
    cColumns.sql
    Get Table Columns & Primary Key Columns
*/



/*
SELECT 'USE ' + QUOTENAME(name) + ';' FROM sys.databases ORDER BY name;
*/



DECLARE
	  @objId  AS INT = OBJECT_ID(N'UnitSetup.UnitIdentity',N'U')
	, @showPK AS BIT = 0;







SELECT
	  c.TABLE_CATALOG AS DatabaseName
	, c.TABLE_SCHEMA AS SchemaName
	, c.TABLE_NAME AS TableName
	, c.COLUMN_NAME AS ColumnName
	, CASE
		WHEN c.DATA_TYPE IN ( N'binary', N'varbinary'                    ) THEN ( CASE c.CHARACTER_OCTET_LENGTH   WHEN -1 THEN CONCAT(c.DATA_TYPE, N'(max)') ELSE CONCAT( c.DATA_TYPE, N'(', c.CHARACTER_OCTET_LENGTH  , N')' ) END )
		WHEN c.DATA_TYPE IN ( N'char', N'varchar', N'nchar', N'nvarchar' ) THEN ( CASE c.CHARACTER_MAXIMUM_LENGTH WHEN -1 THEN CONCAT(c.DATA_TYPE, N'(max)') ELSE CONCAT( c.DATA_TYPE, N'(', c.CHARACTER_MAXIMUM_LENGTH, N')' ) END )
		WHEN c.DATA_TYPE IN ( N'datetime2', N'datetimeoffset'            ) THEN CONCAT( c.DATA_TYPE, N'(', c.DATETIME_PRECISION, N')' )
		WHEN c.DATA_TYPE IN ( N'decimal', N'numeric'                     ) THEN CONCAT( c.DATA_TYPE, N'(', c.NUMERIC_PRECISION , N',', c.NUMERIC_SCALE, N')' )
		ELSE c.DATA_TYPE
	  END AS DataType
	, CASE c.IS_NULLABLE
		WHEN 'NO'  THEN N'not null'
		WHEN 'YES' THEN     N'null'
	  END AS IsNullable
	, COLUMNPROPERTY(object_id(TABLE_SCHEMA+'.'+TABLE_NAME), COLUMN_NAME, 'IsIdentity') AS IsIdentity
	, cc.definition AS ComputedColumn
	, c.COLUMN_DEFAULT AS ColumnDefault
	, c.ORDINAL_POSITION AS OrdinalPosition
FROM
	INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN
	sys.computed_columns cc ON
		cc.object_id=OBJECT_ID(c.TABLE_SCHEMA+N'.'+c.TABLE_NAME)
		AND cc.name=c.COLUMN_NAME
WHERE
	c.TABLE_SCHEMA=OBJECT_SCHEMA_NAME(@objId)
	AND c.TABLE_NAME=OBJECT_NAME(@objId)
ORDER BY
	c.COLUMN_NAME;






/* primary key */
IF @showPK=1
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
