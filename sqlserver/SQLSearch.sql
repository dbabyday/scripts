DECLARE 
	@db  NVARCHAR(256),
	@sql NVARCHAR(4000);

CREATE TABLE #Objects
(
	[ID]                  INT IDENTITY(1,1),
	[server]              NVARCHAR(256),
	[object]              NVARCHAR(256),
	[schema]              NVARCHAR(256),
	[database]            NVARCHAR(256),
	[type]                NVARCHAR(50),
	--[definition]          NVARCHAR(MAX),
	[JDPD non-OPENQUERY]  INT,
	[JDPD OPENQUERY]      INT,
	[JDPY non-OPENQUERY]  INT,
	[JDPY OPENQUERY]      INT,
	[JDTRN non-OPENQUERY] INT,
	[JDTRN OPENQUERY]     INT
);

DECLARE curEachDatabase CURSOR LOCAL FAST_FORWARD FOR
	SELECT name
	FROM sys.databases
	WHERE state =0;

OPEN curEachDatabase;
FETCH NEXT FROM curEachDatabase INTO @db;

WHILE @@FETCH_STATUS = 0
BEGIN

	SET @sql = N'
		USE ' + @db + ';

		INSERT INTO #Objects ([server], [object], [schema], [database], [type], [definition], [JDPD non-OPENQUERY], [JDPD OPENQUERY], [JDPY non-OPENQUERY], [JDPY OPENQUERY], [JDTRN non-OPENQUERY], [JDTRN OPENQUERY])
		SELECT 
			@@SERVERNAME AS ''server'',
			o.name AS ''object'',
			SCHEMA_NAME() AS ''schema'',
			DB_NAME() AS ''database'',
			CASE o.type
				WHEN ''AF'' THEN ''Aggregate function (CLR)''
				WHEN ''C''  THEN ''CHECK constraint''
				WHEN ''D''  THEN ''Default or DEFAULT constraint''
				WHEN ''F''  THEN ''FOREIGN KEY constraint''
				WHEN ''L''  THEN ''Log''
				WHEN ''FN'' THEN ''Scalar function''
				WHEN ''FS'' THEN ''Assembly (CLR) scalar-function''
				WHEN ''FT'' THEN ''Assembly (CLR) table-valued function''
				WHEN ''IF'' THEN ''In-lined table-function''
				WHEN ''IT'' THEN ''Internal table''
				WHEN ''P''  THEN ''Stored procedure''
				WHEN ''PC'' THEN ''Assembly (CLR) stored-procedure''
				WHEN ''PK'' THEN ''PRIMARY KEY constraint (type is K)''
				WHEN ''RF'' THEN ''Replication filter stored procedure''
				WHEN ''S''  THEN ''System table''
				WHEN ''SN'' THEN ''Synonym''
				WHEN ''SQ'' THEN ''Service queue''
				WHEN ''TA'' THEN ''Assembly (CLR) DML trigger''
				WHEN ''TF'' THEN ''Table function''
				WHEN ''TR'' THEN ''SQL DML Trigger''
				WHEN ''TT'' THEN ''Table type''
				WHEN ''U''  THEN ''User table''
				WHEN ''UQ'' THEN ''UNIQUE constraint (type is K)''
				WHEN ''V''  THEN ''View''
				WHEN ''X''  THEN ''Extended stored procedure''
			END AS ''type'',
			--m.definition,
			((LEN(m.definition) - LEN(REPLACE(m.definition,''JDPD'','''')))/LEN(''JDPD'')) - ((LEN(m.definition) - LEN(REPLACE(m.definition,''OPENQUERY(JDPD'','''')))/LEN(''OPENQUERY(JDPD'')) AS ''number of non-OPENQUERY uses'',
			(LEN(m.definition) - LEN(REPLACE(m.definition,''OPENQUERY(JDPD'','''')))/LEN(''OPENQUERY(JDPD'') AS ''number of OPENQUERY uses'',
			
			((LEN(m.definition) - LEN(REPLACE(m.definition,''JDPY'','''')))/LEN(''JDPY'')) - ((LEN(m.definition) - LEN(REPLACE(m.definition,''OPENQUERY(JDPY'','''')))/LEN(''OPENQUERY(JDPY'')) AS ''number of non-OPENQUERY uses'',
			(LEN(m.definition) - LEN(REPLACE(m.definition,''OPENQUERY(JDPY'','''')))/LEN(''OPENQUERY(JDPY'') AS ''number of OPENQUERY uses'',

			
			((LEN(m.definition) - LEN(REPLACE(m.definition,''JDTRN'','''')))/LEN(''JDTRN'')) - ((LEN(m.definition) - LEN(REPLACE(m.definition,''OPENQUERY(JDTRN'','''')))/LEN(''OPENQUERY(JDTRN'')) AS ''number of non-OPENQUERY uses'',
			(LEN(m.definition) - LEN(REPLACE(m.definition,''OPENQUERY(JDTRN'','''')))/LEN(''OPENQUERY(JDTRN'') AS ''number of OPENQUERY uses''
		FROM 
			sys.sql_modules m
		INNER JOIN 
			sys.objects o
			ON m.object_id = o.object_id
		WHERE
			m.definition LIKE ''%JDPD%''
			OR m.definition LIKE ''%JDPY%''
			OR m.definition LIKE ''%JDTRN%''
		ORDER BY
			o.name;';

	--SELECT @sql;
	
	EXECUTE (@sql);
	
	FETCH NEXT FROM curEachDatabase INTO @db;
END

CLOSE curEachDatabase;
DEALLOCATE curEachDatabase;

SELECT
	[server],
	[object],
	[schema],
	[database],
	[type],
	--[definition],
	[JDPD non-OPENQUERY],
	[JDPD OPENQUERY],
	[JDPY non-OPENQUERY],
	[JDPY OPENQUERY],
	[JDTRN non-OPENQUERY],
	[JDTRN OPENQUERY]
FROM 
	#Objects
ORDER BY 
	[object],
	[database];

DROP TABLE #Objects;