column owner      format a20
column table_name format a50

SELECT
	  t.owner
	, t.table_name
	, t.num_rows
	, round((m.inserts + m.updates + m.deletes) / t.num_rows * 100,0) pct_mod
	, to_char(t.last_analyzed,'YYYY-MM-DD HH24:MI:SS') last_analyzed
FROM
	dba_tables t
LEFT JOIN
	dba_tab_modifications m ON t.owner=m.table_owner AND t.table_name=m.table_name
WHERE
	t.num_rows>0
	and t.owner in ('PRODDTA')
	and t.table_name in ('F0006','F581750S','F1755','F0101','F4801','F0005')
	-- AND (
	-- 	CASE
	-- 	        WHEN t.num_rows=0 THEN 1
	-- 	        WHEN m.table_name is null THEN 0
	-- 	        ELSE (m.inserts + m.updates + m.deletes) / t.num_rows
	-- 	END >= 0.1
	-- 	OR m.truncated='YES'
	-- )
	-- and t.num_rows>100
ORDER BY
	length(pct_mod)
	, pct_mod;
