
    -----------------------------------------------
    --// REMOVE PERMISSIONS                    //--
    -----------------------------------------------

    --  SELECT 'USE ' + QUOTENAME([name]) + ';' FROM sys.databases ORDER BY name;

    USE [ZOE_SECIIT_QA];

    DECLARE @role   NVARCHAR(128),
            @schema NVARCHAR(128),
            @sql    NVARCHAR(MAX),
            @user   NVARCHAR(128);

    DECLARE curRoles CURSOR LOCAL FAST_FORWARD FOR
        SELECT [name]
        FROM   [sys].[database_principals]
        WHERE  [type] = 'R'
                AND [is_fixed_role] = 0
                AND [name] <> 'public';

    DECLARE curSchemas CURSOR LOCAL FAST_FORWARD FOR
        SELECT [name]
        FROM   [sys].[schemas]
        WHERE  USER_NAME([principal_id]) NOT IN ('public',
                                                 'dbo',
                                                 'guest',
                                                 'INFORMATION_SCHEMA',
                                                 'sys',
                                                 'db_owner',
                                                 'db_accessadmin',
                                                 'db_securityadmin',
                                                 'db_ddladmin',
                                                 'db_backupoperator',
                                                 'db_datareader',
                                                 'db_datawriter',
                                                 'db_denydatareader',
                                                 'db_denydatawriter');

    DECLARE curUsers CURSOR LOCAL FAST_FORWARD FOR
        SELECT [name]
        FROM   [sys].[database_principals]
        WHERE  [type] IN ('G','S','U')
               AND [principal_id] > 4;

    -- change schema owners so they don't conflict with dropping users
    OPEN curSchemas;
        FETCH NEXT FROM curSchemas INTO @schema;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @sql = N'ALTER AUTHORIZATION ON SCHEMA::[' + @schema + N'] TO [dbo];';
            EXECUTE(@sql);

            FETCH NEXT FROM curSchemas INTO @schema;
        END
    CLOSE curSchemas;
    DEALLOCATE curSchemas;

    -- drop users
    OPEN curUsers;
        FETCH NEXT FROM curUsers INTO @user;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @sql = N'DROP USER [' + @user + N'];';
            EXECUTE(@sql);

            FETCH NEXT FROM curUsers INTO @user;
        END
    CLOSE curUsers;
    DEALLOCATE curUsers;

    -- drop roles
    OPEN curRoles;
        FETCH NEXT FROM curRoles INTO @role;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @sql = N'DROP ROLE [' + @role + N'];';
            EXECUTE(@sql);

            FETCH NEXT FROM curRoles INTO @role;
        END
    CLOSE curRoles;
    DEALLOCATE curRoles;

    GO


