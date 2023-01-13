SET NOCOUNT ON

DECLARE 
    @SQLCmd             NVARCHAR(4000),
    @Result             INT,
    @FSO                INT,
    @DriveNameOut       INT,
    @TotalSizeOut       VARCHAR(20), 
    @MB                 NUMERIC;
SET @MB = 1048576;

DECLARE @tb_databases TABLE
(
    row_id        INT IDENTITY(1,1),
    servername    sysname NULL,
    dbname        NVARCHAR(255),
    db_size       INT,
    remarks       VARCHAR(254) 
) 

DECLARE @tb_db_show_file_stats TABLE
(
    row_id                            INT IDENTITY(1,1),
    dbname                            NVARCHAR(255),
    fileid                            INT,
    filegroup                         INT,
    totalextents                      INT,
    usedextents                       INT,
    name                              VARCHAR(255),
    filename                          VARCHAR(255) 
) 

DECLARE @tb_database_logsize_and_percent_used TABLE
(
    row_id                            INT IDENTITY(1,1),
    dbname                            NVARCHAR(255),
    log_size_mb                       DECIMAL(10,2),
    log_space_used_percent            DECIMAL(5,2),
    status                            INT
)

-- load database table with database names
--------------------------------------------------------------------------------------
SET             @SQLCmd = 'master..sp_databases'
INSERT INTO     @tb_databases (dbname, db_size, remarks) EXEC sp_executesql @SQLCmd

UPDATE @tb_databases
SET    servername = @@SERVERNAME
WHERE  servername IS NULL

-- loop through databases and load file stats table with information for each database
--------------------------------------------------------------------------------------
DECLARE @dbname VARCHAR(200)
SET     @dbname = ''

WHILE @dbname IS NOT NULL
BEGIN
    SELECT  @dbname = MIN(dbname)
    FROM    @tb_databases
    WHERE   dbname > @dbname

    IF @dbname IS NOT NULL
    BEGIN
        SELECT          @SQLCmd = 'USE [' + @dbname + ']; DBCC SHOWFILESTATS WITH NO_INFOMSGS'
        INSERT INTO     @tb_db_show_file_stats (fileid, filegroup, totalextents, usedextents, name, filename) EXEC sp_executesql @SQLCmd

        UPDATE  @tb_db_show_file_stats
        SET     dbname = @dbname
        WHERE   dbname IS NULL
    END
END

-- add log space info to the mix
--------------------------------------------------------------------------------------
INSERT INTO @tb_database_logsize_and_percent_used EXEC ('dbcc sqlperf(logspace) WITH NO_INFOMSGS')

--SELECT  '' as 'The Database Space Results Are As Follows:'
-- db free space
----------------
SELECT  
    a.DatabaseName      as [DatabaseName],
    a.Recovery_Model    as [Recovery Model],
    a.FileName          as [DB File Name],
    a.Drive             as [Drive],
    a.File_Size         as [File Size],
    a.File_Space_Used   as [File Space Used (MB)],
    a.File_Space_Free   as [File Space Free (MB)],
    a.File_Pct_Free     as [File Pct. Free], 
    a.Log_Size_MB       as [Log Size (MB)],
    a.[Log_%_Used]      as [Log % Used]
FROM   
(
    SELECT TOP 100 PERCENT 
        a.dbname                                                                as [DatabaseName],
        CAST(DATABASEPROPERTYEX (a.dbname, 'Recovery')  AS CHAR(10))            as [Recovery_Model],
        b.name                                                                  as [FileName],
        LEFT(b.filename, 3)                                                     as [Drive],
        STR(SUM((b.totalextents * 64.0) / 1024.0), 10, 2)                       as [File_Size],
        STR(SUM((b.usedextents  * 64.0) / 1024.0), 10, 2)                       as [File_Space_Used],
        STR(SUM((b.totalextents - b.usedextents)  * 64.0 / 1024.0), 10, 2)      as [File_Space_Free],
        STR(SUM((((b.totalextents - b.usedextents)  * 64.0) / 1024.0 * 100.0 / 
            ((b.totalextents * 64.0) / 1024.0))), 10, 2)                        as [File_Pct_Free],
        STR(SUM(c.log_size_mb), 10,2)                                           as [Log_Size_MB],
        STR(SUM(c.log_space_used_percent), 10,2)                                as [Log_%_Used]
    FROM    
        @tb_databases                                       as a
        INNER JOIN @tb_db_show_file_stats                   as b on a.dbname = b.dbname
        INNER JOIN  @tb_database_logsize_and_percent_used   as c on a.dbname = c.dbname
    GROUP BY 
        a.dbname, 
        b.name, 
        b.filename, 
        b.totalextents, 
        b.usedextents
    ORDER BY 
        (((b.totalextents - b.usedextents)  * 64.0) / 1024.0 * 100.0 / ((b.totalextents * 64.0) / 1024.0)), 
        a.dbname
) as a
--WHERE 
--    CAST(a.File_Pct_Free AS DECIMAL(5,2)) <= 10
--    OR CAST(a.[Log_%_Used] AS DECIMAL(5,2)) >= 90.0
ORDER BY 
    a.File_Pct_Free, 
    a.DatabaseName, 
    a.FileName
--ORDER BY a.[Log_%_Used] DESC

-- list the total space consumed by the databases combined.
--------------------------------------------------------------------------------------
SELECT  SUM(cast(a.Space_Used as DECIMAL(10,2)))                                                       as [DB Space Used (MB)],
              SUM(cast(a.DB_File_Size as DECIMAL(10,2)))                                                      as [DB Space Allocated (MB)]
FROM   (
       SELECT TOP 100 PERCENT 
              SUM((b.usedextents  * 64.0) / 1024.0)                                                           as [Space_Used],
              SUM((b.totalextents * 64.0) / 1024.0)                                                           as [DB_File_Size]
       FROM    @tb_databases                           as a
              INNER JOIN @tb_db_show_file_stats       as b on a.dbname = b.dbname
       GROUP BY a.dbname, b.name, b.filename, b.totalextents, b.usedextents
       ORDER BY (((b.totalextents - b.usedextents)  * 64.0) / 1024.0 * 100.0 / ((b.totalextents * 64.0) / 1024.0)), a.dbname
       ) as a
       ORDER BY SUM(cast(a.Space_Used as decimal(10,3)))


-- modify data file script to ensure 20% free
--------------------------------------------------------------------------------------
DECLARE @free_space_percent       DECIMAL(5,3),
              @db_file_modification      VARCHAR(MAX)

SET           @free_space_percent = 0.205


SELECT @db_file_modification = COALESCE(@db_file_modification, '') + 
              (
              CASE 
              WHEN   (
                           CAST((a.Space_Used / (1.0 - @free_space_percent)) AS INT) > a.DB_File_Size
                           )
              THEN
                     '-- Run On ' + a.ServerName                                                                     + CHAR(10) + 
                     'USE [master]'                                                                                               + CHAR(10) + 
                     'GO'                                                                                                         + CHAR(10) +
                     'ALTER DATABASE [' + a.DatabaseName + '] MODIFY FILE ( NAME = N''' + a.FileName + ''', SIZE = ' +
                     CAST(CAST(
                           (a.Space_Used / (1.0 - @free_space_percent)) 
                                  AS INT
                           )      AS VARCHAR (MAX)
                           )                                 + 
                     'MB, FILEGROWTH = 250MB )'                                                                      + CHAR(10) +
                     'GO'
              ELSE
              ''
              END
              )                                                                                                                          + CHAR(10)
FROM   (
       SELECT TOP 100 PERCENT 
              a.servername                                                                                                  AS [ServerName],
              a.dbname                                                                                                            as [DatabaseName],
              b.name                                                                                                              as [FileName],
              SUM((b.totalextents * 64.0) / 1024.0)                                                           as [DB_File_Size],
              SUM((b.usedextents  * 64.0) / 1024.0)                                                           as [Space_Used],
              STR(SUM((b.totalextents - b.usedextents)  * 64.0 / 1024.0), 10, 2)         as [Space_Free],
              SUM((((b.totalextents - b.usedextents)  * 64.0) / 1024.0 * 100.0 / 
              ((b.totalextents * 64.0) / 1024.0)))                                                            as [Pct_Free]
       FROM    @tb_databases                                                             as a
              INNER JOIN @tb_db_show_file_stats                             as b on a.dbname = b.dbname
              INNER JOIN  @tb_database_logsize_and_percent_used      as c on a.dbname = c.dbname
       GROUP BY a.ServerName, a.dbname, b.name, b.filename, b.totalextents, b.usedextents
       ORDER BY (((b.totalextents - b.usedextents)  * 64.0) / 1024.0 * 100.0 / ((b.totalextents * 64.0) / 1024.0)), a.dbname
       ) as a
ORDER BY a.Pct_Free, a.DatabaseName, a.FileName

-- list files to be modified
--------------------------------------------------------------------------------------
SELECT @db_file_modification AS [DB File Modification Commands:]



-- list free drive space
--------------------------------------------------------------------------------------
EXEC xp_fixeddrives
GO


-- autogrowth settings
--------------------------------------------------------------------------------------
SELECT 
		name AS [File_Name]
	  , physical_name AS [Location]
	  , type_desc
	  , state_desc
	  , size * 8 / 1024 AS [size_(MB)]
	  , CASE is_percent_growth
	  		WHEN 0 THEN CAST(growth * 8 / 1024 AS varchar(15)) + ' MB'
	  		WHEN 1 THEN CAST(growth AS varchar(15)) + ' %'
		END AS [grow_by]
	  , CASE max_size
			WHEN 0 THEN 'no growth allowed'
			WHEN -1 THEN 'until disk is full'
			WHEN 268435456 THEN 'up to 2TB'
			ELSE CAST(max_size AS varchar(15)) + ' MB'
	  	END AS [max_size]
FROM sys.master_files
ORDER BY name


