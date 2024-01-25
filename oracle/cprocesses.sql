col name for a20
col value for a20

select
	  name
	, value
from
	v$parameter
where
	name in ('processes','sessions','transactions')
order by
	name;