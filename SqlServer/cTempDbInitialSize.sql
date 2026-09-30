USE tempdb;



DECLARE @DisplayUnits VARCHAR(2) = 'GB';  /* KB, MB, GB, TB */


/* set the size conversion value based on the desired units */
DECLARE @ConversionValueFromPages DECIMAL(19,3);
IF      @DisplayUnits = 'KB' SET @ConversionValueFromPages = 1.0 / 8.0;
ELSE IF @DisplayUnits = 'MB' SET @ConversionValueFromPages = 1.0 / 8.0 * 1024.0;
ELSE IF @DisplayUnits = 'GB' SET @ConversionValueFromPages = 1.0 / 8.0 * 1024.0 * 1024.0;
ELSE IF @DisplayUnits = 'TB' SET @ConversionValueFromPages = 1.0 / 8.0 * 1024.0 * 1024.0 * 1024.0;




SELECT
	  DB_NAME() as 'Database'
	, df.name as 'File'
	--, df.type_desc
	--, df.physical_name
	, CAST(ROUND(df.size / @ConversionValueFromPages, 1) AS DECIMAL(19,1)) AS CurrentSize
	, CAST(ROUND(mf.size / @ConversionValueFromPages, 1) AS DECIMAL(19,1)) AS InitialSize
	, CAST(ROUND((df.size - mf.size) / @ConversionValueFromPages, 1) AS DECIMAL(19,1)) AS SizeDifference
	, @DisplayUnits AS DisplayUnits
FROM	
	tempdb.sys.database_files df
LEFT OUTER JOIN
	sys.master_files mf
	ON df.name = mf.name
ORDER BY 
	df.name;





