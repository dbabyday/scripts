

/*

https://blog.sqlauthority.com/2019/02/21/sql-server-query-listing-all-the-indexes-key-column-with-included-column/

*/


DECLARE   -- leave blank to get all tables
	  @Schema nvarchar(128) = N'dbo'
	, @Table  nvarchar(128) = N'WOKIT';



-- dynamic sql troubleshooting options
DECLARE
	  @PrintQuery bit = 0
	, @ExecuteQuery bit = 1;







DECLARE @Query nvarchar(max) = N'
WITH
	  KeyColumns AS (
		SELECT 
			ic.object_id,
			ic.index_id,
			STRING_AGG(c.name + CASE WHEN ic.is_descending_key = 1 THEN '' desc'' ELSE '''' END, '', '') WITHIN GROUP (ORDER BY ic.key_ordinal) AS key_columns
		FROM sys.index_columns AS ic
		JOIN sys.columns AS c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
		WHERE ic.is_included_column = 0
		GROUP BY ic.object_id, ic.index_id
	  )
	, IncludedColumns AS (
		SELECT 
			ic.object_id,
			ic.index_id,
			STRING_AGG(c.name, '', '') WITHIN GROUP (ORDER BY ic.index_column_id) AS included_columns
		FROM sys.index_columns AS ic
		JOIN sys.columns AS c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
		WHERE ic.is_included_column = 1
		GROUP BY ic.object_id, ic.index_id
	  )
SELECT  /* cIndexColumns.sql */
	  db_name() AS dabase_name
	, SCHEMA_NAME(t.schema_id) + N''.'' + t.name AS table_name
	, i.name AS index_name
	, kc.key_columns
	, inc.included_columns
	, i.type_desc
	, i.is_primary_key
	, i.is_unique
	, i.is_unique_constraint
	, u.user_seeks
	, u.user_scans
	, u.user_lookups
	, u.user_updates
FROM
	sys.tables AS t
INNER JOIN
	sys.indexes AS i ON t.object_id = i.object_id
LEFT JOIN
	KeyColumns AS kc ON i.object_id = kc.object_id AND i.index_id = kc.index_id
LEFT JOIN
	IncludedColumns AS inc ON i.object_id = inc.object_id AND i.index_id = inc.index_id
LEFT JOIN
	sys.dm_db_index_usage_stats AS u 
		ON i.object_id = u.object_id 
		AND i.index_id = u.index_id 
		AND u.database_id = DB_ID()
WHERE
	t.is_ms_shipped = 0
	AND i.type <> 0';

IF @Schema <> N''
	SET @Query = @query + CHAR(13) + CHAR(10) + CHAR(9) + N'AND t.schema_id = SCHEMA_ID(@Schema)';

IF @Table <> N''
	SET @Query = @query + CHAR(13) + CHAR(10) + CHAR(9) + N'AND t.name = @Table';

SET @Query = @query + N'
ORDER BY
	  SCHEMA_NAME(t.schema_id) + N''.'' + t.name
	, kc.key_columns
	, inc.included_columns;';







IF @PrintQuery = 1
	PRINT @Query;

IF @ExecuteQuery = 1
	EXECUTE sp_executesql
		  @Query
		, N'	  @Schema nvarchar(128)
			, @Table nvarchar(128)
		  '
		, @Schema=@Schema
		, @Table=@Table;