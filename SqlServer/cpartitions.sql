/*


use myDbName;

-- Partitioned Tables
select distinct
	schema_name(t.schema_id)+N'.'+t.name AS table_name
from 
	sys.partitions p
join
	sys.tables t ON p.object_id = t.object_id
where
	p.partition_number <> 1
order by
	  schema_name(t.schema_id)+N'.'+t.name;


-- get partition info
declare @objectName nvarchar(128) = N'ComponentTraceability.LicensePlateInventory';
select
	  schema_name(o.schema_id) + N'.' + object_name(i.object_id) as [object]
	, p.partition_number as [p#]
	, fg.name as [filegroup]
	, p.rows
	, au.total_pages as pages
	, case boundary_value_on_right
		when 1 then 'less than'
		else 'less than or equal to' end as comparison
	, rv.value
	, convert (varchar(6), convert (int, substring (au.first_page, 6, 1) +
		substring (au.first_page, 5, 1))) + ':' + convert (varchar(20),
		convert (int, substring (au.first_page, 4, 1) +
		substring (au.first_page, 3, 1) + substring (au.first_page, 2, 1) +
		substring (au.first_page, 1, 1))) as first_page
from	
	sys.partitions p
join
	sys.indexes i on
		p.object_id = i.object_id
		and p.index_id = i.index_id
join
	sys.objects o on p.object_id = o.object_id
join
	sys.system_internals_allocation_units au on p.partition_id = au.container_id
join
	sys.partition_schemes ps on ps.data_space_id = i.data_space_id
join
	sys.partition_functions f on f.function_id = ps.function_id
join
	sys.destination_data_spaces dds on
		dds.partition_scheme_id = ps.data_space_id
		and dds.destination_id = p.partition_number
join
	sys.filegroups fg on dds.data_space_id = fg.data_space_id
left join
	sys.partition_range_values rv
		on f.function_id = rv.function_id
		and p.partition_number = rv.boundary_id
where
	i.index_id < 2
	and o.object_id = object_id(@objectName);




use myDbName;
select object_schema_name(i.object_id) as [schema],
    object_name(i.object_id) as [object],
    i.name as [index],
    s.name as [partition_scheme],
    s.*
    from sys.indexes i
    join sys.partition_schemes s on i.data_space_id = s.data_space_id
*/

go



select 
	  schema_name(t.schema_id)+N'.'+t.name table_name
	, c.name partitioning_column
	--, TYPE_NAME(c.user_type_id) column_type
	--, ps.name AS partition_scheme
from
	sys.tables t
join
	sys.indexes as i on
		t.[object_id] = i.[object_id]
		and i.[type] <= 1
join
	sys.partition_schemes as ps on ps.data_space_id = i.data_space_id   
join
	sys.index_columns as ic on
		ic.[object_id] = i.[object_id]   
		and ic.index_id = i.index_id   
		and ic.partition_ordinal >= 1 
join
	sys.columns as c on
		t.[object_id] = c.[object_id]
		and ic.column_id = c.column_id   
order by
	  schema_name(t.schema_id)+N'.'+t.name;













-- Get partition information.
SELECT
     SCHEMA_NAME(t.schema_id)+N'.'+OBJECT_NAME(i.object_id) AS ObjectName
    ,sum(p.rows) AS 'Rows'
    ,sum(au.total_pages) AS 'TotalDataPages'
    ,sum(au.total_pages)*8.0/1024.0/1024.0 gb
FROM sys.partitions p
    JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
    JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id
    JOIN sys.partition_functions f ON f.function_id = ps.function_id
    LEFT JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id
    JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id =ps.data_space_id AND dds.destination_id = p.partition_number
    JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
    JOIN (SELECT container_id, sum(total_pages) as total_pages
            FROM sys.allocation_units
            GROUP BY container_id) AS au ON au.container_id = p.partition_id 
    JOIN sys.tables t ON p.object_id = t.object_id
WHERE i.index_id < 2
group by
     SCHEMA_NAME(t.schema_id)
    ,OBJECT_NAME(i.object_id)
ORDER BY sum(p.rows);
GO













declare @myTable nvarchar(257)=N'Test.FlyingProbeDetail';

-- Get partition information.
SELECT
     SCHEMA_NAME(t.schema_id) AS SchemaName
    ,OBJECT_NAME(i.object_id) AS ObjectName
    ,i.name IndexName
    ,p.partition_number AS PartitionNumber
    ,fg.name AS Filegroup_Name
    ,rows AS 'Rows'
    ,au.total_pages AS 'TotalDataPages'
    ,CASE boundary_value_on_right
        WHEN 1 THEN 'less than'
        ELSE 'less than or equal to'
     END AS 'Comparison'
    ,value AS 'ComparisonValue'
    ,p.data_compression_desc AS 'DataCompression'
    ,p.partition_id
FROM sys.partitions p
    JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
    JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id
    JOIN sys.partition_functions f ON f.function_id = ps.function_id
    LEFT JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id
    JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id =ps.data_space_id AND dds.destination_id = p.partition_number
    JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
    JOIN (SELECT container_id, sum(total_pages) as total_pages
            FROM sys.allocation_units
            GROUP BY container_id) AS au ON au.container_id = p.partition_id 
    JOIN sys.tables t ON p.object_id = t.object_id
WHERE i.index_id > -1 -- < 2
	and i.object_id=object_id(@myTable,N'U')
ORDER BY ObjectName,p.partition_number,i.name;
GO



--execute sp_BlitzIndex @SchemaName=N'Test', @TableName=N'IctDetail';