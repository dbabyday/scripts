USE [master];
GO

DECLARE
    @db			NVARCHAR(128),
	@command	NVARCHAR(350),
    @file		NVARCHAR(128),
	@grow		NVARCHAR(10),
	@max		NVARCHAR(10),
	@message	NVARCHAR(300),
	@returnCode	INT,
	@size		NVARCHAR(10);
	

------------------------------------------------------------------------------------------
--// USER INPUTS                                                                      //--
------------------------------------------------------------------------------------------

SET @db   = '';
SET @file = '';
SET @size = ''; --MB (leave blank to keep current size setting)
SET @grow = ''; --MB (leave blank to set standard autogrow based on size)
SET @max  = ''; --MB (leave blank to keep current max size setting)


------------------------------------------------------------------------------------------
--// VALIDATE THE USER INPUTS                                                         //--
------------------------------------------------------------------------------------------

-- the user must enter a database name
IF (@db = '')
BEGIN
	RAISERROR('You must specify a database with the @db variable.',16,1);
	RETURN;
END

-- the database name must exist on the server
IF (NOT EXISTS(SELECT name FROM sys.databases WHERE name = @db))
BEGIN
	SET @message = 'Specified database, @db = '''+ @db + ''', does not exist.' + CHAR(13) + CHAR(10);
	SET @message = @message + 'Note: You are connected to server ' + @@SERVERNAME;
	RAISERROR(@message,16,1);
	RETURN;
END
	
-- the user must enter a file name
IF (@file = '')
BEGIN
	RAISERROR('You must specify a file with the @file variable.',16,1);
	RETURN;
END

-- the file name must exist in the datbase
IF (NOT EXISTS(SELECT name FROM sys.master_files WHERE DB_NAME(database_id) = @db AND name = @file))
BEGIN
	SET @message = 'Specified file, @file = '''+ @file + ''', does not exist in database [' + @db + '].'
	RAISERROR(@message,16,1);
	RETURN;
END

-- the user must enter one or more value(s) to be set 
IF (@size = '' AND @grow = '' AND @max = '')
BEGIN
	SET @message = 'You must specify one or more values to set: '			+ CHAR(13) + CHAR(10);
	SET @message = @message + '    @size - size of the file in MB'			+ CHAR(13) + CHAR(10);
	SET @message = @message + '    @grow - autogrowth of the file in MB'	+ CHAR(13) + CHAR(10);
	SET @message = @message + '    @max  - maximum size of the file in MB'
	RAISERROR(@message,16,1);
	RETURN;
END

-- the size must be an integer
IF (ISNUMERIC(@size + '.0e0') = 0)
BEGIN
	SET @message = 'Invalid @size value.'	+ CHAR(13) + CHAR(10);
	SET @message = @message + '@size must be an integer, and represents the desired size of the file in MB.'
	RAISERROR(@message,16,1);
	RETURN;
END

-- the autogrowth amount must be an integer
IF (ISNUMERIC(@grow + '.0e0') = 0)
BEGIN
	SET @message = 'Invalid @grow value.'	+ CHAR(13) + CHAR(10);
	SET @message = @message + '@grow must be an integer, and represents the desired autogrowth of the file in MB.'
	RAISERROR(@message,16,1);
	RETURN;
END

-- the maximum size must be an integer
IF (ISNUMERIC(@max + '.0e0') = 0)
BEGIN
	SET @message = 'Invalid @max value.'	+ CHAR(13) + CHAR(10);
	SET @message = @message + '@max must be an integer, and represents the desired maximum size of the file in MB.'
	RAISERROR(@message,16,1);
	RETURN;
END


------------------------------------------------------------------------------------------
--// BUILD THE COMMAND STRING                                                         //--
------------------------------------------------------------------------------------------

-- start the command with the file name
SET @command = 'ALTER DATABASE [' + @db + '] MODIFY FILE ( NAME = N''' + @file + '''';

-- if the user set the size, add it to the command
IF (@size != '')
BEGIN
	SET @command = @command + ', SIZE = ' + @size + 'MB';

	-- if the user did not specify an autogrow amount, calculate the standard amount based on the file size
	IF (@grow = '')
	BEGIN
		SELECT @grow =	CASE 
							WHEN @size <  72	THEN 4
							WHEN @size <  144	THEN 8
							WHEN @size <  288	THEN 16
							WHEN @size <  576	THEN 32
							WHEN @size <  1152	THEN 64
							WHEN @size <  2304	THEN 128
							WHEN @size <  4608	THEN 256
							WHEN @size <  9216	THEN 512
							WHEN @size <  22528	THEN 1024
							WHEN @size >= 22528	THEN 2048
						END
	END
END

-- add the filegrowth argument for the autogrow amount (if set by user or calculated based on size)
IF (@grow != '') 
	SET @command = @command + ', FILEGROWTH = ' + @grow + 'MB';

-- add the maxsize argument
IF (@max != '')
	SET @command = @command + ', MAXSIZE = ' + @max + 'MB';

-- end the command string
SET @command = @command + ' )';


------------------------------------------------------------------------------------------
--// EXECUTE THE COMMAND                                                              //--
------------------------------------------------------------------------------------------

-- print the command
PRINT @command;
PRINT '';

-- execute the command
EXECUTE @returnCode = sp_executesql @command;

-- display the results of the execution
IF (@returnCode IS NULL)
	RAISERROR('Command was not executed',16,1);
ELSE IF (@returnCode = 0)
	PRINT 'Success';
ELSE 
	RAISERROR('Failure',16,1);
