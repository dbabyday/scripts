

-- select 'use ' + name + ';' from sys.databases order by name;



select
	  @@servername server_name
	, db_name() database_name
	, s.name + N'.' + t.name table_name
	, i.type_desc
	, t.type_desc
	, t.create_date
	, N'ALTER TABLE [' + s.name + N'].[' + t.name + N'] REBUILD WITH (ONLINE=ON);' rebuild_stmt
	, 'set @l_object_id = ' + cast(t.object_id as varchar(11)) + '; select s.name + N''.'' + t.name table_name,i.name index_name,p.index_type_desc,p.page_count,p.avg_fragmentation_in_percent,p.forwarded_record_count from sys.dm_db_index_physical_stats (db_id(), @l_object_id, null, null, N''DETAILED'') p join sys.indexes i on i.object_id=p.object_id and i.index_id=p.index_id join sys.tables t on t.object_id = p.object_id join sys.schemas s on s.schema_id = t.schema_id where forwarded_record_count>0;' [declare @l_object_id int;]
from 	sys.indexes i
join 	sys.tables t on i.object_id = t.object_id
join 	sys.schemas s on t.schema_id = s.schema_id
where
	i.type_desc = 'HEAP'
	and t.name not like 'MSchange%'
	and t.name not like 'MSpeer%'
	and t.name not like 'MSpub%'
	and t.name not like 'sys%'
order by
	  s.name
	, t.name;



