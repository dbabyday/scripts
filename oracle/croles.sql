select
	role
from
	dba_roles
where
	oracle_maintained='N'
order by
	role;