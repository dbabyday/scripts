/**************************************************************************************
*
* Author: James Lutsey
* Date: 02/24/2016
* 
* Purpose: Caclulates average file growth. 
* 
* Notes:
*     1. Connect and run on CO-DB-042
*     2. Enter the server, database, and file names (lines 46-48)
*        - OR - Paste WHERE clause from FILES_Info.sql (line 51) 
*
**************************************************************************************/

IF @@servername <> 'gcc-sql-pd-001'
BEGIN
    RAISERROR('Wrong server - connect to gcc-sql-pd-001',16,1);
    RETURN;
END

DECLARE 
	-- USER INPUTS
    @where			NVARCHAR(MAX) = '',
	    -- or --
	@server			NVARCHAR(128) = '',
	@database		NVARCHAR(128) = '',
	@file			NVARCHAR(128) = '',

	-- other variables
    @3months        INT,
    @6months        INT,
	@aveDailyGrowth	DECIMAL(37,13),
    @command		NVARCHAR(MAX),
    @date1			DATETIME,
    @date2			DATETIME,
	@firstDate		DATETIME,
	@firstUsed		DECIMAL(37,13),
    @growth         INT,
    @growthSelected INT,
    @id1			INT,
    @id2			INT,
	@lastDate		DATETIME,
	@lastUsed		DECIMAL(37,13),
    @message        VARCHAR(500),
    @size           INT,
    @sizeSelected   INT,
    @used1			DECIMAL(37,13),
    @used2			DECIMAL(37,13);


------------------------------------------------------------------------------------------
--// VALIDATE USER INPUTS                                                             //--
------------------------------------------------------------------------------------------

-- user must either enter a value for @where, or values for all 3: @server, @database, @file
IF ( (@where = '') AND (@server = '' OR @database = '' OR @file = '') )
BEGIN
    SET @message = 'Insufficient user inputs.' + CHAR(13) + CHAR(10);
    SET @message = @message + 'You must enter values for @server, @database, and @file (lines 46-48); OR paste the ''WHERE'' string from FILES_Info.sql into @where (line 51).';
    RAISERROR(@message,16,1);
    RETURN;
END

--  if user enters values for @where and all 3: @server, @database, @file; error because it is unknown which one they want to use
IF (@where != '' AND @server != '' AND @database != '' AND @file != '')
BEGIN 
    SET @message = 'Too many user inputs.' + CHAR(13) + CHAR(10);
    SET @message = @message + 'You must enter value for @server, @database, and @file (lines 46-48); OR paste the ''WHERE'' string from FILES_Info.sql into @where (line 51); but not both.';
    RAISERROR(@message,16,1);
    RETURN;
END

-- validate the @where input
IF (@where != '')
BEGIN
    -- check the format. if pasted from FILES_Info.sql, it should not be a problem
    IF 
    (
        LEFT(@where,17) != 'sqlservername = '''
        OR CHARINDEX(''' AND databasename = ''',@where) < 18
        OR CHARINDEX(''' AND DatabaseFileName = ''',@where) < 39
    )
    BEGIN
        SET @message = 'Incorrect format for @where (line 51).' + CHAR(13) + CHAR(10);
        SET @message = @message + '@where must use this format:' + CHAR(13) + CHAR(10);
        SET @message = @message + 'sqlservername = ''<server_name>'' AND databasename = ''<database_name>'' AND DatabaseFileName = ''<file_name>''';
        RAISERROR(@message,16,1);
        RETURN;
    END

    -- check if the server is here
    IF (NOT EXISTS(SELECT [SqlServerName] FROM [CentralAdmin].[dbo].[DatabaseSpaceUsedhistory] WHERE [SqlServerName] = SUBSTRING(@where,18,CHARINDEX(''' AND databasename',@where) - 18)))
    BEGIN
        SET @message = 'Invalid server.' + CHAR(13) + CHAR(10);
        SET @message = @message + 'The specified server, [' + SUBSTRING(@where,18,CHARINDEX(''' AND databasename',@where) - 18) + '], is not in this table. (line 51)';
        RAISERROR(@message,16,1);
        RETURN;
    END

    -- check if the database is here
    IF (NOT EXISTS(SELECT [DatabaseName] FROM [CentralAdmin].[dbo].[DatabaseSpaceUsedhistory] WHERE [DatabaseName] = SUBSTRING(@where,CHARINDEX('databasename = ',@where) + 16,CHARINDEX(''' AND DatabaseFileName',@where) - (CHARINDEX('databasename = ',@where) + 16))))
    BEGIN
        SET @message = 'Invalid database.' + CHAR(13) + CHAR(10);
        SET @message = @message + 'The specified database, [' + SUBSTRING(@where,CHARINDEX('databasename = ',@where) + 16,CHARINDEX(''' AND DatabaseFileName',@where) - (CHARINDEX('databasename = ',@where) + 16)) + '], is not in this table. (line 51)';
        RAISERROR(@message,16,1);
        RETURN;
    END

    -- check if the file is here
    IF (NOT EXISTS(SELECT [DatabaseFileName] FROM [CentralAdmin].[dbo].[DatabaseSpaceUsedhistory] WHERE [DatabaseFileName] = RIGHT(LEFT(@where,LEN(@where)-1),LEN(@where)-1 - (CHARINDEX(''' AND DatabaseFileName',@where) + 25))))
    BEGIN
        SET @message = 'Invalid file.' + CHAR(13) + CHAR(10);
        SET @message = @message + 'The specified file, [' + RIGHT(LEFT(@where,LEN(@where)-1),LEN(@where)-1 - (CHARINDEX(''' AND DatabaseFileName',@where) + 25)) + '], is not in this table. (line 51)';
        RAISERROR(@message,16,1);
        RETURN;
    END

    -- check if there is more than one record for the file
    IF ((SELECT COUNT(*) FROM [CentralAdmin].[dbo].[DatabaseSpaceUsedhistory] WHERE [DatabaseFileName] = RIGHT(LEFT(@where,LEN(@where)-1),LEN(@where)-1 - (CHARINDEX(''' AND DatabaseFileName',@where) + 25))) = 1)
    BEGIN
        SET @message = 'Only one record.' + CHAR(13) + CHAR(10);
        SET @message = @message + 'There is only one record for this file. There must be at least two to calculate file growth.';
        RAISERROR(@message,16,1);
        RETURN;
    END
END
ELSE -- @where = ''
BEGIN
    -- check if the server is here
    IF (@server != '')
    BEGIN
        IF (NOT EXISTS(SELECT [SqlServerName] FROM [CentralAdmin].[dbo].[DatabaseSpaceUsedhistory] WHERE [SqlServerName] = @server))
        BEGIN
            SET @message = 'Invalid server.' + CHAR(13) + CHAR(10);
            SET @message = @message + 'The specified server, [' + @server + '], is not in this table. (line 46)';
            RAISERROR(@message,16,1);
            RETURN;
        END
    END

    -- check if the database is here
    IF (@database != '')
    BEGIN
        IF (NOT EXISTS(SELECT [DatabaseName] FROM [CentralAdmin].[dbo].[DatabaseSpaceUsedhistory] WHERE [DatabaseName] = @database))
        BEGIN
            SET @message = 'Invalid database.' + CHAR(13) + CHAR(10);
            SET @message = @message + 'The specified database, [' + @database + '], is not in this table. (line 47)';
            RAISERROR(@message,16,1);
            RETURN;
        END
    END

    -- check if the file is here
    IF (@file != '')
    BEGIN
        IF (NOT EXISTS(SELECT [DatabaseFileName] FROM [CentralAdmin].[dbo].[DatabaseSpaceUsedhistory] WHERE [DatabaseFileName] = @file))
        BEGIN
            SET @message = 'Invalid file.' + CHAR(13) + CHAR(10);
            SET @message = @message + 'The specified file, [' + @file + '], is not in this table. (line 48)';
            RAISERROR(@message,16,1);
            RETURN;
        END
    END

    -- check if there is more than one record for the file
    IF ((SELECT COUNT(*) FROM [CentralAdmin].[dbo].[DatabaseSpaceUsedhistory] WHERE [DatabaseFileName] = @file) = 1)
    BEGIN
        SET @message = 'Only one record.' + CHAR(13) + CHAR(10);
        SET @message = @message + 'There is only one record for this file. There must be at least to to calculate file growth.';
        RAISERROR(@message,16,1);
        RETURN;
    END

    -- the user entered the server, database, and file; and all validation passed; so now we can...
    -- build the where clause based on the user inputs
    SET @where = 'sqlservername = ''' + @server + ''' AND databasename = ''' + @database + ''' AND DatabaseFileName = ''' + @file + '''';
END


------------------------------------------------------------------------------------------
--// TEMP TABLES                                                                      //--
------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#FileInfo') IS NOT NULL DROP TABLE #FileInfo;
CREATE TABLE #FileInfo
(
    [ID]				INT IDENTITY(1,1) PRIMARY KEY,
    [Server]			VARCHAR(256),
    [Database]			VARCHAR(255),
    [File]				VARCHAR(256),
    [EntryDate]			DATETIME,
    [Size_MB]			DECIMAL(37,13),
    [Used_MB]           DECIMAL(37,13),
    [AveDailyGrowth]    DECIMAL(37,13)
);

IF OBJECT_ID('tempdb..#FileSizes') IS NOT NULL DROP TABLE #FileSizes;
CREATE TABLE #FileSizes
(
    [SizeMB]   INT PRIMARY KEY,
    [GrowthMB] INT
);


------------------------------------------------------------------------------------------
--// POPULATE #FileSizes WITH STANDARD FILE AND GROWTH SIZES                          //--
------------------------------------------------------------------------------------------

SET @growth = 4;
SET @size = 4;
SET @command = N'INSERT INTO #FileSizes ([SizeMB], [GrowthMB])' + CHAR(13) + CHAR(10) + 'VALUES ';

WHILE @size < 1048576 -- 1048576 MB = 1 TB
BEGIN
    SET @command = @command + N'(' + CAST(@size AS NVARCHAR(7)) + N',' + CAST(@growth AS NVARCHAR(7)) + '),';
    SET @size = @size + @growth;
    
    IF (@size = 32) OR (@size = 64) OR (@size = 128) OR (@size = 256) OR (@size = 512) OR (@size = 1024) OR (@size = 2048) OR (@size = 4096) OR (@size = 8192)
    BEGIN
        SET @growth = @growth * 2;
        SET @command = @command + CHAR(13) + CHAR(10) + '       ';
    END
END 

SET @command = @command + N'(' + CAST(@size AS NVARCHAR(7)) + N',' + CAST(@growth AS NVARCHAR(7)) + ');'

EXECUTE(@command);


------------------------------------------------------------------------------------------
--// INSERT FILE INFO INTO TABLE VARIABLE                                             //--
------------------------------------------------------------------------------------------

-- build insert command that uses the where criteria entered by user
SET @command = '
INSERT INTO #FileInfo ([Server], [Database], [File], [EntryDate], [Size_MB], [Used_MB])
SELECT 
    [SqlServerName],
    [DatabaseName],
    [DatabaseFileName],
    [EntryDate],
    [FileSizeMb],
    [FileSpaceUsedMb]
FROM   
    [CentralAdmin].[dbo].[DatabaseSpaceUsedhistory]
WHERE 
    ' + @where + '
UNION
SELECT 
    [SqlServerName],
    [DatabaseName],
    [DatabaseFileName],
    [EntryDate],
    [FileSizeMb],
    [FileSpaceUsedMb]
FROM   
    [CentralAdmin].[dbo].[DatabaseSpaceUsed]
WHERE 
    ' + @where + '
ORDER BY  
    [EntryDate] DESC'

-- insert file info info #FileInfo
EXECUTE(@command);


------------------------------------------------------------------------------------------
--// CALCULATE THE AVERAGE DAILY GROWTH FOR THE TIMESPAN OF THE RECORDS               //--
------------------------------------------------------------------------------------------

-- get the first date and used size
SELECT TOP 1
	@firstDate = [EntryDate],
	@firstUsed = [Used_MB]
FROM 
    #FileInfo
ORDER BY 
    [EntryDate] ASC;

-- get the last date and used size
SELECT TOP 1
	@lastDate = [EntryDate],
	@lastUsed = [Used_MB]
FROM 
    #FileInfo
ORDER BY 
    [EntryDate] DESC;

-- do the math
SET @aveDailyGrowth = (@firstUsed - @lastUsed) / DATEDIFF(SECOND, @lastDate, @firstDate) * 86400;


------------------------------------------------------------------------------------------
--// CALCULATE THE AVERAGE DAILY GROWTH BETWEEN EACH ENTRY                            //--
------------------------------------------------------------------------------------------

-- loop through all entries
DECLARE curGrowth CURSOR FAST_FORWARD FOR
    SELECT [ID], [EntryDate], [Used_MB]
    FROM #FileInfo
    ORDER BY [EntryDate] DESC;
OPEN curGrowth;
    FETCH NEXT FROM curGrowth INTO @id1, @date1, @used1;
    FETCH NEXT FROM curGrowth INTO @id2, @date2, @used2;

    WHILE (@@FETCH_STATUS = 0)
    BEGIN
        IF DATEDIFF(SECOND, @date2, @date1) <> 0 -- make sure it's not a duplicate time / avoid dividing by zero
        BEGIN
            -- do the math based on time in seconds for accuracy and convert it to the amount per day for easier comprehension
            UPDATE #FileInfo 
			SET [AveDailyGrowth] = (@used1 - @used2) / DATEDIFF(SECOND, @date2, @date1) * 86400 
			WHERE [ID] = @id1;
        END

        -- get the next set of data
        SET @id1 = @id2;
        SET @date1 = @date2;
        SET @used1 = @used2;
        FETCH NEXT FROM curGrowth INTO @id2, @date2, @used2;
    END
CLOSE curGrowth;
DEALLOCATE curGrowth;



------------------------------------------------------------------------------------------
--// BUILD THE ALTER DATABASE COMMAND                                                 //--
------------------------------------------------------------------------------------------

-- calculate the predicted sizes for 3 and 6 months
SELECT TOP 1 
	@3months = CAST((([Used_MB] + @aveDailyGrowth * 90) / 0.9) AS INT),
	@6months = CAST((([Used_MB] + @aveDailyGrowth * 180) / 0.9) AS INT)
FROM 
	#FileInfo
ORDER BY
	[EntryDate] DESC;

-- choose the largest standard size between the 3-6 month sizes
IF EXISTS(SELECT [SizeMB] FROM #FileSizes WHERE [SizeMB] >= @3months AND [SizeMB] <= @6months)
    SELECT TOP 1 @sizeSelected = [SizeMB], @growthSelected = [GrowthMB]
    FROM #FileSizes
    WHERE [SizeMB] <= @6months
    ORDER BY [SizeMB] DESC;
ELSE  -- no standard size between the 3-6 month sizes, so use the next standard size greater than the 6 month size
    SELECT TOP 1 @sizeSelected = [SizeMB], @growthSelected = [GrowthMB]
    FROM #FileSizes
    WHERE [SizeMB] > @6months
    ORDER BY [SizeMB] ASC;

SELECT @command = N'ALTER DATABASE ' + QUOTENAME([Database]) + N' MODIFY FILE ( NAME = N''' + [FILE] + N''', SIZE = ' + CAST(@sizeSelected AS NVARCHAR(10)) + N'MB, FILEGROWTH = ' + CAST(@growthSelected AS NVARCHAR(10)) + N'MB );'
FROM #FileInfo;


------------------------------------------------------------------------------------------
--// DISPLAY THE RESULTS                                                              //--
------------------------------------------------------------------------------------------

-- results for the timespan of all the records
SELECT TOP 1
    [Server],
    [Database],
    [File],
	[Size_MB] = CASE
					WHEN LEN(CAST(CAST([Size_MB] AS INT) AS VARCHAR(27))) > 6 
						THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST([Size_MB] AS INT) AS VARCHAR(27))),7,0,','),4,0,','))
					WHEN LEN(CAST(CAST([Size_MB] AS INT) AS VARCHAR(27))) > 3 
						THEN REVERSE(STUFF(REVERSE(CAST(CAST([Size_MB] AS INT) AS VARCHAR(27))),4,0,','))
					ELSE CAST(CAST([Size_MB] AS INT) AS VARCHAR(27))
				END,
    [Used_MB] = CASE
                    WHEN LEN(CAST(CAST([Used_MB] AS INT) AS VARCHAR(27))) > 6 
                        THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST([Used_MB] AS INT) AS VARCHAR(27))),7,0,','),4,0,','))
                    WHEN LEN(CAST(CAST([Used_MB] AS INT) AS VARCHAR(27))) > 3 
                        THEN REVERSE(STUFF(REVERSE(CAST(CAST([Used_MB] AS INT) AS VARCHAR(27))),4,0,','))
                    ELSE CAST(CAST([Used_MB] AS INT) AS VARCHAR(27))
                END,
    -- used size + daily growth for 90 days + 10% free space
    [AveDailyGrowth] = LEFT(CAST(@aveDailyGrowth AS VARCHAR(37)),CHARINDEX('.',CAST(@aveDailyGrowth AS VARCHAR(37))) + 1),
    [3_months] = CASE
                    WHEN LEN(CAST(CAST((([Used_MB] + @aveDailyGrowth * 90) / 0.9) AS INT) AS VARCHAR(27))) > 6 
                        THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST((([Used_MB] + @aveDailyGrowth * 90) / 0.9) AS INT) AS VARCHAR(27))),7,0,','),4,0,','))
                    WHEN LEN(CAST(CAST((([Used_MB] + @aveDailyGrowth * 90) / 0.9) AS INT) AS VARCHAR(27))) > 3 
                        THEN REVERSE(STUFF(REVERSE(CAST(CAST((([Used_MB] + @aveDailyGrowth * 90) / 0.9) AS INT) AS VARCHAR(27))),4,0,','))
                    ELSE CAST(CAST((([Used_MB] + @aveDailyGrowth * 90) / 0.9) AS INT) AS VARCHAR(27))
                END,
    -- used size + daily growth for 180 days + 10% free space
    [6_months] = CASE
                    WHEN LEN(CAST(CAST((([Used_MB] + @aveDailyGrowth * 180) / 0.9) AS INT) AS VARCHAR(27))) > 6 
                        THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST((([Used_MB] + @aveDailyGrowth * 180) / 0.9) AS INT) AS VARCHAR(27))),7,0,','),4,0,','))
                    WHEN LEN(CAST(CAST((([Used_MB] + @aveDailyGrowth * 180) / 0.9) AS INT) AS VARCHAR(27))) > 3 
                        THEN REVERSE(STUFF(REVERSE(CAST(CAST((([Used_MB] + @aveDailyGrowth * 180) / 0.9) AS INT) AS VARCHAR(27))),4,0,','))
                    ELSE CAST(CAST((([Used_MB] + @aveDailyGrowth * 180) / 0.9) AS INT) AS VARCHAR(27))
                END,
    [AlterDatabaseCommand] = @command
FROM
    #FileInfo
ORDER BY
	[EntryDate] DESC;

-- dispaly results for each record
SELECT 
    [Server],
    [Database],
    [File],
    [EntryDate],
    [Size_MB] = CASE
					WHEN LEN(CAST(CAST([Size_MB] AS INT) AS VARCHAR(27))) > 6 
						THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST([Size_MB] AS INT) AS VARCHAR(27))),7,0,','),4,0,','))
					WHEN LEN(CAST(CAST([Size_MB] AS INT) AS VARCHAR(27))) > 3 
						THEN REVERSE(STUFF(REVERSE(CAST(CAST([Size_MB] AS INT) AS VARCHAR(27))),4,0,','))
					ELSE CAST(CAST([Size_MB] AS INT) AS VARCHAR(27))
				END,
    [Used_MB] = CASE
                    WHEN LEN(CAST(CAST([Used_MB] AS INT) AS VARCHAR(27))) > 6 
                        THEN REVERSE(STUFF(STUFF(REVERSE(CAST(CAST([Used_MB] AS INT) AS VARCHAR(27))),7,0,','),4,0,','))
                    WHEN LEN(CAST(CAST([Used_MB] AS INT) AS VARCHAR(27))) > 3 
                        THEN REVERSE(STUFF(REVERSE(CAST(CAST([Used_MB] AS INT) AS VARCHAR(27))),4,0,','))
                    ELSE CAST(CAST([Used_MB] AS INT) AS VARCHAR(27))
                END,
    [AveDailyGrowth] = LEFT(CAST([AveDailyGrowth] AS VARCHAR(37)),CHARINDEX('.',CAST([AveDailyGrowth] AS VARCHAR(37))) + 1)
                        
FROM 
    #FileInfo;



------------------------------------------------------------------------------------------
--// CLEAN UP                                                                         //--
------------------------------------------------------------------------------------------

DROP TABLE #FileInfo;
DROP TABLE #FileSizes;

