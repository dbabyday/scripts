SELECT  CAST(SERVERPROPERTY ('ComputerNamePhysicalNetBIOS')   AS VARCHAR(25)) as [Net BIOS Name],     -- NetBIOS name of the local computer on which the instance of SQL Server is currently running.
        CAST(SERVERPROPERTY ('MachineName')                   AS VARCHAR(25)) as [Machine Name],      -- Windows computer name on which the server instance is running.
        CAST(SERVERPROPERTY ('ServerName')                    AS VARCHAR(25)) as [SQL Server Name],   -- Both the Windows server and instance information associated with a specified instance of SQL Server.
        CAST(SERVERPROPERTY ('Edition')                       AS VARCHAR(30)) as [SQL Edition],       -- Installed product edition of the instance of SQL Server. 
                                                                                         -- Returns:
                                                                                         -----------
                                                                                                -- 'Desktop Engine' (Not available for SQL Server.)
                                                                                                -- 'Developer Edition'
                                                                                                -- 'Enterprise Edition'
                                                                                                -- 'Enterprise Evaluation Edition'
                                                                                                -- 'Personal Edition'(Not available for SQL Server.)
                                                                                                -- 'Standard Edition'
                                                                                                -- 'Express Edition'
                                                                                                -- 'Express Edition with Advanced Services'
                                                                                                -- 'Workgroup Edition'
                                                                                                -- 'Windows Embedded SQL'
        CAST(SERVERPROPERTY ('ProductVersion')                AS VARCHAR(15))  as [SQL Version],      -- Version of the instance of SQL Server, in the form of 'major.minor.build'.
        CAST(SERVERPROPERTY ('ProductLevel')                         AS VARCHAR(15))  as [Product Level],    -- Level of the version of the instance of SQL Server.
                                                                                         -- Returns one of the following:
                                                                                         -------------------------------
                                                                                                -- 'RTM' = Original release version
                                                                                                -- 'SPx' = Service pack version
                                                                                                -- 'CTP', = Community Technology Preview version
        CAST(SERVERPROPERTY ('Collation')                     AS VARCHAR(30))  as [Server Collation], -- Name of the default collation for the server.        
        CAST(
       CASE   WHEN SERVERPROPERTY ('EngineEdition') = 1 THEN 'PERSONAL'
              WHEN SERVERPROPERTY ('EngineEdition') = 2 THEN 'STANDARD'
              WHEN SERVERPROPERTY ('EngineEdition') = 3 THEN 'ENTERPRISE/DEVELOPER'
              WHEN SERVERPROPERTY ('EngineEdition') = 4 THEN 'EXPRESS'
              WHEN SERVERPROPERTY ('EngineEdition') = 5 THEN 'SQL DATABASE'
              ELSE 'N/A'
              END                                      AS VARCHAR(25))  as [SQL Engine], -- Database Engine edition of the instance of SQL Server installed on the server.
                                                                                         -- Returns:
                                                                                         ----------
                                                                                                -- 1 = Personal or Desktop Engine (Not available for SQL Server.)
                                                                                                -- 2 = Standard (This is returned for Standard and Workgroup.)
                                                                                                -- 3 = Enterprise (This is returned for Enterprise, Enterprise Evaluation, and Developer.)
                                                                                                -- 4 = Express (This is returned for Express, Express with Advanced Services, and Windows Embedded SQL.)

        ISNULL(CAST(SERVERPROPERTY ('InstanceName') AS VARCHAR(25)), 'N/A') as [Instance Name],    -- Name of the instance to which the user is connected.
                                                                                         -- Returns NULL if the instance name is the default instance,
        CAST(
        CASE  WHEN SERVERPROPERTY ('IsIntegratedSecurityOnly') = 0 THEN 'Windows Authentication Only' 
              WHEN SERVERPROPERTY ('IsIntegratedSecurityOnly') = 1 THEN 'Windows and SQL Authentication'
              ELSE   'N/A'
              END
       AS VARCHAR(35))                                                      as [Security Model],      
        CAST(SERVERPROPERTY ('LicenseType')            AS VARCHAR(15))            as [License Type],      -- Mode of this instance of SQL Server.
                                                                                         -- PER_SEAT = Per Seat mode
                                                                                         -- PER_PROCESSOR = Per-processor mode
                                                                                         -- DISABLED = Licensing is disabled.
       ISNULL(CAST(SERVERPROPERTY ('NumLicenses')      AS VARCHAR(25)), 'N/A') as [License Number]     -- Number of client licenses registered for this instance of SQL Server if in Per Seat mode.
                                                                                         -- Number of processors licensed for this instance of SQL Server if in per-processor mode.

