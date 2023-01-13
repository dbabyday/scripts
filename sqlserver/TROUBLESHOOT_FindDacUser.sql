-- Find out who is using the DAC

SELECT CASE
           WHEN [s].[session_id]= @@SPID THEN 'It''s me! - '
           ELSE '' 
       END 
       + COALESCE([s].[login_name],'???') AS [WhosGotTheDAC],
       [s].[session_id],
       [s].[login_time],
       [s].[status],
       [s].[original_login_name]
FROM   [sys].[endpoints] AS [e]
JOIN   [sys].[dm_exec_sessions] AS [s] ON [e].[endpoint_id] = [s].[endpoint_id]
WHERE  [e].[name] = 'Dedicated Admin Connection';