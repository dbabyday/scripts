DECLARE @linkedServer AS SYSNAME;

IF OBJECT_ID(N'tempdb..#LinkedServerTests',N'U') IS NOT NULL DROP TABLE #LinkedServerTests;
CREATE TABLE #LinkedServerTests
(
    [local_server]  SYSNAME        NOT NULL CONSTRAINT [PK_LinkedServerTests] PRIMARY KEY CLUSTERED ([linked_server]),
    [linked_server] SYSNAME        NOT NULL,
    [outcome]       BIT            NOT NULL CONSTRAINT [DF_LinkedServerTests_outcome] DEFAULT 1,
    [message]       NVARCHAR(4000) NOT NULL CONSTRAINT [DF_LinkedServerTests_message] DEFAULT N'',
    [entry_time]    DATETIME       NOT NULL CONSTRAINT [DF_LinkedServerTests_entry_time] DEFAULT GETDATE()
);

DECLARE linkedServers CURSOR LOCAL FAST_FORWARD FOR
    SELECT name
    FROM   sys.servers
    WHERE  is_linked = 1
           AND is_data_access_enabled = 1;

OPEN linkedServers;
    FETCH NEXT FROM linkedServers INTO @linkedServer;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO #LinkedServerTests ([local_server],[linked_server])
        VALUES (@@SERVERNAME,@linkedServer);
        
        BEGIN TRY
            EXECUTE sys.sp_testlinkedserver @servername = @linkedServer;
        END TRY
        BEGIN CATCH
            UPDATE #LinkedServerTests
            SET    [outcome] = 0,
                    [message] = N'Msg '     + CONVERT(NVARCHAR(10),ERROR_NUMBER())   +
                                N', Level ' + CONVERT(NVARCHAR(10),ERROR_SEVERITY()) +
                                N', State ' + CONVERT(NVARCHAR(10),ERROR_STATE())    +
                                N', Line '  + CONVERT(NVARCHAR(10),ERROR_LINE())     + NCHAR(0x000D) + NCHAR(0x000A) +
                                ERROR_MESSAGE()
            WHERE  [linked_server] = @linkedServer;
        END CATCH;

        FETCH NEXT FROM linkedServers INTO @linkedServer;
    END;
CLOSE linkedServers;
DEALLOCATE linkedServers;

SELECT N'INSERT INTO #LinkedServerTests1 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N''' + [local_server] + N''',N''' + [linked_server] + N''',' + CAST([outcome] AS NCHAR(1)) + N',N''' + REPLACE([message],'''','''''') + N''',N''' + CONVERT(NCHAR(19),[entry_time],120) + N''');' AS [#LinkedServerTests1],
       N'INSERT INTO #LinkedServerTests2 ([local_server],[linked_server],[outcome],[message],[entry_time]) VALUES (N''' + [local_server] + N''',N''' + [linked_server] + N''',' + CAST([outcome] AS NCHAR(1)) + N',N''' + REPLACE([message],'''','''''') + N''',N''' + CONVERT(NCHAR(19),[entry_time],120) + N''');' AS [#LinkedServerTests2] 
FROM   #LinkedServerTests;

IF OBJECT_ID(N'tempdb..#LinkedServerTests',N'U') IS NOT NULL DROP TABLE #LinkedServerTests;
