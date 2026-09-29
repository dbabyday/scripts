/**********************************************************************************************************

cTableSizes.sql

Author: dbabyday
Date: 

Purpose: Shows the size of tables

Date        Name        Description
----------  ----------  ----------------------------------------------------------------------------------
2025-12-03  dbabyday    Initial creation

**********************************************************************************************************/




DECLARE @DisplayUnits VARCHAR(2) = 'GB';  /* KB, MB, GB, TB */





/* size conversion values */
DECLARE
	  @ConversionValueFromBytes DECIMAL(19,3)
	, @ConversionValueFromPages DECIMAL(19,3);
/* set the size conversion value based on the desired units */
IF @DisplayUnits = 'KB' 
	SET @ConversionValueFromBytes = 1024.0;
ELSE IF @DisplayUnits = 'MB'
	SET @ConversionValueFromBytes = 1024.0 * 1024.0;
ELSE IF @DisplayUnits = 'GB'
	SET @ConversionValueFromBytes = 1024.0 * 1024.0 * 1024.0;
ELSE IF @DisplayUnits = 'TB'
	SET @ConversionValueFromBytes = 1024.0 * 1024.0 * 1024.0 * 1024.0;
/* set the value for units that report in 8K pages */
SET @ConversionValueFromPages = @ConversionValueFromBytes / 1024.0 / 8.0;






SELECT 
	  OBJECT_SCHEMA_NAME(t.object_id) + '.' + t.name AS TableName
	, SUM(p.rows) AS RowCounts
	, CAST(ROUND(SUM(a.total_pages) / @ConversionValueFromPages, 1) AS DECIMAL(19,1)) AS TotalSpace
	, CAST(ROUND(SUM(CASE WHEN i.index_id >= 2 THEN a.used_pages ELSE 0 END) / @ConversionValueFromPages, 1) AS DECIMAL(19,1)) AS IndexSpace
	, CAST(ROUND(SUM(CASE WHEN i.index_id < 2 THEN a.used_pages ELSE 0 END) / @ConversionValueFromPages, 1) AS DECIMAL(19,1)) AS DataSpace
	, CAST(ROUND(SUM(a.used_pages) / @ConversionValueFromPages, 1) AS DECIMAL(19,1)) AS UsedSpace
	, @DisplayUnits AS DisplayUnits
	, t.is_ms_shipped
FROM 
	sys.tables t
INNER JOIN      
	sys.indexes i ON t.object_id = i.object_id
INNER JOIN 
	sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN 
	sys.allocation_units a ON p.partition_id = a.container_id
--WHERE 
--	t.is_ms_shipped = 0  -- Excludes system tables
--	t.name IN (N'', N'')
GROUP BY 
	  t.name
	, t.object_id
	, t.is_ms_shipped
ORDER BY 
	TotalSpace DESC;
	--TableName;