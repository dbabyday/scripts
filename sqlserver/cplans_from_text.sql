SELECT
	  UseCounts
	, Cacheobjtype
	, Objtype
	, TEXT
	, query_plan  
FROM
	sys.dm_exec_cached_plans cp
CROSS APPLY
	sys.dm_exec_sql_text(plan_handle) sqltext 
CROSS APPLY
	sys.dm_exec_query_plan(plan_handle) queryplan
where
	--sqltext.text like '%CREATE TABLE #tblUnitIdentity%';
	sqltext.text like '%insert%@p_UnitBackFlushDetailTable%';