--Modified from http://blogs.msdn.com/sqlserverstorageengine/archive/2009/01/12/tempdb-monitoring-and-troubleshooting-out-of-space.aspx

SELECT    [u].[session_id],
          [u].[request_id],
          CAST(([u].[task_alloc_pages]   * 8./1024./1024.) as NUMERIC(10,1))         AS [task_alloc_GB],
          CAST(([u].[task_dealloc_pages] * 8./1024./1024.) as NUMERIC(10,1))         AS [task_dealloc_GB],
          CASE 
              WHEN [u].[session_id] <= 50 THEN 'SYS' 
              ELSE [s].[host_name] 
          END                                                                         AS [host],
          [s].[login_name],
          [s].[status],
          [s].[last_request_start_time],
          [s].[last_request_end_time],
          [s].[row_count],
          [s].[transaction_isolation_level],
          COALESCE
          (
              (
                  SELECT SUBSTRING
                         (
                             [text], 
                             [e].[statement_start_offset] / 2 + 1,
                             (
                                 CASE 
                                     WHEN [statement_end_offset] = -1 THEN LEN(CONVERT(NVARCHAR(MAX),[text])) * 2
                                     ELSE [statement_end_offset]
                                 END - [e].[statement_start_offset]
                             ) / 2
                         )
                  FROM   [sys].[dm_exec_sql_text]([e].[sql_handle])
              ), 
              'Not currently executing'
          )                                                                           AS [query_text],
          ( SELECT [query_plan] FROM [sys].[dm_exec_query_plan]([e].[plan_handle]) ) AS [query_plan]
FROM      (
              SELECT   [session_id], 
                       [request_id],
                       SUM([internal_objects_alloc_page_count]   + [user_objects_alloc_page_count])   AS [task_alloc_pages],
                       SUM([internal_objects_dealloc_page_count] + [user_objects_dealloc_page_count]) AS [task_dealloc_pages]
              FROM     [sys].[dm_db_task_space_usage]
              GROUP BY [session_id], 
                       [request_id]
          ) AS [u]
LEFT JOIN [sys].[dm_exec_requests] AS [e] ON  [u].[session_id] = [e].[session_id]
                                          AND [u].[request_id] = [e].[request_id]
LEFT JOIN [sys].[dm_exec_sessions] AS [s] ON  [u].[session_id] = [s].[session_id]
WHERE     [u].[session_id] > 50 -- ignore system unless you suspect there's a problem there
          AND [u].[session_id] <> @@SPID -- ignore this request itself
ORDER BY  [u].[task_alloc_pages] DESC;

GO