USE msdb;

SELECT   DB_NAME(database_id) AS database_name
       , OBJECT_NAME(object_id) AS obj_name
       , (total_worker_time / execution_count) AS ave_worker_time
       , last_worker_time
       , execution_count
       , CAST(CAST(last_worker_time AS DECIMAL(12,1)) / (total_worker_time / execution_count) AS DECIMAL(13,2)) AS pct_last_to_ave_worker_time
       --, *
FROM     sys.dm_exec_procedure_stats
WHERE    database_id = DB_ID(DB_NAME())
ORDER BY 6 DESC;

