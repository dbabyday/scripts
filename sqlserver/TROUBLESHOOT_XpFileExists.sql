/*
    TROUBLESHOOT_XpFileExist.sql

    See results of xp_fileexist for a given path
*/

DECLARE @path AS NVARCHAR(4000) = '\\na\databackup\Guad_SQL_Backups\';
 
DECLARE @file_results TABLE
(
    file_exists             INT,
    file_is_a_directory     INT,
    parent_directory_exists INT
)
 
INSERT INTO @file_results (file_exists, file_is_a_directory, parent_directory_exists)
EXECUTE master.dbo.xp_fileexist @path;
     
SELECT * FROM @file_results;