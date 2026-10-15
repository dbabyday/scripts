USE [master];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @LoginName sysname = N'REPLACE_WITH_LOGIN_NAME'; -- e.g. N'app_login'
DECLARE @LoginSid  varbinary(85);
DECLARE @ExecuteChanges bit = 0; -- 0 = report only, 1 = execute changes





SELECT @LoginSid = sp.sid
FROM sys.server_principals AS sp
WHERE sp.name = @LoginName;

IF @LoginSid IS NULL
BEGIN
    RAISERROR('Login %s was not found.', 16, 1, @LoginName);
    RETURN;
END;

PRINT CONCAT('Processing login: ', @LoginName);
PRINT CASE WHEN @ExecuteChanges = 1
           THEN N'Mode: EXECUTE (changes will be applied)'
           ELSE N'Mode: REPORT ONLY (no changes will be applied)'
      END;




--------------------------------------------------------------------------------
-- Optional: remove login from server roles first
--------------------------------------------------------------------------------
DECLARE @cmd nvarchar(max) = N'';

SELECT @cmd = @cmd +
    N'ALTER SERVER ROLE ' + QUOTENAME(r.name) + N' DROP MEMBER ' + QUOTENAME(@LoginName) + N';' + CHAR(13)
FROM sys.server_role_members rm
JOIN sys.server_principals r ON r.principal_id = rm.role_principal_id
JOIN sys.server_principals m ON m.principal_id = rm.member_principal_id
WHERE m.name = @LoginName;

IF @cmd <> N''
BEGIN
    IF @ExecuteChanges = 1
    BEGIN
        PRINT 'Dropping server role memberships...';
        EXEC sp_executesql @cmd;
    END
    ELSE
        PRINT @cmd;
END;




--------------------------------------------------------------------------------
-- Optional: if SQL Agent is installed, reassign jobs owned by this login to sa
--------------------------------------------------------------------------------
IF DB_ID(N'msdb') IS NOT NULL
BEGIN
    DECLARE @jobcmd nvarchar(max) = N'';

    SELECT @jobcmd = @jobcmd +
        N'EXEC msdb.dbo.sp_update_job @job_id = ''' + CONVERT(nvarchar(36), j.job_id) +
        N''', @owner_login_name = N''sa'';' + CHAR(13)
    FROM msdb.dbo.sysjobs AS j
    WHERE SUSER_SNAME(j.owner_sid) = @LoginName;

    IF @jobcmd <> N''
    BEGIN
        IF @ExecuteChanges = 1
        BEGIN
            PRINT 'Reassigning SQL Agent job ownership to sa...';
            EXEC sp_executesql @jobcmd;
        END
        ELSE
            PRINT @jobcmd;
    END;
END;




--------------------------------------------------------------------------------
-- Drop associated database users in each online, accessible database
--------------------------------------------------------------------------------
DECLARE @db sysname;
DECLARE @sql nvarchar(max);

DECLARE dbs CURSOR LOCAL FAST_FORWARD FOR
SELECT d.name
FROM sys.databases AS d
WHERE d.state_desc = N'ONLINE'
  AND HAS_DBACCESS(d.name) = 1
  AND d.source_database_id IS NULL; -- skip snapshots

OPEN dbs;
FETCH NEXT FROM dbs INTO @db;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
USE ' + QUOTENAME(@db) + N';
SET NOCOUNT ON;

DECLARE @UserName sysname, @InnerCmd nvarchar(max);

DECLARE u CURSOR LOCAL FAST_FORWARD FOR
SELECT dp.name
FROM sys.database_principals AS dp
WHERE dp.sid = @LoginSid
  AND dp.principal_id > 4
  AND dp.type IN (''S'',''U'',''G'',''E'',''X'');

OPEN u;
FETCH NEXT FROM u INTO @UserName;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Drop role memberships
    SELECT @InnerCmd = STUFF((
        SELECT N'';ALTER ROLE '' + QUOTENAME(r.name) + N'' DROP MEMBER '' + QUOTENAME(@UserName)
        FROM sys.database_role_members drm
        JOIN sys.database_principals r ON r.principal_id = drm.role_principal_id
        JOIN sys.database_principals m ON m.principal_id = drm.member_principal_id
        WHERE m.name = @UserName
        FOR XML PATH(''''), TYPE).value(''.'', ''nvarchar(max)'')
    ,1,1,N'''');

    IF @InnerCmd IS NOT NULL AND LEN(@InnerCmd) > 0
    BEGIN
        IF @ExecuteChanges = 1
            EXECUTE sp_executesql @InnerCmd;
        ELSE
            PRINT @InnerCmd;
    END;

    -- Transfer owned schemas to dbo
    SELECT @InnerCmd = STUFF((
        SELECT N'';ALTER AUTHORIZATION ON SCHEMA::'' + QUOTENAME(s.name) + N'' TO dbo''
        FROM sys.schemas s
        WHERE s.principal_id = USER_ID(@UserName)
          AND s.name NOT IN (''dbo'', ''sys'', ''INFORMATION_SCHEMA'')
        FOR XML PATH(''''), TYPE).value(''.'', ''nvarchar(max)'')
    ,1,1,N'''');

    IF @InnerCmd IS NOT NULL AND LEN(@InnerCmd) > 0
    BEGIN
        IF @ExecuteChanges = 1
            EXECUTE sp_executesql @InnerCmd;
        ELSE
            PRINT @InnerCmd;
    END;

    -- Drop user
    SET @InnerCmd = N''DROP USER '' + QUOTENAME(@UserName) + N'';'';
    IF @ExecuteChanges = 1
    BEGIN
        EXECUTE sp_executesql @InnerCmd;
        PRINT N''Dropped user '' + QUOTENAME(@UserName) + N'' in database '' + DB_NAME();
    END
    ELSE
        PRINT @InnerCmd;

    FETCH NEXT FROM u INTO @UserName;
END

CLOSE u;
DEALLOCATE u;
';

    BEGIN TRY
        PRINT CONCAT('Processing database: ', @db);
        EXEC sp_executesql
            @sql,
            N'@LoginSid varbinary(85), @ExecuteChanges bit',
            @LoginSid = @LoginSid,
            @ExecuteChanges = @ExecuteChanges;
    END TRY
    BEGIN CATCH
        PRINT CONCAT('Database ', @db, ' skipped/error: ', ERROR_MESSAGE());
    END CATCH;

    FETCH NEXT FROM dbs INTO @db;
END

CLOSE dbs;
DEALLOCATE dbs;




--------------------------------------------------------------------------------
-- Drop login
--------------------------------------------------------------------------------
DECLARE @DropLoginSql nvarchar(max) = N'DROP LOGIN ' + QUOTENAME(@LoginName) + N';';
IF @ExecuteChanges = 1
BEGIN
    EXECUTE sp_executesql @DropLoginSql;
    PRINT CONCAT('Completed. Login dropped: ', @LoginName);
END
ELSE
    PRINT @DropLoginSql;
GO