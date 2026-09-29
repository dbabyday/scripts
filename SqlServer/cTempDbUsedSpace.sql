use tempdb;


DECLARE @DisplayUnits VARCHAR(2) = 'GB';  /* KB, MB, GB, TB */


/* set the size conversion value based on the desired units */
DECLARE @ConversionValueFromPages DECIMAL(19,3);
IF      @DisplayUnits = 'KB' SET @ConversionValueFromPages = 1.0 / 8.0;
ELSE IF @DisplayUnits = 'MB' SET @ConversionValueFromPages = 1.0 / 8.0 * 1024.0;
ELSE IF @DisplayUnits = 'GB' SET @ConversionValueFromPages = 1.0 / 8.0 * 1024.0 * 1024.0;
ELSE IF @DisplayUnits = 'TB' SET @ConversionValueFromPages = 1.0 / 8.0 * 1024.0 * 1024.0 * 1024.0;




SELECT 
	  CAST(ROUND(SUM(total_page_count)                    / @ConversionValueFromPages, 1) AS DECIMAL(19,1)) AS Size
	, CAST(ROUND(SUM(unallocated_extent_page_count)       / @ConversionValueFromPages, 1) AS DECIMAL(19,1)) AS FreeSpace
	, CAST(ROUND(SUM(allocated_extent_page_count)         / @ConversionValueFromPages, 1) AS DECIMAL(19,1)) AS UsedSpace
	, CAST(ROUND(SUM(allocated_extent_page_count) * 1.0 / SUM(total_page_count) * 100, 0) AS INT)           AS PercentUsed
	, CAST(ROUND(SUM(version_store_reserved_page_count)   / @ConversionValueFromPages, 1) AS DECIMAL(19,1)) AS VersionStore
	, CAST(ROUND(SUM(internal_object_reserved_page_count) / @ConversionValueFromPages, 1) AS DECIMAL(19,1)) AS InternalObjects
	, CAST(ROUND(SUM(user_object_reserved_page_count)     / @ConversionValueFromPages, 1) AS DECIMAL(19,1)) AS UserObjects
	, @DisplayUnits AS DisplayUnits
FROM
	sys.dm_db_file_space_usage;