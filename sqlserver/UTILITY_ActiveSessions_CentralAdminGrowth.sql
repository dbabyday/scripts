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
USE [CentralAdmin]; -- select name from sys.databases order by name 
GO

DECLARE 

	-- other variables
	@id	           BIGINT,
	@objname       NVARCHAR(776),
	@pages	       BIGINT,
	@reservedpages BIGINT,
	@rowCount      BIGINT,
	@usedpages     BIGINT,
	
	@hours         INT,
	@mb            INT;
		
-- table variable to hold the info for each table
DECLARE @tblTableSizes TABLE
(
	[server_name]   VARCHAR(128),
	[database_name] VARCHAR(128),
	[table_name]    SYSNAME ,
	[row_count]     INT,
	[reserved_kb]   BIGINT,
	[data_kb]       BIGINT,
	[index_kb]      BIGINT,
	[unused_kb]     BIGINT
);


---------------------------------------------------------
--//  GET TABLE SIZE INFO                            //--
---------------------------------------------------------

-- all the base tables in the database
DECLARE curTables CURSOR FAST_FORWARD FOR
	SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME;

OPEN curTables;
	FETCH NEXT FROM curTables INTO @objname;

	-- loop through all the tables
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @id = object_id FROM sys.objects WHERE name = @objname;
		
		--Now calculate the summary data. 
		--Note that LOB Data and Row-overflow Data are counted as Data Pages.
		SELECT 
			@reservedpages = SUM (reserved_page_count),
			@usedpages = SUM (used_page_count),
			@pages = SUM (
				CASE
					WHEN (index_id < 2) THEN (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count)
					ELSE lob_used_page_count + row_overflow_used_page_count
				END
				),
			@rowCount = SUM (
				CASE
					WHEN (index_id < 2) THEN row_count
					ELSE 0
				END
				)
		FROM sys.dm_db_partition_stats
		WHERE object_id = @id;

		
		--Check if table has XML Indexes or Fulltext Indexes which use internal tables tied to this table
		IF (SELECT count(*) FROM sys.internal_tables WHERE parent_id = @id AND internal_type IN (202,204,211,212,213,214,215,216)) > 0 
		BEGIN
			
			--Now calculate the summary data. Row counts in these internal tables don't contribute towards row count of original table.
			SELECT 
				@reservedpages = @reservedpages + sum(reserved_page_count),
				@usedpages = @usedpages + sum(used_page_count)
			FROM sys.dm_db_partition_stats p, sys.internal_tables it
			WHERE it.parent_id = @id AND it.internal_type IN (202,204,211,212,213,214,215,216) AND p.object_id = it.object_id;
		END

		-- put the info for this table into the temp table
		INSERT INTO @tblTableSizes (server_name, database_name, table_name, row_count, reserved_kb, data_kb, index_kb, unused_kb)
		SELECT 
			@@SERVERNAME,
			DB_NAME(),
			@objname,
			@rowCount,
			@reservedpages * 8,
			@pages * 8,
			(CASE WHEN @usedpages > @pages THEN (@usedpages - @pages) ELSE 0 END) * 8,
			(CASE WHEN @reservedpages > @usedpages THEN (@reservedpages - @usedpages) ELSE 0 END) * 8

		FETCH NEXT FROM curTables INTO @objname;
	END
CLOSE curTables;
DEALLOCATE curTables;



SELECT @mb = SUM(CAST(ROUND(reserved_kb / 1024.0, 0) AS INT))
FROM @tblTableSizes
WHERE table_name IN ('ActiveSessions','ServerConnections');
		
SELECT TOP 1 @hours = DATEDIFF(HOUR,EntryDate,GETDATE())
FROM CentralAdmin.dbo.ActiveSessions
ORDER BY EntryDate ASC;

SELECT 
	[mb_now]        = @mb,
	[hours_so_far]  = @hours,
	[mb_per_hour]   = @mb*1.0/@hours,
	[mb_30_days]    = @mb*720.0/@hours,
	[mb_additional] = @mb*720.0/@hours - @mb;

