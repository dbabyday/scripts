use myDbName;

select
	  N'[' + db_name() + N'].[' + object_schema_name(object_id) + N'].[' + name + N']' synonym_name
	, base_object_name
from
	sys.synonyms
order by
	1;