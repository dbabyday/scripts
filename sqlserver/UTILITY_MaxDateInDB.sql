USE myDatabase; -- change 'myDatabase'
GO

SET NOCOUNT ON;

DECLARE
	@tableCatalog varchar(128),
	@tableSchema  varchar(128),
	@tableName    varchar(128),
	@columnName   varchar(128),
	@maxDate      datetime,
	@query        varchar(max),
	@i            int;

SET @i = 1;

IF OBJECT_ID('tempdb..#tblMaxDates') IS NOT NULL
	DROP TABLE #tblMaxDates;

CREATE TABLE #tblMaxDates
(
	[ID]            int,
	[TABLE_CATALOG] varchar(128),
	[TABLE_SCHEMA]  varchar(128),
	[TABLE_NAME]    varchar(128),
	[COLUMN_NAME]   varchar(128),
	[MaxDate]       datetime
);

DECLARE curMaxDates CURSOR FAST_FORWARD FOR
	SELECT 
		TABLE_CATALOG, 
		TABLE_SCHEMA, 
		TABLE_NAME, 
		COLUMN_NAME
	FROM 
		INFORMATION_SCHEMA.COLUMNS 
	WHERE 
		DATA_TYPE IN ('date','datetime','datetime2','datetimeoffset','smalldatetime','time');

OPEN curMaxDates;
	FETCH NEXT FROM curMaxDates INTO @tableCatalog, @tableSchema, @tableName, @columnName;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO #tblMaxDates ([ID],[TABLE_CATALOG],[TABLE_SCHEMA],[TABLE_NAME],[COLUMN_NAME])
		VALUES (@i,@tableCatalog, @tableSchema, @tableName, @columnName);

		EXECUTE('UPDATE #tblMaxDates ' + 
                'SET [MaxDate] = (SELECT MAX([' + @columnName + ']) FROM [' + @tableCatalog + '].[' + @tableSchema + '].[' + @tableName + ']) ' +
                'WHERE [ID] = ' + @i);

		SET @i = @i + 1;
		FETCH NEXT FROM curMaxDates INTO @tableCatalog, @tableSchema, @tableName, @columnName;
	END
CLOSE curMaxDates;
DEALLOCATE curMaxDates;

SELECT * FROM #tblMaxDates ORDER BY [MaxDate] DESC;

IF OBJECT_ID('tempdb..#tblMaxDates') IS NOT NULL
	DROP TABLE #tblMaxDates;


