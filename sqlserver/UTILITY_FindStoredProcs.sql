SET NOCOUNT ON;

DECLARE 
	--USER INPUT
	@RoutineName  NVARCHAR(128) = '',

	--other variables
	@DB           NVARCHAR(128);

-- store info from each database
IF OBJECT_ID('tempdb..#tblRoutines') IS NOT NULL
	DROP TABLE #tblRoutines;
CREATE TABLE #tblRoutines
(
	[ROUTINE_CATALOG] NVARCHAR(128),
	[ROUTINE_SCHEMA]  NVARCHAR(128),
	[ROUTINE_NAME]    NVARCHAR(128),
	[LAST_ALTERED]    DATETIME2(3),
	[ScriptRoutine]   NVARCHAR(MAX)
);

-- loop through all the databases
DECLARE curDatabases CURSOR LOCAL FAST_FORWARD FOR
	SELECT name
	FROM sys.databases
	where state=0
	--WHERE is_read_only = 0
	ORDER BY name;

OPEN curDatabases;
	FETCH NEXT FROM curDatabases INTO @DB;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- if stored proc exists in this databases, save the info in the temp table
		EXECUTE
		(
			'INSERT INTO #tblRoutines ([ROUTINE_CATALOG],[ROUTINE_SCHEMA],[ROUTINE_NAME],[LAST_ALTERED],[ScriptRoutine]) ' + 
			'SELECT [ROUTINE_CATALOG],[ROUTINE_SCHEMA],[ROUTINE_NAME],[LAST_ALTERED],' + 
				-- commands to script out the routine
				'''PRINT ''''USE ['' + [ROUTINE_CATALOG] + ''];'''';'' + CHAR(13)+CHAR(10) + ' + 
				'''PRINT ''''GO'''';'' + CHAR(13)+CHAR(10) + ' + 
				'''PRINT ''''IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = '''''''''' + [ROUTINE_CATALOG] + '''''''''')'''';'' + CHAR(13)+CHAR(10) + ' +
				'''PRINT ''''    EXEC(''''''''CREATE PROCEDURE ['' + [ROUTINE_SCHEMA] + ''].['' + [ROUTINE_NAME] + ''] AS SET NOCOUNT ON;'''''''');'''';'' + CHAR(13)+CHAR(10) + ' + 
				'''PRINT ''''GO'''';'' + CHAR(13)+CHAR(10) + ' + 
				'''USE ['' + [ROUTINE_CATALOG] + ''];'' + CHAR(13)+CHAR(10) + ' + 
				'''EXEC sp_helptext '''''' + [ROUTINE_SCHEMA] + ''.'' + [ROUTINE_NAME] + '''''';'' + CHAR(13)+CHAR(10) + '  + 
				'''PRINT ''''GO'''';'' + CHAR(13)+CHAR(10) + ' + 
				'''PRINT '''''''';'' + CHAR(13)+CHAR(10) + ' + 
				'''PRINT '''''''';'' + CHAR(13)+CHAR(10) + ' + 
				'''PRINT '''''''';'' + CHAR(13)+CHAR(10) + CHAR(13)+CHAR(10) + '''' ' + 
			'FROM [' + @DB + '].[INFORMATION_SCHEMA].[ROUTINES] ' + 
			'WHERE ROUTINE_NAME = ''' + @RoutineName + ''';'
		);
		
		FETCH NEXT FROM curDatabases INTO @DB;
	END
CLOSE curDatabases;
DEALLOCATE curDatabases;

-- display the results
SELECT @@servername,* FROM #tblRoutines;

-- clean up
IF OBJECT_ID('tempdb..#tblRoutines') IS NOT NULL
	DROP TABLE #tblRoutines;

