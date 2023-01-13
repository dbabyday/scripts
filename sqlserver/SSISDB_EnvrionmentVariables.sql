use ssisdb;

/*

use ssisdb;
select environment_name from internal.environments order by environment_name;

*/

select
	  v.name variable_name
	, v.value
	, e.environment_name
from
	catalog.environment_variables v
join
	internal.environments e on e.environment_id=v.environment_id
where
	--upper(convert(varchar(4000),v.value)) LIKE N'%GEM%'
	e.environment_name=N'JDEToPACT'
order by
	v.name;




