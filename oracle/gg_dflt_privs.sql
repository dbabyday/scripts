-- gg dflt privs
with plxdev as (
	select
		  owner
		, table_name
	from
		dba_tab_privs
	where
		grantee='PLXDEV'
		and privilege='SELECT'
)
select
	'grant select on '||t.owner||'.'||t.table_name||' to plxdev;' stmt
from
	dba_tables t
left join
	plxdev p on p.owner=t.owner and p.table_name=t.table_name
where
	p.table_name is null
	and t.owner in ('PRODDTA','PRODCTL')
order by
	  t.owner
	, t.table_name