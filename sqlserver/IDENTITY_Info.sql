/**********************************************************************************************************
* 
* UTILITY_IdentityInfo.sql
* 
* Author: James Lutsey
* Date: 07/07/2016
* 
* Purpose: Get identity column (if one exists), along with its last value, increment value, and 
*          next value, for all tables in a database for all tables in a database.
* 
* Note: Enter a database in @database (line 18) - leave blank to get a list of the databases on this instance
* 
**********************************************************************************************************/

SET NOCOUNT ON;

DECLARE
	@database VARCHAR(128) = '', -- leave blank to get a list of databases
	@schema   VARCHAR(128),
	@table    VARCHAR(128),
	@column   VARCHAR(218);

-- make sure the user entered a vaild database name
IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE name = @database)
BEGIN	
	SELECT name AS 'Databases' FROM sys.databases ORDER BY name;
	RETURN;
END

-- temp table for identity column info
IF OBJECT_ID('tempdb..#IdentityColumns') IS NOT NULL
	DROP TABLE #IdentityColumns;

CREATE TABLE #IdentityColumns
(
	[database]          VARCHAR(128),
	[schema]            VARCHAR(128),
	[table]             VARCHAR(128),
	[column]            VARCHAR(128),
	[IsIdentity]        VARCHAR(5),
	[LastIdentityValue]	BIGINT,
	[IncrementValue]    BIGINT,
	[NextValue]         BIGINT
);

-- select the database context
EXECUTE('DECLARE curIsIdentity CURSOR FAST_FORWARD FOR ' + 
	    'SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME ' + 
	    'FROM ' + @database + '.INFORMATION_SCHEMA.COLUMNS; ');

-- loop through all the column names in the database
OPEN curIsIdentity;
	FETCH NEXT FROM curIsIdentity INTO @schema, @table, @column;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- if the column is identity, then insert the info into the temp table
		EXECUTE('USE ' + @database + '; ' +
                'IF (SELECT COLUMNPROPERTY(OBJECT_ID(''' + @database + '.' + @schema + '.' + @table + '''), ''' + @column + ''',''IsIdentity'')) = 1 ' +
			        'INSERT INTO #IdentityColumns ([database],[schema],[table],[column],[IsIdentity],[LastIdentityValue],[IncrementValue],[NextValue]) ' +
                    'SELECT ' +
                        '''' + @database + ''', ' +
                        '''' + @schema + ''', ' +
                        '''' + @table + ''', ' +
                        '''' + @column + ''', ' +
                        '''TRUE'', ' +
                        'IDENT_CURRENT(''' + @database + '.' + @schema + '.' + @table + '''), ' +
                        'IDENT_INCR(''' + @database + '.' +  @schema + '.' + @table + '''), ' +
                        'IDENT_CURRENT(''' + @database + '.' + @schema + '.' + @table + ''') + IDENT_INCR(''' + @database + '.' + @schema + '.' + @table + '''); ');

		FETCH NEXT FROM curIsIdentity INTO @schema, @table, @column;
	END
CLOSE curIsIdentity;
DEALLOCATE curIsIdentity;

-- get the info
SELECT * 
FROM #IdentityColumns 
ORDER BY 1,2,3;

-- clean up
IF OBJECT_ID('tempdb..#IdentityColumns') IS NOT NULL
	DROP TABLE #IdentityColumns;

