

WITH  CTE_1
AS 
(
    SELECT     OBJECT_NAME(a.Object_id) AS table_name,
               a.Name AS columnname,
               b.name AS [datatype],
               CONVERT(BIGINT, ISNULL(a.last_value, 0)) AS last_value,
               CASE WHEN b.name = 'tinyint' THEN 255
                    WHEN b.name = 'smallint' THEN 32767
                    WHEN b.name = 'int' THEN 2147483647
                    WHEN b.name = 'bigint' THEN 9223372036854775807
               END AS dt_value
    FROM       sys.identity_columns a 
    INNER JOIN sys.types AS b ON a.system_type_id = b.system_type_id
)
SELECT *,
       CONVERT(NUMERIC(18, 2), ((CONVERT(FLOAT, last_value) / CONVERT(FLOAT, dt_value)) * 100)) AS [Percent]
FROM   CTE_1  
ORDER BY [Percent] DESC;



select 2147483647 - 1933842835,
       9223372036854775807 - 1933842835;


select quotename(db_name()) + '.' + quotename(schema_name(schema_id)) + '.' + quotename(name)
from   sys.tables
where  name = 'ValuesToAdd';