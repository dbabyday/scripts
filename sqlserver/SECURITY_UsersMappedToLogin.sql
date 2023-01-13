/******************************************************************
* 
* SECURITY_UsersMappedToLogin.sql
* Author: James Lutsey
* Date: 2017-07-10
* 
* Purpose: Get users mapped to login(s), orphaned users
* 
******************************************************************/

-- USER INPUT
DECLARE @login  NVARCHAR(128) = N'',
        @option INT = 7, -- 1 = users mapped to login provided
                         -- 2 = users mapped to all logins
                         -- 4 = orphaned users

-- other variables
        @sql           NVARCHAR(MAX) = N'',
        @oneLogin      BIT = 0,
        @allLogins     BIT = 0,
        @orphanedUsers BIT = 0;

-- verify user input
IF @option < 1 OR @option > 7
BEGIN
    RAISERROR(N'@option must be an integer between 1-7',16,1);
    SET NOEXEC ON;
END

-- flag the options
IF @option >= 4
BEGIN
    SET @orphanedUsers = 1;
    SET @option -= 4;
END

IF @option >= 2
BEGIN
    SET @allLogins = 1;
    SET @option -= 2;
END

IF @option >= 1
BEGIN
    SET @oneLogin = 1;
    SET @option -= 1;
END



---------------------------------------
--// USERS MAPPED TO LOGIN         //--
---------------------------------------

IF @oneLogin = 1
BEGIN
    IF LEN(@login) > 0
    BEGIN
        SET @sql = N'';
        
        SELECT @sql += N'
UNION ALL
SELECT          [sp].[name] collate database_default AS [LoginName],
                N''' + [name] + N''' collate database_default AS [DbName],
                [dp].[name] collate database_default AS [UserName]
FROM            [sys].[server_principals] AS [sp]
LEFT OUTER JOIN [' + [name] + N'].[sys].[database_principals] AS [dp] ON [sp].[sid] = [dp].[sid]
WHERE           [sp].[name] = N''' + @login + N'''' collate database_default
        FROM   [sys].[databases]
        WHERE  [state] = 0;

        SET @sql = STUFF(@sql,1,13,N'') + CHAR(10) + N'ORDER BY 2,3;';

        --SELECT @sql;
        EXECUTE(@sql);
    END
    ELSE
        RAISERROR('You need to enter a name for @login to find users mapped to that one login',16,1);
END



---------------------------------------
--// USERS MAPPED TO ALL LOGINS    //--
---------------------------------------

IF @allLogins = 1
BEGIN
    SET @sql = N'';

    SELECT @sql += N'
UNION ALL
SELECT   [sp].[name] collate database_default AS [LoginName],
         N''' + [name] + N''' collate database_default AS [DbName],
         [dp].[name] collate database_default AS [UserName]
FROM     [sys].[server_principals] AS [sp]
JOIN     [' + [name] + N'].[sys].[database_principals] AS [dp] ON [sp].[sid] = [dp].[sid]' collate database_default
    FROM   [sys].[databases]
    WHERE  [state] = 0;

    SET @sql = STUFF(@sql,1,13,N'') + CHAR(10) + N'ORDER BY 1,2,3;';

    --SELECT @sql;
    EXECUTE(@sql);
END



---------------------------------------
--// ORPHANED USERS                //--
---------------------------------------

IF @orphanedUsers = 1
BEGIN
    SET @sql = N'';

    SELECT @sql += N'
UNION ALL
SELECT          [sp].[name] collate database_default AS [LoginName],
                N''' + [name] + N''' collate database_default AS [DbName],
                [dp].[name] collate database_default AS [UserName]
FROM            [' + [name] + N'].[sys].[database_principals] AS [dp]
LEFT OUTER JOIN [sys].[server_principals] AS [sp] ON [dp].[sid] = [sp].[sid]
WHERE           [sp].[name] IS NULL
                AND [dp].[is_fixed_role] = 0
                AND [dp].[principal_id] > 4
                AND [dp].[type] != N''R''' collate database_default
    FROM   [sys].[databases]
    WHERE  [state] = 0;

    SET @sql = STUFF(@sql,1,13,N'') + CHAR(10) + N'ORDER BY 2,3;';

    --SELECT @sql;
    EXECUTE(@sql);
END



---------------------------------------
--// RESET EXECUTION IF NEEDED     //--
---------------------------------------

SET NOEXEC OFF;
