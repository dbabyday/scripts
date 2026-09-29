
--  SELECT 'USE [' + name + '];' FROM sys.databases ORDER BY name;




/* only see a specific table: uncomment these variables, and the where clause */
declare 
	  @mySchema sysname=N'UnitSetup'
	, @myTable sysname=N'UnitIdentity';



-- get foreign keys in database
select
	  f.name                  AS ForeignKey
	, ps.name + N'.' + p.name AS TableName
	, pc.name                 AS ColumnName
	, rs.name + N'.' + r.name AS ReferenceTableName
	, rc.name                 AS ReferenceColumnName
	, f.is_not_for_replication
	, f.is_not_trusted
	, f.is_disabled
	, N'alter table [' + ps.name + N'].[' + p.name + N'] with ' + 
		case when f.is_not_trusted=1 then N'nocheck' else N'check' end +
		N' add constraint [' + f.name + N'] foreign key ([' + pc.name + N']) references [' + rs.name + N'].[' + r.name + N'] ([' + rc.name + N'])' +
		case when f.is_not_for_replication=1 then N' not for replication;' else N';' end + char(13)+char(10) + 
		N'alter table [' + ps.name + N'].[' + p.name + N'] ' +
		case when f.is_disabled=1 then N'nocheck' else N'check' end +
		N' constraint [' + f.name + N'];'
		create_fk
	, N'alter table [' + ps.name + N'].[' + p.name + N'] drop constraint [' + f.name + N']; '            AS drop_fk
	, N'alter table [' + ps.name + N'].[' + p.name + N'] nocheck constraint [' + f.name + N'];'          AS disable_cmd
	, N'alter table [' + ps.name + N'].[' + p.name + N'] with check check constraint [' + f.name + N'];' AS enable_and_check_cmd
from     sys.foreign_keys        AS f 
join     sys.foreign_key_columns AS fc ON f.object_id=fc.constraint_object_id
join     sys.objects             AS p  ON p.object_id=f.parent_object_id
join     sys.objects             AS r  ON r.object_id=f.referenced_object_id
join     sys.schemas             AS ps ON ps.schema_id=p.schema_id
join     sys.schemas             AS rs ON rs.schema_id=r.schema_id
join     sys.columns             AS pc ON pc.object_id=fc.parent_object_id and pc.column_id=fc.parent_column_id
join     sys.columns             AS rc ON rc.object_id=fc.referenced_object_id and rc.column_id=fc.referenced_column_id
--where    rs.name=@mySchema and r.name=@myTable
where    ps.name=@mySchema and p.name=@myTable
--where f.name=N'FK_VerificationCodeVersion_UnitIdentity_VerificationCodeVersionId'
order by TableName
       , ColumnName;

/*
alter table Test.FlyingProbeDetail with nocheck add constraint FK_FlyingProbeHeader_FlyingProbeDetail_FlyingProbeHeaderId foreign key (FlyingProbeHeaderId) references Test.FlyingProbeHeader (FlyingProbeHeaderId) not for replication;
alter table Test.FlyingProbeDetail check constraint FK_FlyingProbeHeader_FlyingProbeDetail_FlyingProbeHeaderId;

	WITH CHECK | WITH NOCHECK
	Specifies whether the data in the table is or isn't validated against 
	a newly added or re-enabled FOREIGN KEY or CHECK constraint. If you 
	don't specify, WITH CHECK is assumed for new constraints, 
	and WITH NOCHECK is assumed for re-enabled constraints.

*/
