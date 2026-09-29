/*
Use query text to get query_id to put in Query Store GUI: Tracked Queries
From there you can see the plans, and details about their executions.
*/



SELECT 
	  q.query_id
	, q.last_execution_time AT TIME ZONE 'Central Standard Time' AS last_execution_time /* 'Singapore Standard Time' */
	, t.query_sql_text
	, OBJECT_SCHEMA_NAME(q.object_id) + N'.' + OBJECT_NAME(q.object_id) AS ObjectName
FROM
	sys.query_store_query q
INNER JOIN
	sys.query_store_query_text t ON q.query_text_id = t.query_text_id
WHERE
    t.query_sql_text LIKE '%XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX%'
    AND t.query_sql_text NOT LIKE '%query_store_query%';




/* get all queries for a specified stored procedure */
DECLARE
	  @SchemaName NVARCHAR(128) = N'dbo'
	, @ProcName   NVARCHAR(128) = N'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';

SELECT 
	  q.query_id
	, q.last_execution_time AT TIME ZONE 'Central Standard Time' AS last_execution_time /* 'Singapore Standard Time' */
	, t.query_sql_text
FROM
	sys.query_store_query q
INNER JOIN
	sys.query_store_query_text t ON q.query_text_id = t.query_text_id
INNER JOIN
	sys.procedures p ON p.object_id=q.object_id
WHERE
    p.schema_id=SCHEMA_ID(@SchemaName)
    AND p.name=@ProcName;



