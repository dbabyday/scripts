SET NOCOUNT ON;

DECLARE @db  AS NVARCHAR(128) = N'<Database Name,,>',  -- select name from sys.databases order by name;
        @msg AS NVARCHAR(MAX);



-----------------------------------------------
--// CREATE THE STRUCTURE IN CENTRAL ADMIN //--
-----------------------------------------------

USE [CentralAdmin];

-- check/create the persist schema
IF NOT EXISTS(SELECT 1 FROM [sys].[schemas] WHERE [name] = N'persist') 
BEGIN
    SET @msg = CONVERT(NCHAR(19),GETDATE(),120) + N' | Creating schema [persist]';
    RAISERROR(@msg,0,1) WITH NOWAIT;
    EXECUTE('CREATE SCHEMA [persist] AUTHORIZATION [dbo]');
END;

-- check/create the persist permissions table
IF OBJECT_ID(N'[persist].[DatabasePermissions]',N'U') IS NULL
BEGIN
    SET @msg = CONVERT(NCHAR(19),GETDATE(),120) + N' | Creating table [persist].[DatabasePermissions]';
    RAISERROR(@msg,0,1) WITH NOWAIT;
    
    CREATE TABLE [persist].[DatabasePermissions]
    (
        [Id]           BIGINT         NOT NULL IDENTITY(1,1),
        [DatabaseName] SYSNAME        NOT NULL,
        [Definition]   NVARCHAR(709)  NOT NULL,
        [EntryTime]    DATETIME2(3)   NOT NULL CONSTRAINT [DF_persist_DatabasePermissions_EntryTime] DEFAULT (GETDATE()),

        CONSTRAINT [PK_persist_DatabasePermissions] PRIMARY KEY ([Id])
    );
END;
ELSE
BEGIN
    SET @msg = CONVERT(NCHAR(19),GETDATE(),120) + N' | Deleting ''' + @db + ''' records in [persist].[DatabasePermissions]';
    RAISERROR(@msg,0,1) WITH NOWAIT;
    
    DELETE FROM [persist].[DatabasePermissions]
    WHERE  [DatabaseName] = @db;
END;



-----------------------------------------------
--// CHECK FOR UNHANDLED CASES             //--
-----------------------------------------------

USE [<Database Name,,>];

-- get principals of types we're not going to handle
IF EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [type] NOT IN ('G','R','S','U'))
BEGIN
    SET @msg = N'Database principals exist that are not handled by this script. Run the following query to look at them.' + NCHAR(0x000D) + NCHAR(0x000A) +
               N'--------------------------------------------------------'                                                + NCHAR(0x000D) + NCHAR(0x000A) +
               N'USE [' + DB_NAME() + N'];'                                                                               + NCHAR(0x000D) + NCHAR(0x000A) +
               N'SELECT *'                                                                                                + NCHAR(0x000D) + NCHAR(0x000A) +
               N'FROM   [sys].[database_principals]'                                                                      + NCHAR(0x000D) + NCHAR(0x000A) +
               N'WHERE  [type] NOT IN (''G'',''R'',''S'',''U'');'                                                         + NCHAR(0x000D) + NCHAR(0x000A) +
               N'--------------------------------------------------------';

    RAISERROR(@msg,16,1) WITH NOWAIT;
END;  

-- check for orphaned users
IF EXISTS(SELECT          1 
          FROM            [sys].[database_principals] AS [d]
          LEFT OUTER JOIN [sys].[server_principals]   AS [s] ON [s].[sid] = [d].[sid]
          WHERE           [d].[principal_id] > 4
                          AND [d].[type] IN ('G','S','U')
                          AND [s].[name] IS NULL
         )
BEGIN
    SET @msg = N'Orphaned users exist; these should probably be repaired or dropped. Run the following query to find them:' + NCHAR(0x000D) + NCHAR(0x000A) +
               N'--------------------------------------------------------'                                                  + NCHAR(0x000D) + NCHAR(0x000A) +
               N'USE [' + DB_NAME() + N'];'                                                                                 + NCHAR(0x000D) + NCHAR(0x000A) +
               N'SELECT          [d].*'                                                                                     + NCHAR(0x000D) + NCHAR(0x000A) +
               N'FROM            [sys].[database_principals] AS [d]'                                                        + NCHAR(0x000D) + NCHAR(0x000A) +
               N'LEFT OUTER JOIN [sys].[server_principals]   AS [s] ON [s].[sid] = [d].[sid]'                               + NCHAR(0x000D) + NCHAR(0x000A) +
               N'WHERE           [d].[principal_id] > 4'                                                                    + NCHAR(0x000D) + NCHAR(0x000A) +
               N'                AND [d].[type] IN (''G'',''S'',''U'')'                                                     + NCHAR(0x000D) + NCHAR(0x000A) +
               N'                AND [s].[name] IS NULL'                                                                    + NCHAR(0x000D) + NCHAR(0x000A) +
               N'--------------------------------------------------------';

    RAISERROR(@msg,16,1) WITH NOWAIT;
END;

-- get permissions on database permissions - these are not hanlded by this script
IF EXISTS(SELECT          1 
          FROM            [sys].[database_permissions]
          WHERE           [class] = 4
         )
BEGIN
    SET @msg = N'Permissions for class Database Prinicpal exist; these are not handled by this script. Run the following query to find them:' + NCHAR(0x000D) + NCHAR(0x000A) +
               N'--------------------------------------------------------'                                                                    + NCHAR(0x000D) + NCHAR(0x000A) +
               N'USE [' + DB_NAME() + N'];'                                                                                                   + NCHAR(0x000D) + NCHAR(0x000A) +
               N'SELECT *'                                                                                                                    + NCHAR(0x000D) + NCHAR(0x000A) +
               N'FROM   [sys].[database_permissions]'                                                                                         + NCHAR(0x000D) + NCHAR(0x000A) +
               N'WHERE  [class] = 4'                                                                                                          + NCHAR(0x000D) + NCHAR(0x000A) +
               N'--------------------------------------------------------';

    RAISERROR(@msg,16,1) WITH NOWAIT;
END;




-----------------------------------------------
--// GET THE PERMISSIONS                   //--
-----------------------------------------------

-- create the database use statement
INSERT INTO [CentralAdmin].[persist].[DatabasePermissions] ([DatabaseName],[Definition]) VALUES (DB_NAME(),N'USE [' + DB_NAME() + N'];');

-- get the users
SET @msg = CONVERT(NCHAR(19),GETDATE(),120) + N' | Getting the users';
RAISERROR(@msg,0,1) WITH NOWAIT;

INSERT INTO [CentralAdmin].[persist].[DatabasePermissions] ([DatabaseName],[Definition]) VALUES (DB_NAME(),N'');
INSERT INTO [CentralAdmin].[persist].[DatabasePermissions] ([DatabaseName],[Definition]) VALUES (DB_NAME(),N'-- create the users');
INSERT INTO [CentralAdmin].[persist].[DatabasePermissions]
(
                [DatabaseName],
                [Definition]
)
SELECT          DB_NAME(),
                COALESCE(   N'IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N''' + [d].[name] + N''') CREATE USER [' + [d].[name] + N'] FOR LOGIN [' + [s].[name] + N'] WITH DEFAULT_SCHEMA = [' + [d].[default_schema_name] + N'];',
                            N'IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N''' + [d].[name] + N''') CREATE USER [' + [d].[name] + N'] FOR LOGIN [' + [s].[name] + N'];',
                            N'IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N''' + [d].[name] + N''') CREATE USER [' + [d].[name] + N'] WITHOUT LOGIN;'
                        )
FROM            [sys].[database_principals] AS [d]
LEFT OUTER JOIN [sys].[server_principals]   AS [s] ON [s].[sid] = [d].[sid]
WHERE           [d].[principal_id] > 4
                AND [d].[is_fixed_role] = 0
                AND [d].[type] IN ('G','S','U')
ORDER BY        [d].[name];

-- get the roles
SET @msg = CONVERT(NCHAR(19),GETDATE(),120) + N' | Getting the roles';
RAISERROR(@msg,0,1) WITH NOWAIT;

INSERT INTO [CentralAdmin].[persist].[DatabasePermissions] ([DatabaseName],[Definition]) VALUES (DB_NAME(),N'');
INSERT INTO [CentralAdmin].[persist].[DatabasePermissions] ([DatabaseName],[Definition]) VALUES (DB_NAME(),N'-- create the roles');
INSERT INTO [CentralAdmin].[persist].[DatabasePermissions]
(
         [DatabaseName],
         [Definition]
)
SELECT   DB_NAME(),
         N'IF NOT EXISTS(SELECT 1 FROM [sys].[database_principals] WHERE [name] = N''' + [name] +''') CREATE ROLE [' + [name] + N'];'
FROM     [sys].[database_principals]
WHERE    [type] = 'R'
         AND [is_fixed_role] = 0
         AND [principal_id] <> 0
ORDER BY [name];

-- get the role members
SET @msg = CONVERT(NCHAR(19),GETDATE(),120) + N' | Getting the role members';
RAISERROR(@msg,0,1) WITH NOWAIT;

INSERT INTO [CentralAdmin].[persist].[DatabasePermissions] ([DatabaseName],[Definition]) VALUES (DB_NAME(),N'');
INSERT INTO [CentralAdmin].[persist].[DatabasePermissions] ([DatabaseName],[Definition]) VALUES (DB_NAME(),N'-- add role members');
INSERT INTO [CentralAdmin].[persist].[DatabasePermissions]
(
            [DatabaseName],
            [Definition]
)
SELECT      DB_NAME(),
            CASE
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
SET @msg = CONVERT(NCHAR(19),GETDATE(),120) + N' | Getting the permissions';
RAISERROR(@msg,0,1) WITH NOWAIT;

INSERT INTO [CentralAdmin].[persist].[DatabasePermissions] ([DatabaseName],[Definition]) VALUES (DB_NAME(),N'');
INSERT INTO [CentralAdmin].[persist].[DatabasePermissions] ([DatabaseName],[Definition]) VALUES (DB_NAME(),N'-- apply permissions to principals');
INSERT INTO [CentralAdmin].[persist].[DatabasePermissions]
(
                [DatabaseName],
                [Definition]
)
SELECT          DB_NAME(),
                CASE
                    WHEN [perm].[state] <> 'W' AND [perm].[class] = 0                            THEN [perm].[state_desc] + N' ' + [perm].[permission_name] + N' ON DATABASE::['                                                        + DB_NAME()                              +  N'] TO [' + [grantee].[name]                   + N'] AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  'W' AND [perm].[class] = 0                            THEN N'GRANT '           + N' ' + [perm].[permission_name] + N' ON DATABASE::['                                                        + DB_NAME()                              +  N'] TO [' + [grantee].[name] + N'] WITH GRANT OPTION AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> 'W' AND [perm].[class] = 1  AND [perm].[minor_id] = 0 THEN [perm].[state_desc] + N' ' + [perm].[permission_name] + N' ON OBJECT::['                + SCHEMA_NAME([obj].[schema_id]) + N'].[' + [obj].[name]                           +  N'] TO [' + [grantee].[name]                   + N'] AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  'W' AND [perm].[class] = 1  AND [perm].[minor_id] = 0 THEN N'GRANT '           + N' ' + [perm].[permission_name] + N' ON OBJECT::['                + SCHEMA_NAME([obj].[schema_id]) + N'].[' + [obj].[name]                           +  N'] TO [' + [grantee].[name] + N'] WITH GRANT OPTION AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> 'W' AND [perm].[class] = 1  AND [perm].[minor_id] > 0 THEN [perm].[state_desc] + N' ' + [perm].[permission_name] + N' ON OBJECT::['                + SCHEMA_NAME([obj].[schema_id]) + N'].[' + [obj].[name]  + N'] ([' + [col].[name] + N']) TO [' + [grantee].[name]                   + N'] AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  'W' AND [perm].[class] = 1  AND [perm].[minor_id] > 0 THEN N'GRANT '           + N' ' + [perm].[permission_name] + N' ON OBJECT::['                + SCHEMA_NAME([obj].[schema_id]) + N'].[' + [obj].[name]  + N'] ([' + [col].[name] + N']) TO [' + [grantee].[name] + N'] WITH GRANT OPTION AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> 'W' AND [perm].[class] = 3                            THEN [perm].[state_desc] + N' ' + [perm].[permission_name] + N' ON SCHEMA::['                                                          + [sch].[name]                           +  N'] TO [' + [grantee].[name]                   + N'] AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  'W' AND [perm].[class] = 3                            THEN N'GRANT '           + N' ' + [perm].[permission_name] + N' ON SCHEMA::['                                                          + [sch].[name]                           +  N'] TO [' + [grantee].[name] + N'] WITH GRANT OPTION AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> 'W' AND [perm].[class] = 5                            THEN [perm].[state_desc] + N' ' + [perm].[permission_name] + N' ON ASSEMBLY::['                                                        + [asmb].[name]                          +  N'] TO [' + [grantee].[name]                   + N'] AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  'W' AND [perm].[class] = 5                            THEN N'GRANT '           + N' ' + [perm].[permission_name] + N' ON ASSEMBLY::['                                                        + [asmb].[name]                          +  N'] TO [' + [grantee].[name] + N'] WITH GRANT OPTION AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> 'W' AND [perm].[class] = 6                            THEN [perm].[state_desc] + N' ' + [perm].[permission_name] + N' ON TYPE::['                  + SCHEMA_NAME([typ].[schema_id]) + N'].[' + [typ].[name]                           +  N'] TO [' + [grantee].[name]                   + N'] AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  'W' AND [perm].[class] = 6                            THEN N'GRANT '                  + [perm].[permission_name] + N' ON TYPE::['                  + SCHEMA_NAME([typ].[schema_id]) + N'].[' + [typ].[name]                           +  N'] TO [' + [grantee].[name] + N'] WITH GRANT OPTION AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> 'W' AND [perm].[class] = 10                           THEN [perm].[state_desc] + N' ' + [perm].[permission_name] + N' ON XML SCHEMA COLLECTION::[' + SCHEMA_NAME([typ].[schema_id]) + N'].[' + [xsc].[name]                           +  N'] TO [' + [grantee].[name]                   + N'] AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  'W' AND [perm].[class] = 10                           THEN N'GRANT '                  + [perm].[permission_name] + N' ON XML SCHEMA COLLECTION::[' + SCHEMA_NAME([typ].[schema_id]) + N'].[' + [xsc].[name]                           +  N'] TO [' + [grantee].[name] + N'] WITH GRANT OPTION AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> 'W' AND [perm].[class] = 15                           THEN [perm].[state_desc] + N' ' + [perm].[permission_name] + N' ON MESSAGE TYPE::['                                                    + [msg].[name]                           +  N'] TO [' + [grantee].[name]                   + N'] AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  'W' AND [perm].[class] = 15                           THEN N'GRANT '           + N' ' + [perm].[permission_name] + N' ON MESSAGE TYPE::['                                                    + [msg].[name]                           +  N'] TO [' + [grantee].[name] + N'] WITH GRANT OPTION AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> 'W' AND [perm].[class] = 16                           THEN [perm].[state_desc] + N' ' + [perm].[permission_name] + N' ON CONTRACT::['                                                        + [con].[name]                           +  N'] TO [' + [grantee].[name]                   + N'] AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  'W' AND [perm].[class] = 16                           THEN N'GRANT '           + N' ' + [perm].[permission_name] + N' ON CONTRACT::['                                                        + [con].[name]                           +  N'] TO [' + [grantee].[name] + N'] WITH GRANT OPTION AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> 'W' AND [perm].[class] = 17                           THEN [perm].[state_desc] + N' ' + [perm].[permission_name] + N' ON SERVICE::['                                                         + [srvc].[name]                          +  N'] TO [' + [grantee].[name]                   + N'] AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  'W' AND [perm].[class] = 17                           THEN N'GRANT '           + N' ' + [perm].[permission_name] + N' ON SERVICE::['                                                         + [srvc].[name]                          +  N'] TO [' + [grantee].[name] + N'] WITH GRANT OPTION AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> 'W' AND [perm].[class] = 18                           THEN [perm].[state_desc] + N' ' + [perm].[permission_name] + N' ON REMOTE SERVICE BINDING::['                                          + [rsb].[name]                           +  N'] TO [' + [grantee].[name]                   + N'] AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  'W' AND [perm].[class] = 18                           THEN N'GRANT '           + N' ' + [perm].[permission_name] + N' ON REMOTE SERVICE BINDING::['                                          + [rsb].[name]                           +  N'] TO [' + [grantee].[name] + N'] WITH GRANT OPTION AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> 'W' AND [perm].[class] = 19                           THEN [perm].[state_desc] + N' ' + [perm].[permission_name] + N' ON ROUTE::['                                                           + [rte].[name]                           +  N'] TO [' + [grantee].[name]                   + N'] AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  'W' AND [perm].[class] = 19                           THEN N'GRANT '           + N' ' + [perm].[permission_name] + N' ON ROUTE::['                                                           + [rte].[name]                           +  N'] TO [' + [grantee].[name] + N'] WITH GRANT OPTION AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> 'W' AND [perm].[class] = 24                           THEN [perm].[state_desc] + N' ' + [perm].[permission_name] + N' ON SYMMETRIC KEY::['                                                   + [sk].[name]                            +  N'] TO [' + [grantee].[name]                   + N'] AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  'W' AND [perm].[class] = 24                           THEN N'GRANT '           + N' ' + [perm].[permission_name] + N' ON SYMMETRIC KEY::['                                                   + [sk].[name]                            +  N'] TO [' + [grantee].[name] + N'] WITH GRANT OPTION AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> 'W' AND [perm].[class] = 25                           THEN [perm].[state_desc] + N' ' + [perm].[permission_name] + N' ON CERTIFICATE::['                                                     + [cert].[name]                          +  N'] TO [' + [grantee].[name]                   + N'] AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  'W' AND [perm].[class] = 25                           THEN N'GRANT '           + N' ' + [perm].[permission_name] + N' ON CERTIFICATE::['                                                     + [cert].[name]                          +  N'] TO [' + [grantee].[name] + N'] WITH GRANT OPTION AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] <> 'W' AND [perm].[class] = 26                           THEN [perm].[state_desc] + N' ' + [perm].[permission_name] + N' ON ASYMMETRIC KEY::['                                                  + [ak].[name]                            +  N'] TO [' + [grantee].[name]                   + N'] AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    WHEN [perm].[state] =  'W' AND [perm].[class] = 26                           THEN N'GRANT '           + N' ' + [perm].[permission_name] + N' ON ASYMMETRIC KEY::['                                                  + [ak].[name]                            +  N'] TO [' + [grantee].[name] + N'] WITH GRANT OPTION AS [' + [grantor].[name] + N'];' COLLATE DATABASE_DEFAULT
                    ELSE N'RAISERROR(N''Unaccounted for datbase permissions class existed | ' + [perm].[class_desc] + N''',16,1) WITH NOWAIT;'
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
                [perm].[state_desc];


/*
    SELECT   [Definition]
    FROM     [CentralAdmin].[persist].[DatabasePermissions]
    WHERE    [DatabaseName] = N'<Database Name,,>'
    ORDER BY [Id];
*/