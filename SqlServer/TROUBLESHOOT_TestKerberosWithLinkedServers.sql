USE [master];
SELECT COUNT(*) FROM sys.servers WHERE name = 'co-db-145';
EXECUTE sys.sp_addlinkedserver @server = N'co-db-145', @srvproduct=N'SQL Server';
EXECUTE sys.sp_testlinkedserver @servername = N'co-db-145';
EXECUTE sys.sp_dropserver @server = N'co-db-145', @droplogins = 'droplogins';


SELECT * FROM sys.dm_exec_connections;
SELECT * FROM sys.dm_server_services;

