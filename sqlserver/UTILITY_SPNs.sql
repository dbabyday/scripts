/*
* 
* UTILITY_SPN.sql
* 
* Author: James Lutsey
* Date:   2018-01-02
* 
* Purpose: generate the commands to check/drop/add SPNs
* 
* SPN Formats (https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/register-a-service-principal-name-for-kerberos-connections)
*     Protocol                   Instance           Format
*     -------------------------  -----------------  ----------
*     TCP                        default and named  MSSQLSvc/<FQDN>:<port>
*     named pipes/shared memory  default            MSSQLSvc/<FQDN>
*     named pipes/shared memory  named              MSSQLSvc/<FQDN>:<instancename>
*/

DECLARE @domain             NVARCHAR(128),
        @instance           NVARCHAR(128),
        @machineName        NVARCHAR(128),
        @port               NVARCHAR(20),
        @spnTcp             NVARCHAR(MAX),
        @spnNonTcp          NVARCHAR(MAX),
        @srvcAccount        NVARCHAR(256);

SELECT @instance = CONVERT(NVARCHAR(128),SERVERPROPERTY('ServerName'));

IF CHARINDEX('\',@instance) <> 0
BEGIN
    SET @instance = SUBSTRING(@instance,
                              CHARINDEX('\',@instance) + 1,
                              LEN(@instance) - CHARINDEX('\',@instance));
END;
ELSE SET @instance = NULL;

-- get the domain from the registry
EXEC [master].[dbo].[xp_regread] @rootkey    = 'HKEY_LOCAL_MACHINE', 
                                 @key        = 'SYSTEM\CurrentControlSet\services\Tcpip\Parameters', 
                                 @value_name = N'Domain',
                                 @value      = @domain OUTPUT;

SELECT @machineName = CONVERT(NVARCHAR(128),SERVERPROPERTY('MachineName')); -- + N'.' + @domain

SELECT @port = CAST(local_tcp_port AS NVARCHAR(20))
FROM   sys.dm_exec_connections
WHERE  session_id = @@SPID;

SELECT @srvcAccount = service_account
FROM   sys.dm_server_services
WHERE  servicename LIKE 'SQL Server (%)';

-- create spn format for tcp protocol
SET @spnTcp = N'MSSQLSvc/' + @machineName + N'.' + @domain + N':' + @port;

-- create spn format for non tcp protocol
IF @instance IS NULL -- default instance
    SET @spnNonTcp = N'MSSQLSvc/' + @machineName + N'.' + @domain;
ELSE -- named instance
    SET @spnNonTcp = N'MSSQLSvc/' + @machineName + N'.' + @domain + N':' + @instance;

-- query spn
SELECT N'setspn -Q ' + @spnTcp AS [Check if an SPN is already registered]
UNION
SELECT N'setspn -Q ' + @spnNonTcp AS [Check if an SPN is already registered]
UNION
SELECT N'setspn -L ' + @srvcAccount + NCHAR(0x000D) + NCHAR(0x000A) AS [Check if an SPN is already registered]
ORDER BY [Check if an SPN is already registered] DESC;

-- delete spn
SELECT N'setspn -D ' + @spnTcp + N' <accountname>' AS [If a wrong SPN exists, drop it]
UNION
SELECT N'setspn -D ' + @spnNonTcp + N' <accountname>' AS [If a wrong SPN exists, drop it];

-- add spn
SELECT N'setspn -S ' + @spnTcp + N' ' + @srvcAccount AS [Add SPN]
UNION
SELECT N'setspn -S ' + @spnNonTcp + N' ' + @srvcAccount AS [Add SPN];



