/*
    Choose a directory to create the backup file in.

    A PowerShell command will be generated that you can use to delete the file 
    (log backups of model database are not needed for anything...we're just freeing 
    up space in the log file so it doesn't keep growing unnecessarily)
*/


DECLARE @directory AS NVARCHAR(255),
        @file      AS NVARCHAR(260),
        @sql       AS NVARCHAR(MAX);

SET @directory = N'F:\Backups\';
--SET @directory = N'\\na\databackup\Dev_SQL_Backups\Common\';
--SET @directory = N'\\na\databackup\Guad_SQL_Backups\Common\';
--SET @directory = N'F:\Backups\';

SET @file = @directory + REPLACE(@@SERVERNAME,N'\',N'$') + N'_model_LOG_' + REPLACE(REPLACE(REPLACE(CONVERT(NCHAR(19),GETDATE(),120),N'-',N''),N' ',N'_'),N':',N'') + N'.trn';

SELECT @sql = N'BACKUP LOG model TO DISK = N''' + @file + N''';';
EXECUTE sys.sp_executesql @stmt = @sql;

SELECT N'Remove-Item -Path "' + @file + N'"' AS PowerShell_DeleteFile;


