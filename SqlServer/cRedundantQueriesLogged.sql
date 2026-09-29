/*

use CentralAdmin;
select TOP(100) * from 	dbo.RedundantQueries order by EntryTime desc, PlansCached desc;


SELECT MIN(EntryTime) SampleStartTime, MAX(EntryTime) SampleEndTime
FROM dbo.RedundantQueries
WHERE EntryTime > DATEADD(WEEK,-4,GETDATE());

--*/


--/*
USE CentralAdmin;
GO

DECLARE
	  @EntryTime_Start datetime2(3) = DATEADD(WEEK,-4,GETDATE())
	, @Qty_ExampleText int          = 10;


WITH
	  cte_RedundantQueries AS (
		SELECT
			  @@SERVERNAME AS ServerName
			, query_hash
			, COUNT(*) AS NumEntries
			, SUM(PlansCached) AS SUM_PlansCached
			, CAST(ROUND(AVG(PlansCached*1.0),0) AS INT) AS AVG_PlansCached
			, SUM(DistinctPlansCached) AS SUM_DistinctPlansCached
			, SUM(Total_Executions) AS SUM_Total_Executions
			, MIN(EntryTime) AS MIN_EntryTime
			, MAX(EntryTime) AS MAX_EntryTime
		FROM
			dbo.RedundantQueries
		WHERE
			EntryTime > @EntryTime_Start
		GROUP BY
			query_hash
	  )
	, cte_X AS (
		SELECT
			  s.query_hash
			, t.text
			, ROW_NUMBER() OVER (PARTITION BY s.query_hash ORDER BY s.sql_handle) as RowNum
		FROM
			sys.dm_exec_query_stats AS s
		CROSS APPLY
			sys.dm_exec_sql_text(s.sql_handle) AS t
		WHERE
			EXISTS (
				SELECT 1
				FROM cte_RedundantQueries r
				WHERE r.query_hash = s.query_hash
			)
	  )
SELECT
	  r.query_hash
	, x.RowNum
	, x.text
	, r.NumEntries
	, r.SUM_PlansCached
	, r.AVG_PlansCached
	, r.SUM_DistinctPlansCached
	, r.SUM_Total_Executions
	, r.MIN_EntryTime
	, r.MAX_EntryTime
FROM 
	cte_RedundantQueries r
LEFT OUTER JOIN
	cte_X AS x on x.query_hash = r.query_hash
WHERE
	x.RowNum <= @Qty_ExampleText
	OR x.RowNum IS NULL
ORDER BY
	  r.SUM_PlansCached DESC
	, r.query_hash
	, x.RowNum;
--*/





/*

USE CentralAdmin;
GO

DECLARE @EntryTime_Start datetime2(3) = DATEADD(WEEK,-4,GETDATE());

SELECT
	  @@SERVERNAME AS ServerName
	, query_hash
	, COUNT(*) AS NumEntries
	, SUM(PlansCached) AS SUM_PlansCached
	, CAST(ROUND(AVG(PlansCached*1.0),0) AS INT) AS AVG_PlansCached
	, SUM(DistinctPlansCached) AS SUM_DistinctPlansCached
	, SUM(Total_Executions) AS SUM_Total_Executions
	, MIN(EntryTime) AS MIN_EntryTime
	, MAX(EntryTime) AS MAX_EntryTime
FROM
	dbo.RedundantQueries
WHERE
	EntryTime >  @EntryTime_Start
GROUP BY
	query_hash
ORDER BY query_hash
	--SUM_PlansCached DESC;



GO

--*/


/*
-- see quantity logged over time for a specific query hash


use CentralAdmin;

declare @query_hash binary(8) = 0x054D8829331682C7;

select distinct
	  EntryTime
	, @query_hash query_hash
	, 0 sum_PlansCached
	, 0 sum_DistinctPlansCached
	, 0 sum_Total_Executions
from
	dbo.RedundantQueries
where
	EntryTime not in (
		select EntryTime
		from dbo.RedundantQueries
		where query_hash=@query_hash
	)
	AND EntryTime > DATEADD(WEEK,-1,GETDATE())
union all
select
	  EntryTime
	, @query_hash query_hash
	, sum(PlansCached) sum_PlansCached
	, sum(DistinctPlansCached) sum_DistinctPlansCached
	, sum(Total_Executions) sum_Total_Executions
from
	dbo.RedundantQueries
where
	query_hash=@query_hash
	AND EntryTime > DATEADD(WEEK,-1,GETDATE())
group by
	  EntryTime
	, query_hash
order by
	  EntryTime desc;

select top(100) SampleQueryText
from dbo.RedundantQueries
where query_hash=@query_hash
	AND EntryTime > DATEADD(WEEK,-1,GETDATE())
group by SampleQueryText;

--*/



/*
-- see total numbers combined for an entry time (only top 10 are recorded)

use CentralAdmin;


select
	  EntryTime
	, sum(PlansCached) sum_PlansCached
	, sum(DistinctPlansCached) sum_DistinctPlansCached
	, sum(Total_Executions) sum_Total_Executions
from
	dbo.RedundantQueries
group by
	  EntryTime
order by
	  EntryTime;

--*/