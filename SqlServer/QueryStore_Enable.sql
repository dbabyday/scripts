/*

ALTER DATABASE [DBName] SET QUERY_STORE = OFF;

*/


IF @@SERVERNAME <> N'ACC-SQL-PD-015'
BEGIN
    RAISERROR('wrong server - skipping execution',16,1) WITH NOWAIT;
    RETURN;
END;


USE master;
GO


DECLARE
	  @TheDb nvarchar(128)
	, @SqlStmt nvarchar(max);



DECLARE curDbsForQueryStore CURSOR LOCAL FAST_FORWARD FOR
	SELECT the_db
	FROM (
		VALUES
			(N'Wms_Bgk1_PROD'), (N'Wms_Brg_PROD'), (N'Wms_Config_APAC_PROD'), (N'Wms_Config_Bgk1_PROD'), 
			(N'Wms_Config_Brg_PROD'), (N'Wms_Hil_PROD'), (N'WMS_Isl_PROD'), (N'Wms_Operational_Reporting_PROD'), 
			(N'Wms_Riv_PROD'), (N'Wms_Rve_PROD'), (N'Wms_Sea_PROD'), (N'Wms_Sng_PROD'), (N'WmsArchive_APAC_PROD')
	) AS tbl(the_db);




OPEN curDbsForQueryStore;
	FETCH NEXT FROM curDbsForQueryStore INTO @TheDb;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @SqlStmt = N'
ALTER DATABASE [' + @TheDb + N']
SET QUERY_STORE = ON (
	  OPERATION_MODE = READ_WRITE
	, CLEANUP_POLICY = ( STALE_QUERY_THRESHOLD_DAYS = 30 )
	, DATA_FLUSH_INTERVAL_SECONDS = 900
	, MAX_STORAGE_SIZE_MB = 2000
	, INTERVAL_LENGTH_MINUTES = 60
	, QUERY_CAPTURE_MODE = AUTO
	, SIZE_BASED_CLEANUP_MODE = AUTO
	, MAX_PLANS_PER_QUERY = 200
);';
		
		EXECUTE sp_executesql @SqlStmt;

		FETCH NEXT FROM curDbsForQueryStore INTO @TheDb;
	END;
CLOSE curDbsForQueryStore;
DEALLOCATE curDbsForQueryStore;




GO