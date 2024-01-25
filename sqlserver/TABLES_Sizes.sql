/**********************************************************************************************
* 
* TABLES_Sizes.sql
* 
* Author: James Lutsey (sections of code used from sp_spaceused)
* Date: 07/20/2016
* 
* Purpose: Get the size info for all tables in a database
* 
* Notes: 
*     1. Enter the database in the use statement you want to check
*     2. You can select the results in KB, MB, or GB (MB is the default)
* 
**********************************************************************************************/

-- enter the database to check
-- SELECT 'USE ' + QUOTENAME([name]) + ';' FROM [sys].[databases] ORDER BY [name];



DECLARE 
	  @id            BIGINT
	, @schemaname    SYSNAME
	, @tablename     SYSNAME
	, @pages         BIGINT
	, @reservedpages BIGINT
	, @rowCount      BIGINT
	, @usedpages     BIGINT;

-- table variable to hold the info for each table
DECLARE @tblTableSizes TABLE
(
	[server_name]   NVARCHAR(128) NOT NULL,
	[schema_name]   SYSNAME NOT NULL,
	[database_name] SYSNAME NOT NULL,
	[table_name]    SYSNAME NOT NULL,
	[row_count]     INT     NOT NULL,
	[reserved_kb]   BIGINT  NOT NULL,
	[data_kb]       BIGINT  NOT NULL,
	[index_kb]      BIGINT  NOT NULL,
	[unused_kb]     BIGINT  NOT NULL
);


---------------------------------------------------------
--//  GET TABLE SIZE INFO                            //--
---------------------------------------------------------

-- all the base tables in the database
DECLARE curTables CURSOR LOCAL FAST_FORWARD FOR
	SELECT   [object_id],
		SCHEMA_NAME([schema_id]),
		[name]
	FROM     [sys].[tables] 
	WHERE    [type] = 'U';

OPEN curTables;
	FETCH NEXT FROM curTables INTO @id, @schemaname, @tablename;

	-- loop through all the tables
	WHILE @@FETCH_STATUS = 0
	BEGIN
		--Now calculate the summary data. 
		--Note that LOB Data and Row-overflow Data are counted as Data Pages.
        SELECT @reservedpages = SUM ([reserved_page_count]),
               @usedpages     = SUM ([used_page_count]),
               @pages         = SUM(   CASE
                                           WHEN ([index_id] < 2) THEN ([in_row_data_page_count] + [lob_used_page_count] + [row_overflow_used_page_count])
                                           ELSE [lob_used_page_count] + [row_overflow_used_page_count]
                                       END
                                   ),
               @rowCount      = SUM(   CASE
                                           WHEN ([index_id] < 2) THEN [row_count]
                                           ELSE 0
                                       END
                                   )
        FROM   [sys].[dm_db_partition_stats]
        WHERE  [object_id] = @id;

		
		--Check if table has XML Indexes or Fulltext Indexes which use internal tables tied to this table
		IF EXISTS(SELECT 1 FROM [sys].[internal_tables] WHERE [parent_id] = @id AND [internal_type] IN (202,204,211,212,213,214,215,216))
		BEGIN
			--Now calculate the summary data. Row counts in these internal tables don't contribute towards row count of original table.
			SELECT     @reservedpages = @reservedpages + SUM([p].[reserved_page_count]),
				       @usedpages     = @usedpages + SUM([p].[used_page_count])
			FROM       [sys].[dm_db_partition_stats] AS [p]
            INNER JOIN [sys].[internal_tables]       AS [it] ON [it].[object_id] = [p].[object_id]
			WHERE      it.parent_id = @id 
                       AND it.internal_type IN (202,204,211,212,213,214,215,216);
		END

		-- put the info for this table into the temp table
		INSERT INTO @tblTableSizes ([server_name], [database_name], [schema_name], [table_name], [row_count], [reserved_kb], [data_kb], [index_kb], [unused_kb])
		SELECT CONVERT(NVARCHAR(128),SERVERPROPERTY('ServerName')),
               DB_NAME(),
               @schemaname,
               @tablename,
               @rowCount,
               @reservedpages * 8,
               @pages * 8,
               (CASE WHEN @usedpages > @pages THEN (@usedpages - @pages) ELSE 0 END) * 8,
               (CASE WHEN @reservedpages > @usedpages THEN (@reservedpages - @usedpages) ELSE 0 END) * 8;

		FETCH NEXT FROM curTables INTO @id, @schemaname, @tablename;
	END
CLOSE curTables;
DEALLOCATE curTables;


---------------------------------------------------------
--//  DISPLAY THE RESULTS                            //--
---------------------------------------------------------

SELECT
	  server_name
	, database_name
	, schema_name
	, table_name
	, row_count
	, CAST(ROUND(reserved_kb / 1024.0, 0) AS INT) AS [reserved_mb]
	, CAST(ROUND(data_kb     / 1024.0, 0) AS INT) AS [data_mb]
	, CAST(ROUND(index_kb    / 1024.0, 0) AS INT) AS [index_mb]
	, CAST(ROUND(unused_kb   / 1024.0, 0) AS INT) AS [unused_mb]
	, CAST(ROUND(reserved_kb / 1024.0 / 1024.0, 0) AS INT) AS 'reserved_gb'
	, CAST(ROUND(data_kb     / 1024.0 / 1024.0, 0) AS INT) AS 'data_gb'
	, CAST(ROUND(index_kb    / 1024.0 / 1024.0, 0) AS INT) AS 'index_gb'
	, CAST(ROUND(unused_kb   / 1024.0 / 1024.0, 0) AS INT) AS 'unused_gb'
FROM
	@tblTableSizes
ORDER BY
	  schema_name
	, table_name;