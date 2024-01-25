/*


USE TipQA_DEV;
SELECT name FROM sys.database_principals WHERE is_fixed_role = 0 AND principal_id > 4 order by name;


-- find which AD Group a login is using
use msdb;
execute as login = 'NA\rafael.figueroa';
select * from  sys.user_token;
revert;



*/



SET NOCOUNT ON;


DECLARE 
    -- USER INPUT
    @loginName NVARCHAR(128) = N'',
    @option    INT           = 0,  -- 0 = select permissions, 1 = script permissions
    
    -- OTHER VARIABLES
    @credentialId        INT,
    @db                  NVARCHAR(128),
    @defaultDb           NVARCHAR(128),
    @defaultLang         NVARCHAR(128),
    @isDisabled          INT,
    @expirationCheck     NVARCHAR(3),
    @policyCheck         NVARCHAR(3),
    @loginType           CHAR(1),
    @passwordHash        VARBINARY(256),
    @password_nvarchar   NVARCHAR(514),
    @password_varbinary  VARBINARY(256),
    @serverRole          NVARCHAR(128),
    @sid_nvarchar        NVARCHAR(514),
    @sid_varbinary       VARBINARY(85),
    @sql                 NVARCHAR(MAX);

IF @loginName = N''
BEGIN
    SELECT @sql = N'select   name,' + CHAR(10) +
                  N'         principal_id,' + CHAR(10) +
                  N'         type_desc' + CHAR(10) +
                  N'FROM     sys.server_principals' + CHAR(10) +
                  N'WHERE    principal_id > 2' + CHAR(10) +
                  CASE WHEN CAST(PARSENAME(CAST(SERVERPROPERTY('productversion') AS varchar(20)), 4) AS INT) <= 10 THEN ''
				       ELSE N'         and is_fixed_role = 0' + CHAR(10)
				  END +
                  N'         and name not like N''##%##''' + CHAR(10) +
                  N'         and name not like N''nt authority%''' + CHAR(10) +
                  N'         and name not like N''nt service%''' + CHAR(10) +
                  N'order by name';
	PRINT @sql;
	EXECUTE sys.sp_executesql @stmt=@sql;
    RETURN;
END;

--  table to hold the server permissions
DECLARE @tblServerPermissions TABLE
(
    [grantee]          NVARCHAR(128),
	[state_desc]       NVARCHAR(60),
	[permission_name]  NVARCHAR(128),
    [class_desc]       NVARCHAR(128),
	[target]           NVARCHAR(128),
	[grantor]          NVARCHAR(128)
);

-- temp table to hold database roles for each database that the login has a user
IF OBJECT_ID('tempdb..#DbRoles','U') IS NOT NULL DROP TABLE #DbRoles;
CREATE TABLE #DbRoles
(
    [database] NVARCHAR(128),
	[user]     NVARCHAR(128),
	[role]     NVARCHAR(128),
	[login]    NVARCHAR(128)
);

-- temp table to hold database permissions for each database that the login has a user
IF OBJECT_ID('tempdb..#DbPermissions','U') IS NOT NULL DROP TABLE #DbPermissions;
CREATE TABLE #DbPermissions
(
    [database]        NVARCHAR(128),
	[grantee]         NVARCHAR(128),
	[state_desc]      NVARCHAR(60),
	[permission_name] NVARCHAR(128),
	[class_desc]      NVARCHAR(60),
    [target]          NVARCHAR(128),
    [column]          NVARCHAR(128),
	[grantor]         NVARCHAR(128)
);

-- temp table to hold commands for scripting permissions
IF OBJECT_ID('tempdb..#ScriptCommands','U') IS NOT NULL DROP TABLE #ScriptCommands;
CREATE TABLE #ScriptCommands
(
    [ID]          INT IDENTITY(1,1),
	[Deffinition] NVARCHAR(MAX)
);

-- cursor to loop through all the online databases
DECLARE curDBs CURSOR LOCAL FAST_FORWARD FOR
    SELECT [name] FROM [sys].[databases] WHERE [state] = 0;

-- cursor to loop through all the user-defined server roles for the login
DECLARE curServerRoles CURSOR LOCAL FAST_FORWARD FOR
    SELECT [theRole].[name]
    FROM [sys].[server_principals] AS [theLogin]
    JOIN [sys].[server_role_members] AS [srm] ON [theLogin].[principal_id] = [srm].[member_principal_id]
    JOIN [sys].[server_principals] AS [theRole] ON [srm].[role_principal_id] = [theRole].[principal_id]
    WHERE [theLogin].[name] = @loginName AND [theRole].[principal_id] > 10;
    



-------------------------------------------------------------------------------
--// GET THE INFO FROM EACH DATABASE                                       //--
-------------------------------------------------------------------------------

-- loop through each online database
OPEN curDBs;
    FETCH NEXT FROM curDBs INTO @db;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXECUTE(N'  
USE [' + @db + N'];

DECLARE @role NVARCHAR(128);

-- cursor to loop through all user-defined database roles
DECLARE curRoles CURSOR LOCAL FAST_FORWARD FOR
    SELECT [role] FROM #DbRoles WHERE [database] = DB_NAME() AND [role] NOT IN (''db_owner'',''db_accessadmin'',''db_securityadmin'',
                                                                                ''db_ddladmin'',''db_backupoperator'',''db_datareader'',
                                                                                ''db_datawriter'',''db_denydatareader'',''db_denydatawriter'');


-- get the roles for the user
INSERT INTO #DbRoles ([database],[user],[role],[login])
SELECT
    DB_NAME(),
    [theUser].[name],
    [theRole].[name],
    [theLogin].[name]
FROM [sys].[server_principals] AS [theLogin]
JOIN [sys].[database_principals] AS [theUser] ON [theLogin].[sid] = [theUser].[sid]
JOIN [sys].[database_role_members] AS [dbrm] ON [theUser].[principal_Id] = [dbrm].[member_principal_Id]
JOIN [sys].[database_principals] AS [theRole] ON [dbrm].[role_principal_id] = [theRole].[principal_id]
WHERE [theLogin].[name] = ''' + @loginName + N''';

-- get the database permissions for the user
INSERT INTO #DbPermissions ([database],[grantee],[state_desc],[permission_name],[class_desc],[target],[column],[grantor])
SELECT 
    DB_NAME(),
    [grantee].[name],
    [dbperm].[state_desc],
    [dbperm].[permission_name],
    [dbperm].[class_desc],
    CASE [dbperm].[class]
        WHEN 0  THEN DB_NAME([dbperm].[major_id])
        --WHEN 1  THEN OBJECT_NAME([dbperm].[major_id])
		WHEN 1  THEN (SELECT SCHEMA_NAME(x.schema_id) + N''.'' + name from [sys].[objects] as [x] WHERE [dbperm].[major_id] = [x].[object_id])
        WHEN 3  THEN SCHEMA_NAME([dbperm].[major_id])
        WHEN 4  THEN (SELECT [x].[name] FROM [sys].[database_principals]     AS [x] WHERE [dbperm].[major_id] = [x].[principal_id])
        WHEN 5  THEN (SELECT [x].[name] FROM [sys].[assemblies]              AS [x] WHERE [dbperm].[major_id] = [x].[assembly_id])
        WHEN 6  THEN (SELECT [x].[name] FROM [sys].[types]                   AS [x] WHERE [dbperm].[major_id] = [x].[user_type_id])
        WHEN 10 THEN (SELECT [x].[name] FROM [sys].[xml_schema_collections]  AS [x] WHERE [dbperm].[major_id] = [x].[xml_collection_id])
        WHEN 15 THEN (SELECT [x].[name] FROM [sys].[service_message_types]   AS [x] WHERE [dbperm].[major_id] = [x].[message_type_id])
        WHEN 16 THEN (SELECT [x].[name] FROM [sys].[service_contracts]       AS [x] WHERE [dbperm].[major_id] = [x].[service_contract_id])
        WHEN 17 THEN (SELECT [x].[name] FROM [sys].[services]                AS [x] WHERE [dbperm].[major_id] = [x].[service_id])
        WHEN 18 THEN (SELECT [x].[name] FROM [sys].[remote_service_bindings] AS [x] WHERE [dbperm].[major_id] = [x].[remote_service_binding_id])
        WHEN 19 THEN (SELECT [x].[name] FROM [sys].[routes]                  AS [x] WHERE [dbperm].[major_id] = [x].[route_id])
        WHEN 23 THEN (SELECT [x].[name] FROM [sys].[fulltext_catalogs]       AS [x] WHERE [dbperm].[major_id] = [x].[fulltext_catalog_id])
        WHEN 24 THEN (SELECT [x].[name] FROM [sys].[symmetric_keys]          AS [x] WHERE [dbperm].[major_id] = [x].[symmetric_key_id])
        WHEN 25 THEN (SELECT [x].[name] FROM [sys].[certificates]            AS [x] WHERE [dbperm].[major_id] = [x].[certificate_id])
        WHEN 26 THEN (SELECT [x].[name] FROM [sys].[asymmetric_keys]         AS [x] WHERE [dbperm].[major_id] = [x].[asymmetric_key_id])
        ELSE N''need to add class''
    END,
    CASE [dbperm].[minor_id]
        WHEN 0 THEN N''''
        ELSE (SELECT [x].[name] FROM [sys].[columns] AS [x] WHERE [x].[object_id] = [dbperm].[major_id] AND [x].[column_id] = [dbperm].[minor_id])
    END,
    [grantor].[name]
FROM [sys].[database_permissions] AS [dbperm]
JOIN [sys].[database_principals] AS [grantee] on [dbperm].[grantee_principal_id] = [grantee].[principal_id]
JOIN [sys].[database_principals] AS [grantor] on [dbperm].[grantor_principal_id] = [grantor].[principal_id]
WHERE [grantee].[name] = ''' + @loginName + N''';

-- loop through the user-defined database roles for the user to get the database permissions for those roles
OPEN curRoles;
    FETCH NEXT FROM curRoles INTO @role;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- get the database permissions for the role
        INSERT INTO #DbPermissions ([database],[grantee],[state_desc],[permission_name],[class_desc],[target],[column],[grantor])
        SELECT 
            DB_NAME(),
            [grantee].[name],
            [dbperm].[state_desc],
            [dbperm].[permission_name],
            [dbperm].[class_desc],
            CASE [dbperm].[class]
                WHEN 0  THEN DB_NAME([dbperm].[major_id])
                --WHEN 1  THEN OBJECT_NAME([dbperm].[major_id])
                WHEN 1  THEN (SELECT SCHEMA_NAME(x.schema_id) + N''.'' + name from [sys].[objects] as [x] WHERE [dbperm].[major_id] = [x].[object_id])
                WHEN 3  THEN SCHEMA_NAME([dbperm].[major_id])
                WHEN 4  THEN (SELECT [x].[name] FROM [sys].[database_principals]     AS [x] WHERE [dbperm].[major_id] = [x].[principal_id])
                WHEN 5  THEN (SELECT [x].[name] FROM [sys].[assemblies]              AS [x] WHERE [dbperm].[major_id] = [x].[assembly_id])
                WHEN 6  THEN (SELECT [x].[name] FROM [sys].[types]                   AS [x] WHERE [dbperm].[major_id] = [x].[user_type_id])
                WHEN 10 THEN (SELECT [x].[name] FROM [sys].[xml_schema_collections]  AS [x] WHERE [dbperm].[major_id] = [x].[xml_collection_id])
                WHEN 15 THEN (SELECT [x].[name] FROM [sys].[service_message_types]   AS [x] WHERE [dbperm].[major_id] = [x].[message_type_id])
                WHEN 16 THEN (SELECT [x].[name] FROM [sys].[service_contracts]       AS [x] WHERE [dbperm].[major_id] = [x].[service_contract_id])
                WHEN 17 THEN (SELECT [x].[name] FROM [sys].[services]                AS [x] WHERE [dbperm].[major_id] = [x].[service_id])
                WHEN 18 THEN (SELECT [x].[name] FROM [sys].[remote_service_bindings] AS [x] WHERE [dbperm].[major_id] = [x].[remote_service_binding_id])
                WHEN 19 THEN (SELECT [x].[name] FROM [sys].[routes]                  AS [x] WHERE [dbperm].[major_id] = [x].[route_id])
                WHEN 23 THEN (SELECT [x].[name] FROM [sys].[fulltext_catalogs]       AS [x] WHERE [dbperm].[major_id] = [x].[fulltext_catalog_id])
                WHEN 24 THEN (SELECT [x].[name] FROM [sys].[symmetric_keys]          AS [x] WHERE [dbperm].[major_id] = [x].[symmetric_key_id])
                WHEN 25 THEN (SELECT [x].[name] FROM [sys].[certificates]            AS [x] WHERE [dbperm].[major_id] = [x].[certificate_id])
                WHEN 26 THEN (SELECT [x].[name] FROM [sys].[asymmetric_keys]         AS [x] WHERE [dbperm].[major_id] = [x].[asymmetric_key_id])
                ELSE N''need to add class''
            END COLLATE DATABASE_DEFAULT,
            CASE [dbperm].[minor_id]
                WHEN 0 THEN N''''
                ELSE (SELECT [z].[name] FROM [sys].[columns] AS [z] WHERE [z].[object_id] = [dbperm].[major_id] AND [z].[column_id] = [dbperm].[minor_id])
            END,
            [grantor].[name]
        FROM [sys].[database_permissions] AS [dbperm]
        JOIN [sys].[database_principals] AS [grantee] on [dbperm].[grantee_principal_id] = [grantee].[principal_id]
        JOIN [sys].[database_principals] AS [grantor] on [dbperm].[grantor_principal_id] = [grantor].[principal_id]
        WHERE [grantee].[name] = @role;

        FETCH NEXT FROM curRoles INTO @role;
    END
CLOSE curRoles;
DEALLOCATE curRoles;');

        FETCH NEXT FROM curDBs INTO @db;
    END -- (WHILE @@FETCH_STATUS = 0...curDBs)
CLOSE curDBs;
DEALLOCATE curDBs;



-------------------------------------------------------------------------------
--// GET THE SERVER AND SERVER ROLE PERMISSIONS                            //--
-------------------------------------------------------------------------------

-- get the server permissions for the login
INSERT INTO @tblServerPermissions ([grantee],[state_desc],[permission_name],[class_desc],[target],[grantor])
SELECT 
	[grantee].[name],
	[sperm].[state_desc],
	[sperm].[permission_name],
	[sperm].[class_desc],
    CASE [sperm].[class]
        WHEN 100 THEN N''
        WHEN 101 THEN (SELECT [x].[name] FROM [sys].[server_principals] AS [x] WHERE [x].[principal_id] = [sperm].[major_id])
        WHEN 105 THEN (SELECT [y].[name] FROM [sys].[endpoints] AS [y] WHERE [y].[endpoint_id] = [sperm].[major_id])
    END AS [target],
	[grantor].[name]
FROM [sys].[server_permissions] AS [sperm]
JOIN [sys].[server_principals] AS [grantee] on [sperm].[grantee_principal_id] = [grantee].[principal_id]
JOIN [sys].[server_principals] AS [grantor] on [sperm].[grantor_principal_id] = [grantor].[principal_id]
WHERE [grantee].[name] = @loginName;

-- loop through the user-defined server roles to get the server permissions for those roles
OPEN curServerRoles;
    FETCH NEXT FROM curServerRoles INTO @serverRole;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- inser the server permissions for the user-defined role
        INSERT INTO @tblServerPermissions ([grantee],[state_desc],[permission_name],[class_desc],[target],[grantor])
        SELECT 
	        [grantee].[name],
	        [sperm].[state_desc],
	        [sperm].[permission_name],
	        [sperm].[class_desc],
            CASE [sperm].[class]
                WHEN 100 THEN N''
                WHEN 101 THEN (SELECT [x].[name] FROM [sys].[server_principals] AS [x] WHERE [x].[principal_id] = [sperm].[major_id])
                WHEN 105 THEN (SELECT [y].[name] FROM [sys].[endpoints] AS [y] WHERE [y].[endpoint_id] = [sperm].[major_id])
            END AS [target],
	        [grantor].[name]
        FROM [sys].[server_permissions] AS [sperm]
        JOIN [sys].[server_principals] AS [grantee] on [sperm].[grantee_principal_id] = [grantee].[principal_id]
        JOIN [sys].[server_principals] AS [grantor] on [sperm].[grantor_principal_id] = [grantor].[principal_id]
        WHERE [grantee].[name] = @serverRole;

        FETCH NEXT FROM curServerRoles INTO @serverRole;
    END -- (WHILE @@FETCH_STATUS = 0...curServerRoles)
CLOSE curServerRoles;



-------------------------------------------------------------------------------
--// DISPLAY RESULTS                                                       //--
-------------------------------------------------------------------------------

IF @option = 0 -- select permissions
BEGIN
    -- server roles
    SELECT 
        [theLogin].[name] AS [login],
	    [theRole].[name]  AS [server_role]
    FROM [sys].[server_principals] AS [theLogin]
    JOIN [sys].[server_role_members] AS [srm] ON [theLogin].[principal_id] = [srm].[member_principal_id]
    JOIN [sys].[server_principals] AS [theRole] ON [srm].[role_principal_id] = [theRole].[principal_id]
    WHERE [theLogin].[name] = @loginName;

    -- server permissions
    SELECT   *
    FROM     @tblServerPermissions
    ORDER BY [grantee],
             [permission_name],
             [state_desc];

    -- database roles
    SELECT *
    FROM #DbRoles
    ORDER BY [database],[user],[role];

    -- database permissions
    SELECT   *
    FROM     #DbPermissions
    ORDER BY [database],
             [grantee],
             [class_desc],
             [target],
             [permission_name];
END -- (IF @option = 0 -- select permissions)
ELSE IF @option = 1 -- script permissions
BEGIN
    SET @sql = 'USE [master];' + CHAR(10);
    INSERT INTO #ScriptCommands ([Deffinition]) VALUES (@sql);

    -- create user defined server roles
    -- loop through the user-defined server roles to get the server permissions for those roles
    OPEN curServerRoles;
        FETCH NEXT FROM curServerRoles INTO @serverRole;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @sql = N'IF NOT EXISTS(SELECT 1 FROM [sys].[server_principals] WHERE [name] = N''' + @serverRole + N''' AND [type] = ''R'')' + CHAR(10) +
                       N'    CREATE SERVER ROLE [' + @serverRole + N'];' + CHAR(10);

            INSERT INTO #ScriptCommands ([Deffinition]) VALUES (@sql);
            
            SELECT   @sql = N'';
            SELECT   @sql += [state_desc] + N' ' + [permission_name] + N' TO [' + [grantee] + N'];' + CHAR(10)
            FROM     @tblServerPermissions
            WHERE    [grantee] = @serverRole
            ORDER BY [state_desc],
                     [permission_name];

            INSERT INTO #ScriptCommands ([Deffinition]) VALUES (@sql);

            FETCH NEXT FROM curServerRoles INTO @serverRole;
        END
    CLOSE curServerRoles;
    

    -- create login
    SELECT @loginType    = [type],
           @credentialId = [credential_id],
           @defaultDb    = [default_database_name],
           @defaultLang  = [default_language_name],
           @isDisabled   = [is_disabled]
    FROM   [sys].[server_principals] 
    WHERE  [name] = @loginName;

    SET @sql = N'IF NOT EXISTS(SELECT 1 FROM [sys].[server_principals] WHERE [name] = N''' + @loginName + N''')' + CHAR(10);
    IF ( (@loginType = N'U') OR (@loginType = 'G') )
        SET @sql += N'    CREATE LOGIN [' + @loginName + N'] FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultDb + N'], DEFAULT_LANGUAGE = [' + @defaultLang + N'];' + CHAR(10);
    ELSE IF @loginType = 'S'
    BEGIN
        IF CAST(LEFT(CONVERT(NVARCHAR(128),SERVERPROPERTY('ProductVersion')),CHARINDEX(N'.',CONVERT(NVARCHAR(128),SERVERPROPERTY('ProductVersion')))-1) AS INT) >= 11
        BEGIN -- password_hash in sys.sql_logins begins with SQL Server 2012
            SELECT @expirationCheck    = CASE [is_expiration_checked]
                                             WHEN 0 THEN N'OFF'
                                             WHEN 1 THEN N'ON'
                                         END,
                   @policyCheck        = CASE [is_policy_checked]
                                             WHEN 0 THEN N'OFF'
                                             WHEN 1 THEN N'ON'
                                         END,
                   @password_varbinary = [password_hash],
                   @sid_varbinary      = [sid]
            FROM   [sys].[sql_logins]
            WHERE  [name] = @loginName;
        END
        ELSE -- password_hash not in sys.sql_logins prior to SQL Server 2012
        BEGIN
            SELECT @expirationCheck = CASE [is_expiration_checked]
                                          WHEN 0 THEN N'OFF'
                                          WHEN 1 THEN N'ON'
                                      END,
                   @policyCheck     = CASE [is_policy_checked]
                                          WHEN 0 THEN N'OFF'
                                          WHEN 1 THEN N'ON'
                                      END,
                   @sid_varbinary   = [sid]
            FROM   [sys].[sql_logins]
            WHERE  [name] = @loginName;

            SET @password_varbinary = CAST( LOGINPROPERTY( @loginName, 'PasswordHash' ) AS VARBINARY(256) );
            
            EXECUTE [CentralAdmin].[dbo].[usp_hexadecimal] @password_varbinary, @password_nvarchar OUT;
        END
        
        -- convert pw and sid to nvarchar
        EXECUTE [CentralAdmin].[dbo].[usp_hexadecimal] @password_varbinary, @password_nvarchar OUT;
        EXECUTE [CentralAdmin].[dbo].[usp_hexadecimal] @sid_varbinary, @sid_nvarchar OUT;



        SET @sql += N'    CREATE LOGIN [' + @loginName + N'] WITH PASSWORD         = '    + @password_nvarchar + ' HASHED,' + CHAR(10) + 
                    REPLICATE(N' ',25 + LEN(@loginName)) +      N'SID              = '    + @sid_nvarchar      + N','       + CHAR(10) + 
                    REPLICATE(N' ',25 + LEN(@loginName)) +      N'DEFAULT_DATABASE = ['   + @defaultdb         + N'],'      + CHAR(10) + 
                    REPLICATE(N' ',25 + LEN(@loginName)) +      N'DEFAULT_LANGUAGE = ['   + @defaultLang       + N'],'      + CHAR(10) + 
                    REPLICATE(N' ',25 + LEN(@loginName)) +      N'CHECK_EXPIRATION = '    + @expirationCheck   + N','       + CHAR(10) + 
                    REPLICATE(N' ',25 + LEN(@loginName)) +      N'CHECK_POLICY     = '    + @policyCheck       + N';'       + CHAR(10);
    END 

    INSERT INTO #ScriptCommands ([Deffinition]) VALUES (@sql);
    

--select * from sys.server_principals WHERE principal_id > 10 AND type = 'R'
--select * from sys.server_principals


    -- add login to server roles


    -- apply server permissions


    -- create user(s)


        -- create database roles
        
        
        -- add user to database roles


        -- apply database permissions



    SELECT [Deffinition] FROM #ScriptCommands ORDER BY [ID]
 /*   
    -- server roles
    SELECT 
        [theLogin].[name] AS [login],
	    [theRole].[name]  AS [server_role]
    FROM [sys].[server_principals] AS [theLogin]
    JOIN [sys].[server_role_members] AS [srm] ON [theLogin].[principal_id] = [srm].[member_principal_id]
    JOIN [sys].[server_principals] AS [theRole] ON [srm].[role_principal_id] = [theRole].[principal_id]
    WHERE [theLogin].[name] = @loginName;

    -- server permissions
    SELECT   *
    FROM     @tblServerPermissions
    ORDER BY [grantee],
             [permission_name],
             [state_desc];

    -- database roles
    SELECT *
    FROM #DbRoles
    ORDER BY [database],[user],[role];

    -- database permissions
    SELECT   *
    FROM     #DbPermissions
    ORDER BY [database],
             [grantee],
             [class_desc],
             [target],
             [permission_name];
*/
END -- (ELSE IF @option = 1 -- script permissions)




-------------------------------------------------------------------------------
--// CLEAN UP                                                              //--
-------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#DbRoles','U') IS NOT NULL DROP TABLE #DbRoles;
IF OBJECT_ID('tempdb..#DbPermissions','U') IS NOT NULL DROP TABLE #DbPermissions;
IF OBJECT_ID('tempdb..#ServerPermissions','U') IS NOT NULL DROP TABLE #ServerPermissions;
IF OBJECT_ID('tempdb..#ScriptCommands','U') IS NOT NULL DROP TABLE #ScriptCommands;