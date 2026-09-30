USE master;
GO
CREATE OR ALTER procedure dbo.sp_cObject
	@objName sysname
AS
	DECLARE
		  @db sysname = db_name()
		, @schemaName sysname
		, @sqlString nvarchar(4000);


	/* get the object info */
	CREATE TABLE #myObjects (
		  DbName      sysname
		, SchemaName  sysname
		, ObjName     sysname
		, type_desc   nvarchar(60)
		, definition  nvarchar(max)
		, create_date datetime2(3)
		, modify_date datetime2(3)
	);


	SET @sqlString = N'
USE [' + @db + N'];
INSERT INTO #myObjects /*dbo.sp_cObject*/ (
	  DbName
	, SchemaName
	, ObjName
	, type_desc
	, definition
	, create_date
	, modify_date
)
SELECT
	  db_name()
	, object_schema_name(o.object_id)
	, o.name
	, o.type_desc
	, m.definition
	, o.create_date
	, o.modify_date
FROM
	sys.objects o
INNER JOIN
	sys.sql_modules m ON m.object_id=o.object_id
WHERE
	o.name = @objName;';

	EXECUTE sp_executesql
		  @sqlString
		, N'@objName sysname'
		, @objName=@objName;





	/* display the object info */
	SELECT
		  DbName
		, SchemaName
		, ObjName
		, type_desc
		, definition
		, create_date
		, modify_date
	FROM
		#myObjects
	ORDER BY
		  type_desc
		, SchemaName
		, ObjName;



	
	/* show the parameters for the object
	   run the query for each object
	   in case there are multple objects that have the same name */
	DECLARE cur_Objects CURSOR LOCAL FAST_FORWARD FOR
		SELECT
			  SchemaName
			, ObjName
		FROM
			#myObjects
		ORDER BY
			  type_desc
			, SchemaName
			, ObjName;

	OPEN cur_Objects;
		FETCH NEXT FROM cur_Objects INTO @schemaName, @objName;

		WHILE @@fetch_status = 0
		BEGIN
			EXECUTE sp_cParams
				  @DatabaseName = @db
				, @SchemaName   = @schemaName
				, @ObjectName   = @objName;

			FETCH NEXT FROM cur_Objects INTO @schemaName, @objName;
		END;
	CLOSE cur_Objects;
	DEALLOCATE cur_Objects;
GO