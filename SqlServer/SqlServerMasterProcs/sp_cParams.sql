USE master;
GO
/*
Adapted from: https://stackoverflow.com/questions/20115881/how-to-get-stored-procedure-parameters-details
*/
CREATE OR ALTER PROCEDURE dbo.sp_cParams
	  @DatabaseName nvarchar(128) = NULL
	, @SchemaName nvarchar(128) = NULL
	, @ObjectName nvarchar(128) = NULL
AS
	DECLARE
		  @FullyQualifiedObjectName nvarchar(392) = N'[' + @DatabaseName + N'].[' + @SchemaName + N'].[' + @ObjectName + N']'
		, @ObjId INT
		, @SQLString nvarchar(max)
		, @Msg nvarchar(max)
		, @crlf nvarchar(2) = NCHAR(13) + NCHAR(10);
	


	/* Error checking */
	IF @DatabaseName IS NULL OR @SchemaName IS NULL OR @ObjectName IS NULL
	BEGIN
		SET @Msg = 
			N'/* You must enter values for all three parameters */' + @crlf +
			@crlf +
			N'EXECUTE sp_cParams' + @crlf +
			N'	  @DatabaseName = N''''' + @crlf +
			N'	, @SchemaName = N''''' + @crlf +
			N'	, @ObjectName = N'''';' + @crlf +
			@crlf;
		RAISERROR(@Msg,0,1) WITH NOWAIT;
		RETURN;
	END;

	IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE name=@DatabaseName)
	BEGIN
		SET @Msg = N'@DatabaseName = ''' + @DatabaseName + ''' does not exist';
		RAISERROR(@Msg,16,1) WITH NOWAIT;
		RETURN;
	END;

	IF OBJECT_ID(@FullyQualifiedObjectName) IS NULL
	BEGIN
		SET @Msg = N'Object ' + @FullyQualifiedObjectName + ''' does not exist';
		RAISERROR(@Msg,16,1) WITH NOWAIT;
		RETURN;
	END;




	/* get the info */
	SET @ObjId = OBJECT_ID(@FullyQualifiedObjectName);
	/* put the query as dynamic sql so we can select from the correct database */
	SET @SQLString = N'
		SELECT
			  name AS ParameterName
			, type_name(user_type_id) AS Type
			, max_length AS Length
			, CASE
				WHEN type_name(system_type_id) = ''uniqueidentifier'' THEN precision  
				ELSE OdbcPrec(system_type_id, max_length, precision)
			  END AS Precision
			, OdbcScale(system_type_id, scale) AS Scale
			, parameter_id
		FROM
			[' + @DatabaseName + N'].sys.parameters
		WHERE
			object_id = @ds_ObjId
		ORDER BY
			parameter_id';

	EXECUTE sp_executesql
		  @SQLString
		, N'@ds_ObjId INT'
		, @ds_ObjId = @ObjId;
GO