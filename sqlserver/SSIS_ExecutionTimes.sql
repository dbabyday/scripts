USE SSISDB;
 

SELECT   ex.execution_id
       , ex.project_name
       , e.executable_id
       , e.executable_name
       , e.package_name
       , e.package_path
       , CONVERT(DATETIME, es.start_time) AS start_time
       , CONVERT(DATETIME, es.end_time) AS end_time
       --, CONVERT(VARCHAR, DATEADD(ms, es.execution_duration, 0), 108) AS 'duration_h:m:s'
       , es.execution_duration/1000/60 AS 'duration_minutes'
       , es.execution_result
       , CASE es.execution_result
              WHEN 0 THEN 'Success'
              WHEN 1 THEN 'Failure'
              WHEN 2 THEN 'Completion'
              WHEN 3 THEN 'Cancelled'
         END AS execution_result_description
       , es.execution_path
FROM     catalog.executions ex (NOLOCK)
         JOIN catalog.executables e (NOLOCK) ON ex.execution_id = e.execution_id
         JOIN catalog.executable_statistics es (NOLOCK) ON e.executable_id = es.executable_id AND e.execution_id = es.execution_id
WHERE    ex.project_name=N'Kinaxis'
         and e.executable_name=N'Execute PurchaseOrder_JDE_RR'
   --      and CONVERT(DATETIME, es.start_time)>'2022-03-08 00:00:00'
	  --and CONVERT(DATETIME, es.end_time)<'2022-03-09 00:00:00'
	  -- and es.execution_duration>1000*60
ORDER BY es.start_time;
--ORDER BY es.execution_duration desc;