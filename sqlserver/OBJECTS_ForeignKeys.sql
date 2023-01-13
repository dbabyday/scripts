
--  SELECT 'USE [' + name + '];' FROM sys.databases ORDER BY name;



-- get foreign keys in database
select   f.name                  AS ForeignKey
       , ps.name + N'.' + p.name AS TableName
       , pc.name                 AS ColumnName
       , rs.name + N'.' + r.name AS ReferenceTableName
       , rc.name                 AS ReferenceColumnName
       , is_not_trusted
	   , N'alter table [' + ps.name + N'].[' + p.name + N'] nocheck constraint [' + f.name + N'];'          AS disable_cmd
	   , N'alter table [' + ps.name + N'].[' + p.name + N'] with check check constraint [' + f.name + N'];' AS enable_and_check_cmd
	   , N'alter table [' + ps.name + N'].[' + p.name + N'] with check add constraint [' + f.name + N'] foreign key ([' + pc.name + N']) references [' + rs.name + N'].[' + r.name + N']([' + rc.name + N']);' AS create_fk
	   , N'alter table [' + ps.name + N'].[' + p.name + N'] drop constraint [' + f.name + N']; '            AS drop_fk
from     sys.foreign_keys        AS f 
join     sys.foreign_key_columns AS fc ON f.object_id = fc.constraint_object_id
join     sys.objects             AS p  ON p.object_id=f.parent_object_id
join     sys.objects             AS r  ON r.object_id=f.referenced_object_id
join     sys.schemas             AS ps ON ps.schema_id=p.schema_id
join     sys.schemas             AS rs ON rs.schema_id=r.schema_id
join     sys.columns             AS pc ON pc.object_id=fc.parent_object_id and pc.column_id=fc.parent_column_id
join     sys.columns             AS rc ON rc.object_id=fc.referenced_object_id and rc.column_id=fc.referenced_column_id
order by TableName
       , ColumnName;

/*

	WITH CHECK | WITH NOCHECK
	Specifies whether the data in the table is or isn't validated against 
	a newly added or re-enabled FOREIGN KEY or CHECK constraint. If you 
	don't specify, WITH CHECK is assumed for new constraints, 
	and WITH NOCHECK is assumed for re-enabled constraints.

*/