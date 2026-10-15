-- ==========================================
-- DYNAMIC READ-ONLY AUDITOR PROVISIONING
-- ==========================================
USE [master];
GO

-- Enter the login name here (e.g. DOMAIN\User)
DECLARE @LoginName SYSNAME = N'REPLACE_WITH_LOGIN_NAME';
DECLARE @ExecuteChanges BIT = 0; -- 0 = print commands only, 1 = execute



DECLARE @QuotedName NVARCHAR(300) = QUOTENAME(@LoginName);
DECLARE @NestedLiteral NVARCHAR(300) = REPLACE(@LoginName, '''', '''''''''');
DECLARE @DynamicSQL NVARCHAR(MAX);



PRINT @@SERVERNAME;



PRINT CASE WHEN @ExecuteChanges = 1
           THEN 'Mode: EXECUTE'
           ELSE 'Mode: PRINT ONLY'
      END;





-- 1. Create the Login if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @LoginName)
BEGIN
    SET @DynamicSQL = N'CREATE LOGIN ' + @QuotedName + N' FROM WINDOWS;';
    IF @ExecuteChanges = 1
    BEGIN
        EXECUTE sp_executesql @DynamicSQL;
        PRINT 'Login created successfully.';
    END
    ELSE
        PRINT @DynamicSQL;
END
ELSE
BEGIN
    PRINT 'Login already exists.';
END






-- 2. Apply baseline instance-wide metadata visibility (Supported on all modern versions)
SET @DynamicSQL = N'GRANT VIEW ANY DATABASE TO ' + @QuotedName + N';
GRANT VIEW ANY DEFINITION TO ' + @QuotedName + N';
GRANT VIEW SERVER STATE TO ' + @QuotedName + N';';

IF @ExecuteChanges = 1
BEGIN
    EXECUTE sp_executesql @DynamicSQL;
    PRINT 'Baseline server-level metadata permissions granted.';
END
ELSE
    PRINT @DynamicSQL;





-- 2b. Grant execute on utility procedures in master
SET @DynamicSQL = N'
IF OBJECT_ID(N''[dbo].[sp_Blitz]'', N''P'') IS NOT NULL GRANT EXECUTE ON OBJECT::[dbo].[sp_Blitz] TO ' + @QuotedName + N';
IF OBJECT_ID(N''[dbo].[sp_BlitzAnalysis]'', N''P'') IS NOT NULL GRANT EXECUTE ON OBJECT::[dbo].[sp_BlitzAnalysis] TO ' + @QuotedName + N';
IF OBJECT_ID(N''[dbo].[sp_BlitzBackups]'', N''P'') IS NOT NULL GRANT EXECUTE ON OBJECT::[dbo].[sp_BlitzBackups] TO ' + @QuotedName + N';
IF OBJECT_ID(N''[dbo].[sp_BlitzCache]'', N''P'') IS NOT NULL GRANT EXECUTE ON OBJECT::[dbo].[sp_BlitzCache] TO ' + @QuotedName + N';
IF OBJECT_ID(N''[dbo].[sp_BlitzIndex]'', N''P'') IS NOT NULL GRANT EXECUTE ON OBJECT::[dbo].[sp_BlitzIndex] TO ' + @QuotedName + N';
IF OBJECT_ID(N''[dbo].[sp_BlitzLock]'', N''P'') IS NOT NULL GRANT EXECUTE ON OBJECT::[dbo].[sp_BlitzLock] TO ' + @QuotedName + N';
IF OBJECT_ID(N''[dbo].[sp_BlitzWho]'', N''P'') IS NOT NULL GRANT EXECUTE ON OBJECT::[dbo].[sp_BlitzWho] TO ' + @QuotedName + N';
IF OBJECT_ID(N''[dbo].[sp_BlitzFirst]'', N''P'') IS NOT NULL GRANT EXECUTE ON OBJECT::[dbo].[sp_BlitzFirst] TO ' + @QuotedName + N';
IF OBJECT_ID(N''[dbo].[sp_cColumns]'', N''P'') IS NOT NULL GRANT EXECUTE ON OBJECT::[dbo].[sp_cColumns] TO ' + @QuotedName + N';
IF OBJECT_ID(N''[dbo].[sp_cObject]'', N''P'') IS NOT NULL GRANT EXECUTE ON OBJECT::[dbo].[sp_cObject] TO ' + @QuotedName + N';
IF OBJECT_ID(N''[dbo].[sp_cParams]'', N''P'') IS NOT NULL GRANT EXECUTE ON OBJECT::[dbo].[sp_cParams] TO ' + @QuotedName + N';
IF OBJECT_ID(N''[dbo].[sp_HumanEvents]'', N''P'') IS NOT NULL GRANT EXECUTE ON OBJECT::[dbo].[sp_HumanEvents] TO ' + @QuotedName + N';
IF OBJECT_ID(N''[dbo].[sp_JamesIndex]'', N''P'') IS NOT NULL GRANT EXECUTE ON OBJECT::[dbo].[sp_JamesIndex] TO ' + @QuotedName + N';
IF OBJECT_ID(N''[dbo].[sp_JamesLock]'', N''P'') IS NOT NULL GRANT EXECUTE ON OBJECT::[dbo].[sp_JamesLock] TO ' + @QuotedName + N';
IF OBJECT_ID(N''[dbo].[sp_RaiserrorTime]'', N''P'') IS NOT NULL GRANT EXECUTE ON OBJECT::[dbo].[sp_RaiserrorTime] TO ' + @QuotedName + N';
IF OBJECT_ID(N''[dbo].[sp_WhoIsActive]'', N''P'') IS NOT NULL GRANT EXECUTE ON OBJECT::[dbo].[sp_WhoIsActive] TO ' + @QuotedName + N';';

IF @ExecuteChanges = 1
BEGIN
    EXECUTE sp_executesql @DynamicSQL;
    PRINT 'Master procedure execute permissions granted.';
END
ELSE
    PRINT @DynamicSQL;






-- 3. Check version and apply conditional data-reading logic
DECLARE @ProductVersion NVARCHAR(128);
DECLARE @MajorVersion INT;

SET @ProductVersion = CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)); --
SET @MajorVersion = CAST(SUBSTRING(@ProductVersion, 1, CHARINDEX('.', @ProductVersion) - 1) AS INT);

PRINT 'Detected SQL Server Major Version: ' + CAST(@MajorVersion AS VARCHAR(5));

IF @MajorVersion >= 16
BEGIN
    -- ----------------------------------------------------
    -- SQL SERVER 2022+ LOGIC
    -- Uses new instance-wide system roles & permissions
    -- ----------------------------------------------------
    PRINT 'Applying SQL Server 2022+ native modern instance-wide permissions...';
    
    SET @DynamicSQL = N'
        ALTER SERVER ROLE [##MS_DatabaseConnector##] ADD MEMBER ' + @QuotedName + N';
        ALTER SERVER ROLE [##MS_DefinitionReader##] ADD MEMBER ' + @QuotedName + N';
        ALTER SERVER ROLE [##MS_ServerStateReader##] ADD MEMBER ' + @QuotedName + N';
        GRANT SELECT ALL USER SECURABLES TO ' + @QuotedName + N';
    ';
    IF @ExecuteChanges = 1
    BEGIN
        EXEC sp_executesql @DynamicSQL;
        PRINT 'SQL Server 2022+ configuration applied successfully.';
    END
    ELSE
        PRINT @DynamicSQL;
END
ELSE
BEGIN
    -- ----------------------------------------------------
    -- SQL SERVER 2019 & OLDER LOGIC
    -- Cascades db_datareader down to every individual database
    -- ----------------------------------------------------
    PRINT 'Applying SQL Server 2019 & older legacy database loop...';
    
    SET @DynamicSQL = N'
        EXEC sp_MSforeachdb ''
            USE [?];
            IF DATABASEPROPERTYEX(DB_NAME(), ''''Updateability'''') = ''''READ_ONLY''''
            BEGIN
                PRINT ''''Skipping read-only database: [?]'''';
            END
            ELSE
            BEGIN
                -- Exclude system distribution databases if replication isn''''t used, but map everything else
                IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N''''' + @NestedLiteral + N''''')
                BEGIN
                    PRINT ''''Creating user in database: [?]'''';
                    CREATE USER ' + @QuotedName + N' FOR LOGIN ' + @QuotedName + N';
                END
                ELSE
                BEGIN
                    PRINT ''''User already exists in database: [?]'''';
                END

                PRINT ''''Granting db_datareader in database: [?]'''';
                ALTER ROLE [db_datareader] ADD MEMBER ' + @QuotedName + N';
            END
        '';
    ';
    IF @ExecuteChanges = 1
    BEGIN
        EXEC sp_executesql @DynamicSQL;
        PRINT 'SQL Server 2019 & older database-level loop completed successfully.';
    END
    ELSE
        PRINT @DynamicSQL;
END
GO
