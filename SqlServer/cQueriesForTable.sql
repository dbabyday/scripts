


DECLARE
	  @schema_name nvarchar(128) = N'dbo'
	, @table_name nvarchar(128) = N'KitHold';





DECLARE @target_table NVARCHAR(257) = @schema_name + N'.' + @table_name;


DROP TABLE IF EXISTS #Views;
CREATE TABLE #Views (
	  view_schema varchar(128)
	, view_name varchar(128)
	, dependency_path varchar(1000)
);



WITH ViewDependencies AS (
	-- Anchor Member: Find the direct views referencing the base table
	SELECT 
		  sed.referencing_id
		, OBJECT_SCHEMA_NAME(sed.referencing_id) AS view_schema
		, OBJECT_NAME(sed.referencing_id) AS view_name
		, 1 AS dependency_level
		, CAST(OBJECT_SCHEMA_NAME(sed.referencing_id) + '.' + OBJECT_NAME(sed.referencing_id) AS NVARCHAR(MAX)) AS dependency_path
	FROM
		sys.sql_expression_dependencies sed
	INNER JOIN
		sys.views v ON sed.referencing_id = v.object_id
	WHERE
		sed.referenced_id = OBJECT_ID(@target_table)
	UNION ALL
	-- Recursive Member: Find views that reference the views found in the previous step
	SELECT 
		  sed.referencing_id
		, OBJECT_SCHEMA_NAME(sed.referencing_id) AS view_schema
		, OBJECT_NAME(sed.referencing_id) AS view_name
		, vd.dependency_level + 1 AS dependency_level
		, CAST(vd.dependency_path + ' -> ' + OBJECT_SCHEMA_NAME(sed.referencing_id) + '.' + OBJECT_NAME(sed.referencing_id) AS NVARCHAR(MAX)) AS dependency_path
	FROM
		sys.sql_expression_dependencies sed
	INNER JOIN
		sys.views v ON sed.referencing_id = v.object_id
	INNER JOIN
		ViewDependencies vd ON sed.referenced_id = vd.referencing_id
)
-- Select the distinct list of views and their paths
INSERT INTO #Views (
	  view_schema
	, view_name
	, dependency_path
)
SELECT DISTINCT
	  view_schema
	, view_name
	, STRING_AGG(dependency_path, '    |    ') AS dependency_path
FROM
	ViewDependencies
GROUP BY 
	  view_schema
	, view_name;




-- show the table name
SELECT @target_table AS TargetTable;

-- show the views
SELECT
	  view_schema
	, view_name
	, dependency_path
FROM
	#Views
ORDER BY
	  view_schema
	, view_name;
		




DECLARE @SQL nvarchar(max) = N'
SELECT TOP 50
	q.query_id
	, qt.query_sql_text AS query_text
	, SUM(rs.count_executions) AS total_executions
	, OBJECT_NAME(q.object_id) AS parent_object_name
	, MAX(rs.last_execution_time) AS last_execution_time
	, SUM(rs.count_executions * rs.avg_duration) / SUM(rs.count_executions) / 1000.0 AS avg_duration_ms
	, SUM(rs.count_executions * rs.avg_cpu_time) / SUM(rs.count_executions) / 1000.0 AS avg_cpu_time_ms
FROM
	sys.query_store_query q
INNER JOIN
	sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
INNER JOIN
	sys.query_store_plan p ON q.query_id = p.query_id
INNER JOIN
	sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
WHERE 
	(
		qt.query_sql_text LIKE ''%' + @table_name + N'%''';




IF EXISTS (SELECT 1 FROM #Views)
BEGIN
		SET @SQL = @SQL + N'
		OR qt.query_sql_text LIKE ''%';

		SELECT @SQL = @SQL + STRING_AGG(view_name, '%''
		OR qt.query_sql_text LIKE ''%')
		FROM #Views;
		
		SET @SQL = @SQL + N'%''';
END




SET @SQL = @SQL + N'
	)
	AND qt.query_sql_text NOT LIKE ''%sys.query_store%''
GROUP BY 
	  q.query_id
	, qt.query_sql_text
	, q.object_id
ORDER BY 
	total_executions DESC;';






--PRINT @SQL
EXECUTE sp_executesql @SQL;


