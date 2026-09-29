use tempdb;

/*
drop table if exists dbo.where_am_i;
*/



if object_id(N'dbo.where_am_i',N'U') is null
begin
	create table dbo.where_am_i (sql_server nvarchar(128));
	insert into dbo.where_am_i (sql_server) select @@servername;
end;




select 'local' as checking, * from dbo.where_am_i;
--select 'linked server' as checking, * from [dcc-sql-qa-010].tempdb.dbo.where_am_i;


