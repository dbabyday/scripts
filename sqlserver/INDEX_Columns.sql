-- select 'USE '+ quotename(name) + ';' from sys.databases order by name




SELECT 
    [Table]    = SCHEMA_NAME(t.schema_id) + N'.' + t.name,
    [Index]    = ind.name,
    [Column]   = col.name,
	[Included] = CASE ic.is_included_column
	                 WHEN 1 THEN 'INCLUDED'
					 WHEN 0 THEN 'ON'
				 END,
	[IdxType]  = ind.type_desc,
	[Unique]   = CASE ind.is_unique
	                 WHEN 1 THEN 'Unique'
					 WHEN 0 THEN 'Not Unique'
			     END,
	[PK]       = CASE ind.is_primary_key
				     WHEN 1 THEN 'Part of PK'
				     WHEN 0 THEN 'Not Part of PK'
			     END
    --,[TableId]  = t.object_id
    --,[IndexId]  = ind.index_id
    --,[TblColId] = ic.column_id
    --,[IdxColId] = ic.index_column_id
	
    --,ind.*
    --,ic.*
    --,col.* 
FROM 
     sys.indexes ind 
INNER JOIN 
     sys.index_columns ic 
	 ON ind.object_id = ic.object_id 
	 and ind.index_id = ic.index_id 
INNER JOIN 
     sys.columns col 
	 ON ic.object_id = col.object_id 
	 and ic.column_id = col.column_id 
INNER JOIN 
     sys.tables t 
	 ON ind.object_id = t.object_id 
--WHERE 
--    t.name = ''
--    ind.name = ''
--    ind.is_primary_key = 0 
--    AND ind.is_unique = 0 
--    AND ind.is_unique_constraint = 0 
--    AND t.is_ms_shipped = 0 
ORDER BY 
	t.name, 
	ind.name,
    ic.is_included_column,
	ic.index_column_id
     --t.name, ind.name, ind.index_id, ic.index_column_id