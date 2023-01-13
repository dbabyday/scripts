/******************************************************************************************
* 
* DATABASE_TablesAndColumns.sql
* 
* Author: James Lutsey
* Date:   12/04/2015
* 
* Purpose: Get the notification level and email address(s)
* 
******************************************************************************************/

USE [];
GO

SELECT 
    t.name AS [table_name],
    SCHEMA_NAME(schema_id) AS [schema_name],
    c.name AS [column_name]
FROM 
    sys.tables AS t
INNER JOIN
    sys.columns AS c
    ON t.object_id = c.object_id
--WHERE
--    t.name = ''