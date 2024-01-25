use ssisdb;

/*

-- do a general search for environment names
use ssisdb;
select environment_name 
from internal.environments 
where environment_name like '%HARM%' 
order by environment_name;


-- get the environment name from the reference_id
-- the job command probably has the env reference id
use ssisdb;
SELECT distinct
	e.name
FROM
	catalog.folders AS F
JOIN 
	catalog.environments AS E ON E.folder_id = F.folder_id
JOIN 
	catalog.environment_references AS ER ON 
		(
			ER.reference_type = 'A'
			AND ER.environment_folder_name = F.name
			AND ER.environment_name = E.name
		)
		OR (
			ER.reference_type = 'R'
			AND ER.environment_name = E.name
		)
JOIN 
	catalog.projects AS PJ ON PJ.project_id = ER.project_id AND PJ.folder_id = F.folder_id
JOIN 
	catalog.packages AS PK ON PK.project_id = PJ.project_id
JOIN 
	catalog.folders AS F2 ON F2.folder_id = PJ.folder_id
where
	f.name='GSF2_APP'
	and ER.reference_id=238;

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
	e.environment_name=N'HarmonicSigmasureDataFeed'
order by
	v.name;



