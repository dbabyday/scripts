use CentralAdmin;
--execute dbo.LogRedundantQueries;

--begin transaction;
--declare @t datetime = '2024-01-19 13:25:11.897';
--delete from dbo.RedundantQueries where EntryTime=@t;
select * from dbo.RedundantQueries order by EntryTime desc, PlansCached desc;
/*
ROLLBACK TRANSACTION;
COMMIT TRANSACTION;
SELECT @@TRANCOUNT AS [TransactionCount];
*/



declare @query_hash varbinary(max) = 0xBC2F2A2EBE979033;
select
	  EntryTime
	, query_hash
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

