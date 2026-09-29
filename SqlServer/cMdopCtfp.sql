





/* set the group size when viewing the number of statements in a cost range */
DECLARE @cost_group_size int = 25;









EXECUTE sp_RaiserrorTime @p_msg_str=N'Getting current values';
SELECT
	  'Current Values' AS description
	, name
	, value
FROM
	sys.configurations
WHERE
	name IN (N'cost threshold for parallelism',N'max degree of parallelism')
ORDER BY
	name DESC;



EXECUTE sp_RaiserrorTime @p_msg_str=N'checking if server is single or multiple numa nodes, and number of logical processors';
SELECT
	  'Checking NUMA Nodes' AS description
	, @@version AS sql_server_version
	, node_id
	, node_state_desc
	, cpu_count
FROM
	sys.dm_os_nodes
WHERE
	node_id < 64; -- Exclude the DAC node (node 64)



EXECUTE sp_RaiserrorTime @p_msg_str=N'Reference of Microsoft MAXDOP guidance';
SELECT
	  'MAXDOP Guidance' AS description
	, sql_server_version
	, server_configuration
	, number_of_processors
	, guidance
	, more_info
FROM
	( VALUES
		  ('2016+', 'Server with single NUMA node', '<= 8 logical processor', 'Keep MAXDOP at or under the # of logical processors', 'https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-max-degree-of-parallelism-server-configuration-option')
		, ('2016+', 'Server with single NUMA node', '> 8 logical processor', 'Keep MAXDOP at 8', 'https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-max-degree-of-parallelism-server-configuration-option')
		, ('2016+', 'Server with multiple NUMA nodes', '<= 16 logical processors per NUMA node', 'Keep MAXDOP at or under the # of logical processors per NUMA node', 'https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-max-degree-of-parallelism-server-configuration-option')
		, ('2016+', 'Server with multiple NUMA nodes', '> 16 logical processors per NUMA node', 'Keep MAXDOP at half the number of logical processors per NUMA node with a MAX value of 16', 'https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-max-degree-of-parallelism-server-configuration-option')
		, ('2014-', 'Server with single NUMA node', '<= 8 logical processor', 'Keep MAXDOP at or under the # of logical processors', 'https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-max-degree-of-parallelism-server-configuration-option')
		, ('2014-', 'Server with single NUMA node', '> 8 logical processor', 'Keep MAXDOP at 8', 'https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-max-degree-of-parallelism-server-configuration-option')
		, ('2014-', 'Server with multiple NUMA nodes', '<= 8 logical processors per NUMA node', 'Keep MAXDOP at or under the # of logical processors per NUMA node', 'https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-max-degree-of-parallelism-server-configuration-option')
		, ('2014-', 'Server with multiple NUMA nodes', '> 8 logical processors per NUMA node', 'Keep MAXDOP at 8', 'https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-max-degree-of-parallelism-server-configuration-option')
	) AS maxdop_guidance (sql_server_version, server_configuration, number_of_processors, guidance, more_info);





/*
Determining a setting for Cost Threshold for Parallelism
https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Parallelism/Determining%20a%20setting%20for%20Cost%20Threshold%20for%20Parallelism.sql
Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
This script uses another method to attempt to calculate an appropriate value for Cost Threshold for Parallelism
From http://sqlknowitall.com/determining-a-setting-for-cost-threshold-for-parallelism/

"So what do I do with these numbers? In my case, I am trying to get “about” 50% of the queries below the threshold and 50% above.
This way, I split the amount of queries using parallelism. This is not going to guarantee me the best performance, but I figured 
it was the best objective way to come up with a good starting point.

If all of my statistics are very close, I just set the Cost Threshold for Parallelism equal to about what that number is. 
An average of the 3 and round will work. In many of my cases, this was between 25 and 30.
IF the numbers are different, i.e. a few very large costs skew the average up but the median and mode are close, then I will use something
between the median and mode."
*/


/**************************************/
/* get the data                       */
/**************************************/

DROP TABLE IF EXISTS #subtree_cost;
CREATE TABLE #subtree_cost (
	statement_subtree_cost DECIMAL(18, 2)
);




EXECUTE sp_RaiserrorTime @p_msg_str=N'Getting current parallel statement cost data';
WITH
	XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
INSERT INTO
	#subtree_cost (statement_subtree_cost)
SELECT
	CAST(n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)') AS DECIMAL(18, 2))
FROM
	sys.dm_exec_cached_plans AS cp
CROSS APPLY
	sys.dm_exec_query_plan(plan_handle) AS qp
CROSS APPLY
	query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS qn(n)
WHERE
	n.query('.').exist('//RelOp[@PhysicalOp="Parallelism"]') = 1;






/**************************************/
/* measures of central tendancy       */
/**************************************/

DROP TABLE IF EXISTS #central_tendancy;
CREATE TABLE #central_tendancy (
	  id int identity(1,1)
	, measure varchar(25)
	, value decimal(18,2)
	, count_of_mode int
);




EXECUTE sp_RaiserrorTime @p_msg_str=N'Calculating the average statement cost';
INSERT INTO
	#central_tendancy (measure, value, count_of_mode)
SELECT
	  'average statement cost' AS measure
	, AVG(statement_subtree_cost) AS value
	, NULL AS count_of_mode
FROM
	#subtree_cost;



EXECUTE sp_RaiserrorTime @p_msg_str=N'Calculating the median statement cost';
INSERT INTO
	#central_tendancy (measure, value, count_of_mode)
SELECT DISTINCT
	  'median statement cost' AS measure
	, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY statement_subtree_cost) OVER () AS value
	, NULL AS count_of_mode
FROM
    #subtree_cost;




EXECUTE sp_RaiserrorTime @p_msg_str=N'Calculating the mode statement cost';
WITH
	  /* Step 1: Count the frequency of each unique cost value */
	  value_counts AS (
		SELECT
			  statement_subtree_cost
			, COUNT(statement_subtree_cost) AS frequency
		FROM
			#subtree_cost
		GROUP BY
			statement_subtree_cost
	  )
	  /* Step 2: Rank the frequencies (highest frequency gets Rank 1) */
	, ranked_counts AS (
		SELECT
			  statement_subtree_cost
			, frequency
			  /* DENSE_RANK assigns the same rank if frequencies are tied, ensuring all modes (co-modes) are included. */
			, DENSE_RANK() OVER (ORDER BY frequency DESC) AS rank_by_frequency
		FROM
			value_counts
	  )
/* Step 3: Select all cost values that have a Rank of 1 (the highest frequency) */
INSERT INTO
	#central_tendancy (measure, value, count_of_mode)
SELECT
	  'mode statement cost' AS measure
	, statement_subtree_cost AS value
	, frequency AS count_of_mode
FROM
	ranked_counts
WHERE
	rank_by_frequency = 1
ORDER BY
	value;

	


EXECUTE sp_RaiserrorTime @p_msg_str=N'Display central tendancy values';
SELECT
	  'Central Tendancy' AS description
	, measure
	, value
	, count_of_mode
FROM
	#central_tendancy
ORDER BY
	id;



EXECUTE sp_RaiserrorTime @p_msg_str=N'Display grouped parallel statement costs';
SELECT
	  'Statements Grouped By Costs' AS description
	, FLOOR(statement_subtree_cost / @cost_group_size) * @cost_group_size + 1 AS cost_start
	, CAST(FLOOR(statement_subtree_cost / @cost_group_size) * @cost_group_size + 1 AS VARCHAR(19)) + ' - ' + CAST(FLOOR(statement_subtree_cost / @cost_group_size) * @cost_group_size + @cost_group_size AS VARCHAR(19)) AS cost_range
	, COUNT(*) AS number_of_statements_in_group
	, SUM(statement_subtree_cost) AS total_cost_in_group
FROM
	#subtree_cost
GROUP BY
	FLOOR(statement_subtree_cost / @cost_group_size) * @cost_group_size
ORDER BY
	cost_start;





/**************************************/
/* see the individual statement costs */
/**************************************/

EXECUTE sp_RaiserrorTime @p_msg_str=N'Display individual parallel statement costs';
SELECT
	  'Individual Statement Costs' AS description
	, statement_subtree_cost
FROM
	#subtree_cost
ORDER BY
	statement_subtree_cost;




/*
DROP TABLE IF EXISTS #subtree_cost;
DROP TABLE IF EXISTS #central_tendancy;
*/
