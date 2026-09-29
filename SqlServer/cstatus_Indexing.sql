use CentralAdmin;


/* Duration for each step */
select
	  id
	, entry_time
	, database_name
	, schema_name
	, table_name
	, index_name
	, description
	, case
		when description in ('END') then ''
		when lead(entry_time) over (order by id) is null then format(dateadd(second,datediff(second,convert(datetime2,entry_time),convert(datetime2,sysdatetimeoffset())),0),'HH:mm:ss') + ' ...and probably still running?'
		else format(dateadd(second,datediff(second,convert(datetime2,entry_time),convert(datetime2,lead(entry_time) over (order by id))),0),'HH:mm:ss')
	  end duration
from
	dbo.indexing_status
order by
	id;