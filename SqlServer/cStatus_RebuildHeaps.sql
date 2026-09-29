use CentralAdmin;


/* Duration for each step */
select
	  Id
	, EntryTime
	, DatabaseName
	, SchemaName
	, TableName
	, Description
	, case
		when description in ('Starting work on this database','End') then ''
		when lead(EntryTime) over (order by id) is null then format(dateadd(second,datediff(second,convert(datetime2,EntryTime),convert(datetime2,sysdatetimeoffset())),0),'HH:mm:ss') + ' ...and probably still running?'
		else format(dateadd(second,datediff(second,convert(datetime2,EntryTime),convert(datetime2,lead(EntryTime) over (order by id))),0),'HH:mm:ss')
	  end duration
from
	dbo.HeapRebuildStatus
order by
	Id;





/*

-- sort by duration

with durations as (
select
	  Id
	, EntryTime
	, DatabaseName
	, SchemaName
	, TableName
	, Description
	, case
		when description in ('Starting work on this database','End') then ''
		when lead(EntryTime) over (order by id) is null then format(dateadd(second,datediff(second,convert(datetime2,EntryTime),convert(datetime2,sysdatetimeoffset())),0),'HH:mm:ss') + ' ...and probably still running?'
		else format(dateadd(second,datediff(second,convert(datetime2,EntryTime),convert(datetime2,lead(EntryTime) over (order by id))),0),'HH:mm:ss')
	  end duration
from
	dbo.HeapRebuildStatus
)
select
	  Id
	, EntryTime
	, DatabaseName
	, SchemaName
	, TableName
	, Description
	, duration
from
	durations
order by
	duration desc;



*/