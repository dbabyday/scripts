IF UPPER(@@SERVERNAME) != N'CO-DB-034'
BEGIN
    RAISERROR(N'wrong server...setting NOEXEC ON',16,1);
    SET NOEXEC ON;
END

-- Calculate the date the identity value will reach the INT datatype limit

USE [CentralAdmin];

DECLARE @dateA  DATETIME2(3),
        @dateB  DATETIME2(3),
        @entry  INT,
        @valueA BIGINT,
        @valueB BIGINT;

IF OBJECT_ID('tempdb..#MaxIdentityValueA','U') IS NOT NULL DROP TABLE #MaxIdentityValueA;
CREATE TABLE #MaxIdentityValueA
(
    [database_name] NVARCHAR(128),
    [schema_name]   NVARCHAR(128),
    [table_name]    NVARCHAR(128),
    [value]         BIGINT,
    [entry_date]    DATETIME2(3),
    [entry_order]   INT
);

IF OBJECT_ID('tempdb..#MaxIdentityValueB','U') IS NOT NULL DROP TABLE #MaxIdentityValueB;
CREATE TABLE #MaxIdentityValueB
(
    [database_name] NVARCHAR(128),
    [schema_name]   NVARCHAR(128),
    [table_name]    NVARCHAR(128),
    [value]         BIGINT,
    [entry_date]    DATETIME2(3),
    [entry_order]   INT
);

IF OBJECT_ID('tempdb..#MaxIdentityValueC','U') IS NOT NULL DROP TABLE #MaxIdentityValueC;
CREATE TABLE #MaxIdentityValueC
(
    [database_name] NVARCHAR(128),
    [schema_name]   NVARCHAR(128),
    [table_name]    NVARCHAR(128),
    [value]         BIGINT,
    [entry_date]    DATETIME2(3),
    [date_reach_limit] DATETIME2(0)
);

INSERT INTO #MaxIdentityValueA ([database_name],[schema_name],[table_name],[value],[entry_date],[entry_order])
SELECT      [database_name],
            [schema_name],
            [table_name],
            [value],
            [entry_date],
            ROW_NUMBER() OVER (ORDER BY [entry_date] ASC)
FROM        [CentralAdmin].[dbo].[MaxIdentityValue];

INSERT INTO #MaxIdentityValueB ([database_name],[schema_name],[table_name],[value],[entry_date],[entry_order])
SELECT      [database_name],
            [schema_name],
            [table_name],
            [value],
            [entry_date],
            (ROW_NUMBER() OVER (ORDER BY [entry_date] ASC)) - 1
FROM        [CentralAdmin].[dbo].[MaxIdentityValue];

SELECT TOP 1 @dateB  = [entry_date],
             @valueB = [value]
FROM         [CentralAdmin].[dbo].[MaxIdentityValue]
ORDER BY     [entry_date] ASC;

WHILE EXISTS(SELECT 1 FROM [CentralAdmin].[dbo].[MaxIdentityValue] WHERE [entry_date] >= DATEADD(HOUR,160,@dateB)) /*168 hours per week (minus some hours to not miss the day by milliseconds)*/
BEGIN
    SET @dateA = @dateB;
    SET @valueA = @valueB;

    SELECT TOP 1 @dateB  = [entry_date],
                 @valueB = [value]
    FROM         [CentralAdmin].[dbo].[MaxIdentityValue]
    WHERE        [entry_date] >= DATEADD(HOUR,160,@dateB)
    ORDER BY     [entry_date] ASC;     
    
    INSERT INTO  #MaxIdentityValueC ([database_name],[schema_name],[table_name],[value],[entry_date],[date_reach_limit])
    SELECT TOP 1 [database_name],
                 [schema_name],
                 [table_name],
                 [value],
                 [entry_date],
                 CAST(DATEADD(SECOND,CAST(ROUND((2147483647 - @valueB) / (1.0 * (@valueB - @valueA) / DATEDIFF(SECOND,@dateA,@dateB)),0) AS INT),@dateB) AS DATETIME2(0))
    FROM         [CentralAdmin].[dbo].[MaxIdentityValue]
    WHERE        [entry_date] = @dateB;    
END

SELECT     [b].[database_name],
           [b].[schema_name],
           [b].[table_name],
           [b].[value],
           [b].[entry_date],
           CASE
               WHEN [a].[value] != [b].[value] THEN CAST(ROUND((2147483647 - [b].[value]) / (1.0 * ([b].[value] - [a].[value]) / DATEDIFF(SECOND,[a].[entry_date],[b].[entry_date]) * 86400),0) AS INT)
               ELSE 999999999999999999
           END AS [days_until_limit],
           CASE
               WHEN [a].[value] != [b].[value] THEN CAST(DATEADD(SECOND,CAST(ROUND((2147483647 - [b].[value]) / (1.0 * ([b].[value] - [a].[value]) / DATEDIFF(SECOND,[a].[entry_date],[b].[entry_date])),0) AS INT),[b].[entry_date]) AS DATETIME2(0))
               ELSE CAST('9999-12-31' AS DATETIME2(0))
           END AS [date_reach_limit]
FROM       #MaxIdentityValueA AS [a]
INNER JOIN #MaxIdentityValueB AS [b] ON [a].[entry_order] = [b].[entry_order]
ORDER BY   [a].[entry_date] DESC;

SELECT *
FROM   #MaxIdentityValueC;

IF OBJECT_ID('tempdb..#MaxIdentityValueA','U') IS NOT NULL DROP TABLE #MaxIdentityValueA;
IF OBJECT_ID('tempdb..#MaxIdentityValueB','U') IS NOT NULL DROP TABLE #MaxIdentityValueB;
IF OBJECT_ID('tempdb..#MaxIdentityValueC','U') IS NOT NULL DROP TABLE #MaxIdentityValueC;




