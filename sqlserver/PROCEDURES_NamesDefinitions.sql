
USE [];

SELECT 
    --[p].[name],
    [m].[definition]
FROM 
    [sys].[procedures] AS [p]
INNER JOIN 
    [sys].[sql_modules] AS [m] 
    ON [p].[object_id] = [m].[object_id]
--WHERE 
--    [p].[name] = ''
ORDER BY 
    [name];