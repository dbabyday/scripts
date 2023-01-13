

DECLARE 
	@command	NVARCHAR(500),
	@returnCode	INT;


------------------------------------------------------------------------------------------
--// SET AUTOGROWTH TO STANDARD AMOUNTS BASED ON FILE SIZE                            //--
------------------------------------------------------------------------------------------

-- loop through and create the command to change filegrowth for all files that are able to have this setting changed
DECLARE curSetFilegrowth CURSOR FAST_FORWARD FOR
	SELECT 
		CASE 
			WHEN f.size <  9216		THEN N'/* ' + @@SERVERNAME + N' */ ALTER DATABASE [' + DB_NAME(f.database_id) + N'] MODIFY FILE ( NAME = N''' + f.name + N''', FILEGROWTH = 4MB );'
			WHEN f.size <  18432	THEN N'/* ' + @@SERVERNAME + N' */ ALTER DATABASE [' + DB_NAME(f.database_id) + N'] MODIFY FILE ( NAME = N''' + f.name + N''', FILEGROWTH = 8MB );'
			WHEN f.size <  36864	THEN N'/* ' + @@SERVERNAME + N' */ ALTER DATABASE [' + DB_NAME(f.database_id) + N'] MODIFY FILE ( NAME = N''' + f.name + N''', FILEGROWTH = 16MB );'
			WHEN f.size <  76728	THEN N'/* ' + @@SERVERNAME + N' */ ALTER DATABASE [' + DB_NAME(f.database_id) + N'] MODIFY FILE ( NAME = N''' + f.name + N''', FILEGROWTH = 32MB );'
			WHEN f.size <  147456	THEN N'/* ' + @@SERVERNAME + N' */ ALTER DATABASE [' + DB_NAME(f.database_id) + N'] MODIFY FILE ( NAME = N''' + f.name + N''', FILEGROWTH = 64MB );'
			WHEN f.size <  294912	THEN N'/* ' + @@SERVERNAME + N' */ ALTER DATABASE [' + DB_NAME(f.database_id) + N'] MODIFY FILE ( NAME = N''' + f.name + N''', FILEGROWTH = 128MB );'
			WHEN f.size <  589824	THEN N'/* ' + @@SERVERNAME + N' */ ALTER DATABASE [' + DB_NAME(f.database_id) + N'] MODIFY FILE ( NAME = N''' + f.name + N''', FILEGROWTH = 256MB );'
			WHEN f.size <  1179648	THEN N'/* ' + @@SERVERNAME + N' */ ALTER DATABASE [' + DB_NAME(f.database_id) + N'] MODIFY FILE ( NAME = N''' + f.name + N''', FILEGROWTH = 512MB );'
			WHEN f.size <  2883584	THEN N'/* ' + @@SERVERNAME + N' */ ALTER DATABASE [' + DB_NAME(f.database_id) + N'] MODIFY FILE ( NAME = N''' + f.name + N''', FILEGROWTH = 1024MB );'
			WHEN f.size >= 2883584	THEN N'/* ' + @@SERVERNAME + N' */ ALTER DATABASE [' + DB_NAME(f.database_id) + N'] MODIFY FILE ( NAME = N''' + f.name + N''', FILEGROWTH = 2048MB );'
		END
	FROM   
		sys.master_files f
	INNER JOIN
		sys.databases d
		ON d.database_id = f.database_id
	WHERE
		DB_NAME(f.database_id) NOT IN ('master', 'model', 'msdb', 'tempdb', 'distribution')
		AND f.type IN (0,1)
		AND d.state = 0 -- database online
		AND d.is_read_only = 0 -- read_write
		AND f.state = 0 -- file online
	ORDER BY 
		d.name,
		f.name

OPEN curSetFilegrowth;
FETCH NEXT FROM curSetFilegrowth INTO @command;

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		-- print the command
		PRINT @command;

		-- execute the command
		EXECUTE @returnCode = sp_executesql @command;

		-- display the results of the execution
		IF (@returnCode IS NULL)
			RAISERROR('Command was not executed',16,1);
		ELSE IF (@returnCode = 0)
			PRINT 'Success';
		ELSE 
			RAISERROR('Failure',16,1);
		
		FETCH NEXT FROM curSetFilegrowth INTO @command;
	END
CLOSE curSetFilegrowth;
DEALLOCATE curSetFilegrowth;

