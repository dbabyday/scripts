/***************************************************************************************************
*
* Shrink File Incrementally
*
* Author: James Lutsey
* Date: 09/24/2015
* Purpose: Shrink a file incrementally by a specified amount.
*
* Notes: 
*      1. Set @File_Id for the file you want to shrink (use the commented out select statement 
*         to find file_id's)
*      2. Set @ShrinkAmtMB to the number of MB you want to shrink on each iteration
*
****************************************************************************************************/

USE [];  -- select name from master.sys.databases order by name
GO

--     SELECT file_id, name, size * 8 / 1024 as MB FROM sys.database_files;

DECLARE @FileName        NVARCHAR(255),
        @Size            INT,
		@TargetSize      INT,
		@Command         NVARCHAR(300),
		@File_Id         INT,
		@ShrinkAmtMB     INT; 
		
SET @File_Id = <file_id>;
SET @ShrinkAmtMB = 500;
SET @FileName = (SELECT name FROM sys.database_files WHERE file_id = @File_Id);
SET @Size = 8 * (SELECT size FROM sys.database_files WHERE file_id = @File_Id) / 1024;
SET @TargetSize = ROUND(@Size, 0) - @ShrinkAmtMB;

SELECT @Command = N'DBCC SHRINKFILE (N''' + @FileName + N''', ' + CONVERT(NVARCHAR(20), @TargetSize) + N')';

SELECT 
    'Before executing DBCC SHRINKFILE',
    @FileName AS name,
    @Size AS size_MB,
    @TargetSize AS TargetSize,
	@Command AS command;
	   
--EXECUTE sp_executesql @Command;
--  

SELECT 
    'After executing DBCC SHRINKFILE',
    name,
    size * 8 / 1024 AS size_MB
FROM 
    sys.database_files 
WHERE 
    file_id = @File_Id


