-- check to see if backups are run natively or by CommVault or by both

IF EXISTS(SELECT 1 FROM msdb.dbo.backupmediafamily WHERE LEFT(physical_device_name,2) = N'\\')
   AND NOT EXISTS(SELECT 1 FROM msdb.dbo.backupmediafamily WHERE physical_device_name LIKE ('________-____-____-____-____________'))
BEGIN
    SELECT @@SERVERNAME AS server_name, 
           'Native'     AS backup_method;
END;
ELSE IF NOT EXISTS(SELECT 1 FROM msdb.dbo.backupmediafamily WHERE LEFT(physical_device_name,2) = N'\\')
        AND EXISTS(SELECT 1 FROM msdb.dbo.backupmediafamily WHERE physical_device_name LIKE ('________-____-____-____-____________'))
BEGIN
    SELECT @@SERVERNAME AS server_name, 
           'CommVault'  AS backup_method;
END;
ELSE IF EXISTS(SELECT 1 FROM msdb.dbo.backupmediafamily WHERE LEFT(physical_device_name,2) = N'\\')
        AND EXISTS(SELECT 1 FROM msdb.dbo.backupmediafamily WHERE physical_device_name LIKE ('________-____-____-____-____________'))
BEGIN
    SELECT @@SERVERNAME AS server_name, 
           'Both Native and CommVault'  AS backup_method;
END;
ELSE
BEGIN
    SELECT @@SERVERNAME AS server_name, 
           'Something unaccounted for is going on...'  AS backup_method;
END;


