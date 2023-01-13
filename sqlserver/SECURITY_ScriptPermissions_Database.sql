/*********************************************************************************************************************
* 
* SECURITY_DatabasePermissions_Script.sql
* 
* Author: James Lutsey
* Date:   2018-03-23
* 
* Purpose: Scripts out the database permissions. You can specify a particular principal (user or role), or leave it
*          blank to script permissions for all principals.
* 
* Date        Name                  Description of change
* ----------  --------------------  ---------------------------------------------------------------------------------
* 2018-07-11  James Lutsey          Added create login if not exist commands for users
* 
*********************************************************************************************************************/



-- Script Database Permissions

SET NOCOUNT ON;

--  SELECT 'USE ' + QUOTENAME([name]) + ';' FROM [sys].[databases] ORDER BY [name];



-- USER INPUT 
-- enter a principal name or leave blank to get all database permissions
DECLARE @principal AS NVARCHAR(128) = N'';  -- select name from sys.database_principals where type in ('G','R','S','U') and name NOT IN (N'guest',N'INFORMATION_SCHEMA',N'sys',N'MS_DataCollectorInternalUser') and is_fixed_role = 0 order by name;

-- other variables
DECLARE @binvalue       AS VARBINARY(256)
      , @hexstring      AS NCHAR(16)     = N'0123456789ABCDEF'
      , @i              AS INT           = 1
      , @int0           AS INT
      , @int1           AS INT
      , @int2           AS INT
      , @length         AS INT
      , @msg            AS NVARCHAR(MAX) = N''
      , @ncharvalue     AS NVARCHAR(514) = N'0x'
      , @sqlPrincipal   AS NVARCHAR(128)
      , @sqlPrincipalId AS INT;

-- other variables
DECLARE @sql AS NVARCHAR(MAX) = N'';

IF OBJECT_ID(N'tempdb..#Passwords',N'U') IS NOT NULL DROP TABLE #Passwords;
CREATE TABLE #Passwords
(
      principal_id INT           NOT NULL
    , password     NVARCHAR(514) NOT NULL
);

IF OBJECT_ID(N'tempdb..#Results',N'U') IS NOT NULL DROP TABLE #Results;
CREATE TABLE #Results
(
      id         INT            NOT NULL IDENTITY(1,1)
    , definition NVARCHAR(4000) NOT NULL
);

DECLARE SqlLogins CURSOR LOCAL FAST_FORWARD FOR
    SELECT l.principal_id 
         , l.name
    FROM   sys.sql_logins          AS l
    JOIN   sys.database_principals AS d ON d.sid = l.sid;

INSERT INTO #Results (definition) VALUES (N'/*')
                                       , (N'    Server:       ' + CONVERT(NVARCHAR(128),SERVERPROPERTY('ServerName')))
                                       , (N'    Database:     ' + DB_NAME())
                                       , (N'    Date:         ' + CONVERT(NCHAR(19),GETDATE(),120))
                                       , (N'    DB Principal: ' + CASE WHEN @principal = N'' THEN N'All' ELSE @principal END)
                                       , (N'*/');

IF @principal = N''
BEGIN
    -----------------------------------------------
    --// CHECK FOR UNHANDLED CASES             //--
    -----------------------------------------------

    -- get principals of types we're not going to handle
    IF EXISTS(SELECT 1 FROM sys.database_principals WHERE type NOT IN ('G','R','S','U','C'))
    BEGIN
        SET @msg = N'Database principals exist that are not handled by this script. Run the following query to look at them.' + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'--------------------------------------------------------'                                                + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'USE [' + DB_NAME() + N'];'                                                                               + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'SELECT *'                                                                                                + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'FROM   sys.database_principals'                                                                          + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'WHERE  type NOT IN (''G'',''R'',''S'',''U'',''C'');'                                                     + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'--------------------------------------------------------'                                                + NCHAR(0x000D) + NCHAR(0x000A) + NCHAR(0x000D) + NCHAR(0x000A);

        RAISERROR(@msg,16,1) WITH NOWAIT;
    END;  

    -- check for orphaned users
    IF EXISTS(SELECT          1 
              FROM            sys.database_principals AS d
              LEFT OUTER JOIN sys.server_principals   AS s ON s.sid = d.sid
              WHERE           d.name NOT IN (N'guest',N'INFORMATION_SCHEMA',N'sys',N'MS_DataCollectorInternalUser')
                              AND d.type IN ('G','S','U')
                              AND s.name IS NULL
                              AND d.principal_id <> 1 -- dbo
             )
    BEGIN
        SET @msg = N'Orphaned users exist; these should probably be repaired or dropped. Run the following query to find them:'     + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'--------------------------------------------------------'                                                      + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'USE [' + DB_NAME() + N'];'                                                                                     + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'SELECT          ''drop user [''+d.name+N''];'' drop_user'                                                      + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'              , d.*'                                                                                           + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'FROM            sys.database_principals AS d'                                                                  + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'LEFT OUTER JOIN sys.server_principals   AS s ON s.sid = d.sid'                                                 + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'WHERE           d.name NOT IN (N''guest'',N''INFORMATION_SCHEMA'',N''sys'',N''MS_DataCollectorInternalUser'')' + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'                AND d.type IN (''G'',''S'',''U'')'                                                             + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'                AND s.name IS NULL'                                                                            + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'                AND d.principal_id <> 1  -- dbo'                                                               + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'--------------------------------------------------------'                                                      + NCHAR(0x000D) + NCHAR(0x000A) + NCHAR(0x000D) + NCHAR(0x000A);

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
    SELECT     N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + s.name + N''') CREATE LOGIN [' + s.name + N'] FROM WINDOWS WITH DEFAULT_DATABASE = [' + s.default_database_name + N'], DEFAULT_LANGUAGE = [' + s.default_language_name + N'];'
    FROM       sys.database_principals AS d
    INNER JOIN sys.server_principals   AS s ON s.sid = d.sid
    WHERE      d.type IN ('G','U')
    ORDER BY   d.name;

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
    SELECT     CASE
                   WHEN s.is_policy_checked = 1 AND s.is_expiration_checked = 1 THEN N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + s.name + N''') CREATE LOGIN [' + s.name + N'] WITH PASSWORD = N''' + p.password + N''' HASHED, CHECK_EXPIRATION = ON, CHECK_POLICY = ON, DEFAULT_DATABASE = [' + s.default_database_name + N'], DEFAULT_LANGUAGE = [' + s.default_language_name + N'];'
                   WHEN s.is_policy_checked = 1 AND s.is_expiration_checked = 0 THEN N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + s.name + N''') CREATE LOGIN [' + s.name + N'] WITH PASSWORD = N''' + p.password + N''' HASHED, CHECK_EXPIRATION = ON, CHECK_POLICY = OFF, DEFAULT_DATABASE = [' + s.default_database_name + N'], DEFAULT_LANGUAGE = [' + s.default_language_name + N'];'
                   WHEN s.is_policy_checked = 0 AND s.is_expiration_checked = 1 THEN N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + s.name + N''') CREATE LOGIN [' + s.name + N'] WITH PASSWORD = N''' + p.password + N''' HASHED, CHECK_EXPIRATION = OFF, CHECK_POLICY = ON, DEFAULT_DATABASE = [' + s.default_database_name + N'], DEFAULT_LANGUAGE = [' + s.default_language_name + N'];'
                   WHEN s.is_policy_checked = 0 AND s.is_expiration_checked = 0 THEN N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + s.name + N''') CREATE LOGIN [' + s.name + N'] WITH PASSWORD = N''' + p.password + N''' HASHED, CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF, DEFAULT_DATABASE = [' + s.default_database_name + N'], DEFAULT_LANGUAGE = [' + s.default_language_name + N'];'
                   ELSE N'-- something is wrong with the logic for sql login [' + s.name + N']'
               END
    FROM       sys.sql_logins AS s
    INNER JOIN #Passwords     AS p ON p.principal_id = s.principal_id
    ORDER BY   s.name;

    -- disabled logins
    INSERT INTO #Results (definition) VALUES (N''), (N'-- disable logins');
    INSERT INTO #Results (definition)
    SELECT     N'ALTER LOGIN [' + s.name + N'] DISABLE;'
    FROM       sys.database_principals AS d
    INNER JOIN sys.server_principals   AS s ON s.sid = d.sid
    WHERE      s.type IN ('S','U','G')
               AND s.is_disabled = 1
    ORDER BY   d.name;

    -- get logins that do not have access to the server
    INSERT INTO #Results (definition) VALUES (N''), (N'-- no access logins');
    WITH HasAccessLogins AS
    (
        SELECT s.principal_id
        FROM   sys.database_principals AS d
        JOIN   sys.server_principals   AS s ON s.sid = d.sid
        JOIN   sys.server_permissions  AS p ON p.grantee_principal_id = s.principal_id
        WHERE  p.type = 'COSQ'
    )
    INSERT INTO     #Results (definition)
    SELECT          N'REVOKE CONNECT SQL TO [' + s.name + N'];'
    FROM            sys.database_principals  AS d
    JOIN            sys.server_principals    AS s ON s.sid = d.sid
    LEFT OUTER JOIN HasAccessLogins AS h ON h.principal_id = s.principal_id
    WHERE           s.type IN ('S','U','G')
                    AND h.principal_id IS NULL
    ORDER BY        s.name;

    INSERT INTO #Results (definition) VALUES (N'')
                                           , (N'')
                                           , (N'')
                                           , (N'-----------------------------------------------')
                                           , (N'--// DATABASE USERS AND PERMISSIONS        //--')
                                           , (N'-----------------------------------------------')
                                           , (N'')
                                           , (N'USE [' + DB_NAME() + N'];');

    -- get the users
    INSERT INTO #Results (definition) VALUES (N''), (N'-- create users');
    INSERT INTO #Results (definition)
    SELECT          CASE d.type
                        WHEN 'C' THEN    N'IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE name = N''' + d.name + N''') CREATE USER [' + d.name + N'] FOR CERTIFICATE [' + c.name + N'];'
                        ELSE COALESCE(   N'IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE name = N''' + d.name + N''') CREATE USER [' + d.name + N'] FOR LOGIN [' + s.name + N'] WITH DEFAULT_SCHEMA = [' + d.default_schema_name + N'];' collate database_default,
                                         N'IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE name = N''' + d.name + N''') CREATE USER [' + d.name + N'] FOR LOGIN [' + s.name + N'];' collate database_default,
                                         N'IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE name = N''' + d.name + N''') CREATE USER [' + d.name + N'] WITHOUT LOGIN;' collate database_default
                                     )
                    END
    FROM            sys.database_principals AS d
    LEFT OUTER JOIN sys.server_principals   AS s ON s.sid = d.sid
    LEFT OUTER JOIN sys.certificates        AS c ON c.sid = d.sid
    WHERE           d.type IN ('G','S','U','C')
                    AND d.name NOT IN (N'dbo',N'guest',N'INFORMATION_SCHEMA',N'sys',N'MS_DataCollectorInternalUser')
    ORDER BY        d.name;

    -- get the roles
    INSERT INTO #Results (definition) VALUES (N''), (N'-- create roles');
    INSERT INTO #Results (definition)
    SELECT   N'IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE name = N''' + name +''') CREATE ROLE [' + name + N'];'
    FROM     sys.database_principals
    WHERE    type = 'R'
             AND is_fixed_role = 0
             AND name <> N'public'
    ORDER BY name;

    -- get the role members
    INSERT INTO #Results (definition) VALUES (N''), (N'-- add role members');
    INSERT INTO #Results (definition)
    SELECT      CASE
                    WHEN (SELECT CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)), 2) AS INT)) > 10 THEN N'ALTER ROLE [' + [theRole].[name] + N'] ADD MEMBER [' + [theUser].[name] + N'];'
                    ELSE N'EXECUTE [sys].[sp_addrolemember] @rolename = N''' + [theRole].[name] + N''', @membername = N''' + [theUser].[name] + N''';'
                END
    FROM        [sys].[database_principals]   AS [theUser]
    INNER JOIN  [sys].[database_role_members] AS [dbrm]    ON [theUser].[principal_Id] = [dbrm].[member_principal_Id]
    INNER JOIN  [sys].[database_principals]   AS [theRole] ON [dbrm].[role_principal_id] = [theRole].[principal_id]
    WHERE       [theUser].[principal_id] <> 1
    ORDER BY    [theUser].[name],
                [theRole].[name];

    -- get the database permissions
    INSERT INTO #Results (definition) VALUES (N''), (N'-- apply permissions');
    INSERT INTO #Results (definition)
    SELECT          CASE
                        WHEN perm.state <> 'W' AND perm.class = 0                               THEN perm.state_desc + N' ' + perm.permission_name + N' ON DATABASE::['                                                    + DB_NAME()                      +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 0                               THEN N'GRANT'        + N' ' + perm.permission_name + N' ON DATABASE::['                                                    + DB_NAME()                      +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 1  AND perm.minor_id = 0        THEN perm.state_desc + N' ' + perm.permission_name + N' ON OBJECT::['                + SCHEMA_NAME(obj.schema_id) + N'].[' + obj.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 1  AND perm.minor_id = 0        THEN N'GRANT'        + N' ' + perm.permission_name + N' ON OBJECT::['                + SCHEMA_NAME(obj.schema_id) + N'].[' + obj.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 1  AND perm.minor_id > 0        THEN perm.state_desc + N' ' + perm.permission_name + N' ON OBJECT::['                + SCHEMA_NAME(obj.schema_id) + N'].[' + obj.name  + N'] ([' + col.name + N']) TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 1  AND perm.minor_id > 0        THEN N'GRANT'        + N' ' + perm.permission_name + N' ON OBJECT::['                + SCHEMA_NAME(obj.schema_id) + N'].[' + obj.name  + N'] ([' + col.name + N']) TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 3                               THEN perm.state_desc + N' ' + perm.permission_name + N' ON SCHEMA::['                                                      + sch.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 3                               THEN N'GRANT'        + N' ' + perm.permission_name + N' ON SCHEMA::['                                                      + sch.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 4 AND pri.type NOT IN ('A','R') THEN perm.state_desc + N' ' + perm.permission_name + N' ON USER::['                                                        + pri.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 4 AND pri.type NOT IN ('A','R') THEN N'GRANT'        + N' ' + perm.permission_name + N' ON USER::['                                                        + pri.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 4 AND pri.type = 'A'            THEN perm.state_desc + N' ' + perm.permission_name + N' ON APPLICATION ROLE::['                                            + pri.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 4 AND pri.type = 'A'            THEN N'GRANT'        + N' ' + perm.permission_name + N' ON APPLICATION ROLE::['                                            + pri.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 4 AND pri.type = 'R'            THEN perm.state_desc + N' ' + perm.permission_name + N' ON ROLE::['                                                        + pri.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 4 AND pri.type = 'R'            THEN N'GRANT'        + N' ' + perm.permission_name + N' ON ROLE::['                                                        + pri.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 5                               THEN perm.state_desc + N' ' + perm.permission_name + N' ON ASSEMBLY::['                                                    + asmb.name                      +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 5                               THEN N'GRANT'        + N' ' + perm.permission_name + N' ON ASSEMBLY::['                                                    + asmb.name                      +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 6                               THEN perm.state_desc + N' ' + perm.permission_name + N' ON TYPE::['                  + SCHEMA_NAME(typ.schema_id) + N'].[' + typ.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 6                               THEN N'GRANT'        + N' ' + perm.permission_name + N' ON TYPE::['                  + SCHEMA_NAME(typ.schema_id) + N'].[' + typ.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 10                              THEN perm.state_desc + N' ' + perm.permission_name + N' ON XML SCHEMA COLLECTION::[' + SCHEMA_NAME(xsc.schema_id) + N'].[' + xsc.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 10                              THEN N'GRANT'        + N' ' + perm.permission_name + N' ON XML SCHEMA COLLECTION::[' + SCHEMA_NAME(xsc.schema_id) + N'].[' + xsc.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 15                              THEN perm.state_desc + N' ' + perm.permission_name + N' ON MESSAGE TYPE::['                                                + msg.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 15                              THEN N'GRANT'        + N' ' + perm.permission_name + N' ON MESSAGE TYPE::['                                                + msg.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 16                              THEN perm.state_desc + N' ' + perm.permission_name + N' ON CONTRACT::['                                                    + con.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 16                              THEN N'GRANT'        + N' ' + perm.permission_name + N' ON CONTRACT::['                                                    + con.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 17                              THEN perm.state_desc + N' ' + perm.permission_name + N' ON SERVICE::['                                                     + srvc.name                      +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 17                              THEN N'GRANT'        + N' ' + perm.permission_name + N' ON SERVICE::['                                                     + srvc.name                      +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 18                              THEN perm.state_desc + N' ' + perm.permission_name + N' ON REMOTE SERVICE BINDING::['                                      + rsb.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 18                              THEN N'GRANT'        + N' ' + perm.permission_name + N' ON REMOTE SERVICE BINDING::['                                      + rsb.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 19                              THEN perm.state_desc + N' ' + perm.permission_name + N' ON ROUTE::['                                                       + rte.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 19                              THEN N'GRANT'        + N' ' + perm.permission_name + N' ON ROUTE::['                                                       + rte.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 24                              THEN perm.state_desc + N' ' + perm.permission_name + N' ON SYMMETRIC KEY::['                                               + sk.name                        +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 24                              THEN N'GRANT'        + N' ' + perm.permission_name + N' ON SYMMETRIC KEY::['                                               + sk.name                        +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 25                              THEN perm.state_desc + N' ' + perm.permission_name + N' ON CERTIFICATE::['                                                 + cert.name                      +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 25                              THEN N'GRANT'        + N' ' + perm.permission_name + N' ON CERTIFICATE::['                                                 + cert.name                      +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 26                              THEN perm.state_desc + N' ' + perm.permission_name + N' ON ASYMMETRIC KEY::['                                              + ak.name                        +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 26                              THEN N'GRANT'        + N' ' + perm.permission_name + N' ON ASYMMETRIC KEY::['                                              + ak.name                        +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        ELSE N'RAISERROR(N''Unaccounted for datbase permissions class existed | ' + perm.class_desc + N''',16,1) WITH NOWAIT;'
                    END
    FROM            sys.database_permissions    AS perm
    INNER JOIN      sys.database_principals     AS grantee ON grantee.principal_id = perm.grantee_principal_id
    INNER JOIN      sys.database_principals     AS grantor ON grantor.principal_id = perm.grantor_principal_id
    LEFT OUTER JOIN sys.objects                 AS obj     ON perm.major_id = obj.object_id                 AND perm.class = 1
    LEFT OUTER JOIN sys.columns                 AS col     ON perm.major_id = col.object_id                 AND perm.class = 1  AND perm.minor_id = col.column_id
    LEFT OUTER JOIN sys.schemas                 AS sch     ON perm.major_id = sch.schema_id                 AND perm.class = 3
    LEFT OUTER JOIN sys.database_principals     AS pri     ON perm.major_id = pri.principal_id              AND perm.class = 4
    LEFT OUTER JOIN sys.assemblies              AS asmb    ON perm.major_id = asmb.assembly_id              AND perm.class = 5
    LEFT OUTER JOIN sys.types                   AS typ     ON perm.major_id = typ.user_type_id              AND perm.class = 6
    LEFT OUTER JOIN sys.xml_schema_collections  AS xsc     ON perm.major_id = xsc.xml_collection_id         AND perm.class = 10
    LEFT OUTER JOIN sys.service_message_types   AS msg     ON perm.major_id = msg.message_type_id           AND perm.class = 15
    LEFT OUTER JOIN sys.service_contracts       AS con     ON perm.major_id = con.service_contract_id       AND perm.class = 16
    LEFT OUTER JOIN sys.services                AS srvc    ON perm.major_id = srvc.service_id               AND perm.class = 17
    LEFT OUTER JOIN sys.remote_service_bindings AS rsb     ON perm.major_id = rsb.remote_service_binding_id AND perm.class = 18
    LEFT OUTER JOIN sys.routes                  AS rte     ON perm.major_id = rte.route_id                  AND perm.class = 19
    LEFT OUTER JOIN sys.symmetric_keys          AS sk      ON perm.major_id = sk.symmetric_key_id           AND perm.class = 24
    LEFT OUTER JOIN sys.certificates            AS cert    ON perm.major_id = cert.certificate_id           AND perm.class = 25
    LEFT OUTER JOIN sys.asymmetric_keys         AS ak      ON perm.major_id = ak.asymmetric_key_id          AND perm.class = 26
    WHERE           perm.major_id >= 0
                    AND grantee.principal_id <> 1  -- dbo
    ORDER BY        grantee.name,
                    perm.permission_name,
                    perm.state_desc;
END;
ELSE
BEGIN
    -----------------------------------------------
    --// CHECK FOR UNHANDLED CASES             //--
    -----------------------------------------------

    -- verify the principal exists
    IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = @principal)
    BEGIN
        SET @msg = N'Database principal [' + @principal + N'] does not exist.';
        RAISERROR(@msg,16,1) WITH NOWAIT;
        SET NOEXEC ON;
    END;
    
    -- check if the principal is a type we're not going to handle
    IF EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = @principal AND [type] NOT IN ('G','R','S','U','C'))
    BEGIN
        SET @msg = N'The database principal type is not handled by this script. Run the following query to look at it.' + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'--------------------------------------------------------'                                          + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'USE [' + DB_NAME() + N'];'                                                                         + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'SELECT *'                                                                                          + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'FROM   [sys].[database_principals]'                                                                + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'WHERE  [name] = ''' + @principal + N''';'                                                          + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'--------------------------------------------------------';

        RAISERROR(@msg,16,1) WITH NOWAIT;
    END;  

    -- check if the principal orphaned users
    IF EXISTS(SELECT          1 
              FROM            [sys].[database_principals] AS [d]
              LEFT OUTER JOIN [sys].[server_principals]   AS [s] ON [s].[sid] = [d].[sid]
              WHERE           [d].[name] = @principal
                              AND [d].[type] IN ('G','S','U')
                              AND [s].[name] IS NULL
             )
    BEGIN
        SET @msg = N'This is an orphaned user. Run the following query to see it:'                + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'--------------------------------------------------------'                    + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'USE [' + DB_NAME() + N'];'                                                   + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'SELECT          [d].*'                                                       + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'FROM            [sys].[database_principals] AS [d]'                          + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'LEFT OUTER JOIN [sys].[server_principals]   AS [s] ON [s].[sid] = [d].[sid]' + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'WHERE           [d].[name] = ''' + @principal + N''''                        + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'                AND [d].[type] IN (''G'',''S'',''U'')'                       + NCHAR(0x000D) + NCHAR(0x000A) +
                   N'                AND [s].[name] IS NULL'                                      + NCHAR(0x000D) + NCHAR(0x000A) +
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
    SELECT     N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + s.name + N''') CREATE LOGIN [' + s.name + N'] FROM WINDOWS WITH DEFAULT_DATABASE = [' + s.default_database_name + N'], DEFAULT_LANGUAGE = [' + s.default_language_name + N'];'
    FROM       sys.database_principals AS d
    INNER JOIN sys.server_principals   AS s ON s.sid = d.sid
    WHERE      d.name = @principal
               AND d.type IN ('G','U')
    ORDER BY   d.name;

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
    SELECT     CASE
                   WHEN s.is_policy_checked = 1 AND s.is_expiration_checked = 1 THEN N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + s.name + N''') CREATE LOGIN [' + s.name + N'] WITH PASSWORD = N''' + p.password + N''', CHECK_EXPIRATION = ON, CHECK_POLICY = ON, DEFAULT_DATABASE = [' + s.default_database_name + N'], DEFAULT_LANGUAGE = [' + s.default_language_name + N'];'
                   WHEN s.is_policy_checked = 1 AND s.is_expiration_checked = 0 THEN N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + s.name + N''') CREATE LOGIN [' + s.name + N'] WITH PASSWORD = N''' + p.password + N''', CHECK_EXPIRATION = ON, CHECK_POLICY = OFF, DEFAULT_DATABASE = [' + s.default_database_name + N'], DEFAULT_LANGUAGE = [' + s.default_language_name + N'];'
                   WHEN s.is_policy_checked = 0 AND s.is_expiration_checked = 1 THEN N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + s.name + N''') CREATE LOGIN [' + s.name + N'] WITH PASSWORD = N''' + p.password + N''', CHECK_EXPIRATION = OFF, CHECK_POLICY = ON, DEFAULT_DATABASE = [' + s.default_database_name + N'], DEFAULT_LANGUAGE = [' + s.default_language_name + N'];'
                   WHEN s.is_policy_checked = 0 AND s.is_expiration_checked = 0 THEN N'IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = N''' + s.name + N''') CREATE LOGIN [' + s.name + N'] WITH PASSWORD = N''' + p.password + N''', CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF, DEFAULT_DATABASE = [' + s.default_database_name + N'], DEFAULT_LANGUAGE = [' + s.default_language_name + N'];'
                   ELSE N'-- something is wrong with the logic for sql login [' + s.name + N']'
               END
    FROM       sys.sql_logins AS s
    INNER JOIN #Passwords     AS p ON p.principal_id = s.principal_id
    WHERE      s.name = @principal
    ORDER BY   s.name;

    -- disabled logins
    INSERT INTO #Results (definition) VALUES (N''), (N'-- disable logins');
    INSERT INTO #Results (definition)
    SELECT     N'ALTER LOGIN [' + s.name + N'] DISABLE;'
    FROM       sys.database_principals AS d
    INNER JOIN sys.server_principals   AS s ON s.sid = d.sid
    WHERE      d.name = @principal
               AND s.is_disabled = 1
    ORDER BY   d.name;

    -- get logins that do not have access to the server
    INSERT INTO #Results (definition) VALUES (N''), (N'-- no access logins');
    WITH HasAccessLogins AS
    (
        SELECT s.principal_id
        FROM   sys.database_principals AS d
        JOIN   sys.server_principals   AS s ON s.sid = d.sid
        JOIN   sys.server_permissions  AS p ON p.grantee_principal_id = s.principal_id
        WHERE  p.type = 'COSQ'
    )
    INSERT INTO     #Results (definition)
    SELECT          N'REVOKE CONNECT SQL TO [' + s.name + N'];'
    FROM   sys.database_principals  AS d
    JOIN   sys.server_principals    AS s ON s.sid = d.sid
    LEFT OUTER JOIN HasAccessLogins AS h ON h.principal_id = s.principal_id
    WHERE           d.name = @principal
                    AND h.principal_id IS NULL
    ORDER BY        s.name;

    INSERT INTO #Results (definition) VALUES (N'')
                                           , (N'')
                                           , (N'')
                                           , (N'-----------------------------------------------')
                                           , (N'--// DATABASE USERS AND PERMISSIONS        //--')
                                           , (N'-----------------------------------------------')
                                           , (N'')
                                           , (N'USE [' + DB_NAME() + N'];');

    -- get the users
    INSERT INTO #Results (definition) VALUES (N''), (N'-- create users');
    INSERT INTO #Results (definition)
    SELECT          COALESCE(   N'IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N''' + [d].[name] + N''') CREATE USER [' + [d].[name] + N'] FOR LOGIN [' + [s].[name] + N'] WITH DEFAULT_SCHEMA = [' + [d].[default_schema_name] + N'];' collate database_default, 
                                N'IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N''' + [d].[name] + N''') CREATE USER [' + [d].[name] + N'] FOR LOGIN [' + [s].[name] + N'];' collate database_default,
                                N'IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N''' + [d].[name] + N''') CREATE USER [' + [d].[name] + N'] WITHOUT LOGIN;' collate database_default
                            )
    FROM            [sys].[database_principals] AS [d]
    LEFT OUTER JOIN [sys].[server_principals]   AS [s] ON [s].[sid] = [d].[sid]
    WHERE           [d].[name] = @principal
                    AND [d].[is_fixed_role] = 0
                    AND [d].[type] IN ('G','S','U')
    ORDER BY        [d].[name];

    -- get the roles
    INSERT INTO #Results (definition) VALUES (N''), (N'-- create roles');
    INSERT INTO #Results (definition)
    SELECT   N'IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N''' + [name] +''') CREATE ROLE [' + [name] + N'];'
    FROM     [sys].[database_principals]
    WHERE    [name] = @principal
             AND [type] = 'R'
             AND [is_fixed_role] = 0
    ORDER BY [name];

    -- get the role members
    INSERT INTO #Results (definition) VALUES (N''), (N'-- add role members');
    INSERT INTO #Results (definition)
    SELECT      CASE
                    WHEN (SELECT CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)), 2) AS INT)) > 10 THEN N'ALTER ROLE [' + [theRole].[name] + N'] ADD MEMBER [' + [theUser].[name] + N'];'
                    ELSE N'EXECUTE [sys].[sp_addrolemember] @rolename = N''' + [theRole].[name] + N''', @membername = N''' + [theUser].[name] + N''';'
                END
    FROM        [sys].[database_principals]   AS [theUser]
    INNER JOIN  [sys].[database_role_members] AS [dbrm]    ON [theUser].[principal_Id] = [dbrm].[member_principal_Id]
    INNER JOIN  [sys].[database_principals]   AS [theRole] ON [dbrm].[role_principal_id] = [theRole].[principal_id]
    WHERE       [theUser].[name] = @principal
    ORDER BY    [theUser].[name],
                [theRole].[name];

    -- get the database permissions
    INSERT INTO #Results (definition) VALUES (N''), (N'-- apply permissions');
    INSERT INTO #Results (definition)
    SELECT          CASE
                        WHEN perm.state <> 'W' AND perm.class = 0                               THEN perm.state_desc + N' ' + perm.permission_name + N' ON DATABASE::['                                                    + DB_NAME()                      +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 0                               THEN N'GRANT'        + N' ' + perm.permission_name + N' ON DATABASE::['                                                    + DB_NAME()                      +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 1  AND perm.minor_id = 0        THEN perm.state_desc + N' ' + perm.permission_name + N' ON OBJECT::['                + SCHEMA_NAME(obj.schema_id) + N'].[' + obj.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 1  AND perm.minor_id = 0        THEN N'GRANT'        + N' ' + perm.permission_name + N' ON OBJECT::['                + SCHEMA_NAME(obj.schema_id) + N'].[' + obj.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 1  AND perm.minor_id > 0        THEN perm.state_desc + N' ' + perm.permission_name + N' ON OBJECT::['                + SCHEMA_NAME(obj.schema_id) + N'].[' + obj.name  + N'] ([' + col.name + N']) TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 1  AND perm.minor_id > 0        THEN N'GRANT'        + N' ' + perm.permission_name + N' ON OBJECT::['                + SCHEMA_NAME(obj.schema_id) + N'].[' + obj.name  + N'] ([' + col.name + N']) TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 3                               THEN perm.state_desc + N' ' + perm.permission_name + N' ON SCHEMA::['                                                      + sch.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 3                               THEN N'GRANT'        + N' ' + perm.permission_name + N' ON SCHEMA::['                                                      + sch.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 4 AND pri.type NOT IN ('A','R') THEN perm.state_desc + N' ' + perm.permission_name + N' ON USER::['                                                        + pri.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 4 AND pri.type NOT IN ('A','R') THEN N'GRANT'        + N' ' + perm.permission_name + N' ON USER::['                                                        + pri.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 4 AND pri.type = 'A'            THEN perm.state_desc + N' ' + perm.permission_name + N' ON APPLICATION ROLE::['                                            + pri.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 4 AND pri.type = 'A'            THEN N'GRANT'        + N' ' + perm.permission_name + N' ON APPLICATION ROLE::['                                            + pri.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 4 AND pri.type = 'R'            THEN perm.state_desc + N' ' + perm.permission_name + N' ON ROLE::['                                                        + pri.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 4 AND pri.type = 'R'            THEN N'GRANT'        + N' ' + perm.permission_name + N' ON ROLE::['                                                        + pri.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 5                               THEN perm.state_desc + N' ' + perm.permission_name + N' ON ASSEMBLY::['                                                    + asmb.name                      +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 5                               THEN N'GRANT'        + N' ' + perm.permission_name + N' ON ASSEMBLY::['                                                    + asmb.name                      +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 6                               THEN perm.state_desc + N' ' + perm.permission_name + N' ON TYPE::['                  + SCHEMA_NAME(typ.schema_id) + N'].[' + typ.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 6                               THEN N'GRANT'        + N' ' + perm.permission_name + N' ON TYPE::['                  + SCHEMA_NAME(typ.schema_id) + N'].[' + typ.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 10                              THEN perm.state_desc + N' ' + perm.permission_name + N' ON XML SCHEMA COLLECTION::[' + SCHEMA_NAME(xsc.schema_id) + N'].[' + xsc.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 10                              THEN N'GRANT'        + N' ' + perm.permission_name + N' ON XML SCHEMA COLLECTION::[' + SCHEMA_NAME(xsc.schema_id) + N'].[' + xsc.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 15                              THEN perm.state_desc + N' ' + perm.permission_name + N' ON MESSAGE TYPE::['                                                + msg.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 15                              THEN N'GRANT'        + N' ' + perm.permission_name + N' ON MESSAGE TYPE::['                                                + msg.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 16                              THEN perm.state_desc + N' ' + perm.permission_name + N' ON CONTRACT::['                                                    + con.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 16                              THEN N'GRANT'        + N' ' + perm.permission_name + N' ON CONTRACT::['                                                    + con.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 17                              THEN perm.state_desc + N' ' + perm.permission_name + N' ON SERVICE::['                                                     + srvc.name                      +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 17                              THEN N'GRANT'        + N' ' + perm.permission_name + N' ON SERVICE::['                                                     + srvc.name                      +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 18                              THEN perm.state_desc + N' ' + perm.permission_name + N' ON REMOTE SERVICE BINDING::['                                      + rsb.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 18                              THEN N'GRANT'        + N' ' + perm.permission_name + N' ON REMOTE SERVICE BINDING::['                                      + rsb.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 19                              THEN perm.state_desc + N' ' + perm.permission_name + N' ON ROUTE::['                                                       + rte.name                       +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 19                              THEN N'GRANT'        + N' ' + perm.permission_name + N' ON ROUTE::['                                                       + rte.name                       +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 24                              THEN perm.state_desc + N' ' + perm.permission_name + N' ON SYMMETRIC KEY::['                                               + sk.name                        +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 24                              THEN N'GRANT'        + N' ' + perm.permission_name + N' ON SYMMETRIC KEY::['                                               + sk.name                        +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 25                              THEN perm.state_desc + N' ' + perm.permission_name + N' ON CERTIFICATE::['                                                 + cert.name                      +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 25                              THEN N'GRANT'        + N' ' + perm.permission_name + N' ON CERTIFICATE::['                                                 + cert.name                      +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state <> 'W' AND perm.class = 26                              THEN perm.state_desc + N' ' + perm.permission_name + N' ON ASYMMETRIC KEY::['                                              + ak.name                        +  N'] TO [' + grantee.name                   + N'] AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        WHEN perm.state =  'W' AND perm.class = 26                              THEN N'GRANT'        + N' ' + perm.permission_name + N' ON ASYMMETRIC KEY::['                                              + ak.name                        +  N'] TO [' + grantee.name + N'] WITH GRANT OPTION AS [' + grantor.name + N'];' COLLATE DATABASE_DEFAULT
                        ELSE N'RAISERROR(N''Unaccounted for datbase permissions class existed | ' + perm.class_desc + N''',16,1) WITH NOWAIT;'
                    END
    FROM            sys.database_permissions    AS perm
    INNER JOIN      sys.database_principals     AS grantee ON grantee.principal_id = perm.grantee_principal_id
    INNER JOIN      sys.database_principals     AS grantor ON grantor.principal_id = perm.grantor_principal_id
    LEFT OUTER JOIN sys.objects                 AS obj     ON perm.major_id = obj.object_id                 AND perm.class = 1
    LEFT OUTER JOIN sys.columns                 AS col     ON perm.major_id = col.object_id                 AND perm.class = 1  AND perm.minor_id = col.column_id
    LEFT OUTER JOIN sys.schemas                 AS sch     ON perm.major_id = sch.schema_id                 AND perm.class = 3
    LEFT OUTER JOIN sys.database_principals     AS pri     ON perm.major_id = pri.principal_id              AND perm.class = 4
    LEFT OUTER JOIN sys.assemblies              AS asmb    ON perm.major_id = asmb.assembly_id              AND perm.class = 5
    LEFT OUTER JOIN sys.types                   AS typ     ON perm.major_id = typ.user_type_id              AND perm.class = 6
    LEFT OUTER JOIN sys.xml_schema_collections  AS xsc     ON perm.major_id = xsc.xml_collection_id         AND perm.class = 10
    LEFT OUTER JOIN sys.service_message_types   AS msg     ON perm.major_id = msg.message_type_id           AND perm.class = 15
    LEFT OUTER JOIN sys.service_contracts       AS con     ON perm.major_id = con.service_contract_id       AND perm.class = 16
    LEFT OUTER JOIN sys.services                AS srvc    ON perm.major_id = srvc.service_id               AND perm.class = 17
    LEFT OUTER JOIN sys.remote_service_bindings AS rsb     ON perm.major_id = rsb.remote_service_binding_id AND perm.class = 18
    LEFT OUTER JOIN sys.routes                  AS rte     ON perm.major_id = rte.route_id                  AND perm.class = 19
    LEFT OUTER JOIN sys.symmetric_keys          AS sk      ON perm.major_id = sk.symmetric_key_id           AND perm.class = 24
    LEFT OUTER JOIN sys.certificates            AS cert    ON perm.major_id = cert.certificate_id           AND perm.class = 25
    LEFT OUTER JOIN sys.asymmetric_keys         AS ak      ON perm.major_id = ak.asymmetric_key_id          AND perm.class = 26
    WHERE           grantee.name = @principal
                    AND perm.major_id >= 0
    ORDER BY        grantee.name,
                    perm.permission_name,
                    perm.state_desc;
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

SET NOEXEC OFF;

IF OBJECT_ID(N'tempdb..#Passwords',N'U') IS NOT NULL DROP TABLE #Passwords;
IF OBJECT_ID(N'tempdb..#Results',N'U') IS NOT NULL DROP TABLE #Results;

