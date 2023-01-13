/*********************************************************************************************************************
* 
* REFRESH_SavePermissions.sql
* 
* Author: James Lutsey
* Date:   2018-02-25
* 
* Purpose: Save database permissions in CentralAdmin so that they can be reapplied after refreshing the database
* 
* Note: You must enter the database name for @db
* 
* Date        Modified By             Description of Changes
* ----------  ----------------------  -------------------------------------------------------------------------------
* 
* 
*********************************************************************************************************************/



USE [CentralAdmin];

DECLARE @db AS SYSNAME = N'<Database Name, SYSNAME, MyDatabase>';  -- select name from sys.databases_order by name;



------------------------------------------------------
--// VALIDATE USER INPUT                          //--
------------------------------------------------------

IF NOT EXISTS(SELECT 1 FROM [sys].[databases] WHERE [name] = @db)
BEGIN
    RAISERROR(N'You must enter a valide database name.',16,1) WITH NOWAIT;
    SET NOEXEC ON;
END;



------------------------------------------------------
--// CHECK THE SCHEMA                             //--
------------------------------------------------------

IF NOT EXISTS(SELECT 1 FROM [sys].[schemas] WHERE [name] = N'refresh')
    EXECUTE(N'CREATE SCHEMA [refresh] AUTHORIZATION [dbo];');



------------------------------------------------------
--// CREATE / CLEAR THE TABLES                    //--
------------------------------------------------------

IF OBJECT_ID(N'[refresh].[database_principals]',N'U') IS NULL
BEGIN
    CREATE TABLE [refresh].[database_principals]
    (
        [database_name]       SYSNAME       NOT NULL,
        [principal_id]        INT           NOT NULL,
        [name]                SYSNAME       NOT NULL,
        [type]                CHAR(1)       NOT NULL,
        [default_schema_name] SYSNAME       NULL,
        [sid]                 VARBINARY(85) NOT NULL,

        CONSTRAINT [PK_refresh_database_principals] PRIMARY KEY ([database_name], [principal_id])
    )
END;
ELSE
BEGIN
    DELETE FROM [refresh].[database_principals]
    WHERE       [database_name] = @db;
END;

IF OBJECT_ID(N'[refresh].[database_role_members]',N'U') IS NULL
BEGIN
    CREATE TABLE [refresh].[database_role_members]
    (
        [database_name]       SYSNAME NOT NULL,
        [role_principal_id]   INT     NOT NULL,
        [member_principal_id] INT     NOT NULL,

        CONSTRAINT [PK_refresh_database_role_members] PRIMARY KEY ([database_name],[role_principal_id],[member_principal_id])
    )
END;
ELSE
BEGIN
    DELETE FROM [refresh].[database_role_members]
    WHERE       [database_name] = @db;
END;

IF OBJECT_ID(N'[refresh].[database_permissions]',N'U') IS NULL
BEGIN
    CREATE TABLE [refresh].[database_permissions]
    (
        [database_name]        SYSNAME       NOT NULL,
        [class]                TINYINT       NOT NULL,
        [major_id]             INT           NOT NULL,
        [minor_id]             INT           NOT NULL,
        [grantee_principal_id] INT           NOT NULL,
        [permission_name]      NVARCHAR(128) NOT NULL,
        [state_desc]           NVARCHAR(60)  NOT NULL,

        CONSTRAINT [PK_refresh_database_permissions] PRIMARY KEY ([database_name],[class],[major_id],[minor_id],[permission_name],[state_desc])
    )
END;
ELSE
BEGIN
    DELETE FROM [refresh].[database_permissions]
    WHERE       [database_name] = @db;
END;



------------------------------------------------------
--// GET THE INFO                                 //--
------------------------------------------------------

USE [<Database Name, SYSNAME, MyDatabase>];

INSERT INTO [CentralAdmin].[refresh].[database_principals]
(
       [database_name],
       [principal_id],
       [name],
       [type],
       [default_schema_name],
       [sid]
)
SELECT DB_NAME(),
       [principal_id],
       [name],
       [type],
       [default_schema_name],
       [sid]
FROM   [sys].[database_principals]
WHERE  [principal_id] > 4
       AND [is_fixed_role] = 0;

INSERT INTO [CentralAdmin].[refresh].[database_role_members]
(
       [database_name],
       [role_principal_id],
       [member_principal_id]
)
SELECT DB_NAME(),
       [role_principal_id],
       [member_principal_id]
FROM   [sys].[database_role_members];

INSERT INTO [CentralAdmin].[refresh].[database_permissions]
(      
       [database_name],
       [class],
       [major_id],
       [minor_id],
       [grantee_principal_id],
       [permission_name],
       [state_desc]
)
SELECT DB_NAME(),
       [class],
       [major_id],
       [minor_id],
       [grantee_principal_id],
       [permission_name],
       [state_desc]
FROM   [sys].[database_permissions];



------------------------------------------------------
--// RESET NOEXEC                                 //--
------------------------------------------------------

SET NOEXEC OFF;