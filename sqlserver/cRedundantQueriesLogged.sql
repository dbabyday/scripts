--/*

use CentralAdmin;
select 	* from 	dbo.RedundantQueries order by EntryTime desc, PlansCached desc;

--*/


/*


use CentralAdmin;

declare @query_hash binary(8) = 0xE83CA202893908DF;

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
group by
	  EntryTime
	, query_hash
order by
	  EntryTime desc;

--*/