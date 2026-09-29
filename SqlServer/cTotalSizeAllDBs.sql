
/*

cTotalSizeAllDBs.sql

Description: Get size of user databases used space

Date        Who          What
==========  ===========  ===================================================
2025-01-29  dbabyday     Initial script


*/

DROP TABLE IF EXISTS #DbUsedSpace;
CREATE TABLE #DbUsedSpace (DatabaseName SYSNAME, UsedPages BIGINT);



DECLARE
	  @DatabaseName SYSNAME
	, @SqlString NVARCHAR(4000);

DECLARE cur_Databases CURSOR LOCAL FAST_FORWARD FOR
	SELECT name
	FROM sys.databases
	WHERE
		database_id>4
		AND state=0;

OPEN cur_Databases;
	FETCH NEXT FROM cur_Databases INTO @DatabaseName;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @SqlString = N'/* Dynaic SQL to get used space for all user databases */
		
		USE [' + @DatabaseName + N'];
				
		INSERT INTO #DbUsedSpace (DatabaseName, UsedPages)
		SELECT ''' + @DatabaseName + N''', SUM(allocated_extent_page_count)
		FROM sys.dm_db_file_space_usage;';

		EXECUTE sp_executesql @SqlString;

		FETCH NEXT FROM cur_Databases INTO @DatabaseName;
	END;
CLOSE cur_Databases;
DEALLOCATE cur_Databases;



SELECT
	  @@SERVERNAME AS ServerName
	, SYSDATETIMEOFFSET() AS EntryTime
	, CAST(ROUND(SUM(UsedPages) / 131072.000, 1) AS DECIMAL(19,1)) AS UsedGB
FROM #DbUsedSpace




/* Reference */
SELECT '1 - 150 GB' AS Size, 'easy to handle on Standard Edition' AS Difficulty
UNION ALL
SELECT '150 - 500 GB' AS Size, 'easy to hanlde with Enterprise Edition' AS Difficulty
UNION ALL
SELECT 'Over 500 GB' AS Size, 'matters if it is active data and how accessed (OLTP vs Analytical)' AS Difficulty
UNION ALL
SELECT 'Over 1TB OLTP data' AS Size, 'starts to get very challenging' AS Difficulty
UNION ALL
SELECT '100 TB, 10-12K databases per server' AS Size, 'Very uncomfortable' AS Difficulty;



DROP TABLE IF EXISTS #DbUsedSpace;


