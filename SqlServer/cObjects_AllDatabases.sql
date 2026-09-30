	



/* user input */
DECLARE
	  @searchType TINYINT = 1  /* 1 = search by object name equality, 2 = search by object name like, 3 = search for a string in the object definition */
	, @SearchString NVARCHAR(4000) = N'myStoredProcName';


IF @searchType NOT IN (1,2,3)
BEGIN
	RAISERROR('You entered an unsupported value for @searchType. Please try again.',16,1);
	RETURN;
END;





/* other variables */
DECLARE
	  @dbName NVARCHAR(128)
	, @sqlStmt NVARCHAR(4000);
/* temp table to store the results */
DROP TABLE IF EXISTS #CombineResults;
CREATE TABLE #CombineResults (
	  DbName NVARCHAR(128)
	, SchemaName NVARCHAR(128)
	, ObjectName NVARCHAR(128)
	, type_desc NVARCHAR(60)
	, definition NVARCHAR(MAX)
	, create_date DATETIME
	, modify_date DATETIME
);




/* loop through the databases and look for the objects */
DECLARE cur_DBs CURSOR LOCAL FAST_FORWARD FOR
	SELECT name FROM sys.databases WHERE state=0;

OPEN cur_DBs;
	FETCH NEXT FROM cur_DBs INTO @dbName;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @sqlStmt = N'
INSERT INTO /* cObjects_AllDatabases */
	#CombineResults (
		  DbName
		, SchemaName
		, ObjectName
		, definition
		, type_desc
		, modify_date
		, create_date
	)
SELECT
	  @dbName
	, s.name
	, o.name
	, m.definition
	, o.type_desc
	, o.modify_date
	, o.create_date
FROM     [' + @dbName + N'].sys.objects     AS o
JOIN     [' + @dbName + N'].sys.schemas     AS s ON s.schema_id = o.schema_id	
JOIN     [' + @dbName + N'].sys.sql_modules AS m ON m.object_id = o.object_id
';

	SELECT @sqlStmt = @sqlStmt + 
		CASE @searchType
			WHEN 1 THEN N'WHERE    o.name = @SearchString'
			WHEN 2 THEN N'WHERE    o.name like ''%'' + @SearchString + N''%'''
			WHEN 3 THEN N'WHERE    m.definition like ''%'' + @SearchString + N''%'''
		END;

	
		EXECUTE sp_executesql @sqlStmt, N'@dbName NVARCHAR(128), @SearchString NVARCHAR(4000)', @dbName=@dbName, @SearchString=@SearchString;



		FETCH NEXT FROM cur_DBs INTO @dbName;
	END;
CLOSE cur_DBs;
DEALLOCATE cur_DBs;




/* display results */
SELECT
	  @@SERVERNAME AS ServerName
	, DbName
	, SchemaName
	, ObjectName
	, definition
	, type_desc
	, modify_date
	, create_date
FROM
	#CombineResults
ORDER BY
	  DbName
	, SchemaName
	, ObjectName;




/* --compare the code

declare @comparison_db varchar(128) = 'Wms_Nee_PROD';

-- show the one we are using for comparison
select 'comparison' category, DbName, SchemaName, ObjectName, type_desc, definition, create_date, modify_date
from #CombineResults
where DbName=@comparison_db;

-- show all the matching ones
with	one as (	select DbName, SchemaName, ObjectName, type_desc, definition, create_date, modify_date
			from #CombineResults
			where DbName=@comparison_db),
	others as (	select DbName, SchemaName, ObjectName, type_desc, definition, create_date, modify_date
			from #CombineResults
			where DbName<>@comparison_db)
select 'matching' category, DbName, SchemaName, ObjectName, type_desc, definition, create_date, modify_date
from others b
where exists (select 1 from one a where replace(replace(replace(replace(a.definition, char(13), ''), char(10), ''), char(9), ''), ' ', '') = replace(replace(replace(replace(b.definition, char(13), ''), char(10), ''), char(9), ''), ' ', '') )
order by b.DbName;

-- show all the different ones
with	one as (	select DbName, SchemaName, ObjectName, type_desc, definition, create_date, modify_date
			from #CombineResults
			where DbName=@comparison_db),
	others as (	select DbName, SchemaName, ObjectName, type_desc, definition, create_date, modify_date
			from #CombineResults
			where DbName<>@comparison_db)
select 'different' category, DbName, SchemaName, ObjectName, type_desc, definition, create_date, modify_date
from others b
where not exists (select 1 from one a where replace(replace(replace(replace(a.definition, char(13), ''), char(10), ''), char(9), ''), ' ', '') = replace(replace(replace(replace(b.definition, char(13), ''), char(10), ''), char(9), ''), ' ', '') )
order by b.DbName;

*/

GO

