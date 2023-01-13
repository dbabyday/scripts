-- Run at the distributor on the distribution database

USE [distribution];
--USE Gsf2distribution;

IF OBJECT_ID(N'dbo.usp_PendingCommands',N'P') IS NULL 
    EXECUTE(N'CREATE PROCEDURE dbo.usp_PendingCommands AS ;');

GO
ALTER PROCEDURE dbo.usp_PendingCommands AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @publisher SYSNAME
            ,@publisher_db SYSNAME
            ,@publication SYSNAME
            ,@subscriber SYSNAME
            ,@subscriber_db SYSNAME
            ,@subscription_type INT
            ,@rn AS SMALLINT = 0
            ,@TotalSubscriptions AS SMALLINT
            ,@retcode INT
            ,@agent_id INT
            ,@publisher_id INT
            ,@subscriber_id INT
            ,@lastrunts TIMESTAMP
            ,@xact_seqno VARBINARY(16)
            ,@inactive INT
            ,@virtual INT
            ,@Message AS VARCHAR(MAX)
            ,@sql AS NVARCHAR(MAX);

    DECLARE @countab AS TABLE (pendingcmdcount INT);
    CREATE TABLE #t
    (
        rn SMALLINT IDENTITY(1, 1)
        ,Publisher sysname
        ,Publisher_db sysname
        ,Publication sysname
        ,Subscriber sysname
        ,Subscriber_db sysname
        ,Subscription_Type NCHAR(1)
        ,PendingCommands INT
        ,Distributor sysname
    );


    INSERT INTO #t (Publisher,Publisher_db,Publication,Subscriber,Subscriber_db,Subscription_Type,PendingCommands,Distributor)
    SELECT     sp.name AS Publisher,
               msa.publisher_db AS Publisher_db,
               msa.publication AS Publication,
               ss.name AS Subscriber,
               msa.subscriber_db AS Subscriber_db,
               CAST(msa.subscription_type AS NCHAR(1)) AS Subscription_Type,
               CAST(0 AS INT) AS PendingCommands,
               DB_NAME()
    FROM       dbo.MSdistribution_agents AS msa
    INNER JOIN sys.servers AS sp ON sp.server_id = msa.publisher_id
    INNER JOIN sys.servers AS ss ON ss.server_id = msa.subscriber_id;

    SET @TotalSubscriptions = @@ROWCOUNT;

    WHILE @rn < @TotalSubscriptions
    BEGIN
        --reset
        SELECT
        @retcode = NULL
        ,@agent_id = NULL
        ,@publisher_id = NULL
        ,@subscriber_id = NULL
        ,@lastrunts = NULL
        ,@xact_seqno = NULL
        ,@inactive = 1
        ,@virtual = -1
        ,@rn += 1; --increment by 1

        SELECT
        @publisher = t.Publisher
        ,@publisher_db = t.Publisher_db
        ,@publication = t.Publication
        ,@subscriber = t.Subscriber
        ,@subscriber_db = t.Subscriber_db
        ,@subscription_type = t.Subscription_Type
        FROM
        #t AS t
        WHERE
        t.rn = @rn;

        --
        -- get the server ids for publisher and subscriber
        --
        SELECT
        @publisher_id = server_id
        FROM
        sys.servers
        WHERE
        UPPER(name) = UPPER(@publisher)
        IF (@publisher_id IS NULL)
        BEGIN
        RAISERROR(21618, 16, -1, @publisher)
        --return 1
        END
        SELECT
        @subscriber_id = server_id
        FROM
        sys.servers
        WHERE
        UPPER(name) = UPPER(@subscriber)
        IF (@subscriber_id IS NULL)
        BEGIN
        RAISERROR(20032, 16, -1, @subscriber, @publisher)
        --return 1
        END

        --
        -- get the agent id
        --
        SELECT
        @agent_id = id
        FROM
        dbo.MSdistribution_agents
        WHERE
        publisher_id = @publisher_id
        AND publisher_db = @publisher_db
        AND publication IN (@publication, 'ALL')
        AND subscriber_id = @subscriber_id
        AND subscriber_db = @subscriber_db
        AND subscription_type = @subscription_type
        IF (@agent_id IS NULL)
        BEGIN
        RAISERROR(14055, 16, -1)
        --return (1)
        END;

        --
        -- Compute timestamp for latest run
        --
        WITH dist_sessions(start_time, runstatus, timestamp)
        AS (
        SELECT
        start_time
        ,MAX(runstatus)
        ,MAX(timestamp)
        FROM
        dbo.MSdistribution_history
        WHERE
        agent_id = @agent_id
        GROUP BY
        start_time
        )
        SELECT
        @lastrunts = MAX(timestamp)
        FROM
        dist_sessions
        WHERE
        runstatus IN (2, 3, 4);
        IF (@lastrunts IS NULL)
        BEGIN
        --
        -- Distribution agent has not run successfully even once
        -- and virtual subscription of immediate sync publication is inactive (snapshot has not run), no point of returning any counts
        -- see SQLBU#320752, orig fix SD#881433, and regression bug VSTS# 140179 before you attempt to fix it differently :)
        IF EXISTS ( SELECT
        *
        FROM
        dbo.MSpublications p
        JOIN dbo.MSsubscriptions s
        ON p.publication_id = s.publication_id
        WHERE
        p.publisher_id = @publisher_id
        AND p.publisher_db = @publisher_db
        AND p.publication = @publication
        AND p.immediate_sync = 1
        AND s.status = @inactive
        AND s.subscriber_id = @virtual )
        BEGIN
        SELECT
        'pendingcmdcount' = 0
        --return 0
        END
        --
        -- Grab the max timestamp
        --
        SELECT
        @lastrunts = MAX(timestamp)
        FROM
        dbo.MSdistribution_history
        WHERE
        agent_id = @agent_id
        END
        --
        -- get delivery rate for the latest completed run
        -- get the latest sequence number
        --
        SELECT
        @xact_seqno = xact_seqno
        FROM
        dbo.MSdistribution_history
        WHERE
        agent_id = @agent_id
        AND timestamp = @lastrunts
        --
        -- if no rows are selected in last query
        -- explicitly initialize these variables
        --
        SELECT
        @xact_seqno = ISNULL(@xact_seqno, 0x0)


        --
        -- get the count of undelivered commands
        -- PAL check done inside
        --
        DELETE
        @countab;

        INSERT INTO @countab
        (
        pendingcmdcount
        )
        EXEC @retcode = sys.sp_MSget_repl_commands @agent_id = @agent_id, @last_xact_seqno = @xact_seqno, @get_count = 2,
        @compatibility_level = 9000000


        UPDATE
        #t
        SET
        PendingCommands = (
        SELECT
        pendingcmdcount
        FROM
        @countab
        )
        WHERE
        rn = @rn;

    END

    SELECT * FROM #t ORDER BY publication, subscriber, subscriber_db;

    DROP TABLE #t;
END;
GO

USE master;