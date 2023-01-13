/*********************************************************************************************************************
* 
* SECURITY_ScriptPermissions_All.sql
* 
* Author: James Lutsey
* Date:   2018-07-11
* 
* Purpose: Scripts out the server permissions. You can specify a particular principal (user or role), or leave it
*          blank to script permissions for all principals.
* 
* Date        Name                  Description of change
* ----------  --------------------  ---------------------------------------------------------------------------------
* 
* 
*********************************************************************************************************************/



-- Script Server Permissions

SET NOCOUNT ON;
USE master;


-- USER INPUT 
-- enter a principal name or leave blank to get all server permissions
DECLARE @principal AS NVARCHAR(128) = N'';  -- select name from sys.server_principals where type in ('G','R','S','U') AND name NOT LIKE N'##%##' AND name NOT LIKE N'NT AUTHORITY%\%' AND name NOT LIKE N'NT SERVICE%\%' order by name;

-- other variables
DECLARE @binvalue       AS VARBINARY(256)
      , @dbName         AS NVARCHAR(128)
      , @hexstring      AS NCHAR(16)     = N'0123456789ABCDEF'
      , @i              AS INT           = 1
      , @int0           AS INT
      , @int1           AS INT
      , @int2           AS INT
      , @length         AS INT
      , @msg            AS NVARCHAR(MAX) = N''
      , @ncharvalue     AS NVARCHAR(514) = N'0x'
      , @sql            AS NVARCHAR(MAX)
      , @sqlPrincipal   AS NVARCHAR(128)
      , @sqlPrincipalId AS INT;
      
IF OBJECT_ID(N'tempdb..#Passwords',N'U') IS NOT NULL DROP TABLE #Passwords;
CREATE TABLE #Passwords
(
      principal_id INT           NOT NULL
    , password     NVARCHAR(514) NOT NULL
);
      
IF OBJECT_ID(N'tempdb..#Principal',N'U') IS NOT NULL DROP TABLE #Principal;
CREATE TABLE #Principal
(
      name NVARCHAR(128) NOT NULL
);

IF OBJECT_ID(N'tempdb..#Results',N'U') IS NOT NULL DROP TABLE #Results;
CREATE TABLE #Results
(
      id         INT            NOT NULL IDENTITY(1,1)
    , definition NVARCHAR(4000) NOT NULL
);

DECLARE Databases CURSOR LOCAL FAST_FORWARD FOR
    SELECT   name
    FROM     sys.databases
    WHERE    state = 0
    ORDER BY name;

DECLARE SqlLogins CURSOR LOCAL FAST_FORWARD FOR
    SELECT principal_id 
         , name
    FROM   sys.sql_logins;

INSERT INTO #Results (definition) VALUES (N'/*')
                                       , (N'    Server:           ' + CONVERT(NVARCHAR(128),SERVERPROPERTY('ServerName')))
                                       , (N'    Date:             ' + CONVERT(NCHAR(19),GETDATE(),120))
                                       , (N'    Server Principal: ' + CASE WHEN @principal = N'' THEN N'All' ELSE @principal END)
                                       , (N'*/');

IF @principal = N''
BEGIN
    -----------------------------------------------
    --// CHECK FOR UNHANDLED CASES             //--
    -----------------------------------------------

    -- get principals of types we're not going to handle
    IF EXISTS(SELECT 1 FROM sys.server_principals WHERE type NOT IN ('G','R','S','U') AND name NOT LIKE N'##%##')
    BEGIN
        SET @msg = N'Server principals exist that are not handled by this script. Run the following query to look at them.' + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'--------------------------------------------------------'                                              + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'USE [' + DB_NAME() + N'];'                                                                             + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'SELECT *'                                                                                              + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'FROM   sys.server_principals'                                                                          + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'WHERE  type NOT IN (''G'',''R'',''S'',''U'')'                                                          + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'       AND name NOT LIKE N''##%##'';'                                                                  + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'--------------------------------------------------------';

        RAISERROR(@msg,16,1) WITH NOWAIT;
    END;  



    -----------------------------------------------
    --// GET THE PERMISSIONS                   //--
    -----------------------------------------------

    INSERT INTO #Results (definition) VALUES (N'')
                                           , (N'')
                                           , (N'')
                                           , (N'-----------------------------------------------')
                                           , (N'--// LOGINS                                //--')
                                           , (N'-----------------------------------------------')
                                           , (N'')
                                           , (N'USE master;');

    -- logins for windows users
    INSERT INTO #Results (definition) VALUES (N''), (N'-- create windows logins');
    INSERT INTO #Results (definition)
    SELECT   N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + name + N''') CREATE LOGIN [' + name + N'] FROM WINDOWS WITH DEFAULT_DATABASE = [' + default_database_name + N'], DEFAULT_LANGUAGE = [' + default_language_name + N'];'
    FROM     sys.server_principals
    WHERE    principal_id > 10
             AND name NOT LIKE N'##%##'
             AND name NOT LIKE N'NT AUTHORITY%\%'
             AND name NOT LIKE N'NT SERVICE%\%'
             AND type IN ('G','U')
    ORDER BY name;

    -- get the hashed passwords for sql logins
    OPEN SqlLogins;
        FETCH NEXT FROM SqlLogins INTO @sqlPrincipalId, @sqlPrincipal;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT @binvalue = password_hash
                 , @length   = DATALENGTH(password_hash)
                 , @i = 1
                 , @ncharvalue = N'0x'
            FROM   sys.sql_logins
            WHERE  name = @sqlPrincipal;

            WHILE (@i <= @length)
            BEGIN
                SET @int0 = CAST(SUBSTRING(@binvalue,@i,1) AS INT);
                SET @int1 = FLOOR(@int0 / 16.0);
                SET @int2 = @int0 - (@int1 * 16);
                SET @ncharvalue += SUBSTRING(@hexstring, @int1 + 1, 1) + SUBSTRING(@hexstring, @int2+1, 1);
                SET @i += 1;
            END;

            INSERT INTO #Passwords ( principal_id,  password )
            VALUES ( @sqlPrincipalId, @ncharvalue );

            FETCH NEXT FROM SqlLogins INTO @sqlPrincipalId, @sqlPrincipal;
        END;
    CLOSE SqlLogins;
    DEALLOCATE SqlLogins;
    
    -- logins for sql users
    INSERT INTO #Results (definition) VALUES (N''), (N'-- create sql logins');
    INSERT INTO #Results (definition)
    SELECT   CASE
                 WHEN is_policy_checked = 1 AND is_expiration_checked = 1 THEN N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + s.name + N''') CREATE LOGIN [' + s.name + N'] WITH PASSWORD = N''' + p.password + N''' HASHED, CHECK_EXPIRATION = ON, CHECK_POLICY = ON, DEFAULT_DATABASE = [' + s.default_database_name + N'], DEFAULT_LANGUAGE = [' + s.default_language_name + N'];'
                 WHEN is_policy_checked = 1 AND is_expiration_checked = 0 THEN N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + s.name + N''') CREATE LOGIN [' + s.name + N'] WITH PASSWORD = N''' + p.password + N''' HASHED, CHECK_EXPIRATION = ON, CHECK_POLICY = OFF, DEFAULT_DATABASE = [' + s.default_database_name + N'], DEFAULT_LANGUAGE = [' + s.default_language_name + N'];'
                 WHEN is_policy_checked = 0 AND is_expiration_checked = 1 THEN N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + s.name + N''') CREATE LOGIN [' + s.name + N'] WITH PASSWORD = N''' + p.password + N''' HASHED, CHECK_EXPIRATION = OFF, CHECK_POLICY = ON, DEFAULT_DATABASE = [' + s.default_database_name + N'], DEFAULT_LANGUAGE = [' + s.default_language_name + N'];'
                 WHEN is_policy_checked = 0 AND is_expiration_checked = 0 THEN N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + s.name + N''') CREATE LOGIN [' + s.name + N'] WITH PASSWORD = N''' + p.password + N''' HASHED, CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF, DEFAULT_DATABASE = [' + s.default_database_name + N'], DEFAULT_LANGUAGE = [' + s.default_language_name + N'];'
                 ELSE N'-- something is wrong with the logic for sql login [' + s.name + N']'
             END
    FROM     sys.sql_logins AS s
    JOIN     #Passwords     AS p ON p.principal_id = s.principal_id
    WHERE    s.principal_id > 10
             AND s.name NOT LIKE N'##%##'
    ORDER BY s.name;

    -- get disabled logins
    INSERT INTO #Results (definition) VALUES (N''), (N'-- disable logins');
    INSERT INTO #Results (definition)
    SELECT   N'ALTER LOGIN [' + name + N'] DISABLE;'
    FROM     sys.server_principals
    WHERE    principal_id > 10
             AND is_disabled = 1
    ORDER BY name;

    -- get logins that do not have access to the server
    INSERT INTO #Results (definition) VALUES (N''), (N'-- no access logins');
    WITH HasAccessLogins AS
    (
        SELECT prin.principal_id
        FROM   sys.server_principals  AS prin
        JOIN   sys.server_permissions AS perm ON perm.grantee_principal_id = prin.principal_id
        WHERE  perm.type = 'COSQ'
    )
    INSERT INTO     #Results (definition)
    SELECT          N'REVOKE CONNECT SQL TO [' + p.name + N'];'
    FROM            sys.server_principals  AS p
    LEFT OUTER JOIN HasAccessLogins AS h ON h.principal_id = p.principal_id
    WHERE           p.type IN ('S','U','G')
                    AND h.principal_id IS NULL
    ORDER BY        p.name;

    -- get the roles
    INSERT INTO #Results (definition) VALUES (N''), (N'-- create roles');
    INSERT INTO #Results (definition)
    SELECT   N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + name +''') CREATE ROLE [' + name + N'];'
    FROM     sys.server_principals
    WHERE    type = 'R'
             AND is_fixed_role = 0
             AND name <> N'public'
    ORDER BY name;

    -- get the role members
    INSERT INTO #Results (definition) VALUES (N''), (N'-- add role members');
    INSERT INTO #Results (definition)
    SELECT      CASE
                    WHEN (SELECT CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)), 2) AS INT)) > 10 THEN N'ALTER SERVER ROLE [' + theRole.name + N'] ADD MEMBER [' + theLogin.name + N'];'
                    ELSE N'EXECUTE sys.sp_addsrvrolemember @rolename = N''' + theRole.name + N''', @loginame = N''' + theLogin.name + N''';'
                END
    FROM        sys.server_principals   AS theLogin
    INNER JOIN  sys.server_role_members AS srm      ON theLogin.principal_Id = srm.member_principal_Id
    INNER JOIN  sys.server_principals   AS theRole  ON srm.role_principal_id = theRole.principal_id
    WHERE       theLogin.principal_id <> 1
    ORDER BY    theLogin.name,
                theRole.name;

    -- get the server permissions
    INSERT INTO #Results (definition) VALUES (N''), (N'-- apply permissions');
    INSERT INTO #Results (definition)
    SELECT  CASE 
                WHEN perm.state <> 'W' AND perm.class = 100                     THEN perm.state_desc + N' ' + perm.permission_name +                                      N' TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                WHEN perm.state =  'W' AND perm.class = 100                     THEN N'GRANT '       + N' ' + perm.permission_name +                                      N' TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                WHEN perm.state <> 'W' AND perm.class = 101 AND prn.type <> 'R' THEN perm.state_desc + N' ' + perm.permission_name + N' ON LOGIN::['       + prn.name +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                WHEN perm.state =  'W' AND perm.class = 101 AND prn.type <> 'R' THEN N'GRANT '       + N' ' + perm.permission_name + N' ON LOGIN::['       + prn.name +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                WHEN perm.state <> 'W' AND perm.class = 101 AND prn.type =  'R' THEN perm.state_desc + N' ' + perm.permission_name + N' ON SERVER ROLE::[' + prn.name +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                WHEN perm.state =  'W' AND perm.class = 101 AND prn.type =  'R' THEN N'GRANT '       + N' ' + perm.permission_name + N' ON SERVER ROLE::[' + prn.name +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                WHEN perm.state <> 'W' AND perm.class = 105                     THEN perm.state_desc + N' ' + perm.permission_name + N' ON ENDPOINT::['    + ept.name +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                WHEN perm.state =  'W' AND perm.class = 105                     THEN N'GRANT '       + N' ' + perm.permission_name + N' ON ENDPOINT::['    + ept.name +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                ELSE N'RAISERROR(N''Unaccounted for server permissions class existed | ' + [perm].[class_desc] + N''',16,1) WITH NOWAIT;'
            END
    FROM            sys.server_permissions    AS perm
    INNER JOIN      sys.server_principals     AS grantee ON grantee.principal_id = perm.grantee_principal_id
    INNER JOIN      sys.server_principals     AS grantor ON grantor.principal_id = perm.grantor_principal_id
    LEFT OUTER JOIN sys.server_principals     AS prn     ON perm.major_id = prn.principal_id AND perm.class = 101
    LEFT OUTER JOIN sys.endpoints             AS ept     ON perm.major_id = ept.endpoint_id  AND perm.class = 105
    ORDER BY        grantee.name,
                    perm.permission_name,
                    perm.state_desc;



    -----------------------------------------------
    --// DATABASE PERMISSIONS                  //--
    -----------------------------------------------

    INSERT INTO #Results (definition) VALUES (N'')
                                           , (N'')
                                           , (N'')
                                           , (N'-----------------------------------------------')
                                           , (N'--// DATABASE USERS AND PERMISSIONS        //--')
                                           , (N'-----------------------------------------------');
    
    OPEN Databases;
        FETCH NEXT FROM Databases INTO @dbName;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @sql = N'USE [' + @dbName + N'];

DECLARE @msg AS NVARCHAR(MAX) = N'''';

-----------------------------------------------
--// CHECK FOR UNHANDLED CASES             //--
-----------------------------------------------

-- get principals of types we''re not going to handle
IF EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [type] NOT IN (''G'',''R'',''S'',''U''))
BEGIN
    SET @msg = N''Database principals exist that are not handled by this script. Run the following query to look at them.'' + NCHAR(0x000D) + NCHAR(0x000A) +
               N''--------------------------------------------------------''                                                + NCHAR(0x000D) + NCHAR(0x000A) +
               N''USE ['' + DB_NAME() + N''];''                                                                               + NCHAR(0x000D) + NCHAR(0x000A) +
               N''SELECT *''                                                                                                + NCHAR(0x000D) + NCHAR(0x000A) +
               N''FROM   [sys].[database_principals]''                                                                      + NCHAR(0x000D) + NCHAR(0x000A) +
               N''WHERE  [type] NOT IN (''''G'''',''''R'''',''''S'''',''''U'''');''                                                         + NCHAR(0x000D) + NCHAR(0x000A) +
               N''--------------------------------------------------------''                                                + NCHAR(0x000D) + NCHAR(0x000A) + NCHAR(0x000D) + NCHAR(0x000A);

    RAISERROR(@msg,16,1) WITH NOWAIT;
END;';
            SET @sql += N'
-- check for orphaned users
IF EXISTS(SELECT          1 
          FROM            [sys].[database_principals] AS [d]
          LEFT OUTER JOIN [sys].[server_principals]   AS [s] ON [s].[sid] = [d].[sid]
          WHERE           [d].[principal_id] > 4
                          AND [d].[type] IN (''G'',''S'',''U'')
                          AND [s].[name] IS NULL
         )
BEGIN
    SET @msg = N''Orphaned users exist; these should probably be repaired or dropped. Run the following query to find them:'' + NCHAR(0x000D) + NCHAR(0x000A) +
               N''--------------------------------------------------------''                                                  + NCHAR(0x000D) + NCHAR(0x000A) +
               N''USE ['' + DB_NAME() + N''];''                                                                                 + NCHAR(0x000D) + NCHAR(0x000A) +
               N''SELECT          [d].*''                                                                                     + NCHAR(0x000D) + NCHAR(0x000A) +
               N''FROM            [sys].[database_principals] AS [d]''                                                        + NCHAR(0x000D) + NCHAR(0x000A) +
               N''LEFT OUTER JOIN [sys].[server_principals]   AS [s] ON [s].[sid] = [d].[sid]''                               + NCHAR(0x000D) + NCHAR(0x000A) +
               N''WHERE           [d].[principal_id] > 4''                                                                    + NCHAR(0x000D) + NCHAR(0x000A) +
               N''                AND [d].[type] IN (''''G'''',''''S'''',''''U'''')''                                                     + NCHAR(0x000D) + NCHAR(0x000A) +
               N''                AND [s].[name] IS NULL''                                                                    + NCHAR(0x000D) + NCHAR(0x000A) +
               N''--------------------------------------------------------''                                                  + NCHAR(0x000D) + NCHAR(0x000A) + NCHAR(0x000D) + NCHAR(0x000A);

    RAISERROR(@msg,16,1) WITH NOWAIT;
END;';
            SET @sql += N'
-- get permissions on database permissions - these are not hanlded by this script
IF EXISTS(SELECT          1 
          FROM            [sys].[database_permissions]
          WHERE           [class] = 4
         )
BEGIN
    SET @msg = N''Permissions for class Database Prinicpal exist; these are not handled by this script. Run the following query to find them:'' + NCHAR(0x000D) + NCHAR(0x000A) +
               N''--------------------------------------------------------''                                                                    + NCHAR(0x000D) + NCHAR(0x000A) +
               N''USE ['' + DB_NAME() + N''];''                                                                                                   + NCHAR(0x000D) + NCHAR(0x000A) +
               N''SELECT *''                                                                                                                    + NCHAR(0x000D) + NCHAR(0x000A) +
               N''FROM   [sys].[database_permissions]''                                                                                         + NCHAR(0x000D) + NCHAR(0x000A) +
               N''WHERE  [class] = 4''                                                                                                          + NCHAR(0x000D) + NCHAR(0x000A) +
               N''--------------------------------------------------------''                                                                    + NCHAR(0x000D) + NCHAR(0x000A) + NCHAR(0x000D) + NCHAR(0x000A);

    RAISERROR(@msg,16,1) WITH NOWAIT;
END;

';
            SET @sql += N'
-----------------------------------------------
--// GET THE PERMISSIONS                   //--
-----------------------------------------------

-- get the users
INSERT INTO #Results (definition) VALUES (N'''')
                                       , (N'''')
                                       , (N''USE [' + @dbName + N'];'')
                                       , (N'''')
                                       , (N''-- create users'');
INSERT INTO #Results (definition)
SELECT          COALESCE(   N''IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N'''''' + [d].[name] + N'''''') CREATE USER ['' + [d].[name] + N''] FOR LOGIN ['' + [s].[name] + N''] WITH DEFAULT_SCHEMA = ['' + [d].[default_schema_name] + N''];'',
                            N''IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N'''''' + [d].[name] + N'''''') CREATE USER ['' + [d].[name] + N''] FOR LOGIN ['' + [s].[name] + N''];'',
                            N''IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N'''''' + [d].[name] + N'''''') CREATE USER ['' + [d].[name] + N''] WITHOUT LOGIN;''
                        )
FROM            [sys].[database_principals] AS [d]
LEFT OUTER JOIN [sys].[server_principals]   AS [s] ON [s].[sid] = [d].[sid]
WHERE           [d].[principal_id] > 4
                AND [d].[is_fixed_role] = 0
                AND [d].[type] IN (''G'',''S'',''U'')
ORDER BY        [d].[name];';
            SET @sql += N'
-- get the roles
INSERT INTO #Results (definition) VALUES (N''''), (N''-- create roles'');
INSERT INTO #Results (definition)
SELECT   N''IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N'''''' + [name] +'''''') CREATE ROLE ['' + [name] + N''];''
FROM     [sys].[database_principals]
WHERE    [type] = ''R''
         AND [is_fixed_role] = 0
         AND [principal_id] <> 0
ORDER BY [name];';
            SET @sql += N'
-- get the role members
INSERT INTO #Results (definition) VALUES (N''''), (N''-- add role members'');
INSERT INTO #Results (definition)
SELECT      CASE
                WHEN (SELECT CAST(LEFT(CAST(SERVERPROPERTY(''ProductVersion'') AS NVARCHAR(128)), 2) AS INT)) > 10 THEN N''ALTER ROLE ['' + [theRole].[name] + N''] ADD MEMBER ['' + [theUser].[name] + N''];''
                ELSE N''EXECUTE [sys].[sp_addrolemember] @rolename = N'''''' + [theRole].[name] + N'''''', @membername = N'''''' + [theUser].[name] + N'''''';''
            END
FROM        [sys].[database_principals]   AS [theUser]
INNER JOIN  [sys].[database_role_members] AS [dbrm]    ON [theUser].[principal_Id] = [dbrm].[member_principal_Id]
INNER JOIN  [sys].[database_principals]   AS [theRole] ON [dbrm].[role_principal_id] = [theRole].[principal_id]
WHERE       [theUser].[principal_id] <> 1
ORDER BY    [theUser].[name],
            [theRole].[name];';
            SET @sql += N'
-- get the database permissions
INSERT INTO #Results (definition) VALUES (N''''), (N''-- apply permissions'');
INSERT INTO #Results (definition)
SELECT          CASE
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 0                            THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON DATABASE::[''                                                        + DB_NAME()                              +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 0                            THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON DATABASE::[''                                                        + DB_NAME()                              +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 1  AND [perm].[minor_id] = 0 THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON OBJECT::[''                + SCHEMA_NAME([obj].[schema_id]) + N''].['' + [obj].[name]                           +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 1  AND [perm].[minor_id] = 0 THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON OBJECT::[''                + SCHEMA_NAME([obj].[schema_id]) + N''].['' + [obj].[name]                           +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 1  AND [perm].[minor_id] > 0 THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON OBJECT::[''                + SCHEMA_NAME([obj].[schema_id]) + N''].['' + [obj].[name]  + N''] (['' + [col].[name] + N'']) TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 1  AND [perm].[minor_id] > 0 THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON OBJECT::[''                + SCHEMA_NAME([obj].[schema_id]) + N''].['' + [obj].[name]  + N''] (['' + [col].[name] + N'']) TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 3                            THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON SCHEMA::[''                                                          + [sch].[name]                           +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 3                            THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON SCHEMA::[''                                                          + [sch].[name]                           +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 5                            THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON ASSEMBLY::[''                                                        + [asmb].[name]                          +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 5                            THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON ASSEMBLY::[''                                                        + [asmb].[name]                          +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 6                            THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON TYPE::[''                  + SCHEMA_NAME([typ].[schema_id]) + N''].['' + [typ].[name]                           +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 6                            THEN N''GRANT ''                  + [perm].[permission_name] + N'' ON TYPE::[''                  + SCHEMA_NAME([typ].[schema_id]) + N''].['' + [typ].[name]                           +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 10                           THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON XML SCHEMA COLLECTION::['' + SCHEMA_NAME([xsc].[schema_id]) + N''].['' + [xsc].[name]                           +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 10                           THEN N''GRANT ''                  + [perm].[permission_name] + N'' ON XML SCHEMA COLLECTION::['' + SCHEMA_NAME([xsc].[schema_id]) + N''].['' + [xsc].[name]                           +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 15                           THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON MESSAGE TYPE::[''                                                    + [msg].[name]                           +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 15                           THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON MESSAGE TYPE::[''                                                    + [msg].[name]                           +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 16                           THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON CONTRACT::[''                                                        + [con].[name]                           +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 16                           THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON CONTRACT::[''                                                        + [con].[name]                           +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 17                           THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON SERVICE::[''                                                         + [srvc].[name]                          +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 17                           THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON SERVICE::[''                                                         + [srvc].[name]                          +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 18                           THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON REMOTE SERVICE BINDING::[''                                          + [rsb].[name]                           +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 18                           THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON REMOTE SERVICE BINDING::[''                                          + [rsb].[name]                           +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 19                           THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON ROUTE::[''                                                           + [rte].[name]                           +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 19                           THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON ROUTE::[''                                                           + [rte].[name]                           +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 24                           THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON SYMMETRIC KEY::[''                                                   + [sk].[name]                            +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 24                           THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON SYMMETRIC KEY::[''                                                   + [sk].[name]                            +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 25                           THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON CERTIFICATE::[''                                                     + [cert].[name]                          +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 25                           THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON CERTIFICATE::[''                                                     + [cert].[name]                          +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 26                           THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON ASYMMETRIC KEY::[''                                                  + [ak].[name]                            +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 26                           THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON ASYMMETRIC KEY::[''                                                  + [ak].[name]                            +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    ELSE N''RAISERROR(N''''Unaccounted for datbase permissions class existed | '' + [perm].[class_desc] + N'''''',16,1) WITH NOWAIT;''
                END
FROM            [sys].[database_permissions]    AS [perm]
INNER JOIN      [sys].[database_principals]     AS [grantee] ON [grantee].[principal_id] = [perm].[grantee_principal_id]
INNER JOIN      [sys].[database_principals]     AS [grantor] ON [grantor].[principal_id] = [perm].[grantor_principal_id]
LEFT OUTER JOIN [sys].[objects]                 AS [obj]     ON [perm].[major_id] = [obj].[object_id]                 AND [perm].[class] = 1
LEFT OUTER JOIN [sys].[columns]                 AS [col]     ON [perm].[major_id] = [col].[object_id]                 AND [perm].[class] = 1  AND [perm].[minor_id] = [col].[column_id]
LEFT OUTER JOIN [sys].[schemas]                 AS [sch]     ON [perm].[major_id] = [sch].[schema_id]                 AND [perm].[class] = 3
LEFT OUTER JOIN [sys].[assemblies]              AS [asmb]    ON [perm].[major_id] = [asmb].[assembly_id]              AND [perm].[class] = 5
LEFT OUTER JOIN [sys].[types]                   AS [typ]     ON [perm].[major_id] = [typ].[user_type_id]              AND [perm].[class] = 6
LEFT OUTER JOIN [sys].[xml_schema_collections]  AS [xsc]     ON [perm].[major_id] = [xsc].[xml_collection_id]         AND [perm].[class] = 10
LEFT OUTER JOIN [sys].[service_message_types]   AS [msg]     ON [perm].[major_id] = [msg].[message_type_id]           AND [perm].[class] = 15
LEFT OUTER JOIN [sys].[service_contracts]       AS [con]     ON [perm].[major_id] = [con].[service_contract_id]       AND [perm].[class] = 16
LEFT OUTER JOIN [sys].[services]                AS [srvc]    ON [perm].[major_id] = [srvc].[service_id]               AND [perm].[class] = 17
LEFT OUTER JOIN [sys].[remote_service_bindings] AS [rsb]     ON [perm].[major_id] = [rsb].[remote_service_binding_id] AND [perm].[class] = 18
LEFT OUTER JOIN [sys].[routes]                  AS [rte]     ON [perm].[major_id] = [rte].[route_id]                  AND [perm].[class] = 19
LEFT OUTER JOIN [sys].[symmetric_keys]          AS [sk]      ON [perm].[major_id] = [sk].[symmetric_key_id]           AND [perm].[class] = 24
LEFT OUTER JOIN [sys].[certificates]            AS [cert]    ON [perm].[major_id] = [cert].[certificate_id]           AND [perm].[class] = 25
LEFT OUTER JOIN [sys].[asymmetric_keys]         AS [ak]      ON [perm].[major_id] = [ak].[asymmetric_key_id]          AND [perm].[class] = 26
WHERE           [perm].[major_id] >= 0
                AND [grantee].[principal_id] > 4
ORDER BY        [grantee].[name],
                [perm].[permission_name],
                [perm].[state_desc];';

            --SELECT @sql;
            EXECUTE sys.sp_executesql @stmt = @sql;
            
            FETCH NEXT FROM Databases INTO @dbName;
        END;
    CLOSE Databases;
    DEALLOCATE Databases;
END;
ELSE
BEGIN
    -----------------------------------------------
    --// CHECK FOR UNHANDLED CASES             //--
    -----------------------------------------------

    -- verify the principal exists
    IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = @principal)
    BEGIN
        SET @msg = N'Server principal [' + @principal + N'] does not exist.';
        RAISERROR(@msg,16,1) WITH NOWAIT;
        SET NOEXEC ON;
    END;

    -- get principals of types we're not going to handle
    IF EXISTS(SELECT 1 FROM sys.server_principals WHERE name = @principal AND type NOT IN ('G','R','S','U') AND name NOT LIKE N'##%##')
    BEGIN
        SET @msg = N'Server principals exist that are not handled by this script. Run the following query to look at them.' + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'--------------------------------------------------------'                                              + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'USE [' + DB_NAME() + N'];'                                                                             + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'SELECT *'                                                                                              + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'FROM   sys.server_principals'                                                                          + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'WHERE  name = ''' + @principal + N''';'                                                                + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'--------------------------------------------------------';

        RAISERROR(@msg,16,1) WITH NOWAIT;
    END; 



    -----------------------------------------------
    --// GET THE PERMISSIONS                   //--
    -----------------------------------------------
    
    INSERT INTO #Results (definition) VALUES (N'')
                                           , (N'')
                                           , (N'')
                                           , (N'-----------------------------------------------')
                                           , (N'--// LOGINS                                //--')
                                           , (N'-----------------------------------------------')
                                           , (N'')
                                           , (N'USE master;');

    -- logins for windows users
    INSERT INTO #Results (definition) VALUES (N''), (N'-- create windows logins');
    INSERT INTO #Results (definition)
    SELECT   N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + name + N''') CREATE LOGIN [' + name + N'] FROM WINDOWS WITH DEFAULT_DATABASE = [' + default_database_name + N'], DEFAULT_LANGUAGE = [' + default_language_name + N'];'
    FROM     sys.server_principals
    WHERE    name = @principal
             AND name NOT LIKE N'##%##'
             AND name NOT LIKE N'NT AUTHORITY%\%'
             AND name NOT LIKE N'NT SERVICE%\%'
             AND type IN ('G','U')
    ORDER BY name;
    
    -- get the hashed passwords for sql logins
    SELECT @binvalue = password_hash
         , @length   = DATALENGTH(password_hash)
         , @i = 1
         , @ncharvalue = N'0x'
    FROM   sys.sql_logins
    WHERE  name = @principal;

    WHILE (@i <= @length)
    BEGIN
        SET @int0 = CAST(SUBSTRING(@binvalue,@i,1) AS INT);
        SET @int1 = FLOOR(@int0 / 16.0);
        SET @int2 = @int0 - (@int1 * 16);
        SET @ncharvalue += SUBSTRING(@hexstring, @int1 + 1, 1) + SUBSTRING(@hexstring, @int2+1, 1);
        SET @i += 1;
    END;

    -- logins for sql users
    INSERT INTO #Results (definition) VALUES (N''), (N'-- create sql logins');
    INSERT INTO #Results (definition)
    SELECT   CASE
                 WHEN is_policy_checked = 1 AND is_expiration_checked = 1 THEN N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + name + N''') CREATE LOGIN [' + name + N'] WITH PASSWORD = N''' + @ncharvalue + N''' HASHED, CHECK_EXPIRATION = ON, CHECK_POLICY = ON, DEFAULT_DATABASE = [' + default_database_name + N'], DEFAULT_LANGUAGE = [' + default_language_name + N'];'
                 WHEN is_policy_checked = 1 AND is_expiration_checked = 0 THEN N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + name + N''') CREATE LOGIN [' + name + N'] WITH PASSWORD = N''' + @ncharvalue + N''' HASHED, CHECK_EXPIRATION = ON, CHECK_POLICY = OFF, DEFAULT_DATABASE = [' + default_database_name + N'], DEFAULT_LANGUAGE = [' + default_language_name + N'];'
                 WHEN is_policy_checked = 0 AND is_expiration_checked = 1 THEN N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + name + N''') CREATE LOGIN [' + name + N'] WITH PASSWORD = N''' + @ncharvalue + N''' HASHED, CHECK_EXPIRATION = OFF, CHECK_POLICY = ON, DEFAULT_DATABASE = [' + default_database_name + N'], DEFAULT_LANGUAGE = [' + default_language_name + N'];'
                 WHEN is_policy_checked = 0 AND is_expiration_checked = 0 THEN N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + name + N''') CREATE LOGIN [' + name + N'] WITH PASSWORD = N''' + @ncharvalue + N''' HASHED, CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF, DEFAULT_DATABASE = [' + default_database_name + N'], DEFAULT_LANGUAGE = [' + default_language_name + N'];'
                 ELSE N'-- something is wrong with the logic for sql login [' + name + N']'
             END
    FROM     sys.sql_logins
    WHERE    name = @principal
             AND name NOT LIKE N'##%##'
    ORDER BY name;

    -- get disabled logins
    INSERT INTO #Results (definition) VALUES (N''), (N'-- disable logins');
    INSERT INTO #Results (definition)
    SELECT   N'ALTER LOGIN [' + name + N'] DISABLE;'
    FROM     sys.server_principals
    WHERE    name = @principal
             AND is_disabled = 1
    ORDER BY name;

    -- get the roles
    INSERT INTO #Results (definition) VALUES (N''), (N'-- create roles');
    INSERT INTO #Results (definition)
    SELECT   N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + name +''') CREATE ROLE [' + name + N'];'
    FROM     sys.server_principals
    WHERE    name = @principal
             AND type = 'R'
             AND is_fixed_role = 0
             AND name <> N'public'
    ORDER BY name;

    -- get the role members
    INSERT INTO #Results (definition) VALUES (N''), (N'-- add role members');
    INSERT INTO #Results (definition)
    SELECT      CASE
                    WHEN (SELECT CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)), 2) AS INT)) > 10 THEN N'ALTER SERVER ROLE [' + theRole.name + N'] ADD MEMBER [' + theLogin.name + N'];'
                    ELSE N'EXECUTE sys.sp_addsrvrolemember @rolename = N''' + theRole.name + N''', @loginame = N''' + theLogin.name + N''';'
                END
    FROM        sys.server_principals   AS theLogin
    INNER JOIN  sys.server_role_members AS srm      ON theLogin.principal_Id = srm.member_principal_Id
    INNER JOIN  sys.server_principals   AS theRole  ON srm.role_principal_id = theRole.principal_id
    WHERE       theLogin.name = @principal
                AND theLogin.principal_id <> 1
    ORDER BY    theLogin.name,
                theRole.name;

    -- get the server permissions
    INSERT INTO #Results (definition) VALUES (N''), (N'-- apply permissions');
    INSERT INTO #Results (definition)
    SELECT  CASE 
                WHEN perm.state <> 'W' AND perm.class = 100                     THEN perm.state_desc + N' ' + perm.permission_name +                                      N' TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                WHEN perm.state =  'W' AND perm.class = 100                     THEN N'GRANT '       + N' ' + perm.permission_name +                                      N' TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                WHEN perm.state <> 'W' AND perm.class = 101 AND prn.type <> 'R' THEN perm.state_desc + N' ' + perm.permission_name + N' ON LOGIN::['       + prn.name +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                WHEN perm.state =  'W' AND perm.class = 101 AND prn.type <> 'R' THEN N'GRANT '       + N' ' + perm.permission_name + N' ON LOGIN::['       + prn.name +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                WHEN perm.state <> 'W' AND perm.class = 101 AND prn.type =  'R' THEN perm.state_desc + N' ' + perm.permission_name + N' ON SERVER ROLE::[' + prn.name +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                WHEN perm.state =  'W' AND perm.class = 101 AND prn.type =  'R' THEN N'GRANT '       + N' ' + perm.permission_name + N' ON SERVER ROLE::[' + prn.name +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                WHEN perm.state <> 'W' AND perm.class = 105                     THEN perm.state_desc + N' ' + perm.permission_name + N' ON ENDPOINT::['    + ept.name +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                WHEN perm.state =  'W' AND perm.class = 105                     THEN N'GRANT '       + N' ' + perm.permission_name + N' ON ENDPOINT::['    + ept.name +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                ELSE N'RAISERROR(N''Unaccounted for server permissions class existed | ' + [perm].[class_desc] + N''',16,1) WITH NOWAIT;'
            END
    FROM            sys.server_permissions    AS perm
    INNER JOIN      sys.server_principals     AS grantee ON grantee.principal_id = perm.grantee_principal_id
    INNER JOIN      sys.server_principals     AS grantor ON grantor.principal_id = perm.grantor_principal_id
    LEFT OUTER JOIN sys.server_principals     AS prn     ON perm.major_id = prn.principal_id AND perm.class = 101
    LEFT OUTER JOIN sys.endpoints             AS ept     ON perm.major_id = ept.endpoint_id  AND perm.class = 105
    WHERE           grantee.name = @principal
    ORDER BY        grantee.name,
                    perm.permission_name,
                    perm.state_desc;



    -----------------------------------------------
    --// DATABASE PERMISSIONS                  //--
    -----------------------------------------------

    INSERT INTO #Results (definition) VALUES (N'')
                                           , (N'')
                                           , (N'')
                                           , (N'-----------------------------------------------')
                                           , (N'--// DATABASE USERS AND PERMISSIONS        //--')
                                           , (N'-----------------------------------------------');
    
    OPEN Databases;
        FETCH NEXT FROM Databases INTO @dbName;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @sql = N'USE [' + @dbName + N'];
            
DECLARE @msg            AS NVARCHAR(MAX) = N'''';

-- get the users
INSERT INTO #Results (definition) VALUES (N'''')
                                       , (N'''')
                                       , (N''USE [' + @dbName + N'];'')
                                       , (N'''')
                                       , (N''-- create users'');
INSERT INTO #Results (definition)
SELECT          COALESCE(   N''IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N'''''' + [d].[name] + N'''''') CREATE USER ['' + [d].[name] + N''] FOR LOGIN ['' + [s].[name] + N''] WITH DEFAULT_SCHEMA = ['' + [d].[default_schema_name] + N''];'',
                            N''IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N'''''' + [d].[name] + N'''''') CREATE USER ['' + [d].[name] + N''] FOR LOGIN ['' + [s].[name] + N''];'',
                            N''IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N'''''' + [d].[name] + N'''''') CREATE USER ['' + [d].[name] + N''] WITHOUT LOGIN;''
                        )
FROM            [sys].[database_principals] AS [d]
LEFT OUTER JOIN [sys].[server_principals]   AS [s] ON [s].[sid] = [d].[sid]
WHERE           [d].[name] = N''' + @principal + N'''
                AND [d].[is_fixed_role] = 0
                AND [d].[type] IN (''G'',''S'',''U'')
ORDER BY        [d].[name];';
            SET @sql += N'
-- get the roles
INSERT INTO #Results (definition) VALUES (N''''), (N''-- create roles'');
INSERT INTO #Results (definition)
SELECT   N''IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N'''''' + [name] +'''''') CREATE ROLE ['' + [name] + N''];''
FROM     [sys].[database_principals]
WHERE    [name] = N''' + @principal + N'''
         AND [type] = ''R''
         AND [is_fixed_role] = 0
         AND [principal_id] <> 0
ORDER BY [name];';
            SET @sql += N'
-- get the role members
INSERT INTO #Results (definition) VALUES (N''''), (N''-- add role members'');
INSERT INTO #Results (definition)
SELECT      CASE
                WHEN (SELECT CAST(LEFT(CAST(SERVERPROPERTY(''ProductVersion'') AS NVARCHAR(128)), 2) AS INT)) > 10 THEN N''ALTER ROLE ['' + [theRole].[name] + N''] ADD MEMBER ['' + [theUser].[name] + N''];''
                ELSE N''EXECUTE [sys].[sp_addrolemember] @rolename = N'''''' + [theRole].[name] + N'''''', @membername = N'''''' + [theUser].[name] + N'''''';''
            END
FROM        [sys].[database_principals]   AS [theUser]
INNER JOIN  [sys].[database_role_members] AS [dbrm]    ON [theUser].[principal_Id] = [dbrm].[member_principal_Id]
INNER JOIN  [sys].[database_principals]   AS [theRole] ON [dbrm].[role_principal_id] = [theRole].[principal_id]
WHERE       [theUser].[name] = N''' + @principal + N'''
ORDER BY    [theUser].[name],
            [theRole].[name];';
            SET @sql += N'
-- get the database permissions
INSERT INTO #Results (definition) VALUES (N''''), (N''-- apply permissions'');
INSERT INTO #Results (definition)
SELECT          CASE
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 0                            THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON DATABASE::[''                                                        + DB_NAME()                              +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 0                            THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON DATABASE::[''                                                        + DB_NAME()                              +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 1  AND [perm].[minor_id] = 0 THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON OBJECT::[''                + SCHEMA_NAME([obj].[schema_id]) + N''].['' + [obj].[name]                           +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 1  AND [perm].[minor_id] = 0 THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON OBJECT::[''                + SCHEMA_NAME([obj].[schema_id]) + N''].['' + [obj].[name]                           +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 1  AND [perm].[minor_id] > 0 THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON OBJECT::[''                + SCHEMA_NAME([obj].[schema_id]) + N''].['' + [obj].[name]  + N''] (['' + [col].[name] + N'']) TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 1  AND [perm].[minor_id] > 0 THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON OBJECT::[''                + SCHEMA_NAME([obj].[schema_id]) + N''].['' + [obj].[name]  + N''] (['' + [col].[name] + N'']) TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 3                            THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON SCHEMA::[''                                                          + [sch].[name]                           +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 3                            THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON SCHEMA::[''                                                          + [sch].[name]                           +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 5                            THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON ASSEMBLY::[''                                                        + [asmb].[name]                          +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 5                            THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON ASSEMBLY::[''                                                        + [asmb].[name]                          +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 6                            THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON TYPE::[''                  + SCHEMA_NAME([typ].[schema_id]) + N''].['' + [typ].[name]                           +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 6                            THEN N''GRANT ''                  + [perm].[permission_name] + N'' ON TYPE::[''                  + SCHEMA_NAME([typ].[schema_id]) + N''].['' + [typ].[name]                           +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 10                           THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON XML SCHEMA COLLECTION::['' + SCHEMA_NAME([xsc].[schema_id]) + N''].['' + [xsc].[name]                           +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 10                           THEN N''GRANT ''                  + [perm].[permission_name] + N'' ON XML SCHEMA COLLECTION::['' + SCHEMA_NAME([xsc].[schema_id]) + N''].['' + [xsc].[name]                           +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 15                           THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON MESSAGE TYPE::[''                                                    + [msg].[name]                           +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 15                           THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON MESSAGE TYPE::[''                                                    + [msg].[name]                           +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 16                           THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON CONTRACT::[''                                                        + [con].[name]                           +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 16                           THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON CONTRACT::[''                                                        + [con].[name]                           +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 17                           THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON SERVICE::[''                                                         + [srvc].[name]                          +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 17                           THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON SERVICE::[''                                                         + [srvc].[name]                          +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 18                           THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON REMOTE SERVICE BINDING::[''                                          + [rsb].[name]                           +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 18                           THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON REMOTE SERVICE BINDING::[''                                          + [rsb].[name]                           +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 19                           THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON ROUTE::[''                                                           + [rte].[name]                           +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 19                           THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON ROUTE::[''                                                           + [rte].[name]                           +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 24                           THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON SYMMETRIC KEY::[''                                                   + [sk].[name]                            +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 24                           THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON SYMMETRIC KEY::[''                                                   + [sk].[name]                            +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 25                           THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON CERTIFICATE::[''                                                     + [cert].[name]                          +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 25                           THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON CERTIFICATE::[''                                                     + [cert].[name]                          +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> ''W'' AND [perm].[class] = 26                           THEN [perm].[state_desc] + N'' '' + [perm].[permission_name] + N'' ON ASYMMETRIC KEY::[''                                                  + [ak].[name]                            +  N''] TO ['' + [grantee].[name]                   + N''] AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  ''W'' AND [perm].[class] = 26                           THEN N''GRANT ''           + N'' '' + [perm].[permission_name] + N'' ON ASYMMETRIC KEY::[''                                                  + [ak].[name]                            +  N''] TO ['' + [grantee].[name] + N''] WITH GRANT OPTION AS ['' + [grantor].[name] + N''];'' COLLATE DATABASE_DEFAULT
                    ELSE N''RAISERROR(N''''Unaccounted for datbase permissions class existed | '' + [perm].[class_desc] + N'''''',16,1) WITH NOWAIT;''
                END
FROM            [sys].[database_permissions]    AS [perm]
INNER JOIN      [sys].[database_principals]     AS [grantee] ON [grantee].[principal_id] = [perm].[grantee_principal_id]
INNER JOIN      [sys].[database_principals]     AS [grantor] ON [grantor].[principal_id] = [perm].[grantor_principal_id]
LEFT OUTER JOIN [sys].[objects]                 AS [obj]     ON [perm].[major_id] = [obj].[object_id]                 AND [perm].[class] = 1
LEFT OUTER JOIN [sys].[columns]                 AS [col]     ON [perm].[major_id] = [col].[object_id]                 AND [perm].[class] = 1  AND [perm].[minor_id] = [col].[column_id]
LEFT OUTER JOIN [sys].[schemas]                 AS [sch]     ON [perm].[major_id] = [sch].[schema_id]                 AND [perm].[class] = 3
LEFT OUTER JOIN [sys].[assemblies]              AS [asmb]    ON [perm].[major_id] = [asmb].[assembly_id]              AND [perm].[class] = 5
LEFT OUTER JOIN [sys].[types]                   AS [typ]     ON [perm].[major_id] = [typ].[user_type_id]              AND [perm].[class] = 6
LEFT OUTER JOIN [sys].[xml_schema_collections]  AS [xsc]     ON [perm].[major_id] = [xsc].[xml_collection_id]         AND [perm].[class] = 10
LEFT OUTER JOIN [sys].[service_message_types]   AS [msg]     ON [perm].[major_id] = [msg].[message_type_id]           AND [perm].[class] = 15
LEFT OUTER JOIN [sys].[service_contracts]       AS [con]     ON [perm].[major_id] = [con].[service_contract_id]       AND [perm].[class] = 16
LEFT OUTER JOIN [sys].[services]                AS [srvc]    ON [perm].[major_id] = [srvc].[service_id]               AND [perm].[class] = 17
LEFT OUTER JOIN [sys].[remote_service_bindings] AS [rsb]     ON [perm].[major_id] = [rsb].[remote_service_binding_id] AND [perm].[class] = 18
LEFT OUTER JOIN [sys].[routes]                  AS [rte]     ON [perm].[major_id] = [rte].[route_id]                  AND [perm].[class] = 19
LEFT OUTER JOIN [sys].[symmetric_keys]          AS [sk]      ON [perm].[major_id] = [sk].[symmetric_key_id]           AND [perm].[class] = 24
LEFT OUTER JOIN [sys].[certificates]            AS [cert]    ON [perm].[major_id] = [cert].[certificate_id]           AND [perm].[class] = 25
LEFT OUTER JOIN [sys].[asymmetric_keys]         AS [ak]      ON [perm].[major_id] = [ak].[asymmetric_key_id]          AND [perm].[class] = 26
WHERE           [grantee].[name] = N''' + @principal + N'''
                AND [perm].[major_id] >= 0
                AND [grantee].[principal_id] > 4
ORDER BY        [grantee].[name],
                [perm].[permission_name],
                [perm].[state_desc];';

            --SELECT @sql;
            EXECUTE sys.sp_executesql @stmt = @sql;
            
            FETCH NEXT FROM Databases INTO @dbName;
        END;
    CLOSE Databases;
    DEALLOCATE Databases;
END;



-----------------------------------------------
--// DISPLAY RESULTS                       //--
-----------------------------------------------

-- display the results
SELECT   definition
FROM     #Results 
ORDER BY id;



-----------------------------------------------
--// CLEAN UP                              //--
-----------------------------------------------

-- reset
SET NOEXEC OFF;

-- 
IF OBJECT_ID(N'tempdb..#Passwords',N'U') IS NOT NULL DROP TABLE #Passwords;
IF OBJECT_ID(N'tempdb..#Principal',N'U') IS NOT NULL DROP TABLE #Principal;
IF OBJECT_ID(N'tempdb..#Results',N'U') IS NOT NULL DROP TABLE #Results;
