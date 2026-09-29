
declare
	  @myFileGroup sysname = N''
	, @myTableName nvarchar(357) = N'Test.IctDetail';

if @myFileGroup <> N''
	select
		  object_schema_name(i.object_id)+N'.'+object_name(i.object_id) AS ObjectName
		, i.name AS IndexName
		, i.type_desc AS IndexType
		, f.name AS FileGroup
		, d.physical_name AS FileName
	from
		sys.indexes i
	join
		sys.filegroups f on f.data_space_id = i.data_space_id
	join
		sys.database_files d on f.data_space_id = d.data_space_id
	where
		objectproperty(i.object_id, 'IsUserTable') = 1
		and f.name=@myFileGroup
	order by
		  f.name
		, object_schema_name(i.object_id)
		, object_name(i.object_id);
else if @myTableName <> N''
	select
		  object_schema_name(i.object_id)+N'.'+object_name(i.object_id) AS ObjectName
		, i.name AS IndexName
		, i.type_desc AS IndexType
		, f.name AS FileGroup
		, d.physical_name AS FileName
	from
		sys.indexes i
	join
		sys.filegroups f on f.data_space_id = i.data_space_id
	join
		sys.database_files d on f.data_space_id = d.data_space_id
	where
		objectproperty(i.object_id, 'IsUserTable') = 1
		and i.object_id=object_id(@myTableName,N'U')
	order by
		  f.name
		, object_schema_name(i.object_id)
		, object_name(i.object_id);
else
	select
		  object_schema_name(i.object_id)+N'.'+object_name(i.object_id) AS ObjectName
		, i.name AS IndexName
		, i.type_desc AS IndexType
		, f.name AS FileGroup
		, d.physical_name AS FileName
	from
		sys.indexes i
	join
		sys.filegroups f on f.data_space_id = i.data_space_id
	join
		sys.database_files d on f.data_space_id = d.data_space_id
	where
		objectproperty(i.object_id, 'IsUserTable') = 1
	order by
		  f.name
		, object_schema_name(i.object_id)
		, object_name(i.object_id);