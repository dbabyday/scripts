/**************************************************************************************
*
*  Author:  James Lutsey
*  Date:    12/15/2015
*  Purpose: Shows the expected growth for databases on an instance
*  
*  Enter:   server name (line 34)
*           database name for details from each backup (line 35)
*
*  Run on:  CO-DB-042
*
**************************************************************************************/

IF @@servername != 'CO-DB-042'
BEGIN
	RAISERROR('Wrong server. Change connection to CO-DB-042.', 16, 1);
	RETURN;
END

DECLARE 
    @FirstDate          DATETIME,
    @FirstSize          NUMERIC(20,10),
    @LastDate           DATETIME,
    @LastSize           NUMERIC(20,10),
    @AveDailyGrowth     NUMERIC(20,10),
    @ThreeMonths        NUMERIC(20,10),
    @SixMonths          NUMERIC(20,10),
	@TwelveMonths		NUMERIC(20,10),
    @db_name            VARCHAR(256),
    @server             VARCHAR(256),
	@selectedDB			VARCHAR(256),
	@errorMessage		VARCHAR(MAX);

SET @server = '';  -- enter server name
SET @selectedDB = '';  -- enter database name

IF (@server = '')
BEGIN
	SET @errorMessage = 'You must specify a server (line 34).';
	RAISERROR(@errorMessage,16,1);
	RETURN
END

IF OBJECT_ID('tempdb..#DatabaseGrowth') IS NOT NULL
	DROP TABLE #DatabaseGrowth
IF OBJECT_ID('tempdb..#GrowthDetails') IS NOT NULL
	DROP TABLE #GrowthDetails

CREATE TABLE #DatabaseGrowth
(
    [server]                VARCHAR(256),
    [db_name]               VARCHAR(256),
	[BackupDate]			DATETIME,
    [Size(MB)]              NUMERIC(20,10),
    [AveDailyGrowth(MB)]    NUMERIC(20,10),
    [3_Months(MB)]          NUMERIC(20,10),
    [6_Months(MB)]          NUMERIC(20,10),
	[12_Months(MB)]			NUMERIC(20,10)
);

CREATE TABLE #GrowthDetails
(
	[db_name]				VARCHAR(256),
	[BackupDate]			DATETIME, 
	[Size(MB)]				NUMERIC(20,10),
	[GrowthPerDay(MB)]		NUMERIC(20,10)
);

DECLARE growth_cursor CURSOR FOR
SELECT DISTINCT
    [database_name] 
FROM 
    [CentralAdmin].[dbo].[DatabaseBackupListHistory]
WHERE 
    [SqlServerName] = @server

OPEN growth_cursor

FETCH NEXT FROM growth_cursor
INTO @db_name

WHILE @@FETCH_STATUS = 0
BEGIN
    -- put database backup dates and sizes into a temp table
	IF OBJECT_ID('tempdb..#BackupSizes') IS NOT NULL
		DROP TABLE #BackupSizes

    SELECT 
        [backup_finish_date], [BackupSizeInBytes] 
    INTO 
        [#BackupSizes]
    FROM 
        [CentralAdmin].[dbo].[DatabaseBackupListHistory]
    WHERE   
        [SqlServerName] = @server 
        AND [database_name] = @db_name 
        AND [backup_type]   = 'Database' -- 'Database', 'Diff', or 'Log'
    GROUP BY 
        [SqlServerName],
        [database_name],
        [backup_type],
        [backup_finish_date],
        [BackupSizeInBytes]
    ORDER BY 
        [SqlServerName],
        [database_name],
        [backup_type],
        [backup_finish_date];

    -- get the first and last backup dates and sizes
    SELECT TOP 1
        @FirstDate = [backup_finish_date],
        @FirstSize = [BackupSizeInBytes] / 1024 / 1024  -- MB
    FROM 
        [#BackupSizes]
    ORDER BY 
        [backup_finish_date] ASC;

    SELECT TOP 1
        @LastDate = [backup_finish_date],
        @LastSize = [BackupSizeInBytes] / 1024 / 1024   -- MB
    FROM 
        [#BackupSizes]
    ORDER BY 
        [backup_finish_date] DESC;

    -- do the math
    IF DATEDIFF(DAY,@FirstDate,@LastDate) <> 0
    BEGIN
        SELECT @AveDailyGrowth = ( @LastSize - @FirstSize ) / DATEDIFF(DAY,@FirstDate,@LastDate);
        SELECT @ThreeMonths = ( @LastSize - @FirstSize ) / DATEDIFF(DAY,@FirstDate,@LastDate) * ( 365.25 / 4 );
        SELECT @SixMonths = @ThreeMonths * 2;
		SELECT @TwelveMonths = @ThreeMonths * 4;
    END

    -- put the results for individual database into temp table
    INSERT INTO [#DatabaseGrowth] ([server], [db_name], [BackupDate], [Size(MB)], [AveDailyGrowth(MB)], [3_Months(MB)], [6_Months(MB)], [12_Months(MB)])
    VALUES (@server, @db_name, @LastDate, @LastSize, @AveDailyGrowth, @ThreeMonths, @SixMonths, @TwelveMonths)
        
	-- get the details for the selected database
	IF (@selectedDB = @db_name)
	BEGIN
		DECLARE 
			@backupDate1	DATETIME, 
			@backupDate2	DATETIME,
			@size1			DECIMAL(19,7),
			@size2			DECIMAL(19,7);

		SET @backupDate2 = NULL;

		DECLARE details_cursor CURSOR FOR
		SELECT 
			[backup_finish_date], [BackupSizeInBytes] 
		FROM 
			[#BackupSizes]

		OPEN details_cursor

		FETCH NEXT FROM details_cursor
		INTO @backupDate1, @size1

		INSERT INTO [#GrowthDetails] ( [db_name], [BackupDate], [Size(MB)] )
		VALUES ( @selectedDB, @backupDate1, @size1 / 1024 / 1024 )

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @size1 = @size1 / 1024 /1024;	-- MB

			IF DATEDIFF(SECOND, @backupDate2, @backupDate1) <> 0
			BEGIN
				INSERT INTO [#GrowthDetails] ( [db_name], [BackupDate], [Size(MB)], [GrowthPerDay(MB)] )
				VALUES ( @selectedDB, @backupDate1, @size1, (@size1 - @size2) / DATEDIFF(SECOND, @backupDate2, @backupDate1) * 86400 )
			END

			SET @backupDate2 = @backupDate1;
			SET @size2 = @size1;				-- MB
	
			FETCH NEXT FROM details_cursor
			INTO @backupDate1, @size1
		END
		CLOSE details_cursor;
		DEALLOCATE details_cursor;

		-- select the details
		ALTER TABLE [#GrowthDetails] ALTER COLUMN [Size(MB)] NUMERIC(10,0);
		ALTER TABLE [#GrowthDetails] ALTER COLUMN [GrowthPerDay(MB)] NUMERIC(11,1);
	END

    FETCH NEXT FROM growth_cursor
    INTO @db_name
END
CLOSE growth_cursor;
DEALLOCATE growth_cursor; 


------------------------------------------------------------------------------------------
--// DISPLAY THE RESULTS FOR THE SELECTED DATABASE                                    //--
------------------------------------------------------------------------------------------
IF (@selectedDB <> '')
BEGIN
	SELECT
		--[server],
		[db_name],
		CONVERT(VARCHAR, [BackupDate] ,101) AS [BackupDate],
		CAST([Size(MB)] AS NUMERIC(10,0)) AS [Size(MB)],
		CAST([AveDailyGrowth(MB)] AS NUMERIC(11,1)) AS [AveDailyGrowth(MB)],
		CAST([3_Months(MB)] AS NUMERIC(10,0)) AS [3_Months(MB)],
		CAST([6_Months(MB)] AS NUMERIC(10,0)) AS [6_Months(MB)],
		CAST([12_Months(MB)] AS NUMERIC(10,0)) AS [12_Months(MB)]
	FROM
		[#DatabaseGrowth]
	WHERE
		[db_name] = @SelectedDB;
END


------------------------------------------------------------------------------------------
--// DISPLAY THE DETAILED RESULTS FOR THE SELECTED DATABSASE                          //--
------------------------------------------------------------------------------------------
IF (@selectedDB <> '')
BEGIN
	SELECT 
		[db_name],
		CONVERT(VARCHAR, [BackupDate] ,101) AS [BackupDate], 
		[Size(MB)],
		[GrowthPerDay(MB)]
	FROM 
		[#GrowthDetails];
END

/*
------------------------------------------------------------------------------------------
--// DISPLAY THE RESUTLS FOR EACH DATABASE                                            //--
------------------------------------------------------------------------------------------
SELECT
    --[server],
	[db_name],
	CONVERT(VARCHAR, [BackupDate] ,101) AS [BackupDate],
	CAST([Size(MB)] AS NUMERIC(10,0)) AS [Size(MB)],
	CAST([AveDailyGrowth(MB)] AS NUMERIC(11,1)) AS [AveDailyGrowth(MB)],
	CAST([3_Months(MB)] AS NUMERIC(10,0)) AS [3_Months(MB)],
	CAST([6_Months(MB)] AS NUMERIC(10,0)) AS [6_Months(MB)],
	CAST([12_Months(MB)] AS NUMERIC(10,0)) AS [12_Months(MB)]
FROM
    [#DatabaseGrowth]
ORDER BY
    [db_name];

	
------------------------------------------------------------------------------------------
--// DISPLAY THE SUM OF ALL DATABASES                                                 //--
------------------------------------------------------------------------------------------
SELECT
    [server],
    CAST(SUM([Size(MB)]) AS NUMERIC(10,0)) AS [Total_Size(MB)],
    CAST(SUM([AveDailyGrowth(MB)]) AS NUMERIC(11,1)) AS [Total_AveDailyGrowth(MB)],
    CAST(SUM([3_Months(MB)]) AS NUMERIC(10,0)) AS [Total_3_Months(MB)],
    CAST(SUM([6_Months(MB)]) AS NUMERIC(10,0)) AS [Total_6_Months(MB)],
    CAST(SUM([12_Months(MB)]) AS NUMERIC(10,0)) AS [Total_12_Months(MB)]
FROM
    [#DatabaseGrowth]
--WHERE
--    [db_name] IN (		-- to find the growth of a drive, insert the list of databases here
					
							/* -- run this query on the server in question to get a list of databases on a drive
								select distinct db_name(database_id)
								from master.sys.master_files
								where physical_name like 'F:\%'
							*/
--				 )
GROUP BY
    [server];

*/
------------------------------------------------------------------------------------------
--// CLEAN UP                                                                         //--
------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#DatabaseGrowth') IS NOT NULL
	DROP TABLE #DatabaseGrowth;
IF OBJECT_ID('tempdb..#BackupSizes') IS NOT NULL
	DROP TABLE #BackupSizes;
IF OBJECT_ID('tempdb..#GrowthDetails') IS NOT NULL
	DROP TABLE #GrowthDetails;


