USE SSISDB;

/*****************************************************/
/* get rowcounts for each component					 */
/*****************************************************/
DECLARE
	@rowcountExecutionid BIGINT,
	@package			 VARCHAR(100);

SET @package = 'GSF_Integration_FromWMS_Update.dtsx';
SET @rowcountExecutionid =
	(	SELECT	MAX(execution_id)
		FROM	catalog.execution_data_statistics
		WHERE	package_name = @package);

SELECT
			package_name,
			task_name,
			source_component_name,
			SUM(rows_sent) AS [Rowcount]
FROM		SSISDB.catalog.execution_data_statistics
WHERE		execution_id = @rowcountExecutionid
GROUP BY	package_name,
			task_name,
			source_component_name,
			created_time
ORDER BY	created_time;

/*****************************************************/
/* get execution times for each phase of a component */
/*****************************************************/
DECLARE @execution_id BIGINT;

SET @execution_id =
	(	SELECT	MAX(execution_id)
		FROM	catalog.execution_component_phases
		WHERE	package_name = @package);

-- time spent per transform
SELECT
			package_name								 AS PackageName,
			subcomponent_name							 AS Transform,
			SUM(DATEDIFF(ms, start_time, end_time))		 AS ActiveTime,
			DATEDIFF(ms, MIN(start_time), MAX(end_time)) AS TotalTime
FROM		catalog.execution_component_phases
WHERE		execution_id = @execution_id
GROUP BY	package_name,
			subcomponent_name,
			execution_path
ORDER BY	ActiveTime DESC;

-- transforms per phase
SELECT
			package_name								 AS PackageName,
			task_name									 AS TaskName,
			subcomponent_name							 AS Component,
			phase,
			SUM(DATEDIFF(ms, start_time, end_time))		 AS ActiveTime,
			DATEDIFF(ms, MIN(start_time), MAX(end_time)) AS TotalTime
FROM		catalog.execution_component_phases
WHERE		execution_id = @execution_id
GROUP BY	package_name,
			subcomponent_name,
			task_name,
			phase
ORDER BY	ActiveTime DESC;
