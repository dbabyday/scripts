/*********************************************************************************************************************
* 
* FILES_OutOfPlace.sql
* 
* Author: James Lutsey
* Date:   2018-05-14
* 
* Purpose: Finds files that are not in the standard directories
* 
* Date        Name                  Description of change
* ----------  --------------------  ---------------------------------------------------------------------------------
* 
* 
*********************************************************************************************************************/



-------------------------------------------------------
--// USER INPUT                                    //--
-------------------------------------------------------

DECLARE @DataFileDirectory   AS NVARCHAR(260) = N'F:\Databases\',
        @LogFileDirectory    AS NVARCHAR(260) = N'G:\Logs\',
        @TempdbFileDirectory AS NVARCHAR(260) = N'T:\TempDB\';



-------------------------------------------------------
--// PREP                                          //--
-------------------------------------------------------

DECLARE @fileList AS NVARCHAR(MAX) = N'';

DECLARE @Files TABLE
(
    server_name        NVARCHAR(128) NOT NULL,
    database_name      NVARCHAR(128) NOT NULL,
    file_name          NVARCHAR(128) NOT NULL,
    type_desc          NVARCHAR(60)  NOT NULL,
    size_mb            INT           NOT NULL,
    physical_name      NVARCHAR(260) NOT NULL,
    standard_directory NVARCHAR(260) NOT NULL
);

-- verify directory format
IF RIGHT(@DataFileDirectory,1) <> N'\'   SET @DataFileDirectory += N'\';
IF RIGHT(@LogFileDirectory,1) <> N'\'    SET @LogFileDirectory += N'\';
IF RIGHT(@TempdbFileDirectory,1) <> N'\' SET @TempdbFileDirectory += N'\';



-------------------------------------------------------
--// FIND FILES OUT OF PLACE                       //--
-------------------------------------------------------

-- data files
INSERT INTO @Files
(
    server_name,
    database_name,
    file_name,
    type_desc,
    size_mb,
    physical_name,
    standard_directory
)
SELECT   @@SERVERNAME,
         DB_NAME(database_id),
         name,
         type_desc,
         CAST(ROUND(size/128.0,0) AS INT),
         physical_name,
         @DataFileDirectory
FROM     sys.master_files
WHERE    DB_NAME(database_id) NOT IN (N'master',N'model',N'msdb',N'tempdb')
         AND type = 0
         AND LEFT(physical_name,13) <> @DataFileDirectory

-- log files
INSERT INTO @Files
(
    server_name,
    database_name,
    file_name,
    type_desc,
    size_mb,
    physical_name,
    standard_directory
)
SELECT   @@SERVERNAME,
         DB_NAME(database_id),
         name,
         type_desc,
         CAST(ROUND(size/128.0,0) AS INT),
         physical_name,
         @LogFileDirectory
FROM     sys.master_files
WHERE    DB_NAME(database_id) NOT IN (N'master',N'model',N'msdb',N'tempdb')
         AND type = 1
         AND LEFT(physical_name,8) <> @LogFileDirectory

-- tempdb
INSERT INTO @Files
(
    server_name,
    database_name,
    file_name,
    type_desc,
    size_mb,
    physical_name,
    standard_directory
)
SELECT   @@SERVERNAME,
         DB_NAME(database_id),
         name,
         type_desc,
         CAST(ROUND(size/128.0,0) AS INT),
         physical_name,
         @TempdbFileDirectory
FROM     sys.master_files
WHERE    DB_NAME(database_id) = N'tempdb'
         AND LEFT(physical_name,10) <> @TempdbFileDirectory
ORDER BY [type_desc] desc,
         DB_NAME(database_id),
         name;



-------------------------------------------------------
--// DISPLAY THE RESULTS                           //--
-------------------------------------------------------

-- all details
SELECT   server_name,
         database_name,
         file_name,
         type_desc,
         size_mb,
         physical_name,
         standard_directory
FROM     @Files
ORDER BY database_name,
         file_name;

-- get a list of the files to use in FILES_MoveCommands.sql
SELECT   @fileList += N'''' + file_name + N''','
FROM     @Files
ORDER BY database_name,
         file_name;

SELECT @fileList = LEFT(@fileList,LEN(@fileList) - 1);
SELECT @fileList AS [file lsit to use in FILES_MoveCommands.sql];
